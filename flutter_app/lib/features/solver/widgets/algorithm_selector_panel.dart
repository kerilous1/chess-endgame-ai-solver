/// features/solver/widgets/algorithm_selector_panel.dart
/// =======================================================
/// Step 2 Dynamic Algorithm Selector & Strategy Control Panel.
///
/// STRICT PLUG-AND-PLAY RULE:
/// Reads every available algorithm and category dynamically from
/// `AlgorithmRegistry.all` and `AlgorithmRegistry.activeCategories` — never
/// hardcodes algorithm names, so adding new algorithms automatically populates
/// the category filters, cards, explainer, and benchmark dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';

/// Dynamic search algorithm picker, heuristic/policy controls, and Solve CTAs.
class AlgorithmSelectorPanel extends ConsumerWidget {
  /// Creates an [AlgorithmSelectorPanel].
  const AlgorithmSelectorPanel({
    super.key,
    this.onCompareAllTriggered,
  });

  /// Optional callback invoked right after triggering Compare All (used by
  /// mobile tabbed layout to switch directly to the Benchmark tab).
  final VoidCallback? onCompareAllTriggered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final setup = ref.watch(boardSetupProvider);
    final solver = ref.watch(solverProvider);
    final benchmark = ref.watch(benchmarkProvider);

    final solverNotifier = ref.read(solverProvider.notifier);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final benchmarkNotifier = ref.read(benchmarkProvider.notifier);

    final allAlgorithms = AlgorithmRegistry.all;
    final categories = AlgorithmRegistry.activeCategories;
    final visible = solver.visibleAlgorithms;
    final boardValid = setup.validation.isValid;

    return GlassCard(
      stepNumber: 2,
      title: strings.solverCardTitle,
      badgeTone: StepBadgeTone.violet,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: GlassDecorations.pill(
          active: true,
          accent: AppColors.violet,
        ),
        child: Text(
          '${allAlgorithms.length}',
          style: AppTypography.mono(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.violet,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1) Dynamic Category Filter Pills (automatically adapts to Registry)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _CategoryFilterPill(
                label: '${strings.allCategoriesLabel} (${allAlgorithms.length})',
                active: solver.activeCategoryFilter == null,
                accent: AppColors.cyan,
                onTap: () => solverNotifier.setCategoryFilter(null),
              ),
              ...categories.map((cat) {
                final count = AlgorithmRegistry.byCategory(cat).length;
                return _CategoryFilterPill(
                  label: '${strings.categoryName(cat)} ($count)',
                  active: solver.activeCategoryFilter == cat,
                  accent: AppColors.categoryAccent(cat),
                  onTap: () => solverNotifier.setCategoryFilter(cat),
                );
              }),
            ],
          ),

          const SizedBox(height: 12),

          // 2) Selectable Algorithm Cards
          Column(
            children: visible.map((algo) {
              final isSelected = algo.id == solver.selectedAlgorithmId;
              final accent = AppColors.categoryAccent(algo.category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AlgorithmOptionCard(
                  key: ValueKey<String>('algo_card_${algo.id}'),
                  algorithm: algo,
                  title: strings.algorithmName(algo),
                  categoryLabel: strings.categoryName(algo.category),
                  description: strings.algorithmDesc(algo),
                  stubLabel: strings.notImplementedBadge,
                  optimalLabel: strings.optimalLabel,
                  accent: accent,
                  isSelected: isSelected,
                  onTap: () => solverNotifier.selectAlgorithm(algo.id),
                ),
              );
            }).toList(growable: false),
          ),

          const SizedBox(height: 6),

          // 3) Strategy Control: Black King Policy Dropdown
          _StrategyDropdown<BlackPolicy>(
            label: strings.blackPolicyLabel,
            value: settings.blackPolicy,
            items: BlackPolicy.values
                .map(
                  (p) => DropdownMenuItem<BlackPolicy>(
                    value: p,
                    child: Text(
                      strings.blackPolicyName(p),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (val) {
              if (val != null) settingsNotifier.setBlackPolicy(val);
            },
          ),

          const SizedBox(height: 10),

          // 4) Node Expansion Budget Selector
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            runSpacing: 6,
            children: <Widget>[
              Text(
                strings.nodeCapLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              ...<int>[10000, 50000, 150000].map((cap) {
                final active = settings.maxNodes == cap;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => settingsNotifier.setMaxNodes(cap),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: GlassDecorations.pill(
                      active: active,
                      accent: AppColors.sky,
                      inactiveColor: AppColors.glassSurfaceStrong,
                    ),
                    child: Text(
                      '${cap ~/ 1000}k',
                      style: AppTypography.mono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 14),

          // 5) Primary Action CTAs: Run AI Solver & Compare All
          LayoutBuilder(
            builder: (context, constraints) {
              final stackButtons = constraints.maxWidth < 340;
              final runBtn = NeonButton(
                key: const ValueKey<String>('run_solver_btn'),
                label: strings.runSolverCta,
                icon: Icons.bolt_rounded,
                variant: NeonButtonVariant.primaryAmber,
                expand: true,
                isLoading: solver.isSolving,
                onPressed: (boardValid && !benchmark.isRunning)
                    ? solverNotifier.runSelectedAlgorithm
                    : null,
              );
              final compareBtn = NeonButton(
                key: const ValueKey<String>('compare_all_btn'),
                label: strings.compareAllCta,
                icon: Icons.bar_chart_rounded,
                variant: NeonButtonVariant.cyan,
                expand: true,
                isLoading: benchmark.isRunning,
                onPressed: (boardValid && !solver.isSolving)
                    ? () {
                        benchmarkNotifier.runCompareAll();
                        onCompareAllTriggered?.call();
                      }
                    : null,
              );

              if (stackButtons) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    runBtn,
                    const SizedBox(height: 8),
                    compareBtn,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(flex: 6, child: runBtn),
                  const SizedBox(width: 9),
                  Expanded(flex: 5, child: compareBtn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterPill extends StatelessWidget {
  const _CategoryFilterPill({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: GlassDecorations.pill(
          active: active,
          accent: accent,
          inactiveColor: AppColors.glassSurfaceStrong,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AlgorithmOptionCard extends StatelessWidget {
  const _AlgorithmOptionCard({
    super.key,
    required this.algorithm,
    required this.title,
    required this.categoryLabel,
    required this.description,
    required this.stubLabel,
    required this.optimalLabel,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final SearchAlgorithm algorithm;
  final String title;
  final String categoryLabel;
  final String description;
  final String stubLabel;
  final String optimalLabel;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.14)
              : AppColors.glassSurfaceStrong,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.78)
                : AppColors.glassBorder,
            width: isSelected ? 1.3 : 1.0,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 16,
                    spreadRadius: -3,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textMain,
                    ),
                  ),
                ),
                if (algorithm.isOptimal) ...<Widget>[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: optimalLabel,
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    categoryLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                if (!algorithm.isImplemented)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stubLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.8,
                color: AppColors.textMuted,
                height: 1.38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyDropdown<T> extends StatelessWidget {
  const _StrategyDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.glassSurfaceStrong,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.bgElevated,
              iconEnabledColor: AppColors.cyan,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
