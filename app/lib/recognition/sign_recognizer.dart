import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../data/vocabulary.dart';

class SignPrediction {
  const SignPrediction({required this.sign, required this.confidence});

  final SignWord sign;

  /// 0..1, how sure the model is.
  final double confidence;
}

/// What the recognizer is doing right now, shown to the child as a hint.
enum SignStatus {
  /// No hand in the signing space.
  waiting,

  /// A sign is being watched; it ends when the hands are lowered.
  watching,

  /// The last sign was not recognized confidently.
  unsure,
}

/// Turns camera frames into recognized signs.
abstract class SignRecognizer {
  /// Loads the models. Returns false when recognition is unavailable on this
  /// device (e.g. no native landmark support yet).
  Future<bool> initialize();

  /// True once [initialize] succeeded.
  bool get isReady;

  /// One event per recognized sign.
  Stream<SignPrediction> get predictions;

  ValueListenable<SignStatus> get status;

  /// Why recognition is not running, or null when it is. Shown to testers so
  /// "it doesn't work on my phone" comes back as an actual cause.
  String? get unavailableReason;

  /// Device and live counters for the diagnostics dialog.
  Future<Map<String, String>> diagnostics();

  Future<void> processFrame(CameraImage image, CameraDescription camera);

  Future<void> dispose();
}

/// Stand-in with no model (tests, platforms without landmark support). It
/// never reads frames, but [simulate] lets demos and tests drive the flow.
class PendingSignRecognizer implements SignRecognizer {
  final _predictions = StreamController<SignPrediction>.broadcast();
  final _status = ValueNotifier(SignStatus.waiting);

  @override
  Future<bool> initialize() async => false;

  @override
  bool get isReady => false;

  @override
  Stream<SignPrediction> get predictions => _predictions.stream;

  @override
  ValueListenable<SignStatus> get status => _status;

  @override
  String? get unavailableReason => 'no sign model in this build';

  @override
  Future<Map<String, String>> diagnostics() async => {
    'recognition': 'unavailable',
    'reason': unavailableReason!,
  };

  @override
  Future<void> processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {}

  void simulate(SignWord sign) {
    _predictions.add(SignPrediction(sign: sign, confidence: 1));
  }

  @override
  Future<void> dispose() async {
    _status.dispose();
    await _predictions.close();
  }
}
