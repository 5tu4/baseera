import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../services/glasses/glasses_link.dart';
import 'obstacle_decoder.dart';
import 'obstacle_detector.dart';

/// Runs the YOLO model trained in `ml/obstacle` (or a stock COCO YOLO) on
/// glasses frames. Inference runs on its own isolate so the UI stays smooth.
class YoloObstacleDetector implements ObstacleDetector {
  static const modelAsset = 'assets/model/obstacles.tflite';
  static const labelsAsset = 'assets/model/obstacle_labels.txt';

  Interpreter? _interpreter;
  IsolateInterpreter? _isolate;
  List<String> _labels = const [];
  int _inputSize = 320;
  List<int> _outputShape = const [];

  @override
  Future<bool> initialize() async {
    if (_isolate != null) return true;
    try {
      final interpreter = await Interpreter.fromAsset(
        modelAsset,
        options: InterpreterOptions()..threads = 4,
      );
      _labels = [
        for (final line in (await rootBundle.loadString(
          labelsAsset,
        )).split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ];
      _inputSize = interpreter.getInputTensor(0).shape[1];
      _outputShape = interpreter.getOutputTensor(0).shape;
      _interpreter = interpreter;
      _isolate = await IsolateInterpreter.create(address: interpreter.address);
      return true;
    } catch (e) {
      // No model shipped yet (ml/obstacle/install_model.py adds one).
      debugPrint('Obstacle model unavailable: $e');
      return false;
    }
  }

  @override
  Future<List<GlassesSighting>> detect(
    Uint8List jpeg, {
    int quarterTurns = 0,
  }) async {
    final isolate = _isolate;
    if (isolate == null) return const [];
    final (input, letterbox) = await _toInput(jpeg, quarterTurns % 4);

    // Filled in the model's own layout; decodeYolo reads it by shape.
    final rows = _outputShape[1], columns = _outputShape[2];
    final output = [
      List.generate(rows, (_) => List<double>.filled(columns, 0)),
    ];
    await isolate.run(input.reshape([1, _inputSize, _inputSize, 3]), output);

    final flat = <double>[for (final row in output.first) ...row];
    return sightingsFrom(
      decodeYolo(
        flat,
        shape: _outputShape,
        labels: _labels,
        letterbox: letterbox,
      ),
    );
  }

  /// JPEG → letterboxed RGB floats (0..1), the way Ultralytics trains:
  /// scaled to fit, centered, grey (114) padding. The picture is turned
  /// [turns] quarter turns clockwise first, so boxes (and left/right) come
  /// out the right way up.
  Future<(Float32List, Letterbox)> _toInput(Uint8List jpeg, int turns) async {
    final probe = await ui.instantiateImageCodec(jpeg);
    final first = (await probe.getNextFrame()).image;
    final sideways = turns.isOdd;
    final letterbox = Letterbox(
      sourceWidth: sideways ? first.height : first.width,
      sourceHeight: sideways ? first.width : first.height,
      inputSize: _inputSize,
    );
    // Decoded at the scaled size of the picture as it comes, turned below.
    final targetWidth = sideways
        ? letterbox.scaledHeight
        : letterbox.scaledWidth;
    final targetHeight = sideways
        ? letterbox.scaledWidth
        : letterbox.scaledHeight;
    var image = first;
    if (targetWidth != first.width || targetHeight != first.height) {
      first.dispose();
      final codec = await ui.instantiateImageCodec(
        jpeg,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      image = (await codec.getNextFrame()).image;
    }
    final rgba = (await image.toByteData())!.buffer.asUint8List();
    final w = image.width, h = image.height;
    image.dispose();

    final size = _inputSize;
    final input = Float32List(size * size * 3)
      ..fillRange(0, size * size * 3, 114 / 255);
    final left = letterbox.padX.floor(), top = letterbox.padY.floor();
    for (var y = 0; y < h; y++) {
      var src = y * w * 4;
      for (var x = 0; x < w; x++) {
        final (tx, ty) = turnPixel(x, y, w, h, turns);
        var dst = ((ty + top) * size + tx + left) * 3;
        input[dst++] = rgba[src] / 255;
        input[dst++] = rgba[src + 1] / 255;
        input[dst] = rgba[src + 2] / 255;
        src += 4;
      }
    }
    return (input, letterbox);
  }

  @override
  Future<void> dispose() async {
    await _isolate?.close();
    _interpreter?.close();
    _isolate = null;
    _interpreter = null;
  }
}

ObstacleDetector createObstacleDetector() => YoloObstacleDetector();
