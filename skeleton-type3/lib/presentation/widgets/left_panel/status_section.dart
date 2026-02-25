import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// STATUS section — colour-coded state indicator, progress bar, step label.
///
/// Replace the demo content with your app's specific status display.
class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final stateLabel = provider.isRunning ? 'Running' : 'Waiting';
    final stateColor = provider.isRunning
        ? (isDark ? AppColorsDark.primary : AppColors.primary)
        : textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State indicator
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: stateColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              stateLabel,
              style: AppTextStyles.label.copyWith(color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Progress bar (indeterminate when running, hidden when waiting)
        if (provider.isRunning)
          const LinearProgressIndicator()
        else
          Text(
            provider.contentMode == ContentMode.display
                ? 'Complete'
                : 'Waiting for input',
            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
          ),
      ],
    );
  }
}
