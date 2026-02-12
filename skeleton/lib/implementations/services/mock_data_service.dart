import '../../domain/services/data_service.dart';

/// Mock implementation that returns placeholder data.
/// Replace with real mock data loaded from CSV/assets for your app.
class MockDataService implements DataService {
  @override
  Future<Map<String, dynamic>> loadData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'itemCount': 42,
      'status': 'Mock data loaded',
      'items': ['Alpha', 'Beta', 'Gamma', 'Delta'],
    };
  }
}
