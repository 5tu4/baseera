import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../recognition/sign_recognizer.dart';
import 'glasses/glasses_controller.dart';
import 'phrases_store.dart';
import 'settings_controller.dart';
import 'tts_service.dart';

/// App-wide services, created once in `main` and replaced with fakes in tests.
class AppServices {
  AppServices({
    required this.settings,
    required this.tts,
    required this.phrases,
    required this.glasses,
    required this.createRecognizer,
    this.findCameras = availableCameras,
  });

  final SettingsController settings;
  final TtsService tts;
  final PhrasesStore phrases;
  final GlassesController glasses;

  /// Each sign screen gets its own recognizer (and disposes it).
  final SignRecognizer Function() createRecognizer;

  /// The phone's cameras (replaced in tests, which have none).
  final Future<List<CameraDescription>> Function() findCameras;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
