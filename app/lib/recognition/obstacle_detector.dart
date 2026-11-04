import 'dart:typed_data';

import '../services/glasses/glasses_link.dart';

/// Finds obstacles in the glasses' camera frames.
abstract class ObstacleDetector {
  /// Loads the model. False when there is none (then only the distance
  /// sensors warn, on glasses that have them).
  Future<bool> initialize();

  /// Warnings found in one JPEG frame, most important first. [quarterTurns]
  /// turns the picture clockwise first, for a camera mounted on its side.
  Future<List<GlassesSighting>> detect(Uint8List jpeg, {int quarterTurns = 0});

  Future<void> dispose();
}

/// No model in this build (web preview, tests).
class NoObstacleDetector implements ObstacleDetector {
  const NoObstacleDetector();

  @override
  Future<bool> initialize() async => false;

  @override
  Future<List<GlassesSighting>> detect(
    Uint8List jpeg, {
    int quarterTurns = 0,
  }) async => const [];

  @override
  Future<void> dispose() async {}
}
