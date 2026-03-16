import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_line_weights.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/data_table_provider.dart';

/// The main data grid — active body state.
///
/// Features:
/// - Fixed row-number column on the left
/// - Horizontally scrollable header + data columns
/// - Virtual scrolling via ListView.builder
/// - Sort indicators in column headers
/// - Search highlighting (match + focused match)
/// - Annotation mode: inline editing with distinct cell background
/// - Go-to-row highlight animation
class ActiveState extends StatefulWidget {
  const ActiveState({super.key});

  @override
  State<ActiveState> createState() => _ActiveStateState();
}

class _ActiveStateState extends State<ActiveState> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();

  // Editing state
  int? _editingRow;
  String? _editingColumn;
  late TextEditingController _editController;

  // Row number column width
  static const double _rowNumWidth = 56.0;
  // Data cell dimensions
  static const double _cellWidth = 140.0;
  static const double _rowHeight = 32.0;
  static const double _headerHeight = 36.0;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();

    // Sync horizontal scrolling between header and body
    _horizontalController.addListener(() {
      if (_headerHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(_horizontalController.offset);
      }
    });
    _headerHorizontalController.addListener(() {
      if (_horizontalController.hasClients) {
        _horizontalController.jumpTo(_headerHorizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _headerHorizontalController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<DataTableProvider>();
    // Handle go-to-row
    final goTo = provider.goToRowValue;
    if (goTo != null && _verticalController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetOffset = goTo * _rowHeight;
        if (_verticalController.hasClients) {
          _verticalController.animateTo(
            targetOffset.clamp(0.0, _verticalController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _startEditing(int row, String column, dynamic currentValue) {
    setState(() {
      _editingRow = row;
      _editingColumn = column;
      _editController.text = currentValue?.toString() ?? '';
    });
  }

  void _commitEdit(DataTableProvider provider) {
    if (_editingRow != null && _editingColumn != null) {
      final text = _editController.text;
      // Try to parse as number
      final numVal = double.tryParse(text);
      provider.editCell(
          _editingRow!, _editingColumn!, numVal ?? text);
    }
    setState(() {
      _editingRow = null;
      _editingColumn = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingRow = null;
      _editingColumn = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataTableProvider>();
    final schema = provider.schema;
    final rows = provider.loadedRows?.rows ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (schema == null) return const SizedBox.shrink();

    final columns = schema.columns;
    final totalDataWidth = columns.length * _cellWidth;

    // Colors
    final headerBg =
        isDark ? AppColorsDark.surfaceElevated : AppColors.neutral100;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final searchHighlight =
        isDark ? const Color(0x40FBBF24) : const Color(0x40F59E0B);
    final focusedHighlight =
        isDark ? const Color(0x80FBBF24) : const Color(0x80F59E0B);
    final editedBg =
        isDark ? const Color(0x3014B8A6) : const Color(0x301E40AF);
    final goToHighlight =
        isDark ? const Color(0x60FBBF24) : const Color(0x60FDE68A);
    final sortIconColor =
        isDark ? AppColorsDark.primary : AppColors.primary;
    final rowAltBg = isDark
        ? AppColorsDark.surface
        : AppColors.surface;
    final rowBg = isDark
        ? AppColorsDark.panelBackground
        : AppColors.panelBackground;

    return Column(
      children: [
        // Sorting/loading indicator
        if (provider.isSorting)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(sortIconColor),
          ),
        // Header row
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              // Row number header
              Container(
                width: _rowNumWidth,
                height: _headerHeight,
                decoration: BoxDecoration(
                  color: headerBg,
                  border: Border(
                    right: BorderSide(
                        color: borderColor,
                        width: AppLineWeights.lineSubtle),
                    bottom: BorderSide(
                        color: borderColor,
                        width: AppLineWeights.lineSubtle),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#',
                  style: AppTextStyles.labelSmall.copyWith(color: mutedColor),
                ),
              ),
              // Column headers (horizontally scrollable)
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerHorizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      for (int c = 0; c < columns.length; c++)
                        _ColumnHeader(
                          column: columns[c],
                          width: _cellWidth,
                          height: _headerHeight,
                          isSorted: provider.sortColumn == columns[c].name,
                          ascending: provider.sortAscending,
                          isSorting: provider.isSorting,
                          onSort: () => provider.sort(columns[c].name),
                          headerBg: headerBg,
                          borderColor: borderColor,
                          textColor: textColor,
                          sortIconColor: sortIconColor,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Data rows
        Expanded(
          child: _buildDataArea(
            provider: provider,
            rows: rows,
            columns: columns,
            isDark: isDark,
            totalDataWidth: totalDataWidth,
            borderColor: borderColor,
            textColor: textColor,
            mutedColor: mutedColor,
            searchHighlight: searchHighlight,
            focusedHighlight: focusedHighlight,
            editedBg: editedBg,
            goToHighlight: goToHighlight,
            rowBg: rowBg,
            rowAltBg: rowAltBg,
          ),
        ),
        // Status bar
        _StatusBar(provider: provider, isDark: isDark),
      ],
    );
  }

  Widget _buildDataArea({
    required DataTableProvider provider,
    required List<Map<String, dynamic>> rows,
    required List columns,
    required bool isDark,
    required double totalDataWidth,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
    required Color searchHighlight,
    required Color focusedHighlight,
    required Color editedBg,
    required Color goToHighlight,
    required Color rowBg,
    required Color rowAltBg,
  }) {
    if (rows.isEmpty && provider.isLoadingPage) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColorsDark.primary : AppColors.primary),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load more data when near the end
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            final currentCount = rows.length;
            if (currentCount < provider.totalRows && !provider.isLoadingPage) {
              provider.loadPage(currentCount, DataTableProvider.pageSize);
            }
          }
        }
        return false;
      },
      child: Row(
        children: [
          // Fixed row number column
          SizedBox(
            width: _rowNumWidth,
            child: ListView.builder(
              controller: _verticalController,
              itemCount: rows.length + (provider.isLoadingPage ? 1 : 0),
              itemExtent: _rowHeight,
              itemBuilder: (context, index) {
                if (index >= rows.length) {
                  // Loading placeholder
                  return Container(
                    height: _rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                            color: borderColor,
                            width: AppLineWeights.lineSubtle),
                        bottom: BorderSide(
                            color: borderColor,
                            width: AppLineWeights.lineSubtle),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(mutedColor),
                      ),
                    ),
                  );
                }

                final isGoToRow = provider.goToRowValue == index;
                return Container(
                  height: _rowHeight,
                  decoration: BoxDecoration(
                    color: isGoToRow
                        ? goToHighlight
                        : (index.isEven ? rowBg : rowAltBg),
                    border: Border(
                      right: BorderSide(
                          color: borderColor,
                          width: AppLineWeights.lineSubtle),
                      bottom: BorderSide(
                          color: borderColor,
                          width: AppLineWeights.lineSubtle),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: mutedColor,
                      height: 1.0,
                    ),
                  ),
                );
              },
            ),
          ),
          // Data columns (horizontally scrollable)
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: totalDataWidth,
                child: ListView.builder(
                  // Share vertical scroll with row numbers
                  // We need a separate controller that syncs
                  itemCount: rows.length + (provider.isLoadingPage ? 1 : 0),
                  itemExtent: _rowHeight,
                  itemBuilder: (context, rowIndex) {
                    if (rowIndex >= rows.length) {
                      // Loading placeholder row
                      return Container(
                        height: _rowHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: borderColor,
                                width: AppLineWeights.lineSubtle),
                          ),
                        ),
                        child: Row(
                          children: [
                            for (int c = 0; c < columns.length; c++)
                              Container(
                                width: _cellWidth,
                                height: _rowHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                        color: borderColor,
                                        width: AppLineWeights.lineSubtle),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 10,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: borderColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    final row = rows[rowIndex];
                    final isGoToRow = provider.goToRowValue == rowIndex;

                    return Container(
                      height: _rowHeight,
                      decoration: BoxDecoration(
                        color: isGoToRow
                            ? goToHighlight
                            : (rowIndex.isEven ? rowBg : rowAltBg),
                        border: Border(
                          bottom: BorderSide(
                              color: borderColor,
                              width: AppLineWeights.lineSubtle),
                        ),
                      ),
                      child: Row(
                        children: [
                          for (int c = 0; c < columns.length; c++)
                            _buildCell(
                              rowIndex: rowIndex,
                              column: columns[c],
                              value: row[columns[c].name],
                              provider: provider,
                              textColor: textColor,
                              borderColor: borderColor,
                              searchHighlight: searchHighlight,
                              focusedHighlight: focusedHighlight,
                              editedBg: editedBg,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required int rowIndex,
    required dynamic column,
    required dynamic value,
    required DataTableProvider provider,
    required Color textColor,
    required Color borderColor,
    required Color searchHighlight,
    required Color focusedHighlight,
    required Color editedBg,
    required bool isDark,
  }) {
    final colName = column.name as String;
    final colType = column.type as String;
    final isNumeric = colType == 'double' || colType == 'int32' ||
        colType == 'uint64' || colType == 'uint16';

    // Check for edits
    final editedVal = provider.getEditedValue(rowIndex, colName);
    final isEdited = provider.isCellEdited(rowIndex, colName);
    final displayValue = isEdited ? editedVal : value;

    // Search highlighting
    final isMatch = provider.isCellSearchMatch(rowIndex, colName);
    final isFocusedMatch = provider.isCellCurrentMatch(rowIndex, colName);

    // Determine cell background
    Color? cellBg;
    if (isFocusedMatch) {
      cellBg = focusedHighlight;
    } else if (isMatch) {
      cellBg = searchHighlight;
    } else if (isEdited) {
      cellBg = editedBg;
    }

    // Check if this cell is being edited
    final isEditingThis =
        _editingRow == rowIndex && _editingColumn == colName;

    if (isEditingThis && provider.annotationMode) {
      return Container(
        width: _cellWidth,
        height: _rowHeight,
        decoration: BoxDecoration(
          color: cellBg ?? Colors.transparent,
          border: Border(
            right: BorderSide(
                color: borderColor, width: AppLineWeights.lineSubtle),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: TextField(
          controller: _editController,
          autofocus: true,
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            height: 1.0,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: BorderSide(
                color: isDark ? AppColorsDark.primary : AppColors.primary,
                width: AppLineWeights.lineEmphasis,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 4, vertical: 4),
            isDense: true,
            isCollapsed: true,
          ),
          onSubmitted: (_) => _commitEdit(provider),
          onTapOutside: (_) => _commitEdit(provider),
        ),
      );
    }

    // Format display value
    String displayText;
    if (displayValue == null) {
      displayText = '';
    } else if (isNumeric && displayValue is num) {
      // Up to 6 significant digits
      displayText = displayValue.toStringAsPrecision(
          displayValue.abs() >= 1 ? 6 : 4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      // Fallback to simple string if precision formatting is weird
      if (displayText.contains('e') || displayText.length > 12) {
        displayText = displayValue.toString();
      }
    } else {
      displayText = displayValue.toString();
    }

    return GestureDetector(
      onTap: provider.annotationMode
          ? () => _startEditing(rowIndex, colName, displayValue)
          : null,
      child: Tooltip(
        message: '$colName: $displayText',
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          width: _cellWidth,
          height: _rowHeight,
          decoration: BoxDecoration(
            color: cellBg,
            border: Border(
              right: BorderSide(
                  color: borderColor, width: AppLineWeights.lineSubtle),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            displayText,
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor,
              height: 1.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// Column header widget with sort indicator.
class _ColumnHeader extends StatefulWidget {
  final dynamic column;
  final double width;
  final double height;
  final bool isSorted;
  final bool ascending;
  final bool isSorting;
  final VoidCallback onSort;
  final Color headerBg;
  final Color borderColor;
  final Color textColor;
  final Color sortIconColor;

  const _ColumnHeader({
    required this.column,
    required this.width,
    required this.height,
    required this.isSorted,
    required this.ascending,
    required this.isSorting,
    required this.onSort,
    required this.headerBg,
    required this.borderColor,
    required this.textColor,
    required this.sortIconColor,
  });

  @override
  State<_ColumnHeader> createState() => _ColumnHeaderState();
}

class _ColumnHeaderState extends State<_ColumnHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isSorting
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isSorting ? null : widget.onSort,
        child: Tooltip(
          message: '${widget.column.name} (${widget.column.type})',
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.borderColor.withValues(alpha: 0.3)
                  : widget.headerBg,
              border: Border(
                right: BorderSide(
                    color: widget.borderColor,
                    width: AppLineWeights.lineSubtle),
                bottom: BorderSide(
                    color: widget.borderColor,
                    width: AppLineWeights.lineSubtle),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.column.name,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: widget.textColor,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (widget.isSorted) ...[
                  const SizedBox(width: 2),
                  FaIcon(
                    widget.ascending
                        ? FontAwesomeIcons.arrowUp
                        : FontAwesomeIcons.arrowDown,
                    size: 10,
                    color: widget.sortIconColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom status bar showing table info.
class _StatusBar extends StatelessWidget {
  final DataTableProvider provider;
  final bool isDark;

  const _StatusBar({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final loadedCount = provider.loadedRows?.rows.length ?? 0;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: borderColor, width: AppLineWeights.lineSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '$loadedCount of ${provider.totalRows} rows',
            style: AppTextStyles.bodySmall.copyWith(
              color: mutedColor,
              fontSize: 11,
              height: 1.0,
            ),
          ),
          if (provider.schema != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              '${provider.schema!.columns.length} columns',
              style: AppTextStyles.bodySmall.copyWith(
                color: mutedColor,
                fontSize: 11,
                height: 1.0,
              ),
            ),
          ],
          if (provider.sortColumn != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              'Sorted: ${provider.sortColumn} ${provider.sortAscending ? "ASC" : "DESC"}',
              style: AppTextStyles.bodySmall.copyWith(
                color: mutedColor,
                fontSize: 11,
                height: 1.0,
              ),
            ),
          ],
          if (provider.annotationMode) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              '${provider.editCount} edit(s)',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColorsDark.warning : AppColors.warning,
                fontSize: 11,
                height: 1.0,
              ),
            ),
          ],
          const Spacer(),
          if (provider.isLoadingPage)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(mutedColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
