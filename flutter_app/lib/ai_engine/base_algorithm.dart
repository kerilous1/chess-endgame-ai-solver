/// ai_engine/base_algorithm.dart
/// =============================
/// Abstract `SearchAlgorithm` contract, metadata descriptors, and shared
/// telemetry / path-reconstruction helpers.
///
/// Any new search algorithm (e.g., Greedy BFS, UCS, IDA*, Hill Climbing)
/// extends [SearchAlgorithm] and implements a single method:
///   `SearchResult solve(BoardState start, {int maxNodes = 50000, ...})`
library;

import 'heuristics.dart';
import 'moves_engine.dart';
import 'search_models.dart';

/// Academic AI search family used to group algorithms in the selector UI.
enum AlgorithmCategory {
  uninformed('Uninformed Search', 'البحث غير الموجّه'),
  informed('Informed Search', 'البحث الموجّه (الاستدلالي)'),
  memoryBounded('Memory-Bounded', 'البحث محدود الذاكرة'),
  localSearch('Local Search', 'البحث المحلي');

  const AlgorithmCategory(this.labelEn, this.labelAr);

  final String labelEn;
  final String labelAr;
}

/// Visual explainer preset rendered by the Animated Algorithm Explainer card.
///
/// New algorithms simply pick the closest preset (or add a new value later)
/// without needing any changes to the core dashboard screens.
enum ExplainerAnimationType {
  bfsLevelWave,
  dfsBranchBacktrack,
  ucsCostWave,
  astarPriorityWave,
  greedyHeuristicWave,
  idaThresholdRing,
  hillClimbingCurve,
}

/// Tracks live search counters, stopwatch timing, and bounded trace samples.
class SearchTelemetry {
  /// Starts timing immediately upon creation.
  SearchTelemetry({this.maxTraceSamples = 60}) {
    _stopwatch.start();
  }

  final int maxTraceSamples;
  final Stopwatch _stopwatch = Stopwatch();

  int expandedNodes = 0;
  int generatedNodes = 0;
  int maxFrontierSize = 0;
  int _traceStride = 1;
  List<SearchTracePoint> _trace = <SearchTracePoint>[];

  /// Sampled progression snapshots (capped at [maxTraceSamples] points).
  List<SearchTracePoint> get trace => List<SearchTracePoint>.unmodifiable(_trace);

  /// Updates peak frontier / stack memory usage.
  void updateMaxFrontier(int frontierSize) {
    if (frontierSize > maxFrontierSize) {
      maxFrontierSize = frontierSize;
    }
  }

  /// Increments [expandedNodes] and records a downsampled trace point.
  void recordExpansion(
    BoardState state, {
    required int frontierSize,
    double g = 0.0,
    double h = 0.0,
    double? f,
  }) {
    expandedNodes++;
    updateMaxFrontier(frontierSize);

    if (expandedNodes <= 15 || expandedNodes % _traceStride == 0) {
      final bk = state.blackKingOrNull?.pos ?? const GridPos(0, 0);
      _trace.add(
        SearchTracePoint(
          iteration: _trace.length + 1,
          expandedNodes: expandedNodes,
          frontierSize: frontierSize,
          g: g,
          h: h,
          f: f ?? (g + h),
          focusSquare: bk,
        ),
      );
      if (_trace.length > maxTraceSamples) {
        final compacted = <SearchTracePoint>[];
        for (var i = 0; i < _trace.length; i += 2) {
          compacted.add(_trace[i]);
        }
        _trace = compacted;
        _traceStride *= 2;
      }
    }
  }

  /// Increments [generatedNodes] by [count].
  void recordGeneration([int count = 1]) {
    generatedNodes += count;
  }

  /// Stops the timer and returns a finalized [SearchMetrics] snapshot.
  SearchMetrics buildMetrics({
    required int solutionCost,
    required int solutionPlies,
  }) {
    _stopwatch.stop();
    final elapsedMs =
        double.parse((_stopwatch.elapsedMicroseconds / 1000.0).toStringAsFixed(3));
    return SearchMetrics(
      executionTimeMs: elapsedMs,
      expandedNodes: expandedNodes,
      generatedNodes: generatedNodes,
      maxFrontierSize: maxFrontierSize,
      solutionCost: solutionCost,
      solutionPlies: solutionPlies,
    );
  }
}

/// Abstract base class for every plug-and-play search algorithm in `lib/ai_engine/`.
abstract class SearchAlgorithm {
  /// Const constructor for subclasses.
  const SearchAlgorithm();

  /// Unique canonical identifier (e.g., `'bfs'`, `'dfs'`, `'astar'`).
  String get id;

  /// English display name.
  String get nameEn;

  /// Arabic display name.
  String get nameAr;

  /// Search category displayed in grouped pickers & benchmark tables.
  AlgorithmCategory get category;

  /// Underlying frontier data structure (English).
  String get dataStructureEn;

  /// Underlying frontier data structure (Arabic).
  String get dataStructureAr;

  /// Key evaluation formula (e.g., `'f(n) = g(n) + h(n)'`).
  String get formula;

  /// Theoretical worst-case time complexity (e.g., `'O(b^d)'`).
  String get timeComplexity;

  /// Theoretical worst-case space complexity (e.g., `'O(b^d)'`).
  String get spaceComplexity;

  /// True when guaranteed to find a solution if one exists.
  bool get isComplete;

  /// True when guaranteed to find a shortest-move solution.
  bool get isOptimal;

  /// Short 2–3 line academic summary (English).
  String get shortDescEn;

  /// Short 2–3 line academic summary (Arabic).
  String get shortDescAr;

  /// Miniature animation style used by the Animated Explainer card.
  ExplainerAnimationType get explainerAnimationType;

  /// Whether [solve] contains an active implementation (UI shows a badge if false).
  bool get isImplemented => true;

  /// Executes the search starting from [start] and returns a [SearchResult].
  ///
  /// Implementations should:
  /// 1. Validate [start] with [validateStart] first.
  /// 2. Track expansions/generations via [SearchTelemetry].
  /// 3. Stop cleanly and return [buildNodeCapResult] once `expandedNodes >= maxNodes`.
  SearchResult solve(
    BoardState start, {
    int maxNodes = 50000,
    int maxDepth = 40,
    BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
  });

  // -------------------------------------------------------------------------
  // Shared Helpers Available to Every Algorithm Subclass
  // -------------------------------------------------------------------------

  /// Validates [start] and returns a failure [SearchResult] if illegal, or `null` if valid.
  SearchResult? validateStart(BoardState start, SearchTelemetry telemetry) {
    final validation = MovesEngine.validatePosition(start);
    if (validation.isValid) return null;
    return buildFailedResult(
      telemetry,
      errorCode: validation.errorCodes.first,
      message: validation.messagesEn.join(' '),
    );
  }

  /// Reconstructs the ordered `MoveStep` sequence from a parent pointer map.
  List<MoveStep> reconstructPath({
    required BoardState goalState,
    required Map<BoardState, (BoardState, SuccessorTransition)> cameFrom,
    HeuristicFn heuristicFn = endgameHeuristic,
  }) {
    final reversed = <SuccessorTransition>[];
    var cursor = goalState;
    while (cameFrom.containsKey(cursor)) {
      final (parent, transition) = cameFrom[cursor]!;
      reversed.add(transition);
      cursor = parent;
    }
    return buildStepsFromTransitions(
      reversed.reversed.toList(growable: false),
      heuristicFn: heuristicFn,
    );
  }

  /// Converts a list of White+Black [transitions] into detailed playback frames.
  List<MoveStep> buildStepsFromTransitions(
    List<SuccessorTransition> transitions, {
    required HeuristicFn heuristicFn,
  }) {
    final steps = <MoveStep>[];
    var runningG = 0.0;

    for (final t in transitions) {
      runningG += t.stepCost;

      // 1) White move frame
      final mid = t.midState;
      final midCheck = MovesEngine.isCheck(mid);
      final midMate = MovesEngine.isCheckmate(mid);
      final midH = midMate ? 0.0 : heuristicFn(mid);
      steps.add(
        MoveStep(
          stepIndex: steps.length,
          actor: Actor.white,
          piece: t.whiteMove.piece,
          from: t.whiteMove.from,
          to: t.whiteMove.to,
          notation: t.whiteMove.toNotation(
            boardSize: mid.boardSize,
            isCheck: midCheck,
            isCheckmate: midMate,
          ),
          isCheck: midCheck,
          isCheckmate: midMate,
          g: runningG,
          h: midH,
          f: runningG + midH,
          snapshot: mid,
          tacticalTag: t.whiteTacticalTag,
          whiteAttackedSquares:
              MovesEngine.getAttackedSquares(mid, ignoreBlackKing: false),
          blackEscapeSquares: MovesEngine.getBlackKingMoves(mid)
              .map((m) => m.to)
              .toList(growable: false),
        ),
      );

      // 2) Black King response frame (omitted on immediate checkmate)
      final blackMove = t.blackMove;
      if (blackMove != null) {
        final next = t.nextState;
        final nextCheck = MovesEngine.isCheck(next);
        final nextMate = MovesEngine.isCheckmate(next);
        final nextH = nextMate ? 0.0 : heuristicFn(next);
        steps.add(
          MoveStep(
            stepIndex: steps.length,
            actor: Actor.black,
            piece: blackMove.piece,
            from: blackMove.from,
            to: blackMove.to,
            notation: blackMove.toNotation(
              boardSize: next.boardSize,
              isCheck: nextCheck,
              isCheckmate: nextMate,
            ),
            isCheck: nextCheck,
            isCheckmate: nextMate,
            g: runningG,
            h: nextH,
            f: runningG + nextH,
            snapshot: next,
            tacticalTag: t.blackTacticalTag ?? TacticalTag.sidestep,
            whiteAttackedSquares:
                MovesEngine.getAttackedSquares(next, ignoreBlackKing: false),
            blackEscapeSquares: MovesEngine.getBlackKingMoves(next)
                .map((m) => m.to)
                .toList(growable: false),
          ),
        );
      }
    }

    return List<MoveStep>.unmodifiable(steps);
  }

  /// Packages a successful checkmate [SearchResult].
  SearchResult buildSolvedResult(
    SearchTelemetry telemetry,
    List<MoveStep> steps,
  ) {
    final whiteTurns = steps.where((s) => s.actor == Actor.white).length;
    return SearchResult(
      status: SearchStatus.solved,
      algorithmId: id,
      path: steps,
      metrics: telemetry.buildMetrics(
        solutionCost: whiteTurns,
        solutionPlies: steps.length,
      ),
      trace: telemetry.trace,
    );
  }

  /// Packages an exhausted/failed [SearchResult].
  SearchResult buildFailedResult(
    SearchTelemetry telemetry, {
    String errorCode = 'NO_SOLUTION',
    String message = 'No checkmate sequence found.',
  }) {
    return SearchResult(
      status: SearchStatus.failed,
      algorithmId: id,
      path: const <MoveStep>[],
      metrics: telemetry.buildMetrics(solutionCost: 0, solutionPlies: 0),
      trace: telemetry.trace,
      errorCode: errorCode,
      message: message,
    );
  }

  /// Packages a [SearchStatus.nodeCapReached] result when `maxNodes` is hit.
  SearchResult buildNodeCapResult(SearchTelemetry telemetry) {
    return SearchResult(
      status: SearchStatus.nodeCapReached,
      algorithmId: id,
      path: const <MoveStep>[],
      metrics: telemetry.buildMetrics(solutionCost: 0, solutionPlies: 0),
      trace: telemetry.trace,
      errorCode: 'NODE_CAP_REACHED',
      message: '$nameEn reached the node expansion cap.',
    );
  }
}
