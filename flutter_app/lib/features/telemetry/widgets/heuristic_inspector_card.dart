/// features/telemetry/widgets/heuristic_inspector_card.dart
/// =========================================================
/// Live Heuristic Inspector & Run Metrics Card:
/// - Evaluates the built-in admissible heuristic (`endgameHeuristic`) on the
///   currently displayed board state (`g(n)`, `h(n)`, `f(n)`).
/// - Displays Edge Distance, King Gap, and an animated Checkmate Progress bar.
/// - Includes a concise expandable note explaining how `h(n)` works.
/// - Shows animated count-up Run Metrics (`Time ms`, `Expanded Nodes`,
///   `Path Cost`, `Peak Frontier`) once a search result is present.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';

/// Live heuristic evaluator & performance telemetry card.
class HeuristicInspectorCard extends ConsumerStatefulWidget {
  /// Creates a [HeuristicInspectorCard].
  const HeuristicInspectorCard({super.key});

  @override
  ConsumerState<HeuristicInspectorCard> createState() =>
      _HeuristicInspectorCardState();
}

class _HeuristicInspectorCardState
    extends ConsumerState<HeuristicInspectorCard> {
  bool _noteExpanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final setup = ref.watch(boardSetupProvider);
    final playback = ref.watch(playbackProvider);
    final solver = ref.watch(solverProvider);

    final displayedBoard =
        playback.hasSolution ? playback.displayedBoard : setup.board;
    final activeStep = playback.hasSolution ? playback.activeStep : null;

    final allInBounds = displayedBoard.pieces.every(
      (p) => displayedBoard.inBounds(p.row, p.col),
    );
    final bk = displayedBoard.blackKingOrNull;
    final wk = displayedBoard.whiteKingOrNull;
    final canCompute = allInBounds && bk != null && wk != null;

    final isMate = canCompute && MovesEngine.isCheckmate(displayedBoard);
    final dEdge =
        canCompute ? edgeDistance(bk.pos, displayedBoard.boardSize) : 0;
    final kingGap = canCompute
        ? math.max(0, wk.pos.chebyshevDistanceTo(bk.pos) - 2)
        : 0;

    final gVal = activeStep?.g ?? 0.0;
    final hVal = activeStep != null
        ? activeStep.h
        : (canCompute ? endgameHeuristic(displayedBoard) : 0.0);
    final fVal = activeStep?.f ?? (gVal + hVal);

    final closeness = isMate
        ? 1.0
        : (1.0 - (hVal / 6.0)).clamp(0.06, 0.96);
    final closenessPct = (closeness * 100).round();

    final result = solver.result;

    return GlassCard(
      title: strings.telemetryCardTitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: GlassDecorations.pill(
          active: true,
          accent: AppColors.cyan,
        ),
        child: Text(
          strings.admissibleBadge,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.cyan,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1) Built-in Admissible Heuristic Formula Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceStrong,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'h(n) = $defaultHeuristicFormula',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.mono(
                  fontSize: 11.5,
                  color: AppColors.sky,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2) Live Geometry & g(n)/h(n)/f(n) Readout Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 340;
              final edgeTile = _InspectorTile(
                label: strings.edgeDistanceLabel,
                value: '$dEdge',
                accent: AppColors.sky,
              );
              final gapTile = _InspectorTile(
                label: strings.kingGapLabel,
                value: '$kingGap',
                accent: AppColors.violet,
              );
              final evalTile = _InspectorTile(
                label: 'g / h / f',
                value:
                    '${gVal.toStringAsFixed(0)} / ${hVal.toStringAsFixed(1)} / ${fVal.toStringAsFixed(1)}',
                accent: isMate ? AppColors.coral : AppColors.cyan,
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: edgeTile),
                        const SizedBox(width: 8),
                        Expanded(child: gapTile),
                      ],
                    ),
                    const SizedBox(height: 8),
                    evalTile,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(flex: 2, child: edgeTile),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: gapTile),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: evalTile),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // 3) Animated Closeness-to-Checkmate Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                strings.closenessLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '$closenessPct%',
                style: AppTypography.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isMate ? AppColors.coral : AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 9,
              color: AppColors.squareDark,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.06, end: closeness),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, animatedRatio, _) {
                  return FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: animatedRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: isMate
                              ? const <Color>[AppColors.amber, AppColors.coral]
                              : const <Color>[AppColors.cyan, AppColors.sky],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 4) Expandable Heuristic Explanation Note
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _noteExpanded = !_noteExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.school_outlined,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.heuristicNoteTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Icon(
                    _noteExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _noteExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.glassSurfaceStrong,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                strings.heuristicNoteBody,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // 5) Run Performance Metrics Strip (when a search has completed)
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 420 ? 4 : 2;
                final itemWidth =
                    (constraints.maxWidth - (cols - 1) * 8) / cols;
                final cards = <Widget>[
                  AnimatedMetricCard(
                    label: strings.metricTimeMs,
                    value: result.metrics.executionTimeMs,
                    fractionDigits: 2,
                    suffix: strings.msUnit,
                    accent: AppColors.sky,
                    icon: Icons.timer_outlined,
                  ),
                  AnimatedMetricCard(
                    label: strings.metricExpanded,
                    value: result.metrics.expandedNodes.toDouble(),
                    accent: AppColors.violet,
                    icon: Icons.hub_outlined,
                  ),
                  AnimatedMetricCard(
                    label: strings.metricCost,
                    value: result.metrics.solutionCost.toDouble(),
                    suffix: strings.movesUnit,
                    accent: AppColors.cyan,
                    icon: Icons.route_rounded,
                  ),
                  AnimatedMetricCard(
                    label: strings.metricMemory,
                    value: result.metrics.maxFrontierSize.toDouble(),
                    accent: AppColors.amber,
                    icon: Icons.memory_rounded,
                  ),
                ];

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cards
                      .map((c) => SizedBox(width: itemWidth, child: c))
                      .toList(growable: false),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InspectorTile extends StatelessWidget {
  const _InspectorTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
