/// ai_engine/algorithms/dfs_algorithm.dart
/// =========================================
/// Depth-First Search (DFS) solver for 6×6 Chess Endgames.
///
/// Strategy:
/// - Explores deep down one branch first using a LIFO stack (`List`).
/// - Uses a depth limit (`depthCap`) and `visited` set so chess cycles do not
///   cause infinite loops. Low memory footprint O(b · m), not optimal.
library;

import '../base_algorithm.dart';
import '../heuristics.dart';
import '../moves_engine.dart';
import '../search_models.dart';

/// Depth-First Search using a LIFO Stack with cycle & depth-limit protection.
class DfsAlgorithm extends SearchAlgorithm {
  /// Creates a [DfsAlgorithm] solver instance.
  const DfsAlgorithm();

  @override
  String get id => 'dfs';

  @override
  String get nameEn => 'Depth-First Search (DFS)';

  @override
  String get nameAr => 'البحث بالعمق أولاً (DFS)';

  @override
  AlgorithmCategory get category => AlgorithmCategory.uninformed;

  @override
  String get dataStructureEn => 'LIFO Stack (Dart List)';

  @override
  String get dataStructureAr => 'مكدس (LIFO Stack)';

  @override
  String get formula => 'LIFO expansion ≤ depthCap';

  @override
  String get timeComplexity => 'O(b^m)';

  @override
  String get spaceComplexity => 'O(b · m)';

  @override
  bool get isComplete => false;

  @override
  bool get isOptimal => false;

  @override
  String get shortDescEn =>
      'Dives deep along one move sequence via a LIFO stack with a depth bound. '
      'Uses minimal memory, though the first mate found is usually non-optimal.';

  @override
  String get shortDescAr =>
      'يتعمّق في مسار واحد حتى حد العمق عبر مكدس LIFO ثم يتراجع. '
      'استهلاكه للذاكرة منخفض جداً لكنه لا يضمن أقصر مسار.';

  @override
  ExplainerAnimationType get explainerAnimationType =>
      ExplainerAnimationType.dfsBranchBacktrack;

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
    // Cap DFS branching depth to avoid ultra-long non-progressing detours.
    final depthCap = maxDepth > 16 ? 16 : maxDepth;
    final stack = <(BoardState, int)>[(start, 0)];
    final visited = <BoardState>{start};
    final cameFrom = <BoardState, (BoardState, SuccessorTransition)>{};

    while (stack.isNotEmpty) {
      if (telemetry.expandedNodes >= maxNodes) {
        return buildNodeCapResult(telemetry);
      }

      // Pop the most recently pushed state (LIFO).
      final (current, depth) = stack.removeLast();
      telemetry.recordExpansion(
        current,
        frontierSize: stack.length,
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

      if (depth >= depthCap) continue;

      final successors = MovesEngine.getSuccessors(
        current,
        blackPolicy: blackPolicy,
      );

      // Push in reverse order so the first generated move is popped next.
      for (var i = successors.length - 1; i >= 0; i--) {
        final edge = successors[i];
        final next = edge.nextState;

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
          stack.add((next, depth + 1));
          telemetry.recordGeneration();
        }
      }
    }

    return buildFailedResult(
      telemetry,
      message: 'DFS reached depth limit ($depthCap) without finding checkmate.',
    );
  }
}
