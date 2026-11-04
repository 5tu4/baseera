import 'package:flutter_test/flutter_test.dart';
import 'package:baseera/recognition/rotation_finder.dart';

void main() {
  test('turns the image until a body is found, then stays put', () {
    final finder = RotationFinder(initial: 90, framesBeforeTurn: 3);
    expect(finder.rotation, 90);

    expect(finder.report(poseFound: false), isFalse);
    expect(finder.report(poseFound: false), isFalse);
    expect(finder.report(poseFound: false), isTrue, reason: 'turns on the 3rd');
    expect(finder.rotation, 180);
    expect(finder.isSettled, isFalse);

    expect(finder.report(poseFound: true), isFalse);
    expect(finder.isSettled, isTrue);

    // A child stepping out of frame must not start turning the image again.
    for (var i = 0; i < 10; i++) {
      expect(finder.report(poseFound: false), isFalse);
    }
    expect(finder.rotation, 180);
  });

  test('wraps around after a full turn', () {
    final finder = RotationFinder(initial: 270, framesBeforeTurn: 1);
    expect(finder.report(poseFound: false), isTrue);
    expect(finder.rotation, 0);
    expect(finder.report(poseFound: false), isTrue);
    expect(finder.rotation, 90);
  });
}
