import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/settings_controller.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppServices _services = AppScope.of(context);
  late final _name = TextEditingController(text: _services.settings.name);
  final _version = PackageInfo.fromPlatform().then(
    (info) => info.version,
    onError: (_) => '',
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([_services.settings, _services.phrases]),
        builder: (context, _) {
          final settings = _services.settings;
          final textTheme = Theme.of(context).textTheme;
          final c = context.colors;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.xxl,
            ),
            children: [
              SectionLabel(l10n.whoUsesApp),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Column(
                  children: [
                    for (final (mode, icon, title) in [
                      (
                        UserMode.deaf,
                        Icons.hearing_disabled_rounded,
                        l10n.modeDeafTitle,
                      ),
                      (
                        UserMode.blind,
                        Icons.visibility_rounded,
                        l10n.modeBlindTitle,
                      ),
                      (
                        UserMode.companion,
                        Icons.diversity_1_rounded,
                        l10n.modeCompanionTitle,
                      ),
                    ])
                      ListTile(
                        leading: Icon(icon),
                        title: Text(title),
                        selected: settings.userMode == mode,
                        selectedColor: c.onPrimarySoft,
                        trailing: settings.userMode == mode
                            ? Icon(Icons.check_circle_rounded, color: c.primary)
                            : null,
                        onTap: () {
                          settings.userMode = mode;
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                      ),
                  ],
                ),
              ),
              if (settings.userMode != UserMode.blind) ...[
                SectionLabel(l10n.aboutYou),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: false, label: Text(l10n.male)),
                          ButtonSegment(value: true, label: Text(l10n.female)),
                        ],
                        selected: {settings.isFemale},
                        onSelectionChanged: (v) => settings.isFemale = v.first,
                      ),
                      const SizedBox(height: AppSpace.md),
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          hintText: l10n.yourNameOptional,
                        ),
                        onChanged: (value) => settings.name = value,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        l10n.yourNameWhy,
                        style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
              SectionLabel(l10n.languageAndLook),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<AppLanguage>(
                      showSelectedIcon: false,
                      segments: [
                        for (final language in AppLanguage.values)
                          ButtonSegment(
                            value: language,
                            label: Text(language.nativeName),
                          ),
                      ],
                      selected: {settings.language},
                      onSelectionChanged: (v) => settings.language = v.first,
                    ),
                    const SizedBox(height: AppSpace.md),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.themeAuto),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.themeDark),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (v) => settings.themeMode = v.first,
                    ),
                  ],
                ),
              ),
              SectionLabel(l10n.voice),
              SurfaceCard(
                padding: const EdgeInsets.only(top: AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                      ),
                      child: SegmentedButton<SpeechSpeed>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: SpeechSpeed.slow,
                            label: Text(l10n.speedSlow),
                          ),
                          ButtonSegment(
                            value: SpeechSpeed.normal,
                            label: Text(l10n.speedNormal),
                          ),
                          ButtonSegment(
                            value: SpeechSpeed.fast,
                            label: Text(l10n.speedFast),
                          ),
                        ],
                        selected: {settings.speed},
                        onSelectionChanged: (v) {
                          settings.speed = v.first;
                          _services.tts.speak(l10n.voiceSample);
                        },
                      ),
                    ),
                    if (settings.userMode != UserMode.blind)
                      SwitchListTile(
                        value: settings.autoSpeak,
                        onChanged: (v) => settings.autoSpeak = v,
                        title: Text(l10n.autoSpeakSigns),
                      )
                    else
                      const SizedBox(height: AppSpace.lg),
                  ],
                ),
              ),
              SectionLabel(l10n.glassesTitle),
              SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.glassesDemo,
                      onChanged: (v) => settings.glassesDemo = v,
                      title: Text(l10n.demoMode),
                      subtitle: Text(l10n.demoModeHint),
                    ),
                    SwitchListTile(
                      value: settings.glassesWifi,
                      onChanged: (v) => settings.glassesWifi = v,
                      title: Text(l10n.glassesWifi),
                      subtitle: Text(l10n.glassesWifiHint),
                    ),
                  ],
                ),
              ),
              if (_services.phrases.hasHidden) ...[
                SectionLabel(l10n.voiceTitle),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: ListTile(
                    leading: const Icon(Icons.visibility_rounded),
                    title: Text(
                      l10n.showHiddenPhrases(_services.phrases.hiddenCount),
                    ),
                    onTap: _services.phrases.showAllHidden,
                  ),
                ),
              ],
              SectionLabel(l10n.aboutApp),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BrandMark(size: 52),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: FutureBuilder(
                            future: _version,
                            builder: (context, snapshot) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.appName,
                                  style: textTheme.titleMedium,
                                ),
                                Text(
                                  l10n.version(snapshot.data ?? ''),
                                  style: textTheme.bodySmall!.copyWith(
                                    color: c.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      l10n.credits,
                      style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
