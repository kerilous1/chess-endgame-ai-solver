/// features/board_setup/widgets/board_setup_panel.dart
/// =====================================================
/// Step 1 Setup Card allowing the user to configure any 6×6 endgame position:
/// - Endgame piece-set selector (`KRK`, `KQK`, `KRRK`, `KRBK`, `CUSTOM`)
/// - Custom attacker toolbar (`+ Queen`, `+ Rook`, `+ Bishop`)
/// - Piece Palette Pills with mini SVG icons, square coordinate tags, and
///   tap-to-select / delete affordances
/// - Smart Presets bar, Smart Random Legal generator, Reset, and Tactical
///   Vision toggle
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_engine/ai_engine.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';
import 'chess_piece_svgs.dart';

/// Interactive board configuration panel inside a frosted [GlassCard].
class BoardSetupPanel extends ConsumerWidget {
  /// Creates a [BoardSetupPanel].
  const BoardSetupPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final strings = ref.watch(appStringsProvider);
    final setup = ref.watch(boardSetupProvider);
    final notifier = ref.read(boardSetupProvider.notifier);
    final mode = setup.board.endgameMode;
    final presetTitles = strings.presetNames(mode);

    return GlassCard(
      stepNumber: 1,
      title: strings.setupCardTitle,
      badgeTone: StepBadgeTone.cyan,
      trailing: Text(
        mode.code,
        style: AppTypography.mono(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.cyan,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1) Endgame Mode Selector Pills
          Text(
            strings.endgameModeLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: EndgameMode.values.map((candidate) {
              final active = candidate == mode;
              return _ModeChip(
                code: candidate.code,
                subtitle: strings.endgameName(candidate),
                active: active,
                onTap: () => notifier.setEndgameMode(candidate),
              );
            }).toList(growable: false),
          ),

          // 2) Custom Attacker Builder (only shown in CUSTOM mode)
          if (mode == EndgameMode.custom) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              strings.customAttackersLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sky,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: PieceType.attackerTypes.map((attackerType) {
                return NeonButton(
                  compact: true,
                  variant: NeonButtonVariant.cyan,
                  icon: Icons.add_rounded,
                  label: strings.pieceName(attackerType),
                  onPressed: setup.canAddCustomAttacker
                      ? () => notifier.addCustomAttacker(attackerType)
                      : null,
                );
              }).toList(growable: false),
            ),
          ],

          const SizedBox(height: 14),

          // 3) Piece Palette Pills (Tap-to-Select -> Tap Square to Place)
          Text(
            strings.tapOrDragHint,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(setup.board.pieces.length, (idx) {
              final piece = setup.board.pieces[idx];
              final isSelected = idx == setup.selectedPieceIndex;
              final canDelete =
                  mode == EndgameMode.custom && !piece.type.isKing;
              return _PiecePalettePill(
                piece: piece,
                label: strings.pieceName(piece.type),
                squareCoord: piece.pos.toAlgebraic(
                  boardSize: setup.board.boardSize,
                ),
                isSelected: isSelected,
                onTap: () => notifier.selectPieceIndex(idx),
                onDelete: canDelete
                    ? () => notifier.removeCustomAttackerAt(idx)
                    : null,
              );
            }),
          ),

          const SizedBox(height: 14),

          // 4) Curated Presets Row
          Row(
            children: <Widget>[
              Text(
                strings.presetsLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: List<Widget>.generate(presetTitles.length, (variant) {
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => notifier.applyPreset(variant),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: GlassDecorations.pill(
                    active: false,
                    inactiveColor: AppColors.glassSurfaceStrong,
                  ),
                  child: Text(
                    presetTitles[variant],
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // 5) Quick Setup Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              NeonButton(
                compact: true,
                variant: NeonButtonVariant.violet,
                icon: Icons.shuffle_rounded,
                label: strings.randomLegalBtn,
                onPressed: notifier.randomizeLegalPosition,
              ),
              NeonButton(
                compact: true,
                variant: NeonButtonVariant.ghost,
                icon: Icons.restart_alt_rounded,
                label: strings.resetBoardBtn,
                onPressed: notifier.resetToDefault,
              ),
              NeonButton(
                compact: true,
                variant: NeonButtonVariant.cyan,
                isActive: settings.showTacticalVision,
                icon: settings.showTacticalVision
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                label: strings.tacticalVisionToggle,
                onPressed: () => ref
                    .read(appSettingsProvider.notifier)
                    .toggleTacticalVision(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.code,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final String code;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: GlassDecorations.pill(
          active: active,
          accent: AppColors.cyan,
          borderRadius: 11,
          inactiveColor: AppColors.glassSurfaceStrong,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              code,
              style: AppTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.cyan : AppColors.textMain,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.textMain : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PiecePalettePill extends StatelessWidget {
  const _PiecePalettePill({
    required this.piece,
    required this.label,
    required this.squareCoord,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  final Piece piece;
  final String label;
  final String squareCoord;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = piece.type.isWhite ? AppColors.cyan : AppColors.violet;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: GlassDecorations.pill(
          active: isSelected,
          accent: accent,
          borderRadius: 12,
          inactiveColor: AppColors.glassSurfaceStrong,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ChessPieceToken(
              type: piece.type,
              size: 22,
              isSelected: false,
              showGlow: false,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textMain,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.24)
                    : AppColors.textMuted.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                squareCoord,
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
            if (onDelete != null) ...<Widget>[
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
