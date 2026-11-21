import 'dart:math' as math;

import 'package:chess_ai_solver/ai_engine/ai_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchModels & BoardState', () {
    test('coordinate round-trip between GridPos and algebraic', () {
      const topLeft = GridPos(0, 0);
      const bottomRight = GridPos(5, 5);
      expect(topLeft.toAlgebraic(), 'a6');
      expect(bottomRight.toAlgebraic(), 'f1');
      expect(GridPos.fromAlgebraic('a6'), topLeft);
      expect(GridPos.fromAlgebraic('f1'), bottomRight);
      expect(GridPos.fromAlgebraic('e4'), const GridPos(2, 4));
    });

    test('canonical sorting and hash equality for KRRK swapped rooks', () {
      final stateA = BoardState(
        endgameMode: EndgameMode.krrk,
        pieces: const <Piece>[
          Piece(PieceType.wk, 4, 2),
          Piece(PieceType.wr, 5, 0),
          Piece(PieceType.wr, 1, 5),
          Piece(PieceType.bk, 0, 2),
        ],
      );
      final stateB = BoardState(
        endgameMode: EndgameMode.krrk,
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 2),
          Piece(PieceType.wr, 1, 5),
          Piece(PieceType.wk, 4, 2),
          Piece(PieceType.wr, 5, 0),
        ],
      );
      expect(stateA, equals(stateB));
      expect(stateA.hashCode, equals(stateB.hashCode));
      expect(<BoardState>{stateA, stateB}.length, 1);
    });
  });

  group('MovesEngine chess rules', () {
    test('ray blocking, Black King x-ray transparency, and captures', () {
      // Friendly WK at (0, 3) is defended by WR at (0, 5) and blocks rays to (0, 1).
      final friendlyBlock = BoardState(
        pieces: const <Piece>[
          Piece(PieceType.wk, 0, 3),
          Piece(PieceType.wr, 0, 5),
          Piece(PieceType.bk, 4, 0),
        ],
      );
      final attacked = getAttackedSquares(friendlyBlock, ignoreBlackKing: false);
      expect(attacked.contains(const GridPos(0, 3)), isTrue);
      expect(attacked.contains(const GridPos(0, 1)), isFalse);

      // X-ray through BK stops BK from retreating backward along check ray.
      final xrayCheck = BoardState(
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 1),
          Piece(PieceType.wr, 0, 4),
          Piece(PieceType.wk, 3, 3),
        ],
      );
      expect(isCheck(xrayCheck), isTrue);
      final escapes = getBlackKingMoves(xrayCheck).map((m) => m.to).toSet();
      expect(escapes.contains(const GridPos(0, 0)), isFalse);
      expect(escapes.contains(const GridPos(0, 2)), isFalse);
      expect(escapes.contains(const GridPos(1, 1)), isTrue);

      // BK can capture an undefended Rook, but cannot capture a defended Rook.
      final undefended = BoardState(
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 1),
          Piece(PieceType.wr, 0, 2),
          Piece(PieceType.wk, 4, 4),
        ],
      );
      final undefendedMoves = getBlackKingMoves(undefended);
      final captureMove = undefendedMoves
          .where((m) => m.to == const GridPos(0, 2))
          .toList();
      expect(captureMove.length, 1);
      expect(captureMove.first.capturedPiece, PieceType.wr);

      final defended = BoardState(
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 1),
          Piece(PieceType.wr, 0, 2),
          Piece(PieceType.wk, 1, 3),
        ],
      );
      expect(
        getBlackKingMoves(defended).any((m) => m.to == const GridPos(0, 2)),
        isFalse,
      );
    });

    test('checkmate and stalemate detection across KRK, KQK, KRRK, KRBK', () {
      final krkMate = BoardState(
        endgameMode: EndgameMode.krk,
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 0),
          Piece(PieceType.wk, 2, 0),
          Piece(PieceType.wr, 0, 5),
        ],
      );
      expect(isCheckmate(krkMate), isTrue);
      expect(isStalemate(krkMate), isFalse);

      final kqkMate = BoardState(
        endgameMode: EndgameMode.kqk,
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 2),
          Piece(PieceType.wk, 2, 2),
          Piece(PieceType.wq, 1, 2),
        ],
      );
      expect(isCheckmate(kqkMate), isTrue);

      final krrkMate = BoardState(
        endgameMode: EndgameMode.krrk,
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 3),
          Piece(PieceType.wk, 5, 5),
          Piece(PieceType.wr, 0, 0),
          Piece(PieceType.wr, 1, 5),
        ],
      );
      expect(isCheckmate(krrkMate), isTrue);

      final krbkMate = BoardState(
        endgameMode: EndgameMode.krbk,
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 0),
          Piece(PieceType.wk, 2, 1),
          Piece(PieceType.wr, 0, 5),
          Piece(PieceType.wb, 2, 2),
        ],
      );
      expect(isCheckmate(krbkMate), isTrue);

      final kqkStalemate = BoardState(
        endgameMode: EndgameMode.kqk,
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 0),
          Piece(PieceType.wk, 2, 2),
          Piece(PieceType.wq, 1, 2),
        ],
      );
      expect(isCheck(kqkStalemate), isFalse);
      expect(isStalemate(kqkStalemate), isTrue);
      expect(isCheckmate(kqkStalemate), isFalse);
    });

    test('validatePosition catches all 9 invalid placement cases', () {
      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 0, 0),
              Piece(PieceType.wr, 6, 0),
              Piece(PieceType.bk, 4, 4),
            ],
          ),
        ).errorCodes,
        contains('OUT_OF_BOUNDS'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 2, 2),
              Piece(PieceType.wr, 2, 2),
              Piece(PieceType.bk, 5, 5),
            ],
          ),
        ).errorCodes,
        contains('OVERLAPPING_PIECES'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wr, 0, 0),
              Piece(PieceType.bk, 5, 5),
            ],
          ),
        ).errorCodes,
        contains('MISSING_WHITE_KING'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 0, 0),
              Piece(PieceType.wr, 3, 3),
            ],
          ),
        ).errorCodes,
        contains('MISSING_BLACK_KING'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 0, 0),
              Piece(PieceType.wk, 2, 2),
              Piece(PieceType.bk, 5, 5),
            ],
          ),
        ).errorCodes,
        contains('DUPLICATE_WHITE_KING'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 0, 0),
              Piece(PieceType.bk, 4, 4),
              Piece(PieceType.bk, 5, 5),
            ],
          ),
        ).errorCodes,
        contains('DUPLICATE_BLACK_KING'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 2, 2),
              Piece(PieceType.wr, 5, 0),
              Piece(PieceType.bk, 3, 3),
            ],
          ),
        ).errorCodes,
        contains('ADJACENT_KINGS'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 5, 5),
              Piece(PieceType.wr, 0, 5),
              Piece(PieceType.bk, 0, 0),
            ],
          ),
        ).errorCodes,
        contains('BLACK_KING_IN_CHECK'),
      );

      expect(
        validatePosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 0, 0),
              Piece(PieceType.wb, 2, 2),
              Piece(PieceType.wb, 4, 4),
              Piece(PieceType.bk, 5, 5),
            ],
          ),
        ).errorCodes,
        contains('INSUFFICIENT_MATERIAL'),
      );

      // Opposite-colored bishops ARE sufficient material.
      expect(
        isLegalPosition(
          BoardState(
            pieces: const <Piece>[
              Piece(PieceType.wk, 0, 0),
              Piece(PieceType.wb, 2, 2),
              Piece(PieceType.wb, 2, 3),
              Piece(PieceType.bk, 5, 4),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('presets and random generator produce legal positions across modes', () {
      final rng = math.Random(42);
      for (final mode in EndgameMode.values) {
        expect(isLegalPosition(MovesEngine.presetPosition(mode)), isTrue);
        expect(
          isLegalPosition(
            MovesEngine.generateRandomLegalPosition(mode, rng: rng),
          ),
          isTrue,
        );
      }
    });
  });

  group('Heuristics, Registry & Solvers', () {
    test('endgameHeuristic returns 0 on mate and satisfies admissible lower bound', () {
      final mateState = BoardState(
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 0),
          Piece(PieceType.wk, 2, 0),
          Piece(PieceType.wr, 0, 5),
        ],
      );
      expect(endgameHeuristic(mateState), 0.0);

      final mateIn1 = BoardState(
        pieces: const <Piece>[
          Piece(PieceType.bk, 0, 0),
          Piece(PieceType.wk, 2, 0),
          Piece(PieceType.wr, 1, 5),
        ],
      );
      expect(endgameHeuristic(mateIn1), 1.0);

      final mateIn2 = MovesEngine.presetPosition(EndgameMode.krk, variant: 1);
      expect(endgameHeuristic(mateIn2), lessThanOrEqualTo(2.0));
      expect(endgameHeuristic(mateIn2), greaterThanOrEqualTo(1.0));
    });

    test('AlgorithmRegistry registers bfs, dfs, astar dynamically', () {
      final ids = AlgorithmRegistry.all.map((a) => a.id).toList();
      expect(ids, equals(<String>['bfs', 'dfs', 'astar']));
      expect(AlgorithmRegistry.byId('astar').isOptimal, isTrue);
      expect(AlgorithmRegistry.byId('dfs').isOptimal, isFalse);
    });

    test('BFS, DFS, and A* solve multi-endgame positions legally', () {
      final krkDefault = MovesEngine.presetPosition(EndgameMode.krk, variant: 0);
      final krkFast = MovesEngine.presetPosition(EndgameMode.krk, variant: 1);
      final krkEdge = MovesEngine.presetPosition(EndgameMode.krk, variant: 2);
      final kqkFast = MovesEngine.presetPosition(EndgameMode.kqk, variant: 1);
      final krrk = MovesEngine.presetPosition(EndgameMode.krrk, variant: 1);
      final krbk = MovesEngine.presetPosition(EndgameMode.krbk, variant: 1);

      final bfs = AlgorithmRegistry.byId('bfs');
      final dfs = AlgorithmRegistry.byId('dfs');
      final astar = AlgorithmRegistry.byId('astar');

      for (final start in <BoardState>[
        krkDefault,
        krkFast,
        krkEdge,
        kqkFast,
        krrk,
        krbk,
      ]) {
        final bfsRes = bfs.solve(start);
        final astarRes = astar.solve(start);

        expect(bfsRes.isSolved, isTrue, reason: 'BFS failed on ${start.endgameMode}');
        expect(astarRes.isSolved, isTrue, reason: 'A* failed on ${start.endgameMode}');
        expect(bfsRes.path.last.isCheckmate, isTrue);
        expect(astarRes.path.last.isCheckmate, isTrue);
        expect(
          astarRes.metrics.solutionCost,
          equals(bfsRes.metrics.solutionCost),
          reason: 'A* must match optimal BFS cost on ${start.endgameMode}',
        );
      }

      // On non-trivial multi-move endgames (where BFS doesn't hit an early goal
      // on its very 2nd expansion before popping), A* expands fewer or equal nodes.
      for (final nonTrivial in <BoardState>[krkDefault, krkEdge]) {
        final bfsNodes = bfs.solve(nonTrivial).metrics.expandedNodes;
        final astarNodes = astar.solve(nonTrivial).metrics.expandedNodes;
        expect(
          astarNodes,
          lessThanOrEqualTo(bfsNodes),
          reason: 'A* ($astarNodes) should expand <= BFS ($bfsNodes)',
        );
      }

      // Verify DFS returns a valid checkmate path on KRK Fast & KRRK.
      final dfsFast = dfs.solve(krkFast);
      expect(dfsFast.isSolved, isTrue);
      expect(dfsFast.path.last.isCheckmate, isTrue);
      expect(dfsFast.metrics.solutionCost, greaterThanOrEqualTo(2));
    });

    test('AiEngineRunner executes single solve and benchmark via Isolate.run', () async {
      final krkDefault = MovesEngine.presetPosition(EndgameMode.krk, variant: 0);

      final single = await AiEngineRunner.solveInBackground(
        algorithmId: 'astar',
        start: krkDefault,
      );
      expect(single.isSolved, isTrue);
      expect(single.path.last.isCheckmate, isTrue);

      final suite = await AiEngineRunner.benchmarkAllInBackground(
        start: krkDefault,
      );
      expect(suite.results.length, AlgorithmRegistry.all.length);
      expect(suite.winners.shortestPathId, isNotNull);
      expect(suite.winners.fastestId, isNotNull);
      expect(suite.winners.fewestNodesId, isNotNull);
    });
  });
}
