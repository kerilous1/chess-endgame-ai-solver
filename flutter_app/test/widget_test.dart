import 'package:chess_ai_solver/ai_engine/ai_engine.dart';
import 'package:chess_ai_solver/app.dart';
import 'package:chess_ai_solver/core/theme/theme.dart';
import 'package:chess_ai_solver/features/benchmark/benchmark.dart';
import 'package:chess_ai_solver/features/board_setup/board_setup.dart';
import 'package:chess_ai_solver/features/explainer/explainer.dart';
import 'package:chess_ai_solver/features/playback/playback.dart';
import 'package:chess_ai_solver/features/telemetry/telemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(AppTheme.configureOfflineSafeFonts);

  group('End-to-End ChessAiSolverApp Smoke Tests', () {
    testWidgets('boots cleanly on Desktop (1280x900) in AR RTL and toggles to EN LTR',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(const ProviderScope(child: ChessAiSolverApp()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(InteractiveChessBoard), findsOneWidget);
      expect(find.byType(AlgorithmExplainerCard), findsOneWidget);
      expect(find.byType(TacticalStoryCard), findsOneWidget);
      expect(find.byType(HeuristicInspectorCard), findsOneWidget);
      expect(find.byType(BenchmarkDashboard), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Flip language AR (RTL) -> EN (LTR) via top-bar switcher.
      await tester.tap(find.byKey(const ValueKey<String>('lang_toggle_btn')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('6×6 Chess Endgame AI Solver'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Open and close Project Guide Modal.
      await tester.tap(find.byKey(const ValueKey<String>('guide_open_btn')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey<String>('guide_close_btn')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('guide_close_btn')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey<String>('guide_close_btn')), findsNothing);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('mobile (360x780) tabs, solve, and benchmark inspect work without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      await tester.pumpWidget(const ProviderScope(child: ChessAiSolverApp()));
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to EN for crisp assertions and zero overflow check.
      await tester.tap(find.byKey(const ValueKey<String>('lang_toggle_btn')));
      await tester.pump(const Duration(milliseconds: 150));

      // Switch to Analysis tab -> verify Explainer, Story, and Inspector.
      await tester.tap(find.byKey(const ValueKey<String>('mobile_tab_1')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AlgorithmExplainerCard), findsOneWidget);
      expect(find.byType(TacticalStoryCard), findsOneWidget);
      expect(find.byType(HeuristicInspectorCard), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch back to Board & Solve tab, select Mate in 2 preset, and run solver.
      await tester.tap(find.byKey(const ValueKey<String>('mobile_tab_0')));
      await tester.pump(const Duration(milliseconds: 150));

      final mateIn2Btn = find.text('Mate in 2');
      await tester.ensureVisible(mateIn2Btn);
      await tester.tap(mateIn2Btn);
      await tester.pump(const Duration(milliseconds: 100));

      final compareBtn = find.byKey(const ValueKey<String>('compare_all_btn'));
      await tester.ensureVisible(compareBtn);
      await tester.tap(compareBtn);
      // Let background Isolate benchmark complete on Mate-in-2.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 450));

      // Benchmark tab should now display results for every registered algorithm.
      expect(find.byType(BenchmarkDashboard), findsOneWidget);
      expect(find.byType(BenchmarkBarChart), findsOneWidget);
      for (final algo in AlgorithmRegistry.all) {
        expect(find.text(algo.nameEn), findsWidgets);
      }

      // Inspect a solved row -> jumps back to Board tab with PlaybackBar active.
      final playIcons = find.byIcon(Icons.play_circle_outline_rounded);
      expect(playIcons, findsWidgets);
      await tester.ensureVisible(playIcons.first);
      await tester.tap(playIcons.first);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(PlaybackBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
