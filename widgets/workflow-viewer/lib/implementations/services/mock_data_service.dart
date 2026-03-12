import '../../domain/models/workflow_models.dart';
import '../../domain/services/data_service.dart';

/// Mock implementation returning the real "RNAseq Data Connector" workflow
/// from stage.tercen.com (id: 2cdf2d2d4f0adbadc5f95636b10e2cd9).
///
/// 11 steps, flat (no groups), 3 source chains merging through 2 JoinSteps:
///
///   Chain A: GDS5037_full.soft → CSV Import → Gather → Median Expression Per Gene
///                                                                   ↓
///   Chain B: Sample_Metadata.csv → CSV Import ──────────────→ Join (1)
///                                                                   ↓
///   Chain C: hallmark_pathways.gmt → Parse GMT Hallmark ──→ Join (2) → Output
///
class MockDataService implements DataService {
  WorkflowModel? _cached;

  @override
  Future<WorkflowModel> fetchWorkflow(
      String workflowId, String projectId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _cached = _buildReferenceWorkflow();
    return _cached!;
  }

  @override
  Future<void> renameStep(String stepId, String newName) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cached != null) {
      final step = _cached!.steps.firstWhere((s) => s.id == stepId);
      step.name = newName;
    }
  }

  WorkflowModel _buildReferenceWorkflow() {
    final steps = <StepModel>[];
    final links = <LinkModel>[];

    // ── Chain A: Gene expression data ──

    steps.add(StepModel(
      id: 'ts-gds5037',
      name: 'GDS5037_full.soft',
      groupId: '',
      kind: StepKind.tableStep,
      state: StepState.done,
    ));

    steps.add(StepModel(
      id: 'ds-csv-import-1',
      name: 'CSV Import',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-csv-import-1',
      outputStepId: 'ts-gds5037',
    ));

    steps.add(StepModel(
      id: 'ms-gather',
      name: 'Gather',
      groupId: '',
      kind: StepKind.meltStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ms-gather',
      outputStepId: 'ds-csv-import-1',
    ));

    steps.add(StepModel(
      id: 'ds-median',
      name: 'Median Expression Per Gene',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-median',
      outputStepId: 'ms-gather',
    ));

    // ── Chain B: Sample metadata ──

    steps.add(StepModel(
      id: 'ts-metadata',
      name: 'Sample_Metadata.csv',
      groupId: '',
      kind: StepKind.tableStep,
      state: StepState.done,
    ));

    steps.add(StepModel(
      id: 'ds-csv-import-2',
      name: 'CSV Import',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-csv-import-2',
      outputStepId: 'ts-metadata',
    ));

    // ── Join 1: Median + Sample metadata ──

    steps.add(StepModel(
      id: 'js-join-1',
      name: 'Join',
      groupId: '',
      kind: StepKind.joinStep,
      state: StepState.done,
    ));
    // left input (i-0): from Median
    links.add(const LinkModel(
      inputStepId: 'js-join-1',
      outputStepId: 'ds-median',
    ));
    // right input (i-1): from CSV Import 2
    links.add(const LinkModel(
      inputStepId: 'js-join-1',
      outputStepId: 'ds-csv-import-2',
    ));

    // ── Chain C: Pathway data ──

    steps.add(StepModel(
      id: 'ts-hallmark',
      name: 'hallmark_pathways.gmt',
      groupId: '',
      kind: StepKind.tableStep,
      state: StepState.done,
    ));

    steps.add(StepModel(
      id: 'ds-parse-gmt',
      name: 'Parse GMT Hallmark',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-parse-gmt',
      outputStepId: 'ts-hallmark',
    ));

    // ── Join 2: Join 1 + Parse GMT ──

    steps.add(StepModel(
      id: 'js-join-2',
      name: 'Join',
      groupId: '',
      kind: StepKind.joinStep,
      state: StepState.done,
    ));
    // left input (i-0): from Join 1
    links.add(const LinkModel(
      inputStepId: 'js-join-2',
      outputStepId: 'js-join-1',
    ));
    // right input (i-1): from Parse GMT
    links.add(const LinkModel(
      inputStepId: 'js-join-2',
      outputStepId: 'ds-parse-gmt',
    ));

    // ── Output ──

    steps.add(StepModel(
      id: 'os-output',
      name: 'Output',
      groupId: '',
      kind: StepKind.outStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'os-output',
      outputStepId: 'js-join-2',
    ));

    return WorkflowModel(
      id: '2cdf2d2d4f0adbadc5f95636b10e2cd9',
      name: 'RNAseq Data Connector',
      projectId: '2cdf2d2d4f0adbadc5f95636b10e6b08',
      steps: steps,
      links: links,
    );
  }
}
