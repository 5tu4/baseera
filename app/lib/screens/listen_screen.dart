import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/l10n.dart';
import '../services/app_scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

enum _MicStatus { idle, starting, listening, denied, unavailable }

/// أقرأ كلامك: speech → big text, so a deaf user can read what people say.
///
/// Android's recognizer stops after every pause; while the user has the mic
/// on, this screen restarts it, so a whole conversation is transcribed
/// without tapping again. The microphone is released when the tab is left.
class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key, required this.active});

  final bool active;

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  final _speech = SpeechToText();
  final _scroll = ScrollController();
  bool _initialized = false;
  String? _localeId;
  AppLanguage? _localeLanguage;
  _MicStatus _status = _MicStatus.idle;

  /// The user wants the mic on; drives the automatic restarts.
  bool _wanted = false;

  /// Errors in a row; after a few the screen stops retrying and says so.
  int _failures = 0;
  Timer? _restart;

  final List<String> _lines = [];
  String _partial = '';
  bool _showProblem = false;

  @override
  void didUpdateWidget(ListenScreen old) {
    super.didUpdateWidget(old);
    if (old.active && !widget.active && _wanted) _stop();
  }

  @override
  void dispose() {
    _restart?.cancel();
    _speech.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_wanted) {
      await _stop();
    } else {
      _wanted = true;
      _failures = 0;
      setState(() => _showProblem = false);
      await _listen();
    }
  }

  Future<void> _stop() async {
    _wanted = false;
    _restart?.cancel();
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _commitPartial();
      _status = _MicStatus.idle;
    });
  }

  Future<void> _listen() async {
    if (!mounted || !_wanted) return;
    final language = AppScope.of(context).settings.language;
    if (_status != _MicStatus.listening) {
      setState(() => _status = _MicStatus.starting);
    }

    if (!_initialized) {
      try {
        _initialized = await _speech.initialize(
          onError: _onError,
          onStatus: _onStatus,
        );
      } catch (e) {
        debugPrint('Speech init failed: $e');
      }
      if (!_initialized) {
        var denied = false;
        try {
          denied = !await _speech.hasPermission;
        } catch (_) {}
        _wanted = false;
        if (mounted) {
          setState(
            () => _status = denied ? _MicStatus.denied : _MicStatus.unavailable,
          );
        }
        return;
      }
    }
    if (_localeLanguage != language) {
      _localeId = await _speechLocale(language);
      _localeLanguage = language;
    }

    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      if (mounted) setState(() => _status = _MicStatus.listening);
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      _scheduleRestart(failed: true);
    }
  }

  /// Saudi Arabic (or US/UK English), else any variant the device offers.
  Future<String> _speechLocale(AppLanguage language) async {
    final preferred = switch (language) {
      AppLanguage.ar => ['ar_SA', 'ar-SA'],
      AppLanguage.en => ['en_US', 'en-US', 'en_GB', 'en-GB'],
    };
    try {
      final ids = [for (final l in await _speech.locales()) l.localeId];
      for (final id in preferred) {
        if (ids.contains(id)) return id;
      }
      for (final id in ids) {
        if (id.toLowerCase().startsWith(language.locale.languageCode)) {
          return id;
        }
      }
    } catch (_) {}
    return preferred.last;
  }

  void _onResult(SpeechRecognitionResult result) {
    // The plugin can deliver a late final result after the screen is gone.
    if (!mounted) return;
    _failures = 0;
    setState(() {
      _partial = result.recognizedWords;
      if (result.finalResult) _commitPartial();
    });
    _scrollToEnd();
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      setState(_commitPartial);
      _scheduleRestart();
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    debugPrint('Speech error: ${error.errorMsg}');
    setState(_commitPartial);
    if (error.errorMsg.contains('permission')) {
      _wanted = false;
      setState(() => _status = _MicStatus.denied);
      return;
    }
    // Silence ("no match", "timeout") is normal in a conversation.
    final silence =
        error.errorMsg.contains('no_match') ||
        error.errorMsg.contains('timeout');
    _scheduleRestart(failed: !silence);
  }

  void _scheduleRestart({bool failed = false}) {
    if (!_wanted) {
      if (mounted) setState(() => _status = _MicStatus.idle);
      return;
    }
    if (failed && ++_failures >= 4) {
      _wanted = false;
      setState(() {
        _status = _MicStatus.idle;
        _showProblem = true;
      });
      return;
    }
    _restart?.cancel();
    // The recognizer needs a moment to release the mic before it restarts.
    _restart = Timer(const Duration(milliseconds: 400), _listen);
  }

  void _commitPartial() {
    final text = _partial.trim();
    _partial = '';
    if (text.isNotEmpty && (_lines.isEmpty || _lines.last != text)) {
      _lines.add(text);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppMotion.normal,
        curve: AppMotion.curve,
      );
    });
  }

  void _clear() => setState(() {
    _lines.clear();
    _partial = '';
    _showProblem = false;
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final c = context.colors;
    final settings = AppScope.of(context).settings;
    final listening = _wanted && _status != _MicStatus.denied;
    final hasText = _lines.isNotEmpty || _partial.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xs,
        AppSpace.gutter,
        AppSpace.md,
      ),
      child: Column(
        children: [
          Expanded(
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpace.lg,
                        AppSpace.sm,
                        AppSpace.sm,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.whatPeopleSay,
                              style: textTheme.titleSmall!.copyWith(
                                color: c.inkSoft,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.smallerText,
                            icon: const Icon(Icons.text_decrease_rounded),
                            onPressed: settings.transcriptScale > 0.8
                                ? () => settings.transcriptScale -= 0.2
                                : null,
                          ),
                          IconButton(
                            tooltip: l10n.biggerText,
                            icon: const Icon(Icons.text_increase_rounded),
                            onPressed: settings.transcriptScale < 1.8
                                ? () => settings.transcriptScale += 0.2
                                : null,
                          ),
                          IconButton(
                            tooltip: l10n.clearSpeech,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: hasText ? _clear : null,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: _Transcript(
                        status: _status,
                        listening: listening,
                        lines: _lines,
                        partial: _partial,
                        scale: settings.transcriptScale,
                        scroll: _scroll,
                        onRetry: _toggle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _MicButton(
            listening: listening,
            busy: _status == _MicStatus.starting && !listening,
            onPressed: _status == _MicStatus.denied ? null : _toggle,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            listening ? l10n.listeningTapToStop : l10n.tapToListen,
            style: textTheme.titleMedium!.copyWith(
              color: listening ? c.onPrimarySoft : c.inkSoft,
            ),
          ),
          SizedBox(
            height: 24,
            child: _showProblem
                ? Text(
                    l10n.listenProblem,
                    style: textTheme.bodySmall!.copyWith(color: c.danger),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({
    required this.status,
    required this.listening,
    required this.lines,
    required this.partial,
    required this.scale,
    required this.scroll,
    required this.onRetry,
  });

  final _MicStatus status;
  final bool listening;
  final List<String> lines;
  final String partial;
  final double scale;
  final ScrollController scroll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasText = lines.isNotEmpty || partial.isNotEmpty;
    return switch (status) {
      _MicStatus.denied => Center(
        child: SingleChildScrollView(
          child: StatusMessage(
            icon: Icons.mic_off_rounded,
            title: l10n.micPermissionTitle,
            message: l10n.micPermissionBody,
          ),
        ),
      ),
      _MicStatus.unavailable => Center(
        child: SingleChildScrollView(
          child: StatusMessage(
            icon: Icons.hearing_disabled_rounded,
            title: l10n.listenUnavailableTitle,
            message: l10n.listenUnavailableBody,
            actionLabel: l10n.tryAgain,
            onAction: onRetry,
          ),
        ),
      ),
      _ when !hasText => Center(
        child: SingleChildScrollView(
          child: StatusMessage(
            icon: listening
                ? Icons.graphic_eq_rounded
                : Icons.subtitles_rounded,
            title: listening ? l10n.listeningNow : l10n.readyToListen,
            message: l10n.listenHint,
          ),
        ),
      ),
      _ => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          for (var i = 0; i < lines.length; i++)
            _Line(
              text: lines[i],
              isLatest: i == lines.length - 1 && partial.isEmpty,
              scale: scale,
            ),
          if (partial.isNotEmpty)
            _Line(text: partial, isLatest: true, live: true, scale: scale),
        ],
      ),
    };
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.text,
    required this.isLatest,
    required this.scale,
    this.live = false,
  });

  final String text;
  final bool isLatest;
  final double scale;

  /// Still being heard — shown lighter until the sentence is final.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;
    final base = isLatest ? textTheme.headlineMedium! : textTheme.titleLarge!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: isLatest ? c.primarySoft : c.surfaceMuted,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(AppRadius.sm),
              topEnd: Radius.circular(AppRadius.lg),
              bottomStart: Radius.circular(AppRadius.lg),
              bottomEnd: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Text(
            text,
            style: base.copyWith(
              fontSize: base.fontSize! * scale,
              color: live
                  ? c.onPrimarySoft.withValues(alpha: 0.7)
                  : isLatest
                  ? c.onPrimarySoft
                  : c.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// Big round microphone; rings pulse out while listening.
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.listening,
    required this.busy,
    required this.onPressed,
  });

  final bool listening;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const size = AppSize.hero;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final background = widget.listening ? c.primary : c.accent;
    final foreground = widget.listening ? c.onPrimary : c.onAccent;

    return SizedBox.square(
      dimension: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.listening && !reduceMotion)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  for (final offset in [0.0, 0.5])
                    _ring((_pulse.value + offset) % 1, size, c.primary),
                ],
              ),
            ),
          RoundIconButton(
            icon: widget.busy
                ? Icons.more_horiz_rounded
                : widget.listening
                ? Icons.stop_rounded
                : Icons.mic_rounded,
            label: widget.listening
                ? context.l10n.stopListening
                : context.l10n.startListening,
            size: size,
            background: background,
            foreground: foreground,
            onPressed: widget.busy ? null : widget.onPressed,
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, double size, Color color) {
    return Container(
      width: size * (1 + 0.5 * t),
      height: size * (1 + 0.5 * t),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.25 * (1 - t)),
      ),
    );
  }
}
