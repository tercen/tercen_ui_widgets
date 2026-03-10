/// Abstract data service interface.
/// Replace with your app's domain-specific service.
///
/// Phase 2: Create mock implementation that loads from assets.
/// Phase 3: Create real implementation that queries Tercen API.
abstract class DataService {
  /// Load the app's data. Returns a map of key-value pairs as a placeholder.
  /// Replace the return type with your domain model.
  Future<Map<String, dynamic>> loadData();
}
