import '../../domain/services/data_service.dart';
import '../../presentation/providers/app_state_provider.dart';

/// Mock Type 3 data service — demonstrates the stateful service pattern.
///
/// Replace with your app's mock data loaded from CSV/JSON assets.
/// Pre-populates run history and provides sample results for display mode.
class MockDataService implements DataService {
  @override
  Future<List<RunEntry>> getRunHistory() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Pre-populated demo history entries
    return [
      RunEntry(
        id: 'demo_run_1',
        name: 'Run 1 — Default settings',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'complete',
        settings: {'param1': 'value1', 'param2': 42},
      ),
      RunEntry(
        id: 'demo_run_2',
        name: 'Run 2 — High threshold',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'complete',
        settings: {'param1': 'value2', 'param2': 85},
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getResults(String runId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Return demo results keyed by run ID
    return {
      'summary': 'Results for $runId',
      'itemCount': runId == 'demo_run_1' ? 150 : 230,
      'status': 'Analysis complete',
    };
  }

  @override
  Future<Map<String, dynamic>> getInputConfig(int stage) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Demo: single-stage input
    return {
      'stage': stage,
      'heading': 'Configure analysis',
      'fields': ['param1', 'param2'],
    };
  }

  @override
  Future<int> submitInput(Map<String, dynamic> settings) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Demo: single stage, always ready to run
    return -1;
  }
}
