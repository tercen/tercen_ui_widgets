/// Step execution state.
enum StepState {
  init,
  done,
  running,
  failed,
}

/// Step kind enumeration matching the Tercen type hierarchy.
enum StepKind {
  workflow,
  groupStep,
  tableStep,
  joinStep,
  dataStep,
  viewStep,
  inStep,
  outStep,
  meltStep,
  exportStep,
  wizardStep,
}

/// Represents a single step in the workflow.
class StepModel {
  final String id;
  String name;
  final String groupId;
  final StepKind kind;
  StepState state;
  final String description;

  StepModel({
    required this.id,
    required this.name,
    required this.groupId,
    required this.kind,
    this.state = StepState.init,
    this.description = '',
  });
}

/// Represents a data-flow connection between steps.
class LinkModel {
  final String inputStepId;
  final String outputStepId;

  const LinkModel({
    required this.inputStepId,
    required this.outputStepId,
  });
}

/// Represents the loaded workflow.
class WorkflowModel {
  final String id;
  String name;
  final String projectId;
  final List<StepModel> steps;
  final List<LinkModel> links;

  WorkflowModel({
    required this.id,
    required this.name,
    required this.projectId,
    required this.steps,
    required this.links,
  });
}
