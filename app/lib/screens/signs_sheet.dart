import 'package:flutter/material.dart';

import '../data/vocabulary.dart';
import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// The signs the model knows, grouped; tapping one shows how it is signed.
Future<void> showSignsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => _SignsList(scroll: scroll),
    ),
  );
}

class _SignsList extends StatelessWidget {
  const _SignsList({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;
    final language = AppLanguage.of(context);
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Text(l10n.signsIKnow, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.signsIKnowHint(vocabulary.length),
          style: textTheme.bodyMedium!.copyWith(color: c.inkSoft),
        ),
        for (final category in SignCategory.values) ...[
          SectionLabel(category.label(language)),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final sign in vocabulary)
                if (sign.category == category) _SignChip(sign: sign),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        Text(
          l10n.signsSource,
          style: textTheme.bodySmall!.copyWith(color: c.inkFaint),
        ),
      ],
    );
  }
}

class _SignChip extends StatelessWidget {
  const _SignChip({required this.sign});

  final SignWord sign;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final word = sign.wordIn(AppLanguage.of(context));
    return Material(
      color: c.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _SignClipDialog(sign: sign),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm + 2,
          ),
          child: Text(word, style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
    );
  }
}

class _SignClipDialog extends StatelessWidget {
  const _SignClipDialog({required this.sign});

  final SignWord sign;

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = context.l10n;
    final c = context.colors;
    final word = sign.wordIn(AppLanguage.of(context));
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ColoredBox(
                color: c.cameraGround,
                child: Image.asset(
                  sign.clipAsset,
                  height: 260,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  semanticLabel: l10n.howToSign(word),
                  errorBuilder: (_, _, _) => SizedBox(
                    height: 160,
                    child: Center(
                      child: Icon(
                        Icons.sign_language_rounded,
                        size: 64,
                        color: c.onPrimarySoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(word, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => services.tts.speak(word),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(l10n.speakWord),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
