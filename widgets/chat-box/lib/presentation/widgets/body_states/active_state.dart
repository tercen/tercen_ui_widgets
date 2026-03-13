import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../chat_message_list.dart';
import '../chat_input_area.dart';
import '../chat_bottom_bar.dart';

/// Active body state: displays the chat message list and a bordered
/// compose box (input area + bottom toolbar).
///
/// Layout (top to bottom):
///   1. Message list (scrollable, fills remaining space)
///   2. Compose box with primary border:
///      a. Multi-line text field
///      b. Divider
///      c. Bottom toolbar (focus context + send button)
class ActiveState extends StatelessWidget {
  const ActiveState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Column(
      children: [
        // Message list (scrollable, fills remaining space)
        const Expanded(
          child: ChatMessageList(),
        ),
        // Compose box: primary-bordered container with input + toolbar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor, width: 2.0),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            clipBehavior: Clip.antiAlias,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Multi-line input area
                ChatInputArea(),
                // Divider
                Divider(height: 1, thickness: 1),
                // Bottom toolbar: focus context + send button
                ChatBottomBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
