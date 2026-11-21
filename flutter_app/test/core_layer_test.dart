import 'package:chess_ai_solver/ai_engine/ai_engine.dart';
import 'package:chess_ai_solver/core/l10n/app_localizations.dart';
import 'package:chess_ai_solver/core/providers/providers.dart';
import 'package:chess_ai_solver/core/theme/theme.dart';
import 'package:chess_ai_solver/core/widgets/core_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme & Bilingual Localization', () {
    test('AppTheme builds offline-safe dark themes for AR and EN', () {
      final arTheme = AppTheme.buildDarkTheme(AppLanguage.ar);
      final enTheme = AppTheme.buildDarkTheme(AppLanguage.en);

      expect(arTheme.brightness, Brightness.dark);
      expect(arTheme.scaffoldBackgroundColor, AppColors.bgBase);
      expect(arTheme.textTheme.bodyMedium?.fontFamily, 'Cairo');
      expect(enTheme.textTheme.bodyMedium?.fontFamily, 'Plus Jakarta Sans');
      expect(AppTypography.mono().fontFamily, 'JetBrains Mono');
    });

    test('AppStrings builds AR/EN stories and benchmark takeaways', () {
      final krkFast = MovesEngine.presetPosition(EndgameMode.krk, variant: 1);
      final solved = AlgorithmRegistry.byId('astar').solve(krkFast);
      expect(solved.isSolved, isTrue);

      for (final lang in AppLanguage.values) {
        final strings = AppStrings.of(lang);
        final initialStory = strings.buildTacticalStory(currentBoard: krkFast);
        expect(initialStory.badge, isNotEmpty);
        expect(initialStory.body, isNotEmpty);

        final mateStory = strings.buildTacticalStory(
          currentBoard: solved.path.last.snapshot,
          activeStep: solved.path.last,
          previousBoard: solved.path.length > 1
              ? solved.path[solved.path.length - 2].snapshot
              : krkFast,
        );
        expect(mateStory.body, isNotEmpty);
      }
    });
  });

  group('Riverpod Controllers (Registry-Driven)', () {
    test('appSettingsProvider toggles AR/EN, vision, and black policy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appSettingsProvider).language, AppLanguage.ar);
      expect(container.read(appStringsProvider).isAr, isTrue);

      container.read(appSettingsProvider.notifier).toggleLanguage();
      expect(container.read(appSettingsProvider).language, AppLanguage.en);
      expect(container.read(appStringsProvider).isAr, isFalse);

      container
          .read(appSettingsProvider.notifier)
          .setBlackPolicy(BlackPolicy.evasive);
      container.read(appSettingsProvider.notifier).toggleTacticalVision();

      final settings = container.read(appSettingsProvider);
      expect(settings.blackPolicy, BlackPolicy.evasive);
      expect(settings.showTacticalVision, isFalse);
    });

    test('boardSetupProvider supports presets, tap/drag, custom pieces', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final setup = container.read(boardSetupProvider.notifier);

      expect(
        container.read(boardSetupProvider).board.endgameMode,
        EndgameMode.krk,
      );

      setup.setEndgameMode(EndgameMode.krrk);
      expect(
        container.read(boardSetupProvider).board.endgameMode,
        EndgameMode.krrk,
      );
      expect(container.read(boardSetupProvider).board.pieces.length, 4);

      setup.addCustomAttacker(PieceType.wb);
      expect(
        container.read(boardSetupProvider).board.endgameMode,
        EndgameMode.custom,
      );
      expect(container.read(boardSetupProvider).board.pieces.length, 5);

      // Remove a non-king attacker safely.
      final wbIndex = container
          .read(boardSetupProvider)
          .board
          .pieces
          .indexWhere((p) => p.type == PieceType.wb);
      setup.removeCustomAttackerAt(wbIndex);
      expect(container.read(boardSetupProvider).board.pieces.length, 4);

      setup.randomizeLegalPosition();
      expect(container.read(boardSetupProvider).validation.isValid, isTrue);
    });

    test('solverProvider + playbackProvider + benchmarkProvider end-to-end', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Load Mate-in-2 preset so solving + playback are fast and deterministic.
      container.read(boardSetupProvider.notifier).applyPreset(1);

      final solverNotifier = container.read(solverProvider.notifier);
      solverNotifier.selectAlgorithm('astar');
      await solverNotifier.runSelectedAlgorithm();

      final solverState = container.read(solverProvider);
      expect(solverState.result, isNotNull);
      expect(solverState.result!.isSolved, isTrue);

      final playbackNotifier = container.read(playbackProvider.notifier);
      expect(container.read(playbackProvider).hasSolution, isTrue);
      expect(container.read(playbackProvider).currentFrameIndex, 0);

      playbackNotifier.next();
      expect(container.read(playbackProvider).currentFrameIndex, 1);

      playbackNotifier.last();
      expect(container.read(playbackProvider).isAtEnd, isTrue);
      expect(
        container.read(playbackProvider).activeStep?.isCheckmate,
        isTrue,
      );

      playbackNotifier.first();
      expect(container.read(playbackProvider).isAtStart, isTrue);

      playbackNotifier.setSpeed(PlaybackSpeed.fast);
      expect(container.read(playbackProvider).speed, PlaybackSpeed.fast);

      // Run Benchmark across all AlgorithmRegistry.all algorithms.
      final benchNotifier = container.read(benchmarkProvider.notifier);
      await benchNotifier.runCompareAll();

      final benchState = container.read(benchmarkProvider);
      expect(benchState.suite, isNotNull);
      expect(benchState.suite!.results.length, AlgorithmRegistry.all.length);
      expect(benchState.suite!.winners.shortestPathId, isNotNull);

      final strings = container.read(appStringsProvider);
      expect(strings.buildBenchmarkTakeaway(benchState.suite!), isNotEmpty);

      // Inspecting a benchmark result loads its trace into solver + playback.
      benchNotifier.inspectResult('bfs');
      expect(container.read(solverProvider).selectedAlgorithmId, 'bfs');
      expect(container.read(playbackProvider).hasSolution, isTrue);

      // Editing the board automatically clears solver, playback, and benchmark.
      container.read(boardSetupProvider.notifier).randomizeLegalPosition();
      expect(container.read(solverProvider).result, isNull);
      expect(container.read(playbackProvider).hasSolution, isFalse);
      expect(container.read(benchmarkProvider).suite, isNull);
    });
  });

  group('Core Reusable Widgets', () {
    testWidgets('render GlassCard, NeonButton, MetricChip & Scanner in RTL/LTR',
        (tester) async {
      for (final lang in AppLanguage.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.buildDarkTheme(lang),
            home: Directionality(
              textDirection: lang.textDirection,
              child: Scaffold(
                body: AmbientCyberBackground(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        GlassCard(
                          stepNumber: 1,
                          title: AppStrings.of(lang).setupCardTitle,
                          child: Column(
                            children: <Widget>[
                              NeonButton(
                                label: AppStrings.of(lang).runSolverCta,
                                icon: Icons.play_arrow_rounded,
                                variant: NeonButtonVariant.primaryAmber,
                                onPressed: () {},
                              ),
                              const SizedBox(height: 12),
                              AnimatedMetricChip(
                                label: AppStrings.of(lang).metricExpanded,
                                value: 128,
                              ),
                              const SizedBox(height: 12),
                              AiScanningOverlay(
                                title: AppStrings.of(lang).scanningTitle,
                                subtitle: AppStrings.of(lang).scanningSubtitle,
                              ),
                              const SizedBox(height: 12),
                              const ShimmerBar(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 120));
        expect(find.byType(GlassCard), findsOneWidget);
        expect(find.byType(AiScanningOverlay), findsOneWidget);
      }
    });
  });
}
