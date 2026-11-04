import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/glasses/glasses_link.dart';
import '../services/settings_controller.dart';
import '../theme/tokens.dart';
import 'glasses_screen.dart';
import 'listen_screen.dart';
import 'settings_screen.dart';
import 'sign_screen.dart';
import 'voice_screen.dart';

enum HomeTab { sign, listen, voice, glasses }

/// Deaf and companion modes: one tab per section. Tabs keep their state
/// (the transcript, the sentence) while hidden; the camera and microphone
/// stop as soon as their tab is left.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.sign;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    // The app hands over the same const HomeShell when the mode changes, so
    // listen here or the glasses tab wouldn't appear until a restart.
    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) => _build(context, services),
    );
  }

  Widget _build(BuildContext context, AppServices services) {
    final l10n = context.l10n;
    final companion = services.settings.userMode == UserMode.companion;
    final tabs = [
      HomeTab.sign,
      HomeTab.listen,
      HomeTab.voice,
      if (companion) HomeTab.glasses,
    ];
    if (!tabs.contains(_tab)) _tab = HomeTab.sign;

    String title(HomeTab tab) => switch (tab) {
      HomeTab.sign => l10n.signTitle,
      HomeTab.listen => l10n.listenTitle,
      HomeTab.voice => l10n.voiceTitle,
      HomeTab.glasses => l10n.glassesTitle,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title(_tab)),
        actions: [
          if (companion && _tab != HomeTab.glasses)
            _GlassesChip(onTap: () => setState(() => _tab = HomeTab.glasses)),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: IndexedStack(
        index: tabs.indexOf(_tab),
        children: [
          for (final tab in tabs)
            switch (tab) {
              HomeTab.sign => SignScreen(active: _tab == HomeTab.sign),
              HomeTab.listen => ListenScreen(active: _tab == HomeTab.listen),
              HomeTab.voice => const VoiceScreen(),
              HomeTab.glasses => const GlassesScreen(),
            },
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.indexOf(_tab),
        onDestinationSelected: (i) => setState(() => _tab = tabs[i]),
        destinations: [
          for (final tab in tabs)
            switch (tab) {
              HomeTab.sign => NavigationDestination(
                icon: const Icon(Icons.sign_language_outlined),
                selectedIcon: const Icon(Icons.sign_language_rounded),
                label: l10n.signTitle,
              ),
              HomeTab.listen => NavigationDestination(
                icon: const Icon(Icons.subtitles_outlined),
                selectedIcon: const Icon(Icons.subtitles_rounded),
                label: l10n.listenTitle,
              ),
              HomeTab.voice => NavigationDestination(
                icon: const Icon(Icons.record_voice_over_outlined),
                selectedIcon: const Icon(Icons.record_voice_over_rounded),
                label: l10n.voiceTitle,
              ),
              HomeTab.glasses => NavigationDestination(
                icon: const Icon(Icons.visibility_outlined),
                selectedIcon: const Icon(Icons.visibility_rounded),
                label: l10n.glassesTitle,
              ),
            },
        ],
      ),
    );
  }
}

/// Connection dot + battery in the top bar; opens the glasses tab.
class _GlassesChip extends StatelessWidget {
  const _GlassesChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glasses = AppScope.of(context).glasses;
    final c = context.colors;
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: glasses,
      builder: (context, _) {
        final connected = glasses.connection == GlassesConnection.connected;
        final battery = glasses.battery;
        final label = connected
            ? (battery == null ? l10n.connected : l10n.batteryShort(battery))
            : l10n.notConnected;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Semantics(
            button: true,
            label: '${l10n.glassesTitle}: $label',
            excludeSemantics: true,
            child: ActionChip(
              onPressed: onTap,
              avatar: Icon(
                Icons.visibility_rounded,
                size: 18,
                color: connected ? c.success : c.inkFaint,
              ),
              label: Text(label),
            ),
          ),
        );
      },
    );
  }
}
