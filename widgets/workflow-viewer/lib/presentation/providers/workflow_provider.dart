import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../di/service_locator.dart';
import '../../domain/models/content_state.dart';
import '../../domain/models/layout_node.dart';
import '../../domain/models/workflow_models.dart';
import '../../domain/models/window_identity.dart';
import '../../domain/services/data_service.dart';
import '../../domain/services/event_bus.dart';
import '../../domain/services/event_payload.dart';
import '../../domain/services/window_channels.dart';
import '../../domain/services/workflow_channels.dart';

/// Manages workflow viewer state: workflow data, layout, focus, search.
class WorkflowProvider extends ChangeNotifier {
  final DataService _dataService = serviceLocator<DataService>();
  final EventBus _eventBus = serviceLocator<EventBus>();

  final WindowIdentity identity;
  final String windowId;

  // -- Content state --
  ContentState _contentState = ContentState.loading;
  ContentState get contentState => _contentState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // -- Workflow data --
  WorkflowModel? _workflow;
  WorkflowModel? get workflow => _workflow;

  // -- Layout --
  List<LayoutNode> _layoutNodes = [];
  List<LayoutNode> get layoutNodes => _layoutNodes;

  // -- Focus --
  String? _focusedNodeId;
  String? get focusedNodeId => _focusedNodeId;

  LayoutNode? get focusedNode {
    if (_focusedNodeId == null) return null;
    try {
      return _layoutNodes.firstWhere((n) => n.id == _focusedNodeId);
    } catch (_) {
      return null;
    }
  }

  /// Whether the workflow root (not a specific step) is focused.
  bool get isWorkflowRootFocused => _focusedNodeId == _workflowRootId;

  String? get _workflowRootId => _layoutNodes.isNotEmpty &&
          _layoutNodes.first.kind == StepKind.workflow
      ? _layoutNodes.first.id
      : null;

  // -- Search --
  String _searchText = '';
  String get searchText => _searchText;

  Set<String> _searchMatches = {};
  Set<String> get searchMatches => _searchMatches;

  // -- Inline rename --
  String? _editingNodeId;
  String? get editingNodeId => _editingNodeId;

  // -- Subscriptions --
  StreamSubscription<EventPayload>? _commandSub;
  StreamSubscription<EventPayload>? _openWorkflowSub;
  StreamSubscription<EventPayload>? _stepStateSub;
  StreamSubscription<EventPayload>? _workflowUpdatedSub;
  StreamSubscription<EventPayload>? _navigateToStepSub;

  WorkflowProvider({
    required this.identity,
    required this.windowId,
  }) {
    _commandSub = _eventBus
        .subscribe(WindowChannels.commandChannel(windowId))
        .listen(_handleCommand);
    _openWorkflowSub = _eventBus
        .subscribe(WorkflowChannels.openWorkflow)
        .listen(_handleOpenWorkflow);
    _stepStateSub = _eventBus
        .subscribe(WorkflowChannels.stepStateChanged)
        .listen(_handleStepStateChanged);
    _workflowUpdatedSub = _eventBus
        .subscribe(WorkflowChannels.workflowUpdated)
        .listen((_) => loadWorkflow());
    _navigateToStepSub = _eventBus
        .subscribe(WorkflowChannels.navigateToStep)
        .listen(_handleNavigateToStep);

    // Auto-load on creation
    loadWorkflow();
  }

  void _handleCommand(EventPayload payload) {
    // Handle focus/blur from frame
  }

  void _handleOpenWorkflow(EventPayload payload) {
    loadWorkflow();
  }

  void _handleStepStateChanged(EventPayload payload) {
    final stepId = payload.data['stepId'] as String?;
    final newStateStr = payload.data['newState'] as String?;
    if (stepId == null || newStateStr == null) return;

    final newState = StepState.values.firstWhere(
      (s) => s.name == newStateStr,
      orElse: () => StepState.init,
    );

    final node = _findLayoutNode(stepId);
    if (node != null) {
      node.step.state = newState;
      notifyListeners();
    }
  }

  void _handleNavigateToStep(EventPayload payload) {
    final stepId = payload.data['stepId'] as String?;
    if (stepId != null) {
      focusNode(stepId);
    }
  }

  // -- Loading --

  Future<void> loadWorkflow() async {
    _contentState = ContentState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _workflow = await _dataService.fetchWorkflow(
        'abefdbb9bafdfd191f735d19689d53d1',
        'bdd5a7d79e8808876678026cd3001c46',
      );
      if (_workflow == null || _workflow!.steps.isEmpty) {
        _contentState = ContentState.empty;
      } else {
        _contentState = ContentState.active;
        _buildLayout();
        // Focus the workflow root by default
        if (_layoutNodes.isNotEmpty) {
          _focusedNodeId = _layoutNodes.first.id;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _contentState = ContentState.error;
    }
    notifyListeners();
  }

  // -- Layout computation --

  void _buildLayout() {
    if (_workflow == null) return;

    _layoutNodes = [];

    // Add workflow root at col 0, row 0
    final rootStep = StepModel(
      id: 'workflow-root',
      name: _workflow!.name,
      groupId: '',
      kind: StepKind.workflow,
      state: _deriveWorkflowState(),
    );

    _layoutNodes.add(LayoutNode(
      step: rootStep,
      displayStyle: DisplayStyle.icon,
      shape: NodeShape.circleBadge,
      nameDisplay: NameDisplay.labelOutside,
      editableName: true,
      row: 0,
      col: 0,
    ));

    // Get top-level steps in pipeline order (following links)
    final topLevelSteps = _workflow!.steps
        .where((s) => s.groupId.isEmpty)
        .toList();

    final processed = <String>{};
    final ordered = _topologicalSort(topLevelSteps, _workflow!.links);

    // Layout top-level steps in col 1, each on the next available row
    int nextRow = 1;
    for (final step in ordered) {
      if (processed.contains(step.id)) continue;
      nextRow = _layoutStep(step, nextRow, 1, processed);
    }

    // Compute pixel positions from grid
    _computePixelPositions();
  }

  List<StepModel> _topologicalSort(
      List<StepModel> steps, List<LinkModel> links) {
    final stepMap = {for (final s in steps) s.id: s};
    final inDegree = <String, int>{};
    final adjacency = <String, List<String>>{};

    for (final s in steps) {
      inDegree[s.id] = 0;
      adjacency[s.id] = [];
    }

    for (final link in links) {
      if (stepMap.containsKey(link.inputStepId) &&
          stepMap.containsKey(link.outputStepId)) {
        adjacency[link.outputStepId]!.add(link.inputStepId);
        inDegree[link.inputStepId] =
            (inDegree[link.inputStepId] ?? 0) + 1;
      }
    }

    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) queue.add(entry.key);
    }

    final result = <StepModel>[];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (stepMap.containsKey(id)) {
        result.add(stepMap[id]!);
      }
      for (final next in (adjacency[id] ?? [])) {
        inDegree[next] = (inDegree[next] ?? 1) - 1;
        if (inDegree[next] == 0) queue.add(next);
      }
    }

    // Add any remaining steps not in sort (isolated nodes)
    for (final s in steps) {
      if (!result.any((r) => r.id == s.id)) {
        result.add(s);
      }
    }

    return result;
  }

  /// Layout a step on the grid. Returns the next available row.
  ///
  /// Grid rules:
  /// - Sequential steps stack downward (row + 1), same column.
  /// - GroupStep header on its own row; children indented one column right.
  /// - ViewSteps placed to the right of their parent on the SAME row.
  /// - JoinStep occupies its own row at the current column.
  int _layoutStep(
      StepModel step, int currentRow, int col, Set<String> processed) {
    if (processed.contains(step.id)) return currentRow;
    processed.add(step.id);

    final config = _getDisplayConfig(step.kind);

    // ── ViewSteps: same row as parent, column to the right ──
    if (step.kind == StepKind.viewStep) {
      // Find the parent node (the outputStepId in the link to this view)
      final parentLink = _workflow!.links
          .where((l) => l.inputStepId == step.id)
          .toList();
      if (parentLink.isNotEmpty) {
        final parentNode = _findLayoutNode(parentLink.first.outputStepId);
        if (parentNode != null) {
          // Count how many views are already attached to this parent
          final existingViews = _layoutNodes
              .where((n) =>
                  n.kind == StepKind.viewStep &&
                  n.row == parentNode.row)
              .length;

          _layoutNodes.add(LayoutNode(
            step: step,
            displayStyle: config.displayStyle,
            shape: config.shape,
            nameDisplay: config.nameDisplay,
            editableName: config.editableName,
            row: parentNode.row.toDouble(),
            col: parentNode.col + 1 + existingViews,
          ));
          return currentRow; // Views don't consume a row
        }
      }
      // Fallback if no parent found
      _layoutNodes.add(LayoutNode(
        step: step,
        displayStyle: config.displayStyle,
        shape: config.shape,
        nameDisplay: config.nameDisplay,
        editableName: config.editableName,
        row: currentRow.toDouble(),
        col: col.toDouble() + 1,
      ));
      return currentRow;
    }

    // ── GroupStep: header row, then children indented one column ──
    if (step.kind == StepKind.groupStep) {
      _layoutNodes.add(LayoutNode(
        step: step,
        displayStyle: config.displayStyle,
        shape: config.shape,
        nameDisplay: config.nameDisplay,
        editableName: config.editableName,
        row: currentRow.toDouble(),
        col: col.toDouble(),
      ));
      int nextRow = currentRow + 1;

      // Layout children inside this group, indented one column
      final children = _workflow!.steps
          .where((s) => s.groupId == step.id)
          .toList();
      final orderedChildren =
          _topologicalSort(children, _workflow!.links);

      for (final child in orderedChildren) {
        if (processed.contains(child.id)) continue;
        nextRow = _layoutStep(child, nextRow, col + 1, processed);
      }

      return nextRow;
    }

    // ── JoinStep: own row, same column ──
    // (accepts inputs from left, output goes down)
    if (step.kind == StepKind.joinStep) {
      _layoutNodes.add(LayoutNode(
        step: step,
        displayStyle: config.displayStyle,
        shape: config.shape,
        nameDisplay: config.nameDisplay,
        editableName: config.editableName,
        row: currentRow.toDouble(),
        col: col.toDouble(),
      ));
      return currentRow + 1;
    }

    // ── Default (TableStep, DataStep, InStep, OutStep, etc.) ──
    _layoutNodes.add(LayoutNode(
      step: step,
      displayStyle: config.displayStyle,
      shape: config.shape,
      nameDisplay: config.nameDisplay,
      editableName: config.editableName,
      row: currentRow.toDouble(),
      col: col.toDouble(),
    ));

    return currentRow + 1;
  }

  void _computePixelPositions() {
    const double rowHeight = 56.0;
    const double colWidth = 200.0;
    const double marginX = 40.0;
    const double marginY = 24.0;

    for (final node in _layoutNodes) {
      node.x = marginX + node.col * colWidth;
      node.y = marginY + node.row * rowHeight;
    }
  }

  _DisplayConfig _getDisplayConfig(StepKind kind) {
    switch (kind) {
      case StepKind.workflow:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.circleBadge,
          nameDisplay: NameDisplay.labelOutside,
          editableName: true,
        );
      case StepKind.groupStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.circleBadge,
          nameDisplay: NameDisplay.labelOutside,
          editableName: true,
        );
      case StepKind.tableStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.box,
          shape: NodeShape.roundedRect,
          nameDisplay: NameDisplay.alwaysVisible,
          editableName: true,
        );
      case StepKind.joinStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.hexagon90,
          nameDisplay: NameDisplay.alwaysVisible,
          editableName: true,
        );
      case StepKind.dataStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.box,
          shape: NodeShape.roundedRect,
          nameDisplay: NameDisplay.alwaysVisible,
          editableName: true,
        );
      case StepKind.viewStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.circleBadge,
          nameDisplay: NameDisplay.hoverOnly,
          editableName: true,
        );
      case StepKind.inStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.roundedSquare,
          nameDisplay: NameDisplay.hoverOnly,
          editableName: false,
        );
      case StepKind.outStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.roundedSquare,
          nameDisplay: NameDisplay.hoverOnly,
          editableName: false,
        );
      case StepKind.meltStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.box,
          shape: NodeShape.hexagon90,
          nameDisplay: NameDisplay.alwaysVisible,
          editableName: true,
        );
      case StepKind.exportStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.box,
          shape: NodeShape.roundedRect,
          nameDisplay: NameDisplay.alwaysVisible,
          editableName: true,
        );
      case StepKind.wizardStep:
        return _DisplayConfig(
          displayStyle: DisplayStyle.icon,
          shape: NodeShape.roundedRect,
          nameDisplay: NameDisplay.hoverOnly,
          editableName: true,
        );
    }
  }

  StepState _deriveWorkflowState() {
    if (_workflow == null) return StepState.init;
    final steps = _workflow!.steps;
    if (steps.any((s) => s.state == StepState.running)) return StepState.running;
    if (steps.any((s) => s.state == StepState.init)) return StepState.init;
    return StepState.done;
  }

  // -- Focus --

  void focusNode(String nodeId) {
    _focusedNodeId = nodeId;
    _editingNodeId = null; // Cancel any active edit
    notifyListeners();

    final node = _findLayoutNode(nodeId);
    if (node != null) {
      _publishIntent(WorkflowChannels.focusChanged, 'focusChanged', {
        'stepId': node.id,
        'stepType': node.kind.name,
        'stepName': node.name,
        'workflowId': _workflow?.id ?? '',
      });
    }
  }

  void clearFocus() {
    if (_workflowRootId != null) {
      focusNode(_workflowRootId!);
    }
  }

  void openStepViewer(String nodeId) {
    final node = _findLayoutNode(nodeId);
    if (node != null && node.kind != StepKind.workflow) {
      _publishIntent(WorkflowChannels.openStepViewer, 'openStepViewer', {
        'stepId': node.id,
        'stepType': node.kind.name,
        'workflowId': _workflow?.id ?? '',
      });
    }
  }

  // -- Inline rename --

  void startEditing(String nodeId) {
    final node = _findLayoutNode(nodeId);
    if (node != null && node.editableName && nodeId == _focusedNodeId) {
      _editingNodeId = nodeId;
      notifyListeners();
    }
  }

  Future<void> confirmRename(String nodeId, String newName) async {
    final node = _findLayoutNode(nodeId);
    if (node != null && newName.isNotEmpty && newName != node.name) {
      node.step.name = newName;
      await _dataService.renameStep(nodeId, newName);
      _publishIntent(WorkflowChannels.stepRenamed, 'stepRenamed', {
        'stepId': nodeId,
        'newName': newName,
        'workflowId': _workflow?.id ?? '',
      });
    }
    _editingNodeId = null;
    notifyListeners();
  }

  void cancelEditing() {
    _editingNodeId = null;
    notifyListeners();
  }

  // -- Search --

  void setSearchText(String text) {
    _searchText = text;
    _searchMatches = {};

    if (text.isNotEmpty) {
      final lowerText = text.toLowerCase();
      for (final node in _layoutNodes) {
        if (node.name.toLowerCase().contains(lowerText)) {
          _searchMatches.add(node.id);
        }
      }
    }

    notifyListeners();
  }

  // -- Action button --

  /// Get the action button configuration based on current focus.
  ActionButtonConfig get actionButtonConfig {
    if (isWorkflowRootFocused || _focusedNodeId == null) {
      final state = _deriveWorkflowState();
      switch (state) {
        case StepState.init:
          return ActionButtonConfig(
            label: 'Run All',
            tooltip:
                'Run all steps in ${_workflow?.name ?? "workflow"}',
            action: ActionButtonAction.runWorkflow,
          );
        case StepState.running:
          return ActionButtonConfig(
            label: 'Stop All',
            tooltip: 'Stop all running steps',
            action: ActionButtonAction.stopWorkflow,
          );
        case StepState.done:
        case StepState.failed:
          return ActionButtonConfig(
            label: 'Reset All',
            tooltip:
                'Reset all steps in ${_workflow?.name ?? "workflow"}',
            action: ActionButtonAction.resetWorkflow,
          );
      }
    } else {
      final node = focusedNode;
      if (node == null) {
        return ActionButtonConfig(
          label: 'Run All',
          tooltip: 'Run all steps',
          action: ActionButtonAction.runWorkflow,
        );
      }
      switch (node.state) {
        case StepState.init:
          return ActionButtonConfig(
            label: 'Run Step',
            tooltip: 'Run ${node.name}',
            action: ActionButtonAction.runStep,
          );
        case StepState.running:
          return ActionButtonConfig(
            label: 'Stop Step',
            tooltip: 'Stop ${node.name}',
            action: ActionButtonAction.stopStep,
          );
        case StepState.done:
        case StepState.failed:
          return ActionButtonConfig(
            label: 'Reset Step',
            tooltip: 'Reset ${node.name}',
            action: ActionButtonAction.resetStep,
          );
      }
    }
  }

  void executeAction() {
    final config = actionButtonConfig;
    switch (config.action) {
      case ActionButtonAction.runWorkflow:
        _publishIntent(WorkflowChannels.runWorkflow, 'runWorkflow', {
          'workflowId': _workflow?.id ?? '',
        });
        break;
      case ActionButtonAction.stopWorkflow:
        _publishIntent(WorkflowChannels.stopWorkflow, 'stopWorkflow', {
          'workflowId': _workflow?.id ?? '',
        });
        break;
      case ActionButtonAction.resetWorkflow:
        _publishIntent(
            WorkflowChannels.resetWorkflow, 'resetWorkflow', {
          'workflowId': _workflow?.id ?? '',
        });
        // Mock: reset all steps to init
        for (final node in _layoutNodes) {
          node.step.state = StepState.init;
        }
        notifyListeners();
        break;
      case ActionButtonAction.runStep:
        final node = focusedNode;
        if (node != null) {
          _publishIntent(WorkflowChannels.runStep, 'runStep', {
            'stepId': node.id,
            'workflowId': _workflow?.id ?? '',
          });
          // Mock: set step to running
          node.step.state = StepState.running;
          notifyListeners();
        }
        break;
      case ActionButtonAction.stopStep:
        final node = focusedNode;
        if (node != null) {
          _publishIntent(WorkflowChannels.stopStep, 'stopStep', {
            'stepId': node.id,
            'workflowId': _workflow?.id ?? '',
          });
          // Mock: set step to failed
          node.step.state = StepState.failed;
          notifyListeners();
        }
        break;
      case ActionButtonAction.resetStep:
        final node = focusedNode;
        if (node != null) {
          _publishIntent(WorkflowChannels.resetStep, 'resetStep', {
            'stepId': node.id,
            'workflowId': _workflow?.id ?? '',
          });
          // Mock: set step to init
          node.step.state = StepState.init;
          notifyListeners();
        }
        break;
    }
  }

  // -- Path highlighting --

  /// Returns the set of node IDs on the path from root to the focused node.
  Set<String> get focusedPath {
    if (_focusedNodeId == null || _workflow == null) return {};
    final path = <String>{};
    _buildPathToNode(_focusedNodeId!, path);
    return path;
  }

  bool _buildPathToNode(String targetId, Set<String> path) {
    path.add(targetId);
    if (targetId == 'workflow-root') return true;

    // Find parent via links (outputStepId -> inputStepId)
    final parentLinks = _workflow!.links
        .where((l) => l.inputStepId == targetId)
        .toList();

    for (final link in parentLinks) {
      if (_buildPathToNode(link.outputStepId, path)) return true;
    }

    // Also check if this step is inside a group
    final node = _findLayoutNode(targetId);
    if (node != null && node.step.groupId.isNotEmpty) {
      if (_buildPathToNode(node.step.groupId, path)) return true;
    }

    // If workflow root not found via links, add it
    if (_workflowRootId != null) {
      path.add(_workflowRootId!);
      return true;
    }

    return false;
  }

  // -- Keyboard navigation --

  void moveFocus(int rowDelta, int colDelta) {
    if (_layoutNodes.isEmpty) return;

    final current = focusedNode;
    if (current == null) {
      focusNode(_layoutNodes.first.id);
      return;
    }

    // Find nearest node in the direction
    LayoutNode? best;
    double bestDist = double.infinity;

    for (final node in _layoutNodes) {
      if (node.id == current.id) continue;

      if (rowDelta != 0) {
        final dr = (node.row - current.row) * rowDelta;
        if (dr > 0) {
          final dist = (node.row - current.row).abs() +
              (node.col - current.col).abs() * 0.1;
          if (dist < bestDist) {
            bestDist = dist;
            best = node;
          }
        }
      }

      if (colDelta != 0) {
        final dc = (node.col - current.col) * colDelta;
        if (dc > 0) {
          final dist = (node.col - current.col).abs() +
              (node.row - current.row).abs() * 0.1;
          if (dist < bestDist) {
            bestDist = dist;
            best = node;
          }
        }
      }
    }

    if (best != null) {
      focusNode(best.id);
    }
  }

  // -- Helpers --

  LayoutNode? _findLayoutNode(String nodeId) {
    try {
      return _layoutNodes.firstWhere((n) => n.id == nodeId);
    } catch (_) {
      return null;
    }
  }

  void _publishIntent(String channel, String type,
      [Map<String, dynamic> extra = const {}]) {
    _eventBus.publish(
      channel,
      EventPayload(
        type: type,
        sourceWidgetId: windowId,
        data: {'windowId': windowId, ...extra},
      ),
    );
  }

  @override
  void dispose() {
    _commandSub?.cancel();
    _openWorkflowSub?.cancel();
    _stepStateSub?.cancel();
    _workflowUpdatedSub?.cancel();
    _navigateToStepSub?.cancel();
    super.dispose();
  }
}

class _DisplayConfig {
  final DisplayStyle displayStyle;
  final NodeShape shape;
  final NameDisplay nameDisplay;
  final bool editableName;

  const _DisplayConfig({
    required this.displayStyle,
    required this.shape,
    required this.nameDisplay,
    required this.editableName,
  });
}

enum ActionButtonAction {
  runWorkflow,
  stopWorkflow,
  resetWorkflow,
  runStep,
  stopStep,
  resetStep,
}

class ActionButtonConfig {
  final String label;
  final String tooltip;
  final ActionButtonAction action;

  const ActionButtonConfig({
    required this.label,
    required this.tooltip,
    required this.action,
  });
}
