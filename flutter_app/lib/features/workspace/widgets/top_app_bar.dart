/// features/workspace/widgets/top_app_bar.dart
/// ==============================================
/// Frosted header bar featuring the glowing chess emblem, gradient title,
/// 100% Offline badge, Tactical Vision quick toggle, Guide Modal trigger,
/// and instant `AR | EN` RTL/LTR language switcher.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../board_setup/board_setup.dart';
import 'guide_modal.dart';

/// Top application header shared across Desktop and Mobile layouts.
class WorkspaceTopBar extends ConsumerWidget {
  /// Creates a [WorkspaceTopBar].
  const WorkspaceTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final strings = ref.watch(appStringsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    final brandBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.cyan.withValues(alpha: 0.22),
                AppColors.violet.withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.42)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.16),
                blurRadius: 18,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const ChessPieceToken(
            type: PieceType.wk,
            size: 32,
            showGlow: false,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.brandTitleGradient.createShader(bounds),
                child: Text(
                  strings.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                strings.appSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.8,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actionsBlock = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        // Offline ready badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: GlassDecorations.pill(
            active: true,
            accent: AppColors.cyan,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.offline_bolt_rounded,
                size: 14,
                color: AppColors.cyan,
              ),
              const SizedBox(width: 5),
              Text(
                strings.offlineReadyBadge,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),

        // Quick Tactical Vision toggle
        NeonButton(
          compact: true,
          variant: NeonButtonVariant.ghost,
          isActive: settings.showTacticalVision,
          icon: settings.showTacticalVision
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          label: strings.tacticalVisionToggle,
          onPressed: settingsNotifier.toggleTacticalVision,
        ),

        // Instant AR | EN Switcher
        InkWell(
          key: const ValueKey<String>('lang_toggle_btn'),
          borderRadius: BorderRadius.circular(10),
          onTap: settingsNotifier.toggleLanguage,
          child: Tooltip(
            message: strings.languageSwitchTooltip,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: GlassDecorations.pill(
                active: true,
                accent: AppColors.violet,
                borderRadius: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.translate_rounded,
                    size: 15,
                    color: AppColors.violet,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    settings.language == AppLanguage.ar
                        ? 'AR | en'
                        : 'ar | EN',
                    style: AppTypography.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Guide & Shortcuts Modal trigger
        Tooltip(
          message: strings.guideTooltip,
          child: InkWell(
            key: const ValueKey<String>('guide_open_btn'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => showProjectGuideModal(context, strings),
            child: Container(
              width: 36,
              height: 36,
              decoration: GlassDecorations.pill(
                active: false,
                borderRadius: 10,
                inactiveColor: AppColors.glassSurfaceStrong,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.textMain,
              ),
            ),
          ),
        ),
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 780) {
            return Row(
              children: <Widget>[
                Expanded(child: brandBlock),
                const SizedBox(width: 14),
                actionsBlock,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              brandBlock,
              const SizedBox(height: 10),
              actionsBlock,
            ],
          );
        },
      ),
    );
  }
}
