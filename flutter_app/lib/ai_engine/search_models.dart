/// ai_engine/search_models.dart
/// ============================
/// Immutable data models, enums, and lightweight utility structures shared
/// across the 6×6 Chess Endgame rules engine, search algorithms, and UI.
///
/// Pure Dart only (zero Flutter imports) so every model transfers and runs
/// safely inside background `Isolate.run(...)` workers.
library;

import 'dart:math' as math;

/// The side performing a half-move (ply).
enum Actor {
  /// Attacking player (White King + checkmating pieces).
  white('white'),

  /// Defending player (lone Black King).
  black('black');

  const Actor(this.code);

  /// Wire/debug label.
  final String code;

  /// Returns the opposing side.
  Actor get opponent => this == white ? black : white;
}

/// All chess piece types supported on the 6×6 endgame board.
enum PieceType {
  /// White King.
  wk('WK', Actor.white, 'K', '♔', 'White King', 'الملك الأبيض'),

  /// White Queen.
  wq('WQ', Actor.white, 'Q', '♕', 'White Queen', 'الوزير الأبيض'),

  /// White Rook.
  wr('WR', Actor.white, 'R', '♖', 'White Rook', 'الرُخ الأبيض'),

  /// White Bishop.
  wb('WB', Actor.white, 'B', '♗', 'White Bishop', 'الفيل الأبيض'),

  /// Black King.
  bk('BK', Actor.black, 'K', '♚', 'Black King', 'الملك الأسود');

  const PieceType(
    this.code,
    this.actor,
    this.symbol,
    this.glyph,
    this.nameEn,
    this.nameAr,
  );

  /// Short uppercase code (`WK`, `WQ`, `WR`, `WB`, `BK`).
  final String code;

  /// Owner side (`Actor.white` or `Actor.black`).
  final Actor actor;

  /// Algebraic notation prefix (`K`, `Q`, `R`, `B`).
  final String symbol;

  /// Unicode chess piece glyph for compact notation chips.
  final String glyph;

  /// English display name.
  final String nameEn;

  /// Arabic display name.
  final String nameAr;

  /// True for all White pieces.
  bool get isWhite => actor == Actor.white;

  /// True for either King.
  bool get isKing => this == wk || this == bk;

  /// True for Rooks and Queens (4 orthogonal rays).
  bool get slidesOrthogonally => this == wr || this == wq;

  /// True for Bishops and Queens (4 diagonal rays).
  bool get slidesDiagonally => this == wb || this == wq;

  /// True for any long-range sliding piece.
  bool get isSlider => slidesOrthogonally || slidesDiagonally;

  /// White attacking pieces available to customize/place alongside the Kings.
  static const List<PieceType> attackerTypes = <PieceType>[wq, wr, wb];
}

/// Supported White checkmating configurations against a lone Black King.
enum EndgameMode {
  /// White King + Rook vs. Black King.
  krk('KRK', <PieceType>[PieceType.wr], 'King + Rook', 'ملك ورُخ'),

  /// White King + Queen vs. Black King.
  kqk('KQK', <PieceType>[PieceType.wq], 'King + Queen', 'ملك ووزير'),

  /// White King + 2 Rooks vs. Black King.
  krrk(
    'KRRK',
    <PieceType>[PieceType.wr, PieceType.wr],
    'King + 2 Rooks',
    'ملك ورُخّان',
  ),

  /// White King + Rook + Bishop vs. Black King.
  krbk(
    'KRBK',
    <PieceType>[PieceType.wr, PieceType.wb],
    'King + Rook + Bishop',
    'ملك ورُخ وفيل',
  ),

  /// Custom user-configured combination of White attackers.
  custom('CUSTOM', <PieceType>[], 'Custom', 'مخصص');

  const EndgameMode(
    this.code,
    this.defaultWhiteAttackers,
    this.labelEn,
    this.labelAr,
  );

  /// Short preset code (`KRK`, `KQK`, `KRRK`, `KRBK`, `CUSTOM`).
  final String code;

  /// Standard White attacking pieces (excluding `WK`) for this preset.
  final List<PieceType> defaultWhiteAttackers;

  /// English label.
  final String labelEn;

  /// Arabic label.
  final String labelAr;

  /// Maximum attacking pieces permitted alongside the White King in Custom mode.
  static const int maxCustomAttackers = 3;

  /// Complete list of pieces required by a fixed preset.
  List<PieceType> get requiredPieces =>
      <PieceType>[PieceType.wk, ...defaultWhiteAttackers, PieceType.bk];
}

/// Deterministic reply policy used by the lone Black King during search.
enum BlackPolicy {
  /// Legacy `krk_6_6.html` rule: captures undefended pieces first, otherwise
  /// moves to the legal square closest to the geometric center (2.5, 2.5).
  centerSeeking('center_seeking'),

  /// Smart defensive rule: captures undefended material first, otherwise
  /// maximizes future legal mobility and distance from board edges.
  evasive('evasive');

  const BlackPolicy(this.code);

  /// Machine identifier.
  final String code;
}

/// Semantic tactical tags attached to every move for localized storytelling.
enum TacticalTag {
  deliverCheckmate,
  deliverCheck,
  cutOffRank,
  cutOffFile,
  advanceKing,
  restrictEscape,
  reposition,
  captureUndefended,
  evadeCheck,
  centralize,
  retreatToEdge,
  sidestep,
}

/// Lifecycle outcome of a `SearchAlgorithm.solve(...)` invocation.
enum SearchStatus {
  /// Checkmate sequence found.
  solved,

  /// Search space exhausted (or local optimum reached) without finding mate.
  failed,

  /// Expanded-node safety cap (`maxNodes`) reached before solving.
  nodeCapReached,
}

/// Zero-based (row, col) square coordinate on the 6×6 board.
///
/// Convention:
/// - `row = 0` is rank `6` (top), `row = 5` is rank `1` (bottom).
/// - `col = 0` is file `a` (left), `col = 5` is file `f` (right).
class GridPos {
  /// Creates a coordinate for `(row, col)`.
  const GridPos(this.row, this.col);

  /// Row index `[0 .. boardSize - 1]` (top to bottom).
  final int row;

  /// Column index `[0 .. boardSize - 1]` (left to right).
  final int col;

  /// Converts `(row, col)` to flat row-major square index `0..35`.
  int squareIndex({int boardSize = 6}) => row * boardSize + col;

  /// Formats this square in algebraic chess notation (e.g., `(0, 0)` -> `a6`).
  String toAlgebraic({int boardSize = 6}) {
    final fileChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rankNum = boardSize - row;
    return '$fileChar$rankNum';
  }

  /// Parses algebraic notation (e.g., `'e4'`) into a [GridPos].
  factory GridPos.fromAlgebraic(String coord, {int boardSize = 6}) {
    final cleaned = coord.trim().toLowerCase();
    if (cleaned.length < 2) {
      throw FormatException('Invalid algebraic square "$coord".');
    }
    final col = cleaned.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(cleaned.substring(1));
    final row = boardSize - rank;
    if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
      throw RangeError('Square "$coord" is outside ${boardSize}x$boardSize.');
    }
    return GridPos(row, col);
  }

  /// King-step (Chebyshev) distance to [other]: `max(|dr|, |dc|)`.
  int chebyshevDistanceTo(GridPos other) =>
      math.max((row - other.row).abs(), (col - other.col).abs());

  /// Orthogonal (Manhattan) distance to [other]: `|dr| + |dc|`.
  int manhattanDistanceTo(GridPos other) =>
      (row - other.row).abs() + (col - other.col).abs();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GridPos && other.row == row && other.col == col);

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridPos($row, $col)';
}

/// Immutable chess piece positioned at `(row, col)`.
class Piece {
  /// Places [type] at `(row, col)`.
  const Piece(this.type, this.row, this.col);

  /// Piece kind (`WK`, `WQ`, `WR`, `WB`, `BK`).
  final PieceType type;

  /// Row index `[0 .. boardSize - 1]`.
  final int row;

  /// Column index `[0 .. boardSize - 1]`.
  final int col;

  /// Square coordinate as a [GridPos].
  GridPos get pos => GridPos(row, col);

  /// Returns a copy of this piece moved to `(newRow, newCol)`.
  Piece moveTo(int newRow, int newCol) => Piece(type, newRow, newCol);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Piece &&
          other.type == type &&
          other.row == row &&
          other.col == col);

  @override
  int get hashCode => Object.hash(type, row, col);

  @override
  String toString() => '${type.code}@($row,$col)';
}

/// Immutable, hashable board snapshot used as a search graph node.
///
/// Pieces are **canonically sorted** on construction so equivalent positions
/// with identical pieces (e.g., swapped White Rooks in `KRRK`) always produce
/// the exact same [stateKey], [hashCode], and `==` comparison.
class BoardState {
  /// Builds an immutable, canonically ordered [BoardState].
  BoardState({
    required List<Piece> pieces,
    this.boardSize = 6,
    this.endgameMode = EndgameMode.krk,
    this.turn = Actor.white,
  }) : pieces = _canonicalize(pieces) {
    final buffer = StringBuffer()
      ..write(boardSize)
      ..write(':')
      ..write(turn.index);
    for (final p in this.pieces) {
      buffer
        ..write('|')
        ..write(p.type.index)
        ..write('@')
        ..write(p.row)
        ..write(',')
        ..write(p.col);
    }
    stateKey = buffer.toString();
    _cachedHashCode = Object.hash(boardSize, turn, stateKey);
  }

  /// Canonically sorted unmodifiable piece list.
  final List<Piece> pieces;

  /// Board dimension (6 for 6×6 endgames).
  final int boardSize;

  /// Selected endgame preset (metadata only — excluded from equality/hashing).
  final EndgameMode endgameMode;

  /// Active side to move.
  final Actor turn;

  /// Unique canonical string key for fast debugging & equality checks.
  late final String stateKey;

  late final int _cachedHashCode;

  static List<Piece> _canonicalize(List<Piece> raw) {
    final copy = List<Piece>.of(raw)
      ..sort((a, b) {
        final byType = a.type.index.compareTo(b.type.index);
        if (byType != 0) return byType;
        final byRow = a.row.compareTo(b.row);
        if (byRow != 0) return byRow;
        return a.col.compareTo(b.col);
      });
    return List<Piece>.unmodifiable(copy);
  }

  /// Returns a copy of this state with updated [pieces], [endgameMode], or [turn].
  BoardState copyWith({
    List<Piece>? pieces,
    int? boardSize,
    EndgameMode? endgameMode,
    Actor? turn,
  }) {
    return BoardState(
      pieces: pieces ?? this.pieces,
      boardSize: boardSize ?? this.boardSize,
      endgameMode: endgameMode ?? this.endgameMode,
      turn: turn ?? this.turn,
    );
  }

  /// True when `(row, col)` lies within `[0, boardSize)`.
  bool inBounds(int row, int col) =>
      row >= 0 && row < boardSize && col >= 0 && col < boardSize;

  /// Returns the piece on `(row, col)`, or `null` if the square is empty.
  Piece? pieceAt(int row, int col) {
    for (final p in pieces) {
      if (p.row == row && p.col == col) return p;
    }
    return null;
  }

  /// White King if present, otherwise `null`.
  Piece? get whiteKingOrNull {
    for (final p in pieces) {
      if (p.type == PieceType.wk) return p;
    }
    return null;
  }

  /// White King (throws [StateError] if absent).
  Piece get whiteKing =>
      whiteKingOrNull ??
      (throw StateError('BoardState is missing White King (WK).'));

  /// Black King if present, otherwise `null`.
  Piece? get blackKingOrNull {
    for (final p in pieces) {
      if (p.type == PieceType.bk) return p;
    }
    return null;
  }

  /// Black King (throws [StateError] if absent).
  Piece get blackKing =>
      blackKingOrNull ??
      (throw StateError('BoardState is missing Black King (BK).'));

  /// All White pieces currently on the board.
  List<Piece> get whitePieces =>
      pieces.where((p) => p.type.isWhite).toList(growable: false);

  /// All non-king White attacking pieces (Queens, Rooks, Bishops).
  List<Piece> get whiteAttackers =>
      pieces.where((p) => p.type.isWhite && !p.type.isKing).toList(growable: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardState &&
          other._cachedHashCode == _cachedHashCode &&
          other.stateKey == stateKey);

  @override
  int get hashCode => _cachedHashCode;

  @override
  String toString() => 'BoardState(${pieces.join(", ")})';
}

/// A single half-move (ply) by White or Black.
class ChessMove {
  /// Creates an immutable half-move descriptor.
  const ChessMove({
    required this.actor,
    required this.piece,
    required this.from,
    required this.to,
    this.capturedPiece,
  });

  /// Side executing this move.
  final Actor actor;

  /// Piece type being moved.
  final PieceType piece;

  /// Origin square.
  final GridPos from;

  /// Destination square.
  final GridPos to;

  /// Captured piece if Black King takes an undefended White piece.
  final PieceType? capturedPiece;

  /// Formats short algebraic chess notation (e.g., `Rf6#`, `Kc4`, `Kxb5`).
  String toNotation({
    int boardSize = 6,
    bool isCheck = false,
    bool isCheckmate = false,
  }) {
    final capture = capturedPiece != null ? 'x' : '';
    final target = to.toAlgebraic(boardSize: boardSize);
    final suffix = isCheckmate ? '#' : (isCheck ? '+' : '');
    return '${piece.symbol}$capture$target$suffix';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChessMove &&
          other.actor == actor &&
          other.piece == piece &&
          other.from == from &&
          other.to == to &&
          other.capturedPiece == capturedPiece);

  @override
  int get hashCode => Object.hash(actor, piece, from, to, capturedPiece);
}

/// One full White-turn search edge (`whiteMove` + deterministic `blackMove` reply).
class SuccessorTransition {
  /// Creates a transition between White-to-move states (or terminal checkmate).
  const SuccessorTransition({
    required this.whiteMove,
    required this.midState,
    required this.blackMove,
    required this.nextState,
    this.stepCost = 1.0,
    this.whiteTacticalTag = TacticalTag.reposition,
    this.blackTacticalTag,
  });

  /// White's legal move.
  final ChessMove whiteMove;

  /// Board immediately after White's move (before Black replies).
  final BoardState midState;

  /// Black King's deterministic reply, or `null` when [midState] is checkmate.
  final ChessMove? blackMove;

  /// Resulting board ready for White's next turn (equals [midState] on checkmate).
  final BoardState nextState;

  /// Path cost increment `c(s, a, s')` (1.0 per White turn).
  final double stepCost;

  /// Semantic explanation tag for White's move.
  final TacticalTag whiteTacticalTag;

  /// Semantic explanation tag for Black's reply (`null` on checkmate).
  final TacticalTag? blackTacticalTag;
}

/// One playback frame along the reconstructed checkmate solution path.
class MoveStep {
  /// Creates an immutable playback frame with full telemetry and vision overlays.
  const MoveStep({
    required this.stepIndex,
    required this.actor,
    required this.piece,
    required this.from,
    required this.to,
    required this.notation,
    required this.isCheck,
    required this.isCheckmate,
    required this.g,
    required this.h,
    required this.f,
    required this.snapshot,
    required this.tacticalTag,
    required this.whiteAttackedSquares,
    required this.blackEscapeSquares,
  });

  /// Zero-based playback index.
  final int stepIndex;

  /// Side that performed this half-move.
  final Actor actor;

  /// Piece moved.
  final PieceType piece;

  /// Origin square.
  final GridPos from;

  /// Destination square.
  final GridPos to;

  /// Formatted algebraic notation (`Ra6#`, `Kc4`, etc.).
  final String notation;

  /// True if the Black King is in check after this move.
  final bool isCheck;

  /// True if this move delivers checkmate.
  final bool isCheckmate;

  /// Cumulative path cost `g(n)` (White turns taken so far).
  final double g;

  /// Heuristic estimate `h(n)` remaining from [snapshot].
  final double h;

  /// Total evaluation `f(n) = g(n) + h(n)`.
  final double f;

  /// Board position immediately after this half-move.
  final BoardState snapshot;

  /// Semantic tactical tag used by the localized commentary panel.
  final TacticalTag tacticalTag;

  /// Squares controlled by White in [snapshot] (for tactical vision overlay).
  final Set<GridPos> whiteAttackedSquares;

  /// Legal escape squares remaining for Black King in [snapshot].
  final List<GridPos> blackEscapeSquares;
}

/// Lightweight telemetry sample recorded during search for progress charts.
class SearchTracePoint {
  /// Records one sampled point of the search frontier trajectory.
  const SearchTracePoint({
    required this.iteration,
    required this.expandedNodes,
    required this.frontierSize,
    required this.g,
    required this.h,
    required this.f,
    required this.focusSquare,
  });

  final int iteration;
  final int expandedNodes;
  final int frontierSize;
  final double g;
  final double h;
  final double f;
  final GridPos focusSquare;
}

/// Quantitative execution metrics returned by every search run.
class SearchMetrics {
  /// Creates immutable performance metrics for a single search run.
  const SearchMetrics({
    required this.executionTimeMs,
    required this.expandedNodes,
    required this.generatedNodes,
    required this.maxFrontierSize,
    required this.solutionCost,
    required this.solutionPlies,
  });

  /// Wall-clock search duration in milliseconds.
  final double executionTimeMs;

  /// Total states popped / expanded.
  final int expandedNodes;

  /// Total child states generated and pushed to the frontier.
  final int generatedNodes;

  /// Peak frontier / recursion stack size (proxy for memory consumption).
  final int maxFrontierSize;

  /// Solution length in White turns (`0` if unsolved).
  final int solutionCost;

  /// Total half-moves (`MoveStep` frames) in the playback sequence.
  final int solutionPlies;
}

/// Complete output returned by `SearchAlgorithm.solve(...)`.
class SearchResult {
  /// Creates an immutable [SearchResult].
  const SearchResult({
    required this.status,
    required this.algorithmId,
    required this.path,
    required this.metrics,
    this.trace = const <SearchTracePoint>[],
    this.errorCode,
    this.message = '',
  });

  /// Outcome (`solved`, `failed`, or `nodeCapReached`).
  final SearchStatus status;

  /// ID of the algorithm that produced this result.
  final String algorithmId;

  /// Ordered White/Black playback sequence leading to checkmate.
  final List<MoveStep> path;

  /// Performance & complexity metrics.
  final SearchMetrics metrics;

  /// Sampled search progression points (max 60 samples).
  final List<SearchTracePoint> trace;

  /// Optional machine error code when [status] != `solved`.
  final String? errorCode;

  /// Optional human-readable error/status summary.
  final String message;

  /// Convenience getter returning `true` when checkmate was found.
  bool get isSolved => status == SearchStatus.solved;
}

/// Result of real-time legality validation on a user-edited board position.
class PositionValidation {
  /// Creates a validation summary with bilingual error descriptions.
  const PositionValidation({
    required this.isValid,
    required this.errorCodes,
    required this.messagesEn,
    required this.messagesAr,
  });

  /// True when the position satisfies all rules and can be solved.
  final bool isValid;

  /// Machine error identifiers (empty when [isValid] is `true`).
  final List<String> errorCodes;

  /// English validation error messages.
  final List<String> messagesEn;

  /// Arabic validation error messages.
  final List<String> messagesAr;
}

/// Lightweight generic binary Min-Heap priority queue (zero external packages).
///
/// Used by informed and cost-based algorithms (A*, UCS, Greedy Best-First).
class MinHeap<T> {
  /// Creates a min-heap ordered by [compare] (`compare(a, b) < 0` means `a` first).
  MinHeap(this._compare);

  final int Function(T a, T b) _compare;
  final List<T> _items = <T>[];

  /// Current number of elements in the heap.
  int get length => _items.length;

  /// True when the heap has no elements.
  bool get isEmpty => _items.isEmpty;

  /// True when at least one element sits in the heap.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Inserts [value] and restores the heap invariant in O(log n).
  void add(T value) {
    _items.add(value);
    _siftUp(_items.length - 1);
  }

  /// Removes and returns the minimum element in O(log n).
  T removeFirst() {
    if (_items.isEmpty) {
      throw StateError('Cannot removeFirst() from an empty MinHeap.');
    }
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      _siftDown(0);
    }
    return top;
  }

  void _siftUp(int index) {
    var i = index;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[i], _items[parent]) >= 0) break;
      final tmp = _items[i];
      _items[i] = _items[parent];
      _items[parent] = tmp;
      i = parent;
    }
  }

  void _siftDown(int index) {
    var i = index;
    final n = _items.length;
    while (true) {
      final left = (i << 1) + 1;
      final right = left + 1;
      var smallest = i;
      if (left < n && _compare(_items[left], _items[smallest]) < 0) {
        smallest = left;
      }
      if (right < n && _compare(_items[right], _items[smallest]) < 0) {
        smallest = right;
      }
      if (smallest == i) break;
      final tmp = _items[i];
      _items[i] = _items[smallest];
      _items[smallest] = tmp;
      i = smallest;
    }
  }
}
