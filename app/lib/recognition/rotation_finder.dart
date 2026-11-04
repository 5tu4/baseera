/// Camera frames arrive rotated differently on different devices and
/// platforms. Start from the platform's best guess and, when no body is found
/// for a while, try the next quarter turn until one works.
class RotationFinder {
  RotationFinder({required int initial, this.framesBeforeTurn = 20})
    : _rotation = initial % 360;

  /// How many body-less frames to accept before turning the image.
  final int framesBeforeTurn;

  int _rotation;
  int _misses = 0;
  bool _found = false;

  int get rotation => _rotation;

  /// True once a body was seen with the current rotation.
  bool get isSettled => _found;

  /// Feeds back whether the last frame produced a body. Returns true when the
  /// rotation just changed, so callers can drop what they had collected.
  bool report({required bool poseFound}) {
    if (poseFound) {
      _found = true;
      _misses = 0;
      return false;
    }
    if (_found || ++_misses < framesBeforeTurn) return false;
    _misses = 0;
    _rotation = (_rotation + 90) % 360;
    return true;
  }
}
