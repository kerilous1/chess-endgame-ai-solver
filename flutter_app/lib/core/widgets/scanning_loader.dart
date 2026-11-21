/// core/widgets/scanning_loader.dart
/// ==================================
/// Futuristic AI search radar & node-expansion wave animation displayed while
/// `Isolate.run` computes a single solve or full benchmark suite, plus a
/// reusable cyber-slate shimmer placeholder bar.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Pulsing radar sweep + expanding search rings shown over the board/panel
/// while a background Isolate is running.
class AiScanningOverlay extends StatefulWidget {
  /// Creates an [AiScanningOverlay].
  const AiScanningOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.cyan,
  });

  /// Primary localized status headline.
  final String title;

  /// Secondary description (e.g., `"60fps isolated execution"`).
  final String subtitle;

  /// Accent color for the radar beam and node pulses.
  final Color accent;

  @override
  State<AiScanningOverlay> createState() => _AiScanningOverlayState();
}

class _AiScanningOverlayState extends State<AiScanningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgBase.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accent.withValues(alpha: 0.42)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 96,
            height: 96,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadarWavePainter(
                    progress: _controller.value,
                    accent: widget.accent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final elapsedMs = _stopwatch.elapsedMilliseconds;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${elapsedMs}ms',
                  style: AppTypography.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.accent,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RadarWavePainter extends CustomPainter {
  const _RadarWavePainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * 0.46;

    // 1) Concentric radar rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withValues(alpha: 0.24);
    for (final factor in <double>[0.35, 0.68, 1.0]) {
      canvas.drawCircle(center, maxRadius * factor, ringPaint);
    }

    // 2) Expanding sonar wave pulse
    final pulseRadius = maxRadius * progress;
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = accent.withValues(alpha: (1.0 - progress) * 0.65);
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // 3) Rotating sweep beam
    final sweepAngle = progress * math.pi * 2.0;
    final sweepRect = Rect.fromCircle(center: center, radius: maxRadius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 0.65,
        transform: GradientRotation(sweepAngle),
        colors: <Color>[
          accent.withValues(alpha: 0.0),
          accent.withValues(alpha: 0.38),
        ],
      ).createShader(sweepRect);
    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 4) Orbiting search-frontier nodes
    for (var i = 0; i < 4; i++) {
      final angle = sweepAngle * 0.8 + (i * math.pi / 2);
      final orbit = maxRadius * (0.42 + (i % 2) * 0.32);
      final dot = Offset(
        center.dx + math.cos(angle) * orbit,
        center.dy + math.sin(angle) * orbit,
      );
      canvas.drawCircle(
        dot,
        3.2,
        Paint()..color = i.isEven ? accent : AppColors.violet,
      );
    }

    // 5) Core center beacon
    canvas.drawCircle(center, 4.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

/// Smooth cyber-slate loading shimmer placeholder bar.
class ShimmerBar extends StatefulWidget {
  /// Creates a [ShimmerBar].
  const ShimmerBar({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = (_controller.value * 2.4) - 1.2;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(shift - 0.8, 0),
              end: Alignment(shift + 0.8, 0),
              colors: const <Color>[
                AppColors.squareDark,
                Color(0xFF263449),
                AppColors.squareDark,
              ],
            ),
          ),
        );
      },
    );
  }
}
