import 'package:flutter/material.dart';
import '../../core/constants/window_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'window_shell.dart';

/// 48px toolbar with left-aligned action buttons.
///
/// All buttons flow left to right in a single group — no spacer split.
/// Height matches the app header height (AppSpacing.headerHeight)
/// for visual consistency.
class WindowToolbar extends StatelessWidget {
  final List<ToolbarAction> actions;

  const WindowToolbar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: WindowConstants.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: WindowConstants.toolbarGap),
            _buildButton(context, actions[i], isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, ToolbarAction action, bool isDark) {
    final btnBg = action.isPrimary
        ? (isDark ? AppColorsDark.primaryBg : AppColors.primaryBg)
        : (isDark ? const Color(0xFF1F2937) : Colors.white);
    final btnBorder = action.isPrimary
        ? (isDark ? AppColorsDark.primarySurface : AppColors.primarySurface)
        : (isDark ? const Color(0xFF2D3343) : AppColors.neutral200);
    final btnColor = action.isPrimary
        ? (isDark ? AppColorsDark.primary : AppColors.primary)
        : (isDark ? AppColorsDark.neutral400 : AppColors.neutral500);

    if (action.label != null) {
      return _LabeledToolbarButton(
        icon: action.icon,
        label: action.label!,
        tooltip: action.tooltip,
        onPressed: action.onPressed,
        backgroundColor: btnBg,
        borderColor: btnBorder,
        foregroundColor: btnColor,
        isDark: isDark,
      );
    }

    return _IconToolbarButton(
      icon: action.icon,
      tooltip: action.tooltip,
      onPressed: action.onPressed,
      backgroundColor: btnBg,
      borderColor: btnBorder,
      foregroundColor: btnColor,
      isDark: isDark,
    );
  }
}

class _IconToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final bool isDark;

  const _IconToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.isDark,
  });

  @override
  State<_IconToolbarButton> createState() => _IconToolbarButtonState();
}

class _IconToolbarButtonState extends State<_IconToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? const Color(0xFF2D3343)
        : AppColors.neutral100;
    final hoverColor = widget.isDark
        ? AppColorsDark.neutral200
        : AppColors.neutral700;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: WindowConstants.toolbarButtonSize,
            height: WindowConstants.toolbarButtonSize,
            decoration: BoxDecoration(
              color: _hovered ? hoverBg : widget.backgroundColor,
              border: Border.all(
                color: widget.borderColor,
                width: WindowConstants.toolbarButtonBorderWidth,
              ),
              borderRadius: BorderRadius.circular(
                  WindowConstants.toolbarButtonRadius),
            ),
            child: Icon(
              widget.icon,
              size: WindowConstants.toolbarButtonIconSize,
              color: _hovered ? hoverColor : widget.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final bool isDark;

  const _LabeledToolbarButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.isDark,
  });

  @override
  State<_LabeledToolbarButton> createState() => _LabeledToolbarButtonState();
}

class _LabeledToolbarButtonState extends State<_LabeledToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? const Color(0xFF2D3343)
        : AppColors.neutral100;
    final hoverColor = widget.isDark
        ? AppColorsDark.neutral200
        : AppColors.neutral700;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            height: WindowConstants.toolbarButtonSize,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: _hovered ? hoverBg : widget.backgroundColor,
              border: Border.all(
                color: widget.borderColor,
                width: WindowConstants.toolbarButtonBorderWidth,
              ),
              borderRadius: BorderRadius.circular(
                  WindowConstants.toolbarButtonRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: WindowConstants.toolbarButtonIconSize,
                  color: _hovered ? hoverColor : widget.foregroundColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _hovered ? hoverColor : widget.foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
