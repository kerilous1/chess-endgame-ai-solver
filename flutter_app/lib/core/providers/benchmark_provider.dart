/// core/providers/benchmark_provider.dart
/// ========================================
/// Riverpod state controller for the Live Benchmark & Comparison Dashboard.
///
/// Runs every algorithm dynamically registered in [AlgorithmRegistry.all] on the
/// exact same board state and tracks chart display options.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_engine/ai_engine.dart';
import 'app_settings_provider.dart';
import 'board_setup_provider.dart';
import 'solver_provider.dart';

/// Metric plotted by the animated comparative horizontal bar chart.
enum BenchmarkChartMetric {
  expandedNodes,
  executionTimeMs,
  solutionCost,
}

/// Immutable state for the multi-algorithm benchmark dashboard.
class BenchmarkState {
  /// Creates a [BenchmarkState].
  const BenchmarkState({
    this.isRunning = false,
    this.suite,
    this.errorMessage,
    this.chartMetric = BenchmarkChartMetric.expandedNodes,
  });

  /// True while the benchmark comparison is running.
  final bool isRunning;

  /// Latest aggregated benchmark comparison results.
  final BenchmarkSuiteResult? suite;

  /// Localized error message if the board is illegal or execution fails.
  final String? errorMessage;

  /// Selected bar-chart comparison metric.
  final BenchmarkChartMetric chartMetric;

  /// Returns an updated copy of [BenchmarkState].
  BenchmarkState copyWith({
    bool? isRunning,
    BenchmarkSuiteResult? suite,
    bool clearSuite = false,
    String? errorMessage,
    bool clearError = false,
    BenchmarkChartMetric? chartMetric,
  }) {
    return BenchmarkState(
      isRunning: isRunning ?? this.isRunning,
      suite: clearSuite ? null : (suite ?? this.suite),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      chartMetric: chartMetric ?? this.chartMetric,
    );
  }
}

/// Executes batch comparisons across all registered algorithms.
class BenchmarkNotifier extends Notifier<BenchmarkState> {
  @override
  BenchmarkState build() => const BenchmarkState();

  /// Runs every algorithm in [AlgorithmRegistry.all] on the current board.
  Future<void> runCompareAll() async {
    if (state.isRunning) return;

    final boardState = ref.read(boardSetupProvider);
    final settings = ref.read(appSettingsProvider);
    final strings = ref.read(appStringsProvider);

    if (!boardState.validation.isValid) {
      final msg = (strings.isAr
              ? boardState.validation.messagesAr
              : boardState.validation.messagesEn)
          .first;
      state = state.copyWith(errorMessage: msg, clearSuite: true);
      return;
    }

    final startBoard = boardState.board;
    state = state.copyWith(isRunning: true, clearError: true);

    try {
      final suite = await AiEngineRunner.benchmarkAllInBackground(
        start: startBoard,
        maxNodes: settings.maxNodes,
        maxDepth: settings.maxDepth,
        blackPolicy: settings.blackPolicy,
      );

      // Ignore stale benchmark results if the board changed mid-run.
      if (ref.read(boardSetupProvider).board.stateKey != startBoard.stateKey) {
        return;
      }

      state = state.copyWith(
        isRunning: false,
        suite: suite,
        clearError: true,
      );
    } catch (err) {
      state = state.copyWith(isRunning: false, errorMessage: err.toString());
    }
  }

  /// Loads the solved trace for [algorithmId] from the latest benchmark onto the board.
  void inspectResult(String algorithmId) {
    final suite = state.suite;
    if (suite == null) return;
    final startBoard = ref.read(boardSetupProvider).board;
    for (final res in suite.results) {
      if (res.algorithmId == algorithmId) {
        ref
            .read(solverProvider.notifier)
            .loadExternalResult(res, startBoard);
        return;
      }
    }
  }

  /// Switches the comparative bar chart metric.
  void setChartMetric(BenchmarkChartMetric metric) {
    state = state.copyWith(chartMetric: metric);
  }

  /// Clears previous benchmark results (called on board edits).
  void clear() {
    if (state.suite == null && state.errorMessage == null && !state.isRunning) {
      return;
    }
    state = state.copyWith(
      isRunning: false,
      clearSuite: true,
      clearError: true,
    );
  }
}

/// Global benchmark suite provider.
final benchmarkProvider =
    NotifierProvider<BenchmarkNotifier, BenchmarkState>(BenchmarkNotifier.new);
