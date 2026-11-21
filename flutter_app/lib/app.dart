/// app.dart
/// ========
/// Top-level `MaterialApp` wiring localization (`ar` RTL / `en` LTR),
/// Muted Dark Neon theme, and the responsive [WorkspaceScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/providers/providers.dart';
import 'core/theme/theme.dart';
import 'features/workspace/workspace_screen.dart';

/// Root widget configuring bilingual RTL/LTR directionality and theming.
class ChessAiSolverApp extends ConsumerWidget {
  /// Creates a [ChessAiSolverApp].
  const ChessAiSolverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      appSettingsProvider.select((settings) => settings.language),
    );
    final strings = AppStrings.of(language);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: strings.appTitle,
      locale: language.locale,
      supportedLocales: const <Locale>[
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.buildDarkTheme(language),
      builder: (context, child) {
        return Directionality(
          textDirection: language.textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const WorkspaceScreen(),
    );
  }
}
