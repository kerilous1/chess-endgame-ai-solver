/// ai_engine/heuristics.dart
/// =========================
/// Single built-in admissible heuristic function `endgameHeuristic(BoardState)`
/// estimating the minimum number of White turns remaining until checkmate.
///
/// Used automatically by informed search algorithms (such as A*) and the live
/// Heuristic Inspector without exposing heuristic selection to end users.
library;

import 'dart:math' as math;

import 'moves_engine.dart';
import 'search_models.dart';

/// Signature shared by heuristic evaluation functions `h(BoardState)`.
typedef HeuristicFn = double Function(BoardState state);

/// Mathematical formula string displayed in the Heuristic Inspector.
const String defaultHeuristicFormula = 'max(1, d_edge + 1, ⌈(d_kings - 1)/2⌉)';

/// Minimum distance in squares from [pos] to any edge of an `n×n` board.
int edgeDistance(GridPos pos, int boardSize) => [
      pos.row,
      boardSize - 1 - pos.row,
      pos.col,
      boardSize - 1 - pos.col,
    ].reduce(math.min);

/// Provably admissible lower bound on remaining White turns to checkmate:
///
/// - Returns `0.0` when [state] is already checkmate.
/// - For single-major endgames (`KRK` or `KQK`):
///   1. Checkmate requires the Black King on the board edge (`dEdge == 0`)
///      before White delivers mate -> at least `dEdge + 1` turns remain.
///   2. Checkmate also requires `dKings <= 2`, and the two kings close at most
///      2 squares per White+Black turn -> `ceil((dKings - 1) / 2)` turns.
/// - For multi-piece endgames (`KRRK`, `KRBK`, or 2+ attackers), center mates
///   are possible in 1 turn, so `1.0` is returned as a strict admissible floor.
double endgameHeuristic(BoardState state) {
  if (MovesEngine.isCheckmate(state)) return 0.0;

  final attackers = state.whiteAttackers;
  final isSingleMajor = attackers.length == 1 &&
      (attackers.first.type == PieceType.wr ||
          attackers.first.type == PieceType.wq);

  if (!isSingleMajor) return 1.0;

  final bk = state.blackKing.pos;
  final wk = state.whiteKing.pos;
  final dEdge = edgeDistance(bk, state.boardSize);
  final dKings = wk.chebyshevDistanceTo(bk);
  final kingBound = dKings >= 3 ? ((dKings - 1) / 2).ceil() : 1;

  return math.max(1, math.max(dEdge + 1, kingBound)).toDouble();
}
