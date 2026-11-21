/// ai_engine/isolate_runner.dart
/// =============================
/// Executes single search runs and multi-algorithm benchmarks in background
/// Dart Isolates (`Isolate.run`) so animations stay responsive on all devices.
library;

import 'dart:isolate';

import 'algorithm_registry.dart';
import 'search_models.dart';

/// Compile-time check for Flutter Web (where `dart:isolate` is unsupported).
const bool _isWeb = identical(0, 0.0);

/// IDs of top-performing algorithms across solved benchmark runs.
class BenchmarkWinners {
  /// Creates a [BenchmarkWinners] summary.
  const BenchmarkWinners({
    this.shortestPathId,
    this.fastestId,
    this.fewestNodesId,
  });

  /// Algorithm that achieved the fewest White moves (`solutionCost`).
  final String? shortestPathId;

  /// Algorithm with the shortest wall-clock execution time (`executionTimeMs`).
  final String? fastestId;

  /// Algorithm that expanded the fewest search nodes (`expandedNodes`).
  final String? fewestNodesId;
}

/// Complete output of running every registered algorithm on the same board.
class BenchmarkSuiteResult {
  /// Creates an immutable [BenchmarkSuiteResult].
  const BenchmarkSuiteResult({
    required this.results,
    required this.winners,
    required this.totalTimeMs,
  });

  /// Individual results ordered identically to [AlgorithmRegistry.all].
  final List<SearchResult> results;

  /// Highlighted category winners among solved runs.
  final BenchmarkWinners winners;

  /// Total elapsed time for the entire benchmark suite in milliseconds.
  final double totalTimeMs;
}

/// Asynchronous dispatcher wrapping `Isolate.run` for single & batch searches.
abstract final class AiEngineRunner {
  /// Executes a single search algorithm off the UI thread via `Isolate.run`.
  static Future<SearchResult> solveInBackground({
    required String algorithmId,
    required BoardState start,
    int maxNodes = 50000,
    int maxDepth = 40,
    BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
  }) {
    if (_isWeb) {
      return Future<SearchResult>.microtask(
        () => _solveSync(
          algorithmId: algorithmId,
          start: start,
          maxNodes: maxNodes,
          maxDepth: maxDepth,
          blackPolicy: blackPolicy,
        ),
      );
    }

    return Isolate.run(
      () => _solveSync(
        algorithmId: algorithmId,
        start: start,
        maxNodes: maxNodes,
        maxDepth: maxDepth,
        blackPolicy: blackPolicy,
      ),
    );
  }

  /// Runs every algorithm in [AlgorithmRegistry.all] (or [algorithmIds]) on
  /// [start] inside a single background `Isolate.run` call.
  static Future<BenchmarkSuiteResult> benchmarkAllInBackground({
    required BoardState start,
    List<String>? algorithmIds,
    int maxNodes = 50000,
    int maxDepth = 40,
    BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
  }) {
    if (_isWeb) {
      return Future<BenchmarkSuiteResult>.microtask(
        () => _benchmarkSync(
          start: start,
          algorithmIds: algorithmIds,
          maxNodes: maxNodes,
          maxDepth: maxDepth,
          blackPolicy: blackPolicy,
        ),
      );
    }

    return Isolate.run(
      () => _benchmarkSync(
        start: start,
        algorithmIds: algorithmIds,
        maxNodes: maxNodes,
        maxDepth: maxDepth,
        blackPolicy: blackPolicy,
      ),
    );
  }

  static SearchResult _solveSync({
    required String algorithmId,
    required BoardState start,
    required int maxNodes,
    required int maxDepth,
    required BlackPolicy blackPolicy,
  }) {
    final algorithm = AlgorithmRegistry.byId(algorithmId);
    return algorithm.solve(
      start,
      maxNodes: maxNodes,
      maxDepth: maxDepth,
      blackPolicy: blackPolicy,
    );
  }

  static BenchmarkSuiteResult _benchmarkSync({
    required BoardState start,
    required List<String>? algorithmIds,
    required int maxNodes,
    required int maxDepth,
    required BlackPolicy blackPolicy,
  }) {
    final targetIds = algorithmIds ??
        AlgorithmRegistry.all.map((a) => a.id).toList(growable: false);

    final totalWatch = Stopwatch()..start();
    final results = <SearchResult>[];

    for (final algoId in targetIds) {
      final algorithm = AlgorithmRegistry.byId(algoId);
      results.add(
        algorithm.solve(
          start,
          maxNodes: maxNodes,
          maxDepth: maxDepth,
          blackPolicy: blackPolicy,
        ),
      );
    }

    totalWatch.stop();
    final solved = results.where((r) => r.isSolved).toList(growable: false);

    String? shortestId;
    String? fastestId;
    String? fewestNodesId;

    if (solved.isNotEmpty) {
      final byCost = List<SearchResult>.of(solved)
        ..sort((a, b) {
          final byMoves =
              a.metrics.solutionCost.compareTo(b.metrics.solutionCost);
          if (byMoves != 0) return byMoves;
          return a.metrics.executionTimeMs
              .compareTo(b.metrics.executionTimeMs);
        });
      shortestId = byCost.first.algorithmId;

      final byTime = List<SearchResult>.of(solved)
        ..sort(
          (a, b) =>
              a.metrics.executionTimeMs.compareTo(b.metrics.executionTimeMs),
        );
      fastestId = byTime.first.algorithmId;

      final byNodes = List<SearchResult>.of(solved)
        ..sort((a, b) {
          final byExp =
              a.metrics.expandedNodes.compareTo(b.metrics.expandedNodes);
          if (byExp != 0) return byExp;
          return a.metrics.executionTimeMs
              .compareTo(b.metrics.executionTimeMs);
        });
      fewestNodesId = byNodes.first.algorithmId;
    }

    return BenchmarkSuiteResult(
      results: List<SearchResult>.unmodifiable(results),
      winners: BenchmarkWinners(
        shortestPathId: shortestId,
        fastestId: fastestId,
        fewestNodesId: fewestNodesId,
      ),
      totalTimeMs: double.parse(
        (totalWatch.elapsedMicroseconds / 1000.0).toStringAsFixed(3),
      ),
    );
  }
}
