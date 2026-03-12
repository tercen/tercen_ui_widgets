import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
class FlowchartView extends StatefulWidget {
  const FlowchartView({super.key});

  @override
  State<FlowchartView> createState() => _FlowchartViewState();
}

class _FlowchartViewState extends State<FlowchartView> {
  /// GlobalKeys for measuring each node's shape after layout.
  final Map<String, GlobalKey> _shapeKeys = {};

  /// Ensures we only schedule one fitting callback per frame.
  bool _fittingScheduled = false;

  /// Controller for InteractiveViewer zoom/pan.
  final TransformationController _transformController =
      TransformationController();

  /// Track whether we've set the initial zoom-to-fit.
  bool _initialFitApplied = false;

  GlobalKey _shapeKeyFor(String nodeId) {
    return _shapeKeys.putIfAbsent(nodeId, () => GlobalKey());
  }

  void _scheduleFitting(WorkflowProvider provider) {
    if (_fittingScheduled) return;
    _fittingScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fittingScheduled = false;
      if (!mounted) return;

      final measured = <String, Size>{};
      for (final entry in _shapeKeys.entries) {
        final ro = entry.value.currentContext?.findRenderObject();
        if (ro is RenderBox && ro.hasSize) {
          measured[entry.key] = ro.size;
        }
      }

      if (measured.isNotEmpty) {
        provider.fitMeasuredSizes(measured);
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    final nodes = provider.layoutNodes;

    if (nodes.isEmpty) return const SizedBox.shrink();

    // Schedule fitting pass after first render if not yet fitted
    if (!provider.fitted) {
      _scheduleFitting(provider);
    }

    // Compute content size using actual node dimensions
    double maxX = 0;
    double maxY = 0;
    for (final node in nodes) {
      final nodeWidth = node.width > 0 ? node.width : 40.0;
      final nodeHeight = node.shapeHeight > 0 ? node.shapeHeight : 36.0;
      final right = node.x + nodeWidth + 32;
      final bottom = node.y + nodeHeight + 48;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    final contentWidth = maxX;
    final contentHeight = maxY;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate fit-to-window scale (only when fitted and content is known)
            if (provider.fitted &&
                !_initialFitApplied &&
                contentWidth > 0 &&
                contentHeight > 0 &&
                constraints.maxWidth > 0 &&
                constraints.maxHeight > 0) {
              final scaleX = constraints.maxWidth / contentWidth;
              final scaleY = constraints.maxHeight / contentHeight;
              final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 1.0);
              _transformController.value = Matrix4.diagonal3Values(fitScale, fitScale, 1.0);
              _initialFitApplied = true;
            }

            return InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.2,
              maxScale: 2.0,
              constrained: false,
              child: SizedBox(
                width: contentWidth,
                height: contentHeight,
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
                          child: FlowchartNode(
                            node: node,
                            shapeKey: _shapeKeyFor(node.id),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Meta-type for connector port logic.
enum _PortMeta { entrypoint, pathway, connector, output }

_PortMeta _portMeta(StepKind kind) {
  switch (kind) {
    case StepKind.workflow:
    case StepKind.tableStep:
    case StepKind.inStep:
      return _PortMeta.entrypoint;
    case StepKind.dataStep:
    case StepKind.meltStep:
    case StepKind.wizardStep:
      return _PortMeta.pathway;
    case StepKind.joinStep:
      return _PortMeta.connector;
    case StepKind.groupStep:
    case StepKind.viewStep:
    case StepKind.outStep:
    case StepKind.exportStep:
      return _PortMeta.output;
  }
}

/// Paints elbow connector lines between nodes using a port-based system.
///
/// Port rules per meta-type:
/// - Entrypoint: no input port, exit from RIGHT-center
/// - Pathway: input LEFT-center, exit BOTTOM-center
/// - Connector (Join): 2 inputs LEFT (NW, SW vertices), exit BOTTOM (S point)
/// - Output: input LEFT-center, no exit port
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

  /// Get the exit port position for a node (where connectors leave from).
  /// Returns null if the meta-type has no exit port.
  (double, double)? _exitPort(LayoutNode n) {
    final sw = n.shapeWidth > 0 ? n.shapeWidth : 36.0;
    final sh = n.shapeHeight > 0 ? n.shapeHeight : 36.0;
    final meta = _portMeta(n.kind);
    switch (meta) {
      case _PortMeta.entrypoint:
        // Exit from RIGHT-center
        return (n.x + sw, n.y + sh / 2);
      case _PortMeta.pathway:
        // Exit from BOTTOM-center
        return (n.x + sw / 2, n.y + sh);
      case _PortMeta.connector:
        // Exit from BOTTOM (S point of hexagon)
        return (n.x + sw / 2, n.y + sh);
      case _PortMeta.output:
        // No exit port
        return null;
    }
  }

  /// Get the input port position for a node (where connectors arrive).
  /// For connector (JoinStep), uses inputIdx to pick NW (0) or SW (1) vertex.
  /// Returns null if the meta-type has no input port.
  (double, double)? _inputPort(LayoutNode n, {int inputIdx = 0}) {
    final sh = n.shapeHeight > 0 ? n.shapeHeight : 36.0;
    final meta = _portMeta(n.kind);
    switch (meta) {
      case _PortMeta.entrypoint:
        // No input port
        return null;
      case _PortMeta.pathway:
      case _PortMeta.output:
        // Input on LEFT-center
        return (n.x, n.y + sh / 2);
      case _PortMeta.connector:
        // Hexagon NW/SW vertices: pointOffset = h * 0.25
        final pointOffset = sh * 0.25;
        if (inputIdx == 0) {
          return (n.x, n.y + pointOffset); // NW vertex
        } else {
          return (n.x, n.y + sh - pointOffset); // SW vertex
        }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in nodes) n.id: n};

    // Pre-compute join input indices
    final joinInputIndex = <String, Map<String, int>>{};
    for (final link in links) {
      final to = nodeMap[link.inputStepId];
      if (to != null && to.kind == StepKind.joinStep) {
        joinInputIndex.putIfAbsent(to.id, () => {});
        final idx = joinInputIndex[to.id]!.length;
        joinInputIndex[to.id]![link.outputStepId] = idx;
      }
    }

    final defaultPaint = Paint()
      ..color = isDark ? AppColorsDark.neutral600 : AppColors.neutral400
      ..strokeWidth = AppLineWeights.vizData
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = isDark ? AppColorsDark.primary : AppColors.primary
      ..strokeWidth = AppLineWeights.vizHighlight
      ..style = PaintingStyle.stroke;

    for (final link in links) {
      final from = nodeMap[link.outputStepId];
      final to = nodeMap[link.inputStepId];
      if (from == null || to == null) continue;

      final isHighlighted =
          focusedPath.contains(from.id) && focusedPath.contains(to.id);
      final paint = isHighlighted ? highlightPaint : defaultPaint;

      // Get exit port from source
      final exit = _exitPort(from);
      if (exit == null) continue;
      final (startX, startY) = exit;

      // Get input port on target
      final inputIdx = joinInputIndex[to.id]?[from.id] ?? 0;
      final entry = _inputPort(to, inputIdx: inputIdx);
      if (entry == null) continue;
      final (endX, endY) = entry;

      // Draw elbow connector from exit → entry
      final fromMeta = _portMeta(from.kind);
      final path = Path()..moveTo(startX, startY);

      if (fromMeta == _PortMeta.entrypoint) {
        // Exit RIGHT: go right, then elbow down/up to target input
        if ((startY - endY).abs() < 2) {
          // Nearly same height: straight horizontal
          path.lineTo(endX, endY);
        } else {
          // Right then down/up to target
          final midX = startX + (endX - startX) / 2;
          path.lineTo(midX, startY);
          path.lineTo(midX, endY);
          path.lineTo(endX, endY);
        }
      } else {
        // Exit BOTTOM (pathway or connector)
        final toMeta = _portMeta(to.kind);
        // Minimum horizontal approach for join inputs
        const minApproach = 16.0;

        if (endY >= startY) {
          if (toMeta == _PortMeta.connector &&
              (startX - endX).abs() < minApproach) {
            // Connector target nearly same column: route left then horizontal
            final approachX = endX - minApproach;
            path.lineTo(startX, endY);
            path.lineTo(approachX, endY);
            path.lineTo(approachX, endY);
            path.lineTo(endX, endY);
          } else if ((startX - endX).abs() < 2) {
            // Same column, target below: straight vertical
            path.lineTo(endX, endY);
          } else {
            // Down then horizontal to target
            path.lineTo(startX, endY);
            path.lineTo(endX, endY);
          }
        } else {
          // Target is ABOVE: multi-turn routing to avoid crossing nodes
          // Down from bottom exit → horizontal to target column → up to target
          const routeGap = 20.0;
          final routeY = startY + routeGap;
          path.lineTo(startX, routeY);
          if (toMeta == _PortMeta.connector) {
            // Ensure horizontal approach from left
            final approachX = endX - minApproach;
            path.lineTo(approachX, routeY);
            path.lineTo(approachX, endY);
          } else {
            path.lineTo(endX, routeY);
          }
          path.lineTo(endX, endY);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) => true;
}
