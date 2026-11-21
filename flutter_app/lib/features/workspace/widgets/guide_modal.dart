/// features/workspace/widgets/guide_modal.dart
/// ==============================================
/// Frosted Cyber-Slate user guide modal presenting a clear, concise
/// "How to Use & Where Everything Is" tour in Arabic (RTL) and English (LTR).
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/core_widgets.dart';

const List<IconData> _guideIcons = <IconData>[
  Icons.grid_view_rounded,
  Icons.visibility_rounded,
  Icons.psychology_rounded,
  Icons.play_circle_outline_rounded,
  Icons.bar_chart_rounded,
  Icons.translate_rounded,
];

const List<Color> _guideAccents = <Color>[
  AppColors.cyan,
  AppColors.amber,
  AppColors.violet,
  AppColors.sky,
  AppColors.cyan,
  AppColors.violet,
];

/// Displays the localized user guide dialog.
Future<void> showProjectGuideModal(
  BuildContext context,
  AppStrings strings,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final maxScrollHeight = MediaQuery.sizeOf(dialogContext).height * 0.56;
      return Directionality(
        textDirection: strings.language.textDirection,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: GlassCard(
              title: strings.guideTitle,
              borderColor: AppColors.cyan.withValues(alpha: 0.42),
              trailing: IconButton(
                key: const ValueKey<String>('guide_close_icon'),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxScrollHeight),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List<Widget>.generate(
                          strings.guideSections.length,
                          (i) {
                            final section = strings.guideSections[i];
                            final icon = _guideIcons[i % _guideIcons.length];
                            final accent =
                                _guideAccents[i % _guideAccents.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.glassSurfaceStrong,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(icon, size: 17, color: accent),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          section.$1,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          section.$2,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textMain,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  NeonButton(
                    key: const ValueKey<String>('guide_close_btn'),
                    label: strings.guideClose,
                    icon: Icons.check_rounded,
                    variant: NeonButtonVariant.cyan,
                    expand: true,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
