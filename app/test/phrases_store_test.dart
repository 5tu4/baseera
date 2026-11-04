import 'package:baseera/data/phrases.dart';
import 'package:baseera/l10n/app_language.dart';
import 'package:baseera/services/phrases_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<PhraseCard> mine(PhrasesStore store) =>
    store.cards(language: AppLanguage.ar, isFemale: false, customOnly: true);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('added words are saved and survive a restart', () async {
    final store = await PhrasesStore.load();
    store.add(text: '  أريد قهوة  ', category: PhraseCategory.needs);

    final reloaded = await PhrasesStore.load();
    final cards = mine(reloaded);
    expect(cards, hasLength(1));
    expect(cards.single.text, 'أريد قهوة', reason: 'text is trimmed');
    expect(cards.single.category, PhraseCategory.needs);
    expect(cards.single.isCustom, isTrue);
  });

  test('the newest own word comes first, before the built-in ones', () async {
    final store = await PhrasesStore.load();
    store.add(text: 'الأولى', category: PhraseCategory.basics);
    store.add(text: 'الثانية', category: PhraseCategory.basics);

    final all = store.cards(language: AppLanguage.ar, isFemale: false);
    expect(all.take(2).map((c) => c.text), ['الثانية', 'الأولى']);
    expect(all.length, builtInPhrases.length + 2);
  });

  test('editing keeps the id and changes text, category and icon', () async {
    final store = await PhrasesStore.load();
    final added = store.add(text: 'قديم', category: PhraseCategory.basics);
    store.update(added.copyWith(text: 'جديد', category: PhraseCategory.health));

    final card = mine(store).single;
    expect(card.id, added.id);
    expect(card.text, 'جديد');
    expect(card.category, PhraseCategory.health);
  });

  test('removing deletes own words but only hides built-in ones', () async {
    final store = await PhrasesStore.load();
    final added = store.add(text: 'مؤقت', category: PhraseCategory.basics);
    store.remove(added.id);
    expect(mine(store), isEmpty);

    store.remove('water');
    expect(store.hasHidden, isTrue);
    final ids = store
        .cards(language: AppLanguage.ar, isFemale: false)
        .map((c) => c.id);
    expect(ids, isNot(contains('water')));

    final reloaded = await PhrasesStore.load();
    expect(reloaded.hiddenCount, 1, reason: 'hidden ids are saved');
    reloaded.showAllHidden();
    expect(
      reloaded
          .cards(language: AppLanguage.ar, isFemale: false)
          .map((c) => c.id),
      contains('water'),
    );
  });

  test('undo puts a deleted word back where it was', () async {
    final store = await PhrasesStore.load();
    store.add(text: 'أ', category: PhraseCategory.basics);
    final middle = store.add(text: 'ب', category: PhraseCategory.basics);
    store.add(text: 'ج', category: PhraseCategory.basics);
    final index = store.custom.indexOf(middle);

    store.remove(middle.id);
    store.restore(middle.id, custom: middle, index: index);
    expect(mine(store).map((c) => c.text), ['ج', 'ب', 'أ']);
  });

  test('built-in phrases follow gender, language, filter and name', () async {
    final store = PhrasesStore.memory();
    String text(
      String id, {
      bool female = false,
      AppLanguage lang = AppLanguage.ar,
    }) => store
        .cards(language: lang, isFemale: female)
        .firstWhere((c) => c.id == id)
        .text;

    expect(text('tired'), 'أنا متعب وأريد أن أرتاح');
    expect(text('tired', female: true), 'أنا متعبة وأريد أن أرتاح');
    expect(text('tired', lang: AppLanguage.en), "I'm tired and need to rest");

    final health = store.cards(
      language: AppLanguage.ar,
      isFemale: false,
      category: PhraseCategory.health,
    );
    expect(health, isNotEmpty);
    expect(health.every((c) => c.category == PhraseCategory.health), isTrue);

    final named = store.cards(
      language: AppLanguage.ar,
      isFemale: false,
      name: 'سارة',
    );
    expect(named.firstWhere((c) => c.id == 'myName').text, 'اسمي سارة');
  });

  test('corrupt saved data starts empty instead of crashing', () async {
    SharedPreferences.setMockInitialValues({'customPhrases': 'not json'});
    final store = await PhrasesStore.load();
    expect(store.custom, isEmpty);
  });

  test('built-in phrase ids are unique', () {
    final ids = builtInPhrases.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
