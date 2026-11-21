/// core/providers/solver_provider.dart
/// =====================================
/// Riverpod state controller driving single-algorithm search execution via
/// [AiEngineRunner.solveInBackground] (`Isolate.run`).
///
/// Reads available algorithms dynamically from `AlgorithmRegistry.all` — adding
/// new algorithms to the registry automatically exposes them here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_engine/ai_engine.dart';
import 'app_settings_provider.dart';
import 'board_setup_provider.dart';
import 'playback_provider.dart';

/// Immutable state for algorithm selection and single-solve execution.
class SolverState {
  /// Creates a [SolverState].
  const SolverState({
    required this.selectedAlgorithmId,
    this.activeCategoryFilter,
    this.isSolving = false,
    this.result,
    this.errorMessage,
  });

  /// Canonical ID of the selected algorithm inside [AlgorithmRegistry.all].
  final String selectedAlgorithmId;

  /// Optional category filter (`null` shows all registered algorithms).
  final AlgorithmCategory? activeCategoryFilter;

  /// True while `Isolate.run` is executing the selected search algorithm.
  final bool isSolving;

  /// Most recent search result, or `null` before running / after board edits.
  final SearchResult? result;

  /// Localized failure message if validation or search did not produce mate.
  final String? errorMessage;

  /// Resolves the active [SearchAlgorithm] dynamically from [AlgorithmRegistry].
  SearchAlgorithm get selectedAlgorithm =>
      AlgorithmRegistry.tryById(selectedAlgorithmId) ??
      AlgorithmRegistry.all.first;

  /// Algorithms matching [activeCategoryFilter] (all registered if `null`).
  List<SearchAlgorithm> get visibleAlgorithms => activeCategoryFilter == null
      ? AlgorithmRegistry.all
      : AlgorithmRegistry.byCategory(activeCategoryFilter!);

  /// Returns an updated copy of [SolverState].
  SolverState copyWith({
    String? selectedAlgorithmId,
    AlgorithmCategory? activeCategoryFilter,
    bool clearCategoryFilter = false,
    bool? isSolving,
    SearchResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SolverState(
      selectedAlgorithmId: selectedAlgorithmId ?? this.selectedAlgorithmId,
      activeCategoryFilter: clearCategoryFilter
          ? null
          : (activeCategoryFilter ?? this.activeCategoryFilter),
      isSolving: isSolving ?? this.isSolving,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Runs single searches off the UI thread and updates playback automatically.
class SolverNotifier extends Notifier<SolverState> {
  @override
  SolverState build() {
    final defaultId = AlgorithmRegistry.all.isNotEmpty
        ? AlgorithmRegistry.all.first.id
        : 'bfs';
    return SolverState(selectedAlgorithmId: defaultId);
  }

  /// Selects a registered algorithm by [algorithmId] and clears stale results.
  void selectAlgorithm(String algorithmId) {
    if (AlgorithmRegistry.tryById(algorithmId) == null) return;
    if (state.selectedAlgorithmId == algorithmId) return;
    ref.read(playbackProvider.notifier).reset();
    state = state.copyWith(
      selectedAlgorithmId: algorithmId,
      clearResult: true,
      clearError: true,
    );
  }

  /// Filters the algorithm selector chips by [category] (`null` = All).
  void setCategoryFilter(AlgorithmCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(activeCategoryFilter: category);
    }
  }

  /// Executes the currently selected algorithm in a background Dart Isolate.
  Future<void> runSelectedAlgorithm() async {
    if (state.isSolving) return;

    final boardState = ref.read(boardSetupProvider);
    final settings = ref.read(appSettingsProvider);
    final strings = ref.read(appStringsProvider);

    if (!boardState.validation.isValid) {
      final msg = (strings.isAr
              ? boardState.validation.messagesAr
              : boardState.validation.messagesEn)
          .first;
      state = state.copyWith(errorMessage: msg, clearResult: true);
      return;
    }

    final startBoard = boardState.board;
    final algoId = state.selectedAlgorithmId;

    ref.read(playbackProvider.notifier).reset();
    state = state.copyWith(
      isSolving: true,
      clearResult: true,
      clearError: true,
    );

    try {
      final res = await AiEngineRunner.solveInBackground(
        algorithmId: algoId,
        start: startBoard,
        maxNodes: settings.maxNodes,
        maxDepth: settings.maxDepth,
        blackPolicy: settings.blackPolicy,
      );

      // Guard against stale async completion if user edited the board mid-solve.
      if (ref.read(boardSetupProvider).board.stateKey != startBoard.stateKey) {
        return;
      }

      if (res.isSolved) {
        ref.read(playbackProvider.notifier).loadSolution(startBoard, res.path);
        state = state.copyWith(
          isSolving: false,
          result: res,
          clearError: true,
        );
      } else {
        final errorMsg = switch (res.status) {
          SearchStatus.nodeCapReached => strings.nodeCapErrorMsg,
          SearchStatus.failed =>
            res.message.isNotEmpty ? res.message : strings.noSolutionErrorMsg,
          SearchStatus.solved => null,
        };
        state = state.copyWith(
          isSolving: false,
          result: res,
          errorMessage: errorMsg,
        );
      }
    } catch (err) {
      state = state.copyWith(
        isSolving: false,
        errorMessage: err.toString(),
      );
    }
  }

  /// Loads a result produced by the Benchmark suite straight into the player.
  void loadExternalResult(SearchResult result, BoardState initialBoard) {
    if (AlgorithmRegistry.tryById(result.algorithmId) != null) {
      state = state.copyWith(
        selectedAlgorithmId: result.algorithmId,
        result: result,
        clearError: true,
        isSolving: false,
      );
    } else {
      state = state.copyWith(
        result: result,
        clearError: true,
        isSolving: false,
      );
    }

    if (result.isSolved) {
      ref.read(playbackProvider.notifier).loadSolution(initialBoard, result.path);
    } else {
      ref.read(playbackProvider.notifier).reset();
    }
  }

  /// Resets the current solve result and errors (called on board edits).
  void clearResult() {
    if (state.result == null && state.errorMessage == null && !state.isSolving) {
      return;
    }
    state = state.copyWith(
      isSolving: false,
      clearResult: true,
      clearError: true,
    );
  }
}

/// Primary solver controller provider.
final solverProvider =
    NotifierProvider<SolverNotifier, SolverState>(SolverNotifier.new);

/// Convenience provider exposing the active [SearchAlgorithm] metadata.
final selectedAlgorithmProvider = Provider<SearchAlgorithm>((ref) {
  return ref.watch(solverProvider.select((s) => s.selectedAlgorithm));
});
