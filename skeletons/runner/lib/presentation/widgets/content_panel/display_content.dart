import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// Display mode content — scrollable results area.
///
/// Replace this demo with your app's results layout from the spec.
/// Action buttons (Re-Run/Export/Delete) are in the Header Panel, not here.
class DisplayContent extends StatelessWidget {
  const DisplayContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final cardBg = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    final run = provider.selectedRun;

    if (run == null) {
      return Container(
        color: bgColor,
        child: Center(
          child: Text(
            'No run selected',
            style: AppTextStyles.body.copyWith(color: textSecondary),
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results heading
            Text(
              'Results',
              style: AppTextStyles.h3.copyWith(color: textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Status: ${run.status}  •  ${_formatTimestamp(run.timestamp)}',
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Demo results card — replace with your app's results
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run settings',
                    style: AppTextStyles.label.copyWith(color: textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...run.settings.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            Text(
                              '${e.key}: ',
                              style: AppTextStyles.label.copyWith(color: textSecondary),
                            ),
                            Text(
                              '${e.value}',
                              style: AppTextStyles.body.copyWith(color: textPrimary),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Placeholder for actual visualization/report content
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  'Results visualization area\n(charts, tables, reports)',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    return '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} '
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
  }
}
