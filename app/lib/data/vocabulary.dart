import '../l10n/app_language.dart';

/// A group of signs, shown as a filter in the "signs I understand" sheet.
enum SignCategory {
  greetings('تحيات', 'Greetings'),
  important('كلمات مهمة', 'Important words'),
  family('العائلة', 'Family'),
  people('أشخاص', 'People'),
  feelings('مشاعر', 'Feelings'),
  numbers('أرقام', 'Numbers');

  const SignCategory(this.arabic, this.english);

  final String arabic;
  final String english;

  String label(AppLanguage language) => language.isArabic ? arabic : english;
}

/// One sign the app can recognize.
///
/// [id] is the class label the recognition model outputs, and [karslId] is
/// the sign's number in the KArSL dataset the model is trained on
/// (Ishara's `ml/extract.py` reads both from this file — keep them stable).
class SignWord {
  const SignWord({
    required this.id,
    required this.karslId,
    required this.word,
    required this.english,
    required this.category,
  });

  final String id;
  final int karslId;

  /// Arabic word.
  final String word;
  final String english;
  final SignCategory category;

  String wordIn(AppLanguage language) => language.isArabic ? word : english;

  /// Looping clip of a KArSL signer performing the sign.
  String get clipAsset => 'assets/signs/$id.webp';
}

/// Signs available in KArSL (KFUPM Arabic Sign Language dataset) that suit
/// everyday conversation. A Saudi signer should confirm each one matches
/// Saudi Sign Language usage.
const List<SignWord> vocabulary = [
  // تحيات
  SignWord(
    id: 'salam',
    karslId: 290,
    word: 'السلام عليكم',
    english: 'Peace be upon you',
    category: SignCategory.greetings,
  ),
  SignWord(
    id: 'welcome',
    karslId: 289,
    word: 'أهلاً وسهلاً',
    english: 'Welcome',
    category: SignCategory.greetings,
  ),
  SignWord(
    id: 'thanks',
    karslId: 293,
    word: 'شكراً',
    english: 'Thank you',
    category: SignCategory.greetings,
  ),
  // كلمات مهمة
  SignWord(
    id: 'help',
    karslId: 182,
    word: 'ساعدني',
    english: 'Help me',
    category: SignCategory.important,
  ),
  SignWord(
    id: 'eat',
    karslId: 160,
    word: 'آكل',
    english: 'Eat',
    category: SignCategory.important,
  ),
  SignWord(
    id: 'drink',
    karslId: 161,
    word: 'أشرب',
    english: 'Drink',
    category: SignCategory.important,
  ),
  SignWord(
    id: 'sleep',
    karslId: 162,
    word: 'أنام',
    english: 'Sleep',
    category: SignCategory.important,
  ),
  SignWord(
    id: 'toilet',
    karslId: 327,
    word: 'دورة المياه',
    english: 'Bathroom',
    category: SignCategory.important,
  ),
  SignWord(
    id: 'pain',
    karslId: 116,
    word: 'ألم',
    english: 'Pain',
    category: SignCategory.important,
  ),
  SignWord(
    id: 'sick',
    karslId: 134,
    word: 'مريض',
    english: 'Sick',
    category: SignCategory.important,
  ),
  // عائلتي
  SignWord(
    id: 'mother',
    karslId: 196,
    word: 'أمي',
    english: 'Mom',
    category: SignCategory.family,
  ),
  SignWord(
    id: 'father',
    karslId: 195,
    word: 'أبي',
    english: 'Dad',
    category: SignCategory.family,
  ),
  SignWord(
    id: 'brother',
    karslId: 198,
    word: 'أخي',
    english: 'Brother',
    category: SignCategory.family,
  ),
  SignWord(
    id: 'sister',
    karslId: 197,
    word: 'أختي',
    english: 'Sister',
    category: SignCategory.family,
  ),
  SignWord(
    id: 'grandmother',
    karslId: 193,
    word: 'جدتي',
    english: 'Grandma',
    category: SignCategory.family,
  ),
  SignWord(
    id: 'grandfather',
    karslId: 194,
    word: 'جدي',
    english: 'Grandpa',
    category: SignCategory.family,
  ),
  SignWord(
    id: 'home',
    karslId: 299,
    word: 'البيت',
    english: 'Home',
    category: SignCategory.family,
  ),
  // من حولي
  SignWord(
    id: 'teacher',
    karslId: 491,
    word: 'المعلم',
    english: 'Teacher',
    category: SignCategory.people,
  ),
  SignWord(
    id: 'friend',
    karslId: 294,
    word: 'صديقي',
    english: 'Friend',
    category: SignCategory.people,
  ),
  SignWord(
    id: 'child',
    karslId: 223,
    word: 'طفل',
    english: 'Child',
    category: SignCategory.people,
  ),
  SignWord(
    id: 'doctor',
    karslId: 497,
    word: 'الطبيب',
    english: 'Doctor',
    category: SignCategory.people,
  ),
  SignWord(
    id: 'gift',
    karslId: 298,
    word: 'هدية',
    english: 'Gift',
    category: SignCategory.people,
  ),
  // مشاعري
  SignWord(
    id: 'happy',
    karslId: 238,
    word: 'سعيد',
    english: 'Happy',
    category: SignCategory.feelings,
  ),
  SignWord(
    id: 'sad',
    karslId: 239,
    word: 'حزين',
    english: 'Sad',
    category: SignCategory.feelings,
  ),
  SignWord(
    id: 'scared',
    karslId: 237,
    word: 'خائف',
    english: 'Scared',
    category: SignCategory.feelings,
  ),
  SignWord(
    id: 'tired',
    karslId: 255,
    word: 'متعب',
    english: 'Tired',
    category: SignCategory.feelings,
  ),
  SignWord(
    id: 'crying',
    karslId: 256,
    word: 'أبكي',
    english: 'Crying',
    category: SignCategory.feelings,
  ),
  SignWord(
    id: 'love',
    karslId: 174,
    word: 'أحبك',
    english: 'I love you',
    category: SignCategory.feelings,
  ),
  // أرقام
  SignWord(
    id: 'n0',
    karslId: 1,
    word: 'صفر',
    english: 'Zero',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n1',
    karslId: 2,
    word: 'واحد',
    english: 'One',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n2',
    karslId: 3,
    word: 'اثنان',
    english: 'Two',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n3',
    karslId: 4,
    word: 'ثلاثة',
    english: 'Three',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n4',
    karslId: 5,
    word: 'أربعة',
    english: 'Four',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n5',
    karslId: 6,
    word: 'خمسة',
    english: 'Five',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n6',
    karslId: 7,
    word: 'ستة',
    english: 'Six',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n7',
    karslId: 8,
    word: 'سبعة',
    english: 'Seven',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n8',
    karslId: 9,
    word: 'ثمانية',
    english: 'Eight',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n9',
    karslId: 10,
    word: 'تسعة',
    english: 'Nine',
    category: SignCategory.numbers,
  ),
  SignWord(
    id: 'n10',
    karslId: 11,
    word: 'عشرة',
    english: 'Ten',
    category: SignCategory.numbers,
  ),
];

SignWord? signById(String id) {
  for (final sign in vocabulary) {
    if (sign.id == id) return sign;
  }
  return null;
}
