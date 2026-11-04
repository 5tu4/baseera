import 'dart:typed_data';

/// Puts camera frames back together from the pieces the glasses send over
/// Bluetooth (protocol in `glasses_link.dart`): the first piece of a frame
/// starts with `0x80 | id` and the JPEG's length (4 bytes, little-endian),
/// the others with `id`. A frame with a piece missing is dropped; the next
/// first piece starts over.
class BleFrameAssembler {
  static const maxFrameBytes = 200 * 1024;

  int _id = -1;
  int _length = 0;
  BytesBuilder? _bytes;

  /// Adds one piece; returns the JPEG when this piece completes it.
  Uint8List? add(List<int> piece) {
    if (piece.isEmpty) return null;
    final head = piece[0];
    if (head & 0x80 != 0) {
      reset();
      if (piece.length < 5) return null;
      final length =
          piece[1] | piece[2] << 8 | piece[3] << 16 | piece[4] << 24;
      if (length <= 0 || length > maxFrameBytes) return null;
      _id = head & 0x7F;
      _length = length;
      _bytes = BytesBuilder(copy: false)..add(piece.sublist(5));
    } else {
      final bytes = _bytes;
      if (bytes == null || head != _id) {
        reset(); // missed the start of this frame: wait for the next one
        return null;
      }
      bytes.add(piece.sublist(1));
    }

    final bytes = _bytes!;
    if (bytes.length < _length) return null;
    final jpeg = bytes.length == _length ? bytes.takeBytes() : null;
    reset();
    if (jpeg == null || !_looksLikeJpeg(jpeg)) return null;
    return jpeg;
  }

  void reset() {
    _id = -1;
    _length = 0;
    _bytes = null;
  }

  static bool _looksLikeJpeg(Uint8List b) =>
      b.length > 4 &&
      b[0] == 0xFF &&
      b[1] == 0xD8 &&
      b[b.length - 2] == 0xFF &&
      b[b.length - 1] == 0xD9;
}
