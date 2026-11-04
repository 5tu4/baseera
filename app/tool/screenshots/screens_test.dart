// Phone-size screenshots for client meetings, with the camera and microphone
// faked so the screens show what they do on a phone. Kept out of test/ so it
// isn't part of the normal suite. From app/:
//   flutter test tool/screenshots/screens_test.dart --update-goldens
// Output: build/screens/pdf/*.png
// ignore_for_file: depend_on_referenced_packages, invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baseera/app.dart';
import 'package:baseera/data/obstacles.dart';
import 'package:baseera/data/phrases.dart';
import 'package:baseera/data/vocabulary.dart';
import 'package:baseera/recognition/sign_recognizer.dart';
import 'package:baseera/services/app_scope.dart';
import 'package:baseera/services/glasses/glasses_controller.dart';
import 'package:baseera/services/glasses/glasses_link.dart';
import 'package:baseera/services/phrases_store.dart';
import 'package:baseera/services/settings_controller.dart';
import 'package:baseera/services/tts_service.dart';
import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

const _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

ui.Image? _cameraImage;

class _FakeCamera extends CameraPlatform with MockPlatformInterfaceMixin {
  final _initialized = StreamController<CameraInitializedEvent>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async => [_front];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings? mediaSettings,
  ) async => 1;

  @override
  Future<int> createCamera(
    CameraDescription cameraDescription,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = false,
  }) async => 1;

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      _initialized.stream;

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    scheduleMicrotask(
      () => _initialized.add(
        const CameraInitializedEvent(
          1,
          640,
          480,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      ),
    );
  }

  @override
  Stream<CameraResolutionChangedEvent> onCameraResolutionChanged(int id) =>
      const Stream.empty();
  @override
  Stream<CameraClosingEvent> onCameraClosing(int id) => const Stream.empty();
  @override
  Stream<CameraErrorEvent> onCameraError(int id) => const Stream.empty();
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  bool supportsImageStreaming() => true;
  @override
  Stream<CameraImageData> onStreamedFrameAvailable(
    int cameraId, {
    CameraImageStreamOptions? options,
  }) => const Stream.empty();
  @override
  Future<void> lockCaptureOrientation(
    int cameraId,
    DeviceOrientation orientation,
  ) async {}
  @override
  Future<void> unlockCaptureOrientation(int cameraId) async {}
  @override
  Future<void> pausePreview(int cameraId) async {}
  @override
  Future<void> resumePreview(int cameraId) async {}
  @override
  Future<void> dispose(int cameraId) async {}
  @override
  Future<double> getMinZoomLevel(int cameraId) async => 1;
  @override
  Future<double> getMaxZoomLevel(int cameraId) async => 1;

  @override
  Widget buildPreview(int cameraId) => RawImage(
    image: _cameraImage,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.high,
  );
}

class _FakeSpeech extends SpeechToTextPlatform with MockPlatformInterfaceMixin {
  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> initialize({
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async => true;

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<List<dynamic>> locales() async => ['ar_SA:Arabic'];

  void say(String words, {bool done = true}) {
    onTextRecognition!(
      jsonEncode(
        SpeechRecognitionResult.init([
          SpeechRecognitionWords(words, null, 0.9),
        ], done ? ResultType.finalResult : ResultType.partial).toJson(),
      ),
    );
    if (done) onStatus!('done');
  }
}

class _Recognizer implements SignRecognizer {
  final _predictions = StreamController<SignPrediction>.broadcast(sync: true);
  final _status = ValueNotifier(SignStatus.waiting);

  void emit(String id) => _predictions.add(
    SignPrediction(
      sign: vocabulary.firstWhere((w) => w.id == id),
      confidence: 0.93,
    ),
  );

  @override
  Future<bool> initialize() async => true;
  @override
  bool get isReady => true;
  @override
  Stream<SignPrediction> get predictions => _predictions.stream;
  @override
  ValueListenable<SignStatus> get status => _status;
  @override
  String? get unavailableReason => null;
  @override
  Future<Map<String, String>> diagnostics() async => {};
  @override
  Future<void> processFrame(CameraImage image, CameraDescription camera) async {}
  @override
  Future<void> dispose() async {}
}

class _Link implements GlassesLink {
  final _events = StreamController<GlassesEvent>.broadcast(sync: true);
  @override
  Stream<GlassesEvent> get events => _events.stream;
  @override
  Future<void> connect() async {
    _events.add(const GlassesLinkChanged(GlassesConnection.connected));
    _events.add(const GlassesStatus(battery: 82, frontCm: 180, downCm: 96));
  }

  void emit(GlassesEvent e) => _events.add(e);
  @override
  Future<void> disconnect() async {}
  @override
  void send(Map<String, Object?> command) {}
  @override
  Future<void> dispose() => _events.close();
}

Future<ByteData> _file(String path) async =>
    ByteData.sublistView(Uint8List.fromList(File(path).readAsBytesSync()));

void main() {
  final speech = _FakeSpeech();

  setUpAll(() async {
    final plex = FontLoader('Plex');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      plex.addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-$w.ttf'));
    }
    await plex.load();
    await (FontLoader('MaterialIcons')..addFont(
          _file(
            'C:/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ),
        ))
        .load();
    CameraPlatform.instance = _FakeCamera();
    SpeechToTextPlatform.instance = speech;
  });

  late _Recognizer recognizer;

  Future<(AppServices, _Link)> boot(
    WidgetTester tester, {
    UserMode? mode,
    ThemeMode theme = ThemeMode.light,
  }) async {
    _cameraImage ??= await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('tool/screenshots/camera_sick.png').readAsBytesSync(),
      );
      return (await codec.getNextFrame()).image;
    });
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = SettingsController.memory()
      ..phoneSpeaksAlerts = false
      ..glassesDemo = false
      ..themeMode = theme
      ..isFemale = false
      ..name = 'عبدالله';
    if (mode != null) settings.userMode = mode;
    final tts = TtsService(settings);
    late _Link link;
    final phrases = PhrasesStore.memory()
      ..add(text: 'أحتاج كرسياً متحركاً', category: PhraseCategory.needs)
      ..add(text: 'اسمي عبدالله وعندي موعد', category: PhraseCategory.basics);
    final services = AppServices(
      settings: settings,
      tts: tts,
      phrases: phrases,
      glasses: GlassesController(
        settings: settings,
        tts: tts,
        createLink: ({required bool demo}) => link = _Link(),
      ),
      createRecognizer: () => recognizer = _Recognizer(),
      findCameras: () async => const [_front],
    );
    await tester.pumpWidget(BaseeraApp(services: services));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return (services, link);
  }

  // Pictures decode off the test clock: load them before each shot.
  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/screens/pdf/$name.png'),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('onboarding', (tester) async {
    await boot(tester);
    await shot(tester, '01_onboarding');
    await tester.tap(find.text('أصم أو ضعيف سمع'));
    await settle(tester);
    await shot(tester, '02_about_you');
  });

  testWidgets('sign', (tester) async {
    await boot(tester, mode: UserMode.deaf);
    await settle(tester);
    recognizer.emit('salam');
    await settle(tester);
    recognizer.emit('sick');
    await settle(tester);
    await shot(tester, '03_sign');
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await settle(tester);
    await shot(tester, '04_signs_sheet');
  });

  testWidgets('listen', (tester) async {
    await boot(tester, mode: UserMode.deaf);
    await tester.tap(find.widgetWithText(NavigationDestination, 'أقرأ كلامك'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await settle(tester);
    speech.say('السلام عليكم، كيف أقدر أخدمك؟');
    await settle(tester);
    speech.say('موعدك مع الدكتور الساعة عشرة');
    await settle(tester);
    speech.say('تفضل انتظر في الصالة', done: false);
    await settle(tester);
    await shot(tester, '05_listen');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('voice', (tester) async {
    await boot(tester, mode: UserMode.deaf);
    await tester.tap(find.widgetWithText(NavigationDestination, 'صوتي'));
    await settle(tester);
    await shot(tester, '06_voice');
    await tester.tap(find.text('أضف كلمة'));
    await settle(tester);
    await shot(tester, '07_add_word');
  });

  testWidgets('companion glasses', (tester) async {
    final (services, link) = await boot(tester, mode: UserMode.companion);
    await tester.tap(find.widgetWithText(NavigationDestination, 'نظارتي'));
    await settle(tester);
    await services.glasses.connect();
    link.emit(
      GlassesFrame(File('tool/screenshots/glasses_view.jpg').readAsBytesSync()),
    );
    link.emit(
      const GlassesSighting(
        kind: ObstacleKind.person,
        direction: ObstacleDirection.ahead,
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    link.emit(
      const GlassesSighting(
        kind: ObstacleKind.chair,
        direction: ObstacleDirection.right,
      ),
    );
    await settle(tester);
    await shot(tester, '08_glasses');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await settle(tester);
    await shot(tester, '08b_glasses_alerts');
  });

  testWidgets('blind + dark', (tester) async {
    final (services, link) = await boot(
      tester,
      mode: UserMode.blind,
      theme: ThemeMode.dark,
    );
    await services.glasses.connect();
    link.emit(
      const GlassesSighting(
        kind: ObstacleKind.person,
        direction: ObstacleDirection.ahead,
        veryClose: true,
      ),
    );
    await settle(tester);
    await shot(tester, '09_blind_dark');
  });

  testWidgets('settings dark', (tester) async {
    await boot(tester, mode: UserMode.companion, theme: ThemeMode.dark);
    await tester.tap(find.byTooltip('الإعدادات'));
    await settle(tester);
    await shot(tester, '10_settings_dark');
  });
}
