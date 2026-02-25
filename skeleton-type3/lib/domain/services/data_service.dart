import '../../presentation/providers/app_state_provider.dart';

/// Type 3 data service interface.
///
/// Stateful service that tracks input stages and provides run history/results.
/// Phase 2: mock implementation loads from assets.
/// Phase 3: real implementation connects to Tercen APIs.
abstract class DataService {
  /// Get the run history (pre-populated in mock, from project in real).
  Future<List<RunEntry>> getRunHistory();

  /// Get result data for a specific run.
  Future<Map<String, dynamic>> getResults(String runId);

  /// Get input configuration for the given stage.
  Future<Map<String, dynamic>> getInputConfig(int stage);

  /// Submit input settings. Returns the next stage index, or -1 if ready to run.
  Future<int> submitInput(Map<String, dynamic> settings);
}
