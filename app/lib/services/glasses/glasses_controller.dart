import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/obstacles.dart';
import '../../recognition/obstacle_detector.dart';
import '../settings_controller.dart';
import '../tts_service.dart';
import 'glasses_link.dart';
import 'glasses_link_factory.dart';
import 'simulated_glasses_link.dart';

typedef GlassesLinkFactory = GlassesLink Function({required bool demo});

/// The demo, or the real glasses over Bluetooth (over Wi-Fi when [wifi]:
/// firmware built with LINK_BLUETOOTH 0).
GlassesLink defaultGlassesLink({required bool demo, bool wifi = false}) {
  if (demo) return SimulatedGlassesLink();
  return wifi ? createWifiGlassesLink() : createBluetoothGlassesLink();
}

/// Owns the connection to the glasses and decides what to warn about.
///
/// Warnings come from the obstacle model on the camera frames (what it is,
/// on which side, how close) and, on glasses that have them, the distance
/// sensors (something close ahead, the floor dropping away). This class
/// filters them so the user hears the important ones without a stream of
/// chatter: falls first, a cooldown per object and side, and no talking over
/// a warning that is still playing unless the new one matters more.
///
/// The phone speaks each warning; the glasses vibrate with a pattern that says
/// how urgent it is ([ObstacleAlert.vibration]), and keep pulsing while
/// something stays very close ahead. Glasses with distance sensors pulse on
/// their own for things ahead, so the phone then only adds the fall buzz.
class GlassesController extends ChangeNotifier {
  GlassesController({
    required SettingsController settings,
    required TtsService tts,
    GlassesLinkFactory? createLink,
    ObstacleDetector detector = const NoObstacleDetector(),
    DateTime Function()? now,
  }) : _settings = settings,
       _tts = tts,
       _createLink =
           createLink ??
           (({required bool demo}) =>
               defaultGlassesLink(demo: demo, wifi: settings.glassesWifi)),
       _detector = detector,
       _now = now ?? DateTime.now,
       _demo = settings.glassesDemo,
       _wifi = settings.glassesWifi {
    _attach(_createLink(demo: _demo));
    _lastConfig = _configKey();
    _settings.addListener(_onSettingsChanged);
  }

  static const maxAlerts = 30;
  static const lowBatteryPercent = 20;
  static const veryCloseCm = 60;
  static const reconnectDelay = Duration(seconds: 3);
  static const _repeatAfter = Duration(seconds: 4);
  static const _repeatFallAfter = Duration(seconds: 2);
  static const _talkingFor = Duration(milliseconds: 1500);
  static const closePulseEvery = Duration(milliseconds: 1200);

  final SettingsController _settings;
  final TtsService _tts;
  final GlassesLinkFactory _createLink;
  final ObstacleDetector _detector;
  final DateTime Function() _now;

  /// Null until the model has been tried (on the first frame).
  Future<bool>? _detectorReady;
  bool _detecting = false;

  late GlassesLink _link;
  StreamSubscription<GlassesEvent>? _subscription;
  bool _demo;
  bool _wifi;
  late String _lastConfig;
  Timer? _retry;
  bool _wantConnected = false;
  bool _warnedBattery = false;
  GlassesCaps _caps = GlassesCaps.stage1;
  DateTime? _lastVibrationAt;

  GlassesConnection _connection = GlassesConnection.disconnected;
  int? _battery;
  int? _frontCm;
  int? _downCm;
  String? _firmware;
  Uint8List? _frame;

  final List<ObstacleAlert> _alerts = [];
  final Map<String, DateTime> _lastSaid = {};
  DateTime? _lastAlertAt;
  DateTime? _lastAheadAt;
  ObstacleRisk _lastRisk = ObstacleRisk.still;
  double? _floorCm;
  int _dropReadings = 0;

  GlassesConnection get connection => _connection;
  bool get isConnected => _connection == GlassesConnection.connected;
  bool get isDemo => _demo;

  /// True once the user asked to connect; the link then retries by itself.
  bool get wantsConnection => _wantConnected;
  int? get battery => _battery;
  int? get frontCm => _frontCm;
  int? get downCm => _downCm;
  String? get firmware => _firmware;

  /// What the glasses have fitted, from their last status message.
  GlassesCaps get caps => _caps;
  bool get hasSpeaker => _caps.speaker;
  bool get hasDistanceSensors => _caps.distance;

  /// Latest camera frame, for the live preview.
  Uint8List? get frame => _frame;

  /// Newest first.
  List<ObstacleAlert> get alerts => List.unmodifiable(_alerts);
  ObstacleAlert? get lastAlert => _alerts.isEmpty ? null : _alerts.first;

  Future<void> connect() async {
    _wantConnected = true;
    _retry?.cancel();
    await _link.connect();
  }

  Future<void> disconnect() async {
    _wantConnected = false;
    _retry?.cancel();
    await _link.disconnect();
  }

  /// Mutes or unmutes warnings; the glasses confirm with a buzz (and a clip
  /// when they have a speaker). The screens say it on the phone.
  void toggleAlerts() {
    final on = !_settings.alertsOn;
    _settings.alertsOn = on;
    _link.send(
      GlassesCommands.vibrate(
        on ? GlassesVibration.alertsOn : GlassesVibration.alertsOff,
      ),
    );
    if (hasSpeaker) {
      _link.send(
        GlassesCommands.say([
          on ? GlassesClips.alertsOn : GlassesClips.alertsOff,
        ]),
      );
    }
  }

  /// A sample warning through whatever speaks: the glasses' speaker, or the
  /// phone when the glasses have none.
  void testSound() {
    if (hasSpeaker) {
      _link.send(
        GlassesCommands.say([
          ObstacleKind.obstacle.clip,
          ObstacleDirection.ahead.clip,
        ]),
      );
      return;
    }
    final sample = ObstacleAlert(
      kind: ObstacleKind.obstacle,
      direction: ObstacleDirection.ahead,
      veryClose: false,
      time: _now(),
    );
    _tts.speak(sample.text(_settings.language), id: 'glasses-test');
  }

  void testVibration() =>
      _link.send(GlassesCommands.vibrate(GlassesVibration.test));

  void _attach(GlassesLink link) {
    _link = link;
    _subscription = link.events.listen(_onEvent);
  }

  Future<void> _swapLink() async {
    final reconnect = _wantConnected;
    _retry?.cancel();
    await _subscription?.cancel();
    final old = _link;
    _attach(_createLink(demo: _demo));
    _connection = GlassesConnection.disconnected;
    _resetReadings();
    notifyListeners();
    unawaited(old.dispose());
    if (reconnect) await connect();
  }

  void _onSettingsChanged() {
    if (_settings.glassesDemo != _demo || _settings.glassesWifi != _wifi) {
      _demo = _settings.glassesDemo;
      _wifi = _settings.glassesWifi;
      _swapLink();
      return;
    }
    final config = _configKey();
    if (config == _lastConfig) return;
    _lastConfig = config;
    if (isConnected) _sendConfig();
  }

  String _configKey() =>
      '${_settings.alertDistanceCm}/${_settings.alertsOn}/'
      '${_settings.glassesVoice}/${_settings.glassesVibration}';

  /// Muting warnings also stops the glasses' own vibration.
  void _sendConfig() => _link.send(
    GlassesCommands.config(
      alertCm: _settings.alertDistanceCm,
      voice: _settings.alertsOn && _settings.glassesVoice,
      vibrate: _settings.alertsOn && _settings.glassesVibration,
    ),
  );

  void _onEvent(GlassesEvent event) {
    switch (event) {
      case GlassesLinkChanged(:final state):
        _onConnection(state);
      case GlassesStatus():
        _onStatus(event);
      case GlassesFrame(:final jpeg):
        _frame = jpeg;
        notifyListeners();
        _detect(jpeg);
      case GlassesSighting():
        _raise(
          ObstacleAlert(
            kind: event.kind,
            direction: event.direction,
            veryClose: event.veryClose,
            time: _now(),
          ),
        );
        if (event.veryClose && event.direction == ObstacleDirection.ahead) {
          _pulseCloseAhead();
        }
    }
  }

  /// Something stays very close ahead: keep pulsing between the spoken
  /// warnings, like a parking sensor. Glasses with a front distance sensor
  /// do this themselves.
  void _pulseCloseAhead() {
    if (!_settings.alertsOn || !_settings.glassesVibration) return;
    if (hasDistanceSensors) return;
    final now = _now();
    final last = _lastVibrationAt;
    if (last != null && now.difference(last) < closePulseEvery) return;
    _lastVibrationAt = now;
    _link.send(GlassesCommands.vibrate(GlassesVibration.closeAhead));
  }

  /// Runs the obstacle model on a frame. Frames that arrive while the last
  /// one is still being read are skipped, so warnings never lag behind.
  Future<void> _detect(Uint8List jpeg) async {
    if (_detecting || !_settings.alertsOn) return;
    _detecting = true;
    try {
      if (!await (_detectorReady ??= _detector.initialize())) return;
      final sightings = await _detector.detect(
        jpeg,
        quarterTurns: _settings.cameraQuarterTurns,
      );
      for (final sighting in sightings) {
        _onEvent(sighting);
      }
    } catch (e) {
      debugPrint('Obstacle detection failed: $e');
    } finally {
      _detecting = false;
    }
  }

  void _onConnection(GlassesConnection state) {
    final was = _connection;
    _connection = state;
    if (state == GlassesConnection.connected) {
      _sendConfig();
      if (was != state) {
        _link.send(GlassesCommands.vibrate(GlassesVibration.connected));
      }
      if (hasSpeaker) _link.send(GlassesCommands.say([GlassesClips.connected]));
      if (was != state) _announce('تم الاتصال بالنظارة', 'Glasses connected');
    } else if (state == GlassesConnection.disconnected) {
      _resetReadings();
      if (was == GlassesConnection.connected) {
        _announce('انقطع الاتصال بالنظارة', 'Glasses disconnected');
      }
      if (_wantConnected) {
        _retry?.cancel();
        _retry = Timer(reconnectDelay, () {
          if (_wantConnected) _link.connect();
        });
      }
    }
    notifyListeners();
  }

  void _onStatus(GlassesStatus status) {
    _battery = status.battery ?? _battery;
    _frontCm = status.frontCm;
    _downCm = status.downCm;
    _firmware = status.firmware ?? _firmware;
    _caps = status.caps ?? _caps;

    final battery = _battery;
    if (battery != null && battery <= lowBatteryPercent && !_warnedBattery) {
      _warnedBattery = true;
      if (hasSpeaker) {
        _link.send(GlassesCommands.say([GlassesClips.batteryLow]));
      }
      _announce('بطارية النظارة منخفضة', 'Glasses battery is low');
    } else if (battery != null && battery > lowBatteryPercent + 5) {
      _warnedBattery = false;
    }

    _checkForDrop(status.downCm);

    // Something is close ahead. The obstacle model names it when it can;
    // this generic warning covers what the model does not recognize.
    final front = status.frontCm;
    if (front != null && front < _settings.alertDistanceCm) {
      _raise(
        ObstacleAlert(
          kind: ObstacleKind.obstacle,
          direction: ObstacleDirection.ahead,
          veryClose: front < veryCloseCm,
          time: _now(),
        ),
        generic: true,
      );
    }
    notifyListeners();
  }

  /// The downward sensor reads the floor at a steady distance. A sudden,
  /// sustained jump means the floor dropped away: stairs, a curb, a hole.
  void _checkForDrop(int? downCm) {
    if (downCm == null) return;
    final floor = _floorCm;
    if (floor == null) {
      _floorCm = downCm.toDouble();
      return;
    }
    if (downCm > floor * 1.35 + 10) {
      // Two readings in a row, so one bad echo doesn't cry wolf.
      if (++_dropReadings == 2) {
        _raise(
          ObstacleAlert(
            kind: ObstacleKind.dropOff,
            direction: ObstacleDirection.ahead,
            veryClose: true,
            time: _now(),
          ),
        );
      }
    } else {
      _dropReadings = 0;
      // Follow slow changes (slopes, how the head is tilted).
      _floorCm = floor * 0.9 + downCm * 0.1;
    }
  }

  void _raise(ObstacleAlert alert, {bool generic = false}) {
    if (!_settings.alertsOn) return;
    final now = alert.time;
    final risk = alert.kind.risk;
    final key = '${alert.kind.name}/${alert.direction.name}';

    final repeatAfter = risk == ObstacleRisk.fall
        ? _repeatFallAfter
        : _repeatAfter;
    final last = _lastSaid[key];
    if (last != null && now.difference(last) < repeatAfter) return;
    final lastAhead = _lastAheadAt;
    if (generic &&
        lastAhead != null &&
        now.difference(lastAhead) < _repeatAfter) {
      return;
    }
    final lastAlert = _lastAlertAt;
    if (lastAlert != null &&
        now.difference(lastAlert) < _talkingFor &&
        risk.index <= _lastRisk.index) {
      return;
    }

    _lastSaid[key] = now;
    _lastAlertAt = now;
    _lastRisk = risk;
    if (alert.direction == ObstacleDirection.ahead) _lastAheadAt = now;
    _alerts.insert(0, alert);
    if (_alerts.length > maxAlerts) _alerts.removeLast();

    if (_settings.glassesVoice && hasSpeaker) {
      _link.send(GlassesCommands.say(alert.clips));
    }
    if (_settings.glassesVibration &&
        (risk == ObstacleRisk.fall || !hasDistanceSensors)) {
      _lastVibrationAt = now;
      _link.send(GlassesCommands.vibrate(alert.vibration));
    }
    if (_settings.phoneSpeaksAlerts) {
      _tts.speak(alert.text(_settings.language), id: 'glasses-alert');
    }
    notifyListeners();
  }

  void _announce(String arabic, String english) {
    if (!_settings.phoneSpeaksAlerts) return;
    _tts.speak(
      _settings.language.isArabic ? arabic : english,
      id: 'glasses-status',
    );
  }

  void _resetReadings() {
    _battery = null;
    _frontCm = null;
    _downCm = null;
    _frame = null;
    _floorCm = null;
    _dropReadings = 0;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _retry?.cancel();
    _subscription?.cancel();
    _link.dispose();
    _detector.dispose();
    super.dispose();
  }
}
