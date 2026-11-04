import 'package:flutter/widgets.dart';

/// Languages the app can use. The screens, the spoken voice and
/// speech-to-text all follow the one picked in settings.
enum AppLanguage {
  ar(Locale('ar'), 'العربية', ttsLanguages: ['ar-SA', 'ar']),
  en(Locale('en'), 'English', ttsLanguages: ['en-US', 'en-GB', 'en']);

  const AppLanguage(this.locale, this.nativeName, {required this.ttsLanguages});

  final Locale locale;

  /// The language's name in itself, so it can be found from either language.
  final String nativeName;

  /// Text-to-speech voices to try, best first.
  final List<String> ttsLanguages;

  bool get isArabic => this == ar;

  static AppLanguage of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;

  /// The language a piece of text is written in: Arabic if it contains any
  /// Arabic letter. Lets a phrase typed in Arabic be spoken with an Arabic
  /// voice even while the app is in English (and the other way round).
  static AppLanguage ofText(String text) =>
      _arabicLetter.hasMatch(text) ? ar : en;

  static final _arabicLetter = RegExp('[؀-ۿݐ-ݿ]');
}
