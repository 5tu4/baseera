import 'dart:typed_data';

import 'package:baseera/services/glasses/ble_frames.dart';
import 'package:flutter_test/flutter_test.dart';

/// Splits a JPEG into pieces the way the firmware does (link.cpp).
List<List<int>> pieces(List<int> jpeg, int id, {int room = 244}) {
  final out = <List<int>>[];
  var sent = 0;
  var first = true;
  while (sent < jpeg.length) {
    final head = first
        ? [
            0x80 | id,
            jpeg.length & 0xFF,
            (jpeg.length >> 8) & 0xFF,
            (jpeg.length >> 16) & 0xFF,
            (jpeg.length >> 24) & 0xFF,
          ]
        : [id];
    final n = (room - head.length).clamp(0, jpeg.length - sent);
    out.add([...head, ...jpeg.sublist(sent, sent + n)]);
    sent += n;
    first = false;
  }
  return out;
}

Uint8List fakeJpeg(int length, int seed) => Uint8List.fromList([
  0xFF,
  0xD8,
  for (var i = 0; i < length - 4; i++) (i * 7 + seed) & 0xFF,
  0xFF,
  0xD9,
]);

void main() {
  test('reassembles a frame from its pieces', () {
    final jpeg = fakeJpeg(7000, 1);
    final assembler = BleFrameAssembler();
    Uint8List? out;
    for (final p in pieces(jpeg, 5)) {
      out = assembler.add(p);
    }
    expect(out, jpeg);
  });

  test('drops a frame with a missing piece and recovers on the next', () {
    final assembler = BleFrameAssembler();
    final broken = pieces(fakeJpeg(3000, 2), 6)..removeAt(4);
    for (final p in broken) {
      expect(assembler.add(p), isNull);
    }
    final next = fakeJpeg(2500, 3);
    Uint8List? out;
    for (final p in pieces(next, 7)) {
      out = assembler.add(p);
    }
    expect(out, next);
  });

  test('ignores pieces of a frame whose start it never saw', () {
    final assembler = BleFrameAssembler();
    final missedStart = pieces(fakeJpeg(1500, 4), 8).skip(1);
    for (final p in missedStart) {
      expect(assembler.add(p), isNull);
    }
  });

  test('rejects data that is not a JPEG', () {
    final assembler = BleFrameAssembler();
    final notJpeg = List<int>.generate(600, (i) => i & 0xFF);
    Uint8List? out;
    for (final p in pieces(notJpeg, 9)) {
      out = assembler.add(p);
    }
    expect(out, isNull);
  });
}
