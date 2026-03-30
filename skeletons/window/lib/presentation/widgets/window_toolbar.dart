import 'package:flutter/material.dart';
import '../../core/constants/window_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'window_shell.dart';

/// 48px toolbar with left-aligned action buttons and an optional trailing widget.
///
/// Labeled buttons use Primary (ElevatedButton) or Secondary (OutlinedButton)
/// from the approved style guide. Icon-only buttons use Secondary (OutlinedButton)
/// sized to 36x36.
class WindowToolbar extends StatelessWidget {
  final List<ToolbarAction> actions;

  /// Optional widget placed after a flexible spacer (right-aligned).
  final Widget? trailing;

  const WindowToolbar({super.key, required this.actions, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WindowConstants.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: WindowConstants.toolbarGap),
            _buildButton(context, actions[i]),
          ],
          if (trailing != null) ...[
            const SizedBox(width: WindowConstants.toolbarGap),
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, ToolbarAction action) {
    if (action.label != null) {
      // Labeled button: Primary (filled) or Secondary (outlined)
      if (action.isPrimary) {
        return ElevatedButton.icon(
          onPressed: action.onPressed,
          icon: Icon(action.icon, size: WindowConstants.toolbarButtonIconSize),
          label: Text(action.label!, style: AppTextStyles.labelSmall),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(0, WindowConstants.toolbarButtonSize),
          ),
        );
      } else {
        return OutlinedButton.icon(
          onPressed: action.onPressed,
          icon: Icon(action.icon, size: WindowConstants.toolbarButtonIconSize),
          label: Text(action.label!, style: AppTextStyles.labelSmall),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, WindowConstants.toolbarButtonSize),
          ),
        );
      }
    } else {
      // Icon-only: Secondary (outlined) at 36x36
      return SizedBox(
        width: WindowConstants.toolbarButtonSize,
        height: WindowConstants.toolbarButtonSize,
        child: Tooltip(
          message: action.tooltip,
          child: OutlinedButton(
            onPressed: action.onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              action.icon,
              size: WindowConstants.toolbarButtonIconSize,
            ),
          ),
        ),
      );
    }
  }
}
