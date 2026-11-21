/// features/board_setup/widgets/move_arrow_overlay.dart
/// ======================================================
/// Animated `CustomPainter` layer drawing glowing dashed move trajectories and
/// an expanding destination ripple ring whenever stepping through a solution.
///
/// Colors:
/// - White moves: Neon Cyan (`#2DD4BF`)
/// - Black King replies: Neon Violet (`#A78BFA`)
/// - Checkmate destination burst: Coral (`#FB7185`)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/theme/theme.dart';

/// Renders the animated dashed arrow & destination ripple for [activeStep].
class MoveArrowOverlay extends StatefulWidget {
  /// Creates a [MoveArrowOverlay].
  const MoveArrowOverlay({
    super.key,
    required this.boardSize,
    required this.activeStep,
  });

  /// Grid dimension (6 for 6×6 chess).
  final int boardSize;

  /// Active playback move (`null` hides arrows on frame 0).
  final MoveStep? activeStep;

  @override
  State<MoveArrowOverlay> createState() => _MoveArrowOverlayState();
}

class _MoveArrowOverlayState extends State<MoveArrowOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _dashController;
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (widget.activeStep != null) {
      _rippleController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant MoveArrowOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeStep != null &&
        widget.activeStep?.stepIndex != oldWidget.activeStep?.stepIndex) {
      _rippleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _dashController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.activeStep;
    if (step == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _dashController,
          _rippleController,
        ]),
        builder: (context, _) {
          return CustomPaint(
            painter: _MoveArrowPainter(
              boardSize: widget.boardSize,
              step: step,
              dashPhase: _dashController.value,
              rippleProgress: Curves.easeOutCubic.transform(
                _rippleController.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoveArrowPainter extends CustomPainter {
  const _MoveArrowPainter({
    required this.boardSize,
    required this.step,
    required this.dashPhase,
    required this.rippleProgress,
  });

  final int boardSize;
  final MoveStep step;
  final double dashPhase;
  final double rippleProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cell = size.width / boardSize;
    final accent =
        step.actor == Actor.white ? AppColors.cyan : AppColors.violet;
    final rippleColor = step.isCheckmate ? AppColors.coral : accent;

    final start = Offset(
      (step.from.col + 0.5) * cell,
      (step.from.row + 0.5) * cell,
    );
    final end = Offset(
      (step.to.col + 0.5) * cell,
      (step.to.row + 0.5) * cell,
    );

    final delta = end - start;
    final dist = delta.distance;
    if (dist < 1.0) return;

    final unit = delta / dist;
    final trimmedEnd = end - unit * (cell * 0.24);
    final trimmedStart = start + unit * (cell * 0.14);

    // 1) Destination expanding ripple ring
    if (rippleProgress < 1.0) {
      final rippleRadius = cell * (0.16 + rippleProgress * 0.34);
      canvas.drawCircle(
        end,
        rippleRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * (1.0 - rippleProgress * 0.5)
          ..color = rippleColor.withValues(alpha: (1.0 - rippleProgress) * 0.85),
      );
    }

    // 2) Soft glow under trajectory
    canvas.drawLine(
      trimmedStart,
      trimmedEnd,
      Paint()
        ..color = accent.withValues(alpha: 0.24)
        ..strokeWidth = math.max(5.0, cell * 0.12)
        ..strokeCap = StrokeCap.round,
    );

    // 3) Animated flowing dashed trajectory shaft
    final dashLen = cell * 0.17;
    final gapLen = cell * 0.11;
    final period = dashLen + gapLen;
    final shaftLen = (trimmedEnd - trimmedStart).distance;
    final dashPaint = Paint()
      ..color = accent.withValues(alpha: 0.92)
      ..strokeWidth = math.max(2.6, cell * 0.055)
      ..strokeCap = StrokeCap.round;

    var cursor = -(dashPhase * period);
    while (cursor < shaftLen) {
      final segStart = math.max(0.0, cursor);
      final segEnd = math.min(shaftLen, cursor + dashLen);
      if (segEnd > segStart) {
        canvas.drawLine(
          trimmedStart + unit * segStart,
          trimmedStart + unit * segEnd,
          dashPaint,
        );
      }
      cursor += period;
    }

    // 4) Origin anchor dot
    canvas.drawCircle(
      start,
      cell * 0.075,
      Paint()..color = accent.withValues(alpha: 0.65),
    );

    // 5) Crisp triangular arrowhead pointing into the target square
    final angle = delta.direction;
    final headLen = math.max(10.0, cell * 0.24);
    final headHalfAngle = 0.48;
    final tip = end - unit * (cell * 0.10);
    final leftWing = Offset(
      tip.dx - headLen * math.cos(angle - headHalfAngle),
      tip.dy - headLen * math.sin(angle - headHalfAngle),
    );
    final rightWing = Offset(
      tip.dx - headLen * math.cos(angle + headHalfAngle),
      tip.dy - headLen * math.sin(angle + headHalfAngle),
    );

    final headPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();

    canvas.drawPath(headPath, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _MoveArrowPainter oldDelegate) {
    return oldDelegate.dashPhase != dashPhase ||
        oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.step.stepIndex != step.stepIndex ||
        oldDelegate.step.from != step.from ||
        oldDelegate.step.to != step.to;
  }
}
