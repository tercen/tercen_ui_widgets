import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/data_table_provider.dart';
import '../widgets/mock_tab_strip.dart';
import '../widgets/toolbar_search_field.dart';
import '../widgets/body_states/active_state.dart';
import '../widgets/info_popover.dart';
import '../../core/constants/window_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/table_schema.dart';
import '../widgets/window_shell.dart';

/// The main screen for the Data Table window.
///
/// Wires toolbar with Info, Download, Annotate, Save/Discard, Simulate Refresh,
/// Go-to-row field, and search field. Passes ActiveState as active content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _goToRowController = TextEditingController();

  @override
  void dispose() {
    _goToRowController.dispose();
    super.dispose();
  }

  String _tableKindLabel(TableKind kind) {
    switch (kind) {
      case TableKind.tableSchema:
        return 'Table Schema';
      case TableKind.computedTableSchema:
        return 'Computed Table';
      case TableKind.cubeQueryTableSchema:
        return 'Cube Query Table';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataTableProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final fillColor = isDark ? AppColorsDark.surface : AppColors.white;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    // Build toolbar actions
    final actions = <ToolbarAction>[
      // Info button
      ToolbarAction(
        icon: FontAwesomeIcons.circleInfo,
        tooltip: 'Table Info',
        variant: ButtonVariant.ghost,
        onPressed: provider.schema != null
            ? () => InfoPopover.show(
                context, provider.schema!, _tableKindLabel(provider.tableKind))
            : null,
      ),
      // Download CSV button
      ToolbarAction(
        icon: provider.isDownloading
            ? FontAwesomeIcons.spinner
            : FontAwesomeIcons.download,
        tooltip: 'Download CSV',
        variant: ButtonVariant.ghost,
        onPressed: provider.isDownloading ? null : () => provider.exportCsv(),
      ),
      // Annotate toggle button
      ToolbarAction(
        icon: FontAwesomeIcons.penToSquare,
        tooltip: 'Annotation Mode',
        variant: provider.annotationMode
            ? ButtonVariant.primary
            : ButtonVariant.ghost,
        onPressed: () => provider.toggleAnnotationMode(),
      ),
    ];

    // Add Save/Discard when in annotation mode
    if (provider.annotationMode) {
      actions.add(ToolbarAction(
        icon: provider.isSaving
            ? FontAwesomeIcons.spinner
            : FontAwesomeIcons.floppyDisk,
        tooltip: 'Save Annotations',
        label: 'Save (${provider.editCount})',
        variant: ButtonVariant.primary,
        onPressed:
            (provider.editCount > 0 && !provider.isSaving)
                ? () => provider.saveAnnotations()
                : null,
      ));
      actions.add(ToolbarAction(
        icon: FontAwesomeIcons.xmark,
        tooltip: 'Discard Changes',
        variant: ButtonVariant.secondary,
        onPressed: () => provider.discardAnnotations(),
      ));
    }

    // Mock-only: Simulate Refresh
    actions.add(ToolbarAction(
      icon: FontAwesomeIcons.arrowsRotate,
      tooltip: 'Simulate Refresh',
      variant: ButtonVariant.ghost,
      onPressed: () => provider.simulateRefresh(),
    ));

    // Toolbar trailing: go-to-row + search
    final trailing = <Widget>[
      const SizedBox(width: 4),
      // Go-to-row field
      SizedBox(
        width: 72,
        height: WindowConstants.toolbarButtonSize,
        child: TextField(
          controller: _goToRowController,
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            height: 1.0,
          ),
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            final row = int.tryParse(value);
            if (row != null) {
              provider.goToRow(row);
            }
            _goToRowController.clear();
          },
          decoration: InputDecoration(
            hintText: 'Row',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: mutedColor,
              height: 1.0,
            ),
            filled: true,
            fillColor: fillColor,
            isDense: true,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: (WindowConstants.toolbarButtonSize - 12) / 2,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WindowConstants.toolbarButtonRadius),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WindowConstants.toolbarButtonRadius),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(WindowConstants.toolbarButtonRadius),
              borderSide: BorderSide(
                color: isDark ? AppColorsDark.primary : AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      const ToolbarSearchField(),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth =
              constraints.maxWidth < WindowConstants.minWidgetWidth
                  ? WindowConstants.minWidgetWidth
                  : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: effectiveWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  const MockTabStrip(),
                  Expanded(
                    child: WindowShell(
                      toolbarActions: actions,
                      toolbarTrailing: trailing,
                      activeContent: const ActiveState(),
                      emptyIcon: FontAwesomeIcons.table,
                      emptyMessage: 'No data',
                      emptyDetail: 'Table is empty',
                      onRetry: () => provider.loadTable(
                        provider.tableId,
                        provider.tableName,
                        provider.tableKind,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
