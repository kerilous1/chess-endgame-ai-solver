/// main.dart
/// =========
/// Application entry point for the 100% offline 6×6 Chess Endgame AI Search
/// Solver & Visualizer.
///
/// Configures offline-safe typography before launching [ChessAiSolverApp]
/// inside a Riverpod [ProviderScope].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.configureOfflineSafeFonts();
  runApp(const ProviderScope(child: ChessAiSolverApp()));
}
