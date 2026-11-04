import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'بصيرة'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'تواصل أسهل، وخطوة أكثر أماناً'**
  String get tagline;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @start.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get start;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @hide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get hide;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @demo.
  ///
  /// In ar, this message translates to:
  /// **'تجربة'**
  String get demo;

  /// No description provided for @connected.
  ///
  /// In ar, this message translates to:
  /// **'متصلة'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصلة'**
  String get notConnected;

  /// No description provided for @batteryShort.
  ///
  /// In ar, this message translates to:
  /// **'{percent}%'**
  String batteryShort(int percent);

  /// No description provided for @batteryPercent.
  ///
  /// In ar, this message translates to:
  /// **'البطارية {percent}%'**
  String batteryPercent(int percent);

  /// No description provided for @meters.
  ///
  /// In ar, this message translates to:
  /// **'{value} م'**
  String meters(String value);

  /// No description provided for @whoUsesApp.
  ///
  /// In ar, this message translates to:
  /// **'من سيستخدم التطبيق؟'**
  String get whoUsesApp;

  /// No description provided for @modeDeafTitle.
  ///
  /// In ar, this message translates to:
  /// **'أصم أو ضعيف سمع'**
  String get modeDeafTitle;

  /// No description provided for @modeDeafSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة الإشارة، وقراءة الكلام، وعبارات جاهزة'**
  String get modeDeafSubtitle;

  /// No description provided for @modeBlindTitle.
  ///
  /// In ar, this message translates to:
  /// **'كفيف أو ضعيف بصر'**
  String get modeBlindTitle;

  /// No description provided for @modeBlindSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'النظارة الذكية بواجهة صوتية بسيطة'**
  String get modeBlindSubtitle;

  /// No description provided for @modeCompanionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرافق أو تجربة كل الأقسام'**
  String get modeCompanionTitle;

  /// No description provided for @modeCompanionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كل الأقسام في مكان واحد، ومنها إعدادات النظارة'**
  String get modeCompanionSubtitle;

  /// No description provided for @changeLaterHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغيير ذلك لاحقاً من الإعدادات'**
  String get changeLaterHint;

  /// No description provided for @howToAddressYou.
  ///
  /// In ar, this message translates to:
  /// **'كيف نخاطبك؟'**
  String get howToAddressYou;

  /// No description provided for @howToAddressYouHint.
  ///
  /// In ar, this message translates to:
  /// **'نصوغ العبارات بحسب اختيارك، مثل: «أنا متعب» أو «أنا متعبة».'**
  String get howToAddressYouHint;

  /// No description provided for @male.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get female;

  /// No description provided for @yourNameOptional.
  ///
  /// In ar, this message translates to:
  /// **'اسمك (اختياري)'**
  String get yourNameOptional;

  /// No description provided for @yourNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: عبدالله'**
  String get yourNameHint;

  /// No description provided for @yourNameWhy.
  ///
  /// In ar, this message translates to:
  /// **'نضيف عبارة «اسمي ...» إلى صوتي.'**
  String get yourNameWhy;

  /// No description provided for @signTitle.
  ///
  /// In ar, this message translates to:
  /// **'افهمني'**
  String get signTitle;

  /// No description provided for @listenTitle.
  ///
  /// In ar, this message translates to:
  /// **'أقرأ كلامك'**
  String get listenTitle;

  /// No description provided for @voiceTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوتي'**
  String get voiceTitle;

  /// No description provided for @glassesTitle.
  ///
  /// In ar, this message translates to:
  /// **'نظارتي'**
  String get glassesTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @signsIKnow.
  ///
  /// In ar, this message translates to:
  /// **'الإشارات التي أفهمها'**
  String get signsIKnow;

  /// No description provided for @signsIKnowHint.
  ///
  /// In ar, this message translates to:
  /// **'أفهم {count} إشارة حالياً. اضغط على أي إشارة لترى طريقة أدائها.'**
  String signsIKnowHint(int count);

  /// No description provided for @signsSource.
  ///
  /// In ar, this message translates to:
  /// **'المقاطع من قاعدة بيانات KArSL للغة الإشارة العربية (جامعة الملك فهد للبترول والمعادن).'**
  String get signsSource;

  /// No description provided for @howToSign.
  ///
  /// In ar, this message translates to:
  /// **'طريقة أداء إشارة «{word}»'**
  String howToSign(String word);

  /// No description provided for @switchCamera.
  ///
  /// In ar, this message translates to:
  /// **'بدّل الكاميرا'**
  String get switchCamera;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات تقنية'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsHint.
  ///
  /// In ar, this message translates to:
  /// **'أرسل هذه المعلومات إلى فريق التطوير لمعرفة سبب المشكلة.'**
  String get diagnosticsHint;

  /// No description provided for @copyDetails.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copyDetails;

  /// No description provided for @copiedDetails.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ المعلومات'**
  String get copiedDetails;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج إذنك لاستخدام الكاميرا'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionBody.
  ///
  /// In ar, this message translates to:
  /// **'اسمح للتطبيق باستخدام الكاميرا من إعدادات الجهاز.'**
  String get cameraPermissionBody;

  /// No description provided for @cameraUnavailableTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل الكاميرا'**
  String get cameraUnavailableTitle;

  /// No description provided for @cameraUnavailableBody.
  ///
  /// In ar, this message translates to:
  /// **'تأكد أن الكاميرا تعمل، ثم حاول مرة أخرى.'**
  String get cameraUnavailableBody;

  /// No description provided for @cameraStarting.
  ///
  /// In ar, this message translates to:
  /// **'نجهّز الكاميرا...'**
  String get cameraStarting;

  /// No description provided for @modelLoading.
  ///
  /// In ar, this message translates to:
  /// **'نجهّز قراءة الإشارات...'**
  String get modelLoading;

  /// No description provided for @modelUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الإشارات غير متاحة على هذا الجهاز'**
  String get modelUnavailable;

  /// No description provided for @tapForDetails.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل'**
  String get tapForDetails;

  /// No description provided for @hintSignInFrame.
  ///
  /// In ar, this message translates to:
  /// **'أشِر داخل الإطار'**
  String get hintSignInFrame;

  /// No description provided for @hintSignThenLower.
  ///
  /// In ar, this message translates to:
  /// **'أشِر، ثم أنزل يديك'**
  String get hintSignThenLower;

  /// No description provided for @hintWatching.
  ///
  /// In ar, this message translates to:
  /// **'أراك... أنزل يديك عند الانتهاء'**
  String get hintWatching;

  /// No description provided for @hintUnsure.
  ///
  /// In ar, this message translates to:
  /// **'لم أفهم، أعد الإشارة'**
  String get hintUnsure;

  /// No description provided for @noSignYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تظهر إشارة بعد'**
  String get noSignYet;

  /// No description provided for @wordsAppearHere.
  ///
  /// In ar, this message translates to:
  /// **'الكلمات التي أفهمها تظهر هنا'**
  String get wordsAppearHere;

  /// No description provided for @speakWord.
  ///
  /// In ar, this message translates to:
  /// **'انطق الكلمة'**
  String get speakWord;

  /// No description provided for @sentenceHint.
  ///
  /// In ar, this message translates to:
  /// **'كل إشارة تُضاف هنا لتكوين جملة'**
  String get sentenceHint;

  /// No description provided for @speakSentence.
  ///
  /// In ar, this message translates to:
  /// **'انطق الجملة'**
  String get speakSentence;

  /// No description provided for @deleteLastWord.
  ///
  /// In ar, this message translates to:
  /// **'احذف آخر كلمة'**
  String get deleteLastWord;

  /// No description provided for @clearSentence.
  ///
  /// In ar, this message translates to:
  /// **'امسح الجملة'**
  String get clearSentence;

  /// No description provided for @whatPeopleSay.
  ///
  /// In ar, this message translates to:
  /// **'ما يقوله من حولك'**
  String get whatPeopleSay;

  /// No description provided for @smallerText.
  ///
  /// In ar, this message translates to:
  /// **'تصغير النص'**
  String get smallerText;

  /// No description provided for @biggerText.
  ///
  /// In ar, this message translates to:
  /// **'تكبير النص'**
  String get biggerText;

  /// No description provided for @clearSpeech.
  ///
  /// In ar, this message translates to:
  /// **'امسح النص'**
  String get clearSpeech;

  /// No description provided for @tapToListen.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لبدء الاستماع'**
  String get tapToListen;

  /// No description provided for @listeningTapToStop.
  ///
  /// In ar, this message translates to:
  /// **'أستمع الآن، اضغط للإيقاف'**
  String get listeningTapToStop;

  /// No description provided for @listenProblem.
  ///
  /// In ar, this message translates to:
  /// **'توقف الاستماع بسبب مشكلة، حاول مرة أخرى'**
  String get listenProblem;

  /// No description provided for @micPermissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج إذنك لاستخدام الميكروفون'**
  String get micPermissionTitle;

  /// No description provided for @micPermissionBody.
  ///
  /// In ar, this message translates to:
  /// **'اسمح للتطبيق باستخدام الميكروفون من إعدادات الجهاز.'**
  String get micPermissionBody;

  /// No description provided for @listenUnavailableTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحويل الكلام إلى نص غير متاح'**
  String get listenUnavailableTitle;

  /// No description provided for @listenUnavailableBody.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من اتصالك بالإنترنت ومن تثبيت تطبيق Google، ثم حاول مرة أخرى.'**
  String get listenUnavailableBody;

  /// No description provided for @listeningNow.
  ///
  /// In ar, this message translates to:
  /// **'أستمع الآن...'**
  String get listeningNow;

  /// No description provided for @readyToListen.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للاستماع'**
  String get readyToListen;

  /// No description provided for @listenHint.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من الشخص الذي أمامك أن يتكلم، وستظهر كلماته هنا بخط كبير.'**
  String get listenHint;

  /// No description provided for @startListening.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الاستماع'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In ar, this message translates to:
  /// **'أوقف الاستماع'**
  String get stopListening;

  /// No description provided for @typeToSpeakHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما تريد قوله...'**
  String get typeToSpeakHint;

  /// No description provided for @speakIt.
  ///
  /// In ar, this message translates to:
  /// **'انطقها'**
  String get speakIt;

  /// No description provided for @saveToMyWords.
  ///
  /// In ar, this message translates to:
  /// **'احفظ في كلماتي'**
  String get saveToMyWords;

  /// No description provided for @myWords.
  ///
  /// In ar, this message translates to:
  /// **'كلماتي'**
  String get myWords;

  /// No description provided for @addPhrase.
  ///
  /// In ar, this message translates to:
  /// **'أضف كلمة'**
  String get addPhrase;

  /// No description provided for @newPhrase.
  ///
  /// In ar, this message translates to:
  /// **'كلمة جديدة'**
  String get newPhrase;

  /// No description provided for @editPhrase.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الكلمة'**
  String get editPhrase;

  /// No description provided for @phraseHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الكلمة أو العبارة'**
  String get phraseHint;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get category;

  /// No description provided for @tryVoice.
  ///
  /// In ar, this message translates to:
  /// **'جرّب النطق'**
  String get tryVoice;

  /// No description provided for @phraseSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت في كلماتي'**
  String get phraseSaved;

  /// No description provided for @phraseDeleted.
  ///
  /// In ar, this message translates to:
  /// **'حُذفت العبارة'**
  String get phraseDeleted;

  /// No description provided for @phraseHidden.
  ///
  /// In ar, this message translates to:
  /// **'أُخفيت العبارة'**
  String get phraseHidden;

  /// No description provided for @phraseTileHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للنطق، واضغط مطولاً للخيارات'**
  String get phraseTileHint;

  /// No description provided for @noWordsYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضف كلمات بعد'**
  String get noWordsYet;

  /// No description provided for @noWordsYetHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف الكلمات والعبارات التي تحتاجها كثيراً، لتنطقها بضغطة واحدة.'**
  String get noWordsYetHint;

  /// No description provided for @glassesConnected.
  ///
  /// In ar, this message translates to:
  /// **'النظارة متصلة'**
  String get glassesConnected;

  /// No description provided for @glassesConnecting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاتصال بالنظارة'**
  String get glassesConnecting;

  /// No description provided for @glassesDisconnected.
  ///
  /// In ar, this message translates to:
  /// **'النظارة غير متصلة'**
  String get glassesDisconnected;

  /// No description provided for @glassesHint.
  ///
  /// In ar, this message translates to:
  /// **'شغّل النظارة، ثم اضغط «اتصال»'**
  String get glassesHint;

  /// No description provided for @connect.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In ar, this message translates to:
  /// **'قطع الاتصال'**
  String get disconnect;

  /// No description provided for @demoExplain.
  ///
  /// In ar, this message translates to:
  /// **'وضع التجربة يحاكي النظارة حتى تجهز القطعة الفعلية، ويمكنك إيقافه من الإعدادات.'**
  String get demoExplain;

  /// No description provided for @sensorAhead.
  ///
  /// In ar, this message translates to:
  /// **'أمامك'**
  String get sensorAhead;

  /// No description provided for @sensorFloor.
  ///
  /// In ar, this message translates to:
  /// **'الأرض'**
  String get sensorFloor;

  /// No description provided for @cameraPreview.
  ///
  /// In ar, this message translates to:
  /// **'كاميرا النظارة'**
  String get cameraPreview;

  /// No description provided for @cameraPreviewDemo.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد كاميرا في وضع التجربة'**
  String get cameraPreviewDemo;

  /// No description provided for @cameraPreviewWaiting.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر الصورة هنا عند وصولها من النظارة'**
  String get cameraPreviewWaiting;

  /// No description provided for @warnings.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get warnings;

  /// No description provided for @obstacleWarnings.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات العوائق'**
  String get obstacleWarnings;

  /// No description provided for @warningsOnHint.
  ///
  /// In ar, this message translates to:
  /// **'تعمل الآن'**
  String get warningsOnHint;

  /// No description provided for @warningsOffHint.
  ///
  /// In ar, this message translates to:
  /// **'متوقفة، ولن يصل أي تنبيه'**
  String get warningsOffHint;

  /// No description provided for @warnFrom.
  ///
  /// In ar, this message translates to:
  /// **'نبّهني من مسافة'**
  String get warnFrom;

  /// No description provided for @glassesVoice.
  ///
  /// In ar, this message translates to:
  /// **'صوت النظارة'**
  String get glassesVoice;

  /// No description provided for @glassesVibration.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز النظارة'**
  String get glassesVibration;

  /// No description provided for @phoneSpeaksWarnings.
  ///
  /// In ar, this message translates to:
  /// **'نطق التنبيهات من الجوال'**
  String get phoneSpeaksWarnings;

  /// No description provided for @phoneSpeaksWarningsHint.
  ///
  /// In ar, this message translates to:
  /// **'مفيد مع سماعة بلوتوث'**
  String get phoneSpeaksWarningsHint;

  /// No description provided for @testSound.
  ///
  /// In ar, this message translates to:
  /// **'اختبر الصوت'**
  String get testSound;

  /// No description provided for @rotatePicture.
  ///
  /// In ar, this message translates to:
  /// **'تدوير الصورة'**
  String get rotatePicture;

  /// No description provided for @testVibration.
  ///
  /// In ar, this message translates to:
  /// **'اختبر الاهتزاز'**
  String get testVibration;

  /// No description provided for @latestWarnings.
  ///
  /// In ar, this message translates to:
  /// **'آخر التنبيهات'**
  String get latestWarnings;

  /// No description provided for @noWarningsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات بعد'**
  String get noWarningsYet;

  /// No description provided for @tapToHearStatus.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لسماع الحالة'**
  String get tapToHearStatus;

  /// No description provided for @warningsAreOn.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات تعمل'**
  String get warningsAreOn;

  /// No description provided for @warningsAreOff.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات متوقفة'**
  String get warningsAreOff;

  /// No description provided for @turnWarningsOn.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل التنبيهات'**
  String get turnWarningsOn;

  /// No description provided for @turnWarningsOff.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التنبيهات'**
  String get turnWarningsOff;

  /// No description provided for @connectGlasses.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال بالنظارة'**
  String get connectGlasses;

  /// No description provided for @disconnectGlasses.
  ///
  /// In ar, this message translates to:
  /// **'قطع اتصال النظارة'**
  String get disconnectGlasses;

  /// No description provided for @settingsForHelper.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات، للمرافق'**
  String get settingsForHelper;

  /// No description provided for @aboutYou.
  ///
  /// In ar, this message translates to:
  /// **'عنك'**
  String get aboutYou;

  /// No description provided for @languageAndLook.
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمظهر'**
  String get languageAndLook;

  /// No description provided for @themeAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @voice.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get voice;

  /// No description provided for @speedSlow.
  ///
  /// In ar, this message translates to:
  /// **'بطيء'**
  String get speedSlow;

  /// No description provided for @speedNormal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get speedNormal;

  /// No description provided for @speedFast.
  ///
  /// In ar, this message translates to:
  /// **'سريع'**
  String get speedFast;

  /// No description provided for @voiceSample.
  ///
  /// In ar, this message translates to:
  /// **'هكذا سيكون صوت النطق'**
  String get voiceSample;

  /// No description provided for @autoSpeakSigns.
  ///
  /// In ar, this message translates to:
  /// **'انطق الإشارة فور قراءتها'**
  String get autoSpeakSigns;

  /// No description provided for @demoMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع التجربة'**
  String get demoMode;

  /// No description provided for @demoModeHint.
  ///
  /// In ar, this message translates to:
  /// **'نظارة افتراضية لعرض القسم قبل تجهيز القطعة الفعلية'**
  String get demoModeHint;

  /// No description provided for @glassesWifi.
  ///
  /// In ar, this message translates to:
  /// **'نظارة بالواي فاي'**
  String get glassesWifi;

  /// No description provided for @glassesWifiHint.
  ///
  /// In ar, this message translates to:
  /// **'للنظارة التي تتصل عبر شبكتها الخاصة بدل البلوتوث'**
  String get glassesWifiHint;

  /// No description provided for @showHiddenPhrases.
  ///
  /// In ar, this message translates to:
  /// **'إظهار العبارات المخفية ({count})'**
  String showHiddenPhrases(int count);

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String version(String version);

  /// No description provided for @credits.
  ///
  /// In ar, this message translates to:
  /// **'نموذج قراءة الإشارات مدرَّب على قاعدة بيانات KArSL للغة الإشارة العربية، ويستخدم MediaPipe من Google. الخط: IBM Plex Sans Arabic.'**
  String get credits;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
