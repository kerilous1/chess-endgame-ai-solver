/// features/explainer/widgets/algorithm_explainer_card.dart
/// ============================================================
/// Compact interactive card pairing the animated `CustomPainter` explainer
/// ([AlgorithmExplainerCanvas]) with live academic specs (Data Structure,
/// Formula, Time/Space Complexity, Complete/Optimal badges) read dynamically
/// from [selectedAlgorithmProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import 'algorithm_explainer_painter.dart';

/// Displays the animated visualization & academic card for the selected algorithm.
class AlgorithmExplainerCard extends ConsumerWidget {
  /// Creates an [AlgorithmExplainerCard].
  const AlgorithmExplainerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final algo = ref.watch(selectedAlgorithmProvider);
    final strings = ref.watch(appStringsProvider);
    final accent = AppColors.categoryAccent(algo.category);

    return GlassCard(
      title: strings.explainerCardTitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: GlassDecorations.pill(active: true, accent: accent),
        child: Text(
          algo.id.toUpperCase(),
          style: AppTypography.mono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AlgorithmExplainerCanvas(
            animationType: algo.explainerAnimationType,
            accent: accent,
          ),
          const SizedBox(height: 12),
          Text(
            strings.algorithmDesc(algo),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              height: 1.48,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              _SpecChip(
                label: strings.dataStructureLabel,
                value: strings.algorithmDataStructure(algo),
                accent: accent,
              ),
              _SpecChip(
                label: strings.formulaLabel,
                value: algo.formula,
                accent: AppColors.sky,
                monoValue: true,
              ),
              _SpecChip(
                label: strings.timeComplexityLabel,
                value: algo.timeComplexity,
                accent: AppColors.cyan,
                monoValue: true,
              ),
              _SpecChip(
                label: strings.spaceComplexityLabel,
                value: algo.spaceComplexity,
                accent: AppColors.violet,
                monoValue: true,
              ),
              _SpecChip(
                label: strings.completeLabel,
                value: algo.isComplete ? strings.yesLabel : strings.noLabel,
                accent: algo.isComplete ? AppColors.cyan : AppColors.amber,
              ),
              _SpecChip(
                label: strings.optimalLabel,
                value: algo.isOptimal ? strings.yesLabel : strings.noLabel,
                accent: algo.isOptimal ? AppColors.cyan : AppColors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({
    required this.label,
    required this.value,
    required this.accent,
    this.monoValue = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool monoValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: monoValue
                  ? AppTypography.mono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    )
                  : TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
