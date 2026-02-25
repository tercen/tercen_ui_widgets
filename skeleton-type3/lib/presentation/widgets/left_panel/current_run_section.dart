import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// CURRENT RUN section — read-only summary of settings for the active run.
///
/// Updates live as the user provides input. Shows accumulated settings.
class CurrentRunSection extends StatelessWidget {
  const CurrentRunSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final settings = provider.currentSettings;

    if (settings.isEmpty) {
      return Text(
        'No active run',
        style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: settings.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.key}: ',
                style: AppTextStyles.labelSmall.copyWith(color: textSecondary),
              ),
              Expanded(
                child: Text(
                  '${e.value}',
                  style: AppTextStyles.bodySmall.copyWith(color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
