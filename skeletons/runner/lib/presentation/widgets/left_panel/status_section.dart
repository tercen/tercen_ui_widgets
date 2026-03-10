import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// STATUS section — six-state indicator with progress bar.
///
/// States: Waiting, Processing, Running, Complete, Error, Stopped.
/// Processing = synchronous operations (isLoading, not isRunning).
/// Running = full workflow execution (isRunning).
///
/// Standard control — ships with correct progress bar guards and dark mode
/// colors. Customize only the state labels if needed.
class StatusSection extends StatelessWidget {
  const StatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final successColor = isDark ? AppColorsDark.success : AppColors.success;
    final errorColor = isDark ? AppColorsDark.error : AppColors.error;
    final warningColor = isDark ? AppColorsDark.warning : AppColors.warning;

    // Determine state
    final String stateLabel;
    final Color stateColor;

    if (provider.isRunning) {
      stateLabel = 'Running';
      stateColor = primaryColor;
    } else if (provider.isLoading) {
      stateLabel = 'Processing';
      stateColor = primaryColor;
    } else if (provider.contentMode == ContentMode.display) {
      final run = provider.selectedRun;
      if (run?.status == 'error') {
        stateLabel = 'Error';
        stateColor = errorColor;
      } else if (run?.status == 'stopped') {
        stateLabel = 'Stopped';
        stateColor = warningColor;
      } else {
        stateLabel = 'Complete';
        stateColor = successColor;
      }
    } else {
      stateLabel = 'Waiting';
      stateColor = textSecondary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State indicator dot + label
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

        // Running state: determinate progress bar + step count + activity
        if (provider.isRunning) ...[
          LinearProgressIndicator(
            value: provider.totalSteps > 0
                ? (provider.completedSteps / provider.totalSteps).clamp(0.0, 1.0)
                : null,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            backgroundColor: isDark ? AppColorsDark.neutral700 : AppColors.neutral200,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (provider.totalSteps > 0)
            Text(
              '${provider.completedSteps} of ${provider.totalSteps} steps complete',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),
          if (provider.currentRunningStep.isNotEmpty)
            Text(
              provider.currentRunningStep,
              style: AppTextStyles.bodySmall.copyWith(color: primaryColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ]

        // Processing state: indeterminate progress bar + activity
        else if (provider.isLoading) ...[
          LinearProgressIndicator(
            value: null,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            backgroundColor: isDark ? AppColorsDark.neutral700 : AppColors.neutral200,
          ),
          if (provider.currentRunningStep.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              provider.currentRunningStep,
              style: AppTextStyles.bodySmall.copyWith(color: primaryColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ]

        // Error state: failed step + error message
        else if (stateLabel == 'Error') ...[
          if (provider.selectedRun?.failedStep != null)
            Text(
              'Failed: ${provider.selectedRun!.failedStep}',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),
          if (provider.selectedRun?.errorMessage != null)
            Text(
              provider.selectedRun!.errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: errorColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ]

        // Stopped state
        else if (stateLabel == 'Stopped')
          Text(
            'Analysis was stopped by user',
            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
          )

        // Waiting / Complete — simple text
        else
          Text(
            stateLabel == 'Complete' ? 'Complete' : 'Waiting for input',
            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
          ),
      ],
    );
  }
}
