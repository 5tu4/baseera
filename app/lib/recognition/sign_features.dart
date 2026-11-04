import 'dart:math' as math;
import 'dart:typed_data';

/// Dart port of the feature code in `ml/common.py`. The model only works if
/// both produce the same numbers; `test/sign_features_test.dart` checks this
/// against a fixture exported by `ml/train.py export`.

/// Pose landmarks kept: nose, eyes, mouth corners, shoulders, elbows, wrists.
const poseIndices = [0, 2, 5, 9, 10, 11, 12, 13, 14, 15, 16];
const seqLen = 24;
const featureCount = 192;
const _lShoulder = 11, _rShoulder = 12, _lWrist = 15, _rWrist = 16;

/// One camera frame's raw MediaPipe output, in normalized 0..1 coordinates.
class LandmarkFrame {
  const LandmarkFrame({
    required this.pose,
    required this.hands,
    required this.width,
    required this.height,
  });

  /// 33 pose landmarks as x0, y0, x1, y1, ... or null when no body is seen.
  final Float64List? pose;

  /// Up to two hands, each 21 landmarks as x0, y0, x1, y1, ...
  final List<Float64List> hands;
  final int width;
  final int height;
}

/// A frame centered on the shoulders and scaled by shoulder width, with each
/// hand assigned to the side of the nearer pose wrist.
class BodyFrame {
  BodyFrame(this.pose, this.hands, this.present);

  /// 11 × (x, y).
  final Float64List pose;

  /// 2 slots × 21 × (x, y); zeros when the slot's hand is missing.
  final Float64List hands;

  /// Whether slot 0 / slot 1 holds a hand.
  final List<bool> present;

  bool get anyHand => present[0] || present[1];

  /// Wrist height of the higher visible hand (y grows downwards), or null.
  double? get highestWristY {
    double? best;
    for (var slot = 0; slot < 2; slot++) {
      if (!present[slot]) continue;
      final y = hands[slot * 42 + 1];
      if (best == null || y < best) best = y;
    }
    return best;
  }
}

/// Mirrors `normalize_frame` / `normalize_sequence`: remembers the last seen
/// pose so a frame without a detected body still gets normalized.
class BodyNormalizer {
  Float64List? _lastPose;

  void reset() => _lastPose = null;

  BodyFrame? normalize(LandmarkFrame frame) {
    final pose = frame.pose ?? _lastPose;
    if (pose == null) return null;
    _lastPose = pose;

    final w = frame.width.toDouble(), h = frame.height.toDouble();
    double px(int i) => pose[i * 2] * w;
    double py(int i) => pose[i * 2 + 1] * h;

    final ox = (px(_lShoulder) + px(_rShoulder)) / 2;
    final oy = (py(_lShoulder) + py(_rShoulder)) / 2;
    final shoulder = _dist(
      px(_lShoulder),
      py(_lShoulder),
      px(_rShoulder),
      py(_rShoulder),
    );
    final unit = math.max(shoulder, 1e-3);

    final pose11 = Float64List(poseIndices.length * 2);
    for (var k = 0; k < poseIndices.length; k++) {
      pose11[k * 2] = (px(poseIndices[k]) - ox) / unit;
      pose11[k * 2 + 1] = (py(poseIndices[k]) - oy) / unit;
    }

    final hands = Float64List(2 * 21 * 2);
    final present = [false, false];
    final detected = frame.hands.take(2).toList();
    final wrists = [
      [px(_lWrist), py(_lWrist)],
      [px(_rWrist), py(_rWrist)],
    ];
    double wristDist(Float64List hand, int slot) =>
        _dist(hand[0] * w, hand[1] * h, wrists[slot][0], wrists[slot][1]);

    List<int> slots;
    if (detected.length == 1) {
      slots = [wristDist(detected[0], 0) <= wristDist(detected[0], 1) ? 0 : 1];
    } else if (detected.length == 2) {
      final straight = wristDist(detected[0], 0) + wristDist(detected[1], 1);
      final crossed = wristDist(detected[0], 1) + wristDist(detected[1], 0);
      slots = straight <= crossed ? [0, 1] : [1, 0];
    } else {
      slots = const [];
    }
    for (var j = 0; j < slots.length; j++) {
      final hand = detected[j];
      final base = slots[j] * 42;
      for (var p = 0; p < 21; p++) {
        hands[base + p * 2] = (hand[p * 2] * w - ox) / unit;
        hands[base + p * 2 + 1] = (hand[p * 2 + 1] * h - oy) / unit;
      }
      present[slots[j]] = true;
    }
    return BodyFrame(pose11, hands, present);
  }
}

/// Nearest-frame indices spreading [length] samples over [n] frames.
List<int> resampleIndices(int n, [int length = seqLen]) {
  if (n == 1) return List.filled(length, 0);
  final step = (n - 1) / (length - 1);
  return [
    for (var i = 0; i < length; i++)
      i == length - 1 ? n - 1 : (i * step + 0.5).floor(),
  ];
}

/// The model input for one sign: [seqLen] × [featureCount], row-major.
Float32List sampleFeatures(List<BodyFrame> frames) {
  final idx = resampleIndices(frames.length);
  final out = Float32List(seqLen * featureCount);
  for (var t = 0; t < seqLen; t++) {
    _frameFeatures(frames[idx[t]], out, t * featureCount);
  }
  return out;
}

void _frameFeatures(BodyFrame f, Float32List out, int offset) {
  var o = offset;
  for (final v in f.pose) {
    out[o++] = v;
  }
  for (var slot = 0; slot < 2; slot++) {
    final present = f.present[slot];
    out[o++] = present ? 1 : 0;
    final base = slot * 42;
    for (var i = 0; i < 42; i++) {
      out[o++] = present ? f.hands[base + i] : 0;
    }
    final wx = f.hands[base], wy = f.hands[base + 1];
    final size = math.max(
      _dist(wx, wy, f.hands[base + 18], f.hands[base + 19]),
      1e-3,
    );
    for (var p = 0; p < 21; p++) {
      out[o++] = present ? (f.hands[base + p * 2] - wx) / size : 0;
      out[o++] = present ? (f.hands[base + p * 2 + 1] - wy) / size : 0;
    }
  }
}

double _dist(double ax, double ay, double bx, double by) {
  final dx = ax - bx, dy = ay - by;
  return math.sqrt(dx * dx + dy * dy);
}
