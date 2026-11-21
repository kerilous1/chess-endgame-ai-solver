/// core/widgets/animated_metric_chip.dart
/// =======================================
/// Count-up numeric telemetry chips and stat cards rendered in tabular
/// monospace typography (`AppTypography.mono`).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass_decorations.dart';

/// Compact rounded pill showing a label and smoothly animated numeric metric.
class AnimatedMetricChip extends StatelessWidget {
  /// Creates an [AnimatedMetricChip].
  const AnimatedMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.fractionDigits = 0,
    this.suffix = '',
    this.accent = AppColors.cyan,
    this.icon,
  });

  /// Short metric title (e.g. `"Expanded"`).
  final String label;

  /// Target numeric value animated via [TweenAnimationBuilder].
  final double value;

  /// Decimal precision (`0` for integer counts, `2` for milliseconds).
  final int fractionDigits;

  /// Optional unit appended after the number (`"ms"`, `"moves"`).
  final String suffix;

  /// Accent color highlighting the numeric readout.
  final Color accent;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: GlassDecorations.pill(
        active: false,
        inactiveColor: AppColors.glassSurfaceStrong,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
          ],
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              final formatted = fractionDigits == 0
                  ? animatedValue.round().toString()
                  : animatedValue.toStringAsFixed(fractionDigits);
              final text = suffix.isEmpty ? formatted : '$formatted $suffix';
              return Text(
                text,
                style: AppTypography.mono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Expanded KPI stat tile used in the Telemetry & Heuristic Inspector grid.
class AnimatedMetricCard extends StatelessWidget {
  /// Creates an [AnimatedMetricCard].
  const AnimatedMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.fractionDigits = 0,
    this.suffix = '',
    this.accent = AppColors.cyan,
    this.icon,
  });

  final String label;
  final double value;
  final int fractionDigits;
  final String suffix;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              final formatted = fractionDigits == 0
                  ? animatedValue.round().toString()
                  : animatedValue.toStringAsFixed(fractionDigits);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      formatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  if (suffix.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 4),
                    Text(
                      suffix,
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
