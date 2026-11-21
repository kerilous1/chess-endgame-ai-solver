/// features/telemetry/widgets/tactical_story_card.dart
/// ====================================================
/// Displays the live localized tactical explanation ([TacticalStory]) for the
/// current board setup or active playback frame, color-coded by side / mate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';

/// Live tactical move commentary card evolving alongside playback stepping.
class TacticalStoryCard extends ConsumerWidget {
  /// Creates a [TacticalStoryCard].
  const TacticalStoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final setup = ref.watch(boardSetupProvider);
    final playback = ref.watch(playbackProvider);

    final activeStep = playback.hasSolution ? playback.activeStep : null;
    final displayedBoard =
        playback.hasSolution ? playback.displayedBoard : setup.board;
    final prevBoard = playback.hasSolution ? playback.previousBoard : null;

    final story = strings.buildTacticalStory(
      currentBoard: displayedBoard,
      activeStep: activeStep,
      previousBoard: prevBoard,
    );

    final Color accent;
    if (activeStep?.isCheckmate == true) {
      accent = AppColors.coral;
    } else if (activeStep?.actor == Actor.black) {
      accent = AppColors.violet;
    } else if (activeStep?.actor == Actor.white) {
      accent = AppColors.cyan;
    } else {
      accent = AppColors.sky;
    }

    return GlassCard(
      title: strings.storyCardTitle,
      borderColor: accent.withValues(alpha: 0.34),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: GlassDecorations.pill(active: true, accent: accent),
        child: Text(
          story.meta,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              story.badge,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent == AppColors.coral ? Colors.white : accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            story.body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMain,
              height: 1.55,
            ),
          ),
          if (story.bullets.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: story.bullets.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.glassSurfaceStrong,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: '${item.$1}: ',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        TextSpan(
                          text: item.$2,
                          style: AppTypography.mono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
