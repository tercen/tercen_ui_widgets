import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_line_weights.dart';
import '../../domain/models/layout_node.dart';
import '../../domain/models/workflow_models.dart';
import '../providers/workflow_provider.dart';
import 'flowchart_node.dart';

/// The main flowchart body: scrollable canvas with connector lines
/// and positioned step nodes.
class FlowchartView extends StatelessWidget {
  const FlowchartView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    final nodes = provider.layoutNodes;

    if (nodes.isEmpty) return const SizedBox.shrink();

    // Compute content size
    double maxX = 0;
    double maxY = 0;
    for (final node in nodes) {
      final nodeWidth = node.displayStyle == DisplayStyle.box ? 180.0 : 36.0;
      final nodeHeight = node.displayStyle == DisplayStyle.box ? 36.0 : 36.0;
      final right = node.x + nodeWidth + 32;
      final bottom = node.y + nodeHeight + 48;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowUp:
              provider.moveFocus(-1, 0);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowDown:
              provider.moveFocus(1, 0);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowLeft:
              provider.moveFocus(0, -1);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              provider.moveFocus(0, 1);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.enter:
              if (provider.focusedNodeId != null) {
                provider.openStepViewer(provider.focusedNodeId!);
              }
              return KeyEventResult.handled;
            case LogicalKeyboardKey.escape:
              if (provider.editingNodeId != null) {
                provider.cancelEditing();
              } else {
                provider.clearFocus();
              }
              return KeyEventResult.handled;
            default:
              break;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => provider.clearFocus(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: maxX,
              height: maxY,
              child: CustomPaint(
                painter: _ConnectorPainter(
                  nodes: nodes,
                  links: provider.workflow?.links ?? [],
                  focusedPath: provider.focusedPath,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                child: Stack(
                  children: [
                    for (final node in nodes)
                      Positioned(
                        left: node.x,
                        top: node.y,
                        child: FlowchartNode(node: node),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints elbow connector lines between nodes.
///
/// Connection point rules:
/// - Same row (e.g. DataStep → ViewStep): right-center → left-center
/// - Different row (sequential): bottom-center → elbow → left-center of target
/// - JoinStep inputs: treated as different-row (enter from left)
/// - JoinStep output: exits from bottom
class _ConnectorPainter extends CustomPainter {
  final List<LayoutNode> nodes;
  final List<LinkModel> links;
  final Set<String> focusedPath;
  final bool isDark;

  _ConnectorPainter({
    required this.nodes,
    required this.links,
    required this.focusedPath,
    required this.isDark,
  });

  double _nodeWidth(LayoutNode n) =>
      n.displayStyle == DisplayStyle.box ? 180.0 : 36.0;
  static const double _nodeHeight = 36.0;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in nodes) n.id: n};

    final defaultPaint = Paint()
      ..color = isDark ? AppColorsDark.neutral600 : AppColors.neutral400
      ..strokeWidth = AppLineWeights.vizData
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = isDark ? AppColorsDark.primary : AppColors.primary
      ..strokeWidth = AppLineWeights.vizHighlight
      ..style = PaintingStyle.stroke;

    for (final link in links) {
      // link: outputStepId produces data, inputStepId consumes it
      // Visual flow: from (output/source) → to (input/target)
      final from = nodeMap[link.outputStepId];
      final to = nodeMap[link.inputStepId];
      if (from == null || to == null) continue;

      final isHighlighted =
          focusedPath.contains(from.id) && focusedPath.contains(to.id);
      final paint = isHighlighted ? highlightPaint : defaultPaint;

      final fromW = _nodeWidth(from);

      final bool sameRow = (from.row - to.row).abs() < 0.5;

      if (sameRow && to.col > from.col) {
        // ── Horizontal: right-center of source → left-center of target ──
        final startX = from.x + fromW;
        final startY = from.y + _nodeHeight / 2;
        final endX = to.x;
        final endY = to.y + _nodeHeight / 2;

        final path = Path()
          ..moveTo(startX, startY)
          ..lineTo(endX, endY);
        canvas.drawPath(path, paint);
      } else {
        // ── Vertical/elbow: bottom-center of source → left-center of target ──
        final startX = from.x + fromW / 2;
        final startY = from.y + _nodeHeight;
        final endX = to.x;
        final endY = to.y + _nodeHeight / 2;

        // Elbow: go down to the target's vertical level, then across to its left
        final midY = endY;
        final path = Path()
          ..moveTo(startX, startY)
          ..lineTo(startX, midY)
          ..lineTo(endX, midY);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) => true;
}
