import 'package:flutter/material.dart';

import '../data/phrases.dart';
import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../services/phrases_store.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'phrase_editor_sheet.dart';

/// Which cards the board shows.
sealed class _Filter {
  const _Filter();
}

class _All extends _Filter {
  const _All();
}

class _Mine extends _Filter {
  const _Mine();
}

class _InCategory extends _Filter {
  const _InCategory(this.category);

  final PhraseCategory category;

  @override
  bool operator ==(Object other) =>
      other is _InCategory && other.category == category;

  @override
  int get hashCode => category.hashCode;
}

/// صوتي: the phone speaks for the user — typed text, yes/no, ready phrases
/// and the user's own words, which they can add, edit and remove.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  _Filter _filter = const _All();
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _openEditor({CustomPhrase? editing, String? initialText}) async {
    final services = AppScope.of(context);
    final result = await showPhraseEditor(
      context,
      editing: editing,
      initialText: initialText,
      initialCategory: switch (_filter) {
        _InCategory(:final category) => category,
        _ => null,
      },
    );
    if (result == null || !mounted) return;
    if (editing == null) {
      services.phrases.add(text: result.text, category: result.category);
      if (initialText != null) _typed.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.phraseSaved)));
    } else {
      services.phrases.update(
        editing.copyWith(text: result.text, category: result.category),
      );
    }
  }

  void _remove(PhraseCard card) {
    final store = AppScope.of(context).phrases;
    final custom = store.customById(card.id);
    final index = custom == null ? 0 : store.custom.indexOf(custom);
    store.remove(card.id);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(card.isCustom ? l10n.phraseDeleted : l10n.phraseHidden),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () =>
                store.restore(card.id, custom: custom, index: index),
          ),
        ),
      );
  }

  Future<void> _showActions(PhraseCard card) async {
    final services = AppScope.of(context);
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                0,
                AppSpace.xl,
                AppSpace.md,
              ),
              child: Text(
                card.text,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up_rounded),
              title: Text(l10n.speakIt),
              onTap: () => Navigator.pop(sheetContext, 'speak'),
            ),
            if (card.isCustom)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(l10n.edit),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
            ListTile(
              leading: Icon(
                card.isCustom
                    ? Icons.delete_outline_rounded
                    : Icons.visibility_off_outlined,
              ),
              title: Text(card.isCustom ? l10n.delete : l10n.hide),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'speak':
        services.tts.speak(card.text, id: card.id);
      case 'edit':
        final custom = services.phrases.customById(card.id);
        if (custom != null) await _openEditor(editing: custom);
      case 'remove':
        _remove(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-phrase',
        onPressed: _openEditor,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addPhrase),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          services.settings,
          services.phrases,
          services.tts,
        ]),
        builder: (context, _) {
          final settings = services.settings;
          final language = AppLanguage.of(context);
          final speakingId = services.tts.speakingId;
          final cards = services.phrases.cards(
            language: language,
            isFemale: settings.isFemale,
            name: settings.name,
            category: switch (_filter) {
              _InCategory(:final category) => category,
              _ => null,
            },
            customOnly: _filter is _Mine,
          );

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xs,
                  AppSpace.gutter,
                  0,
                ),
                sliver: SliverList.list(
                  children: [
                    _TypeToSpeak(
                      controller: _typed,
                      speaking: speakingId == 'typed',
                      onSpeak: (text) => services.tts.speak(text, id: 'typed'),
                      onSave: (text) => _openEditor(initialText: text),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: _YesNoButton(
                            label: l10n.yes,
                            icon: Icons.thumb_up_rounded,
                            positive: true,
                            speaking: speakingId == 'yes',
                            onPressed: () =>
                                services.tts.speak(l10n.yes, id: 'yes'),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: _YesNoButton(
                            label: l10n.no,
                            icon: Icons.thumb_down_rounded,
                            positive: false,
                            speaking: speakingId == 'no',
                            onPressed: () =>
                                services.tts.speak(l10n.no, id: 'no'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.gutter,
                      vertical: AppSpace.sm,
                    ),
                    children: [
                      _FilterChip(
                        label: l10n.all,
                        selected: _filter is _All,
                        onSelected: () =>
                            setState(() => _filter = const _All()),
                      ),
                      _FilterChip(
                        label: l10n.myWords,
                        icon: Icons.bookmark_rounded,
                        selected: _filter is _Mine,
                        onSelected: () =>
                            setState(() => _filter = const _Mine()),
                      ),
                      for (final category in PhraseCategory.values)
                        _FilterChip(
                          label: category.label(language),
                          selected: _filter == _InCategory(category),
                          onSelected: () =>
                              setState(() => _filter = _InCategory(category)),
                        ),
                    ],
                  ),
                ),
              ),
              if (cards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: StatusMessage(
                      icon: Icons.bookmark_add_outlined,
                      title: l10n.noWordsYet,
                      message: l10n.noWordsYetHint,
                      actionLabel: l10n.addPhrase,
                      onAction: _openEditor,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.xs,
                    AppSpace.gutter,
                    // Room for the add button.
                    96,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisExtent: 104,
                          mainAxisSpacing: AppSpace.md,
                          crossAxisSpacing: AppSpace.md,
                        ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _PhraseTile(
                        card: card,
                        speaking: speakingId == card.id,
                        onPressed: () =>
                            services.tts.speak(card.text, id: card.id),
                        onLongPress: () => _showActions(card),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Type anything and have it spoken; keep it with one tap.
class _TypeToSpeak extends StatelessWidget {
  const _TypeToSpeak({
    required this.controller,
    required this.speaking,
    required this.onSpeak,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool speaking;
  final ValueChanged<String> onSpeak;
  final ValueChanged<String> onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) {
          final text = value.text.trim();
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: l10n.typeToSpeakHint,
                    fillColor: Colors.transparent,
                  ),
                  onSubmitted: (value) => onSpeak(value.trim()),
                ),
              ),
              RoundIconButton(
                icon: Icons.bookmark_add_outlined,
                label: l10n.saveToMyWords,
                background: Colors.transparent,
                onPressed: text.isEmpty ? null : () => onSave(text),
              ),
              const SizedBox(width: AppSpace.xs),
              RoundIconButton(
                icon: Icons.volume_up_rounded,
                label: l10n.speakIt,
                size: 52,
                background: c.accent,
                foreground: c.onAccent,
                onPressed: text.isEmpty ? null : () => onSpeak(text),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  const _YesNoButton({
    required this.label,
    required this.icon,
    required this.positive,
    required this.speaking,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool positive;
  final bool speaking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final soft = positive ? c.successSoft : c.dangerSoft;
    final strong = positive ? c.success : c.danger;
    return Material(
      color: speaking ? strong : soft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: speaking ? c.surface : strong),
              const SizedBox(width: AppSpace.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: speaking ? c.surface : strong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon == null
            ? null
            : Icon(icon, size: 18, color: selected ? c.onPrimary : c.inkSoft),
        showCheckmark: false,
        selected: selected,
        onSelected: (_) => onSelected(),
        labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
          color: selected ? c.onPrimary : c.ink,
        ),
      ),
    );
  }
}

class _PhraseTile extends StatelessWidget {
  const _PhraseTile({
    required this.card,
    required this.speaking,
    required this.onPressed,
    required this.onLongPress,
  });

  final PhraseCard card;
  final bool speaking;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: card.text,
      hint: context.l10n.phraseTileHint,
      excludeSemantics: true,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: speaking ? c.accentSoft : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: speaking ? c.accent : c.outline,
            width: speaking ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onPressed,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      // Clear of the bookmark on the user's own words.
                      padding: EdgeInsetsDirectional.only(
                        end: card.isCustom ? AppSpace.lg : 0,
                      ),
                      child: Text(
                        card.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium!.copyWith(height: 1.35),
                      ),
                    ),
                  ),
                  if (card.isCustom)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 18,
                        color: c.onAccentSoft,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
