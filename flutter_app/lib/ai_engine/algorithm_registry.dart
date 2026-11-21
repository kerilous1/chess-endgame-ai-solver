/// ai_engine/algorithm_registry.dart
/// ===================================
/// Single dynamic plug-and-play registry of all search algorithms in the app.
///
/// ============================================================================
/// HOW TO ADD A NEW SEARCH ALGORITHM IN 2 STEPS (WITHOUT TOUCHING ANY UI CODE):
/// ============================================================================
/// 1. Drop a new file inside `lib/ai_engine/algorithms/`, e.g. `greedy_algorithm.dart`,
///    creating a `class GreedyAlgorithm extends SearchAlgorithm { ... }`.
/// 2. Import it below and add 1 line (`const GreedyAlgorithm(),`) to
///    `AlgorithmRegistry.registeredAlgorithms`.
///
/// Every UI screen — Algorithm Selector, Category Filters, Animated Explainer,
/// Single Solver, and the Benchmark Comparison Dashboard — reads exclusively from
/// `AlgorithmRegistry.all`, so your new algorithm appears automatically!
/// ============================================================================
library;

import 'algorithms/astar_algorithm.dart';
import 'algorithms/bfs_algorithm.dart';
import 'algorithms/dfs_algorithm.dart';
import 'base_algorithm.dart';

/// Central plug-and-play registry read by both background Isolates and the UI.
abstract final class AlgorithmRegistry {
  /// Master list of active algorithms. Add new instances here!
  static const List<SearchAlgorithm> registeredAlgorithms = <SearchAlgorithm>[
    BfsAlgorithm(),
    DfsAlgorithm(),
    AStarAlgorithm(),
  ];

  /// Unmodifiable view of every registered [SearchAlgorithm] in display order.
  static List<SearchAlgorithm> get all => registeredAlgorithms;

  /// Looks up a registered algorithm by its [SearchAlgorithm.id].
  static SearchAlgorithm byId(String id) {
    final found = tryById(id);
    if (found == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Unknown algorithm id. Registered: ${all.map((a) => a.id).join(", ")}',
      );
    }
    return found;
  }

  /// Returns the matching [SearchAlgorithm], or `null` if not registered.
  static SearchAlgorithm? tryById(String id) {
    final normalized = id.trim().toLowerCase();
    for (final algo in all) {
      if (algo.id == normalized) return algo;
    }
    return null;
  }

  /// Returns all registered algorithms belonging to [category].
  static List<SearchAlgorithm> byCategory(AlgorithmCategory category) =>
      all.where((algo) => algo.category == category).toList(growable: false);

  /// Distinct categories that currently contain at least one algorithm.
  static List<AlgorithmCategory> get activeCategories => AlgorithmCategory.values
      .where((cat) => all.any((algo) => algo.category == cat))
      .toList(growable: false);
}
