import 'dart:math' as math;
import 'dart:ui' show Rect;

import '../data/obstacles.dart';
import '../services/glasses/glasses_link.dart';

/// One box the obstacle model found, in 0..1 coordinates of the camera frame.
class Detection {
  const Detection(this.label, this.score, this.box);

  final String label;
  final double score;
  final Rect box;

  @override
  String toString() => '$label ${(score * 100).round()}% $box';
}

/// How a camera frame was fitted into the model's square input: scaled by
/// [scale] and centered with [padX]/[padY] pixels of grey on each side.
class Letterbox {
  Letterbox({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.inputSize,
  }) : scale = math.min(inputSize / sourceWidth, inputSize / sourceHeight) {
    padX = (inputSize - sourceWidth * scale) / 2;
    padY = (inputSize - sourceHeight * scale) / 2;
  }

  final int sourceWidth;
  final int sourceHeight;
  final int inputSize;
  final double scale;
  late final double padX;
  late final double padY;

  int get scaledWidth => (sourceWidth * scale).round();
  int get scaledHeight => (sourceHeight * scale).round();

  /// Input-pixel box → 0..1 box in the camera frame.
  Rect toSource(double left, double top, double right, double bottom) {
    double x(double v) =>
        ((v - padX) / scale / sourceWidth).clamp(0.0, 1.0).toDouble();
    double y(double v) =>
        ((v - padY) / scale / sourceHeight).clamp(0.0, 1.0).toDouble();
    return Rect.fromLTRB(x(left), y(top), x(right), y(bottom));
  }
}

/// Where pixel (x, y) of a w x h picture lands after turning the picture
/// [turns] quarter turns clockwise (as `RotatedBox` shows it).
(int, int) turnPixel(int x, int y, int w, int h, int turns) =>
    switch (turns % 4) {
      1 => (h - 1 - y, x),
      2 => (w - 1 - x, h - 1 - y),
      3 => (y, w - 1 - x),
      _ => (x, y),
    };

/// Decodes the raw output of an Ultralytics YOLO TFLite export: for every
/// candidate box, cx, cy, w, h and then one score per class.
///
/// Exports differ in layout (`[1, 4+classes, boxes]` or `[1, boxes,
/// 4+classes]`) and in units (0..1 or input pixels), so both are handled.
/// Overlapping boxes of the same label are merged (non-maximum suppression).
List<Detection> decodeYolo(
  List<double> output, {
  required List<int> shape,
  required List<String> labels,
  required Letterbox letterbox,
  double minScore = 0.45,
  double maxOverlap = 0.5,
}) {
  final channels = 4 + labels.length;
  final bool channelsFirst;
  final int boxes;
  if (shape.length == 3 && shape[1] == channels) {
    channelsFirst = true;
    boxes = shape[2];
  } else if (shape.length == 3 && shape[2] == channels) {
    channelsFirst = false;
    boxes = shape[1];
  } else {
    throw ArgumentError(
      'output shape $shape does not fit ${labels.length} labels',
    );
  }
  double at(int box, int channel) => channelsFirst
      ? output[channel * boxes + box]
      : output[box * channels + channel];

  // Coordinates in 0..1 (the usual TFLite export) or in input pixels.
  var largest = 0.0;
  for (var i = 0; i < boxes; i++) {
    largest = math.max(largest, at(i, 2));
  }
  final unit = largest <= 2 ? letterbox.inputSize.toDouble() : 1.0;

  final candidates = <Detection>[];
  for (var i = 0; i < boxes; i++) {
    var best = 0;
    var bestScore = at(i, 4);
    for (var c = 1; c < labels.length; c++) {
      final score = at(i, 4 + c);
      if (score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    if (bestScore < minScore) continue;
    final cx = at(i, 0) * unit, cy = at(i, 1) * unit;
    final w = at(i, 2) * unit, h = at(i, 3) * unit;
    candidates.add(
      Detection(
        labels[best],
        bestScore,
        letterbox.toSource(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2),
      ),
    );
  }

  candidates.sort((a, b) => b.score.compareTo(a.score));
  final kept = <Detection>[];
  for (final candidate in candidates) {
    final duplicate = kept.any(
      (k) =>
          k.label == candidate.label &&
          _overlap(k.box, candidate.box) > maxOverlap,
    );
    if (!duplicate) kept.add(candidate);
  }
  return kept;
}

/// Intersection over union.
double _overlap(Rect a, Rect b) {
  final inter = a.intersect(b);
  if (inter.width <= 0 || inter.height <= 0) return 0;
  final i = inter.width * inter.height;
  return i / (a.width * a.height + b.width * b.height - i);
}

/// Turns detections into warnings worth saying: only things that are near
/// the user's path (big, or reaching the lower part of the view), with the
/// side from where the box sits. Most important first, at most [limit].
List<GlassesSighting> sightingsFrom(
  List<Detection> detections, {
  int limit = 2,
}) {
  final found = <(GlassesSighting, double)>[];
  for (final d in detections) {
    final kind = obstacleKindForLabel(d.label);
    if (kind == null) continue;
    final box = d.box;
    final area = box.width * box.height;
    // Far away and small: not worth interrupting the user for.
    if (area < 0.04 && box.bottom < 0.6) continue;
    final center = box.center.dx;
    found.add((
      GlassesSighting(
        kind: kind,
        direction: center < 0.35
            ? ObstacleDirection.left
            : center > 0.65
            ? ObstacleDirection.right
            : ObstacleDirection.ahead,
        veryClose: area > 0.3 || (box.bottom > 0.92 && box.height > 0.5),
      ),
      area,
    ));
  }
  found.sort((a, b) {
    final risk = b.$1.kind.risk.index.compareTo(a.$1.kind.risk.index);
    return risk != 0 ? risk : b.$2.compareTo(a.$2);
  });
  return [for (final (sighting, _) in found.take(limit)) sighting];
}
