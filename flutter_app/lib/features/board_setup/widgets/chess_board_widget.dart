/// features/board_setup/widgets/chess_board_widget.dart
/// ======================================================
/// Interactive 6×6 Chessboard widget with:
/// - **Strict LTR enforcement** around the board & coordinates (`a..f`, `6..1`)
///   so files never reverse when the UI is in Arabic RTL.
/// - Responsive `AspectRatio(1)` sizing (`maxWidth: 480`) preventing phone overflow.
/// - Tap-to-Place AND Drag-and-Drop piece manipulation (including piece swapping).
/// - Smooth 360ms `AnimatedPositioned` piece gliding with stable multi-piece
///   slot tracking (handles duplicate Rooks in `KRRK` cleanly).
/// - Layered [TacticalOverlayLayer], [MoveArrowOverlay], [AiScanningOverlay],
///   tactical legend, and live Legality / Checkmate banner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import 'chess_piece_svgs.dart';
import 'move_arrow_overlay.dart';
import 'tactical_overlay_layer.dart';

/// Stable identity slot allowing [AnimatedPositioned] to glide pieces smoothly
/// across squares without mixing up duplicate pieces like two Rooks in `KRRK`.
class _TrackedPiece {
  const _TrackedPiece({
    required this.slotId,
    required this.boardIndex,
    required this.piece,
  });

  final int slotId;
  final int boardIndex;
  final Piece piece;
}

/// Interactive 6×6 board card combining setup editing, playback animation, and
/// live tactical vision.
class InteractiveChessBoard extends ConsumerStatefulWidget {
  /// Creates an [InteractiveChessBoard].
  const InteractiveChessBoard({super.key});

  @override
  ConsumerState<InteractiveChessBoard> createState() =>
      _InteractiveChessBoardState();
}

class _InteractiveChessBoardState extends ConsumerState<InteractiveChessBoard> {
  final List<_TrackedPiece> _tracked = <_TrackedPiece>[];
  int _nextSlotId = 1;
  String? _lastSyncedKey;
  int? _lastSyncedStepIndex;
  GridPos? _hoveredDropSquare;

  void _syncTrackedPieces(BoardState board, MoveStep? activeStep) {
    final stepMarker = activeStep?.stepIndex;
    if (_lastSyncedKey == board.stateKey &&
        _lastSyncedStepIndex == stepMarker &&
        _tracked.length == board.pieces.length) {
      // Refresh boardIndex pointers even if stateKey didn't change.
      return;
    }

    final targetPieces = board.pieces;
    final usedNewIndices = <int>{};
    final usedOldSlots = <int>{};
    final nextTracked = List<_TrackedPiece?>.filled(targetPieces.length, null);

    // 1) Keep pieces that stayed stationary on their exact square & type.
    for (var oldIdx = 0; oldIdx < _tracked.length; oldIdx++) {
      final oldSlot = _tracked[oldIdx];
      for (var newIdx = 0; newIdx < targetPieces.length; newIdx++) {
        if (usedNewIndices.contains(newIdx)) continue;
        final np = targetPieces[newIdx];
        if (np.type == oldSlot.piece.type &&
            np.row == oldSlot.piece.row &&
            np.col == oldSlot.piece.col) {
          usedOldSlots.add(oldIdx);
          usedNewIndices.add(newIdx);
          nextTracked[newIdx] = _TrackedPiece(
            slotId: oldSlot.slotId,
            boardIndex: newIdx,
            piece: np,
          );
          break;
        }
      }
    }

    // 2) If advancing a playback step, bind the moved piece's origin slot -> destination.
    if (activeStep != null) {
      final destIdx = targetPieces.indexWhere(
        (p) =>
            p.type == activeStep.piece &&
            p.row == activeStep.to.row &&
            p.col == activeStep.to.col,
      );
      if (destIdx != -1 && !usedNewIndices.contains(destIdx)) {
        final originOldIdx = _tracked.indexWhere(
          (slot) =>
              !usedOldSlots.contains(_tracked.indexOf(slot)) &&
              slot.piece.type == activeStep.piece &&
              slot.piece.row == activeStep.from.row &&
              slot.piece.col == activeStep.from.col,
        );
        if (originOldIdx != -1) {
          usedOldSlots.add(originOldIdx);
          usedNewIndices.add(destIdx);
          nextTracked[destIdx] = _TrackedPiece(
            slotId: _tracked[originOldIdx].slotId,
            boardIndex: destIdx,
            piece: targetPieces[destIdx],
          );
        }
      }
    }

    // 3) Match any remaining displaced pieces of the same type by nearest distance.
    for (var newIdx = 0; newIdx < targetPieces.length; newIdx++) {
      if (usedNewIndices.contains(newIdx)) continue;
      final np = targetPieces[newIdx];
      var bestOldIdx = -1;
      var bestDist = 999;

      for (var oldIdx = 0; oldIdx < _tracked.length; oldIdx++) {
        if (usedOldSlots.contains(oldIdx)) continue;
        final op = _tracked[oldIdx].piece;
        if (op.type != np.type) continue;
        final dist = np.pos.manhattanDistanceTo(op.pos);
        if (dist < bestDist) {
          bestDist = dist;
          bestOldIdx = oldIdx;
        }
      }

      if (bestOldIdx != -1) {
        usedOldSlots.add(bestOldIdx);
        usedNewIndices.add(newIdx);
        nextTracked[newIdx] = _TrackedPiece(
          slotId: _tracked[bestOldIdx].slotId,
          boardIndex: newIdx,
          piece: np,
        );
      } else {
        usedNewIndices.add(newIdx);
        nextTracked[newIdx] = _TrackedPiece(
          slotId: _nextSlotId++,
          boardIndex: newIdx,
          piece: np,
        );
      }
    }

    _tracked
      ..clear()
      ..addAll(nextTracked.whereType<_TrackedPiece>());
    _lastSyncedKey = board.stateKey;
    _lastSyncedStepIndex = stepMarker;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final strings = ref.watch(appStringsProvider);
    final setup = ref.watch(boardSetupProvider);
    final solver = ref.watch(solverProvider);
    final playback = ref.watch(playbackProvider);
    final benchmark = ref.watch(benchmarkProvider);

    final isComputing = solver.isSolving || benchmark.isRunning;
    final activeStep = playback.hasSolution ? playback.activeStep : null;
    final displayedBoard =
        playback.hasSolution ? playback.displayedBoard : setup.board;

    // Pieces can be tapped/dragged directly whenever not solving & at frame 0.
    final isEditable =
        !isComputing && (!playback.hasSolution || playback.isAtStart);

    final isMate = displayedBoard.pieces
            .every((p) => displayedBoard.inBounds(p.row, p.col)) &&
        MovesEngine.isCheckmate(displayedBoard);

    _syncTrackedPieces(displayedBoard, activeStep);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Strict LTR wrapper ensures files `a -> f` never flip in Arabic RTL.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  padding: const EdgeInsets.all(8),
                  decoration: GlassDecorations.boardFrame(isCheckmate: isMate),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _FileHeaderRow(boardSize: displayedBoard.boardSize),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          _RankLabelColumn(
                            boardSize: displayedBoard.boardSize,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.glassBorderHover,
                                      width: 1.3,
                                    ),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final boardPx = constraints.maxWidth;
                                      final cell =
                                          boardPx / displayedBoard.boardSize;

                                      return Stack(
                                        children: <Widget>[
                                          // 1) Interactive 6x6 squares grid
                                          _buildSquaresGrid(
                                            board: displayedBoard,
                                            isEditable: isEditable,
                                            cellSize: cell,
                                          ),

                                          // 2) Tactical vision + check/escape rings
                                          Positioned.fill(
                                            child: TacticalOverlayLayer(
                                              board: displayedBoard,
                                              showTacticalVision:
                                                  settings.showTacticalVision,
                                              activeStep: activeStep,
                                            ),
                                          ),

                                          // 3) Animated glowing move trajectory
                                          Positioned.fill(
                                            child: MoveArrowOverlay(
                                              boardSize:
                                                  displayedBoard.boardSize,
                                              activeStep: activeStep,
                                            ),
                                          ),

                                          // 4) Smoothly gliding piece layer
                                          ..._buildGlidingPieces(
                                            cellSize: cell,
                                            isEditable: isEditable,
                                            selectedIdx:
                                                setup.selectedPieceIndex,
                                          ),

                                          // 5) Futuristic AI search radar overlay
                                          if (isComputing)
                                            Positioned.fill(
                                              child: Container(
                                                color: AppColors.bgBase
                                                    .withValues(alpha: 0.48),
                                                alignment: Alignment.center,
                                                padding:
                                                    const EdgeInsets.all(18),
                                                child: AiScanningOverlay(
                                                  title: benchmark.isRunning
                                                      ? strings
                                                          .benchmarkScanningTitle
                                                      : strings.scanningTitle,
                                                  subtitle: benchmark.isRunning
                                                      ? strings
                                                          .benchmarkScanningSubtitle
                                                      : strings.scanningSubtitle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _RankLabelColumn(
                            boardSize: displayedBoard.boardSize,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _FileHeaderRow(boardSize: displayedBoard.boardSize),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Compact Tactical Vision Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _LegendDot(
                color: AppColors.cyan.withValues(alpha: 0.55),
                borderColor: AppColors.cyan,
                label: strings.legendSlider,
                isCircle: false,
              ),
              _LegendDot(
                color: AppColors.indigo.withValues(alpha: 0.55),
                borderColor: const Color(0xFF818CF8),
                label: strings.legendKing,
                isCircle: false,
              ),
              _LegendDot(
                color: AppColors.amber,
                borderColor: AppColors.amber,
                label: strings.legendEscape,
                isCircle: true,
              ),
              _LegendDot(
                color: Colors.transparent,
                borderColor: AppColors.coral,
                label: strings.legendCheck,
                isCircle: true,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Live Legality / Checkmate / Error Banner
          _BoardStatusBanner(
            strings: strings,
            validation: setup.validation,
            isCheckmate: isMate,
            solverError: solver.errorMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildSquaresGrid({
    required BoardState board,
    required bool isEditable,
    required double cellSize,
  }) {
    final n = board.boardSize;
    return Column(
      children: List<Widget>.generate(n, (row) {
        return Expanded(
          child: Row(
            children: List<Widget>.generate(n, (col) {
              final pos = GridPos(row, col);
              final isDark = (row + col).isOdd;
              final isHovered = _hoveredDropSquare == pos;

              return Expanded(
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (details) {
                    if (!isEditable) return false;
                    if (_hoveredDropSquare != pos) {
                      setState(() => _hoveredDropSquare = pos);
                    }
                    return true;
                  },
                  onLeave: (_) {
                    if (_hoveredDropSquare == pos) {
                      setState(() => _hoveredDropSquare = null);
                    }
                  },
                  onAcceptWithDetails: (details) {
                    setState(() => _hoveredDropSquare = null);
                    ref
                        .read(boardSetupProvider.notifier)
                        .dragPieceTo(details.data, pos);
                  },
                  builder: (context, _, __) {
                    return GestureDetector(
                      key: ValueKey<String>('sq_${pos.toAlgebraic(boardSize: n)}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: isEditable
                          ? () => ref
                              .read(boardSetupProvider.notifier)
                              .handleSquareTap(pos)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.squareDark
                              : AppColors.squareLight,
                          border: isHovered
                              ? Border.all(color: AppColors.cyan, width: 2.2)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  List<Widget> _buildGlidingPieces({
    required double cellSize,
    required bool isEditable,
    required int selectedIdx,
  }) {
    return _tracked.map((tracked) {
      final p = tracked.piece;
      final isSelected = isEditable && tracked.boardIndex == selectedIdx;
      final token = ChessPieceToken(
        type: p.type,
        size: cellSize,
        isSelected: isSelected,
      );

      final interactiveChild = isEditable
          ? DragTarget<int>(
              onWillAcceptWithDetails: (details) =>
                  details.data != tracked.boardIndex,
              onAcceptWithDetails: (details) {
                setState(() => _hoveredDropSquare = null);
                ref
                    .read(boardSetupProvider.notifier)
                    .dragPieceTo(details.data, p.pos);
              },
              builder: (context, _, __) {
                return Draggable<int>(
                  data: tracked.boardIndex,
                  maxSimultaneousDrags: 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.15,
                      child: ChessPieceToken(
                        type: p.type,
                        size: cellSize,
                        isSelected: true,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.28, child: token),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref
                        .read(boardSetupProvider.notifier)
                        .selectPieceIndex(tracked.boardIndex),
                    child: token,
                  ),
                );
              },
            )
          : IgnorePointer(child: token);

      return AnimatedPositioned(
        key: ValueKey<int>(tracked.slotId),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        left: p.col * cellSize,
        top: p.row * cellSize,
        width: cellSize,
        height: cellSize,
        child: interactiveChild,
      );
    }).toList(growable: false);
  }
}

class _FileHeaderRow extends StatelessWidget {
  const _FileHeaderRow({required this.boardSize});

  final int boardSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List<Widget>.generate(boardSize, (col) {
          final file = String.fromCharCode('a'.codeUnitAt(0) + col);
          return Expanded(
            child: Center(
              child: Text(
                file,
                key: ValueKey<String>('coord_file_$file'),
                style: AppTypography.mono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDim,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RankLabelColumn extends StatelessWidget {
  const _RankLabelColumn({required this.boardSize});

  final int boardSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      child: AspectRatio(
        aspectRatio: 1 / boardSize,
        child: Column(
          children: List<Widget>.generate(boardSize, (row) {
            final rank = boardSize - row;
            return Expanded(
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTypography.mono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDim,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.borderColor,
    required this.label,
    required this.isCircle,
  });

  final Color color;
  final Color borderColor;
  final String label;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _BoardStatusBanner extends StatelessWidget {
  const _BoardStatusBanner({
    required this.strings,
    required this.validation,
    required this.isCheckmate,
    required this.solverError,
  });

  final AppStrings strings;
  final PositionValidation validation;
  final bool isCheckmate;
  final String? solverError;

  @override
  Widget build(BuildContext context) {
    final StatusBannerTone tone;
    final IconData icon;
    final Color iconColor;
    final String message;

    if (isCheckmate) {
      tone = StatusBannerTone.mate;
      icon = Icons.emoji_events_rounded;
      iconColor = AppColors.amber;
      message = strings.statusCheckmateBanner;
    } else if (!validation.isValid) {
      tone = StatusBannerTone.error;
      icon = Icons.warning_amber_rounded;
      iconColor = AppColors.coral;
      message = (strings.isAr ? validation.messagesAr : validation.messagesEn)
          .first;
    } else if (solverError != null && solverError!.isNotEmpty) {
      tone = StatusBannerTone.info;
      icon = Icons.info_outline_rounded;
      iconColor = AppColors.amber;
      message = solverError!;
    } else {
      tone = StatusBannerTone.ok;
      icon = Icons.check_circle_outline_rounded;
      iconColor = AppColors.cyan;
      message = strings.statusLegalReady;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: GlassDecorations.statusBanner(tone),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
