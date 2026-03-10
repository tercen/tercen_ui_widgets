import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Placeholder FILTERS section demonstrating: text input, number input.
/// Replace with app-specific controls.
///
/// WIRING PATTERN:
///   control.onChanged → provider.setXxx(value) → notifyListeners() → main content rebuilds
class FiltersSection extends StatefulWidget {
  const FiltersSection({super.key});

  @override
  State<FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<FiltersSection> {
  final _filterController = TextEditingController();
  final _minValueController = TextEditingController();
  final _filterFocus = FocusNode();
  final _minValueFocus = FocusNode();

  @override
  void dispose() {
    _filterController.dispose();
    _minValueController.dispose();
    _filterFocus.dispose();
    _minValueFocus.dispose();
    super.dispose();
  }

  /// Sync controller text with provider state, but only when not actively editing.
  void _syncController(TextEditingController controller, FocusNode focus, String value) {
    if (!focus.hasFocus && controller.text != value) {
      controller.text = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final labelColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    // Sync controllers when provider updates (but not while user is typing)
    _syncController(_filterController, _filterFocus, provider.filterText);
    _syncController(
      _minValueController,
      _minValueFocus,
      provider.minValue?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text input
        Text('Search Filter', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _filterController,
          focusNode: _filterFocus,
          decoration: const InputDecoration(
            hintText: 'Type to filter...',
            prefixIcon: Icon(Icons.search, size: 18),
          ),
          onChanged: provider.setFilterText,
        ),

        const SizedBox(height: AppSpacing.controlSpacing),

        // Number input (nullable = auto mode)
        Text('Min Value', style: AppTextStyles.label.copyWith(color: labelColor)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _minValueController,
          focusNode: _minValueFocus,
          decoration: const InputDecoration(
            hintText: 'Auto',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            provider.setMinValue(value.isEmpty ? null : parsed);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            'Leave empty for auto',
            style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColorsDark.textMuted : AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
