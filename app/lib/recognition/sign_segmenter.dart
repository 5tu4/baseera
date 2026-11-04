import 'sign_features.dart';

/// Splits the live stream of frames into single signs.
///
/// A sign starts when a hand rises into the signing space (wrist above
/// [activeBelow], in shoulder-width units with y pointing down) and ends once
/// the hands have been lowered or out of view for [quietFrames] frames — so
/// children are told to lower their hands after each sign.
class SignSegmenter {
  SignSegmenter({
    this.activeBelow = 1.8,
    this.quietFrames = 4,
    this.minFrames = 3,
    this.maxFrames = 48,
  });

  final double activeBelow;
  final int quietFrames;
  final int minFrames;

  /// Cuts overly long signing (≈4 s at 12 fps) so feedback never stalls.
  final int maxFrames;

  final _frames = <BodyFrame>[];
  int _quiet = 0;

  /// True while a sign is being collected.
  bool get isCollecting => _frames.isNotEmpty;

  bool isActive(BodyFrame? frame) {
    final wristY = frame?.highestWristY;
    return wristY != null && wristY < activeBelow;
  }

  /// Adds a frame (null when nothing was detected). Returns the frames of a
  /// finished sign, or null.
  List<BodyFrame>? add(BodyFrame? frame) {
    if (isActive(frame)) {
      _frames.add(frame!);
      _quiet = 0;
      return _frames.length >= maxFrames ? _finish() : null;
    }
    if (_frames.isEmpty) return null;
    return ++_quiet >= quietFrames ? _finish() : null;
  }

  void reset() {
    _frames.clear();
    _quiet = 0;
  }

  List<BodyFrame>? _finish() {
    final segment = List.of(_frames);
    reset();
    return segment.length >= minFrames ? segment : null;
  }
}
