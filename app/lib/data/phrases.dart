import '../l10n/app_language.dart';

/// Groups on the صوتي board. User-added phrases pick one of these too.
enum PhraseCategory {
  basics('أساسيات', 'Basics'),
  needs('احتياجاتي', 'My needs'),
  health('صحتي', 'Health'),
  outside('في الخارج', 'Out and about'),
  emergency('طوارئ', 'Emergency'),
  greetings('تحيات', 'Greetings');

  const PhraseCategory(this.arabic, this.english);

  final String arabic;
  final String english;

  String label(AppLanguage language) => language.isArabic ? arabic : english;
}

/// A ready-made sentence the user taps to have it spoken aloud.
///
/// Arabic changes with the speaker's gender ("أنا متعب" / "أنا متعبة"), so a
/// phrase may carry a separate [female] form, picked from the settings.
class Phrase {
  const Phrase({
    required this.id,
    required this.male,
    required this.english,
    required this.category,
    this.female,
  });

  final String id;
  final String male;
  final String? female;
  final String english;
  final PhraseCategory category;

  String textFor(AppLanguage language, {required bool isFemale}) {
    if (!language.isArabic) return english;
    return isFemale ? (female ?? male) : male;
  }
}

/// Built-in phrases. Users can hide any of them and add their own
/// (`PhrasesStore`); ids must stay stable because hidden ones are saved by id.
const List<Phrase> builtInPhrases = [
  // أساسيات
  Phrase(
    id: 'deaf',
    male: 'أنا أصم، أتواصل بلغة الإشارة',
    female: 'أنا صمّاء، أتواصل بلغة الإشارة',
    english: "I'm deaf, I communicate in sign language",
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'slowly',
    male: 'تكلّم ببطء من فضلك',
    english: 'Please speak slowly',
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'readScreen',
    male: 'اقرأ ما على الشاشة من فضلك',
    english: 'Please read what is on the screen',
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'writeIt',
    male: 'اكتبها لي من فضلك',
    english: 'Please write it down for me',
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'repeat',
    male: 'لم أفهم، أعد من فضلك',
    english: "I didn't understand, please repeat",
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'wait',
    male: 'انتظر لحظة من فضلك',
    english: 'Please wait a moment',
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'thanks',
    male: 'شكراً لك',
    english: 'Thank you',
    category: PhraseCategory.basics,
  ),
  Phrase(
    id: 'sorry',
    male: 'أنا آسف',
    female: 'أنا آسفة',
    english: "I'm sorry",
    category: PhraseCategory.basics,
  ),
  // احتياجاتي
  Phrase(
    id: 'help',
    male: 'أحتاج مساعدة من فضلك',
    english: 'I need help, please',
    category: PhraseCategory.needs,
  ),
  Phrase(
    id: 'water',
    male: 'أريد ماءً من فضلك',
    english: "I'd like some water, please",
    category: PhraseCategory.needs,
  ),
  Phrase(
    id: 'toilet',
    male: 'أين دورة المياه؟',
    english: 'Where is the bathroom?',
    category: PhraseCategory.needs,
  ),
  Phrase(
    id: 'hungry',
    male: 'أنا جائع',
    female: 'أنا جائعة',
    english: "I'm hungry",
    category: PhraseCategory.needs,
  ),
  Phrase(
    id: 'tired',
    male: 'أنا متعب وأريد أن أرتاح',
    female: 'أنا متعبة وأريد أن أرتاح',
    english: "I'm tired and need to rest",
    category: PhraseCategory.needs,
  ),
  Phrase(
    id: 'charge',
    male: 'أحتاج إلى شحن جوالي',
    english: 'I need to charge my phone',
    category: PhraseCategory.needs,
  ),
  Phrase(
    id: 'callNumber',
    male: 'هل يمكنك الاتصال بهذا الرقم؟',
    english: 'Can you call this number for me?',
    category: PhraseCategory.needs,
  ),
  // صحتي
  Phrase(
    id: 'pain',
    male: 'أشعر بألم',
    english: "I'm in pain",
    category: PhraseCategory.health,
  ),
  Phrase(
    id: 'painHere',
    male: 'الألم هنا',
    english: 'It hurts here',
    category: PhraseCategory.health,
  ),
  Phrase(
    id: 'doctor',
    male: 'أحتاج إلى طبيب',
    english: 'I need a doctor',
    category: PhraseCategory.health,
  ),
  Phrase(
    id: 'sick',
    male: 'أنا مريض',
    female: 'أنا مريضة',
    english: "I'm sick",
    category: PhraseCategory.health,
  ),
  Phrase(
    id: 'allergy',
    male: 'عندي حساسية',
    english: 'I have an allergy',
    category: PhraseCategory.health,
  ),
  Phrase(
    id: 'medicine',
    male: 'أحتاج إلى دوائي',
    english: 'I need my medicine',
    category: PhraseCategory.health,
  ),
  Phrase(
    id: 'pharmacy',
    male: 'أين أقرب صيدلية؟',
    english: "Where's the nearest pharmacy?",
    category: PhraseCategory.health,
  ),
  // في الخارج
  Phrase(
    id: 'price',
    male: 'كم السعر؟',
    english: 'How much is it?',
    category: PhraseCategory.outside,
  ),
  Phrase(
    id: 'address',
    male: 'أريد الذهاب إلى هذا العنوان',
    english: 'I want to go to this address',
    category: PhraseCategory.outside,
  ),
  Phrase(
    id: 'stopHere',
    male: 'توقّف هنا من فضلك',
    english: 'Please stop here',
    category: PhraseCategory.outside,
  ),
  Phrase(
    id: 'exit',
    male: 'أين المخرج؟',
    english: 'Where is the exit?',
    category: PhraseCategory.outside,
  ),
  Phrase(
    id: 'card',
    male: 'أريد الدفع بالبطاقة',
    english: "I'd like to pay by card",
    category: PhraseCategory.outside,
  ),
  Phrase(
    id: 'myTurn',
    male: 'هل هذا دوري؟',
    english: 'Is it my turn?',
    category: PhraseCategory.outside,
  ),
  Phrase(
    id: 'lost',
    male: 'أنا تائه، هل يمكنك مساعدتي؟',
    female: 'أنا تائهة، هل يمكنك مساعدتي؟',
    english: "I'm lost, can you help me?",
    category: PhraseCategory.outside,
  ),
  // طوارئ
  Phrase(
    id: 'ambulance',
    male: 'اتصل بالإسعاف فوراً',
    english: 'Call an ambulance now',
    category: PhraseCategory.emergency,
  ),
  Phrase(
    id: 'police',
    male: 'اتصل بالشرطة',
    english: 'Call the police',
    category: PhraseCategory.emergency,
  ),
  Phrase(
    id: 'danger',
    male: 'أنا في خطر، ساعدني',
    english: "I'm in danger, help me",
    category: PhraseCategory.emergency,
  ),
  Phrase(
    id: 'fell',
    male: 'سقطت وأحتاج إلى مساعدة',
    english: 'I fell and need help',
    category: PhraseCategory.emergency,
  ),
  Phrase(
    id: 'callFamily',
    male: 'اتصل بأهلي من فضلك',
    english: 'Please call my family',
    category: PhraseCategory.emergency,
  ),
  Phrase(
    id: 'writeToMe',
    male: 'لا أسمع، تواصل معي بالكتابة',
    english: "I can't hear, please write to me",
    category: PhraseCategory.emergency,
  ),
  // تحيات
  Phrase(
    id: 'salam',
    male: 'السلام عليكم',
    english: 'Peace be upon you',
    category: PhraseCategory.greetings,
  ),
  Phrase(
    id: 'morning',
    male: 'صباح الخير',
    english: 'Good morning',
    category: PhraseCategory.greetings,
  ),
  Phrase(
    id: 'evening',
    male: 'مساء الخير',
    english: 'Good evening',
    category: PhraseCategory.greetings,
  ),
  Phrase(
    id: 'howAreYou',
    male: 'كيف حالك؟',
    english: 'How are you?',
    category: PhraseCategory.greetings,
  ),
  Phrase(
    id: 'fine',
    male: 'أنا بخير، الحمد لله',
    english: "I'm fine, thank God",
    category: PhraseCategory.greetings,
  ),
  Phrase(
    id: 'niceToMeet',
    male: 'تشرّفت بمعرفتك',
    english: 'Nice to meet you',
    category: PhraseCategory.greetings,
  ),
  Phrase(
    id: 'bye',
    male: 'مع السلامة',
    english: 'Goodbye',
    category: PhraseCategory.greetings,
  ),
];

/// "اسمي ..." — only offered once the user has entered a name in settings.
Phrase myNamePhrase(String name) => Phrase(
  id: 'myName',
  male: 'اسمي $name',
  english: 'My name is $name',
  category: PhraseCategory.greetings,
);
