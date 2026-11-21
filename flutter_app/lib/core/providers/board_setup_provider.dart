/// core/providers/board_setup_provider.dart
/// ==========================================
/// Riverpod state controller managing interactive 6×6 board setup:
/// - Endgame piece-set selection (`KRK`, `KQK`, `KRRK`, `KRBK`, `CUSTOM`)
/// - Tap-to-place & Drag-and-Drop piece positioning (with swap on occupied squares)
/// - Adding/removing Custom White attackers (`WQ`, `WR`, `WB`)
/// - Smart Presets & Smart Random Legal Position generation
/// - Real-time legality validation + Tactical Vision overlay sets
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_engine/ai_engine.dart';
import 'benchmark_provider.dart';
import 'playback_provider.dart';
import 'solver_provider.dart';

/// Immutable snapshot of the editable 6×6 setup board and its tactical state.
class BoardSetupState {
  /// Creates a [BoardSetupState].
  const BoardSetupState({
    required this.board,
    required this.selectedPieceIndex,
    required this.customAttackers,
    required this.validation,
    required this.whiteAttackedSquares,
    required this.blackEscapeSquares,
  });

  /// Current board arrangement (White moves first).
  final BoardState board;

  /// Index inside `board.pieces` selected for Tap-to-Place movement.
  final int selectedPieceIndex;

  /// Current attacking pieces used when [EndgameMode.custom] is active.
  final List<PieceType> customAttackers;

  /// Live placement legality result.
  final PositionValidation validation;

  /// Squares controlled by White pieces in [board].
  final Set<GridPos> whiteAttackedSquares;

  /// Legal escape squares available to the Black King in [board].
  final List<GridPos> blackEscapeSquares;

  /// Currently selected piece on the board, if any.
  Piece? get selectedPiece => (selectedPieceIndex >= 0 &&
          selectedPieceIndex < board.pieces.length)
      ? board.pieces[selectedPieceIndex]
      : null;

  /// True when the user can add another attacker in [EndgameMode.custom] mode.
  bool get canAddCustomAttacker =>
      customAttackers.length < EndgameMode.maxCustomAttackers;
}

/// Manages user edits to the starting 6×6 endgame position.
class BoardSetupNotifier extends Notifier<BoardSetupState> {
  @override
  BoardSetupState build() {
    final initial = MovesEngine.presetPosition(EndgameMode.krk, variant: 0);
    return _deriveState(initial, selectedIndex: 0);
  }

  /// Switches the active endgame preset (`KRK`, `KQK`, `KRRK`, `KRBK`, `CUSTOM`).
  void setEndgameMode(EndgameMode mode) {
    final nextBoard = MovesEngine.presetPosition(mode, variant: 0);
    state = _deriveState(nextBoard, selectedIndex: 0);
    _clearAnalysis();
  }

  /// Applies a numbered curated preset for the current [EndgameMode].
  void applyPreset(int variant) {
    final nextBoard = MovesEngine.presetPosition(
      state.board.endgameMode,
      variant: variant,
    );
    state = _deriveState(nextBoard, selectedIndex: 0);
    _clearAnalysis();
  }

  /// Generates a random, guaranteed-legal position for the current endgame set.
  void randomizeLegalPosition() {
    final nextBoard = MovesEngine.generateRandomLegalPosition(
      state.board.endgameMode,
      customAttackers: state.customAttackers,
    );
    state = _deriveState(
      nextBoard,
      selectedIndex: 0,
      customAttackers: state.customAttackers,
    );
    _clearAnalysis();
  }

  /// Resets the current endgame mode back to its default preset.
  void resetToDefault() => applyPreset(0);

  /// Highlights the piece at [index] inside `state.board.pieces`.
  void selectPieceIndex(int index) {
    if (index < 0 || index >= state.board.pieces.length) return;
    state = _deriveState(
      state.board,
      selectedIndex: index,
      customAttackers: state.customAttackers,
    );
  }

  /// Handles tapping square [target]: selects an occupying piece, or moves
  /// the currently selected piece onto [target].
  void handleSquareTap(GridPos target) {
    if (!state.board.inBounds(target.row, target.col)) return;

    final existingIdx = state.board.pieces.indexWhere(
      (p) => p.row == target.row && p.col == target.col,
    );
    if (existingIdx != -1) {
      selectPieceIndex(existingIdx);
      return;
    }

    _movePiece(state.selectedPieceIndex, target);
  }

  /// Handles dragging piece at [pieceIndex] onto [target] (swapping if occupied).
  void dragPieceTo(int pieceIndex, GridPos target) {
    if (!state.board.inBounds(target.row, target.col)) return;
    if (pieceIndex < 0 || pieceIndex >= state.board.pieces.length) return;

    final pieces = List<Piece>.of(state.board.pieces);
    final moving = pieces[pieceIndex];
    if (moving.row == target.row && moving.col == target.col) return;

    final occupantIdx = pieces.indexWhere(
      (p) => p.row == target.row && p.col == target.col,
    );

    if (occupantIdx != -1) {
      // Swap positions smoothly when dropping onto another piece.
      final occupant = pieces[occupantIdx];
      pieces[occupantIdx] = occupant.moveTo(moving.row, moving.col);
    }
    final movedPiece = moving.moveTo(target.row, target.col);
    pieces[pieceIndex] = movedPiece;

    final nextBoard = state.board.copyWith(pieces: pieces);
    final newIdx = nextBoard.pieces.indexOf(movedPiece);
    state = _deriveState(
      nextBoard,
      selectedIndex: newIdx >= 0 ? newIdx : 0,
      customAttackers: state.customAttackers,
    );
    _clearAnalysis();
  }

  /// Adds a White attacker (`WQ`, `WR`, `WB`) and switches to `CUSTOM` mode.
  void addCustomAttacker(PieceType type) {
    if (!type.isWhite || type.isKing) return;
    if (state.customAttackers.length >= EndgameMode.maxCustomAttackers) return;

    final emptySquare = _findFirstEmptySquare(state.board);
    if (emptySquare == null) return;

    final added = Piece(type, emptySquare.row, emptySquare.col);
    final updatedPieces = <Piece>[...state.board.pieces, added];
    final nextBoard = state.board.copyWith(
      pieces: updatedPieces,
      endgameMode: EndgameMode.custom,
    );
    final newIdx = nextBoard.pieces.indexOf(added);
    state = _deriveState(
      nextBoard,
      selectedIndex: newIdx >= 0 ? newIdx : 0,
    );
    _clearAnalysis();
  }

  /// Removes a non-king White attacker at [pieceIndex] and enters `CUSTOM` mode.
  void removeCustomAttackerAt(int pieceIndex) {
    if (pieceIndex < 0 || pieceIndex >= state.board.pieces.length) return;
    final target = state.board.pieces[pieceIndex];
    if (target.type.isKing) return;

    final updated = List<Piece>.of(state.board.pieces)..removeAt(pieceIndex);
    final nextBoard = state.board.copyWith(
      pieces: updated,
      endgameMode: EndgameMode.custom,
    );
    state = _deriveState(nextBoard, selectedIndex: 0);
    _clearAnalysis();
  }

  void _movePiece(int pieceIndex, GridPos target) {
    if (pieceIndex < 0 || pieceIndex >= state.board.pieces.length) return;
    final pieces = List<Piece>.of(state.board.pieces);
    final moved = pieces[pieceIndex].moveTo(target.row, target.col);
    pieces[pieceIndex] = moved;

    final nextBoard = state.board.copyWith(pieces: pieces);
    final newIdx = nextBoard.pieces.indexOf(moved);
    state = _deriveState(
      nextBoard,
      selectedIndex: newIdx >= 0 ? newIdx : 0,
      customAttackers: state.customAttackers,
    );
    _clearAnalysis();
  }

  GridPos? _findFirstEmptySquare(BoardState board) {
    for (var r = 0; r < board.boardSize; r++) {
      for (var c = 0; c < board.boardSize; c++) {
        if (board.pieceAt(r, c) == null) return GridPos(r, c);
      }
    }
    return null;
  }

  BoardSetupState _deriveState(
    BoardState board, {
    required int selectedIndex,
    List<PieceType>? customAttackers,
  }) {
    final validation = MovesEngine.validatePosition(board);
    final allInBounds = board.pieces.every((p) => board.inBounds(p.row, p.col));
    final attacked = allInBounds
        ? MovesEngine.getAttackedSquares(board, ignoreBlackKing: false)
        : const <GridPos>{};
    final escapes = (allInBounds && board.blackKingOrNull != null)
        ? MovesEngine.getBlackKingMoves(board)
            .map((m) => m.to)
            .toList(growable: false)
        : const <GridPos>[];

    final attackers = customAttackers ??
        board.whiteAttackers.map((p) => p.type).toList(growable: false);

    final clampedIndex = board.pieces.isEmpty
        ? 0
        : selectedIndex.clamp(0, board.pieces.length - 1);

    return BoardSetupState(
      board: board,
      selectedPieceIndex: clampedIndex,
      customAttackers: List<PieceType>.unmodifiable(attackers),
      validation: validation,
      whiteAttackedSquares: attacked,
      blackEscapeSquares: escapes,
    );
  }

  void _clearAnalysis() {
    ref.read(solverProvider.notifier).clearResult();
    ref.read(playbackProvider.notifier).reset();
    ref.read(benchmarkProvider.notifier).clear();
  }
}

/// Interactive board setup state provider.
final boardSetupProvider =
    NotifierProvider<BoardSetupNotifier, BoardSetupState>(
  BoardSetupNotifier.new,
);
