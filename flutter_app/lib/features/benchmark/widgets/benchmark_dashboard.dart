/// features/benchmark/widgets/benchmark_dashboard.dart
/// =====================================================
/// Step 4 Dynamic Benchmark & Comparison Dashboard.
///
/// Runs every algorithm in [AlgorithmRegistry.all] on the exact same board
/// inside `Isolate.run`, renders 3 Winner Cards, an interactive horizontally
/// scrollable Comparison Table (tapping any solved row loads its moves onto the
/// board!), an animated [BenchmarkBarChart], and an AR/EN analytical takeaway.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import 'benchmark_bar_chart.dart';

/// Multi-algorithm benchmark comparison card.
class BenchmarkDashboard extends ConsumerWidget {
  /// Creates a [BenchmarkDashboard].
  const BenchmarkDashboard({
    super.key,
    this.onInspectLoaded,
  });

  /// Optional callback invoked after loading a solved trace from the table
  /// (used on mobile tabbed layouts to return smoothly to the Board tab).
  final VoidCallback? onInspectLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final setup = ref.watch(boardSetupProvider);
    final solver = ref.watch(solverProvider);
    final benchmark = ref.watch(benchmarkProvider);
    final notifier = ref.read(benchmarkProvider.notifier);

    final suite = benchmark.suite;

    return GlassCard(
      stepNumber: 4,
      title: strings.benchmarkTitle,
      badgeTone: StepBadgeTone.amber,
      trailing: NeonButton(
        compact: true,
        variant: NeonButtonVariant.cyan,
        icon: Icons.compare_arrows_rounded,
        label: strings.compareAllCta,
        isLoading: benchmark.isRunning,
        onPressed: (setup.validation.isValid && !solver.isSolving)
            ? notifier.runCompareAll
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.benchmarkSubtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          if (benchmark.isRunning) ...<Widget>[
            AiScanningOverlay(
              title: strings.benchmarkScanningTitle,
              subtitle: strings.benchmarkScanningSubtitle,
              accent: AppColors.amber,
            ),
            const SizedBox(height: 12),
            const ShimmerBar(height: 16),
            const SizedBox(height: 8),
            const ShimmerBar(height: 16, width: 220),
          ] else if (benchmark.errorMessage != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: GlassDecorations.statusBanner(StatusBannerTone.error),
              child: Text(
                benchmark.errorMessage!,
                style: const TextStyle(fontSize: 13, color: AppColors.textMain),
              ),
            ),
          ] else if (suite == null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.glassSurfaceStrong,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.analytics_outlined,
                    size: 32,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.benchmarkEmptyPrompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...<Widget>[
            // 1) 3 Winner Cards
            _WinnerCardsRow(suite: suite, strings: strings),

            const SizedBox(height: 12),

            // 2) Auto-Generated Bilingual Analytical Takeaway
            Container(
              padding: const EdgeInsets.all(12),
              decoration: GlassDecorations.statusBanner(StatusBannerTone.ok),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      strings.buildBenchmarkTakeaway(suite),
                      style: const TextStyle(
                        fontSize: 12.8,
                        color: AppColors.textMain,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3) Interactive Comparison Table
            _ComparisonTable(
              suite: suite,
              strings: strings,
              activeAlgorithmId: solver.selectedAlgorithmId,
              onInspect: (algoId) {
                notifier.inspectResult(algoId);
                onInspectLoaded?.call();
              },
            ),

            const SizedBox(height: 14),

            // 4) Animated Horizontal Comparative Bar Chart
            BenchmarkBarChart(
              suite: suite,
              metric: benchmark.chartMetric,
              strings: strings,
              onMetricChanged: notifier.setChartMetric,
            ),
          ],
        ],
      ),
    );
  }
}

class _WinnerCardsRow extends StatelessWidget {
  const _WinnerCardsRow({
    required this.suite,
    required this.strings,
  });

  final BenchmarkSuiteResult suite;
  final AppStrings strings;

  SearchResult? _findResult(String? id) {
    if (id == null) return null;
    for (final r in suite.results) {
      if (r.algorithmId == id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shortestRes = _findResult(suite.winners.shortestPathId);
    final fastestRes = _findResult(suite.winners.fastestId);
    final fewestRes = _findResult(suite.winners.fewestNodesId);

    String algoLabel(String? id) {
      if (id == null) return '-';
      final algo = AlgorithmRegistry.tryById(id);
      return algo == null ? id : (strings.isAr ? algo.nameAr : algo.nameEn);
    }

    final cards = <Widget>[
      _WinnerTile(
        title: strings.winnerShortest,
        winnerName: algoLabel(suite.winners.shortestPathId),
        metricValue: shortestRes != null
            ? '${shortestRes.metrics.solutionCost} ${strings.movesUnit}'
            : '-',
        icon: Icons.route_rounded,
        accent: AppColors.cyan,
      ),
      _WinnerTile(
        title: strings.winnerFastest,
        winnerName: algoLabel(suite.winners.fastestId),
        metricValue: fastestRes != null
            ? '${fastestRes.metrics.executionTimeMs.toStringAsFixed(2)} ${strings.msUnit}'
            : '-',
        icon: Icons.bolt_rounded,
        accent: AppColors.sky,
      ),
      _WinnerTile(
        title: strings.winnerFewestNodes,
        winnerName: algoLabel(suite.winners.fewestNodesId),
        metricValue: fewestRes != null
            ? '${fewestRes.metrics.expandedNodes}'
            : '-',
        icon: Icons.hub_outlined,
        accent: AppColors.violet,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return Row(
            children: <Widget>[
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
              const SizedBox(width: 10),
              Expanded(child: cards[2]),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            cards[0],
            const SizedBox(height: 8),
            cards[1],
            const SizedBox(height: 8),
            cards[2],
          ],
        );
      },
    );
  }
}

class _WinnerTile extends StatelessWidget {
  const _WinnerTile({
    required this.title,
    required this.winnerName,
    required this.metricValue,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String winnerName;
  final String metricValue;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            winnerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metricValue,
            style: AppTypography.mono(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({
    required this.suite,
    required this.strings,
    required this.activeAlgorithmId,
    required this.onInspect,
  });

  final BenchmarkSuiteResult suite;
  final AppStrings strings;
  final String activeAlgorithmId;
  final ValueChanged<String> onInspect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowHeight: 42,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 50,
          horizontalMargin: 14,
          columnSpacing: 18,
          headingRowColor: const WidgetStatePropertyAll<Color>(
            Color(0xFF162033),
          ),
          columns: <DataColumn>[
            DataColumn(label: _headerText(strings.colAlgorithm)),
            DataColumn(label: _headerText(strings.colCategory)),
            DataColumn(label: _headerText(strings.colStatus)),
            DataColumn(label: _headerText(strings.colMoves), numeric: true),
            DataColumn(label: _headerText(strings.colExpanded), numeric: true),
            DataColumn(label: _headerText(strings.colMemory), numeric: true),
            DataColumn(label: _headerText(strings.colTime), numeric: true),
            DataColumn(label: _headerText(strings.colAction)),
          ],
          rows: suite.results.map((res) {
            final algo = AlgorithmRegistry.tryById(res.algorithmId);
            final catAccent = algo != null
                ? AppColors.categoryAccent(algo.category)
                : AppColors.cyan;
            final isHighlighted = res.algorithmId == activeAlgorithmId;

            final (String statusLabel, Color statusColor) = switch (res.status) {
              SearchStatus.solved => (strings.statusSolved, AppColors.cyan),
              SearchStatus.nodeCapReached => (
                  strings.statusNodeCap,
                  AppColors.amber,
                ),
              SearchStatus.failed => (strings.statusFailed, AppColors.coral),
            };

            return DataRow(
              selected: isHighlighted,
              color: WidgetStatePropertyAll<Color?>(
                isHighlighted
                    ? AppColors.cyan.withValues(alpha: 0.08)
                    : null,
              ),
              onSelectChanged: res.isSolved
                  ? (_) => onInspect(res.algorithmId)
                  : null,
              cells: <DataCell>[
                DataCell(
                  Text(
                    algo != null ? strings.algorithmName(algo) : res.algorithmId,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: catAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      algo != null ? strings.categoryName(algo.category) : '-',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: catAccent,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    res.isSolved ? '${res.metrics.solutionCost}' : '-',
                    style: AppTypography.mono(
                      fontSize: 12.5,
                      color: res.isSolved ? AppColors.cyan : AppColors.textDim,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${res.metrics.expandedNodes}',
                    style: AppTypography.mono(
                      fontSize: 12.5,
                      color: AppColors.violet,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${res.metrics.maxFrontierSize}',
                    style: AppTypography.mono(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    res.metrics.executionTimeMs.toStringAsFixed(2),
                    style: AppTypography.mono(
                      fontSize: 12.5,
                      color: AppColors.sky,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    tooltip: strings.loadTraceTooltip,
                    icon: Icon(
                      Icons.play_circle_outline_rounded,
                      color: res.isSolved ? AppColors.cyan : AppColors.textDim,
                      size: 20,
                    ),
                    onPressed: res.isSolved
                        ? () => onInspect(res.algorithmId)
                        : null,
                  ),
                ),
              ],
            );
          }).toList(growable: false),
        ),
      ),
    );
  }

  static Widget _headerText(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }
}
