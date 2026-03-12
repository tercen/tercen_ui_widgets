import 'package:flutter/material.dart' hide StepState;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_line_weights.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/layout_node.dart';
import '../../domain/models/workflow_models.dart';
import '../providers/workflow_provider.dart';

/// Renders a single step node in the flowchart.
///
/// Handles shape rendering, state colour, focus highlight, search highlight,
/// click interactions, hover tooltips, and inline rename.
class FlowchartNode extends StatefulWidget {
  final LayoutNode node;

  const FlowchartNode({super.key, required this.node});

  @override
  State<FlowchartNode> createState() => _FlowchartNodeState();
}

class _FlowchartNodeState extends State<FlowchartNode> {
  bool _hovered = false;
  DateTime? _lastClickTime;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final node = widget.node;

    final isFocused = provider.focusedNodeId == node.id;
    final isSearchMatch = provider.searchMatches.contains(node.id);
    final isEditing = provider.editingNodeId == node.id;

    // State-based icon colour
    final iconColor = _iconColorForState(node.state, isDark);

    // Shape styling
    final shapeFill = isDark
        ? AppColorsDark.surfaceElevated
        : AppColors.neutral100;
    final shapeBorder = isFocused
        ? (isDark ? AppColorsDark.primary : AppColors.primary)
        : (isDark ? AppColorsDark.border : AppColors.border);
    final shapeBorderWidth = isFocused
        ? AppLineWeights.lineEmphasis
        : AppLineWeights.lineStandard;

    // Search highlight
    final searchHighlightColor = isSearchMatch
        ? (isDark
            ? AppColorsDark.warning.withValues(alpha: 0.3)
            : AppColors.warningLight)
        : null;

    // Hover highlight
    final hoverColor = _hovered && !isFocused
        ? (isDark
            ? AppColorsDark.neutral700
            : AppColors.neutral200)
        : null;

    final effectiveFill =
        searchHighlightColor ?? hoverColor ?? shapeFill;

    Widget shapeWidget;

    switch (node.shape) {
      case NodeShape.circleBadge:
        shapeWidget = _buildCircleBadge(
          iconColor: iconColor,
          fill: effectiveFill,
          borderColor: shapeBorder,
          borderWidth: shapeBorderWidth,
          node: node,
        );
        break;
      case NodeShape.roundedRect:
        shapeWidget = _buildRoundedRect(
          iconColor: iconColor,
          fill: effectiveFill,
          borderColor: shapeBorder,
          borderWidth: shapeBorderWidth,
          node: node,
          isDark: isDark,
          isEditing: isEditing,
          provider: provider,
        );
        break;
      case NodeShape.roundedSquare:
        shapeWidget = _buildRoundedSquare(
          iconColor: iconColor,
          fill: effectiveFill,
          borderColor: shapeBorder,
          borderWidth: shapeBorderWidth,
          node: node,
        );
        break;
      case NodeShape.hexagon90:
        shapeWidget = _buildHexagon(
          iconColor: iconColor,
          fill: effectiveFill,
          borderColor: shapeBorder,
          borderWidth: shapeBorderWidth,
          node: node,
          isDark: isDark,
        );
        break;
    }

    // Wrap with label outside for icon display style
    Widget result;
    if (node.displayStyle == DisplayStyle.icon &&
        node.nameDisplay == NameDisplay.labelOutside) {
      final textColor = isDark
          ? AppColorsDark.textSecondary
          : AppColors.textSecondary;
      result = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          shapeWidget,
          const SizedBox(height: 2),
          if (isEditing)
            _buildInlineEditor(node, provider, isDark)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                node.name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor,
                  fontWeight:
                      isFocused ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      );
    } else {
      result = shapeWidget;
    }

    // Tooltip for hover-only names
    if (node.nameDisplay == NameDisplay.hoverOnly) {
      result = Tooltip(
        message: node.name,
        child: result,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _handleTap(provider, node),
        onDoubleTap: () => provider.openStepViewer(node.id),
        child: result,
      ),
    );
  }

  void _handleTap(WorkflowProvider provider, LayoutNode node) {
    final now = DateTime.now();

    // Slow double-click detection for inline rename
    if (provider.focusedNodeId == node.id &&
        node.editableName &&
        _lastClickTime != null) {
      final elapsed = now.difference(_lastClickTime!).inMilliseconds;
      // Slow double-click: 500-2000ms between clicks
      if (elapsed > 500 && elapsed < 2000) {
        provider.startEditing(node.id);
        _lastClickTime = null;
        return;
      }
    }

    _lastClickTime = now;
    provider.focusNode(node.id);
  }

  Widget _buildInlineEditor(
      LayoutNode node, WorkflowProvider provider, bool isDark) {
    final controller = TextEditingController(text: node.name);
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: node.name.length);
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    return SizedBox(
      width: 140,
      height: 24,
      child: TextField(
        controller: controller,
        autofocus: true,
        style: AppTextStyles.body.copyWith(
          color: textColor,
          height: 1.0,
        ),
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(
              color: isDark ? AppColorsDark.primary : AppColors.primary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            borderSide: BorderSide(
              color: isDark ? AppColorsDark.primary : AppColors.primary,
              width: 2,
            ),
          ),
        ),
        onSubmitted: (value) =>
            provider.confirmRename(node.id, value),
        onTapOutside: (_) => provider.cancelEditing(),
      ),
    );
  }

  Widget _buildCircleBadge({
    required Color iconColor,
    required Color fill,
    required Color borderColor,
    required double borderWidth,
    required LayoutNode node,
  }) {
    final icon = _iconForKind(node.kind);
    final isRunning = node.state == StepState.running;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: isRunning
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: AppLineWeights.lineEmphasis,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            : FaIcon(icon, size: 14, color: iconColor),
      ),
    );
  }

  Widget _buildRoundedRect({
    required Color iconColor,
    required Color fill,
    required Color borderColor,
    required double borderWidth,
    required LayoutNode node,
    required bool isDark,
    required bool isEditing,
    required WorkflowProvider provider,
  }) {
    final icon = _iconForKind(node.kind);
    final isRunning = node.state == StepState.running;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    return Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: AppLineWeights.lineEmphasis,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          else
            FaIcon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          if (isEditing)
            Flexible(
              child: _buildInlineEditor(node, provider, isDark),
            )
          else if (node.nameDisplay == NameDisplay.alwaysVisible)
            Flexible(
              child: Text(
                node.name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundedSquare({
    required Color iconColor,
    required Color fill,
    required Color borderColor,
    required double borderWidth,
    required LayoutNode node,
  }) {
    final icon = _iconForKind(node.kind);
    final isRunning = node.state == StepState.running;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: isRunning
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: AppLineWeights.lineEmphasis,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            : FaIcon(icon, size: 12, color: iconColor),
      ),
    );
  }

  Widget _buildHexagon({
    required Color iconColor,
    required Color fill,
    required Color borderColor,
    required double borderWidth,
    required LayoutNode node,
    required bool isDark,
  }) {
    final icon = _iconForKind(node.kind);
    final isRunning = node.state == StepState.running;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    // For box display style (MeltStep), show name inside
    final showName = node.displayStyle == DisplayStyle.box &&
        node.nameDisplay == NameDisplay.alwaysVisible;

    return ClipPath(
      clipper: _Hexagon90Clipper(),
      child: Container(
        height: 40,
        constraints: BoxConstraints(
          minWidth: showName ? 80 : 40,
          maxWidth: showName ? 180 : 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: fill,
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          // The border won't clip to the hexagon, so we draw it via the painter
          color: Colors.transparent,
        ),
        child: CustomPaint(
          painter: _HexagonBorderPainter(
            color: borderColor,
            strokeWidth: borderWidth,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRunning)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: AppLineWeights.lineEmphasis,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                else
                  FaIcon(icon, size: 14, color: iconColor),
                if (showName) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      node.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Icon mapping --

  IconData _iconForKind(StepKind kind) {
    switch (kind) {
      case StepKind.workflow:
        return FontAwesomeIcons.sitemap;
      case StepKind.groupStep:
        return FontAwesomeIcons.sitemap;
      case StepKind.tableStep:
        return FontAwesomeIcons.table;
      case StepKind.joinStep:
        return FontAwesomeIcons.codeMerge;
      case StepKind.dataStep:
        return FontAwesomeIcons.cubes;
      case StepKind.viewStep:
        return FontAwesomeIcons.eye;
      case StepKind.inStep:
        return FontAwesomeIcons.rightToBracket;
      case StepKind.outStep:
        return FontAwesomeIcons.rightFromBracket;
      case StepKind.meltStep:
        return FontAwesomeIcons.shuffle;
      case StepKind.exportStep:
        return FontAwesomeIcons.file;
      case StepKind.wizardStep:
        return FontAwesomeIcons.wandMagicSparkles;
    }
  }

  Color _iconColorForState(StepState state, bool isDark) {
    switch (state) {
      case StepState.init:
        return isDark ? AppColorsDark.neutral400 : AppColors.neutral600;
      case StepState.done:
        return isDark ? AppColorsDark.success : AppColors.success;
      case StepState.running:
        return isDark ? AppColorsDark.info : AppColors.info;
      case StepState.failed:
        return isDark ? AppColorsDark.error : AppColors.error;
    }
  }
}

/// Clips content to a hexagon rotated 90 degrees (points N and S).
class _Hexagon90Clipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final pointOffset = h * 0.25;

    return Path()
      ..moveTo(w / 2, 0) // top point (N)
      ..lineTo(w, pointOffset) // top-right
      ..lineTo(w, h - pointOffset) // bottom-right
      ..lineTo(w / 2, h) // bottom point (S)
      ..lineTo(0, h - pointOffset) // bottom-left
      ..lineTo(0, pointOffset) // top-left
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Paints a hexagon border (since BoxDecoration border doesn't follow ClipPath).
class _HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _HexagonBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pointOffset = h * 0.25;

    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, pointOffset)
      ..lineTo(w, h - pointOffset)
      ..lineTo(w / 2, h)
      ..lineTo(0, h - pointOffset)
      ..lineTo(0, pointOffset)
      ..close();

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexagonBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
