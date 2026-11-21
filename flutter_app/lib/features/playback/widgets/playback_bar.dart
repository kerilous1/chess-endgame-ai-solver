/// features/playback/widgets/playback_bar.dart
/// ============================================
/// Step 3 Playback Console allowing the user to replay any solved checkmate
/// sequence frame-by-frame:
/// - **Forced LTR transport bar** (`⏮ ◀ ▶/⏸ ▶ ⏭`) so playback buttons keep
///   canonical media orientation in both Arabic RTL and English LTR.
/// - Speed pills (`0.5×`, `1×`, `2×`).
/// - Timeline scrubber `Slider`.
/// - Auto-scrolling horizontal move-notation chip strip (`0` = Initial,
///   `1. Kf3`, `1... Ke5`, `6. Rf6#`).
/// - Compact summary metrics (`Cost`, `Expanded`, `Time ms`).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';

/// Interactive playback bar rendered inside a [GlassCard] when a solution exists.
class PlaybackBar extends ConsumerStatefulWidget {
  /// Creates a [PlaybackBar].
  const PlaybackBar({super.key});

  @override
  ConsumerState<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends ConsumerState<PlaybackBar> {
  final ScrollController _stripController = ScrollController();

  @override
  void dispose() {
    _stripController.dispose();
    super.dispose();
  }

  void _scrollChipIntoView(int frameIndex, int totalFrames) {
    if (!_stripController.hasClients || totalFrames <= 0) return;
    final maxExtent = _stripController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final ratio = (frameIndex / totalFrames).clamp(0.0, 1.0);
    final target = (ratio * maxExtent).clamp(0.0, maxExtent);
    _stripController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final playback = ref.watch(playbackProvider);
    final solver = ref.watch(solverProvider);
    final notifier = ref.read(playbackProvider.notifier);

    ref.listen<int>(
      playbackProvider.select((s) => s.currentFrameIndex),
      (_, nextIndex) => _scrollChipIntoView(nextIndex, playback.totalFrames),
    );

    if (!playback.hasSolution) {
      return const SizedBox.shrink();
    }

    final result = solver.result;
    final activeStep = playback.activeStep;
    final frameTitle = activeStep == null
        ? strings.initialPositionLabel
        : strings.stepOfLabel(playback.currentFrameIndex, playback.totalFrames);

    return GlassCard(
      stepNumber: 3,
      title: strings.playbackCardTitle,
      badgeTone: StepBadgeTone.cyan,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: GlassDecorations.pill(
          active: activeStep != null,
          accent: activeStep?.isCheckmate == true
              ? AppColors.coral
              : (activeStep?.actor == Actor.black
                  ? AppColors.violet
                  : AppColors.cyan),
        ),
        child: Text(
          activeStep == null
              ? strings.initialPositionLabel
              : '${(activeStep.g).round()}${activeStep.actor == Actor.white ? "." : "..."} ${activeStep.notation}',
          style: AppTypography.mono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1) Compact Summary Headline & Animated Metric Chips
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Text(
                frameTitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              if (result != null && result.isSolved)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    AnimatedMetricChip(
                      label: strings.metricCost,
                      value: result.metrics.solutionCost.toDouble(),
                      suffix: strings.movesUnit,
                      accent: AppColors.cyan,
                    ),
                    AnimatedMetricChip(
                      label: strings.metricExpanded,
                      value: result.metrics.expandedNodes.toDouble(),
                      accent: AppColors.violet,
                    ),
                    AnimatedMetricChip(
                      label: strings.metricTimeMs,
                      value: result.metrics.executionTimeMs,
                      fractionDigits: 2,
                      suffix: strings.msUnit,
                      accent: AppColors.sky,
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 2) Forced-LTR Transport Buttons + Speed Selector (Zero Phone Overflow)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _TransportButton(
                      key: const ValueKey<String>('playback_first'),
                      icon: Icons.first_page_rounded,
                      onPressed: playback.isAtStart ? null : notifier.first,
                    ),
                    const SizedBox(width: 4),
                    _TransportButton(
                      key: const ValueKey<String>('playback_prev'),
                      icon: Icons.chevron_left_rounded,
                      onPressed: playback.isAtStart ? null : notifier.prev,
                    ),
                    const SizedBox(width: 4),
                    _TransportButton(
                      key: const ValueKey<String>('playback_play_pause'),
                      icon: playback.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      accent: AppColors.cyan,
                      highlighted: playback.isPlaying,
                      onPressed: notifier.toggleAutoPlay,
                    ),
                    const SizedBox(width: 4),
                    _TransportButton(
                      key: const ValueKey<String>('playback_next'),
                      icon: Icons.chevron_right_rounded,
                      onPressed: playback.isAtEnd ? null : notifier.next,
                    ),
                    const SizedBox(width: 4),
                    _TransportButton(
                      key: const ValueKey<String>('playback_last'),
                      icon: Icons.last_page_rounded,
                      onPressed: playback.isAtEnd ? null : notifier.last,
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurfaceStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: PlaybackSpeed.values.map((speed) {
                      final active = playback.speed == speed;
                      return InkWell(
                        key: ValueKey<String>('speed_${speed.name}'),
                        borderRadius: BorderRadius.circular(7),
                        onTap: () => notifier.setSpeed(speed),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.cyan.withValues(alpha: 0.22)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            speed.label,
                            style: AppTypography.mono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? const Color(0xFFCCFBF1)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3) Timeline Scrubber Slider (LTR progress left -> right)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: <Widget>[
                Text(
                  '${playback.currentFrameIndex}',
                  style: AppTypography.mono(
                    fontSize: 12,
                    color: AppColors.cyan,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: playback.currentFrameIndex
                        .toDouble()
                        .clamp(0, math.max(1, playback.totalFrames).toDouble()),
                    min: 0,
                    max: math.max(1, playback.totalFrames).toDouble(),
                    divisions: math.max(1, playback.totalFrames),
                    onChanged: (val) => notifier.scrubTo(val.round()),
                  ),
                ),
                Text(
                  '${playback.totalFrames}',
                  style: AppTypography.mono(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 4) Horizontal Scrollable Move Notation Chips
          SizedBox(
            height: 36,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ListView.separated(
                controller: _stripController,
                scrollDirection: Axis.horizontal,
                itemCount: playback.steps.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final isActive = index == playback.currentFrameIndex;
                  if (index == 0) {
                    return _MoveChip(
                      label: strings.initialPositionLabel,
                      isActive: isActive,
                      accent: AppColors.sky,
                      onTap: () => notifier.scrubTo(0),
                    );
                  }
                  final step = playback.steps[index - 1];
                  final turnNum = step.g.round();
                  final prefix = step.actor == Actor.white
                      ? '$turnNum.'
                      : '$turnNum...';
                  final accent = step.isCheckmate
                      ? AppColors.coral
                      : (step.actor == Actor.white
                          ? AppColors.cyan
                          : AppColors.violet);
                  return _MoveChip(
                    label: '$prefix ${step.piece.glyph} ${step.notation}',
                    isActive: isActive,
                    accent: accent,
                    onTap: () => notifier.scrubTo(index),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            strings.shortcutsHint,
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.accent = AppColors.textMain,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.36,
      child: Material(
        color: highlighted
            ? accent.withValues(alpha: 0.22)
            : AppColors.glassSurfaceStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: highlighted
                ? accent.withValues(alpha: 0.85)
                : AppColors.glassBorder,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: highlighted ? Colors.white : accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({
    required this.label,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: GlassDecorations.pill(
          active: isActive,
          accent: accent,
          inactiveColor: AppColors.glassSurfaceStrong,
        ),
        child: Text(
          label,
          style: AppTypography.mono(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
