import 'package:flutter/material.dart';

import '../data/phrases.dart';
import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/phrases_store.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// What the editor hands back.
typedef PhraseDraft = ({String text, PhraseCategory category});

/// Add a new word or phrase (or edit one of the user's own).
Future<PhraseDraft?> showPhraseEditor(
  BuildContext context, {
  CustomPhrase? editing,
  String? initialText,
  PhraseCategory? initialCategory,
}) {
  return showModalBottomSheet<PhraseDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PhraseEditor(
      editing: editing,
      initialText: initialText,
      initialCategory: initialCategory,
    ),
  );
}

class _PhraseEditor extends StatefulWidget {
  const _PhraseEditor({
    required this.editing,
    required this.initialText,
    required this.initialCategory,
  });

  final CustomPhrase? editing;
  final String? initialText;
  final PhraseCategory? initialCategory;

  @override
  State<_PhraseEditor> createState() => _PhraseEditorState();
}

class _PhraseEditorState extends State<_PhraseEditor> {
  late final _text = TextEditingController(
    text: widget.editing?.text ?? widget.initialText ?? '',
  );
  late PhraseCategory _category =
      widget.editing?.category ??
      widget.initialCategory ??
      PhraseCategory.basics;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    Navigator.pop<PhraseDraft>(context, (text: text, category: _category));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final language = AppLanguage.of(context);
    final tts = AppScope.of(context).tts;

    return Padding(
      // Keep the fields above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          AppSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.editing == null ? l10n.newPhrase : l10n.editPhrase,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: _text,
              autofocus: widget.editing == null && widget.initialText == null,
              minLines: 2,
              maxLines: 4,
              maxLength: 120,
              style: textTheme.titleMedium,
              decoration: InputDecoration(hintText: l10n.phraseHint),
            ),
            SectionLabel(l10n.category),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final category in PhraseCategory.values)
                  ChoiceChip(
                    label: Text(category.label(language)),
                    showCheckmark: false,
                    selected: _category == category,
                    labelStyle: textTheme.labelMedium!.copyWith(
                      color: _category == category ? c.onPrimary : c.ink,
                    ),
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            ValueListenableBuilder(
              valueListenable: _text,
              builder: (context, value, _) {
                final empty = value.text.trim().isEmpty;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: empty
                            ? null
                            : () => tts.speak(value.text.trim()),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: Text(l10n.tryVoice),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: FilledButton(
                        style: accentButtonStyle(context),
                        onPressed: empty ? null : _save,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
