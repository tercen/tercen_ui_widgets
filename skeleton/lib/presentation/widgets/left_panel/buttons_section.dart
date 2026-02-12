import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Demonstrates all 5 button variants from the style guide:
/// Primary, Secondary, Ghost, Subtle, Danger.
///
/// Buttons follow the style guide: radius-md (8px), default height 36px,
/// padding 10px × 20px, icon+text gap 8px.
class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    // Theme-aware colors for custom button styles
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final primaryDarker = isDark ? AppColorsDark.primaryDarker : AppColors.primaryDarker;
    final primarySurface = isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;
    final dangerColor = isDark ? AppColorsDark.error : AppColors.error;
    final dangerBg = isDark
        ? AppColorsDark.error.withValues(alpha: 0.1)
        : AppColors.errorLight;
    final subtleBg = isDark ? AppColorsDark.surfaceElevated : AppColors.neutral200;
    final subtleText = isDark ? AppColorsDark.textSecondary : AppColors.textPrimary;
    final ghostHoverBg = isDark ? AppColorsDark.surfaceElevated : AppColors.neutral200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. PRIMARY — highest emphasis (Save, Submit, Run)
        Text('Primary', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const FaIcon(FontAwesomeIcons.play, size: 14),
            label: const Text('Run'),
          ),
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // 2. SECONDARY — medium emphasis, alongside primary
        Text('Secondary', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: FaIcon(FontAwesomeIcons.floppyDisk, size: 14, color: primaryColor),
            label: const Text('Save'),
          ),
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // 3. GHOST — low emphasis (Cancel, Skip)
        Text('Ghost', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            child: const Text('Cancel'),
          ),
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // 4. SUBTLE — least emphasis (background actions, toolbars)
        Text('Subtle', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: subtleBg,
              foregroundColor: subtleText,
            ),
            child: const Text('Details'),
          ),
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // 5. DANGER — destructive actions (Delete, Remove)
        Text('Danger', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: dangerColor,
              side: BorderSide(color: dangerColor, width: 1.5),
            ),
            icon: FaIcon(FontAwesomeIcons.trash, size: 14, color: dangerColor),
            label: const Text('Delete'),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // BUTTON GROUP EXAMPLE — horizontal layout, primary leftmost
        Text('Button Group', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
