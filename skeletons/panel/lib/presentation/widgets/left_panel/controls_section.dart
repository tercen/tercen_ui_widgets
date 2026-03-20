import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Demonstrates all 10 control types from the style guide.
/// Each control wires to the provider: control.onChanged → provider.setXxx → notifyListeners → main content rebuilds.
///
/// Control types: text input, dropdown, checkbox, radio, switch/toggle,
/// slider, range slider, number input, searchable input, segmented button.
class ControlsSection extends StatefulWidget {
  const ControlsSection({super.key});

  @override
  State<ControlsSection> createState() => _ControlsSectionState();
}

class _ControlsSectionState extends State<ControlsSection> {
  final _textController = TextEditingController();
  final _numberController = TextEditingController();
  final _textFocus = FocusNode();
  final _numberFocus = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _numberController.dispose();
    _textFocus.dispose();
    _numberFocus.dispose();
    super.dispose();
  }

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
    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    _syncController(_textController, _textFocus, provider.textInputValue);
    _syncController(
      _numberController,
      _numberFocus,
      provider.numberInputValue?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TEXT INPUT
        _ControlLabel('Text Input', labelColor),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _textController,
          focusNode: _textFocus,
          decoration: const InputDecoration(hintText: 'Type here...'),
          onChanged: provider.setTextInputValue,
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. DROPDOWN / SELECT
        _ControlLabel('Dropdown', labelColor),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            value: provider.dropdownValue,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'Option A', child: Text('Option A')),
              DropdownMenuItem(value: 'Option B', child: Text('Option B')),
              DropdownMenuItem(value: 'Option C', child: Text('Option C')),
            ],
            onChanged: (value) {
              if (value != null) provider.setDropdownValue(value);
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 3. CHECKBOX (16x16 per style guide)
        _ControlLabel('Checkbox', labelColor),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: provider.checkboxValue,
                onChanged: (value) => provider.setCheckboxValue(value ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Enable feature', style: AppTextStyles.body.copyWith(color: labelColor)),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // 4. RADIO GROUP (16x16 per style guide)
        _ControlLabel('Radio', labelColor),
        const SizedBox(height: AppSpacing.xs),
        ...['Small', 'Medium', 'Large'].map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Radio<String>(
                    value: option,
                    groupValue: provider.radioValue,
                    onChanged: (value) {
                      if (value != null) provider.setRadioValue(value);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(option, style: AppTextStyles.body.copyWith(color: labelColor)),
              ],
            ),
          );
        }),

        const SizedBox(height: AppSpacing.md),

        // 5. SWITCH / TOGGLE (20px height × 36px width per style guide)
        _ControlLabel('Toggle', labelColor),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Show labels', style: AppTextStyles.body.copyWith(color: labelColor)),
            SizedBox(
              width: 36,
              height: 20,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch(
                  value: provider.toggleValue,
                  onChanged: provider.setToggleValue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // 6. SLIDER
        _ControlLabel('Slider', labelColor),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: provider.sliderValue,
                min: 0,
                max: 100,
                onChanged: provider.setSliderValue,
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                provider.sliderValue.toStringAsFixed(0),
                style: AppTextStyles.body.copyWith(color: labelColor),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // 7. RANGE SLIDER
        _ControlLabel('Range Slider', labelColor),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                provider.rangeSliderValue.start.toStringAsFixed(0),
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
              ),
            ),
            Expanded(
              child: RangeSlider(
                values: provider.rangeSliderValue,
                min: 0,
                max: 100,
                onChanged: provider.setRangeSliderValue,
              ),
            ),
            SizedBox(
              width: 28,
              child: Text(
                provider.rangeSliderValue.end.toStringAsFixed(0),
                style: AppTextStyles.bodySmall.copyWith(color: mutedColor),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // 8. NUMBER INPUT (nullable = auto)
        _ControlLabel('Number Input', labelColor),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _numberController,
          focusNode: _numberFocus,
          decoration: const InputDecoration(hintText: 'Auto'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            provider.setNumberInputValue(value.isEmpty ? null : double.tryParse(value));
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text('Leave empty for auto', style: AppTextStyles.bodySmall.copyWith(color: mutedColor)),
        ),

        const SizedBox(height: AppSpacing.md),

        // 9. SEARCHABLE INPUT (dropdown with search)
        _ControlLabel('Searchable Input', labelColor),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                final options = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta'];
                if (textEditingValue.text.isEmpty) return options;
                return options.where(
                  (o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                );
              },
              initialValue: TextEditingValue(text: provider.searchableInputValue),
              onSelected: provider.setSearchableInputValue,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
                  ),
                  onChanged: provider.setSearchableInputValue,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(option, style: AppTextStyles.body),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // 10. SEGMENTED BUTTON
        _ControlLabel('Segmented Button', labelColor),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Day', label: Text('Day')),
              ButtonSegment(value: 'Week', label: Text('Week')),
              ButtonSegment(value: 'Month', label: Text('Month')),
            ],
            selected: {provider.segmentedValue},
            onSelectionChanged: (values) {
              provider.setSegmentedValue(values.first);
            },
            showSelectedIcon: false,
          ),
        ),
      ],
    );
  }
}

class _ControlLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _ControlLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.label.copyWith(color: color));
  }
}
