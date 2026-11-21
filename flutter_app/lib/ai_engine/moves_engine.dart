/// ai_engine/moves_engine.dart
/// ===========================
/// The single source of truth for 6×6 multi-endgame chess rules, move
/// generation, attack maps, legality validation, and deterministic Black King
/// opponent policies (`KRK`, `KQK`, `KRRK`, `KRBK`, and `Custom`).
///
/// Design Goal: Keep every chess rule crystal-clear, well-commented, and
/// accessible through clean top-level functions (`isLegalPosition`,
/// `getWhiteMoves`, `getBlackKingMoves`, `getSuccessors`, `isCheck`,
/// `isCheckmate`, `getAttackedSquares`) as well as [MovesEngine].
library;

import 'dart:math' as math;

import 'search_models.dart';

/// All 8 king / queen directions `(dRow, dCol)`.
const List<(int, int)> _allDirs = <(int, int)>[
  (-1, -1),
  (-1, 0),
  (-1, 1),
  (0, -1),
  (0, 1),
  (1, -1),
  (1, 0),
  (1, 1),
];

/// 4 orthogonal rook / queen directions.
const List<(int, int)> _orthogonalDirs = <(int, int)>[
  (-1, 0),
  (1, 0),
  (0, -1),
  (0, 1),
];

/// 4 diagonal bishop / queen directions.
const List<(int, int)> _diagonalDirs = <(int, int)>[
  (-1, -1),
  (-1, 1),
  (1, -1),
  (1, 1),
];

/// Capture priority when the Black King can take an undefended White piece.
const Map<PieceType, int> _capturePriority = <PieceType, int>{
  PieceType.wq: 3,
  PieceType.wr: 2,
  PieceType.wb: 1,
};

// ---------------------------------------------------------------------------
// Clean Top-Level Convenience Functions (Ergonomic API for Algorithms & UI)
// ---------------------------------------------------------------------------

/// Validates whether [state] satisfies all chess placement & legality rules.
bool isLegalPosition(BoardState state) => MovesEngine.isLegalPosition(state);

/// Returns detailed bilingual legality validation feedback for [state].
PositionValidation validatePosition(BoardState state) =>
    MovesEngine.validatePosition(state);

/// Returns all squares attacked or defended by White pieces in [state].
///
/// Set [ignoreBlackKing] to `true` (x-ray mode) when evaluating legal Black King
/// escapes so the Black King cannot step backward along an attacker's check ray.
Set<GridPos> getAttackedSquares(
  BoardState state, {
  bool ignoreBlackKing = false,
}) =>
    MovesEngine.getAttackedSquares(state, ignoreBlackKing: ignoreBlackKing);

/// Returns `true` if the Black King stands on a square attacked by White.
bool isCheck(BoardState state) => MovesEngine.isCheck(state);

/// Returns `true` if the Black King is in check and has zero legal escapes.
bool isCheckmate(BoardState state) => MovesEngine.isCheckmate(state);

/// Returns `true` if the Black King is NOT in check yet has zero legal moves.
bool isStalemate(BoardState state) => MovesEngine.isStalemate(state);

/// Generates every legal move for White pieces in [state].
List<ChessMove> getWhiteMoves(BoardState state) =>
    MovesEngine.getWhiteMoves(state);

/// Generates every legal escape (or capture) move for the Black King in [state].
List<ChessMove> getBlackKingMoves(BoardState state) =>
    MovesEngine.getBlackKingMoves(state);

/// Generates full White+Black successor edges from [state].
List<SuccessorTransition> getSuccessors(
  BoardState state, {
  BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
  bool pruneDeadEnds = true,
}) =>
    MovesEngine.getSuccessors(
      state,
      blackPolicy: blackPolicy,
      pruneDeadEnds: pruneDeadEnds,
    );

// ---------------------------------------------------------------------------
// Core Multi-Endgame Rules Engine
// ---------------------------------------------------------------------------

/// Stateless rules engine implementing 6×6 chess endgame logic.
abstract final class MovesEngine {
  /// Computes squares attacked by a single White [piece] in [state].
  ///
  /// Friendly White pieces are included in the returned set (they are defended
  /// against Black King capture!) and block sliding rays behind them.
  static Set<GridPos> getPieceAttackedSquares(
    BoardState state,
    Piece piece, {
    bool ignoreBlackKing = false,
  }) {
    if (!piece.type.isWhite) return const <GridPos>{};

    final n = state.boardSize;
    final attacked = <GridPos>{};

    if (piece.type == PieceType.wk) {
      for (final (dr, dc) in _allDirs) {
        final nr = piece.row + dr;
        final nc = piece.col + dc;
        if (state.inBounds(nr, nc)) {
          attacked.add(GridPos(nr, nc));
        }
      }
      return attacked;
    }

    final rays = switch (piece.type) {
      PieceType.wr => _orthogonalDirs,
      PieceType.wb => _diagonalDirs,
      PieceType.wq => _allDirs,
      _ => const <(int, int)>[],
    };

    for (final (dr, dc) in rays) {
      var nr = piece.row + dr;
      var nc = piece.col + dc;
      while (nr >= 0 && nr < n && nc >= 0 && nc < n) {
        attacked.add(GridPos(nr, nc));
        final occupant = state.pieceAt(nr, nc);
        if (occupant != null) {
          if (occupant.type.isWhite) {
            // Friendly piece is protected (added above) and stops the ray.
            break;
          }
          if (!ignoreBlackKing) {
            // Literal check visibility stops at the Black King.
            break;
          }
        }
        nr += dr;
        nc += dc;
      }
    }
    return attacked;
  }

  /// Computes the union of squares attacked/defended by all White pieces.
  static Set<GridPos> getAttackedSquares(
    BoardState state, {
    bool ignoreBlackKing = false,
  }) {
    final attacked = <GridPos>{};
    for (final piece in state.whitePieces) {
      attacked.addAll(
        getPieceAttackedSquares(
          state,
          piece,
          ignoreBlackKing: ignoreBlackKing,
        ),
      );
    }
    return attacked;
  }

  /// Returns `true` when the Black King is currently under attack by White.
  static bool isCheck(BoardState state) {
    final bk = state.blackKingOrNull;
    if (bk == null) return false;
    return getAttackedSquares(state, ignoreBlackKing: false).contains(bk.pos);
  }

  /// Returns `true` when the Black King is in check with zero legal escapes.
  static bool isCheckmate(BoardState state) =>
      isCheck(state) && getBlackKingMoves(state).isEmpty;

  /// Returns `true` when the Black King is NOT in check yet has zero legal moves.
  static bool isStalemate(BoardState state) =>
      !isCheck(state) && getBlackKingMoves(state).isEmpty;

  /// Verifies whether White retains enough pieces to force checkmate:
  /// at least 1 Queen, OR at least 1 Rook, OR at least 2 opposite-color Bishops.
  static bool hasSufficientMatingMaterial(BoardState state) {
    final bishops = <Piece>[];
    for (final piece in state.whitePieces) {
      if (piece.type == PieceType.wq || piece.type == PieceType.wr) {
        return true;
      }
      if (piece.type == PieceType.wb) {
        bishops.add(piece);
      }
    }
    if (bishops.length >= 2) {
      final colors = bishops.map((b) => (b.row + b.col) % 2).toSet();
      if (colors.length == 2) return true;
    }
    return false;
  }

  /// Returns `true` when [state] is completely legal for White to move first.
  static bool isLegalPosition(BoardState state) =>
      validatePosition(state).isValid;

  /// Performs full legality validation with bilingual AR/EN error reporting.
  static PositionValidation validatePosition(BoardState state) {
    final codes = <String>[];
    final en = <String>[];
    final ar = <String>[];

    final n = state.boardSize;
    final seen = <GridPos>{};
    var outOfBounds = false;
    var overlap = false;
    final whiteKings = <Piece>[];
    final blackKings = <Piece>[];

    for (final piece in state.pieces) {
      if (piece.row < 0 || piece.row >= n || piece.col < 0 || piece.col >= n) {
        outOfBounds = true;
      }
      final pos = piece.pos;
      if (!seen.add(pos)) {
        overlap = true;
      }
      if (piece.type == PieceType.wk) whiteKings.add(piece);
      if (piece.type == PieceType.bk) blackKings.add(piece);
    }

    if (outOfBounds) {
      codes.add('OUT_OF_BOUNDS');
      en.add('One or more pieces lie outside the ${n}x$n board.');
      ar.add('توجد قطعة واحدة أو أكثر خارج حدود الرقعة $n×$n.');
    }

    if (overlap) {
      codes.add('OVERLAPPING_PIECES');
      en.add('Two pieces cannot occupy the same square.');
      ar.add('لا يمكن لقطعتين الوقوف على نفس المربع.');
    }

    if (whiteKings.isEmpty) {
      codes.add('MISSING_WHITE_KING');
      en.add('A White King is required.');
      ar.add('يجب وضع الملك الأبيض على الرقعة.');
    } else if (whiteKings.length > 1) {
      codes.add('DUPLICATE_WHITE_KING');
      en.add('Only one White King is allowed.');
      ar.add('يُسمح بملك أبيض واحد فقط.');
    }

    if (blackKings.isEmpty) {
      codes.add('MISSING_BLACK_KING');
      en.add('A Black King is required.');
      ar.add('يجب وضع الملك الأسود على الرقعة.');
    } else if (blackKings.length > 1) {
      codes.add('DUPLICATE_BLACK_KING');
      en.add('Only one Black King is allowed.');
      ar.add('يُسمح بملك أسود واحد فقط.');
    }

    // Spatial & check rules only apply when basic placement is coherent.
    if (codes.isEmpty) {
      final wk = whiteKings.first;
      final bk = blackKings.first;

      if (wk.pos.chebyshevDistanceTo(bk.pos) <= 1) {
        codes.add('ADJACENT_KINGS');
        en.add('White King and Black King cannot touch or stand adjacent.');
        ar.add('لا يجوز أن يتلامس الملك الأبيض والملك الأسود.');
      }

      if (isCheck(state)) {
        codes.add('BLACK_KING_IN_CHECK');
        en.add('Black King cannot start in check while White moves first.');
        ar.add('لا يمكن أن يبدأ الملك الأسود في حالة كش لأن الأبيض يلعب أولاً.');
      }

      if (!hasSufficientMatingMaterial(state)) {
        codes.add('INSUFFICIENT_MATERIAL');
        en.add('White lacks sufficient material to force checkmate.');
        ar.add('القطع البيضاء الحالية غير كافية لتنفيذ كش مات.');
      }
    }

    return PositionValidation(
      isValid: codes.isEmpty,
      errorCodes: List<String>.unmodifiable(codes),
      messagesEn: List<String>.unmodifiable(en),
      messagesAr: List<String>.unmodifiable(ar),
    );
  }

  /// Generates all legal escape / capture moves for the Black King.
  static List<ChessMove> getBlackKingMoves(BoardState state) {
    final bk = state.blackKingOrNull;
    if (bk == null) return const <ChessMove>[];

    // Use x-ray through BK so it cannot retreat along an active check ray.
    final danger = getAttackedSquares(state, ignoreBlackKing: true);
    final moves = <ChessMove>[];

    for (final (dr, dc) in _allDirs) {
      final nr = bk.row + dr;
      final nc = bk.col + dc;
      if (!state.inBounds(nr, nc)) continue;
      final target = GridPos(nr, nc);
      if (danger.contains(target)) continue;

      final occupant = state.pieceAt(nr, nc);
      if (occupant != null && occupant.type == PieceType.wk) continue;

      moves.add(
        ChessMove(
          actor: Actor.black,
          piece: PieceType.bk,
          from: bk.pos,
          to: target,
          capturedPiece: occupant?.type,
        ),
      );
    }
    return moves;
  }

  /// Generates all legal moves for every White piece on the board.
  static List<ChessMove> getWhiteMoves(BoardState state) {
    final bk = state.blackKingOrNull;
    if (bk == null) return const <ChessMove>[];

    final moves = <ChessMove>[];
    for (final piece in state.whitePieces) {
      if (piece.type == PieceType.wk) {
        for (final (dr, dc) in _allDirs) {
          final nr = piece.row + dr;
          final nc = piece.col + dc;
          if (!state.inBounds(nr, nc)) continue;
          if (state.pieceAt(nr, nc) != null) continue;
          final target = GridPos(nr, nc);
          // Kings can never step adjacent to each other.
          if (target.chebyshevDistanceTo(bk.pos) <= 1) continue;
          moves.add(
            ChessMove(
              actor: Actor.white,
              piece: PieceType.wk,
              from: piece.pos,
              to: target,
            ),
          );
        }
        continue;
      }

      final rays = switch (piece.type) {
        PieceType.wr => _orthogonalDirs,
        PieceType.wb => _diagonalDirs,
        PieceType.wq => _allDirs,
        _ => const <(int, int)>[],
      };

      for (final (dr, dc) in rays) {
        var nr = piece.row + dr;
        var nc = piece.col + dc;
        while (state.inBounds(nr, nc)) {
          // Any occupied square (friendly piece or Black King) blocks sliding.
          if (state.pieceAt(nr, nc) != null) break;
          moves.add(
            ChessMove(
              actor: Actor.white,
              piece: piece.type,
              from: piece.pos,
              to: GridPos(nr, nc),
            ),
          );
          nr += dr;
          nc += dc;
        }
      }
    }
    return moves;
  }

  /// Returns a new [BoardState] after applying [move] and flipping the turn.
  static BoardState applyMove(BoardState state, ChessMove move) {
    final updated = <Piece>[];
    var movedFound = false;

    for (final p in state.pieces) {
      if (p.type == move.piece &&
          p.row == move.from.row &&
          p.col == move.from.col) {
        movedFound = true;
        continue;
      }
      if (p.row == move.to.row && p.col == move.to.col) {
        // Captured undefended White piece when Black King moves onto it.
        continue;
      }
      updated.add(p);
    }

    if (!movedFound) {
      throw StateError(
        'Cannot apply move ${move.piece.code} ${move.from} -> ${move.to}: '
        'source piece not found.',
      );
    }

    updated.add(Piece(move.piece, move.to.row, move.to.col));
    return state.copyWith(pieces: updated, turn: move.actor.opponent);
  }

  /// Selects Black's deterministic defensive response according to [policy].
  static ChessMove? chooseBlackKingMove(
    BoardState state, {
    BlackPolicy policy = BlackPolicy.centerSeeking,
  }) {
    final moves = getBlackKingMoves(state);
    if (moves.isEmpty) return null;

    // 1) Always capture undefended material first (highest value piece).
    final captures =
        moves.where((m) => m.capturedPiece != null).toList(growable: false);
    if (captures.isNotEmpty) {
      captures.sort((a, b) {
        final pa = _capturePriority[a.capturedPiece] ?? 0;
        final pb = _capturePriority[b.capturedPiece] ?? 0;
        if (pa != pb) return pb.compareTo(pa);
        return a.to
            .squareIndex(boardSize: state.boardSize)
            .compareTo(b.to.squareIndex(boardSize: state.boardSize));
      });
      return captures.first;
    }

    final n = state.boardSize;
    final center = (n - 1) / 2.0;

    if (policy == BlackPolicy.centerSeeking) {
      // Exact match to `krk_6_6.html`: minimize squared Euclidean center dist.
      final sorted = List<ChessMove>.of(moves)
        ..sort((a, b) {
          final da = (a.to.row - center) * (a.to.row - center) +
              (a.to.col - center) * (a.to.col - center);
          final db = (b.to.row - center) * (b.to.row - center) +
              (b.to.col - center) * (b.to.col - center);
          final byDist = da.compareTo(db);
          if (byDist != 0) return byDist;
          return a.to
              .squareIndex(boardSize: n)
              .compareTo(b.to.squareIndex(boardSize: n));
        });
      return sorted.first;
    }

    // Evasive policy: maximize post-move escape squares and stay away from edges.
    final wk = state.whiteKing;
    double scoreMove(ChessMove move) {
      final after = applyMove(state, move);
      final mobility = getBlackKingMoves(after).length;
      final centerDist =
          (move.to.row - center).abs() + (move.to.col - center).abs();
      final edgeDist = [
        move.to.row,
        n - 1 - move.to.row,
        move.to.col,
        n - 1 - move.to.col,
      ].reduce(math.min);
      final kingDist = move.to.chebyshevDistanceTo(wk.pos);
      return (mobility * 3.0) -
          (centerDist * 2.5) +
          (edgeDist * 2.0) +
          (kingDist * 0.4);
    }

    ChessMove best = moves.first;
    var bestScore = scoreMove(best);
    for (var i = 1; i < moves.length; i++) {
      final candidate = moves[i];
      final score = scoreMove(candidate);
      if (score > bestScore ||
          (score == bestScore &&
              candidate.to.squareIndex(boardSize: n) <
                  best.to.squareIndex(boardSize: n))) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  /// Expands all legal White moves and pairs each non-terminal move with
  /// Black's deterministic reply so single-agent graph search works seamlessly.
  static List<SuccessorTransition> getSuccessors(
    BoardState state, {
    BlackPolicy blackPolicy = BlackPolicy.centerSeeking,
    bool pruneDeadEnds = true,
  }) {
    final transitions = <SuccessorTransition>[];
    final priorEscapes = getBlackKingMoves(state).length;
    final bkBefore = state.blackKing;
    final wkBefore = state.whiteKing;

    for (final whiteMove in getWhiteMoves(state)) {
      final midState = applyMove(state, whiteMove);

      if (isCheckmate(midState)) {
        transitions.add(
          SuccessorTransition(
            whiteMove: whiteMove,
            midState: midState,
            blackMove: null,
            nextState: midState,
            stepCost: 1.0,
            whiteTacticalTag: TacticalTag.deliverCheckmate,
            blackTacticalTag: null,
          ),
        );
        continue;
      }

      if (pruneDeadEnds && isStalemate(midState)) {
        continue;
      }

      final blackMove = chooseBlackKingMove(midState, policy: blackPolicy);
      if (blackMove == null) {
        if (pruneDeadEnds) continue;
        transitions.add(
          SuccessorTransition(
            whiteMove: whiteMove,
            midState: midState,
            blackMove: null,
            nextState: midState,
          ),
        );
        continue;
      }

      final nextState = applyMove(midState, blackMove);
      if (pruneDeadEnds && !hasSufficientMatingMaterial(nextState)) {
        // White left a critical piece undefended and lost mating material.
        continue;
      }

      final whiteTag = _classifyWhiteTag(
        move: whiteMove,
        mid: midState,
        priorEscapes: priorEscapes,
        bkBefore: bkBefore,
        wkBefore: wkBefore,
      );
      final blackTag = _classifyBlackTag(
        mid: midState,
        move: blackMove,
        boardSize: state.boardSize,
      );

      transitions.add(
        SuccessorTransition(
          whiteMove: whiteMove,
          midState: midState,
          blackMove: blackMove,
          nextState: nextState,
          stepCost: 1.0,
          whiteTacticalTag: whiteTag,
          blackTacticalTag: blackTag,
        ),
      );
    }
    return transitions;
  }

  static TacticalTag _classifyWhiteTag({
    required ChessMove move,
    required BoardState mid,
    required int priorEscapes,
    required Piece bkBefore,
    required Piece wkBefore,
  }) {
    if (isCheckmate(mid)) return TacticalTag.deliverCheckmate;
    if (isCheck(mid)) return TacticalTag.deliverCheck;

    if (move.piece == PieceType.wr || move.piece == PieceType.wq) {
      if ((move.to.row - bkBefore.row).abs() == 1 &&
          move.from.row != move.to.row) {
        return TacticalTag.cutOffRank;
      }
      if ((move.to.col - bkBefore.col).abs() == 1 &&
          move.from.col != move.to.col) {
        return TacticalTag.cutOffFile;
      }
    }

    if (move.piece == PieceType.wk) {
      final beforeDist = wkBefore.pos.chebyshevDistanceTo(bkBefore.pos);
      final afterDist = move.to.chebyshevDistanceTo(bkBefore.pos);
      if (afterDist < beforeDist) return TacticalTag.advanceKing;
    }

    if (getBlackKingMoves(mid).length < priorEscapes) {
      return TacticalTag.restrictEscape;
    }

    return TacticalTag.reposition;
  }

  static TacticalTag _classifyBlackTag({
    required BoardState mid,
    required ChessMove move,
    required int boardSize,
  }) {
    if (move.capturedPiece != null) return TacticalTag.captureUndefended;
    if (isCheck(mid)) return TacticalTag.evadeCheck;

    final center = (boardSize - 1) / 2.0;
    final distBefore =
        (move.from.row - center).abs() + (move.from.col - center).abs();
    final distAfter =
        (move.to.row - center).abs() + (move.to.col - center).abs();
    if (distAfter < distBefore) return TacticalTag.centralize;

    final edgeBefore = [
      move.from.row,
      boardSize - 1 - move.from.row,
      move.from.col,
      boardSize - 1 - move.from.col,
    ].reduce(math.min);
    final edgeAfter = [
      move.to.row,
      boardSize - 1 - move.to.row,
      move.to.col,
      boardSize - 1 - move.to.col,
    ].reduce(math.min);
    if (edgeAfter < edgeBefore) return TacticalTag.retreatToEdge;

    return TacticalTag.sidestep;
  }

  // -------------------------------------------------------------------------
  // Curated Endgame Presets & Smart Random Legal Generator
  // -------------------------------------------------------------------------

  /// Returns a curated, verified-legal starting position for [mode].
  ///
  /// `KRK` variants mirror `krk_6_6.html` directly:
  /// - `0`: Default (`WK b2`, `WR d1`, `BK e4`)
  /// - `1`: Fast Mate-in-2 (`WK c3`, `WR e5`, `BK a6`)
  /// - `2`: Edge Push (`WK d3`, `WR b4`, `BK d6`)
  /// - `3`: Challenge (`WK a1`, `WR b1`, `BK d4`)
  static BoardState presetPosition(EndgameMode mode, {int variant = 0}) {
    final pieces = switch (mode) {
      EndgameMode.krk => switch (variant % 4) {
          1 => const <Piece>[
              Piece(PieceType.wk, 3, 2), // c3
              Piece(PieceType.wr, 1, 4), // e5
              Piece(PieceType.bk, 0, 0), // a6
            ],
          2 => const <Piece>[
              Piece(PieceType.wk, 3, 3), // d3
              Piece(PieceType.wr, 2, 1), // b4
              Piece(PieceType.bk, 0, 3), // d6
            ],
          3 => const <Piece>[
              Piece(PieceType.wk, 5, 0), // a1
              Piece(PieceType.wr, 5, 1), // b1
              Piece(PieceType.bk, 2, 3), // d4
            ],
          _ => const <Piece>[
              Piece(PieceType.wk, 4, 1), // b2
              Piece(PieceType.wr, 5, 3), // d1
              Piece(PieceType.bk, 2, 4), // e4
            ],
        },
      EndgameMode.kqk => switch (variant % 2) {
          1 => const <Piece>[
              Piece(PieceType.wk, 3, 2), // c3
              Piece(PieceType.wq, 4, 4), // e2
              Piece(PieceType.bk, 0, 1), // b6
            ],
          _ => const <Piece>[
              Piece(PieceType.wk, 4, 1), // b2
              Piece(PieceType.wq, 5, 2), // c1
              Piece(PieceType.bk, 1, 4), // e5
            ],
        },
      EndgameMode.krrk => switch (variant % 2) {
          1 => const <Piece>[
              Piece(PieceType.wk, 4, 2), // c2
              Piece(PieceType.wr, 5, 0), // a1
              Piece(PieceType.wr, 2, 5), // f4
              Piece(PieceType.bk, 1, 2), // c5
            ],
          _ => const <Piece>[
              Piece(PieceType.wk, 5, 3), // d1
              Piece(PieceType.wr, 5, 0), // a1
              Piece(PieceType.wr, 4, 5), // f2
              Piece(PieceType.bk, 2, 2), // c4
            ],
        },
      EndgameMode.krbk => switch (variant % 2) {
          1 => const <Piece>[
              Piece(PieceType.wk, 3, 2), // c3
              Piece(PieceType.wr, 1, 5), // f5
              Piece(PieceType.wb, 4, 3), // d2
              Piece(PieceType.bk, 0, 1), // b6
            ],
          _ => const <Piece>[
              Piece(PieceType.wk, 4, 1), // b2
              Piece(PieceType.wr, 5, 4), // e1
              Piece(PieceType.wb, 4, 4), // e2
              Piece(PieceType.bk, 1, 2), // c5
            ],
        },
      EndgameMode.custom => const <Piece>[
          Piece(PieceType.wk, 4, 1), // b2
          Piece(PieceType.wq, 5, 0), // a1
          Piece(PieceType.wb, 4, 4), // e2
          Piece(PieceType.bk, 1, 3), // d5
        ],
    };

    return BoardState(pieces: pieces, boardSize: 6, endgameMode: mode);
  }

  /// Generates a random, guaranteed-legal 6×6 position for [mode].
  ///
  /// For [EndgameMode.custom], pass [customAttackers] (defaults to `[WQ, WB]`).
  static BoardState generateRandomLegalPosition(
    EndgameMode mode, {
    math.Random? rng,
    List<PieceType>? customAttackers,
  }) {
    final random = rng ?? math.Random();
    final attackers = mode == EndgameMode.custom
        ? (customAttackers != null && customAttackers.isNotEmpty
            ? customAttackers
            : const <PieceType>[PieceType.wq, PieceType.wb])
        : mode.defaultWhiteAttackers;

    final pieceTypes = <PieceType>[
      PieceType.wk,
      ...attackers,
      PieceType.bk,
    ];

    // Rejection sampling quickly finds a legal non-check, non-adjacent layout.
    for (var attempt = 0; attempt < 500; attempt++) {
      final squares = List<int>.generate(36, (i) => i)..shuffle(random);
      final candidatePieces = <Piece>[];
      for (var i = 0; i < pieceTypes.length; i++) {
        final sq = squares[i];
        candidatePieces.add(Piece(pieceTypes[i], sq ~/ 6, sq % 6));
      }
      final candidate = BoardState(
        pieces: candidatePieces,
        boardSize: 6,
        endgameMode: mode,
      );
      if (isLegalPosition(candidate)) {
        return candidate;
      }
    }

    // Deterministic fallback if custom material cannot reach legal placement.
    return presetPosition(mode);
  }
}
