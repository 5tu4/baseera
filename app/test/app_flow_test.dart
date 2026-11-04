import 'dart:async';

import 'package:baseera/app.dart';
import 'package:baseera/recognition/sign_recognizer.dart';
import 'package:baseera/services/app_scope.dart';
import 'package:baseera/services/glasses/glasses_controller.dart';
import 'package:baseera/services/glasses/glasses_link.dart';
import 'package:baseera/services/phrases_store.dart';
import 'package:baseera/services/settings_controller.dart';
import 'package:baseera/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineLink implements GlassesLink {
  final _events = StreamController<GlassesEvent>.broadcast();

  @override
  Stream<GlassesEvent> get events => _events.stream;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void send(Map<String, Object?> command) {}

  @override
  Future<void> dispose() => _events.close();
}

AppServices _services() {
  final settings = SettingsController.memory();
  final tts = TtsService(settings);
  return AppServices(
    settings: settings,
    tts: tts,
    phrases: PhrasesStore.memory(),
    glasses: GlassesController(
      settings: settings,
      tts: tts,
      createLink: ({required bool demo}) => _OfflineLink(),
    ),
    createRecognizer: PendingSignRecognizer.new,
    findCameras: () async => const [],
  );
}

void main() {
  testWidgets('deaf user: onboarding, three tabs, add a word', (tester) async {
    final services = _services();
    await tester.pumpWidget(BaseeraApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('من سيستخدم التطبيق؟'), findsOneWidget);
    await tester.tap(find.text('أصم أو ضعيف سمع'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أنثى'));
    await tester.enterText(find.byType(TextField), 'سارة');
    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();

    expect(services.settings.userMode, UserMode.deaf);
    expect(services.settings.isFemale, isTrue);
    expect(services.settings.name, 'سارة');
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('نظارتي'), findsNothing);

    // صوتي: female forms and the name phrase are used.
    await tester.tap(find.widgetWithText(NavigationDestination, 'صوتي'));
    await tester.pumpAndSettle();
    expect(find.text('اسمي سارة'), findsOneWidget);
    await tester.tap(find.text('صحتي'));
    await tester.pumpAndSettle();
    expect(find.text('أنا مريضة'), findsOneWidget);

    // Add a word of their own.
    await tester.tap(find.text('أضف كلمة'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'اكتب الكلمة أو العبارة'),
      'أحتاج كرسياً متحركاً',
    );
    await tester.ensureVisible(find.text('حفظ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    final mine = services.phrases.custom.single;
    expect(mine.text, 'أحتاج كرسياً متحركاً');
    expect(
      mine.category.name,
      'health',
      reason: 'the open category is the default',
    );
    expect(find.text('أحتاج كرسياً متحركاً'), findsOneWidget);
  });

  testWidgets('switching to companion adds the glasses tab', (tester) async {
    final services = _services();
    services.settings.userMode = UserMode.deaf;
    await tester.pumpWidget(BaseeraApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مرافق أو تجربة كل الأقسام'));
    await tester.pumpAndSettle();

    expect(services.settings.userMode, UserMode.companion);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.tap(find.widgetWithText(NavigationDestination, 'نظارتي'));
    await tester.pumpAndSettle();
    expect(find.text('النظارة غير متصلة'), findsOneWidget);
    expect(find.text('تنبيهات العوائق'), findsOneWidget);
  });

  testWidgets('blind user goes straight to the voice-first screen', (
    tester,
  ) async {
    final services = _services();
    await tester.pumpWidget(BaseeraApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('كفيف أو ضعيف بصر'));
    await tester.pumpAndSettle();

    expect(services.settings.userMode, UserMode.blind);
    expect(services.glasses.wantsConnection, isTrue, reason: 'auto-connects');
    expect(find.text('إيقاف التنبيهات'), findsOneWidget);

    await tester.tap(find.text('إيقاف التنبيهات'));
    await tester.pumpAndSettle();
    expect(services.settings.alertsOn, isFalse);
    expect(find.text('تشغيل التنبيهات'), findsOneWidget);
  });
}
