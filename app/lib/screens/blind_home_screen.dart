import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/glasses/glasses_controller.dart';
import '../services/glasses/glasses_link.dart';
import '../services/settings_controller.dart';
import '../theme/tokens.dart';
import 'settings_screen.dart';

/// Blind mode: one screen, three huge targets, everything spoken.
///
/// The top panel reads the whole status aloud when tapped (double-tapped with
/// TalkBack). The glasses connect by themselves when the screen opens.
class BlindHomeScreen extends StatefulWidget {
  const BlindHomeScreen({super.key});

  @override
  State<BlindHomeScreen> createState() => _BlindHomeScreenState();
}

class _BlindHomeScreenState extends State<BlindHomeScreen> {
  late final AppServices _services = AppScope.of(context);

  @override
  void initState() {
    super.initState();
    final glasses = _services.glasses;
    if (!glasses.wantsConnection) glasses.connect();
  }

  String _status(BuildContext context) {
    final l10n = context.l10n;
    final glasses = _services.glasses;
    final settings = _services.settings;
    final battery = glasses.battery;
    return [
      switch (glasses.connection) {
        GlassesConnection.connected => l10n.glassesConnected,
        GlassesConnection.connecting => l10n.glassesConnecting,
        GlassesConnection.disconnected => l10n.glassesDisconnected,
      },
      if (glasses.isConnected && battery != null) l10n.batteryPercent(battery),
      settings.alertsOn ? l10n.warningsAreOn : l10n.warningsAreOff,
    ].join('. ');
  }

  void _toggleAlerts(BuildContext context) {
    _services.glasses.toggleAlerts();
    final l10n = context.l10n;
    _services.tts.speak(
      _services.settings.alertsOn ? l10n.warningsAreOn : l10n.warningsAreOff,
    );
  }

  void _toggleConnection(BuildContext context) {
    final glasses = _services.glasses;
    final l10n = context.l10n;
    if (glasses.connection == GlassesConnection.disconnected) {
      glasses.connect();
      _services.tts.speak(l10n.glassesConnecting);
    } else {
      glasses.disconnect();
      _services.tts.speak(l10n.glassesDisconnected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.settingsForHelper,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.gutter),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _services.glasses,
              _services.settings,
            ]),
            builder: (context, _) {
              final glasses = _services.glasses;
              final settings = _services.settings;
              final connected = glasses.isConnected;
              final status = _status(context);
              final last = glasses.lastAlert;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: status,
                      hint: l10n.tapToHearStatus,
                      excludeSemantics: true,
                      child: Material(
                        color: connected ? c.primary : c.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _services.tts.speak(status),
                          child: _StatusPanel(
                            glasses: glasses,
                            settings: settings,
                            lastAlert: last?.text(AppLanguage.of(context)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _HugeButton(
                    icon: settings.alertsOn
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_active_rounded,
                    label: settings.alertsOn
                        ? l10n.turnWarningsOff
                        : l10n.turnWarningsOn,
                    background: c.accent,
                    foreground: c.onAccent,
                    onPressed: () => _toggleAlerts(context),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _HugeButton(
                    icon: glasses.connection == GlassesConnection.disconnected
                        ? Icons.link_rounded
                        : Icons.link_off_rounded,
                    label: glasses.connection == GlassesConnection.disconnected
                        ? l10n.connectGlasses
                        : l10n.disconnectGlasses,
                    background: c.surface,
                    foreground: c.ink,
                    onPressed: () => _toggleConnection(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.glasses,
    required this.settings,
    required this.lastAlert,
  });

  final GlassesController glasses;
  final SettingsController settings;
  final String? lastAlert;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final connected = glasses.isConnected;
    final ink = connected ? c.onPrimary : c.ink;
    final soft = connected ? c.onPrimary.withValues(alpha: 0.8) : c.inkSoft;
    final battery = glasses.battery;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            connected ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 88,
            color: connected ? c.accent : c.inkFaint,
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            switch (glasses.connection) {
              GlassesConnection.connected => l10n.glassesConnected,
              GlassesConnection.connecting => l10n.glassesConnecting,
              GlassesConnection.disconnected => l10n.glassesDisconnected,
            },
            textAlign: TextAlign.center,
            style: textTheme.displaySmall!.copyWith(color: ink),
          ),
          if (connected && battery != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.batteryPercent(battery),
              style: textTheme.headlineSmall!.copyWith(color: soft),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Text(
            settings.alertsOn ? l10n.warningsAreOn : l10n.warningsAreOff,
            style: textTheme.titleLarge!.copyWith(color: soft),
          ),
          if (lastAlert != null) ...[
            const SizedBox(height: AppSpace.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: connected ? Colors.white12 : c.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                lastAlert!,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge!.copyWith(color: ink),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text(
            l10n.tapToHearStatus,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium!.copyWith(color: soft),
          ),
        ],
      ),
    );
  }
}

class _HugeButton extends StatelessWidget {
  const _HugeButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: foreground),
                const SizedBox(width: AppSpace.md),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall!.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
