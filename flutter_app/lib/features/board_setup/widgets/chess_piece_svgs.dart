/// features/board_setup/widgets/chess_piece_svgs.dart
/// ====================================================
/// High-contrast Staunton vector SVG assets for all 5 endgame piece types
/// (`WK`, `WQ`, `WR`, `WB`, `BK`) and the glowing [ChessPieceToken] widget.
///
/// Visual design evolved directly from `krk_6_6.html`:
/// - White pieces: crisp slate-white `#F8FAFC` with `#0F172A` outline, cyan
///   `#2DD4BF` accents, and a subtle cyan ambient glow.
/// - Black King: obsidian `#090D16` fill with `#C4B5FD` / `#A78BFA` violet
///   strokes and a soft violet aura.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/theme/theme.dart';

/// Raw inline `45×45` SVG strings indexed by [PieceType].
abstract final class ChessPieceSvgs {
  /// White King vector evolved from `krk_6_6.html`.
  static const String whiteKing = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#f8fafc" stroke="#0f172a" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M22.5 11.63V6M20 8h5" stroke="#2dd4bf" stroke-width="2.2"/>
    <path d="M22.5 25s4.5-7.5 3-10.5c0 0-1-2.5-3-2.5s-3 2.5-3 2.5c-1.5 3 3 10.5 3 10.5"/>
    <path d="M11.5 37c5.5 3.5 15.5 3.5 21 0v-7s9-4.5 6-10.5c-4-6.5-13.5-3.5-16 4V27v-3.5c-3.5-7.5-13-10.5-16-4-3 6 5 10 5 10V37z"/>
    <path d="M11.5 30c5.5-3 15.5-3 21 0M11.5 33.5c5.5-3 15.5-3 21 0M11.5 37c5.5-3 15.5-3 21 0" fill="none" stroke="#0f172a" stroke-width="1.3"/>
  </g>
</svg>''';

  /// White Queen vector matching the Cyber-Slate Staunton aesthetic.
  static const String whiteQueen = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#f8fafc" stroke="#0f172a" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="6" cy="12" r="2.5" fill="#2dd4bf"/>
    <circle cx="14" cy="9" r="2.5" fill="#2dd4bf"/>
    <circle cx="22.5" cy="8" r="2.5" fill="#2dd4bf"/>
    <circle cx="31" cy="9" r="2.5" fill="#2dd4bf"/>
    <circle cx="39" cy="12" r="2.5" fill="#2dd4bf"/>
    <path d="M9 26c8.5-1.5 21-1.5 27 0l2.5-12.5L31 25l-.3-14.1-5.2 13.6-3-14.5-3 14.5-5.2-13.6L14 25 6.5 13.5 9 26z"/>
    <path d="M9 26c0 2 1.5 2 2.5 4 1 1.5 1 1 .5 3.5-1.5 1-1.5 2.5-1.5 2.5-1.5 1.5.5 2.5.5 2.5 6.5 1 16.5 1 23 0 0 0 1.5-1 0-2.5 0 0 .5-1.5-1-2.5-.5-2.5-.5-2 .5-3.5 1-2 2.5-2 2.5-4-8.5-1.5-18.5-1.5-27 0z"/>
    <path d="M11.5 30c3.5-1 18.5-1 22 0M12 33.5c6-1 15-1 21 0" fill="none" stroke="#2dd4bf" stroke-width="1.5"/>
  </g>
</svg>''';

  /// White Rook vector evolved from `krk_6_6.html`.
  static const String whiteRook = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#f8fafc" stroke="#0f172a" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9 39h27v-3H9v3zM12 36v-4h21v4H12zM11 14V9h4v2h5V9h5v2h5V9h4v5"/>
    <path d="M34 14l-3 3H14l-3-3"/>
    <path d="M31 17v12.5H14V17"/>
    <path d="M31 29.5l1.5 2.5h-20l1.5-2.5"/>
    <path d="M11 14h23" fill="none" stroke="#2dd4bf" stroke-width="1.8"/>
  </g>
</svg>''';

  /// White Bishop vector matching the Cyber-Slate Staunton aesthetic.
  static const String whiteBishop = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#f8fafc" stroke="#0f172a" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9 36c3.39-.97 10.11.43 13.5-2 3.39 2.43 10.11 1.03 13.5 2 0 0 1.65.54 3 2-.68.97-1.65.99-3 .5-3.39-.97-10.11.46-13.5-1-3.39 1.46-10.11.03-13.5 1-1.35.49-2.32.47-3-.5 1.35-1.94 3-2 3-2z"/>
    <path d="M15 32c2.5 2.5 12.5 2.5 15 0 .5-1.5 0-2 0-2 0-2.5-2.5-4-2.5-4 5.5-1.5 6-11.5-5-15.5-11 4-10.5 14-5 15.5 0 0-2.5 1.5-2.5 4 0 0-.5.5 0 2z"/>
    <circle cx="22.5" cy="8" r="2.5" fill="#2dd4bf"/>
    <path d="M17.5 26h10M15 30h15M22.5 15.5v5M20 18h5" fill="none" stroke="#2dd4bf" stroke-width="1.8"/>
  </g>
</svg>''';

  /// Black King vector evolved from `krk_6_6.html`.
  static const String blackKing = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#090d16" stroke="#c4b5fd" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M22.5 11.63V6M20 8h5" stroke="#a78bfa" stroke-width="2.2"/>
    <path d="M22.5 25s4.5-7.5 3-10.5c0 0-1-2.5-3-2.5s-3 2.5-3 2.5c-1.5 3 3 10.5 3 10.5"/>
    <path d="M11.5 37c5.5 3.5 15.5 3.5 21 0v-7s9-4.5 6-10.5c-4-6.5-13.5-3.5-16 4V27v-3.5c-3.5-7.5-13-10.5-16-4-3 6 5 10 5 10V37z"/>
    <path d="M11.5 30c5.5-3 15.5-3 21 0M11.5 33.5c5.5-3 15.5-3 21 0M11.5 37c5.5-3 15.5-3 21 0" fill="none" stroke="#a78bfa" stroke-width="1.2" opacity="0.85"/>
  </g>
</svg>''';

  /// Returns the inline SVG markup corresponding to [type].
  static String forType(PieceType type) => switch (type) {
        PieceType.wk => whiteKing,
        PieceType.wq => whiteQueen,
        PieceType.wr => whiteRook,
        PieceType.wb => whiteBishop,
        PieceType.bk => blackKing,
      };
}

/// Renders a crisp vector chess piece with subtle neon cyan (White) or violet
/// (Black) ambient halo and smooth selection scaling.
class ChessPieceToken extends StatelessWidget {
  /// Creates a [ChessPieceToken].
  const ChessPieceToken({
    super.key,
    required this.type,
    required this.size,
    this.isSelected = false,
    this.showGlow = true,
  });

  /// Piece kind (`WK`, `WQ`, `WR`, `WB`, `BK`).
  final PieceType type;

  /// Bounding square size in logical pixels.
  final double size;

  /// Scales the token up slightly when selected in setup mode.
  final bool isSelected;

  /// Enables the subtle radial neon aura behind the SVG.
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final glowColor = type.isWhite ? AppColors.cyan : AppColors.violet;
    final svgSize = size * 0.80;

    return AnimatedScale(
      scale: isSelected ? 1.11 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (showGlow)
              Container(
                width: size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      glowColor.withValues(alpha: isSelected ? 0.36 : 0.22),
                      glowColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            SvgPicture.string(
              ChessPieceSvgs.forType(type),
              width: svgSize,
              height: svgSize,
            ),
          ],
        ),
      ),
    );
  }
}
