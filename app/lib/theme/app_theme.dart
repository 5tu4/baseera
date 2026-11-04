import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material theme built from the tokens, one per brightness.
ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark
      ? BaseeraColors.dark
      : BaseeraColors.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.onPrimarySoft,
    secondary: c.accent,
    onSecondary: c.onAccent,
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.onAccentSoft,
    error: c.danger,
    onError: c.onPrimary,
    errorContainer: c.dangerSoft,
    onErrorContainer: c.danger,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkSoft,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceMuted,
    surfaceContainerHighest: c.surfaceMuted,
    outline: c.outline,
    outlineVariant: c.outline,
  );

  // Arabic script needs more line height than Latin to stay readable.
  TextStyle style(double size, FontWeight weight, {double height = 1.45}) =>
      TextStyle(
        fontFamily: 'Plex',
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: c.ink,
      );

  final textTheme = TextTheme(
    displaySmall: style(34, FontWeight.w700, height: 1.3),
    headlineLarge: style(30, FontWeight.w700, height: 1.35),
    headlineMedium: style(26, FontWeight.w700, height: 1.35),
    headlineSmall: style(22, FontWeight.w600, height: 1.4),
    titleLarge: style(20, FontWeight.w600),
    titleMedium: style(17, FontWeight.w600),
    titleSmall: style(15, FontWeight.w600),
    bodyLarge: style(17, FontWeight.w400, height: 1.6),
    bodyMedium: style(15, FontWeight.w400, height: 1.55),
    bodySmall: style(13, FontWeight.w400, height: 1.5),
    labelLarge: style(16, FontWeight.w600, height: 1.3),
    labelMedium: style(14, FontWeight.w600, height: 1.3),
    labelSmall: style(12, FontWeight.w500, height: 1.3),
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  );
  const buttonSize = Size(AppSize.touch, 52);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Plex',
    textTheme: textTheme,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primarySoft,
      height: 76,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected)
              ? c.onPrimarySoft
              : c.inkSoft,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected)
              ? c.onPrimarySoft
              : c.inkSoft,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        disabledBackgroundColor: c.surfaceMuted,
        disabledForegroundColor: c.inkFaint,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.onPrimarySoft,
        minimumSize: buttonSize,
        shape: buttonShape,
        side: BorderSide(color: c.outline, width: 1.5),
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.onPrimarySoft,
        minimumSize: const Size(AppSize.touch, AppSize.touch),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(AppSize.touch, AppSize.touch),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: 2,
      extendedTextStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceMuted,
      hintStyle: textTheme.bodyLarge!.copyWith(color: c.inkFaint),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.primary,
      side: BorderSide(color: c.outline),
      labelStyle: textTheme.labelMedium!.copyWith(color: c.ink),
      secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: c.onPrimary),
      checkmarkColor: c.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.sm,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: c.primary,
        selectedForegroundColor: c.onPrimary,
        foregroundColor: c.ink,
        side: BorderSide(color: c.outline),
        textStyle: textTheme.labelMedium,
        minimumSize: const Size(AppSize.touch, AppSize.touch),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.onPrimary : c.inkSoft,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.primary : c.surfaceMuted,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.outline),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.primary,
      inactiveTrackColor: c.primarySoft,
      thumbColor: c.primary,
      valueIndicatorColor: c.primary,
      valueIndicatorTextStyle: textTheme.labelMedium!.copyWith(
        color: c.onPrimary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      showDragHandle: true,
      dragHandleColor: c.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: c.background),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.inkSoft,
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.bodySmall!.copyWith(color: c.inkSoft),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      minVerticalPadding: AppSpace.md,
    ),
  );
}
