import 'package:flutter/material.dart';

import '../data/obstacles.dart';
import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/glasses/glasses_controller.dart';
import '../services/glasses/glasses_link.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// نظارتي (companion view): connection, live sensors (on glasses that have
/// them), camera, warning settings and the latest warnings. The blind user's
/// own screen is `BlindHomeScreen`.
class GlassesScreen extends StatelessWidget {
  const GlassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([services.glasses, services.settings]),
      builder: (context, _) {
        final glasses = services.glasses;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.xs,
            AppSpace.gutter,
            AppSpace.xxl,
          ),
          children: [
            _ConnectionCard(glasses: glasses),
            if (glasses.isConnected) ...[
              if (glasses.hasDistanceSensors) ...[
                const SizedBox(height: AppSpace.md),
                _SensorsCard(glasses: glasses),
              ],
              const SizedBox(height: AppSpace.md),
              _CameraCard(glasses: glasses),
            ],
            SectionLabel(context.l10n.warnings),
            const _WarningSettings(),
            SectionLabel(context.l10n.latestWarnings),
            _RecentWarnings(alerts: glasses.alerts),
          ],
        );
      },
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.glasses});

  final GlassesController glasses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final state = glasses.connection;
    final battery = glasses.battery;

    final (title, color) = switch (state) {
      GlassesConnection.connected => (l10n.glassesConnected, c.success),
      GlassesConnection.connecting => (l10n.glassesConnecting, c.accent),
      GlassesConnection.disconnected => (l10n.glassesDisconnected, c.inkFaint),
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 30,
                  color: c.onPrimarySoft,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(title, style: textTheme.titleMedium),
                        ),
                      ],
                    ),
                    Text(
                      state == GlassesConnection.connected && battery != null
                          ? l10n.batteryPercent(battery)
                          : l10n.glassesHint,
                      style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
                    ),
                  ],
                ),
              ),
              if (glasses.isDemo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    l10n.demo,
                    style: textTheme.labelSmall!.copyWith(
                      color: c.onAccentSoft,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          switch (state) {
            GlassesConnection.connected => OutlinedButton.icon(
              onPressed: glasses.disconnect,
              icon: const Icon(Icons.link_off_rounded),
              label: Text(l10n.disconnect),
            ),
            GlassesConnection.connecting => FilledButton.icon(
              onPressed: glasses.disconnect,
              icon: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              label: Text(l10n.cancel),
            ),
            GlassesConnection.disconnected => FilledButton.icon(
              onPressed: glasses.connect,
              icon: const Icon(Icons.link_rounded),
              label: Text(l10n.connect),
            ),
          },
          if (glasses.isDemo) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.demoExplain,
              style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _SensorsCard extends StatelessWidget {
  const _SensorsCard({required this.glasses});

  final GlassesController glasses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = AppScope.of(context).settings;
    return SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _DistanceMeter(
              label: l10n.sensorAhead,
              icon: Icons.straight_rounded,
              cm: glasses.frontCm,
              warnBelowCm: settings.alertDistanceCm,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: _DistanceMeter(
              label: l10n.sensorFloor,
              icon: Icons.south_rounded,
              cm: glasses.downCm,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceMeter extends StatelessWidget {
  const _DistanceMeter({
    required this.label,
    required this.icon,
    required this.cm,
    this.warnBelowCm,
  });

  final String label;
  final IconData icon;
  final int? cm;
  final int? warnBelowCm;

  static const _fullScaleCm = 300;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final cm = this.cm;
    final warn = cm != null && warnBelowCm != null && cm < warnBelowCm!;
    final color = warn ? c.danger : c.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: c.inkSoft),
            const SizedBox(width: AppSpace.xs),
            Text(
              label,
              style: textTheme.labelMedium!.copyWith(color: c.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          cm == null ? '—' : context.l10n.meters((cm / 100).toStringAsFixed(1)),
          style: textTheme.headlineMedium!.copyWith(color: color),
        ),
        const SizedBox(height: AppSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: cm == null ? 0 : (cm / _fullScaleCm).clamp(0, 1).toDouble(),
            color: color,
            backgroundColor: c.surfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.glasses});

  final GlassesController glasses;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = AppScope.of(context).settings;
    final frame = glasses.frame;
    final turns = settings.cameraQuarterTurns;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: frame != null && turns.isOdd ? 3 / 4 : 4 / 3,
        child: ColoredBox(
          color: c.cameraGround,
          child: frame == null
              ? Center(
                  child: StatusMessage(
                    onDark: true,
                    icon: Icons.videocam_outlined,
                    title: context.l10n.cameraPreview,
                    message: glasses.isDemo
                        ? context.l10n.cameraPreviewDemo
                        : context.l10n.cameraPreviewWaiting,
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // The obstacle model sees the picture turned the same way.
                    RotatedBox(
                      quarterTurns: turns,
                      child: Image.memory(
                        frame,
                        gaplessPlayback: true,
                        fit: BoxFit.cover,
                      ),
                    ),
                    PositionedDirectional(
                      top: AppSpace.sm,
                      end: AppSpace.sm,
                      child: IconButton.filledTonal(
                        tooltip: context.l10n.rotatePicture,
                        icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
                        onPressed: () =>
                            settings.cameraQuarterTurns = turns + 1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WarningSettings extends StatelessWidget {
  const _WarningSettings();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    final glasses = services.glasses;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;
    final on = settings.alertsOn;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        children: [
          SwitchListTile(
            value: on,
            onChanged: (value) => settings.alertsOn = value,
            title: Text(l10n.obstacleWarnings),
            subtitle: Text(on ? l10n.warningsOnHint : l10n.warningsOffHint),
          ),
          // The warning distance and the glasses' own voice only exist on
          // glasses with distance sensors and a speaker.
          if (glasses.hasDistanceSensors) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.warnFrom, style: textTheme.titleMedium),
                  ),
                  Text(
                    l10n.meters(
                      (settings.alertDistanceCm / 100).toStringAsFixed(1),
                    ),
                    style: textTheme.titleMedium!.copyWith(
                      color: c.onPrimarySoft,
                    ),
                  ),
                ],
              ),
            ),
            Slider(
              value: settings.alertDistanceCm.toDouble(),
              min: 50,
              max: 250,
              divisions: 8,
              label: l10n.meters(
                (settings.alertDistanceCm / 100).toStringAsFixed(1),
              ),
              onChanged: on
                  ? (value) => settings.alertDistanceCm = value.round()
                  : null,
            ),
          ],
          if (glasses.hasSpeaker)
            SwitchListTile(
              value: settings.glassesVoice,
              onChanged: on ? (value) => settings.glassesVoice = value : null,
              title: Text(l10n.glassesVoice),
            ),
          SwitchListTile(
            value: settings.glassesVibration,
            onChanged: on ? (value) => settings.glassesVibration = value : null,
            title: Text(l10n.glassesVibration),
          ),
          SwitchListTile(
            value: settings.phoneSpeaksAlerts,
            onChanged: on
                ? (value) => settings.phoneSpeaksAlerts = value
                : null,
            title: Text(l10n.phoneSpeaksWarnings),
            subtitle: Text(l10n.phoneSpeaksWarningsHint),
          ),
          const _TestButtons(),
        ],
      ),
    );
  }
}

class _TestButtons extends StatelessWidget {
  const _TestButtons();

  @override
  Widget build(BuildContext context) {
    final glasses = AppScope.of(context).glasses;
    final l10n = context.l10n;
    final enabled = glasses.isConnected;
    // Without a speaker on the glasses, the sound test is the phone's voice.
    final soundEnabled = enabled || !glasses.hasSpeaker;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: soundEnabled ? glasses.testSound : null,
              icon: const Icon(Icons.volume_up_rounded),
              label: Text(l10n.testSound),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled ? glasses.testVibration : null,
              icon: const Icon(Icons.vibration_rounded),
              label: Text(l10n.testVibration),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentWarnings extends StatelessWidget {
  const _RecentWarnings({required this.alerts});

  final List<ObstacleAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final language = AppLanguage.of(context);
    if (alerts.isEmpty) {
      return SurfaceCard(
        child: Text(
          context.l10n.noWarningsYet,
          style: textTheme.bodyMedium!.copyWith(color: c.inkSoft),
        ),
      );
    }
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          for (final alert in alerts.take(10))
            ListTile(
              dense: true,
              leading: Icon(
                switch (alert.kind.risk) {
                  ObstacleRisk.fall => Icons.warning_rounded,
                  ObstacleRisk.moving => Icons.directions_walk_rounded,
                  ObstacleRisk.still => Icons.square_rounded,
                },
                color: switch (alert.kind.risk) {
                  ObstacleRisk.fall => c.danger,
                  ObstacleRisk.moving => c.onAccentSoft,
                  ObstacleRisk.still => c.inkSoft,
                },
              ),
              title: Text(alert.text(language), style: textTheme.titleSmall),
              trailing: Text(
                MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(TimeOfDay.fromDateTime(alert.time)),
                style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
              ),
            ),
        ],
      ),
    );
  }
}
