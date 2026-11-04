import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_language.dart';
import 'settings_controller.dart';

/// Speaks text aloud and tells the UI what is being spoken, so the tapped
/// card can show it is playing.
class TtsService extends ChangeNotifier {
  TtsService(this._settings);

  final SettingsController _settings;
  FlutterTts? _tts;
  SpeechSpeed? _appliedSpeed;
  AppLanguage? _appliedLanguage;
  String? _speakingId;

  /// Id passed to the [speak] call that is currently playing.
  String? get speakingId => _speakingId;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;

    final tts = FlutterTts();
    _tts = tts;
    tts
      ..setCompletionHandler(_clearSpeaking)
      ..setCancelHandler(_clearSpeaking)
      ..setErrorHandler((_) => _clearSpeaking());
    return tts;
  }

  /// Picks the best installed voice for [language] (e.g. ar-SA, else ar).
  Future<void> _applyLanguage(FlutterTts tts, AppLanguage language) async {
    if (language == _appliedLanguage) return;
    var voice = language.ttsLanguages.last;
    for (final candidate in language.ttsLanguages) {
      try {
        if (await tts.isLanguageAvailable(candidate) == true) {
          voice = candidate;
          break;
        }
      } catch (_) {
        break;
      }
    }
    await tts.setLanguage(voice);
    _appliedLanguage = language;
  }

  /// Speaks [text], interrupting whatever was playing. The voice follows the
  /// text's own script, so an Arabic phrase is read by an Arabic voice even
  /// while the app is in English.
  Future<void> speak(String text, {String? id}) async {
    if (text.trim().isEmpty) return;
    try {
      final tts = await _engine();
      await _applyLanguage(tts, AppLanguage.ofText(text));
      await _applySpeed(tts);
      await tts.stop();
      _speakingId = id ?? text;
      notifyListeners();
      await tts.speak(text);
    } catch (e) {
      debugPrint('Text-to-speech failed: $e');
      _clearSpeaking();
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _clearSpeaking();
  }

  Future<void> _applySpeed(FlutterTts tts) async {
    final speed = _settings.speed;
    if (speed == _appliedSpeed) return;
    // Android treats 0.5 as normal speed; browsers treat 1.0 as normal.
    final rate = switch (speed) {
      SpeechSpeed.slow => 0.35,
      SpeechSpeed.normal => 0.5,
      SpeechSpeed.fast => 0.6,
    };
    await tts.setSpeechRate(kIsWeb ? rate * 2 : rate);
    _appliedSpeed = speed;
  }

  void _clearSpeaking() {
    if (_speakingId == null) return;
    _speakingId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }
}
