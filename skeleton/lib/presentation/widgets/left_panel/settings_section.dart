import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Placeholder SETTINGS section demonstrating: dropdown, toggle, slider.
/// Replace with app-specific controls.
///
/// WIRING PATTERN:
///   control.onChanged → provider.setXxx(value) → notifyListeners() → main content rebuilds
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown
        Text('Display Mode', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: provider.selectedOption,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'Option A', child: Text('Option A')),
              DropdownMenuItem(value: 'Option B', child: Text('Option B')),
              DropdownMenuItem(value: 'Option C', child: Text('Option C')),
            ],
            onChanged: (value) {
              if (value != null) provider.setSelectedOption(value);
            },
          ),
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show Labels', style: AppTextStyles.label.copyWith(color: labelColor)),
            Switch(
              value: provider.showLabels,
              onChanged: provider.setShowLabels,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // Slider
        Text('Threshold', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: provider.threshold,
                min: 0,
                max: 100,
                onChanged: provider.setThreshold,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                provider.threshold.toStringAsFixed(0),
                style: AppTextStyles.body.copyWith(color: labelColor),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
