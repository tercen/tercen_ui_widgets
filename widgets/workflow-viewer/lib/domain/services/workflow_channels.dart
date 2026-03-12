/// Channel names for workflow-viewer-specific EventBus communication.
///
/// These extend the base WindowChannels with workflow-specific events.
class WorkflowChannels {
  WorkflowChannels._();

  // -- Outbound (viewer -> frame) --

  /// Focus changed: user selected a step in the flowchart.
  static const String focusChanged = 'workflow.focusChanged';

  /// Open step viewer: user double-clicked a step.
  static const String openStepViewer = 'workflow.openStepViewer';

  /// Run workflow: action button when workflow focused + Init.
  static const String runWorkflow = 'workflow.runWorkflow';

  /// Stop workflow: action button when workflow focused + Running.
  static const String stopWorkflow = 'workflow.stopWorkflow';

  /// Reset workflow: action button when workflow focused + Done/Error.
  static const String resetWorkflow = 'workflow.resetWorkflow';

  /// Run step: action button when step focused + Init.
  static const String runStep = 'workflow.runStep';

  /// Stop step: action button when step focused + Running.
  static const String stopStep = 'workflow.stopStep';

  /// Reset step: action button when step focused + Done/Error.
  static const String resetStep = 'workflow.resetStep';

  /// Step renamed: inline rename confirmed.
  static const String stepRenamed = 'workflow.stepRenamed';

  // -- Inbound (frame -> viewer) --

  /// Open a specific workflow.
  static const String openWorkflow = 'workflow.openWorkflow';

  /// Step state changed: frame notifies state transitions.
  static const String stepStateChanged = 'workflow.stepStateChanged';

  /// Workflow updated: re-fetch and re-render.
  static const String workflowUpdated = 'workflow.workflowUpdated';

  /// Navigate to a specific step: scroll and focus.
  static const String navigateToStep = 'workflow.navigateToStep';
}
