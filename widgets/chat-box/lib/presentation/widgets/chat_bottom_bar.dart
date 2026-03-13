import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/chat_provider.dart';

/// Bottom toolbar below the input area.
///
/// Contains: [Focus context indicator] ... spacer ... [Send button]
/// The send button triggers message send via ChatProvider.
class ChatBottomBar extends StatelessWidget {
  const ChatBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ChatProvider>();
    final bgColor = isDark ? AppColorsDark.panelBackground : AppColors.panelBackground;
    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final disabledColor =
        isDark ? AppColorsDark.textDisabled : AppColors.textDisabled;

    final canSend = provider.canSend;
    final focusCtx = provider.focusContext;

    return Container(
      height: 40,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          // Focus context indicator
          if (focusCtx != null) ...[
            FaIcon(
              FontAwesomeIcons.crosshairs,
              size: 10,
              color: mutedColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Focus: ${focusCtx.displayLabel}',
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          const Spacer(),
          // Send button — Primary Button style
          Tooltip(
            message: 'Send',
            child: MouseRegion(
              cursor:
                  canSend ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: canSend ? () => provider.sendFromInput() : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: canSend
                        ? primaryColor
                        : (isDark
                            ? AppColorsDark.neutral700
                            : AppColors.neutral200),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.paperPlane,
                      size: 14,
                      color: canSend
                          ? const Color(0xFFFFFFFF)
                          : disabledColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
