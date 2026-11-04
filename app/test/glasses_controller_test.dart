import 'dart:async';
import 'dart:typed_data';

import 'package:baseera/data/obstacles.dart';
import 'package:baseera/l10n/app_language.dart';
import 'package:baseera/recognition/obstacle_detector.dart';
import 'package:baseera/services/glasses/glasses_controller.dart';
import 'package:baseera/services/glasses/glasses_link.dart';
import 'package:baseera/services/settings_controller.dart';
import 'package:baseera/services/tts_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLink implements GlassesLink {
  FakeLink({required this.demo});

  final bool demo;
  final _events = StreamController<GlassesEvent>.broadcast(sync: true);
  final sent = <Map<String, Object?>>[];
  int connects = 0;
  bool disposed = false;

  @override
  Stream<GlassesEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    connects++;
    emit(const GlassesLinkChanged(GlassesConnection.connected));
  }

  @override
  Future<void> disconnect() async =>
      emit(const GlassesLinkChanged(GlassesConnection.disconnected));

  @override
  void send(Map<String, Object?> command) => sent.add(command);

  void emit(GlassesEvent event) => _events.add(event);

  List<List<int>> get said => [
    for (final c in sent)
      if (c['t'] == 'say') (c['clips']! as List).cast<int>(),
  ];

  List<List<int>> get vibrations => [
    for (final c in sent)
      if (c['t'] == 'vib') (c['p']! as List).cast<int>(),
  ];

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
  }
}

class FakeDetector implements ObstacleDetector {
  FakeDetector(this.result);

  final List<GlassesSighting> result;
  int initialized = 0;
  int frames = 0;
  int? quarterTurns;
  Completer<void>? gate;

  @override
  Future<bool> initialize() async {
    initialized++;
    return true;
  }

  @override
  Future<List<GlassesSighting>> detect(
    Uint8List jpeg, {
    int quarterTurns = 0,
  }) async {
    frames++;
    this.quarterTurns = quarterTurns;
    await gate?.future;
    return result;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late SettingsController settings;
  late List<FakeLink> links;
  late DateTime now;
  late GlassesController glasses;

  FakeLink link() => links.last;

  GlassesController makeController({ObstacleDetector? detector}) =>
      GlassesController(
        settings: settings,
        tts: TtsService(settings),
        detector: detector ?? const NoObstacleDetector(),
        now: () => now,
        createLink: ({required bool demo}) {
          final link = FakeLink(demo: demo);
          links.add(link);
          return link;
        },
      );

  setUp(() {
    settings = SettingsController.memory()
      // The phone's voice needs the TTS plugin, which tests don't have.
      ..phoneSpeaksAlerts = false;
    links = [];
    now = DateTime(2026, 10, 8, 12);
    glasses = makeController();
  });

  tearDown(() => glasses.dispose());

  void later(int ms) => now = now.add(Duration(milliseconds: ms));

  /// Glasses with the speaker and distance sensors fitted (stage 2).
  Future<void> connectFull() async {
    await glasses.connect();
    link().emit(const GlassesStatus(caps: GlassesCaps.full));
  }

  test('connecting sends the warning settings and a short buzz', () async {
    await glasses.connect();
    expect(glasses.isConnected, isTrue);
    expect(link().sent.first, {
      't': 'config',
      'alertCm': 120,
      'voice': true,
      'vibrate': true,
    });
    expect(link().vibrations, [GlassesVibration.connected]);
    expect(link().said, isEmpty, reason: 'stage 1 glasses have no speaker');
  });

  test('stage 1: the glasses vibrate by urgency and never get clips', () async {
    await glasses.connect();
    link().emit(const GlassesStatus(battery: 80, caps: GlassesCaps.stage1));
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.chair,
        direction: ObstacleDirection.left,
      ),
    );
    later(2000);
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.person,
        direction: ObstacleDirection.right,
      ),
    );
    later(2000);
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.stairs,
        direction: ObstacleDirection.ahead,
      ),
    );
    expect(glasses.alerts, hasLength(3));
    expect(link().vibrations.skip(1), [
      GlassesVibration.still,
      GlassesVibration.moving,
      GlassesVibration.fall,
    ]);
    expect(link().said, isEmpty);
  });

  test('something very close ahead keeps pulsing between warnings', () async {
    await glasses.connect();
    const close = GlassesSighting(
      kind: ObstacleKind.person,
      direction: ObstacleDirection.ahead,
      veryClose: true,
    );
    link().emit(close);
    expect(link().vibrations.last, GlassesVibration.veryClose);
    final buzzes = link().vibrations.length;

    later(500);
    link().emit(close);
    expect(link().vibrations, hasLength(buzzes), reason: 'too soon');

    later(800);
    link().emit(close);
    expect(link().vibrations.last, GlassesVibration.closeAhead);
    expect(glasses.alerts, hasLength(1), reason: 'spoken once, pulsed again');

    later(1200);
    link().emit(close);
    expect(link().vibrations, hasLength(buzzes + 2));

    later(3000);
    link().emit(close);
    expect(glasses.alerts, hasLength(2), reason: 'said again after 4 s');
    expect(link().vibrations.last, GlassesVibration.veryClose);
  });

  test('with distance sensors the phone only adds the fall buzz', () async {
    await connectFull();
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.chair,
        direction: ObstacleDirection.ahead,
        veryClose: true,
      ),
    );
    expect(glasses.alerts, hasLength(1));
    expect(
      link().vibrations.skip(1),
      isEmpty,
      reason: 'the glasses pulse on their own',
    );
    expect(link().said.last, [
      ObstacleKind.chair.clip,
      ObstacleDirection.ahead.clip,
      GlassesClips.veryClose,
    ]);
  });

  test(
    'something close ahead is announced, then not repeated at once',
    () async {
      await connectFull();
      link().emit(const GlassesStatus(frontCm: 90, downCm: 95, battery: 80));
      expect(glasses.alerts, hasLength(1));
      expect(glasses.lastAlert!.text(AppLanguage.ar), 'عائق أمامك');
      expect(link().said.last, [
        ObstacleKind.obstacle.clip,
        ObstacleDirection.ahead.clip,
      ]);

      later(1000);
      link().emit(const GlassesStatus(frontCm: 80, downCm: 95));
      expect(glasses.alerts, hasLength(1), reason: 'within the cooldown');

      later(4500);
      link().emit(const GlassesStatus(frontCm: 50, downCm: 95));
      expect(glasses.alerts, hasLength(2));
      expect(glasses.lastAlert!.veryClose, isTrue);
      expect(glasses.lastAlert!.text(AppLanguage.ar), 'عائق أمامك، قريب جداً');
    },
  );

  test('a named object ahead replaces the generic warning', () async {
    await glasses.connect();
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.chair,
        direction: ObstacleDirection.ahead,
      ),
    );
    later(2000);
    link().emit(const GlassesStatus(frontCm: 90));
    expect(glasses.alerts.map((a) => a.kind), [ObstacleKind.chair]);
  });

  test('a drop in the floor interrupts and makes the glasses buzz', () async {
    await connectFull();
    for (final cm in [95, 96, 94, 95]) {
      link().emit(GlassesStatus(frontCm: 250, downCm: cm));
      later(100);
    }
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.person,
        direction: ObstacleDirection.left,
      ),
    );
    later(300);
    link().emit(const GlassesStatus(frontCm: 250, downCm: 170));
    expect(
      glasses.alerts.first.kind,
      ObstacleKind.person,
      reason: 'one high reading may be a bad echo',
    );
    later(100);
    link().emit(const GlassesStatus(frontCm: 250, downCm: 168));
    expect(glasses.alerts.first.kind, ObstacleKind.dropOff);
    expect(link().vibrations.last, GlassesVibration.fall);
  });

  test('a lower-risk warning does not talk over one still playing', () async {
    await glasses.connect();
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.car,
        direction: ObstacleDirection.right,
      ),
    );
    later(500);
    link().emit(
      const GlassesSighting(
        kind: ObstacleKind.chair,
        direction: ObstacleDirection.left,
      ),
    );
    expect(glasses.alerts.map((a) => a.kind), [ObstacleKind.car]);
  });

  test('muted warnings stay silent and the glasses are told so', () async {
    await connectFull();
    glasses.toggleAlerts();
    expect(settings.alertsOn, isFalse);
    expect(link().said.last, [GlassesClips.alertsOff]);
    expect(link().vibrations.last, GlassesVibration.alertsOff);
    expect(link().sent.where((c) => c['t'] == 'config').last, {
      't': 'config',
      'alertCm': 120,
      'voice': false,
      'vibrate': false,
    });

    link().emit(const GlassesStatus(frontCm: 40));
    expect(glasses.alerts, isEmpty);
  });

  test('changing the warning distance updates the glasses', () async {
    await glasses.connect();
    settings.alertDistanceCm = 200;
    expect(link().sent.last['alertCm'], 200);
  });

  test('low battery is announced once', () async {
    await connectFull();
    link().emit(const GlassesStatus(battery: 19));
    link().emit(const GlassesStatus(battery: 18));
    expect(
      link().said.where((c) => c.single == GlassesClips.batteryLow),
      hasLength(1),
    );
  });

  test('switching demo mode swaps the link and keeps the connection', () async {
    await glasses.connect();
    expect(link().demo, isTrue);
    settings.glassesDemo = false;
    await Future<void>.delayed(Duration.zero);
    expect(links, hasLength(2));
    expect(links.first.disposed, isTrue);
    expect(link().demo, isFalse);
    expect(link().connects, 1);
    expect(glasses.isConnected, isTrue);
  });

  testWidgets('a dropped link reconnects by itself, unless asked to stop', (
    tester,
  ) async {
    // Built inside the test so its retry timer runs on the test's clock.
    final glasses = makeController();
    addTearDown(glasses.dispose);
    await glasses.connect();
    link().emit(const GlassesLinkChanged(GlassesConnection.disconnected));
    expect(glasses.isConnected, isFalse);
    await tester.pump(GlassesController.reconnectDelay);
    expect(link().connects, 2);
    expect(glasses.isConnected, isTrue);

    await glasses.disconnect();
    await tester.pump(GlassesController.reconnectDelay * 2);
    expect(link().connects, 2);
  });

  test('camera frames go through the obstacle model, one at a time', () async {
    final detector = FakeDetector([
      const GlassesSighting(
        kind: ObstacleKind.door,
        direction: ObstacleDirection.left,
      ),
    ])..gate = Completer();
    final glasses = makeController(detector: detector);
    addTearDown(glasses.dispose);
    await glasses.connect();

    final frame = GlassesFrame(Uint8List(4));
    link().emit(frame);
    link().emit(frame); // arrives while the first is still being read
    await Future<void>.delayed(Duration.zero);
    expect(detector.frames, 1);
    expect(glasses.frame, isNotNull);

    detector.gate!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(glasses.lastAlert!.text(AppLanguage.ar), 'باب على يسارك');
    expect(detector.initialized, 1);
  });

  test('frames are turned the way the preview shows them', () async {
    final detector = FakeDetector(const []);
    final glasses = makeController(detector: detector);
    addTearDown(glasses.dispose);
    settings.cameraQuarterTurns = 5;
    expect(settings.cameraQuarterTurns, 1);
    await glasses.connect();
    link().emit(GlassesFrame(Uint8List(4)));
    await Future<void>.delayed(Duration.zero);
    expect(detector.quarterTurns, 1);
  });

  test('alert text and clips', () {
    final alert = ObstacleAlert(
      kind: ObstacleKind.stairsDown,
      direction: ObstacleDirection.right,
      veryClose: true,
      time: DateTime(2026),
    );
    expect(alert.text(AppLanguage.ar), 'درج نازل على يمينك، قريب جداً');
    expect(
      alert.text(AppLanguage.en),
      'Stairs going down on your right, very close',
    );
    expect(alert.clips, [2, 52, GlassesClips.veryClose]);
  });

  test('every clip number is unique', () {
    final clips = [
      for (final k in ObstacleKind.values) k.clip,
      for (final d in ObstacleDirection.values) d.clip,
      GlassesClips.veryClose,
      GlassesClips.connected,
      GlassesClips.disconnected,
      GlassesClips.batteryLow,
      GlassesClips.alertsOff,
      GlassesClips.alertsOn,
    ];
    expect(clips.toSet().length, clips.length);
  });

  test('status messages from the firmware are read leniently', () {
    final status = GlassesStatus.fromJson({
      't': 'status',
      'bat': 81.6,
      'front': 143,
      'down': null,
      'fw': '0.1.0',
    });
    expect(status.battery, 82);
    expect(status.frontCm, 143);
    expect(status.downCm, isNull);
    expect(status.firmware, '0.1.0');
    expect(status.caps, GlassesCaps.full, reason: '0.1 sent no caps');

    final stage1 = GlassesStatus.fromJson({
      't': 'status',
      'bat': 90,
      'fw': '0.2.0',
      'caps': {'spk': false, 'dist': false, 'btn': false},
    });
    expect(stage1.caps, GlassesCaps.stage1);
    expect(stage1.frontCm, isNull);
  });

  test('vibration patterns start with a buzz and fit the firmware', () {
    final patterns = [
      GlassesVibration.fall,
      GlassesVibration.veryClose,
      GlassesVibration.moving,
      GlassesVibration.still,
      GlassesVibration.closeAhead,
      GlassesVibration.connected,
      GlassesVibration.alertsOn,
      GlassesVibration.alertsOff,
      GlassesVibration.test,
    ];
    for (final p in patterns) {
      expect(p.length, inInclusiveRange(1, 16));
      expect(p.length.isOdd, isTrue, reason: 'ends on a buzz, not a gap');
      expect(p.every((ms) => ms >= 10 && ms <= 2000), isTrue);
    }
  });
}
