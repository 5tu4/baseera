import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Rounded panel with a hairline border — the app's card.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // A Material (not a DecoratedBox), so list tiles and buttons inside
    // show their ink ripple.
    return Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Small grey heading above a group of settings or cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.xs,
        top: AppSpace.xl,
        bottom: AppSpace.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.copyWith(color: context.colors.inkSoft),
        ),
      ),
    );
  }
}

/// Empty, waiting and permission states: icon, title, message, one action.
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.onDark = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Over the camera image: light text on a dark ground.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final ink = onDark ? Colors.white : c.ink;
    final soft = onDark ? Colors.white70 : c.inkSoft;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onDark ? Colors.white12 : c.primarySoft,
            ),
            child: Icon(
              icon,
              size: 36,
              color: onDark ? Colors.white : c.onPrimarySoft,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge!.copyWith(color: ink),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium!.copyWith(color: soft),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpace.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A rounded label laid over the camera image.
class OverlayPill extends StatelessWidget {
  const OverlayPill({
    super.key,
    required this.text,
    this.icon,
    this.background = const Color(0xB30B1020),
    this.foreground = Colors.white,
  });

  final String text;
  final IconData? icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpace.xs + 2),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round icon button with a spoken label (TalkBack) and a long-press tooltip.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = AppSize.touch,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: enabled ? (background ?? c.surfaceMuted) : c.surfaceMuted,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                icon,
                size: size * 0.46,
                color: enabled ? (foreground ?? c.ink) : c.inkFaint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The amber style for a screen's main action.
ButtonStyle accentButtonStyle(BuildContext context) {
  final c = context.colors;
  return FilledButton.styleFrom(
    backgroundColor: c.accent,
    foregroundColor: c.onAccent,
  );
}

/// The Baseera logo in a rounded square.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    // The logo (tool/make_icons.py); the app's name is always written next
    // to it, so screen readers skip the picture.
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/brand/logo.png',
        width: size,
        height: size,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
