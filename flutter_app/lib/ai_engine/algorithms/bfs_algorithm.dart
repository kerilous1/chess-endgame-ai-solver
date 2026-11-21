/// ai_engine/algorithms/bfs_algorithm.dart
/// =========================================
/// Breadth-First Search (BFS) solver for 6×6 Chess Endgames.
///
/// Strategy:
/// - Explores states level-by-level using a FIFO [Queue].
/// - Guaranteed **Complete** and **Optimal** (fewest White moves to mate)
///   because every White+Black transition has uniform cost `1.0`.
library;

import 'dart:collection';

import '../base_algorithm.dart';
import '../heuristics.dart';
import '../moves_engine.dart';
import '../search_models.dart';

/// Breadth-First Search using a FIFO Queue.
class BfsAlgorithm extends SearchAlgorithm {
  /// Creates a [BfsAlgorithm] solver instance.
  const BfsAlgorithm();

  @override
  String get id => 'bfs';

  @override
  String get nameEn => 'Breadth-First Search (BFS)';

  @override
  String get nameAr => 'البحث بالعرض أولاً (BFS)';

  @override
  AlgorithmCategory get category => AlgorithmCategory.uninformed;

  @override
  String get dataStructureEn => 'FIFO Queue (dart:collection Queue)';

  @override
  String get dataStructureAr => 'طابور (FIFO Queue)';

  @override
  String get formula => 'level(n) = depth(n)';

  @override
  String get timeComplexity => 'O(b^d)';

  @override
  String get spaceComplexity => 'O(b^d)';

  @override
  bool get isComplete => true;

  @override
  bool get isOptimal => true;

  @override
  String get shortDescEn =>
      'Explores all legal responses level-by-level in a FIFO queue. '
      'Guaranteed to find the shortest checkmate sequence, at the cost of higher memory.';

  @override
  String get shortDescAr =>
      'يستكشف النقلات الممكنة مستوىً بعد مستوى عبر طابور FIFO. '
      'يضمن إيجاد أقصر كش مات ممكن، مقابل استهلاك أعلى للذاكرة.';

  @override
  ExplainerAnimationType get explainerAnimationType =>
      ExplainerAnimationType.bfsLevelWave;

  @override
  SearchResult solve(
    BoardState start, {
    int maxNodes = 50000,
    int maxDepth = 40,
    BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
  }) {
    final telemetry = SearchTelemetry();
    final invalid = validateStart(start, telemetry);
    if (invalid != null) return invalid;

    // === YOUR SEARCH LOGIC HERE ===
    final queue = Queue<(BoardState, int)>()..addLast((start, 0));
    final visited = <BoardState>{start};
    final cameFrom = <BoardState, (BoardState, SuccessorTransition)>{};

    while (queue.isNotEmpty) {
      if (telemetry.expandedNodes >= maxNodes) {
        return buildNodeCapResult(telemetry);
      }

      // Pop the oldest state (FIFO) and record telemetry.
      final (current, depth) = queue.removeFirst();
      telemetry.recordExpansion(
        current,
        frontierSize: queue.length,
        g: depth.toDouble(),
        h: endgameHeuristic(current),
      );

      if (MovesEngine.isCheckmate(current)) {
        final steps = reconstructPath(
          goalState: current,
          cameFrom: cameFrom,
        );
        return buildSolvedResult(telemetry, steps);
      }

      if (depth >= maxDepth) continue;

      // Generate all legal White moves + deterministic Black King replies.
      for (final edge in MovesEngine.getSuccessors(
        current,
        blackPolicy: blackPolicy,
      )) {
        final next = edge.nextState;

        // Early goal check: stop immediately when a White move delivers mate.
        if (MovesEngine.isCheckmate(next)) {
          cameFrom[next] = (current, edge);
          telemetry.recordGeneration();
          final steps = reconstructPath(
            goalState: next,
            cameFrom: cameFrom,
          );
          return buildSolvedResult(telemetry, steps);
        }

        if (visited.add(next)) {
          cameFrom[next] = (current, edge);
          queue.addLast((next, depth + 1));
          telemetry.recordGeneration();
        }
      }
    }

    return buildFailedResult(
      telemetry,
      message: 'BFS explored all reachable states without finding checkmate.',
    );
  }
}
