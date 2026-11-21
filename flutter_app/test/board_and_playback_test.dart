import 'package:chess_ai_solver/ai_engine/ai_engine.dart';
import 'package:chess_ai_solver/core/l10n/app_localizations.dart';
import 'package:chess_ai_solver/core/providers/providers.dart';
import 'package:chess_ai_solver/core/theme/theme.dart';
import 'package:chess_ai_solver/core/widgets/core_widgets.dart';
import 'package:chess_ai_solver/features/board_setup/board_setup.dart';
import 'package:chess_ai_solver/features/playback/playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildHarness({
  required ProviderContainer container,
  required AppLanguage language,
  required double width,
  required double height,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.buildDarkTheme(language),
      home: Directionality(
        textDirection: language.textDirection,
        child: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: AmbientCyberBackground(
              child: PlaybackKeyboardScope(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: const <Widget>[
                      InteractiveChessBoard(),
                      SizedBox(height: 12),
                      BoardSetupPanel(),
                      SizedBox(height: 12),
                      PlaybackBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Step C: SVG Pieces, Forced-LTR Board & Playback', () {
    testWidgets('all 5 SVG piece types render cleanly without warnings',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: PieceType.values
                  .map(
                    (type) => ChessPieceToken(
                      type: type,
                      size: 48,
                      isSelected: type == PieceType.wk,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChessPieceToken), findsNWidgets(5));
    });

    testWidgets('6x6 board enforces LTR file order (a -> f) even in Arabic RTL',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _buildHarness(
          container: container,
          language: AppLanguage.ar,
          width: 420,
          height: 900,
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      final fileADx =
          tester.getCenter(find.byKey(const ValueKey<String>('coord_file_a')).first).dx;
      final fileFDx =
          tester.getCenter(find.byKey(const ValueKey<String>('coord_file_f')).first).dx;
      expect(fileADx, lessThan(fileFDx));
    });

    testWidgets('renders with zero layout overflow on mobile (360px) and desktop (1280px)',
        (tester) async {
      for (final (lang, width, height) in <(AppLanguage, double, double)>[
        (AppLanguage.ar, 360, 780),
        (AppLanguage.en, 360, 780),
        (AppLanguage.ar, 1280, 820),
      ]) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // Preload Mate-in-2 solution so PlaybackBar is visible during layout check.
        container.read(boardSetupProvider.notifier).applyPreset(1);
        await container.read(solverProvider.notifier).runSelectedAlgorithm();

        await tester.binding.setSurfaceSize(Size(width, height));
        await tester.pumpWidget(
          _buildHarness(
            container: container,
            language: lang,
            width: width,
            height: height,
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.byType(InteractiveChessBoard), findsOneWidget);
        expect(find.byType(BoardSetupPanel), findsOneWidget);
        expect(find.byType(PlaybackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('supports endgame switching, tap-to-place, and playback controls',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appSettingsProvider.notifier).setLanguage(AppLanguage.en);

      await tester.binding.setSurfaceSize(const Size(420, 1200));
      await tester.pumpWidget(
        _buildHarness(
          container: container,
          language: AppLanguage.en,
          width: 420,
          height: 1200,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to KRRK (4 pieces) via mode pill tap.
      await tester.tap(find.text('KRRK'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        container.read(boardSetupProvider).board.endgameMode,
        EndgameMode.krrk,
      );
      expect(container.read(boardSetupProvider).board.pieces.length, 4);

      // Tap empty square a6 while piece 0 is selected -> moves piece to a6.
      await tester.tap(find.byKey(const ValueKey<String>('sq_a6')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(boardSetupProvider).board.pieceAt(0, 0), isNotNull);

      // Load Mate-in-2 and verify PlaybackBar step navigation + move arrows.
      container.read(boardSetupProvider.notifier).setEndgameMode(EndgameMode.krk);
      container.read(boardSetupProvider.notifier).applyPreset(1);
      container.read(solverProvider.notifier).selectAlgorithm('astar');
      await container.read(solverProvider.notifier).runSelectedAlgorithm();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(PlaybackBar), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('playback_next')));
      await tester.pump(const Duration(milliseconds: 420));
      expect(container.read(playbackProvider).currentFrameIndex, 1);
      expect(find.byType(MoveArrowOverlay), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('speed_fast')));
      await tester.pump();
      expect(container.read(playbackProvider).speed, PlaybackSpeed.fast);

      await tester.tap(find.byKey(const ValueKey<String>('playback_last')));
      await tester.pump(const Duration(milliseconds: 420));
      expect(container.read(playbackProvider).isAtEnd, isTrue);
      expect(container.read(playbackProvider).activeStep?.isCheckmate, isTrue);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
