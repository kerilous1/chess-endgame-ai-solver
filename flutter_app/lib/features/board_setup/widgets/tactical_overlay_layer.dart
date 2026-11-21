/// features/board_setup/widgets/tactical_overlay_layer.dart
/// ==========================================================
/// CustomPainter overlay rendering Tactical Vision onto the 6×6 grid:
/// - Squares controlled by White attackers (`WQ`/`WR`/`WB`) and White King
///   (with blended dual-control shading matching `krk_6_6.html`).
/// - Last-move origin and destination square highlights.
/// - Pulsing Amber (`#F59E0B`) legal Black King escape dots.
/// - Pulsing Coral (`#FB7185`) check / checkmate halo around the Black King.
///
/// Uses a single shared repeating [AnimationController] for smooth 60fps pulses.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/theme/theme.dart';

/// Paints tactical attack shading, last-move borders, escape dots, and check rings.
class TacticalOverlayLayer extends StatefulWidget {
  /// Creates a [TacticalOverlayLayer].
  const TacticalOverlayLayer({
    super.key,
    required this.board,
    required this.showTacticalVision,
    this.activeStep,
  });

  /// Currently displayed board snapshot.
  final BoardState board;

  /// Whether attacked squares and escape dots should be painted.
  final bool showTacticalVision;

  /// Active playback step (used for last-move square highlights).
  final MoveStep? activeStep;

  @override
  State<TacticalOverlayLayer> createState() => _TacticalOverlayLayerState();
}

class _TacticalOverlayLayerState extends State<TacticalOverlayLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final allInBounds =
        board.pieces.every((p) => board.inBounds(p.row, p.col));

    // Compute separated slider vs. king attack maps for distinct visual shading.
    final sliderAttacked = <GridPos>{};
    final kingAttacked = <GridPos>{};
    var inCheck = false;
    var inMate = false;
    var escapeSquares = const <GridPos>[];

    if (allInBounds) {
      for (final piece in board.whiteAttackers) {
        sliderAttacked.addAll(
          MovesEngine.getPieceAttackedSquares(
            board,
            piece,
            ignoreBlackKing: false,
          ),
        );
      }
      final wk = board.whiteKingOrNull;
      if (wk != null) {
        kingAttacked.addAll(
          MovesEngine.getPieceAttackedSquares(
            board,
            wk,
            ignoreBlackKing: false,
          ),
        );
      }
      inCheck = MovesEngine.isCheck(board);
      inMate = MovesEngine.isCheckmate(board);
      if (board.blackKingOrNull != null) {
        escapeSquares = MovesEngine.getBlackKingMoves(board)
            .map((m) => m.to)
            .toList(growable: false);
      }
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return CustomPaint(
            painter: _TacticalOverlayPainter(
              boardSize: board.boardSize,
              showVision: widget.showTacticalVision,
              sliderAttacked: sliderAttacked,
              kingAttacked: kingAttacked,
              escapeSquares: escapeSquares,
              blackKingPos: board.blackKingOrNull?.pos,
              isCheck: inCheck,
              isCheckmate: inMate,
              activeStep: widget.activeStep,
              pulse: _pulseController.value,
            ),
          );
        },
      ),
    );
  }
}

class _TacticalOverlayPainter extends CustomPainter {
  const _TacticalOverlayPainter({
    required this.boardSize,
    required this.showVision,
    required this.sliderAttacked,
    required this.kingAttacked,
    required this.escapeSquares,
    required this.blackKingPos,
    required this.isCheck,
    required this.isCheckmate,
    required this.activeStep,
    required this.pulse,
  });

  final int boardSize;
  final bool showVision;
  final Set<GridPos> sliderAttacked;
  final Set<GridPos> kingAttacked;
  final List<GridPos> escapeSquares;
  final GridPos? blackKingPos;
  final bool isCheck;
  final bool isCheckmate;
  final MoveStep? activeStep;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cell = size.width / boardSize;
    final smoothPulse = 0.5 - 0.5 * math.cos(pulse * math.pi);

    // 1) Attacked square shading (slider control, king zone, or combined)
    if (showVision) {
      for (var r = 0; r < boardSize; r++) {
        for (var c = 0; c < boardSize; c++) {
          final pos = GridPos(r, c);
          final bySlider = sliderAttacked.contains(pos);
          final byKing = kingAttacked.contains(pos);
          if (!bySlider && !byKing) continue;

          final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
          if (bySlider && byKing) {
            final paint = Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.cyan.withValues(alpha: 0.16),
                  AppColors.indigo.withValues(alpha: 0.22),
                ],
              ).createShader(rect);
            canvas.drawRect(rect, paint);
            canvas.drawRect(
              rect.deflate(0.5),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = AppColors.sky.withValues(alpha: 0.22),
            );
          } else if (bySlider) {
            canvas.drawRect(rect, Paint()..color = AppColors.sliderControl);
            canvas.drawRect(
              rect.deflate(0.5),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = AppColors.cyan.withValues(alpha: 0.16),
            );
          } else {
            canvas.drawRect(rect, Paint()..color = AppColors.kingControl);
          }
        }
      }
    }

    // 2) Last-move origin and destination square highlights
    final step = activeStep;
    if (step != null) {
      final accent = step.actor == Actor.white ? AppColors.cyan : AppColors.violet;
      final fromRect = Rect.fromLTWH(
        step.from.col * cell,
        step.from.row * cell,
        cell,
        cell,
      ).deflate(1.5);
      final toRect = Rect.fromLTWH(
        step.to.col * cell,
        step.to.row * cell,
        cell,
        cell,
      ).deflate(1.5);

      canvas.drawRect(
        fromRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = accent.withValues(alpha: 0.45),
      );

      canvas.drawRect(
        toRect,
        Paint()..color = accent.withValues(alpha: 0.12),
      );
      canvas.drawRect(
        toRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = accent.withValues(alpha: 0.72),
      );
    }

    // 3) Pulsing Amber escape dots on legal Black King moves
    if (showVision) {
      final dotRadius = cell * (0.11 + smoothPulse * 0.025);
      final haloRadius = cell * (0.19 + smoothPulse * 0.05);
      for (final sq in escapeSquares) {
        final center = Offset((sq.col + 0.5) * cell, (sq.row + 0.5) * cell);
        canvas.drawCircle(
          center,
          haloRadius,
          Paint()
            ..color = AppColors.amber.withValues(alpha: 0.24 - smoothPulse * 0.08),
        );
        canvas.drawCircle(
          center,
          dotRadius,
          Paint()..color = AppColors.amber,
        );
      }
    }

    // 4) Pulsing Coral check / checkmate ring around Black King
    if (isCheck && blackKingPos != null) {
      final bkCenter = Offset(
        (blackKingPos!.col + 0.5) * cell,
        (blackKingPos!.row + 0.5) * cell,
      );
      final baseRadius = cell * 0.42;
      final scale = 0.94 + smoothPulse * 0.09;

      canvas.drawCircle(
        bkCenter,
        baseRadius * scale,
        Paint()
          ..color = AppColors.coral.withValues(alpha: isCheckmate ? 0.22 : 0.14),
      );
      canvas.drawCircle(
        bkCenter,
        baseRadius * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCheckmate ? 3.0 : 2.3
          ..color = AppColors.coral.withValues(alpha: 0.72 + smoothPulse * 0.25),
      );
      if (isCheckmate) {
        canvas.drawCircle(
          bkCenter,
          baseRadius * (1.08 + smoothPulse * 0.08),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = AppColors.amber.withValues(alpha: 0.45),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalOverlayPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.showVision != showVision ||
        oldDelegate.isCheck != isCheck ||
        oldDelegate.isCheckmate != isCheckmate ||
        oldDelegate.blackKingPos != blackKingPos ||
        oldDelegate.activeStep != activeStep ||
        oldDelegate.sliderAttacked.length != sliderAttacked.length ||
        oldDelegate.kingAttacked.length != kingAttacked.length ||
        oldDelegate.escapeSquares.length != escapeSquares.length;
  }
}
