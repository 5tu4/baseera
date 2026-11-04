import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'recognition/obstacle_detector_factory.dart';
import 'recognition/recognizer_factory.dart';
import 'services/app_scope.dart';
import 'services/glasses/glasses_controller.dart';
import 'services/phrases_store.dart';
import 'services/settings_controller.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The camera panel and the big buttons are designed for an upright phone.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settings = await SettingsController.load();
  final phrases = await PhrasesStore.load();
  final tts = TtsService(settings);
  runApp(
    BaseeraApp(
      services: AppServices(
        settings: settings,
        tts: tts,
        phrases: phrases,
        glasses: GlassesController(
          settings: settings,
          tts: tts,
          detector: createObstacleDetector(),
        ),
        createRecognizer: createSignRecognizer,
      ),
    ),
  );
}
