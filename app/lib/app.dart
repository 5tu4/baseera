import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n.dart';
import 'screens/blind_home_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_scope.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';

class BaseeraApp extends StatelessWidget {
  const BaseeraApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) {
          final settings = services.settings;
          return MaterialApp(
            onGenerateTitle: (context) => context.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: settings.themeMode,
            // Arabic (right-to-left) or English, picked in settings;
            // strings live in lib/l10n/app_*.arb (tool/make_arb.py).
            locale: settings.language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            // Status bar icons follow the theme (screens without an app bar
            // don't get this from AppBar).
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value:
                  (Theme.of(context).brightness == Brightness.dark
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark)
                      .copyWith(statusBarColor: Colors.transparent),
              child: child!,
            ),
            home: switch (settings.userMode) {
              null => const OnboardingScreen(),
              UserMode.blind => const BlindHomeScreen(),
              UserMode.deaf || UserMode.companion => const HomeShell(),
            },
          );
        },
      ),
    );
  }
}
