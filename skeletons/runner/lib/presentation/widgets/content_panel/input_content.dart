import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// Input mode content — two-column layout: form (left) + optional viz (right).
///
/// Replace this demo with your app's input screens from the spec.
/// Each input stage builds its own form layout within this structure.
class InputContent extends StatelessWidget {
  const InputContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description text (optional)
            Text(
              'Configure the analysis parameters below.',
              style: AppTextStyles.body.copyWith(color: textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Two-column body: Form + optional Viz
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Form
                Expanded(
                  flex: 1,
                  child: _DemoForm(
                    provider: provider,
                    labelColor: labelColor,
                    textPrimary: textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Right column: Visualization (optional — remove if not needed)
                Expanded(
                  flex: 1,
                  child: _DemoViz(
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo form column — replace with your app's input controls.
class _DemoForm extends StatelessWidget {
  final AppStateProvider provider;
  final Color labelColor;
  final Color textPrimary;

  const _DemoForm({
    required this.provider,
    required this.labelColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'PARAMETERS',
          style: AppTextStyles.sectionHeader.copyWith(color: labelColor),
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Demo control: text field
        Text('Parameter 1', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Enter value...',
            isDense: true,
          ),
          onChanged: (value) => provider.updateSetting('param1', value),
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
        // Demo control: slider
        Text('Parameter 2', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        Slider(
          value: (provider.currentSettings['param2'] as num?)?.toDouble() ?? 50.0,
          min: 0,
          max: 100,
          onChanged: (value) => provider.updateSetting('param2', value.round()),
        ),
        const SizedBox(height: AppSpacing.controlSpacing),
      ],
    );
  }
}

/// Demo visualization column — replace with your app's data viz or remove.
class _DemoViz extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _DemoViz({
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.surface : AppColors.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Text(
          'Visualization area\n(data step output, read-only)',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: textSecondary),
        ),
      ),
    );
  }
}
