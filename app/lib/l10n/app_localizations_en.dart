// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Baseera';

  @override
  String get tagline => 'Easier conversations, safer steps';

  @override
  String get back => 'Back';

  @override
  String get start => 'Start';

  @override
  String get tryAgain => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get all => 'All';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get undo => 'Undo';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get hide => 'Hide';

  @override
  String get save => 'Save';

  @override
  String get demo => 'Demo';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String batteryShort(int percent) {
    return '$percent%';
  }

  @override
  String batteryPercent(int percent) {
    return 'Battery $percent%';
  }

  @override
  String meters(String value) {
    return '$value m';
  }

  @override
  String get whoUsesApp => 'Who will use the app?';

  @override
  String get modeDeafTitle => 'Deaf or hard of hearing';

  @override
  String get modeDeafSubtitle =>
      'Sign translation, speech to text and ready phrases';

  @override
  String get modeBlindTitle => 'Blind or low vision';

  @override
  String get modeBlindSubtitle =>
      'The smart glasses, with a simple voice interface';

  @override
  String get modeCompanionTitle => 'A companion, or try every section';

  @override
  String get modeCompanionSubtitle =>
      'Every section in one place, including the glasses settings';

  @override
  String get changeLaterHint => 'You can change this later in settings';

  @override
  String get howToAddressYou => 'How should we address you?';

  @override
  String get howToAddressYouHint =>
      'Arabic phrases are worded to match, e.g. «أنا متعب» or «أنا متعبة».';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get yourNameOptional => 'Your name (optional)';

  @override
  String get yourNameHint => 'e.g. Sara';

  @override
  String get yourNameWhy => 'Adds a “My name is …” phrase to My voice.';

  @override
  String get signTitle => 'Understand me';

  @override
  String get listenTitle => 'Read your words';

  @override
  String get voiceTitle => 'My voice';

  @override
  String get glassesTitle => 'My glasses';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get signsIKnow => 'Signs I understand';

  @override
  String signsIKnowHint(int count) {
    return 'I currently understand $count signs. Tap one to see how it is signed.';
  }

  @override
  String get signsSource =>
      'Clips from the KArSL Arabic Sign Language dataset (KFUPM).';

  @override
  String howToSign(String word) {
    return 'How to sign “$word”';
  }

  @override
  String get switchCamera => 'Switch camera';

  @override
  String get diagnosticsTitle => 'Technical details';

  @override
  String get diagnosticsHint =>
      'Send these details to the developers so they can find the cause.';

  @override
  String get copyDetails => 'Copy';

  @override
  String get copiedDetails => 'Details copied';

  @override
  String get cameraPermissionTitle => 'We need permission to use the camera';

  @override
  String get cameraPermissionBody =>
      'Allow the app to use the camera in your device settings.';

  @override
  String get cameraUnavailableTitle => 'The camera couldn\'t start';

  @override
  String get cameraUnavailableBody =>
      'Make sure the camera works, then try again.';

  @override
  String get cameraStarting => 'Starting the camera…';

  @override
  String get modelLoading => 'Getting sign reading ready…';

  @override
  String get modelUnavailable => 'Sign reading isn\'t available on this device';

  @override
  String get tapForDetails => 'tap for details';

  @override
  String get hintSignInFrame => 'Sign inside the frame';

  @override
  String get hintSignThenLower => 'Sign, then lower your hands';

  @override
  String get hintWatching => 'Watching… lower your hands when done';

  @override
  String get hintUnsure => 'I didn\'t get that, sign again';

  @override
  String get noSignYet => 'No sign yet';

  @override
  String get wordsAppearHere => 'Words I understand appear here';

  @override
  String get speakWord => 'Say the word';

  @override
  String get sentenceHint => 'Each sign is added here to build a sentence';

  @override
  String get speakSentence => 'Say the sentence';

  @override
  String get deleteLastWord => 'Delete the last word';

  @override
  String get clearSentence => 'Clear the sentence';

  @override
  String get whatPeopleSay => 'What people around you say';

  @override
  String get smallerText => 'Smaller text';

  @override
  String get biggerText => 'Bigger text';

  @override
  String get clearSpeech => 'Clear the text';

  @override
  String get tapToListen => 'Tap to start listening';

  @override
  String get listeningTapToStop => 'Listening, tap to stop';

  @override
  String get listenProblem =>
      'Listening stopped because of a problem, try again';

  @override
  String get micPermissionTitle => 'We need permission to use the microphone';

  @override
  String get micPermissionBody =>
      'Allow the app to use the microphone in your device settings.';

  @override
  String get listenUnavailableTitle => 'Speech to text isn\'t available';

  @override
  String get listenUnavailableBody =>
      'Check your internet connection and that the Google app is installed, then try again.';

  @override
  String get listeningNow => 'Listening…';

  @override
  String get readyToListen => 'Ready to listen';

  @override
  String get listenHint =>
      'Ask the person in front of you to speak; their words appear here in large text.';

  @override
  String get startListening => 'Start listening';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get typeToSpeakHint => 'Type what you want to say…';

  @override
  String get speakIt => 'Say it';

  @override
  String get saveToMyWords => 'Save to My words';

  @override
  String get myWords => 'My words';

  @override
  String get addPhrase => 'Add words';

  @override
  String get newPhrase => 'New words';

  @override
  String get editPhrase => 'Edit words';

  @override
  String get phraseHint => 'Type the word or phrase';

  @override
  String get category => 'Category';

  @override
  String get tryVoice => 'Try it';

  @override
  String get phraseSaved => 'Saved to My words';

  @override
  String get phraseDeleted => 'Phrase deleted';

  @override
  String get phraseHidden => 'Phrase hidden';

  @override
  String get phraseTileHint => 'Tap to speak, long-press for options';

  @override
  String get noWordsYet => 'No words added yet';

  @override
  String get noWordsYetHint =>
      'Add the words and phrases you use often, and say them with one tap.';

  @override
  String get glassesConnected => 'Glasses connected';

  @override
  String get glassesConnecting => 'Connecting to the glasses';

  @override
  String get glassesDisconnected => 'Glasses not connected';

  @override
  String get glassesHint => 'Turn the glasses on, then tap Connect';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get demoExplain =>
      'Demo mode simulates the glasses until the real hardware is ready. You can turn it off in settings.';

  @override
  String get sensorAhead => 'Ahead';

  @override
  String get sensorFloor => 'Floor';

  @override
  String get cameraPreview => 'Glasses camera';

  @override
  String get cameraPreviewDemo => 'There\'s no camera in demo mode';

  @override
  String get cameraPreviewWaiting =>
      'The picture appears here once the glasses send it';

  @override
  String get warnings => 'Warnings';

  @override
  String get obstacleWarnings => 'Obstacle warnings';

  @override
  String get warningsOnHint => 'On';

  @override
  String get warningsOffHint => 'Off, no warnings will be given';

  @override
  String get warnFrom => 'Warn me from';

  @override
  String get glassesVoice => 'Glasses speaker';

  @override
  String get glassesVibration => 'Glasses vibration';

  @override
  String get phoneSpeaksWarnings => 'Speak warnings on the phone';

  @override
  String get phoneSpeaksWarningsHint => 'Useful with a Bluetooth earphone';

  @override
  String get testSound => 'Test sound';

  @override
  String get rotatePicture => 'Turn the picture';

  @override
  String get testVibration => 'Test vibration';

  @override
  String get latestWarnings => 'Latest warnings';

  @override
  String get noWarningsYet => 'No warnings yet';

  @override
  String get tapToHearStatus => 'Tap to hear the status';

  @override
  String get warningsAreOn => 'Warnings are on';

  @override
  String get warningsAreOff => 'Warnings are off';

  @override
  String get turnWarningsOn => 'Turn warnings on';

  @override
  String get turnWarningsOff => 'Turn warnings off';

  @override
  String get connectGlasses => 'Connect the glasses';

  @override
  String get disconnectGlasses => 'Disconnect the glasses';

  @override
  String get settingsForHelper => 'Settings, for a helper';

  @override
  String get aboutYou => 'About you';

  @override
  String get languageAndLook => 'Language and appearance';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get voice => 'Voice';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String get voiceSample => 'This is how the voice will sound';

  @override
  String get autoSpeakSigns => 'Say each sign as soon as it\'s read';

  @override
  String get demoMode => 'Demo mode';

  @override
  String get demoModeHint =>
      'Simulated glasses, to show the section before the hardware is ready';

  @override
  String get glassesWifi => 'Wi-Fi glasses';

  @override
  String get glassesWifiHint =>
      'For glasses that connect over their own Wi-Fi instead of Bluetooth';

  @override
  String showHiddenPhrases(int count) {
    return 'Show hidden phrases ($count)';
  }

  @override
  String get aboutApp => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get credits =>
      'The sign-reading model is trained on the KArSL Arabic Sign Language dataset and uses Google MediaPipe. Font: IBM Plex Sans Arabic.';
}
