/// core/widgets/glass_card.dart
/// ============================
/// Frosted Cyber-Slate container (`GlassCard`) and numbered step indicator
/// pill (`StepBadge`) used across every workspace and benchmark section.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass_decorations.dart';

/// Neon tint variants for [StepBadge].
enum StepBadgeTone { cyan, violet, amber }

/// Frosted glass panel with optional numbered header and trailing controls.
class GlassCard extends StatelessWidget {
  /// Creates a [GlassCard].
  const GlassCard({
    super.key,
    required this.child,
    this.title,
    this.stepNumber,
    this.badgeTone = StepBadgeTone.cyan,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18,
    this.borderColor,
    this.useBlur = true,
  });

  /// Inner card body.
  final Widget child;

  /// Optional section header title.
  final String? title;

  /// Optional 1-based step badge displayed next to [title].
  final int? stepNumber;

  /// Accent color for [stepNumber].
  final StepBadgeTone badgeTone;

  /// Optional trailing widget aligned opposite [title] in the header row.
  final Widget? trailing;

  /// Inner padding around header and [child].
  final EdgeInsetsGeometry padding;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Optional custom border color override.
  final Color? borderColor;

  /// Enables `BackdropFilter` glass blur (disable for deeply nested cards if desired).
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: GlassDecorations.card(
        borderRadius: borderRadius,
        borderColor: borderColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null || trailing != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (stepNumber != null) ...<Widget>[
                  StepBadge(number: stepNumber!, tone: badgeTone),
                  const SizedBox(width: 9),
                ],
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );

    if (!useBlur) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}

/// Compact 24×24 rounded square displaying a section step number.
class StepBadge extends StatelessWidget {
  /// Creates a [StepBadge] showing [number].
  const StepBadge({
    super.key,
    required this.number,
    this.tone = StepBadgeTone.cyan,
  });

  /// Step number rendered inside the badge.
  final int number;

  /// Neon color tone.
  final StepBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color accent, Color bg) = switch (tone) {
      StepBadgeTone.cyan => (AppColors.cyan, AppColors.cyanSoft),
      StepBadgeTone.violet => (AppColors.violet, AppColors.violetSoft),
      StepBadgeTone.amber => (AppColors.amber, AppColors.amberSoft),
    };

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: accent,
          height: 1.0,
        ),
      ),
    );
  }
}
