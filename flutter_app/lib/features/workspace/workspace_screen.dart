/// features/workspace/workspace_screen.dart
/// ==========================================
/// Main responsive application workspace adapting seamlessly between:
/// - **Desktop / Tablet (`>= 960px`)**: Polished 2-column grid (Setup + Board
///   + Playback on the start side; Dynamic Algorithm Selector + Animated
///   Explainer + Tactical Story + Heuristic Inspector on the end side), with
///   the full-width Benchmark Dashboard beneath.
/// - **Mobile (`< 960px`)**: Clean `SafeArea` 3-tab navigation (`Board & Solve`
///   | `Analysis` | `Benchmark`) preventing cramped scrolling or horizontal
///   overflow on small phones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import '../benchmark/benchmark.dart';
import '../board_setup/board_setup.dart';
import '../explainer/explainer.dart';
import '../playback/playback.dart';
import '../solver/solver.dart';
import '../telemetry/telemetry.dart';
import 'widgets/top_app_bar.dart';

/// Root responsive workspace screen.
class WorkspaceScreen extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceScreen].
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  int _mobileTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: AmbientCyberBackground(
        child: SafeArea(
          child: PlaybackKeyboardScope(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;
                if (isDesktop) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout(
                  tabLabels: <String>[
                    strings.tabWorkspace,
                    strings.tabAnalysis,
                    strings.tabBenchmark,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const WorkspaceTopBar(),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const <Widget>[
                        InteractiveChessBoard(),
                        SizedBox(height: 16),
                        PlaybackBar(),
                        SizedBox(height: 16),
                        BoardSetupPanel(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const <Widget>[
                        AlgorithmSelectorPanel(),
                        SizedBox(height: 16),
                        AlgorithmExplainerCard(),
                        SizedBox(height: 16),
                        TacticalStoryCard(),
                        SizedBox(height: 16),
                        HeuristicInspectorCard(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const BenchmarkDashboard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout({required List<String> tabLabels}) {
    final tabIcons = const <IconData>[
      Icons.grid_on_rounded,
      Icons.psychology_rounded,
      Icons.bar_chart_rounded,
    ];

    final activeBody = switch (_mobileTabIndex) {
      1 => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const <Widget>[
            AlgorithmExplainerCard(),
            SizedBox(height: 14),
            TacticalStoryCard(),
            SizedBox(height: 14),
            HeuristicInspectorCard(),
          ],
        ),
      2 => BenchmarkDashboard(
          onInspectLoaded: () => setState(() => _mobileTabIndex = 0),
        ),
      _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const InteractiveChessBoard(),
            const SizedBox(height: 14),
            const PlaybackBar(),
            const SizedBox(height: 14),
            AlgorithmSelectorPanel(
              onCompareAllTriggered: () =>
                  setState(() => _mobileTabIndex = 2),
            ),
            const SizedBox(height: 14),
            const BoardSetupPanel(),
          ],
        ),
    };

    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: WorkspaceTopBar(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: GlassDecorations.card(
              borderRadius: 14,
              backgroundColor: AppColors.glassSurfaceStrong,
            ),
            child: Row(
              children: List<Widget>.generate(3, (idx) {
                final active = _mobileTabIndex == idx;
                return Expanded(
                  child: InkWell(
                    key: ValueKey<String>('mobile_tab_$idx'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _mobileTabIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.cyan.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: active
                            ? Border.all(
                                color: AppColors.cyan.withValues(alpha: 0.55),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            tabIcons[idx],
                            size: 16,
                            color: active
                                ? AppColors.cyan
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              tabLabels[idx],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 22),
            child: activeBody,
          ),
        ),
      ],
    );
  }
}
