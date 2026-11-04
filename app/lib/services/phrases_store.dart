import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/phrases.dart';
import '../l10n/app_language.dart';

/// A phrase the user wrote on the صوتي board.
@immutable
class CustomPhrase {
  const CustomPhrase({
    required this.id,
    required this.text,
    required this.category,
  });

  final String id;
  final String text;
  final PhraseCategory category;

  CustomPhrase copyWith({String? text, PhraseCategory? category}) =>
      CustomPhrase(
        id: id,
        text: text ?? this.text,
        category: category ?? this.category,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'category': category.name,
  };

  /// Null for entries that can no longer be read (they are dropped).
  static CustomPhrase? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], text = json['text'];
    if (id is! String || text is! String || text.trim().isEmpty) return null;
    return CustomPhrase(
      id: id,
      text: text,
      category:
          PhraseCategory.values.asNameMap()[json['category']] ??
          PhraseCategory.basics,
    );
  }
}

/// One card on the board — built-in or the user's own — with its text
/// already resolved for the current language and gender.
@immutable
class PhraseCard {
  const PhraseCard({
    required this.id,
    required this.text,
    required this.category,
    required this.isCustom,
  });

  final String id;
  final String text;
  final PhraseCategory category;
  final bool isCustom;
}

/// The user's own phrases plus which built-in ones they hid. Saved on the
/// device; Firebase sync comes later.
class PhrasesStore extends ChangeNotifier {
  PhrasesStore._(this._prefs)
    : _custom = _readCustom(_prefs),
      _hidden = {...?_prefs?.getStringList(_kHidden)};

  /// In-memory store (tests, or when storage is unavailable).
  PhrasesStore.memory() : this._(null);

  static Future<PhrasesStore> load() async {
    try {
      return PhrasesStore._(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('Phrase storage unavailable, using memory: $e');
      return PhrasesStore.memory();
    }
  }

  static const _kCustom = 'customPhrases';
  static const _kHidden = 'hiddenPhrases';

  final SharedPreferences? _prefs;

  /// Newest first.
  final List<CustomPhrase> _custom;
  final Set<String> _hidden;

  List<CustomPhrase> get custom => List.unmodifiable(_custom);
  bool get hasHidden => _hidden.isNotEmpty;
  int get hiddenCount => _hidden.length;

  static List<CustomPhrase> _readCustom(SharedPreferences? prefs) {
    final raw = prefs?.getString(_kCustom);
    if (raw == null) return [];
    try {
      return [
        for (final entry in jsonDecode(raw) as List)
          ?CustomPhrase.fromJson(entry),
      ];
    } catch (e) {
      debugPrint('Saved phrases unreadable, starting empty: $e');
      return [];
    }
  }

  CustomPhrase? customById(String id) {
    for (final phrase in _custom) {
      if (phrase.id == id) return phrase;
    }
    return null;
  }

  /// The cards to show: the user's own first (newest first), then the
  /// built-in ones that are not hidden. [category] filters; [customOnly]
  /// keeps only the user's own.
  List<PhraseCard> cards({
    required AppLanguage language,
    required bool isFemale,
    String name = '',
    PhraseCategory? category,
    bool customOnly = false,
  }) {
    final builtIn = [
      if (name.isNotEmpty) myNamePhrase(name),
      ...builtInPhrases,
    ];
    return [
      for (final phrase in _custom)
        if (category == null || phrase.category == category)
          PhraseCard(
            id: phrase.id,
            text: phrase.text,
            category: phrase.category,
            isCustom: true,
          ),
      if (!customOnly)
        for (final phrase in builtIn)
          if (!_hidden.contains(phrase.id) &&
              (category == null || phrase.category == category))
            PhraseCard(
              id: phrase.id,
              text: phrase.textFor(language, isFemale: isFemale),
              category: phrase.category,
              isCustom: false,
            ),
    ];
  }

  CustomPhrase add({required String text, required PhraseCategory category}) {
    // The clock can be coarse (Windows), so make sure the id is new.
    var stamp = DateTime.now().microsecondsSinceEpoch;
    while (customById('u$stamp') != null) {
      stamp++;
    }
    final phrase = CustomPhrase(
      id: 'u$stamp',
      text: text.trim(),
      category: category,
    );
    _custom.insert(0, phrase);
    _saveCustom();
    notifyListeners();
    return phrase;
  }

  void update(CustomPhrase phrase) {
    final index = _custom.indexWhere((p) => p.id == phrase.id);
    if (index < 0) return;
    _custom[index] = phrase.copyWith(text: phrase.text.trim());
    _saveCustom();
    notifyListeners();
  }

  /// Deletes one of the user's phrases, or hides a built-in one.
  void remove(String id) {
    final index = _custom.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _custom.removeAt(index);
      _saveCustom();
    } else if (_hidden.add(id)) {
      _prefs?.setStringList(_kHidden, _hidden.toList());
    } else {
      return;
    }
    notifyListeners();
  }

  /// Puts a just-removed phrase back (the "undo" in the snack bar).
  void restore(String id, {CustomPhrase? custom, int index = 0}) {
    if (custom != null) {
      if (customById(custom.id) != null) return;
      _custom.insert(index.clamp(0, _custom.length), custom);
      _saveCustom();
    } else if (_hidden.remove(id)) {
      _prefs?.setStringList(_kHidden, _hidden.toList());
    } else {
      return;
    }
    notifyListeners();
  }

  void showAllHidden() {
    if (_hidden.isEmpty) return;
    _hidden.clear();
    _prefs?.remove(_kHidden);
    notifyListeners();
  }

  void _saveCustom() => _prefs?.setString(
    _kCustom,
    jsonEncode([for (final phrase in _custom) phrase.toJson()]),
  );
}
