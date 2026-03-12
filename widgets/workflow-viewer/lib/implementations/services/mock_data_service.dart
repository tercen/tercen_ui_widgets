import '../../domain/models/workflow_models.dart';
import '../../domain/services/data_service.dart';

/// Mock implementation that returns a realistic 65-step workflow
/// matching the reference from stage.tercen.com.
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

    // ── Top-level TableSteps ──
    steps.add(StepModel(
      id: 'table-fcs',
      name: 'FCS Files.zip',
      groupId: '',
      kind: StepKind.tableStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'table-annot',
      name: 'Sample Annotation.txt',
      groupId: '',
      kind: StepKind.tableStep,
      state: StepState.done,
    ));

    // ── Group 1: Data preprocessing ──
    steps.add(StepModel(
      id: 'grp-preproc',
      name: 'Data preprocessing',
      groupId: '',
      kind: StepKind.groupStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'in-preproc',
      name: 'In',
      groupId: 'grp-preproc',
      kind: StepKind.inStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-channel-sel',
      name: 'Channel Selection',
      groupId: 'grp-preproc',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-channel-sel-1',
      name: 'Channel Table',
      groupId: 'grp-preproc',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-channel-sel-2',
      name: 'Channel Heatmap',
      groupId: 'grp-preproc',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-read-fcs',
      name: 'Read FCS',
      groupId: 'grp-preproc',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-read-fcs',
      name: 'FCS Preview',
      groupId: 'grp-preproc',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-input-annot',
      name: 'Input Annotation',
      groupId: 'grp-preproc',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-compensate',
      name: 'Compensate',
      groupId: 'grp-preproc',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-transform',
      name: 'ArcSinh Transform',
      groupId: 'grp-preproc',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-transform',
      name: 'Transform Preview',
      groupId: 'grp-preproc',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'out-preproc',
      name: 'Out',
      groupId: 'grp-preproc',
      kind: StepKind.outStep,
      state: StepState.done,
    ));

    // Links within preprocessing
    links.add(const LinkModel(inputStepId: 'in-preproc', outputStepId: 'table-fcs'));
    links.add(const LinkModel(inputStepId: 'ds-channel-sel', outputStepId: 'in-preproc'));
    links.add(const LinkModel(inputStepId: 'view-channel-sel-1', outputStepId: 'ds-channel-sel'));
    links.add(const LinkModel(inputStepId: 'view-channel-sel-2', outputStepId: 'ds-channel-sel'));
    links.add(const LinkModel(inputStepId: 'ds-read-fcs', outputStepId: 'ds-channel-sel'));
    links.add(const LinkModel(inputStepId: 'view-read-fcs', outputStepId: 'ds-read-fcs'));
    links.add(const LinkModel(inputStepId: 'ds-input-annot', outputStepId: 'table-annot'));
    links.add(const LinkModel(inputStepId: 'ds-compensate', outputStepId: 'ds-read-fcs'));
    links.add(const LinkModel(inputStepId: 'ds-transform', outputStepId: 'ds-compensate'));
    links.add(const LinkModel(inputStepId: 'view-transform', outputStepId: 'ds-transform'));
    links.add(const LinkModel(inputStepId: 'out-preproc', outputStepId: 'ds-transform'));

    // ── JoinStep (merges Read FCS output + Input Annotation) ──
    steps.add(StepModel(
      id: 'join-1',
      name: 'Join 1',
      groupId: '',
      kind: StepKind.joinStep,
      state: StepState.done,
    ));
    links.add(const LinkModel(inputStepId: 'join-1', outputStepId: 'out-preproc'));
    links.add(const LinkModel(inputStepId: 'join-1', outputStepId: 'ds-input-annot'));

    // ── Group 2: Clustering and Dimension Reduction ──
    steps.add(StepModel(
      id: 'grp-cluster',
      name: 'Clustering and Dimension Reduction',
      groupId: '',
      kind: StepKind.groupStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'in-cluster',
      name: 'In',
      groupId: 'grp-cluster',
      kind: StepKind.inStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-phenograph',
      name: 'PhenoGraph',
      groupId: 'grp-cluster',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-phenograph-1',
      name: 'Cluster Counts',
      groupId: 'grp-cluster',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-phenograph-2',
      name: 'Cluster Heatmap',
      groupId: 'grp-cluster',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-umap',
      name: 'UMAP',
      groupId: 'grp-cluster',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-umap-1',
      name: 'UMAP Plot',
      groupId: 'grp-cluster',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-umap-2',
      name: 'UMAP Coloured',
      groupId: 'grp-cluster',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-flowsom',
      name: 'FlowSOM',
      groupId: 'grp-cluster',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-flowsom',
      name: 'SOM Tree',
      groupId: 'grp-cluster',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-consensus',
      name: 'Consensus Clustering',
      groupId: 'grp-cluster',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'out-cluster',
      name: 'Out',
      groupId: 'grp-cluster',
      kind: StepKind.outStep,
      state: StepState.done,
    ));

    links.add(const LinkModel(inputStepId: 'in-cluster', outputStepId: 'join-1'));
    links.add(const LinkModel(inputStepId: 'ds-phenograph', outputStepId: 'in-cluster'));
    links.add(const LinkModel(inputStepId: 'view-phenograph-1', outputStepId: 'ds-phenograph'));
    links.add(const LinkModel(inputStepId: 'view-phenograph-2', outputStepId: 'ds-phenograph'));
    links.add(const LinkModel(inputStepId: 'ds-umap', outputStepId: 'ds-phenograph'));
    links.add(const LinkModel(inputStepId: 'view-umap-1', outputStepId: 'ds-umap'));
    links.add(const LinkModel(inputStepId: 'view-umap-2', outputStepId: 'ds-umap'));
    links.add(const LinkModel(inputStepId: 'ds-flowsom', outputStepId: 'ds-umap'));
    links.add(const LinkModel(inputStepId: 'view-flowsom', outputStepId: 'ds-flowsom'));
    links.add(const LinkModel(inputStepId: 'ds-consensus', outputStepId: 'ds-flowsom'));
    links.add(const LinkModel(inputStepId: 'out-cluster', outputStepId: 'ds-consensus'));

    // ── Group 3: Cluster Interpretation ──
    steps.add(StepModel(
      id: 'grp-interpret',
      name: 'Cluster Interpretation',
      groupId: '',
      kind: StepKind.groupStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'in-interpret',
      name: 'In',
      groupId: 'grp-interpret',
      kind: StepKind.inStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-marker-expr',
      name: 'Marker Expression',
      groupId: 'grp-interpret',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-marker-expr',
      name: 'Expression Heatmap',
      groupId: 'grp-interpret',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-cell-counts',
      name: 'Cell Counts',
      groupId: 'grp-interpret',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-cell-counts',
      name: 'Count Barplot',
      groupId: 'grp-interpret',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-annotation',
      name: 'Cluster Annotation',
      groupId: 'grp-interpret',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-abundance',
      name: 'Abundance',
      groupId: 'grp-interpret',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-abundance',
      name: 'Abundance Plot',
      groupId: 'grp-interpret',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'out-interpret',
      name: 'Out',
      groupId: 'grp-interpret',
      kind: StepKind.outStep,
      state: StepState.done,
    ));

    links.add(const LinkModel(inputStepId: 'in-interpret', outputStepId: 'out-cluster'));
    links.add(const LinkModel(inputStepId: 'ds-marker-expr', outputStepId: 'in-interpret'));
    links.add(const LinkModel(inputStepId: 'view-marker-expr', outputStepId: 'ds-marker-expr'));
    links.add(const LinkModel(inputStepId: 'ds-cell-counts', outputStepId: 'ds-marker-expr'));
    links.add(const LinkModel(inputStepId: 'view-cell-counts', outputStepId: 'ds-cell-counts'));
    links.add(const LinkModel(inputStepId: 'ds-annotation', outputStepId: 'ds-cell-counts'));
    links.add(const LinkModel(inputStepId: 'ds-abundance', outputStepId: 'ds-annotation'));
    links.add(const LinkModel(inputStepId: 'view-abundance', outputStepId: 'ds-abundance'));
    links.add(const LinkModel(inputStepId: 'out-interpret', outputStepId: 'ds-abundance'));

    // ── Group 4: Differential Analysis ──
    steps.add(StepModel(
      id: 'grp-diffanal',
      name: 'Differential Analysis',
      groupId: '',
      kind: StepKind.groupStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'in-diffanal',
      name: 'In',
      groupId: 'grp-diffanal',
      kind: StepKind.inStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-diff-expr',
      name: 'Differential Expression',
      groupId: 'grp-diffanal',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-diff-expr',
      name: 'Volcano Plot',
      groupId: 'grp-diffanal',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-diff-abundance',
      name: 'Differential Abundance',
      groupId: 'grp-diffanal',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-diff-abundance',
      name: 'DA Barplot',
      groupId: 'grp-diffanal',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-stat-test',
      name: 'Statistical Test',
      groupId: 'grp-diffanal',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-pvalue-adj',
      name: 'P-value Adjustment',
      groupId: 'grp-diffanal',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'out-diffanal',
      name: 'Out',
      groupId: 'grp-diffanal',
      kind: StepKind.outStep,
      state: StepState.done,
    ));

    links.add(const LinkModel(inputStepId: 'in-diffanal', outputStepId: 'out-interpret'));
    links.add(const LinkModel(inputStepId: 'ds-diff-expr', outputStepId: 'in-diffanal'));
    links.add(const LinkModel(inputStepId: 'view-diff-expr', outputStepId: 'ds-diff-expr'));
    links.add(const LinkModel(inputStepId: 'ds-diff-abundance', outputStepId: 'ds-diff-expr'));
    links.add(const LinkModel(inputStepId: 'view-diff-abundance', outputStepId: 'ds-diff-abundance'));
    links.add(const LinkModel(inputStepId: 'ds-stat-test', outputStepId: 'ds-diff-abundance'));
    links.add(const LinkModel(inputStepId: 'ds-pvalue-adj', outputStepId: 'ds-stat-test'));
    links.add(const LinkModel(inputStepId: 'out-diffanal', outputStepId: 'ds-pvalue-adj'));

    // ── Group 5: Export ──
    steps.add(StepModel(
      id: 'grp-export',
      name: 'Export',
      groupId: '',
      kind: StepKind.groupStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'in-export',
      name: 'In',
      groupId: 'grp-export',
      kind: StepKind.inStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-export-csv',
      name: 'Export CSV',
      groupId: 'grp-export',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-export-fcs',
      name: 'Export FCS',
      groupId: 'grp-export',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'exp-report',
      name: 'Report',
      groupId: 'grp-export',
      kind: StepKind.exportStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-heatmaps',
      name: 'Heatmaps',
      groupId: 'grp-export',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-heatmaps',
      name: 'Heatmap Gallery',
      groupId: 'grp-export',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'ds-boxplots',
      name: 'Boxplots',
      groupId: 'grp-export',
      kind: StepKind.dataStep,
      state: StepState.done,
    ));
    steps.add(StepModel(
      id: 'view-boxplots',
      name: 'Boxplot Gallery',
      groupId: 'grp-export',
      kind: StepKind.viewStep,
      state: StepState.done,
    ));

    links.add(const LinkModel(inputStepId: 'in-export', outputStepId: 'out-diffanal'));
    links.add(const LinkModel(inputStepId: 'ds-export-csv', outputStepId: 'in-export'));
    links.add(const LinkModel(inputStepId: 'ds-export-fcs', outputStepId: 'in-export'));
    links.add(const LinkModel(inputStepId: 'exp-report', outputStepId: 'ds-export-csv'));
    links.add(const LinkModel(inputStepId: 'ds-heatmaps', outputStepId: 'ds-export-csv'));
    links.add(const LinkModel(inputStepId: 'view-heatmaps', outputStepId: 'ds-heatmaps'));
    links.add(const LinkModel(inputStepId: 'ds-boxplots', outputStepId: 'ds-export-fcs'));
    links.add(const LinkModel(inputStepId: 'view-boxplots', outputStepId: 'ds-boxplots'));

    // Top-level links: tables -> group
    links.add(const LinkModel(inputStepId: 'grp-preproc', outputStepId: 'table-fcs'));
    links.add(const LinkModel(inputStepId: 'grp-preproc', outputStepId: 'table-annot'));
    links.add(const LinkModel(inputStepId: 'grp-cluster', outputStepId: 'grp-preproc'));
    links.add(const LinkModel(inputStepId: 'grp-interpret', outputStepId: 'grp-cluster'));
    links.add(const LinkModel(inputStepId: 'grp-diffanal', outputStepId: 'grp-interpret'));
    links.add(const LinkModel(inputStepId: 'grp-export', outputStepId: 'grp-diffanal'));

    return WorkflowModel(
      id: 'abefdbb9bafdfd191f735d19689d53d1',
      name: 'Run - 2026-03-05 15.56',
      projectId: 'bdd5a7d79e8808876678026cd3001c46',
      steps: steps,
      links: links,
    );
  }
}
