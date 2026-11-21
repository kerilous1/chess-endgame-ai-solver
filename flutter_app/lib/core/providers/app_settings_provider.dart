/// core/providers/app_settings_provider.dart
/// ==========================================
/// Global application settings managed via Riverpod:
/// - Active UI language (`AppLanguage.ar` RTL <-> `AppLanguage.en` LTR)
/// - Tactical Vision overlay visibility
/// - Black King reply policy (`centerSeeking` vs. `evasive`)
/// - Node and depth search budgets
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_engine/ai_engine.dart';
import '../l10n/app_localizations.dart';

/// Immutable snapshot of user-configurable UI and engine settings.
class AppSettingsState {
  /// Creates an [AppSettingsState].
  const AppSettingsState({
    this.language = AppLanguage.ar,
    this.showTacticalVision = true,
    this.blackPolicy = BlackPolicy.centerSeeking,
    this.maxNodes = 50000,
    this.maxDepth = 40,
  });

  /// Active language (`ar` RTL by default).
  final AppLanguage language;

  /// Controls attacked squares, escape dots, and check rings on the 6×6 board.
  final bool showTacticalVision;

  /// Deterministic Black King response strategy during search.
  final BlackPolicy blackPolicy;

  /// Maximum node expansions allowed per search run.
  final int maxNodes;

  /// Maximum search depth (White turns).
  final int maxDepth;

  /// Returns a copy with updated fields.
  AppSettingsState copyWith({
    AppLanguage? language,
    bool? showTacticalVision,
    BlackPolicy? blackPolicy,
    int? maxNodes,
    int? maxDepth,
  }) {
    return AppSettingsState(
      language: language ?? this.language,
      showTacticalVision: showTacticalVision ?? this.showTacticalVision,
      blackPolicy: blackPolicy ?? this.blackPolicy,
      maxNodes: maxNodes ?? this.maxNodes,
      maxDepth: maxDepth ?? this.maxDepth,
    );
  }
}

/// Mutates [AppSettingsState] cleanly.
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() => const AppSettingsState();

  /// Flips between Arabic (RTL) and English (LTR).
  void toggleLanguage() {
    state = state.copyWith(language: state.language.toggled);
  }

  /// Explicitly switches to [language].
  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
  }

  /// Toggles Tactical Vision board overlays on/off.
  void toggleTacticalVision() {
    state = state.copyWith(showTacticalVision: !state.showTacticalVision);
  }

  /// Updates the Black King defensive policy.
  void setBlackPolicy(BlackPolicy policy) {
    state = state.copyWith(blackPolicy: policy);
  }

  /// Updates the node expansion cap (`10k`, `50k`, `150k`, etc.).
  void setMaxNodes(int maxNodes) {
    state = state.copyWith(maxNodes: maxNodes.clamp(1000, 300000));
  }

  /// Updates the search depth cap.
  void setMaxDepth(int maxDepth) {
    state = state.copyWith(maxDepth: maxDepth.clamp(4, 100));
  }
}

/// Global settings provider.
final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);

/// Reactive bilingual [AppStrings] derived from the active [AppLanguage].
final appStringsProvider = Provider<AppStrings>((ref) {
  final language = ref.watch(
    appSettingsProvider.select((settings) => settings.language),
  );
  return AppStrings.of(language);
});
