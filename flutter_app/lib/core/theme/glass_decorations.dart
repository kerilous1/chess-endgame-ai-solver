/// core/theme/glass_decorations.dart
/// ==================================
/// Reusable Cyber-Slate frosted-glass box decorations for cards, pills,
/// the 6×6 board frame, and legal/error/checkmate status banners.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Visual tone for inline status and validation banners.
enum StatusBannerTone {
  /// Position is legal / ready.
  ok,

  /// Position has a placement legality error or search failed.
  error,

  /// Checkmate achieved!
  mate,

  /// Neutral informational or node-cap warning state.
  info,
}

/// Factory helpers producing consistent glassmorphism [BoxDecoration] styles.
abstract final class GlassDecorations {
  /// Standard frosted glass container decoration (`#111827` @ 82% + hairline border).
  static BoxDecoration card({
    double borderRadius = 18,
    Color? borderColor,
    Color? backgroundColor,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: gradient == null ? (backgroundColor ?? AppColors.glassSurface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: 1.0,
      ),
      boxShadow: shadows ??
          const <BoxShadow>[
            BoxShadow(
              color: Color(0xBF020617),
              blurRadius: 28,
              spreadRadius: -10,
              offset: Offset(0, 12),
            ),
          ],
    );
  }

  /// Compact pill / chip surface with optional neon active glow.
  static BoxDecoration pill({
    bool active = false,
    Color accent = AppColors.cyan,
    double borderRadius = 999,
    Color? inactiveColor,
  }) {
    return BoxDecoration(
      color: active
          ? accent.withValues(alpha: 0.16)
          : (inactiveColor ?? AppColors.glassSurfaceStrong),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: active ? accent.withValues(alpha: 0.72) : AppColors.glassBorder,
        width: active ? 1.2 : 1.0,
      ),
      boxShadow: active
          ? <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.20),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ]
          : null,
    );
  }

  /// Outer bezel surrounding the 6×6 chess board and coordinate labels.
  static BoxDecoration boardFrame({bool isCheckmate = false}) {
    final accent = isCheckmate ? AppColors.coral : AppColors.cyan;
    return BoxDecoration(
      color: AppColors.boardFrameBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: accent.withValues(alpha: isCheckmate ? 0.65 : 0.24),
        width: isCheckmate ? 1.5 : 1.1,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: isCheckmate
              ? AppColors.coral.withValues(alpha: 0.22)
              : const Color(0xCC020617),
          blurRadius: 32,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.06),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Colored notification banner decoration for validation & checkmate feedback.
  static BoxDecoration statusBanner(StatusBannerTone tone) {
    return switch (tone) {
      StatusBannerTone.ok => BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.26)),
        ),
      StatusBannerTone.error => BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.45)),
        ),
      StatusBannerTone.mate => BoxDecoration(
          gradient: AppColors.checkmateBannerGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.56)),
        ),
      StatusBannerTone.info => BoxDecoration(
          color: AppColors.amberSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.42)),
        ),
    };
  }
}
