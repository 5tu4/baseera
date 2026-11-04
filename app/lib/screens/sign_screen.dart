import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/vocabulary.dart';
import '../l10n/l10n.dart';
import '../recognition/sign_recognizer.dart';
import '../services/app_scope.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'signs_sheet.dart';

enum _CameraStatus { off, starting, ready, denied, unavailable }

/// افهمني: the user signs at the camera; the phone shows and says the words.
///
/// Recognition is Ishara's (MediaPipe landmarks → KArSL-trained model); the
/// camera runs only while this tab is [active].
class SignScreen extends StatefulWidget {
  const SignScreen({super.key, required this.active});

  final bool active;

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> with WidgetsBindingObserver {
  late final AppServices _services = AppScope.of(context);
  late final SignRecognizer _recognizer = _services.createRecognizer();
  StreamSubscription<SignPrediction>? _predictionSub;

  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _controller;
  _CameraStatus _status = _CameraStatus.off;
  bool _pausedInBackground = false;

  /// Null while the recognition models load; false when unavailable.
  bool? _modelReady;

  /// Whether camera frames actually reach the recognizer (diagnostics).
  String _cameraNote = 'not started';

  final List<SignWord> _sentence = [];
  SignWord? _latest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _predictionSub = _recognizer.predictions.listen(_onPrediction);
    _recognizer.initialize().then((ready) {
      if (!mounted) return;
      setState(() => _modelReady = ready);
      _startRecognition();
    });
    if (widget.active) _startCamera();
  }

  @override
  void didUpdateWidget(SignScreen old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (widget.active) {
      _startCamera();
    } else {
      _stopCamera();
      setState(() => _status = _CameraStatus.off);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _predictionSub?.cancel();
    _recognizer.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release a running camera in the background and reopen it on return.
    // Only a camera that was running is resumed: the permission dialog also
    // makes the app inactive, and retrying after a denial would loop.
    if (state == AppLifecycleState.inactive && _status == _CameraStatus.ready) {
      _pausedInBackground = true;
      setState(() => _status = _CameraStatus.starting);
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _pausedInBackground &&
        widget.active) {
      _pausedInBackground = false;
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    await _stopCamera();
    if (!mounted) return;
    setState(() => _status = _CameraStatus.starting);

    try {
      if (_cameras.isEmpty) {
        _cameras = await _services.findCameras();
        final front = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _cameraIndex = max(front, 0);
      }
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _status = _CameraStatus.unavailable);
        return;
      }

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || _controller != controller || !widget.active) {
        await controller.dispose();
        if (_controller == controller) _controller = null;
        return;
      }
      setState(() => _status = _CameraStatus.ready);
      await _startRecognition();
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code} ${e.description}');
      await _stopCamera();
      final code = e.code.toLowerCase();
      final denied =
          code.contains('denied') ||
          code.contains('permission') ||
          code.contains('restricted');
      if (mounted) {
        setState(
          () => _status = denied
              ? _CameraStatus.denied
              : _CameraStatus.unavailable,
        );
      }
    } catch (e) {
      debugPrint('Camera unavailable: $e');
      await _stopCamera();
      if (mounted) setState(() => _status = _CameraStatus.unavailable);
    }
  }

  /// Streams frames to the recognizer once both camera and model are ready.
  Future<void> _startRecognition() async {
    final controller = _controller;
    if (_modelReady != true ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    if (!controller.supportsImageStreaming()) {
      _cameraNote = 'this camera cannot stream frames';
      return;
    }
    try {
      await controller.startImageStream(
        (image) => _recognizer.processFrame(image, controller.description),
      );
      _cameraNote = 'streaming ${controller.resolutionPreset.name}';
    } catch (e) {
      // Some phones refuse the frame format; say so in the diagnostics.
      debugPrint('Camera stream failed: $e');
      _cameraNote = 'stream failed: $e';
    }
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _startCamera();
  }

  void _onPrediction(SignPrediction prediction) {
    setState(() {
      _latest = prediction.sign;
      _sentence.add(prediction.sign);
    });
    if (_services.settings.autoSpeak) {
      _services.tts.speak(
        prediction.sign.wordIn(_services.settings.language),
        id: 'sign-latest',
      );
    }
  }

  void _speakLatest() {
    final latest = _latest;
    if (latest == null) return;
    _services.tts.speak(
      latest.wordIn(_services.settings.language),
      id: 'sign-latest',
    );
  }

  void _speakSentence() {
    if (_sentence.isEmpty) return;
    _services.tts.speak(
      _sentence.map((s) => s.wordIn(_services.settings.language)).join(' '),
      id: 'sign-sentence',
    );
  }

  void _undo() => setState(() {
    _sentence.removeLast();
    _latest = _sentence.isEmpty ? null : _sentence.last;
  });

  void _clear() => setState(() {
    _sentence.clear();
    _latest = null;
  });

  /// Long-press the camera (or tap the "not available" pill) for the real
  /// reason recognition is not running, plus device details and counters,
  /// so a tester far away can send back a cause, not a guess.
  Future<void> _showDiagnostics() async {
    final messenger = ScaffoldMessenger.of(context);
    final version = await PackageInfo.fromPlatform().then(
      (info) => '${info.version} (${info.buildNumber})',
      onError: (_) => '?',
    );
    final details = {
      'app': version,
      ...await _recognizer.diagnostics(),
      'camera stream': _cameraNote,
    };
    final text = details.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final c = dialogContext.colors;
        final textTheme = Theme.of(dialogContext).textTheme;
        return AlertDialog(
          title: Text(l10n.diagnosticsTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.diagnosticsHint,
                  style: textTheme.bodyMedium!.copyWith(color: c.inkSoft),
                ),
                const SizedBox(height: AppSpace.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  // Technical text stays left-to-right in both languages.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SelectableText(text, style: textTheme.bodySmall),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (kDebugMode)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _simulateSign();
                },
                child: const Text('simulate'),
              ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.copiedDetails)),
                );
              },
              child: Text(l10n.copyDetails),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  /// Debug builds only: fakes a recognized sign, so the flow can be tried
  /// without signing at the camera.
  void _simulateSign() {
    final recognizer = _recognizer;
    if (recognizer is! PendingSignRecognizer) return;
    recognizer.simulate(vocabulary[Random().nextInt(vocabulary.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            child: GestureDetector(
              onLongPress: _showDiagnostics,
              child: _CameraPanel(
                status: _status,
                controller: _controller,
                modelReady: _modelReady,
                signStatus: _recognizer.status,
                onRetry: _startCamera,
                onShowDiagnostics: _showDiagnostics,
                actions: [
                  RoundIconButton(
                    icon: Icons.menu_book_rounded,
                    label: l10n.signsIKnow,
                    background: Colors.black45,
                    foreground: Colors.white,
                    onPressed: () => showSignsSheet(context),
                  ),
                  if (_cameras.length > 1)
                    RoundIconButton(
                      icon: Icons.cameraswitch_rounded,
                      label: l10n.switchCamera,
                      background: Colors.black45,
                      foreground: Colors.white,
                      onPressed: _status == _CameraStatus.starting
                          ? null
                          : _switchCamera,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ListenableBuilder(
            listenable: _services.tts,
            builder: (context, _) => _OutputPanel(
              latest: _latest,
              sentence: _sentence,
              speakingId: _services.tts.speakingId,
              onSpeakLatest: _latest == null ? null : _speakLatest,
              onSpeakSentence: _sentence.isEmpty ? null : _speakSentence,
              onUndo: _sentence.isEmpty ? null : _undo,
              onClear: _sentence.isEmpty ? null : _clear,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPanel extends StatelessWidget {
  const _CameraPanel({
    required this.status,
    required this.controller,
    required this.modelReady,
    required this.signStatus,
    required this.onRetry,
    required this.onShowDiagnostics,
    required this.actions,
  });

  final _CameraStatus status;
  final CameraController? controller;
  final bool? modelReady;
  final ValueListenable<SignStatus> signStatus;
  final VoidCallback onRetry;
  final VoidCallback onShowDiagnostics;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final l10n = context.l10n;
    final c = context.colors;
    final showPreview =
        status == _CameraStatus.ready &&
        controller != null &&
        controller.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ColoredBox(
        color: c.cameraGround,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showPreview) _CoverPreview(controller: controller),
            Center(
              child: SingleChildScrollView(
                child: switch (status) {
                  // Off: the tab is hidden, so don't keep a spinner ticking.
                  _CameraStatus.ready ||
                  _CameraStatus.off => const SizedBox.shrink(),
                  _CameraStatus.starting => const _Starting(),
                  _CameraStatus.denied => StatusMessage(
                    onDark: true,
                    icon: Icons.no_photography_rounded,
                    title: l10n.cameraPermissionTitle,
                    message: l10n.cameraPermissionBody,
                    actionLabel: l10n.tryAgain,
                    onAction: onRetry,
                  ),
                  _CameraStatus.unavailable => StatusMessage(
                    onDark: true,
                    icon: Icons.videocam_off_rounded,
                    title: l10n.cameraUnavailableTitle,
                    message: l10n.cameraUnavailableBody,
                    actionLabel: l10n.tryAgain,
                    onAction: onRetry,
                  ),
                },
              ),
            ),
            PositionedDirectional(
              top: AppSpace.md,
              start: AppSpace.md,
              end: AppSpace.md,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: status == _CameraStatus.ready
                          ? _SignHint(
                              modelReady: modelReady,
                              signStatus: signStatus,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: AppSpace.sm),
                    action,
                  ],
                ],
              ),
            ),
            if (modelReady != true)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: modelReady == null
                      ? OverlayPill(
                          icon: Icons.hourglass_top_rounded,
                          text: l10n.modelLoading,
                        )
                      : GestureDetector(
                          onTap: onShowDiagnostics,
                          child: OverlayPill(
                            icon: Icons.info_outline_rounded,
                            text:
                                '${l10n.modelUnavailable} — ${l10n.tapForDetails}',
                            background: c.accent,
                            foreground: c.onAccent,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What to do next: "sign, then lower your hands", "watching", "again".
class _SignHint extends StatelessWidget {
  const _SignHint({required this.modelReady, required this.signStatus});

  final bool? modelReady;
  final ValueListenable<SignStatus> signStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder(
      valueListenable: signStatus,
      builder: (context, sign, _) {
        final (icon, text) = modelReady != true
            ? (Icons.front_hand_rounded, l10n.hintSignInFrame)
            : switch (sign) {
                SignStatus.waiting => (
                  Icons.front_hand_rounded,
                  l10n.hintSignThenLower,
                ),
                SignStatus.watching => (
                  Icons.visibility_rounded,
                  l10n.hintWatching,
                ),
                SignStatus.unsure => (Icons.replay_rounded, l10n.hintUnsure),
              };
        return Semantics(
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: OverlayPill(key: ValueKey(text), icon: icon, text: text),
          ),
        );
      },
    );
  }
}

/// Fills the panel with the camera image (like `BoxFit.cover`).
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    // The controller reports landscape ratios; the phone is held upright.
    final portraitRatio = 1 / controller.value.aspectRatio;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 300,
        height: 300 / portraitRatio,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _Starting extends StatelessWidget {
  const _Starting();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 40,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          context.l10n.cameraStarting,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

/// The latest sign (big) and the sentence built so far.
class _OutputPanel extends StatelessWidget {
  const _OutputPanel({
    required this.latest,
    required this.sentence,
    required this.speakingId,
    required this.onSpeakLatest,
    required this.onSpeakSentence,
    required this.onUndo,
    required this.onClear,
  });

  final SignWord? latest;
  final List<SignWord> sentence;
  final String? speakingId;
  final VoidCallback? onSpeakLatest;
  final VoidCallback? onSpeakSentence;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = context.colors;
    final l10n = context.l10n;
    final language = AppLanguage.of(context);
    final latest = this.latest;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    child: latest == null
                        ? Column(
                            key: const ValueKey('empty'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.noSignYet, style: textTheme.titleLarge),
                              Text(
                                l10n.wordsAppearHere,
                                style: textTheme.bodyMedium!.copyWith(
                                  color: c.inkSoft,
                                ),
                              ),
                            ],
                          )
                        : Align(
                            key: ValueKey('${latest.id}-${sentence.length}'),
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              latest.wordIn(language),
                              style: textTheme.displaySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              RoundIconButton(
                icon: Icons.volume_up_rounded,
                label: l10n.speakWord,
                size: 56,
                background: speakingId == 'sign-latest'
                    ? c.accent
                    : c.primarySoft,
                foreground: speakingId == 'sign-latest'
                    ? c.onAccent
                    : c.onPrimarySoft,
                onPressed: onSpeakLatest,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Divider(),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, maxHeight: 84),
            child: SingleChildScrollView(
              reverse: true,
              child: sentence.isEmpty
                  ? Text(
                      l10n.sentenceHint,
                      style: textTheme.bodyMedium!.copyWith(color: c.inkFaint),
                    )
                  : Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final word in sentence)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: c.primarySoft,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              word.wordIn(language),
                              style: textTheme.titleMedium!.copyWith(
                                color: c.onPrimarySoft,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: accentButtonStyle(context),
                  onPressed: onSpeakSentence,
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: Text(l10n.speakSentence),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              RoundIconButton(
                icon: Icons.backspace_outlined,
                label: l10n.deleteLastWord,
                onPressed: onUndo,
              ),
              const SizedBox(width: AppSpace.sm),
              RoundIconButton(
                icon: Icons.delete_outline_rounded,
                label: l10n.clearSentence,
                onPressed: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
