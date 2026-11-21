/// features/benchmark/widgets/benchmark_bar_chart.dart
/// =====================================================
/// Animated horizontal comparison bar chart supporting switching between
/// Expanded Nodes, Execution Time (ms), and Path Cost with clean proportional
/// bar widths.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';

/// Animated multi-algorithm comparative horizontal bar chart.
class BenchmarkBarChart extends StatelessWidget {
  /// Creates a [BenchmarkBarChart].
  const BenchmarkBarChart({
    super.key,
    required this.suite,
    required this.metric,
    required this.strings,
    required this.onMetricChanged,
  });

  final BenchmarkSuiteResult suite;
  final BenchmarkChartMetric metric;
  final AppStrings strings;
  final ValueChanged<BenchmarkChartMetric> onMetricChanged;

  double _extractValue(SearchResult result) => switch (metric) {
        BenchmarkChartMetric.expandedNodes =>
          result.metrics.expandedNodes.toDouble(),
        BenchmarkChartMetric.executionTimeMs => result.metrics.executionTimeMs,
        BenchmarkChartMetric.solutionCost =>
          result.metrics.solutionCost.toDouble(),
      };

  String _formatValue(SearchResult result) {
    if (!result.isSolved && metric == BenchmarkChartMetric.solutionCost) {
      return '-';
    }
    return switch (metric) {
      BenchmarkChartMetric.expandedNodes => '${result.metrics.expandedNodes}',
      BenchmarkChartMetric.executionTimeMs =>
        '${result.metrics.executionTimeMs.toStringAsFixed(2)} ${strings.msUnit}',
      BenchmarkChartMetric.solutionCost =>
        '${result.metrics.solutionCost} ${strings.movesUnit}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final values = suite.results.map(_extractValue).toList(growable: false);
    final maxVal = values.isEmpty ? 1.0 : math.max(1.0, values.reduce(math.max));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Metric selector pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _ChartMetricChip(
                label: strings.metricExpanded,
                active: metric == BenchmarkChartMetric.expandedNodes,
                onTap: () =>
                    onMetricChanged(BenchmarkChartMetric.expandedNodes),
              ),
              _ChartMetricChip(
                label: strings.metricTimeMs,
                active: metric == BenchmarkChartMetric.executionTimeMs,
                onTap: () =>
                    onMetricChanged(BenchmarkChartMetric.executionTimeMs),
              ),
              _ChartMetricChip(
                label: strings.metricCost,
                active: metric == BenchmarkChartMetric.solutionCost,
                onTap: () =>
                    onMetricChanged(BenchmarkChartMetric.solutionCost),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Proportional Horizontal Animated Bars
          ...List<Widget>.generate(suite.results.length, (i) {
            final res = suite.results[i];
            final algo = AlgorithmRegistry.tryById(res.algorithmId);
            final accent = algo != null
                ? AppColors.categoryAccent(algo.category)
                : AppColors.cyan;
            final label = algo != null
                ? (strings.isAr ? algo.nameAr : algo.nameEn)
                : res.algorithmId;

            final raw = values[i];
            final ratio = raw <= 0
                ? 0.0
                : (raw / maxVal).clamp(0.05, 1.0);

            return Padding(
              padding: EdgeInsets.only(
                bottom: i == suite.results.length - 1 ? 0 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatValue(res),
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: res.isSolved ? accent : AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 11,
                      color: AppColors.squareDark,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: ratio),
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedRatio, _) {
                          return FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: animatedRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  colors: res.isSolved
                                      ? <Color>[
                                          accent.withValues(alpha: 0.72),
                                          accent,
                                        ]
                                      : <Color>[
                                          AppColors.coral.withValues(alpha: 0.5),
                                          AppColors.coral,
                                        ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChartMetricChip extends StatelessWidget {
  const _ChartMetricChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: GlassDecorations.pill(
          active: active,
          accent: AppColors.cyan,
          inactiveColor: AppColors.bgElevated,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
