/// core/widgets/neon_button.dart
/// =============================
/// Accessible, glow-accented interactive buttons matching the `krk_6_6.html`
/// CTA hierarchy (`primaryAmber`, `cyan`, `violet`, `ghost`).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Functional color roles for [NeonButton].
enum NeonButtonVariant {
  /// Primary Solve CTA (warm amber-to-coral gradient).
  primaryAmber,

  /// White/Optimal or active toggle button (muted cyan).
  cyan,

  /// Secondary analytical / random / benchmark action (muted violet).
  violet,

  /// Subtle low-emphasis control button.
  ghost,
}

/// Interactive pill/rounded button with hover glow and built-in loading state.
class NeonButton extends StatefulWidget {
  /// Creates a [NeonButton].
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = NeonButtonVariant.cyan,
    this.isActive = false,
    this.isLoading = false,
    this.compact = false,
    this.expand = false,
  });

  /// Localized text label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Tap callback (`null` disables the button cleanly).
  final VoidCallback? onPressed;

  /// Visual color variant.
  final NeonButtonVariant variant;

  /// Highlights the button as an active toggle pill.
  final bool isActive;

  /// Displays a compact spinner instead of [icon] while disabled.
  final bool isLoading;

  /// Uses 36px height instead of standard 44px touch target height.
  final bool compact;

  /// Stretches button to available horizontal width when true.
  final bool expand;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final minHeight = widget.compact ? 36.0 : 44.0;
    final horizontalPad = widget.compact ? 11.0 : 14.0;

    final (
      Color fg,
      Color bg,
      Color border,
      Color glow,
      Gradient? gradient,
    ) = switch (widget.variant) {
      NeonButtonVariant.primaryAmber => (
          const Color(0xFFFEF3C7),
          Colors.transparent,
          AppColors.amber.withValues(alpha: _hovered ? 0.85 : 0.58),
          AppColors.amber.withValues(alpha: _hovered ? 0.28 : 0.16),
          AppColors.primaryCtaGradient,
        ),
      NeonButtonVariant.cyan => (
          widget.isActive ? Colors.white : const Color(0xFFCCFBF1),
          widget.isActive
              ? AppColors.cyan.withValues(alpha: 0.24)
              : AppColors.cyan.withValues(alpha: _hovered ? 0.20 : 0.12),
          AppColors.cyan.withValues(
            alpha: widget.isActive ? 0.92 : (_hovered ? 0.72 : 0.42),
          ),
          AppColors.cyanGlow,
          null,
        ),
      NeonButtonVariant.violet => (
          const Color(0xFFEDE9FE),
          widget.isActive
              ? AppColors.violet.withValues(alpha: 0.24)
              : AppColors.violet.withValues(alpha: _hovered ? 0.20 : 0.12),
          AppColors.violet.withValues(
            alpha: widget.isActive ? 0.88 : (_hovered ? 0.70 : 0.38),
          ),
          AppColors.violetGlow,
          null,
        ),
      NeonButtonVariant.ghost => (
          _hovered || widget.isActive ? AppColors.textMain : AppColors.textMuted,
          AppColors.glassSurfaceStrong.withValues(alpha: _hovered ? 0.85 : 0.58),
          _hovered || widget.isActive
              ? AppColors.cyan.withValues(alpha: 0.45)
              : AppColors.glassBorder,
          Colors.transparent,
          null,
        ),
    };

    final childRow = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.isLoading) ...<Widget>[
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...<Widget>[
          Icon(widget.icon, size: widget.compact ? 16 : 18, color: fg),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.compact ? 12.5 : 13.5,
              fontWeight: widget.variant == NeonButtonVariant.primaryAmber
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1.0 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: minHeight),
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
            boxShadow: (enabled && (_hovered || widget.isActive || widget.variant == NeonButtonVariant.primaryAmber))
                ? <BoxShadow>[
                    BoxShadow(
                      color: glow,
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: enabled ? widget.onPressed : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: widget.compact ? 6 : 9,
                ),
                child: childRow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
