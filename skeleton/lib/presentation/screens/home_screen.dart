import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/left_panel/left_panel.dart';
import '../widgets/left_panel/controls_section.dart';
import '../widgets/left_panel/buttons_section.dart';
import '../widgets/left_panel/info_section.dart';

/// Home screen: assembles AppShell with sections and main content.
///
/// Replace this screen with your app's specific content.
/// The AppShell, sections list, and main content widget are the three things you customize.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on startup
    Future.microtask(() {
      context.read<AppStateProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appTitle: 'Skeleton App',
      appIcon: Icons.apps,
      sections: const [
        // Replace these placeholder sections with app-specific sections.
        // Each section: icon + UPPERCASE label + content widget.
        PanelSection(
          icon: Icons.tune,
          label: 'CONTROLS',
          content: ControlsSection(),
        ),
        PanelSection(
          icon: Icons.smart_button,
          label: 'BUTTONS',
          content: ButtonsSection(),
        ),
        PanelSection(
          icon: Icons.info_outline,
          label: 'INFO',
          content: InfoSection(),
        ),
      ],
      content: const _MainContent(),
    );
  }
}

/// Placeholder main content that displays current state from the provider.
/// Proves the wiring pattern works: left panel controls → provider → main content.
///
/// Replace this with your app's visualization (chart, grid, images, table, etc.).
class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final cardBg = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    if (provider.isLoading) {
      return Container(
        color: bgColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Container(
        color: bgColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: isDark ? AppColorsDark.error : AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading data', style: AppTextStyles.h3.copyWith(color: textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(provider.error!, style: AppTextStyles.body.copyWith(color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wiring Demo', style: AppTextStyles.h2.copyWith(color: textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Controls in the left panel update this display via the provider.',
                  style: AppTextStyles.body.copyWith(color: textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: borderColor),
                const SizedBox(height: AppSpacing.md),
                _row('Text Input', provider.textInputValue.isEmpty ? '(empty)' : provider.textInputValue, textPrimary, textSecondary),
                _row('Dropdown', provider.dropdownValue, textPrimary, textSecondary),
                _row('Checkbox', provider.checkboxValue ? 'Checked' : 'Unchecked', textPrimary, textSecondary),
                _row('Radio', provider.radioValue, textPrimary, textSecondary),
                _row('Toggle', provider.toggleValue ? 'On' : 'Off', textPrimary, textSecondary),
                _row('Slider', provider.sliderValue.toStringAsFixed(0), textPrimary, textSecondary),
                _row('Range', '${provider.rangeSliderValue.start.toStringAsFixed(0)} – ${provider.rangeSliderValue.end.toStringAsFixed(0)}', textPrimary, textSecondary),
                _row('Number', provider.numberInputValue?.toString() ?? 'Auto', textPrimary, textSecondary),
                _row('Search', provider.searchableInputValue.isEmpty ? '(empty)' : provider.searchableInputValue, textPrimary, textSecondary),
                _row('Segmented', provider.segmentedValue, textPrimary, textSecondary),
                const SizedBox(height: AppSpacing.md),
                Divider(color: borderColor),
                const SizedBox(height: AppSpacing.md),
                Text('Data', style: AppTextStyles.h3.copyWith(color: textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Items: ${provider.data['itemCount'] ?? 0}  |  Status: ${provider.data['status'] ?? 'N/A'}',
                  style: AppTextStyles.body.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: labelColor)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(color: valueColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
