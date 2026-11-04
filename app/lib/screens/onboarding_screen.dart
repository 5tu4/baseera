import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/settings_controller.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// First launch: who uses the app, then (for sighted users) how to address
/// them, so phrases come out as "أنا متعب" or "أنا متعبة".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  UserMode? _mode;
  bool _isFemale = false;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pickMode(UserMode mode) {
    final settings = AppScope.of(context).settings;
    if (mode == UserMode.blind) {
      // A blind user gets straight to the glasses; phrases aren't theirs.
      settings.userMode = mode;
      return;
    }
    setState(() => _mode = mode);
  }

  void _finish() {
    final settings = AppScope.of(context).settings;
    settings
      ..isFemale = _isFemale
      ..name = _name.text
      ..userMode = _mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpace.maxContentWidth,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.normal,
              child: _mode == null
                  ? _WhoStep(key: const ValueKey('who'), onPick: _pickMode)
                  : _AboutYouStep(
                      key: const ValueKey('about'),
                      isFemale: _isFemale,
                      name: _name,
                      onGender: (value) => setState(() => _isFemale = value),
                      onBack: () => setState(() => _mode = null),
                      onDone: _finish,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhoStep extends StatelessWidget {
  const _WhoStep({super.key, required this.onPick});

  final ValueChanged<UserMode> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.gutter),
      children: [
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _LanguageToggle(),
        ),
        const SizedBox(height: AppSpace.lg),
        const Center(child: BrandMark(size: 132)),
        const SizedBox(height: AppSpace.lg),
        Text(
          l10n.appName,
          textAlign: TextAlign.center,
          style: textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.tagline,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge!.copyWith(color: c.inkSoft),
        ),
        const SizedBox(height: AppSpace.xxl),
        Semantics(
          header: true,
          child: Text(l10n.whoUsesApp, style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpace.md),
        _ModeCard(
          icon: Icons.hearing_disabled_rounded,
          title: l10n.modeDeafTitle,
          subtitle: l10n.modeDeafSubtitle,
          onTap: () => onPick(UserMode.deaf),
        ),
        const SizedBox(height: AppSpace.md),
        _ModeCard(
          icon: Icons.visibility_rounded,
          title: l10n.modeBlindTitle,
          subtitle: l10n.modeBlindSubtitle,
          onTap: () => onPick(UserMode.blind),
        ),
        const SizedBox(height: AppSpace.md),
        _ModeCard(
          icon: Icons.diversity_1_rounded,
          title: l10n.modeCompanionTitle,
          subtitle: l10n.modeCompanionSubtitle,
          onTap: () => onPick(UserMode.companion),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          l10n.changeLaterHint,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 30, color: c.onPrimarySoft),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutYouStep extends StatelessWidget {
  const _AboutYouStep({
    super.key,
    required this.isFemale,
    required this.name,
    required this.onGender,
    required this.onBack,
    required this.onDone,
  });

  final bool isFemale;
  final TextEditingController name;
  final ValueChanged<bool> onGender;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.gutter),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IconButton(
            onPressed: onBack,
            tooltip: l10n.back,
            icon: const BackButtonIcon(),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          header: true,
          child: Text(l10n.howToAddressYou, style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.howToAddressYouHint,
          style: textTheme.bodyMedium!.copyWith(color: c.inkSoft),
        ),
        const SizedBox(height: AppSpace.lg),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: Text(l10n.male),
              icon: const Icon(Icons.man_rounded),
            ),
            ButtonSegment(
              value: true,
              label: Text(l10n.female),
              icon: const Icon(Icons.woman_rounded),
            ),
          ],
          selected: {isFemale},
          onSelectionChanged: (value) => onGender(value.first),
        ),
        const SizedBox(height: AppSpace.xl),
        Text(l10n.yourNameOptional, style: textTheme.titleSmall),
        const SizedBox(height: AppSpace.sm),
        TextField(
          controller: name,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: l10n.yourNameHint),
          onSubmitted: (_) => onDone(),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.yourNameWhy,
          style: textTheme.bodySmall!.copyWith(color: c.inkSoft),
        ),
        const SizedBox(height: AppSpace.xxl),
        FilledButton(
          style: accentButtonStyle(context),
          onPressed: onDone,
          child: Text(l10n.start),
        ),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final other = settings.language.isArabic ? AppLanguage.en : AppLanguage.ar;
    return TextButton.icon(
      onPressed: () => settings.language = other,
      icon: const Icon(Icons.translate_rounded, size: 20),
      label: Text(other.nativeName),
    );
  }
}
