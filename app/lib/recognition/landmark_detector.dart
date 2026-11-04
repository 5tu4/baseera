import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sign_features.dart';

/// Talks to the native MediaPipe hand + pose landmarkers
/// (android/.../LandmarkChannel.kt, ios/Runner/LandmarkChannel.swift).
/// Where they are missing, [init] returns the reason and the app says
/// recognition is unavailable.
class LandmarkDetector {
  static const _channel = MethodChannel('baseera/landmarks');

  /// Returns null when the models are ready, else why they are not — the
  /// text a tester can send us from the diagnostics dialog.
  Future<String?> init() async {
    try {
      final started = await _channel.invokeMethod<bool>('init') ?? false;
      return started ? null : 'native landmarker returned false';
    } on MissingPluginException {
      return 'no landmark support on this platform';
    } on PlatformException catch (e) {
      debugPrint('Landmark models failed to load: ${e.message}');
      return e.message ?? e.code;
    } catch (e) {
      debugPrint('Landmark models failed to load: $e');
      return '$e';
    }
  }

  /// Device and model details for the diagnostics dialog.
  Future<Map<String, String>> info() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('info');
      return {
        for (final entry in (info ?? const {}).entries)
          entry.key: '${entry.value}',
      };
    } catch (e) {
      return {'device': 'unknown ($e)'};
    }
  }

  /// [rotation]: degrees to turn the camera image upright.
  Future<LandmarkFrame?> detect(CameraImage image, int rotation) async {
    final frame = switch (image.planes.length) {
      // Android: YUV_420_888 (three planes).
      >= 3 => {
        'y': image.planes[0].bytes,
        'u': image.planes[1].bytes,
        'v': image.planes[2].bytes,
        'yRowStride': image.planes[0].bytesPerRow,
        'uvRowStride': image.planes[1].bytesPerRow,
        'uvPixelStride': image.planes[1].bytesPerPixel ?? 1,
      },
      // iOS: BGRA8888 (one plane).
      1 => {
        'bgra': image.planes[0].bytes,
        'bytesPerRow': image.planes[0].bytesPerRow,
      },
      _ => null,
    };
    if (frame == null) return null;
    final result = await _channel.invokeMapMethod<String, Object?>('detect', {
      'width': image.width,
      'height': image.height,
      'rotation': rotation,
      ...frame,
    });
    if (result == null) return null;
    return LandmarkFrame(
      pose: result['pose'] as Float64List?,
      hands: [for (final hand in result['hands']! as List) hand as Float64List],
      width: result['width']! as int,
      height: result['height']! as int,
    );
  }

  Future<void> close() async {
    try {
      await _channel.invokeMethod<void>('close');
    } on MissingPluginException {
      // Nothing to close off Android/iOS.
    }
  }
}
