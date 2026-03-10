import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// HISTORY section — list of past runs with selection.
///
/// Clicking an entry opens its results in Display mode.
class HistorySection extends StatelessWidget {
  const HistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final selectedBg = isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;

    final history = provider.runHistory;

    if (history.isEmpty) {
      return Text(
        'No runs yet',
        style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: history.map((run) {
        final isSelected = run.id == provider.selectedRunId;
        return InkWell(
          onTap: () => provider.selectHistoryEntry(run.id),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.name,
                  style: AppTextStyles.label.copyWith(
                    color: textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _statusLabel(run.status),
                  style: AppTextStyles.labelSmall.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'complete' => 'Complete',
      'error' => 'Error',
      'stopped' => 'Stopped',
      _ => status,
    };
  }
}
