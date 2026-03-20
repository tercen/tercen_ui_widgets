import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_line_weights.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';

/// Header Panel — 48px fixed strip at top of the right column.
///
/// Two-zone responsive layout:
///   [Action buttons (left)] — [Spacer] — [Theme toggle | Divider | Exit (right)]
///
/// Action buttons are left-aligned to match the content margin below.
/// Exit button is pinned to the right edge, separated by a vertical divider.
/// Spacer fills all remaining width — responsive to any screen size.
///
/// DO NOT MODIFY this widget directly. Apps configure it via AppStateProvider:
/// - setHeaderConfig(heading, actionLabel) for Input mode
/// - selectHistoryEntry() for Display mode heading
/// - startRun() / stopRun() for Running state dimming
class HeaderPanel extends StatelessWidget {
  /// Callback when the primary action button is pressed in Input mode.
  final VoidCallback? onPrimaryAction;

  /// Callback when Re-Run is pressed in Display mode.
  final VoidCallback? onReRun;

  /// Callback when Export is pressed in Display mode.
  final VoidCallback? onExport;

  /// Callback when Delete is pressed in Display mode.
  final VoidCallback? onDelete;

  /// Callback when Exit is pressed. If null, uses default navigation.
  final VoidCallback? onExit;

  /// Callback when theme toggle is pressed. If null, toggle is hidden.
  final VoidCallback? onToggleTheme;

  const HeaderPanel({
    super.key,
    this.onPrimaryAction,
    this.onReRun,
    this.onExport,
    this.onDelete,
    this.onExit,
    this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Container(
      height: AppSpacing.topBarHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md),
      child: Row(
        children: [
          // Left zone: action buttons aligned to content margin
          ..._buildActions(context, provider, isDark),

          // Spacer fills remaining width — responsive
          const Spacer(),

          // Right zone: theme toggle + divider + exit
          if (onToggleTheme != null) ...[
            IconButton(
              onPressed: onToggleTheme,
              icon: FaIcon(
                isDark ? FontAwesomeIcons.solidSun : FontAwesomeIcons.solidMoon,
                size: 16,
                color: textSecondary,
              ),
              tooltip: isDark ? 'Light mode' : 'Dark mode',
              visualDensity: VisualDensity.compact,
            ),
          ],
          SizedBox(
            height: AppSpacing.topBarHeight * 0.5,
            child: VerticalDivider(
              width: AppSpacing.md,
              thickness: AppLineWeights.lineSubtle,
              color: borderColor,
            ),
          ),
          IconButton(
            onPressed: onExit,
            icon: FaIcon(FontAwesomeIcons.xmark, size: 16, color: textSecondary),
            tooltip: 'Exit',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppStateProvider provider,
    bool isDark,
  ) {
    if (provider.contentMode == ContentMode.input) {
      return [
        ElevatedButton(
          onPressed: onPrimaryAction,
          child: Text(provider.headerActionLabel),
        ),
      ];
    }

    // Display mode
    final outlineColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    return [
      OutlinedButton.icon(
        onPressed: onReRun,
        icon: FaIcon(FontAwesomeIcons.arrowsRotate, size: 14, color: outlineColor),
        label: Text('Re-Run', style: TextStyle(color: outlineColor)),
      ),
      const SizedBox(width: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: onExport,
        icon: FaIcon(FontAwesomeIcons.download, size: 14, color: outlineColor),
        label: Text('Export', style: TextStyle(color: outlineColor)),
      ),
      const SizedBox(width: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: onDelete,
        icon: FaIcon(FontAwesomeIcons.trash, size: 14, color: isDark ? AppColorsDark.error : AppColors.error),
        label: Text('Delete', style: TextStyle(color: isDark ? AppColorsDark.error : AppColors.error)),
      ),
    ];
  }
}
