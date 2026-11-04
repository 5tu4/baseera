import 'dart:typed_data';
import 'dart:ui';

import 'package:baseera/data/obstacles.dart';
import 'package:baseera/recognition/obstacle_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Raw output in the Ultralytics TFLite layout [1, 4+classes, boxes].
List<double> channelsFirst(List<List<double>> boxes) => [
  for (var c = 0; c < boxes.first.length; c++)
    for (final box in boxes) box[c],
];

void main() {
  // A 320×240 glasses frame in a 320×320 input: 40 px of grey above and below.
  final letterbox = Letterbox(
    sourceWidth: 320,
    sourceHeight: 240,
    inputSize: 320,
  );
  const labels = ['person', 'chair'];

  test('letterbox maps input pixels back to the camera frame', () {
    expect(letterbox.scale, 1);
    expect(letterbox.padY, 40);
    final box = letterbox.toSource(0, 40, 320, 280);
    expect(box, const Rect.fromLTRB(0, 0, 1, 1));
  });

  test('decodes normalized boxes, picks the best class, drops weak ones', () {
    final out = channelsFirst([
      // cx, cy, w, h (0..1 of the input), person, chair
      [0.5, 0.5, 0.25, 0.5, 0.9, 0.1],
      [0.2, 0.5, 0.1, 0.1, 0.2, 0.3], // too weak
      [0.8, 0.5, 0.2, 0.25, 0.05, 0.7],
    ]);
    final found = decodeYolo(
      out,
      shape: [1, 6, 3],
      labels: labels,
      letterbox: letterbox,
    );
    expect(found.map((d) => d.label), ['person', 'chair']);
    final person = found.first.box;
    expect(person.left, closeTo(0.375, 1e-6));
    expect(person.width, closeTo(0.25, 1e-6));
    // 160 px tall in the input = 160/240 of the frame.
    expect(person.height, closeTo(160 / 240, 1e-6));
  });

  test('pixel units and the transposed layout decode the same', () {
    final rows = [
      [160.0, 160.0, 80.0, 160.0, 0.9, 0.1],
    ];
    final transposed = [for (final r in rows) ...r];
    final found = decodeYolo(
      transposed,
      shape: [1, 1, 6],
      labels: labels,
      letterbox: letterbox,
    );
    expect(found.single.box.left, closeTo(0.375, 1e-6));
    expect(found.single.box.height, closeTo(160 / 240, 1e-6));
  });

  test('overlapping boxes of the same object are merged', () {
    final out = channelsFirst([
      [0.5, 0.5, 0.4, 0.4, 0.9, 0],
      [0.51, 0.5, 0.4, 0.4, 0.8, 0],
      [0.5, 0.5, 0.4, 0.4, 0, 0.6], // a chair in the same place is kept
    ]);
    final found = decodeYolo(
      out,
      shape: [1, 6, 3],
      labels: labels,
      letterbox: letterbox,
    );
    expect(found.map((d) => d.label), ['person', 'chair']);
    expect(found.first.score, 0.9);
  });

  test('a shape that does not fit the labels is refused', () {
    expect(
      () => decodeYolo(
        Float32List(30),
        shape: [1, 5, 7],
        labels: labels,
        letterbox: letterbox,
      ),
      throwsArgumentError,
    );
  });

  group('sightings', () {
    Detection d(String label, Rect box) => Detection(label, 0.9, box);

    test('side comes from where the box sits', () {
      final s = sightingsFrom([
        d('chair', const Rect.fromLTRB(0.0, 0.5, 0.3, 0.9)),
      ]);
      expect(s.single.kind, ObstacleKind.chair);
      expect(s.single.direction, ObstacleDirection.left);
      expect(
        sightingsFrom([
          d('chair', const Rect.fromLTRB(0.7, 0.5, 1.0, 0.9)),
        ]).single.direction,
        ObstacleDirection.right,
      );
    });

    test('small things far away are ignored, big near ones are very close', () {
      expect(
        sightingsFrom([d('person', const Rect.fromLTRB(0.45, 0.2, 0.5, 0.3))]),
        isEmpty,
      );
      final near = sightingsFrom([
        d('person', const Rect.fromLTRB(0.2, 0.1, 0.8, 0.98)),
      ]).single;
      expect(near.direction, ObstacleDirection.ahead);
      expect(near.veryClose, isTrue);
    });

    test('falls first, then moving things, then size; at most two', () {
      final s = sightingsFrom([
        d('chair', const Rect.fromLTRB(0.4, 0.3, 0.9, 0.9)),
        d('stairs', const Rect.fromLTRB(0.3, 0.6, 0.6, 0.8)),
        d('person', const Rect.fromLTRB(0.0, 0.2, 0.2, 0.9)),
        d('kite', const Rect.fromLTRB(0, 0, 1, 1)),
      ]);
      expect(s.map((x) => x.kind), [ObstacleKind.stairs, ObstacleKind.person]);
    });

    test('stock COCO labels map onto Baseera warnings', () {
      expect(obstacleKindForLabel('dining table'), ObstacleKind.table);
      expect(obstacleKindForLabel('truck'), ObstacleKind.car);
      expect(obstacleKindForLabel('Person'), ObstacleKind.person);
      expect(obstacleKindForLabel('kite'), isNull);
    });
  });

  test('turning the picture moves pixels clockwise', () {
    // A 4 x 2 picture; its top-left and top-right corners.
    expect(turnPixel(0, 0, 4, 2, 0), (0, 0));
    expect(turnPixel(0, 0, 4, 2, 1), (1, 0), reason: 'top-left -> top-right');
    expect(turnPixel(3, 0, 4, 2, 1), (
      1,
      3,
    ), reason: 'top-right -> bottom-right');
    expect(turnPixel(0, 0, 4, 2, 2), (3, 1));
    expect(turnPixel(0, 0, 4, 2, 3), (0, 3), reason: 'top-left -> bottom-left');
    expect(turnPixel(1, 1, 4, 2, 5), turnPixel(1, 1, 4, 2, 1));
  });
}
