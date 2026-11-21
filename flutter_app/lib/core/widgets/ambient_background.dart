/// core/widgets/ambient_background.dart
/// ====================================
/// Deep Cyber-Slate (`#0B0F19`) canvas with soft, non-glaring radial ambient
/// neon glows (cyan, violet, and cool sky) matching `krk_6_6.html`.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wraps [child] over the Cyber-Slate gradient backdrop.
class AmbientCyberBackground extends StatelessWidget {
  /// Creates an [AmbientCyberBackground].
  const AmbientCyberBackground({super.key, required this.child});

  /// Foreground application content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.bgBase),
        const IgnorePointer(
          child: CustomPaint(
            painter: _AmbientGlowPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1) Top-left soft cyan aura
    _drawRadialGlow(
      canvas,
      center: Offset(size.width * 0.16, size.height * 0.04),
      radius: size.longestSide * 0.52,
      color: AppColors.cyan.withValues(alpha: 0.085),
    );

    // 2) Top-right soft violet aura
    _drawRadialGlow(
      canvas,
      center: Offset(size.width * 0.88, size.height * 0.14),
      radius: size.longestSide * 0.46,
      color: AppColors.violet.withValues(alpha: 0.085),
    );

    // 3) Bottom-center cool sky aura
    _drawRadialGlow(
      canvas,
      center: Offset(size.width * 0.50, size.height * 0.98),
      radius: size.longestSide * 0.45,
      color: AppColors.sky.withValues(alpha: 0.055),
    );
  }

  void _drawRadialGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0.0)],
        stops: const <double>[0.0, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) => false;
}
