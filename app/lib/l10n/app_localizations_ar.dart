// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'بصيرة';

  @override
  String get tagline => 'تواصل أسهل، وخطوة أكثر أماناً';

  @override
  String get back => 'رجوع';

  @override
  String get start => 'ابدأ';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get all => 'الكل';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get undo => 'تراجع';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get hide => 'إخفاء';

  @override
  String get save => 'حفظ';

  @override
  String get demo => 'تجربة';

  @override
  String get connected => 'متصلة';

  @override
  String get notConnected => 'غير متصلة';

  @override
  String batteryShort(int percent) {
    return '$percent%';
  }

  @override
  String batteryPercent(int percent) {
    return 'البطارية $percent%';
  }

  @override
  String meters(String value) {
    return '$value م';
  }

  @override
  String get whoUsesApp => 'من سيستخدم التطبيق؟';

  @override
  String get modeDeafTitle => 'أصم أو ضعيف سمع';

  @override
  String get modeDeafSubtitle => 'ترجمة الإشارة، وقراءة الكلام، وعبارات جاهزة';

  @override
  String get modeBlindTitle => 'كفيف أو ضعيف بصر';

  @override
  String get modeBlindSubtitle => 'النظارة الذكية بواجهة صوتية بسيطة';

  @override
  String get modeCompanionTitle => 'مرافق أو تجربة كل الأقسام';

  @override
  String get modeCompanionSubtitle =>
      'كل الأقسام في مكان واحد، ومنها إعدادات النظارة';

  @override
  String get changeLaterHint => 'يمكنك تغيير ذلك لاحقاً من الإعدادات';

  @override
  String get howToAddressYou => 'كيف نخاطبك؟';

  @override
  String get howToAddressYouHint =>
      'نصوغ العبارات بحسب اختيارك، مثل: «أنا متعب» أو «أنا متعبة».';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get yourNameOptional => 'اسمك (اختياري)';

  @override
  String get yourNameHint => 'مثال: عبدالله';

  @override
  String get yourNameWhy => 'نضيف عبارة «اسمي ...» إلى صوتي.';

  @override
  String get signTitle => 'افهمني';

  @override
  String get listenTitle => 'أقرأ كلامك';

  @override
  String get voiceTitle => 'صوتي';

  @override
  String get glassesTitle => 'نظارتي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get signsIKnow => 'الإشارات التي أفهمها';

  @override
  String signsIKnowHint(int count) {
    return 'أفهم $count إشارة حالياً. اضغط على أي إشارة لترى طريقة أدائها.';
  }

  @override
  String get signsSource =>
      'المقاطع من قاعدة بيانات KArSL للغة الإشارة العربية (جامعة الملك فهد للبترول والمعادن).';

  @override
  String howToSign(String word) {
    return 'طريقة أداء إشارة «$word»';
  }

  @override
  String get switchCamera => 'بدّل الكاميرا';

  @override
  String get diagnosticsTitle => 'معلومات تقنية';

  @override
  String get diagnosticsHint =>
      'أرسل هذه المعلومات إلى فريق التطوير لمعرفة سبب المشكلة.';

  @override
  String get copyDetails => 'نسخ';

  @override
  String get copiedDetails => 'تم نسخ المعلومات';

  @override
  String get cameraPermissionTitle => 'نحتاج إذنك لاستخدام الكاميرا';

  @override
  String get cameraPermissionBody =>
      'اسمح للتطبيق باستخدام الكاميرا من إعدادات الجهاز.';

  @override
  String get cameraUnavailableTitle => 'تعذّر تشغيل الكاميرا';

  @override
  String get cameraUnavailableBody =>
      'تأكد أن الكاميرا تعمل، ثم حاول مرة أخرى.';

  @override
  String get cameraStarting => 'نجهّز الكاميرا...';

  @override
  String get modelLoading => 'نجهّز قراءة الإشارات...';

  @override
  String get modelUnavailable => 'قراءة الإشارات غير متاحة على هذا الجهاز';

  @override
  String get tapForDetails => 'اضغط للتفاصيل';

  @override
  String get hintSignInFrame => 'أشِر داخل الإطار';

  @override
  String get hintSignThenLower => 'أشِر، ثم أنزل يديك';

  @override
  String get hintWatching => 'أراك... أنزل يديك عند الانتهاء';

  @override
  String get hintUnsure => 'لم أفهم، أعد الإشارة';

  @override
  String get noSignYet => 'لم تظهر إشارة بعد';

  @override
  String get wordsAppearHere => 'الكلمات التي أفهمها تظهر هنا';

  @override
  String get speakWord => 'انطق الكلمة';

  @override
  String get sentenceHint => 'كل إشارة تُضاف هنا لتكوين جملة';

  @override
  String get speakSentence => 'انطق الجملة';

  @override
  String get deleteLastWord => 'احذف آخر كلمة';

  @override
  String get clearSentence => 'امسح الجملة';

  @override
  String get whatPeopleSay => 'ما يقوله من حولك';

  @override
  String get smallerText => 'تصغير النص';

  @override
  String get biggerText => 'تكبير النص';

  @override
  String get clearSpeech => 'امسح النص';

  @override
  String get tapToListen => 'اضغط لبدء الاستماع';

  @override
  String get listeningTapToStop => 'أستمع الآن، اضغط للإيقاف';

  @override
  String get listenProblem => 'توقف الاستماع بسبب مشكلة، حاول مرة أخرى';

  @override
  String get micPermissionTitle => 'نحتاج إذنك لاستخدام الميكروفون';

  @override
  String get micPermissionBody =>
      'اسمح للتطبيق باستخدام الميكروفون من إعدادات الجهاز.';

  @override
  String get listenUnavailableTitle => 'تحويل الكلام إلى نص غير متاح';

  @override
  String get listenUnavailableBody =>
      'تأكد من اتصالك بالإنترنت ومن تثبيت تطبيق Google، ثم حاول مرة أخرى.';

  @override
  String get listeningNow => 'أستمع الآن...';

  @override
  String get readyToListen => 'جاهز للاستماع';

  @override
  String get listenHint =>
      'اطلب من الشخص الذي أمامك أن يتكلم، وستظهر كلماته هنا بخط كبير.';

  @override
  String get startListening => 'ابدأ الاستماع';

  @override
  String get stopListening => 'أوقف الاستماع';

  @override
  String get typeToSpeakHint => 'اكتب ما تريد قوله...';

  @override
  String get speakIt => 'انطقها';

  @override
  String get saveToMyWords => 'احفظ في كلماتي';

  @override
  String get myWords => 'كلماتي';

  @override
  String get addPhrase => 'أضف كلمة';

  @override
  String get newPhrase => 'كلمة جديدة';

  @override
  String get editPhrase => 'تعديل الكلمة';

  @override
  String get phraseHint => 'اكتب الكلمة أو العبارة';

  @override
  String get category => 'القسم';

  @override
  String get tryVoice => 'جرّب النطق';

  @override
  String get phraseSaved => 'حُفظت في كلماتي';

  @override
  String get phraseDeleted => 'حُذفت العبارة';

  @override
  String get phraseHidden => 'أُخفيت العبارة';

  @override
  String get phraseTileHint => 'اضغط للنطق، واضغط مطولاً للخيارات';

  @override
  String get noWordsYet => 'لم تُضف كلمات بعد';

  @override
  String get noWordsYetHint =>
      'أضف الكلمات والعبارات التي تحتاجها كثيراً، لتنطقها بضغطة واحدة.';

  @override
  String get glassesConnected => 'النظارة متصلة';

  @override
  String get glassesConnecting => 'جارٍ الاتصال بالنظارة';

  @override
  String get glassesDisconnected => 'النظارة غير متصلة';

  @override
  String get glassesHint => 'شغّل النظارة، ثم اضغط «اتصال»';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get demoExplain =>
      'وضع التجربة يحاكي النظارة حتى تجهز القطعة الفعلية، ويمكنك إيقافه من الإعدادات.';

  @override
  String get sensorAhead => 'أمامك';

  @override
  String get sensorFloor => 'الأرض';

  @override
  String get cameraPreview => 'كاميرا النظارة';

  @override
  String get cameraPreviewDemo => 'لا توجد كاميرا في وضع التجربة';

  @override
  String get cameraPreviewWaiting => 'ستظهر الصورة هنا عند وصولها من النظارة';

  @override
  String get warnings => 'التنبيهات';

  @override
  String get obstacleWarnings => 'تنبيهات العوائق';

  @override
  String get warningsOnHint => 'تعمل الآن';

  @override
  String get warningsOffHint => 'متوقفة، ولن يصل أي تنبيه';

  @override
  String get warnFrom => 'نبّهني من مسافة';

  @override
  String get glassesVoice => 'صوت النظارة';

  @override
  String get glassesVibration => 'اهتزاز النظارة';

  @override
  String get phoneSpeaksWarnings => 'نطق التنبيهات من الجوال';

  @override
  String get phoneSpeaksWarningsHint => 'مفيد مع سماعة بلوتوث';

  @override
  String get testSound => 'اختبر الصوت';

  @override
  String get rotatePicture => 'تدوير الصورة';

  @override
  String get testVibration => 'اختبر الاهتزاز';

  @override
  String get latestWarnings => 'آخر التنبيهات';

  @override
  String get noWarningsYet => 'لا توجد تنبيهات بعد';

  @override
  String get tapToHearStatus => 'اضغط لسماع الحالة';

  @override
  String get warningsAreOn => 'التنبيهات تعمل';

  @override
  String get warningsAreOff => 'التنبيهات متوقفة';

  @override
  String get turnWarningsOn => 'تشغيل التنبيهات';

  @override
  String get turnWarningsOff => 'إيقاف التنبيهات';

  @override
  String get connectGlasses => 'الاتصال بالنظارة';

  @override
  String get disconnectGlasses => 'قطع اتصال النظارة';

  @override
  String get settingsForHelper => 'الإعدادات، للمرافق';

  @override
  String get aboutYou => 'عنك';

  @override
  String get languageAndLook => 'اللغة والمظهر';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get voice => 'الصوت';

  @override
  String get speedSlow => 'بطيء';

  @override
  String get speedNormal => 'عادي';

  @override
  String get speedFast => 'سريع';

  @override
  String get voiceSample => 'هكذا سيكون صوت النطق';

  @override
  String get autoSpeakSigns => 'انطق الإشارة فور قراءتها';

  @override
  String get demoMode => 'وضع التجربة';

  @override
  String get demoModeHint =>
      'نظارة افتراضية لعرض القسم قبل تجهيز القطعة الفعلية';

  @override
  String get glassesWifi => 'نظارة بالواي فاي';

  @override
  String get glassesWifiHint =>
      'للنظارة التي تتصل عبر شبكتها الخاصة بدل البلوتوث';

  @override
  String showHiddenPhrases(int count) {
    return 'إظهار العبارات المخفية ($count)';
  }

  @override
  String get aboutApp => 'حول التطبيق';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get credits =>
      'نموذج قراءة الإشارات مدرَّب على قاعدة بيانات KArSL للغة الإشارة العربية، ويستخدم MediaPipe من Google. الخط: IBM Plex Sans Arabic.';
}
