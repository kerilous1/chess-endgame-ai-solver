/// ai_engine/algorithms/astar_algorithm.dart
/// ===========================================
/// A* Informed Search solver for 6×6 Chess Endgames.
///
/// Strategy:
/// - Orders the frontier in a binary [MinHeap] by `f(n) = g(n) + h(n)`.
/// - Breaks equal-`f` ties toward smaller `h(n)` (states closer to checkmate).
/// - Tests for checkmate when popping from the heap to preserve optimality
///   when paired with an admissible heuristic (`admissibleEndgameH`).
library;

import '../base_algorithm.dart';
import '../heuristics.dart';
import '../moves_engine.dart';
import '../search_models.dart';

/// Internal priority-queue entry for A*.
class _AStarNode {
  const _AStarNode({
    required this.state,
    required this.g,
    required this.h,
    required this.order,
  });

  final BoardState state;
  final double g;
  final double h;
  final int order;

  double get f => g + h;
}

/// A* Search using a Min-Heap ordered by `f(n) = g(n) + h(n)`.
class AStarAlgorithm extends SearchAlgorithm {
  /// Creates an [AStarAlgorithm] solver instance.
  const AStarAlgorithm();

  @override
  String get id => 'astar';

  @override
  String get nameEn => 'A* Search';

  @override
  String get nameAr => 'خوارزمية البحث الموجّه A*';

  @override
  AlgorithmCategory get category => AlgorithmCategory.informed;

  @override
  String get dataStructureEn => 'Min-Heap Priority Queue';

  @override
  String get dataStructureAr => 'رتل أولوية (Min-Heap)';

  @override
  String get formula => 'f(n) = g(n) + h(n)';

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
      'Combines path cost g(n) with heuristic estimate h(n) inside a min-heap. '
      'Expands far fewer nodes than BFS while staying optimal when h(n) is admissible.';

  @override
  String get shortDescAr =>
      'تجمع بين التكلفة الفعلية g(n) والتقدير الاستدلالي h(n) في رتل أولوية. '
      'تفتح عقداً أقل بكثير من BFS مع ضمان الحل الأمثل عند استخدام دالة مقبولة.';

  @override
  ExplainerAnimationType get explainerAnimationType =>
      ExplainerAnimationType.astarPriorityWave;

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
    final openHeap = MinHeap<_AStarNode>((a, b) {
      final byF = a.f.compareTo(b.f);
      if (byF != 0) return byF;
      final byH = a.h.compareTo(b.h);
      if (byH != 0) return byH;
      return a.order.compareTo(b.order);
    });

    var sequence = 0;
    final h0 = endgameHeuristic(start);
    openHeap.add(_AStarNode(state: start, g: 0.0, h: h0, order: sequence++));

    final bestG = <BoardState, double>{start: 0.0};
    final cameFrom = <BoardState, (BoardState, SuccessorTransition)>{};

    while (openHeap.isNotEmpty) {
      if (telemetry.expandedNodes >= maxNodes) {
        return buildNodeCapResult(telemetry);
      }

      final currentNode = openHeap.removeFirst();
      final current = currentNode.state;

      // Skip outdated duplicate heap entries superseded by a cheaper path.
      if (currentNode.g > (bestG[current] ?? double.infinity)) continue;

      telemetry.recordExpansion(
        current,
        frontierSize: openHeap.length,
        g: currentNode.g,
        h: currentNode.h,
        f: currentNode.f,
      );

      // Goal test on pop guarantees optimality when h(n) is admissible.
      if (MovesEngine.isCheckmate(current)) {
        final steps = reconstructPath(
          goalState: current,
          cameFrom: cameFrom,
        );
        return buildSolvedResult(telemetry, steps);
      }

      if (currentNode.g >= maxDepth) continue;

      for (final edge in MovesEngine.getSuccessors(
        current,
        blackPolicy: blackPolicy,
      )) {
        final next = edge.nextState;
        final newG = currentNode.g + edge.stepCost;

        if (newG < (bestG[next] ?? double.infinity)) {
          bestG[next] = newG;
          cameFrom[next] = (current, edge);
          final nextH = MovesEngine.isCheckmate(next) ? 0.0 : endgameHeuristic(next);
          openHeap.add(
            _AStarNode(state: next, g: newG, h: nextH, order: sequence++),
          );
          telemetry.recordGeneration();
        }
      }
    }

    return buildFailedResult(
      telemetry,
      message: 'A* exhausted all reachable states without finding checkmate.',
    );
  }
}
