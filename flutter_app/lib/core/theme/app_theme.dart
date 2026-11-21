/// core/theme/app_theme.dart
/// ==========================
/// Material 3 dark theme and 100% offline-safe typography configuration for
/// the Cyber-Slate Muted Dark Neon UI.
///
/// Offline Safety Note:
/// - Disables runtime Google Font HTTP fetching (`allowRuntimeFetching = false`)
///   so the APK never throws network exceptions when running offline or in tests.
/// - Uses `Cairo` for Arabic (RTL), `Plus Jakarta Sans` for English (LTR), and
///   `JetBrains Mono` for coordinates, telemetry, and complexity formulas with
///   reliable OS system fallbacks.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import 'app_colors.dart';

/// Offline-safe font helpers for Arabic, English, and monospace telemetry.
abstract final class AppTypography {
  static const List<String> _arabicFallbacks = <String>[
    'Cairo',
    'Tajawal',
    'Noto Sans Arabic',
    'Segoe UI',
    'Tahoma',
    'Roboto',
    'sans-serif',
  ];

  static const List<String> _englishFallbacks = <String>[
    'Plus Jakarta Sans',
    'Inter',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static const List<String> _monoFallbacks = <String>[
    'JetBrains Mono',
    'Cascadia Mono',
    'Consolas',
    'Roboto Mono',
    'monospace',
  ];

  /// Primary font family name for [language].
  static String uiFontFamily(AppLanguage language) =>
      language == AppLanguage.ar ? 'Cairo' : 'Plus Jakarta Sans';

  /// Ordered fallback chain for [language].
  static List<String> uiFontFallback(AppLanguage language) =>
      language == AppLanguage.ar ? _arabicFallbacks : _englishFallbacks;

  /// Builds a UI [TextStyle] adapted to the active language's script & legibility.
  static TextStyle ui(
    AppLanguage language, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: uiFontFamily(language),
      fontFamilyFallback: uiFontFallback(language),
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textMain,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Monospace [TextStyle] for coordinates (`a6`..`f1`), metrics, and `g/h/f`.
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textMain,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'JetBrains Mono',
      fontFamilyFallback: _monoFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }
}

/// Top-level Flutter [ThemeData] builder for the Muted Dark Neon design system.
abstract final class AppTheme {
  static bool _fontsConfigured = false;

  /// Ensures `google_fonts` never initiates network requests on offline devices.
  static void configureOfflineSafeFonts() {
    if (_fontsConfigured) return;
    GoogleFonts.config.allowRuntimeFetching = false;
    _fontsConfigured = true;
  }

  /// Builds the dark Cyber-Slate [ThemeData] localized for [language].
  static ThemeData buildDarkTheme(AppLanguage language) {
    configureOfflineSafeFonts();

    final family = AppTypography.uiFontFamily(language);
    final fallbacks = AppTypography.uiFontFallback(language);

    const colorScheme = ColorScheme.dark(
      primary: AppColors.cyan,
      onPrimary: AppColors.bgBase,
      secondary: AppColors.violet,
      onSecondary: AppColors.bgBase,
      tertiary: AppColors.amber,
      onTertiary: AppColors.bgBase,
      error: AppColors.coral,
      onError: AppColors.textMain,
      surface: AppColors.bgElevated,
      onSurface: AppColors.textMain,
      outline: AppColors.glassBorder,
    );

    final baseTextTheme = ThemeData.dark(useMaterial3: true).textTheme.apply(
          fontFamily: family,
          fontFamilyFallback: fallbacks,
          bodyColor: AppColors.textMain,
          displayColor: AppColors.textMain,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: family,
      fontFamilyFallback: fallbacks,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      canvasColor: AppColors.bgBase,
      cardColor: AppColors.glassSurface,
      dividerColor: AppColors.glassBorder,
      textTheme: baseTextTheme.copyWith(
        headlineSmall: AppTypography.ui(
          language,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleMedium: AppTypography.ui(
          language,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: AppTypography.ui(
          language,
          fontSize: 14,
          height: 1.55,
        ),
        bodySmall: AppTypography.ui(
          language,
          fontSize: 12.5,
          color: AppColors.textMuted,
          height: 1.45,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.cyan,
        inactiveTrackColor: AppColors.glassBorder,
        thumbColor: AppColors.cyan,
        overlayColor: AppColors.cyanSoft,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.glassSurfaceStrong,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorderHover),
        ),
        textStyle: AppTypography.ui(
          language,
          fontSize: 12,
          color: AppColors.textMain,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.textMuted.withValues(alpha: 0.28),
        ),
        radius: const Radius.circular(999),
        thickness: const WidgetStatePropertyAll(6),
      ),
    );
  }
}
