/// core/theme/app_colors.dart
/// ==========================
/// Design tokens for the **Muted Dark Neon (Low-Key Cyber-Slate)** visual
/// system, evolved directly from the `krk_6_6.html` prototype.
///
/// Every color has an intentional functional meaning:
/// - **Cyan / Sky**   (`#2DD4BF` / `#38BDF8`): White pieces, optimal solutions, active state.
/// - **Violet**       (`#A78BFA`): Black King, memory/frontier metrics, secondary emphasis.
/// - **Amber**        (`#F59E0B`): Primary Run/Solve CTA, legal Black King escape dots.
/// - **Coral**        (`#FB7185`): Check / Checkmate warning rings and validation errors.
library;

import 'package:flutter/material.dart';

import '../../ai_engine/ai_engine.dart';

/// Color tokens for the Cyber-Slate dark neon palette.
abstract final class AppColors {
  // ---- Canvas & Surfaces ---------------------------------------------------
  /// Deep Cyber-Slate base canvas.
  static const Color bgBase = Color(0xFF0B0F19);

  /// Elevated panel base before transparency.
  static const Color bgElevated = Color(0xFF111827);

  /// Frosted glass card fill (~82% opacity).
  static const Color glassSurface = Color(0xD1111827);

  /// Strong frosted glass fill (~92% opacity) for nested chips & overlays.
  static const Color glassSurfaceStrong = Color(0xEB0F172A);

  /// Deep inner well fill for board frames and dark input wells.
  static const Color boardFrameBg = Color(0xD1090D18);

  /// Hairline slate border (`rgba(148, 163, 184, 0.14)`).
  static const Color glassBorder = Color(0x2494A3B8);

  /// Hovered / focused glass border (`rgba(148, 163, 184, 0.28)`).
  static const Color glassBorderHover = Color(0x4794A3B8);

  // ---- Functional Neon Accents (Muted) -------------------------------------
  /// Primary White/Optimal neon cyan.
  static const Color cyan = Color(0xFF2DD4BF);

  /// Complementary cool sky blue.
  static const Color sky = Color(0xFF38BDF8);

  /// Soft cyan tint (14% alpha).
  static const Color cyanSoft = Color(0x242DD4BF);

  /// Soft cyan shadow/glow (22% alpha).
  static const Color cyanGlow = Color(0x382DD4BF);

  /// Secondary Black-King / Memory neon violet.
  static const Color violet = Color(0xFFA78BFA);

  /// Soft violet tint (14% alpha).
  static const Color violetSoft = Color(0x24A78BFA);

  /// Soft violet shadow/glow (24% alpha).
  static const Color violetGlow = Color(0x3DA78BFA);

  /// Primary action CTA & escape-square amber.
  static const Color amber = Color(0xFFF59E0B);

  /// Soft amber tint (15% alpha).
  static const Color amberSoft = Color(0x26F59E0B);

  /// Check / checkmate / validation error coral.
  static const Color coral = Color(0xFFFB7185);

  /// Soft coral tint (16% alpha).
  static const Color coralSoft = Color(0x29FB7185);

  /// Indigo accent used for White King tactical control shading.
  static const Color indigo = Color(0xFF6366F1);

  // ---- Tactical Board Squares & Overlays -----------------------------------
  /// Light slate square (`#1E293B`).
  static const Color squareLight = Color(0xFF1E293B);

  /// Dark slate square (`#131C2E`).
  static const Color squareDark = Color(0xFF131C2E);

  /// Overlay for squares attacked by White sliders (Queen / Rook / Bishop).
  static const Color sliderControl = Color(0x262DD4BF);

  /// Overlay for squares guarded by the White King.
  static const Color kingControl = Color(0x386366F1);

  // ---- Typography Hierarchy ------------------------------------------------
  /// Primary high-contrast body & heading text.
  static const Color textMain = Color(0xFFF1F5F9);

  /// Secondary labels and muted metadata.
  static const Color textMuted = Color(0xFF94A3B8);

  /// Subtle coordinates and tertiary captions.
  static const Color textDim = Color(0xFF64748B);

  // ---- Gradients -----------------------------------------------------------
  /// Header brand title gradient (white -> soft teal -> soft lavender).
  static const LinearGradient brandTitleGradient = LinearGradient(
    colors: <Color>[Color(0xFFF8FAFC), Color(0xFF99F6E4), Color(0xFFC4B5FD)],
  );

  /// Primary CTA warm amber-to-coral gradient fill.
  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x38F59E0B), Color(0x38FB7185)],
  );

  /// Checkmate celebration banner gradient.
  static const LinearGradient checkmateBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x2EFB7185), Color(0x29F59E0B)],
  );

  /// Returns the functional accent color associated with an [AlgorithmCategory].
  static Color categoryAccent(AlgorithmCategory category) => switch (category) {
        AlgorithmCategory.uninformed => sky,
        AlgorithmCategory.informed => cyan,
        AlgorithmCategory.memoryBounded => violet,
        AlgorithmCategory.localSearch => amber,
      };
}
