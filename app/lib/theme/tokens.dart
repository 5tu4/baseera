import 'package:flutter/material.dart';

/// Design tokens: the single source for every color, space, radius and
/// duration in the app. Widgets read colors through `context.colors` so light
/// and dark mode both work; they never hardcode a value.
///
/// Palette: deep blue (trust, calm) + amber (actions, highlights). Text on
/// amber is always dark ink — amber is too light to carry white text.
@immutable
class BaseeraColors extends ThemeExtension<BaseeraColors> {
  const BaseeraColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.outline,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
    required this.cameraGround,
  });

  final Color background;
  final Color surface;

  /// Quiet fills: inactive chips, old transcript lines, input fields.
  final Color surfaceMuted;
  final Color outline;

  /// Body text (≥ 7:1 on surface), secondary text (≥ 4.5:1), placeholders.
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;

  final Color primary;
  final Color onPrimary;

  /// Tinted backgrounds, and the text/icons placed on them (≥ 4.5:1).
  final Color primarySoft;
  final Color onPrimarySoft;

  /// The main action on a screen (speak, record, add).
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;

  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;

  /// Behind the camera image before it starts.
  final Color cameraGround;

  static const light = BaseeraColors(
    background: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF1F8),
    outline: Color(0xFFDDE2EE),
    ink: Color(0xFF0E1630),
    inkSoft: Color(0xFF4A5372),
    inkFaint: Color(0xFF7C849E),
    primary: Color(0xFF1D3B8B),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE3E9F8),
    onPrimarySoft: Color(0xFF1D3B8B),
    accent: Color(0xFFF5A524),
    onAccent: Color(0xFF0E1630),
    accentSoft: Color(0xFFFEF1D6),
    onAccentSoft: Color(0xFF7A4A00),
    danger: Color(0xFFD93636),
    dangerSoft: Color(0xFFFCE4E4),
    success: Color(0xFF1E8E5A),
    successSoft: Color(0xFFDDF3E8),
    cameraGround: Color(0xFF0B1020),
  );

  static const dark = BaseeraColors(
    background: Color(0xFF0B1020),
    surface: Color(0xFF151B30),
    surfaceMuted: Color(0xFF1D2440),
    outline: Color(0xFF2A3354),
    ink: Color(0xFFEEF1FA),
    inkSoft: Color(0xFFAEB6D0),
    inkFaint: Color(0xFF7C86A6),
    primary: Color(0xFF8FA8FF),
    onPrimary: Color(0xFF0B1020),
    primarySoft: Color(0xFF1F2A52),
    onPrimarySoft: Color(0xFFC9D5FF),
    accent: Color(0xFFFFC15A),
    onAccent: Color(0xFF0B1020),
    accentSoft: Color(0xFF3A2C10),
    onAccentSoft: Color(0xFFFFD98F),
    danger: Color(0xFFFF6B6B),
    dangerSoft: Color(0xFF3A1717),
    success: Color(0xFF4CD38F),
    successSoft: Color(0xFF123323),
    cameraGround: Color(0xFF05080F),
  );

  @override
  BaseeraColors copyWith() => this;

  @override
  BaseeraColors lerp(BaseeraColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BaseeraColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      outline: mix(outline, other.outline),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      inkFaint: mix(inkFaint, other.inkFaint),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primarySoft: mix(primarySoft, other.primarySoft),
      onPrimarySoft: mix(onPrimarySoft, other.onPrimarySoft),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccentSoft: mix(onAccentSoft, other.onAccentSoft),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
      cameraGround: mix(cameraGround, other.cameraGround),
    );
  }
}

extension BaseeraColorsContext on BuildContext {
  BaseeraColors get colors => Theme.of(this).extension<BaseeraColors>()!;
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Side gutter of every screen.
  static const gutter = 16.0;

  /// Content never grows wider than this (tablets).
  static const maxContentWidth = 640.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

abstract final class AppSize {
  /// Smallest touch target (Android accessibility guideline is 48dp).
  static const touch = 48.0;

  /// The big round mic / speak buttons.
  static const hero = 96.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 450);
  static const curve = Curves.easeOutCubic;
}
