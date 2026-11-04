"""Writes lib/l10n/app_ar.arb and app_en.arb from one table, so the two
languages always have the same keys. Run: python tool/make_arb.py
(then `flutter gen-l10n`, or just build — it runs automatically)."""
import json
from pathlib import Path


def params(*names, kind="String"):
    return {"placeholders": {n: {"type": kind} for n in names}}


def ints(*names):
    return params(*names, kind="int")


# key: (Arabic, English, placeholder metadata)
MESSAGES = {
    "appName": ("بصيرة", "Baseera", None),
    "tagline": ("تواصل أسهل، وخطوة أكثر أماناً", "Easier conversations, safer steps", None),
    "back": ("رجوع", "Back", None),
    "start": ("ابدأ", "Start", None),
    "tryAgain": ("حاول مرة أخرى", "Try again", None),
    "close": ("إغلاق", "Close", None),
    "cancel": ("إلغاء", "Cancel", None),
    "all": ("الكل", "All", None),
    "yes": ("نعم", "Yes", None),
    "no": ("لا", "No", None),
    "undo": ("تراجع", "Undo", None),
    "edit": ("تعديل", "Edit", None),
    "delete": ("حذف", "Delete", None),
    "hide": ("إخفاء", "Hide", None),
    "save": ("حفظ", "Save", None),
    "demo": ("تجربة", "Demo", None),
    "connected": ("متصلة", "Connected", None),
    "notConnected": ("غير متصلة", "Not connected", None),
    "batteryShort": ("{percent}%", "{percent}%", ints("percent")),
    "batteryPercent": ("البطارية {percent}%", "Battery {percent}%", ints("percent")),
    "meters": ("{value} م", "{value} m", params("value")),
    # Onboarding
    "whoUsesApp": ("من سيستخدم التطبيق؟", "Who will use the app?", None),
    "modeDeafTitle": ("أصم أو ضعيف سمع", "Deaf or hard of hearing", None),
    "modeDeafSubtitle": ("ترجمة الإشارة، وقراءة الكلام، وعبارات جاهزة", "Sign translation, speech to text and ready phrases", None),
    "modeBlindTitle": ("كفيف أو ضعيف بصر", "Blind or low vision", None),
    "modeBlindSubtitle": ("النظارة الذكية بواجهة صوتية بسيطة", "The smart glasses, with a simple voice interface", None),
    "modeCompanionTitle": ("مرافق أو تجربة كل الأقسام", "A companion, or try every section", None),
    "modeCompanionSubtitle": ("كل الأقسام في مكان واحد، ومنها إعدادات النظارة", "Every section in one place, including the glasses settings", None),
    "changeLaterHint": ("يمكنك تغيير ذلك لاحقاً من الإعدادات", "You can change this later in settings", None),
    "howToAddressYou": ("كيف نخاطبك؟", "How should we address you?", None),
    "howToAddressYouHint": (
        "نصوغ العبارات بحسب اختيارك، مثل: «أنا متعب» أو «أنا متعبة».",
        "Arabic phrases are worded to match, e.g. «أنا متعب» or «أنا متعبة».",
        None,
    ),
    "male": ("ذكر", "Male", None),
    "female": ("أنثى", "Female", None),
    "yourNameOptional": ("اسمك (اختياري)", "Your name (optional)", None),
    "yourNameHint": ("مثال: عبدالله", "e.g. Sara", None),
    "yourNameWhy": ("نضيف عبارة «اسمي ...» إلى صوتي.", "Adds a “My name is …” phrase to My voice.", None),
    # Sections
    "signTitle": ("افهمني", "Understand me", None),
    "listenTitle": ("أقرأ كلامك", "Read your words", None),
    "voiceTitle": ("صوتي", "My voice", None),
    "glassesTitle": ("نظارتي", "My glasses", None),
    "settingsTitle": ("الإعدادات", "Settings", None),
    # افهمني
    "signsIKnow": ("الإشارات التي أفهمها", "Signs I understand", None),
    "signsIKnowHint": (
        "أفهم {count} إشارة حالياً. اضغط على أي إشارة لترى طريقة أدائها.",
        "I currently understand {count} signs. Tap one to see how it is signed.",
        ints("count"),
    ),
    "signsSource": (
        "المقاطع من قاعدة بيانات KArSL للغة الإشارة العربية (جامعة الملك فهد للبترول والمعادن).",
        "Clips from the KArSL Arabic Sign Language dataset (KFUPM).",
        None,
    ),
    "howToSign": ("طريقة أداء إشارة «{word}»", "How to sign “{word}”", params("word")),
    "switchCamera": ("بدّل الكاميرا", "Switch camera", None),
    "diagnosticsTitle": ("معلومات تقنية", "Technical details", None),
    "diagnosticsHint": (
        "أرسل هذه المعلومات إلى فريق التطوير لمعرفة سبب المشكلة.",
        "Send these details to the developers so they can find the cause.",
        None,
    ),
    "copyDetails": ("نسخ", "Copy", None),
    "copiedDetails": ("تم نسخ المعلومات", "Details copied", None),
    "cameraPermissionTitle": ("نحتاج إذنك لاستخدام الكاميرا", "We need permission to use the camera", None),
    "cameraPermissionBody": ("اسمح للتطبيق باستخدام الكاميرا من إعدادات الجهاز.", "Allow the app to use the camera in your device settings.", None),
    "cameraUnavailableTitle": ("تعذّر تشغيل الكاميرا", "The camera couldn't start", None),
    "cameraUnavailableBody": ("تأكد أن الكاميرا تعمل، ثم حاول مرة أخرى.", "Make sure the camera works, then try again.", None),
    "cameraStarting": ("نجهّز الكاميرا...", "Starting the camera…", None),
    "modelLoading": ("نجهّز قراءة الإشارات...", "Getting sign reading ready…", None),
    "modelUnavailable": ("قراءة الإشارات غير متاحة على هذا الجهاز", "Sign reading isn't available on this device", None),
    "tapForDetails": ("اضغط للتفاصيل", "tap for details", None),
    "hintSignInFrame": ("أشِر داخل الإطار", "Sign inside the frame", None),
    "hintSignThenLower": ("أشِر، ثم أنزل يديك", "Sign, then lower your hands", None),
    "hintWatching": ("أراك... أنزل يديك عند الانتهاء", "Watching… lower your hands when done", None),
    "hintUnsure": ("لم أفهم، أعد الإشارة", "I didn't get that, sign again", None),
    "noSignYet": ("لم تظهر إشارة بعد", "No sign yet", None),
    "wordsAppearHere": ("الكلمات التي أفهمها تظهر هنا", "Words I understand appear here", None),
    "speakWord": ("انطق الكلمة", "Say the word", None),
    "sentenceHint": ("كل إشارة تُضاف هنا لتكوين جملة", "Each sign is added here to build a sentence", None),
    "speakSentence": ("انطق الجملة", "Say the sentence", None),
    "deleteLastWord": ("احذف آخر كلمة", "Delete the last word", None),
    "clearSentence": ("امسح الجملة", "Clear the sentence", None),
    # أقرأ كلامك
    "whatPeopleSay": ("ما يقوله من حولك", "What people around you say", None),
    "smallerText": ("تصغير النص", "Smaller text", None),
    "biggerText": ("تكبير النص", "Bigger text", None),
    "clearSpeech": ("امسح النص", "Clear the text", None),
    "tapToListen": ("اضغط لبدء الاستماع", "Tap to start listening", None),
    "listeningTapToStop": ("أستمع الآن، اضغط للإيقاف", "Listening, tap to stop", None),
    "listenProblem": ("توقف الاستماع بسبب مشكلة، حاول مرة أخرى", "Listening stopped because of a problem, try again", None),
    "micPermissionTitle": ("نحتاج إذنك لاستخدام الميكروفون", "We need permission to use the microphone", None),
    "micPermissionBody": ("اسمح للتطبيق باستخدام الميكروفون من إعدادات الجهاز.", "Allow the app to use the microphone in your device settings.", None),
    "listenUnavailableTitle": ("تحويل الكلام إلى نص غير متاح", "Speech to text isn't available", None),
    "listenUnavailableBody": (
        "تأكد من اتصالك بالإنترنت ومن تثبيت تطبيق Google، ثم حاول مرة أخرى.",
        "Check your internet connection and that the Google app is installed, then try again.",
        None,
    ),
    "listeningNow": ("أستمع الآن...", "Listening…", None),
    "readyToListen": ("جاهز للاستماع", "Ready to listen", None),
    "listenHint": (
        "اطلب من الشخص الذي أمامك أن يتكلم، وستظهر كلماته هنا بخط كبير.",
        "Ask the person in front of you to speak; their words appear here in large text.",
        None,
    ),
    "startListening": ("ابدأ الاستماع", "Start listening", None),
    "stopListening": ("أوقف الاستماع", "Stop listening", None),
    # صوتي
    "typeToSpeakHint": ("اكتب ما تريد قوله...", "Type what you want to say…", None),
    "speakIt": ("انطقها", "Say it", None),
    "saveToMyWords": ("احفظ في كلماتي", "Save to My words", None),
    "myWords": ("كلماتي", "My words", None),
    "addPhrase": ("أضف كلمة", "Add words", None),
    "newPhrase": ("كلمة جديدة", "New words", None),
    "editPhrase": ("تعديل الكلمة", "Edit words", None),
    "phraseHint": ("اكتب الكلمة أو العبارة", "Type the word or phrase", None),
    "category": ("القسم", "Category", None),
    "tryVoice": ("جرّب النطق", "Try it", None),
    "phraseSaved": ("حُفظت في كلماتي", "Saved to My words", None),
    "phraseDeleted": ("حُذفت العبارة", "Phrase deleted", None),
    "phraseHidden": ("أُخفيت العبارة", "Phrase hidden", None),
    "phraseTileHint": ("اضغط للنطق، واضغط مطولاً للخيارات", "Tap to speak, long-press for options", None),
    "noWordsYet": ("لم تُضف كلمات بعد", "No words added yet", None),
    "noWordsYetHint": (
        "أضف الكلمات والعبارات التي تحتاجها كثيراً، لتنطقها بضغطة واحدة.",
        "Add the words and phrases you use often, and say them with one tap.",
        None,
    ),
    # نظارتي
    "glassesConnected": ("النظارة متصلة", "Glasses connected", None),
    "glassesConnecting": ("جارٍ الاتصال بالنظارة", "Connecting to the glasses", None),
    "glassesDisconnected": ("النظارة غير متصلة", "Glasses not connected", None),
    "glassesHint": ("شغّل النظارة، ثم اضغط «اتصال»", "Turn the glasses on, then tap Connect", None),
    "connect": ("اتصال", "Connect", None),
    "disconnect": ("قطع الاتصال", "Disconnect", None),
    "demoExplain": (
        "وضع التجربة يحاكي النظارة حتى تجهز القطعة الفعلية، ويمكنك إيقافه من الإعدادات.",
        "Demo mode simulates the glasses until the real hardware is ready. You can turn it off in settings.",
        None,
    ),
    "sensorAhead": ("أمامك", "Ahead", None),
    "sensorFloor": ("الأرض", "Floor", None),
    "cameraPreview": ("كاميرا النظارة", "Glasses camera", None),
    "cameraPreviewDemo": ("لا توجد كاميرا في وضع التجربة", "There's no camera in demo mode", None),
    "cameraPreviewWaiting": ("ستظهر الصورة هنا عند وصولها من النظارة", "The picture appears here once the glasses send it", None),
    "warnings": ("التنبيهات", "Warnings", None),
    "obstacleWarnings": ("تنبيهات العوائق", "Obstacle warnings", None),
    "warningsOnHint": ("تعمل الآن", "On", None),
    "warningsOffHint": ("متوقفة، ولن يصل أي تنبيه", "Off, no warnings will be given", None),
    "warnFrom": ("نبّهني من مسافة", "Warn me from", None),
    "glassesVoice": ("صوت النظارة", "Glasses speaker", None),
    "glassesVibration": ("اهتزاز النظارة", "Glasses vibration", None),
    "phoneSpeaksWarnings": ("نطق التنبيهات من الجوال", "Speak warnings on the phone", None),
    "phoneSpeaksWarningsHint": ("مفيد مع سماعة بلوتوث", "Useful with a Bluetooth earphone", None),
    "testSound": ("اختبر الصوت", "Test sound", None),
    "testVibration": ("اختبر الاهتزاز", "Test vibration", None),
    "latestWarnings": ("آخر التنبيهات", "Latest warnings", None),
    "noWarningsYet": ("لا توجد تنبيهات بعد", "No warnings yet", None),
    # Blind mode
    "tapToHearStatus": ("اضغط لسماع الحالة", "Tap to hear the status", None),
    "warningsAreOn": ("التنبيهات تعمل", "Warnings are on", None),
    "warningsAreOff": ("التنبيهات متوقفة", "Warnings are off", None),
    "turnWarningsOn": ("تشغيل التنبيهات", "Turn warnings on", None),
    "turnWarningsOff": ("إيقاف التنبيهات", "Turn warnings off", None),
    "connectGlasses": ("الاتصال بالنظارة", "Connect the glasses", None),
    "disconnectGlasses": ("قطع اتصال النظارة", "Disconnect the glasses", None),
    "settingsForHelper": ("الإعدادات، للمرافق", "Settings, for a helper", None),
    # Settings
    "aboutYou": ("عنك", "About you", None),
    "languageAndLook": ("اللغة والمظهر", "Language and appearance", None),
    "themeAuto": ("تلقائي", "Auto", None),
    "themeLight": ("فاتح", "Light", None),
    "themeDark": ("داكن", "Dark", None),
    "voice": ("الصوت", "Voice", None),
    "speedSlow": ("بطيء", "Slow", None),
    "speedNormal": ("عادي", "Normal", None),
    "speedFast": ("سريع", "Fast", None),
    "voiceSample": ("هكذا سيكون صوت النطق", "This is how the voice will sound", None),
    "autoSpeakSigns": ("انطق الإشارة فور قراءتها", "Say each sign as soon as it's read", None),
    "demoMode": ("وضع التجربة", "Demo mode", None),
    "demoModeHint": (
        "نظارة افتراضية لعرض القسم قبل تجهيز القطعة الفعلية",
        "Simulated glasses, to show the section before the hardware is ready",
        None,
    ),
    "showHiddenPhrases": ("إظهار العبارات المخفية ({count})", "Show hidden phrases ({count})", ints("count")),
    "aboutApp": ("حول التطبيق", "About", None),
    "version": ("الإصدار {version}", "Version {version}", params("version")),
    "credits": (
        "نموذج قراءة الإشارات مدرَّب على قاعدة بيانات KArSL للغة الإشارة العربية، ويستخدم MediaPipe من Google. الخط: IBM Plex Sans Arabic.",
        "The sign-reading model is trained on the KArSL Arabic Sign Language dataset and uses Google MediaPipe. Font: IBM Plex Sans Arabic.",
        None,
    ),
}


def main():
    out = Path(__file__).resolve().parent.parent / "lib" / "l10n"
    ar, en = {"@@locale": "ar"}, {"@@locale": "en"}
    for key, (arabic, english, meta) in MESSAGES.items():
        ar[key] = arabic
        if meta:
            ar["@" + key] = meta
        en[key] = english
    for name, data in (("app_ar.arb", ar), ("app_en.arb", en)):
        (out / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(MESSAGES)} messages")


if __name__ == "__main__":
    main()
