import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Accent-colored header for the left panel.
///
/// Expanded: App icon + title + theme toggle + collapse chevron (left to right).
/// Collapsed: App icon only (centered). Theme toggle and chevron move to footer.
///
/// The App icon is hardcoded (Tercen standard) and must NOT be changed.
class LeftPanelHeader extends StatelessWidget {
  final String appTitle;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const LeftPanelHeader({
    super.key,
    required this.appTitle,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Container(
      height: AppSpacing.headerHeight,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: isCollapsed ? _buildCollapsed() : _buildExpanded(context),
    );
  }

  Widget _buildCollapsed() {
    return const Center(
      child: AppIcon(size: 20),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    return Row(
      children: [
        const AppIcon(size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            appTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Theme toggle
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.wb_sunny : Icons.dark_mode,
            color: Colors.white,
            size: 16,
          ),
          onPressed: themeProvider.toggleTheme,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
        ),
        // Collapse chevron
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 16),
          onPressed: onToggleCollapse,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Collapse panel',
        ),
      ],
    );
  }
}
