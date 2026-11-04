import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';

/// Who uses the app. Picked at first launch; it decides the home layout.
enum UserMode {
  /// Deaf or hard of hearing: sign, speech and phrase tabs.
  deaf,

  /// Blind or low vision: one voice-first glasses screen.
  blind,

  /// A helper, or a demo: every section.
  companion,
}

enum SpeechSpeed { slow, normal, fast }

/// Everything the user configures. Persisted on the device only.
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs)
    : _userMode = UserMode.values.asNameMap()[_prefs?.getString(_kMode)],
      _isFemale = _prefs?.getBool(_kFemale) ?? false,
      _name = _prefs?.getString(_kName) ?? '',
      _speed =
          SpeechSpeed.values.asNameMap()[_prefs?.getString(_kSpeed)] ??
          SpeechSpeed.normal,
      _autoSpeak = _prefs?.getBool(_kAutoSpeak) ?? true,
      _language =
          AppLanguage.values.asNameMap()[_prefs?.getString(_kLanguage)] ??
          AppLanguage.ar,
      _themeMode =
          ThemeMode.values.asNameMap()[_prefs?.getString(_kTheme)] ??
          ThemeMode.system,
      _transcriptScale = _prefs?.getDouble(_kTranscriptScale) ?? 1.0,
      _alertsOn = _prefs?.getBool(_kAlertsOn) ?? true,
      _alertDistanceCm = _prefs?.getInt(_kAlertDistance) ?? 120,
      _glassesVoice = _prefs?.getBool(_kGlassesVoice) ?? true,
      _glassesVibration = _prefs?.getBool(_kGlassesVibration) ?? true,
      _phoneSpeaksAlerts = _prefs?.getBool(_kPhoneSpeaks) ?? true,
      _cameraQuarterTurns = (_prefs?.getInt(_kCameraTurns) ?? 0) % 4,
      // On until the real glasses exist, so the section can be demonstrated.
      _glassesDemo = _prefs?.getBool(_kGlassesDemo) ?? true,
      _glassesWifi = _prefs?.getBool(_kGlassesWifi) ?? false;

  /// In-memory settings (tests, or when storage is unavailable).
  SettingsController.memory() : this._(null);

  static Future<SettingsController> load() async {
    try {
      return SettingsController._(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('Settings storage unavailable, using memory: $e');
      return SettingsController.memory();
    }
  }

  static const _kMode = 'userMode';
  static const _kFemale = 'isFemale';
  static const _kName = 'name';
  static const _kSpeed = 'speechSpeed';
  static const _kAutoSpeak = 'autoSpeak';
  static const _kLanguage = 'language';
  static const _kTheme = 'themeMode';
  static const _kTranscriptScale = 'transcriptScale';
  static const _kAlertsOn = 'glassesAlertsOn';
  static const _kAlertDistance = 'glassesAlertDistanceCm';
  static const _kGlassesVoice = 'glassesVoice';
  static const _kGlassesVibration = 'glassesVibration';
  static const _kPhoneSpeaks = 'glassesPhoneSpeaks';
  static const _kGlassesDemo = 'glassesDemo';
  static const _kGlassesWifi = 'glassesWifi';
  static const _kCameraTurns = 'glassesCameraQuarterTurns';

  final SharedPreferences? _prefs;

  UserMode? _userMode;
  bool _isFemale;
  String _name;
  SpeechSpeed _speed;
  bool _autoSpeak;
  AppLanguage _language;
  ThemeMode _themeMode;
  double _transcriptScale;
  bool _alertsOn;
  int _alertDistanceCm;
  bool _glassesVoice;
  bool _glassesVibration;
  bool _phoneSpeaksAlerts;
  int _cameraQuarterTurns;
  bool _glassesDemo;
  bool _glassesWifi;

  /// Null until the user finishes onboarding.
  UserMode? get userMode => _userMode;

  /// Picks the Arabic female forms in phrases ("أنا متعبة").
  bool get isFemale => _isFemale;
  String get name => _name;
  SpeechSpeed get speed => _speed;

  /// Speak each recognized sign as soon as it is read.
  bool get autoSpeak => _autoSpeak;
  AppLanguage get language => _language;
  ThemeMode get themeMode => _themeMode;

  /// Text size multiplier on the أقرأ كلامك transcript.
  double get transcriptScale => _transcriptScale;

  /// Master switch for obstacle warnings.
  bool get alertsOn => _alertsOn;

  /// Warn when something ahead is closer than this.
  int get alertDistanceCm => _alertDistanceCm;

  /// Play warnings on the glasses' own speaker.
  bool get glassesVoice => _glassesVoice;
  bool get glassesVibration => _glassesVibration;

  /// Also speak warnings through the phone (or its Bluetooth earphone).
  bool get phoneSpeaksAlerts => _phoneSpeaksAlerts;

  /// Simulated glasses, for demos before the hardware exists.
  bool get glassesDemo => _glassesDemo;

  /// Glasses whose firmware uses Wi-Fi instead of Bluetooth (LINK_BLUETOOTH 0).
  bool get glassesWifi => _glassesWifi;

  /// Clockwise quarter turns that put the glasses' picture the right way up
  /// (the camera stands on its side in the frame).
  int get cameraQuarterTurns => _cameraQuarterTurns;

  set cameraQuarterTurns(int value) {
    final turns = value % 4;
    if (turns == _cameraQuarterTurns) return;
    _cameraQuarterTurns = turns;
    _prefs?.setInt(_kCameraTurns, turns);
    notifyListeners();
  }

  set userMode(UserMode? value) {
    if (value == _userMode) return;
    _userMode = value;
    value == null
        ? _prefs?.remove(_kMode)
        : _prefs?.setString(_kMode, value.name);
    notifyListeners();
  }

  set isFemale(bool value) =>
      _setBool(_kFemale, _isFemale, value, (v) => _isFemale = v);
  set autoSpeak(bool value) =>
      _setBool(_kAutoSpeak, _autoSpeak, value, (v) => _autoSpeak = v);
  set alertsOn(bool value) =>
      _setBool(_kAlertsOn, _alertsOn, value, (v) => _alertsOn = v);
  set glassesVoice(bool value) =>
      _setBool(_kGlassesVoice, _glassesVoice, value, (v) => _glassesVoice = v);
  set glassesVibration(bool value) => _setBool(
    _kGlassesVibration,
    _glassesVibration,
    value,
    (v) => _glassesVibration = v,
  );
  set phoneSpeaksAlerts(bool value) => _setBool(
    _kPhoneSpeaks,
    _phoneSpeaksAlerts,
    value,
    (v) => _phoneSpeaksAlerts = v,
  );
  set glassesDemo(bool value) =>
      _setBool(_kGlassesDemo, _glassesDemo, value, (v) => _glassesDemo = v);
  set glassesWifi(bool value) =>
      _setBool(_kGlassesWifi, _glassesWifi, value, (v) => _glassesWifi = v);

  set name(String value) {
    final trimmed = value.trim();
    if (trimmed == _name) return;
    _name = trimmed;
    _prefs?.setString(_kName, trimmed);
    notifyListeners();
  }

  set speed(SpeechSpeed value) {
    if (value == _speed) return;
    _speed = value;
    _prefs?.setString(_kSpeed, value.name);
    notifyListeners();
  }

  set language(AppLanguage value) {
    if (value == _language) return;
    _language = value;
    _prefs?.setString(_kLanguage, value.name);
    notifyListeners();
  }

  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    _prefs?.setString(_kTheme, value.name);
    notifyListeners();
  }

  set transcriptScale(double value) {
    final clamped = value.clamp(0.8, 1.8).toDouble();
    if (clamped == _transcriptScale) return;
    _transcriptScale = clamped;
    _prefs?.setDouble(_kTranscriptScale, clamped);
    notifyListeners();
  }

  set alertDistanceCm(int value) {
    final clamped = value.clamp(50, 250);
    if (clamped == _alertDistanceCm) return;
    _alertDistanceCm = clamped;
    _prefs?.setInt(_kAlertDistance, clamped);
    notifyListeners();
  }

  void _setBool(
    String key,
    bool current,
    bool value,
    void Function(bool) assign,
  ) {
    if (value == current) return;
    assign(value);
    _prefs?.setBool(key, value);
    notifyListeners();
  }
}
