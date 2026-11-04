import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../data/vocabulary.dart';
import 'landmark_detector.dart';
import 'rotation_finder.dart';
import 'sign_features.dart';
import 'sign_recognizer.dart';
import 'sign_segmenter.dart';

/// Recognizes signs with the model trained on KArSL (`ml/train.py`):
/// camera frame → MediaPipe landmarks (native) → body-normalized frames →
/// segment of one sign → TFLite classifier.
class KarslSignRecognizer implements SignRecognizer {
  KarslSignRecognizer({LandmarkDetector? detector})
    : _detector = detector ?? LandmarkDetector();

  /// Below this top probability the sign is reported as not understood.
  static const minConfidence = 0.55;

  final LandmarkDetector _detector;
  final _predictions = StreamController<SignPrediction>.broadcast();
  final _status = ValueNotifier(SignStatus.waiting);
  final _normalizer = BodyNormalizer();
  final _segmenter = SignSegmenter();
  RotationFinder? _rotation;
  String? _cameraName;

  Interpreter? _interpreter;
  List<SignWord?> _labels = const [];
  bool _ready = false;
  bool _busy = false;
  bool _disposed = false;

  String? _reason;
  int _frames = 0;
  int _framesWithBody = 0;
  int _framesWithHands = 0;
  String _lastSign = '-';

  @override
  bool get isReady => _ready;

  @override
  Stream<SignPrediction> get predictions => _predictions.stream;

  @override
  ValueListenable<SignStatus> get status => _status;

  @override
  String? get unavailableReason => _ready ? null : _reason;

  @override
  Future<Map<String, String>> diagnostics() async => {
    ...await _detector.info(),
    'recognition': _ready ? 'running' : 'unavailable',
    if (_reason != null) 'reason': _reason!,
    'camera': _cameraName ?? '-',
    'image turned': _rotation == null
        ? '-'
        : '${_rotation!.rotation}°'
              '${_rotation!.isSettled ? ' (body found)' : ' (searching)'}',
    'frames': '$_frames',
    'body seen': '$_framesWithBody',
    'hands seen': '$_framesWithHands',
    'last sign': _lastSign,
  };

  @override
  Future<bool> initialize() async {
    try {
      final landmarkFailure = await _detector.init();
      if (landmarkFailure != null) {
        _reason = 'landmarks: $landmarkFailure';
        return false;
      }
      _interpreter = await Interpreter.fromAsset('assets/model/signs.tflite');
      final labels = await rootBundle.loadString('assets/model/labels.txt');
      _labels = [
        for (final id in labels.split('\n'))
          if (id.trim().isNotEmpty) signById(id.trim()),
      ];
      _ready = !_disposed;
      _reason = _ready ? null : 'screen closed while loading';
    } catch (e) {
      debugPrint('Sign recognizer unavailable: $e');
      _reason = 'sign model: $e';
      _ready = false;
    }
    return _ready;
  }

  @override
  Future<void> processFrame(CameraImage image, CameraDescription camera) async {
    // Frames arriving while the previous one is processed are dropped.
    if (!_ready || _busy || _disposed) return;
    _busy = true;
    try {
      if (_cameraName != camera.name) {
        _cameraName = camera.name;
        // iOS hands over upright frames; Android hands over sensor frames.
        _rotation = RotationFinder(
          initial: defaultTargetPlatform == TargetPlatform.iOS
              ? 0
              : camera.sensorOrientation,
        );
        _restart();
      }
      final raw = await _detector.detect(image, _rotation!.rotation);
      if (_disposed) return;
      _frames++;
      if (raw?.pose != null) _framesWithBody++;
      if (raw != null && raw.hands.isNotEmpty) _framesWithHands++;
      if (_rotation!.report(poseFound: raw?.pose != null)) {
        _restart(); // the image just turned; what we collected is stale
        return;
      }
      final body = raw == null ? null : _normalizer.normalize(raw);
      final segment = _segmenter.add(body);
      if (segment != null) {
        _classify(segment);
      } else if (_segmenter.isCollecting) {
        _status.value = SignStatus.watching;
      } else if (_status.value == SignStatus.watching) {
        _status.value = SignStatus.waiting;
      }
    } catch (e) {
      debugPrint('Sign frame failed: $e');
    } finally {
      _busy = false;
    }
  }

  void _restart() {
    _normalizer.reset();
    _segmenter.reset();
    if (!_disposed) _status.value = SignStatus.waiting;
  }

  void _classify(List<BodyFrame> segment) {
    final input = sampleFeatures(segment).reshape([1, seqLen, featureCount]);
    final output = [List<double>.filled(_labels.length, 0)];
    _interpreter!.run(input, output);
    final probs = output.first;
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    final sign = _labels[best];
    _lastSign =
        '${sign?.id ?? best} ${(probs[best] * 100).round()}%'
        '${probs[best] >= minConfidence ? '' : ' (below threshold)'}';
    if (sign != null && probs[best] >= minConfidence) {
      _status.value = SignStatus.waiting;
      _predictions.add(SignPrediction(sign: sign, confidence: probs[best]));
    } else {
      _status.value = SignStatus.unsure;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _ready = false;
    _interpreter?.close();
    // The native landmarkers stay loaded for the next visit to the screen.
    _status.dispose();
    await _predictions.close();
  }
}
