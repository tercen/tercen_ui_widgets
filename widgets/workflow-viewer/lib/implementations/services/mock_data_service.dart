import '../../domain/models/workflow_models.dart';
import '../../domain/services/data_service.dart';

/// Mock implementation with multiple test workflows.
///
/// Toggle [_activeWorkflow] to switch between them.
class MockDataService implements DataService {
  WorkflowModel? _cached;

  /// Which workflow to display.
  /// 'rnaseq'     = RNAseq Data Connector (11 steps, 2 joins)
  /// 'crabs'      = Crabs Workflow (5 steps, fan-out, no joins)
  /// 'cluster'    = Cluster Interpretation (11 steps, deep fan-out, InStep entry)
  static const String _activeWorkflow = 'cluster';

  @override
  Future<WorkflowModel> fetchWorkflow(
      String workflowId, String projectId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    switch (_activeWorkflow) {
      case 'crabs':
        _cached = _buildCrabsWorkflow();
        break;
      case 'cluster':
        _cached = _buildClusterInterpretation();
        break;
      default:
        _cached = _buildRnaseqWorkflow();
    }
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

  // ═══════════════════════════════════════════════════════════════════
  // Crabs Workflow — from stage.tercen.com
  // ID: f062cb164c337a519d8cf050c2f323f2
  //
  // Fan-out topology: 1 table → 3 parallel data steps, PCA → 1 more
  //
  //   Crabs Data ──→ Heatmap
  //              ├──→ Multi Pairwise
  //              └──→ PCA ──→ Multi Pairwise PC view
  // ═══════════════════════════════════════════════════════════════════

  WorkflowModel _buildCrabsWorkflow() {
    final steps = <StepModel>[];
    final links = <LinkModel>[];

    steps.add(StepModel(
      id: 'ts-crabs',
      name: 'Crabs Data',
      groupId: '',
      kind: StepKind.tableStep,
      state: StepState.done,
    ));

    steps.add(StepModel(
      id: 'ds-heatmap',
      name: 'Heatmap',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-heatmap',
      outputStepId: 'ts-crabs',
    ));

    steps.add(StepModel(
      id: 'ds-multi-pairwise',
      name: 'Multi Pairwise',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-multi-pairwise',
      outputStepId: 'ts-crabs',
    ));

    steps.add(StepModel(
      id: 'ds-pca',
      name: 'PCA',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-pca',
      outputStepId: 'ts-crabs',
    ));

    steps.add(StepModel(
      id: 'ds-multi-pc-view',
      name: 'Multi Pairwise PC view',
      groupId: '',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'ds-multi-pc-view',
      outputStepId: 'ds-pca',
    ));

    return WorkflowModel(
      id: 'f062cb164c337a519d8cf050c2f323f2',
      name: 'Crabs Workflow',
      projectId: 'b8bf50d6a3865a60a0bc0dd4e352ebcb',
      steps: steps,
      links: links,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Cluster Interpretation — group step from Flow Immunophenotyping
  // Workflow: 6056012f5d0da9ea7fe076190c3244b4
  // Group:    4acc795d-f726-4538-8f3f-d3682b4c80c4
  //
  // 11 steps, deep fan-out, InStep entry point:
  //
  //   Input ──→ Marker Enrichment Score ──→ Enrichment Heatmap ──→ Ordered Enrichment Heatmap ──→ View
  //                                     │                                                      └──→ Cluster Markers ──→ View
  //                                     │                                                                            └──→ Cluster Profiles ──→ Output
  //                                     │                                                                                                   └──→ View
  //                                     └──→ Marker expression per cluster
  // ═══════════════════════════════════════════════════════════════════

  WorkflowModel _buildClusterInterpretation() {
    final steps = <StepModel>[];
    final links = <LinkModel>[];

    // ── Entry point (InStep) ──

    steps.add(StepModel(
      id: 'b7f8d18e',
      name: 'Input',
      groupId: '4acc795d',
      kind: StepKind.inStep,
      state: StepState.done,
    ));

    // ── Main spine ──

    steps.add(StepModel(
      id: 'd9faca40',
      name: 'Marker Enrichment Score',
      groupId: '4acc795d',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'd9faca40',
      outputStepId: 'b7f8d18e',
    ));

    steps.add(StepModel(
      id: '89e2c483',
      name: 'Enrichment Heatmap',
      groupId: '4acc795d',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '89e2c483',
      outputStepId: 'd9faca40',
    ));

    steps.add(StepModel(
      id: '50ba414c',
      name: 'Ordered Enrichment Heatmap',
      groupId: '4acc795d',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '50ba414c',
      outputStepId: '89e2c483',
    ));

    // ── Fan-out from Ordered Enrichment Heatmap ──

    steps.add(StepModel(
      id: '7ee10b97',
      name: 'View',
      groupId: '4acc795d',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '7ee10b97',
      outputStepId: '50ba414c',
    ));

    steps.add(StepModel(
      id: '6418bff0',
      name: 'Cluster Markers',
      groupId: '4acc795d',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '6418bff0',
      outputStepId: '50ba414c',
    ));

    // ── Fan-out from Cluster Markers ──

    steps.add(StepModel(
      id: '1405ab2c',
      name: 'View',
      groupId: '4acc795d',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '1405ab2c',
      outputStepId: '6418bff0',
    ));

    steps.add(StepModel(
      id: '56ccde5c',
      name: 'Cluster Profiles',
      groupId: '4acc795d',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '56ccde5c',
      outputStepId: '6418bff0',
    ));

    // ── Fan-out from Cluster Profiles ──

    steps.add(StepModel(
      id: 'cf80bb7e',
      name: 'Output',
      groupId: '4acc795d',
      kind: StepKind.outStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'cf80bb7e',
      outputStepId: '56ccde5c',
    ));

    steps.add(StepModel(
      id: 'fb1eb205',
      name: 'View',
      groupId: '4acc795d',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: 'fb1eb205',
      outputStepId: '56ccde5c',
    ));

    // ── Branch from Marker Enrichment Score ──

    steps.add(StepModel(
      id: '67df0de4',
      name: 'Marker expression per cluster',
      groupId: '4acc795d',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(
      inputStepId: '67df0de4',
      outputStepId: 'd9faca40',
    ));

    return WorkflowModel(
      id: '4acc795d-f726-4538-8f3f-d3682b4c80c4',
      name: 'Cluster Interpretation',
      projectId: '6056012f5d0da9ea7fe076190c3244b4',
      steps: steps,
      links: links,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RNAseq Data Connector — from stage.tercen.com
  // ID: 2cdf2d2d4f0adbadc5f95636b10e2cd9
  //
  // 11 steps, 3 source chains merging through 2 JoinSteps:
  //
  //   Chain A: GDS5037_full.soft → CSV Import → Gather → Median Expression
  //                                                                ↓
  //   Chain B: Sample_Metadata.csv → CSV Import ──────────→ Join (1)
  //                                                                ↓
  //   Chain C: hallmark_pathways.gmt → Parse GMT Hallmark → Join (2) → Output
  // ═══════════════════════════════════════════════════════════════════

  WorkflowModel _buildRnaseqWorkflow() {
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
    links.add(const LinkModel(
      inputStepId: 'js-join-1',
      outputStepId: 'ds-median',
    ));
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
    links.add(const LinkModel(
      inputStepId: 'js-join-2',
      outputStepId: 'js-join-1',
    ));
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
