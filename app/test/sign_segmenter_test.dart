import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:baseera/recognition/sign_features.dart';
import 'package:baseera/recognition/sign_segmenter.dart';

/// A frame with one hand whose wrist sits at [wristY] (shoulder units).
BodyFrame handAt(double wristY) {
  final hands = Float64List(84);
  for (var p = 0; p < 21; p++) {
    hands[p * 2 + 1] = wristY - p * 0.01;
  }
  return BodyFrame(Float64List(22), hands, [true, false]);
}

BodyFrame noHands() =>
    BodyFrame(Float64List(22), Float64List(84), [false, false]);

void main() {
  test('a raised hand starts a sign and lowering it ends the sign', () {
    final segmenter = SignSegmenter(quietFrames: 3, minFrames: 3);
    expect(segmenter.add(handAt(3)), isNull, reason: 'resting hand is ignored');
    expect(segmenter.isCollecting, isFalse);

    for (var i = 0; i < 5; i++) {
      expect(segmenter.add(handAt(0.2)), isNull);
    }
    expect(segmenter.isCollecting, isTrue);

    expect(segmenter.add(noHands()), isNull);
    expect(segmenter.add(null), isNull);
    final sign = segmenter.add(handAt(3));
    expect(sign, hasLength(5));
    expect(segmenter.isCollecting, isFalse);
  });

  test('a brief detection gap does not split a sign', () {
    final segmenter = SignSegmenter(quietFrames: 3, minFrames: 3);
    for (var i = 0; i < 4; i++) {
      segmenter.add(handAt(0));
    }
    segmenter.add(null); // hand lost for one frame
    for (var i = 0; i < 4; i++) {
      expect(segmenter.add(handAt(0)), isNull);
    }
    segmenter.add(null);
    segmenter.add(null);
    expect(segmenter.add(null), hasLength(8));
  });

  test('flickers shorter than minFrames are dropped', () {
    final segmenter = SignSegmenter(quietFrames: 2, minFrames: 3);
    segmenter.add(handAt(0));
    segmenter.add(null);
    expect(segmenter.add(null), isNull);
    expect(segmenter.isCollecting, isFalse);
  });

  test('very long signing is cut at maxFrames', () {
    final segmenter = SignSegmenter(maxFrames: 10);
    List<BodyFrame>? sign;
    for (var i = 0; i < 10; i++) {
      sign = segmenter.add(handAt(0));
    }
    expect(sign, hasLength(10));
  });

  test('resampling spreads 24 indices over any length', () {
    expect(resampleIndices(1), List.filled(24, 0));
    final idx = resampleIndices(10);
    expect(idx.first, 0);
    expect(idx.last, 9);
    expect(idx, orderedEquals([...idx]..sort()));
    expect(resampleIndices(24), List.generate(24, (i) => i));
  });
}
