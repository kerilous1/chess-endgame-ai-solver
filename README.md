<div align="center">

# 6×6 Chess Endgame AI Search Solver & Visualizer

**A 100% offline Flutter & Pure Dart mobile/desktop application with a plug-and-play AI search engine for solving, visualizing, and benchmarking 6×6 chess endgames.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%3E%3D3.4-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-2.6.1-2DD4BF?style=for-the-badge)
![Offline-First](https://img.shields.io/badge/Offline--First-100%25%20Local-F59E0B?style=for-the-badge)
![Bilingual](https://img.shields.io/badge/Localization-AR%20%7C%20EN-A78BFA?style=for-the-badge)

</div>

---

## Screenshots Showcase

> Place rendered screenshots in `docs/screenshots/` to display the live workspace previews below.

| Interactive 6×6 Board & Setup | Algorithm Explainer & Telemetry |
| :---: | :---: |
| ![Interactive 6x6 Board Setup](docs/screenshots/board_setup.png) | ![Algorithm Explainer and Telemetry](docs/screenshots/explainer_telemetry.png) |
| **Benchmark Dashboard & Charts** | **Arabic RTL UI & LTR Chessboard** |
| ![Benchmark Dashboard](docs/screenshots/benchmark_dashboard.png) | ![Arabic RTL Interface](docs/screenshots/arabic_rtl.png) |

---

## Overview & AI Problem Formulation

The **6×6 Chess Endgame AI Search Solver & Visualizer** models forced checkmate planning on a reduced 6×6 chessboard (`a6`–`f1`). It supports five endgame modes out of the box—**KRK** (King + Rook vs. King), **KQK** (King + Queen vs. King), **KRRK** (King + Two Rooks vs. King), **KRBK** (King + Rook + Bishop vs. King), and **Custom** setups—while running every search algorithm completely offline on-device.

| Problem Component | Formulation |
| :--- | :--- |
| **Agent Type** | Deterministic, fully observable, goal-based / informed single-agent search (White) operating against a deterministic opponent policy (`BlackPolicy.centerSeeking` or `BlackPolicy.evasive`). |
| **Initial State** | Any legal 6×6 `BoardState` validated by `MovesEngine.validatePosition()`: in-bounds pieces, zero overlaps, one king per side, Chebyshev king separation > 1, Black not initially in check, and sufficient mating material. |
| **State Space** | Canonicalized legal 6×6 board configurations (`BoardState.stateKey` enforces deterministic piece ordering to deduplicate symmetric states such as twin rooks in `KRRK`). |
| **Actions / Transition Model** | `MovesEngine.getSuccessors()` pairs each legal White move with immediate checkmate or Black's deterministic king reply (capturing undefended pieces first, otherwise applying `centerSeeking` or `evasive`), pruning stalemates and material blunders while attaching `TacticalTag` metadata. |
| **Goal Test** | `MovesEngine.isCheckmate(state)` — verified when the Black King is in check (`isCheck`) and `getBlackKingMoves(state)` is empty (with X-ray attack projection enabled via `ignoreBlackKing: true`). |
| **Path Cost** | Uniform cost of `1` per White move (`g(n)` increments by `1` for each White-move + Black-reply transition). |
| **Admissible Heuristic** $h(n)$ | `endgameHeuristic(state)` returns `0.0` at checkmate; `max(1, d_edge + 1, ⌈(d_kings - 1) / 2⌉)` (`defaultHeuristicFormula`) for single-attacker endgames (`KRK`, `KQK`); and a safe admissible lower bound of `1.0` for multi-attacker endgames (`KRRK`, `KRBK`, `Custom`). |

---

## Core Features

- **Interactive 6×6 Board & Drag/Tap Setup:** Switch between `KRK`, `KQK`, `KRRK`, `KRBK`, and `Custom` modes, load curated presets, generate guaranteed-legal random positions via rejection sampling, place or drag pieces directly on the board with real-time legality validation, and keep algebraic coordinates (`a`–`f`, `1`–`6`) strictly LTR even in Arabic RTL mode.
- **Tactical Vision & Smooth Playback:** Renders crisp inline SVG vector pieces (`WK`, `WQ`, `WR`, `WB`, `BK`), White attack-zone overlays, pulsing Black King escape squares, check/checkmate rings, animated dashed move arrows, `AnimatedPositioned` gliding transitions, an interactive playback scrubber with variable speed controls, and desktop keyboard shortcuts (`←`, `→`, `Space`, `Home`, `End`).
- **Live Animated Algorithm Explainers & Telemetry:** Includes `AlgorithmExplainerPainter` supporting 7 exploration animation presets, plain-language tactical narration via `buildTacticalStory`, and `HeuristicInspectorCard` displaying live `g(n)`, `h(n)`, `f(n)` values, Black King edge distance, and mate proximity progress.
- **Benchmark Dashboard with Tap-to-Replay:** Executes all registered algorithms in a single batch via `AiEngineRunner.benchmarkAllInBackground`, highlights winners across shortest path, fastest runtime, and fewest expanded nodes, summarizes findings automatically, plots animated horizontal comparison charts, and lets users tap any row to load that exact solution onto the board for step-by-step replay.
- **100% Offline Background Execution:** Runs every solve and benchmark inside `Isolate.run` (`AiEngineRunner`, with microtask fallback on Web) alongside bundled offline-safe font configuration—no Python backend, HTTP server, or internet connection required.
- **Full Arabic (RTL) & English (LTR) Localization:** Seamlessly toggles UI directionality and strings across a responsive dual-column workspace on desktop/tablet and a 3-tab mobile layout (`WorkspaceScreen`).

---

## Tech Stack & Architecture

| Technology | Version / Spec | Purpose |
| :--- | :--- | :--- |
| **Flutter** | `Material 3` + `flutter_localizations` | Cross-platform desktop & mobile UI framework with native RTL/LTR localization support |
| **Dart** | `>=3.4.0 <4.0.0` | Pure Dart AI search engine, isolates, and application logic |
| **flutter_riverpod** | `^2.6.1` | Reactive state management across settings, board setup, solver, playback, and benchmarks |
| **flutter_svg** | `^2.0.10+1` | Crisp inline SVG chess piece rendering (`WK`, `WQ`, `WR`, `WB`, `BK`) |
| **google_fonts** | `^6.2.1` | Offline-configured `Cairo` (Arabic RTL), `Plus Jakarta Sans` (English UI), and `JetBrains Mono` (metrics) |
| **intl** | `any` | Locale and number formatting utilities |
| **flutter_test & flutter_lints** | `^5.0.0` | Automated unit/widget test suite and strict static analysis |

### Feature-First Clean Architecture

- **Zero-Dependency Pure Dart Engine (`lib/ai_engine/`):** Contains zero `package:flutter` imports so chess rules, move generation, heuristics, and search algorithms execute safely inside background `Isolate.run` workers and standalone Dart tests.
- **Reactive Core & Decoupled UI (`lib/core/`, `lib/features/`):** Riverpod providers and UI screens read enabled algorithms dynamically from `AlgorithmRegistry.all`, ensuring new search algorithms appear automatically in filter pills, selector cards, explainer animations, and benchmarks without modifying UI code.

---

## Project Structure

```text
chess_ai_solver/
├── README.md                                  # Portfolio project documentation
├── TEAM_GUIDE.md                              # Arabic engineering handbook & team onboarding guide
└── flutter_app/
    ├── pubspec.yaml                           # Dependencies, typography, and Dart SDK constraints
    ├── lib/
    │   ├── main.dart                          # App entry point, offline font config, ProviderScope
    │   ├── app.dart                           # MaterialApp, AR/EN locale binding, Muted Dark Neon theme
    │   ├── ai_engine/                         # 100% Pure Dart search engine (Isolate-safe)
    │   │   ├── ai_engine.dart                 # Barrel export for the AI engine layer
    │   │   ├── search_models.dart             # BoardState, Piece, ChessMove, SearchResult, MinHeap
    │   │   ├── moves_engine.dart              # 6×6 rules, X-ray attacks, black policies, getSuccessors
    │   │   ├── heuristics.dart                # Admissible endgameHeuristic and defaultHeuristicFormula
    │   │   ├── base_algorithm.dart            # SearchAlgorithm contract, SearchTelemetry, path builder
    │   │   ├── algorithm_registry.dart        # Central registry consumed dynamically by the UI
    │   │   ├── isolate_runner.dart            # AiEngineRunner for Isolate solve & benchmark execution
    │   │   └── algorithms/
    │   │       ├── bfs_algorithm.dart         # Breadth-First Search (Queue, shortest-path optimal)
    │   │       ├── dfs_algorithm.dart         # Depth-First Search (depth-capped LIFO Stack)
    │   │       └── astar_algorithm.dart       # A* Search (MinHeap ordered by f = g + h)
    │   ├── core/                              # Shared styling, localization, widgets, and state
    │   │   ├── l10n/
    │   │   │   └── app_localizations.dart     # Bilingual AR/EN strings & buildTacticalStory builder
    │   │   ├── providers/
    │   │   │   ├── app_settings_provider.dart # Language, tactical overlay toggle, BlackPolicy, maxNodes
    │   │   │   ├── board_setup_provider.dart  # Endgame presets, custom pieces, drag/tap validation
    │   │   │   ├── solver_provider.dart       # Dynamic algorithm selection & background solve state
    │   │   │   ├── playback_provider.dart     # Step playback state, auto-play timer, speed controls
    │   │   │   ├── benchmark_provider.dart    # Batch compare execution & tap-to-inspect loading
    │   │   │   └── providers.dart             # Barrel export for Riverpod providers
    │   │   ├── theme/
    │   │   │   ├── app_colors.dart            # Cyber-Slate & Muted Neon color tokens
    │   │   │   ├── app_theme.dart             # Offline-safe ThemeData and text hierarchy
    │   │   │   ├── glass_decorations.dart     # Frosted glass borders, badges, and status banners
    │   │   │   └── theme.dart                 # Barrel export for theme utilities
    │   │   └── widgets/
    │   │       ├── ambient_background.dart    # Subtle corner radial glow canvas
    │   │       ├── animated_metric_chip.dart  # Animated count-up metric chips and cards
    │   │       ├── core_widgets.dart          # Barrel export for shared UI widgets
    │   │       ├── glass_card.dart            # Frosted GlassCard container and StepBadge
    │   │       ├── neon_button.dart           # Styled CTA buttons (Amber, Cyan, Violet, Ghost)
    │   │       └── scanning_loader.dart       # Radar scanning overlay and shimmer loading bars
    │   └── features/                          # Feature-first UI modules
    │       ├── benchmark/                     # BenchmarkDashboard, BenchmarkBarChart, barrel
    │       ├── board_setup/                   # ChessBoardWidget, SVGs, overlays, BoardSetupPanel
    │       ├── explainer/                     # AlgorithmExplainerCard, AlgorithmExplainerPainter
    │       ├── playback/                      # PlaybackBar, PlaybackKeyboardScope
    │       ├── solver/                        # Dynamic AlgorithmSelectorPanel
    │       ├── telemetry/                     # HeuristicInspectorCard, TacticalStoryCard
    │       └── workspace/                     # Responsive WorkspaceScreen, TopAppBar, GuideModal
    └── test/                                  # Unit, provider, widget, and integration tests
        ├── ai_engine_test.dart                # 6×6 chess rules, legality checks, BFS/DFS/A* proofs
        ├── core_layer_test.dart               # Theme, AR/EN strings, Riverpod solver & benchmark tests
        ├── board_and_playback_test.dart       # Board coordinates, piece gliding, playback controls
        └── widget_test.dart                   # Full end-to-end app solve & UI smoke tests
```

---

## Implemented Algorithms & Extensibility

### Currently Registered Search Algorithms

| Algorithm (`id`) | Category | Data Structure | Evaluation / Expansion Rule | Time Complexity | Space Complexity | Complete | Optimal |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **BFS** (`bfs`) | Uninformed | FIFO Queue (`Queue`) | Expands frontier level by level: `level(n) = depth(n)` | `O(b^d)` | `O(b^d)` | Yes | Yes |
| **DFS** (`dfs`) | Uninformed | LIFO Stack (`List`, depth-capped) | Expands deepest frontier node up to `depthCap` (`<= 16`) | `O(b^m)` | `O(b · m)` | No | No |
| **A\*** (`astar`) | Informed | Binary Min-Heap (`MinHeap`) | Expands lowest `f(n) = g(n) + h(n)` (ties broken by `h(n)`) | `O(b^d)` | `O(b^d)` | Yes | Yes |

> All UI selectors, category pills, animated explainers, and benchmark tables read dynamically from `AlgorithmRegistry.all`—adding a new solver requires **zero UI changes**.

### Adding a New Algorithm in 2 Steps

The architecture is ready for drop-in additions such as **Greedy Best-First**, **Uniform Cost Search (UCS)**, **IDA\***, or **Hill Climbing**:

1. **Create your solver class in `lib/ai_engine/algorithms/`** extending `SearchAlgorithm` and implementing `solve(...)` using `MovesEngine.getSuccessors(...)` and `reconstructPath(...)`:

   ```dart
   import '../base_algorithm.dart';
   import '../moves_engine.dart';
   import '../search_models.dart';

   class GreedyAlgorithm extends SearchAlgorithm {
     const GreedyAlgorithm();

     @override String get id => 'greedy';
     @override String get nameEn => 'Greedy Best-First Search';
     @override String get nameAr => 'البحث الجشع لأفضل أولوية';
     @override AlgorithmCategory get category => AlgorithmCategory.informed;
     @override String get dataStructureEn => 'Min-Heap (h only)';
     @override String get dataStructureAr => 'رتل أولوية حسب h(n)';
     @override String get formula => 'f(n) = h(n)';
     @override String get timeComplexity => 'O(b^m)';
     @override String get spaceComplexity => 'O(b^m)';
     @override bool get isComplete => false;
     @override bool get isOptimal => false;
     @override String get shortDescEn => 'Expands the node with lowest h(n) first.';
     @override String get shortDescAr => 'يفتح العقدة ذات أقل تقدير h(n) مباشرة.';
     @override ExplainerAnimationType get explainerAnimationType =>
         ExplainerAnimationType.greedyHeuristicWave;

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

       // Expand states using MovesEngine.getSuccessors(...) and return reconstructPath(...)
       return buildFailedResult(telemetry, message: 'Not implemented yet');
     }
   }
   ```

2. **Register it in `lib/ai_engine/algorithm_registry.dart`:**

   ```dart
   static const List<SearchAlgorithm> registeredAlgorithms = <SearchAlgorithm>[
     BfsAlgorithm(),
     DfsAlgorithm(),
     AStarAlgorithm(),
     GreedyAlgorithm(), // Automatically appears across the entire app
   ];
   ```

---

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/kerilous1/chess-endgame-ai-solver.git

# 2. Enter the Flutter project directory
cd chess-endgame-ai-solver/flutter_app

# 3. Install dependencies
flutter pub get

# 4. Run on your connected mobile device or emulator
flutter run

# 5. Or run directly on Windows Desktop
flutter run -d windows

# 6. Run static analysis & automated tests
flutter analyze
flutter test

# 7. Build a standalone offline release APK
flutter build apk --release
```

---

## Team & Documentation

- **Engineering Handbook:** See [`TEAM_GUIDE.md`](./TEAM_GUIDE.md) for a concise Arabic guide covering every UI module, the complete `lib/ai_engine/` API reference, and step-by-step instructions for implementing additional search algorithms.

### AIM 315 — Artificial Intelligence Project Contributors

| Member | Role | Assigned Algorithms / Modules | GitHub |
| :--- | :--- | :--- | :--- |
| **Contributor 1** | Lead Architect, Chess Rules & UI Visualizer | `moves_engine.dart`, `A*`, Flutter Workspace | `[@username](https://github.com/username)` |
| **Contributor 2** | Search Algorithms & Benchmarking | `BFS`, `DFS`, Future Algorithms (`Greedy` / `UCS` / `IDA*`) | `[@username](https://github.com/username)` |
| **Contributor 3** | Testing, Heuristics & Documentation | Validation Suite, Telemetry, `TEAM_GUIDE.md` | `[@username](https://github.com/username)` |
