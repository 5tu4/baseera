import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:baseera/data/vocabulary.dart';
import 'package:baseera/recognition/sign_features.dart';

Float64List _flatten(List<dynamic> points) => Float64List.fromList([
  for (final point in points)
    for (final v in point as List) (v as num).toDouble(),
]);

void main() {
  final fixture = File('test/fixtures/sign_features.json');
  final labels = File('assets/model/labels.txt');

  test('Dart features match the Python training pipeline', () {
    final samples = jsonDecode(fixture.readAsStringSync()) as List;
    expect(samples, isNotEmpty);
    for (final sample in samples.cast<Map<String, dynamic>>()) {
      final normalizer = BodyNormalizer();
      final frames = <BodyFrame>[];
      for (final f in (sample['frames'] as List).cast<Map<String, dynamic>>()) {
        final body = normalizer.normalize(
          LandmarkFrame(
            pose: f['pose'] == null ? null : _flatten(f['pose'] as List),
            hands: [
              for (final hand in f['hands'] as List) _flatten(hand as List),
            ],
            width: f['width'] as int,
            height: f['height'] as int,
          ),
        );
        if (body != null) frames.add(body);
      }
      final actual = sampleFeatures(frames);
      final expected = [
        for (final row in sample['features'] as List)
          for (final v in row as List) (v as num).toDouble(),
      ];
      expect(actual.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        expect(
          actual[i],
          closeTo(expected[i], 1e-3),
          reason: '${sample['label']}: feature $i',
        );
      }
    }
  }, skip: fixture.existsSync() ? false : 'run `python ml/train.py export`');

  test('every model label is a sign in the app vocabulary', () {
    final ids = labels
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    expect(ids, hasLength(vocabulary.length));
    for (final id in ids) {
      expect(signById(id), isNotNull, reason: id);
    }
  }, skip: labels.existsSync() ? false : 'run `python ml/train.py export`');
}
