import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../domain/services/data_service.dart';

/// App states — two hard states.
enum AppState { running, waiting }

/// Content panel modes.
enum ContentMode { input, display }

/// A run history entry.
class RunEntry {
  final String id;
  final String name;
  final DateTime timestamp;
  final String status; // 'complete', 'error', 'stopped'
  final Map<String, dynamic> settings;

  const RunEntry({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.status,
    this.settings = const {},
  });
}

/// Type 3 AppStateProvider — manages app state, content mode, run history,
/// and current run settings.
///
/// Replace the demo fields with your app's specific state. Keep the state
/// machine structure (appState, contentMode, run history) and extend with
/// app-specific input stages and settings.
class AppStateProvider extends ChangeNotifier {
  final DataService _dataService;

  AppStateProvider({DataService? dataService})
      : _dataService = dataService ?? serviceLocator<DataService>();

  // --- App state machine ---
  AppState _appState = AppState.waiting;
  AppState get appState => _appState;
  bool get isRunning => _appState == AppState.running;

  ContentMode _contentMode = ContentMode.input;
  ContentMode get contentMode => _contentMode;

  // --- Data loading (initial load from mock service) ---
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final history = await _dataService.getRunHistory();
      _runHistory = history;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Header Panel config ---
  String _headerHeading = 'Getting started';
  String get headerHeading => _headerHeading;

  String _headerActionLabel = 'Continue';
  String get headerActionLabel => _headerActionLabel;

  void setHeaderConfig({required String heading, String actionLabel = 'Continue'}) {
    _headerHeading = heading;
    _headerActionLabel = actionLabel;
    notifyListeners();
  }

  // --- Current input stage (for multi-stage input flows) ---
  int _currentStage = 0;
  int get currentStage => _currentStage;

  // --- Current run settings ---
  final Map<String, dynamic> _currentSettings = {};
  Map<String, dynamic> get currentSettings => Map.unmodifiable(_currentSettings);

  void updateSetting(String key, dynamic value) {
    _currentSettings[key] = value;
    notifyListeners();
  }

  // --- Run history ---
  List<RunEntry> _runHistory = [];
  List<RunEntry> get runHistory => List.unmodifiable(_runHistory);

  String? _selectedRunId;
  String? get selectedRunId => _selectedRunId;

  RunEntry? get selectedRun {
    if (_selectedRunId == null) return null;
    try {
      return _runHistory.firstWhere((r) => r.id == _selectedRunId);
    } catch (_) {
      return null;
    }
  }

  // --- Display mode result data ---
  Map<String, dynamic> _currentResults = {};
  Map<String, dynamic> get currentResults => _currentResults;

  // --- Actions ---

  /// Start a run. In mock mode, transitions immediately to Display.
  void startRun() {
    // In mock: immediate transition (no Running simulation)
    final runId = 'run_${_runHistory.length + 1}';
    final entry = RunEntry(
      id: runId,
      name: 'Run ${_runHistory.length + 1}',
      timestamp: DateTime.now(),
      status: 'complete',
      settings: Map.from(_currentSettings),
    );
    _runHistory.insert(0, entry);
    _selectedRunId = runId;
    _contentMode = ContentMode.display;
    _headerHeading = entry.name;
    _appState = AppState.waiting;
    notifyListeners();
  }

  /// Stop the current run. In mock mode, this is a no-op.
  void stopRun() {
    _appState = AppState.waiting;
    notifyListeners();
  }

  /// Reset the app to its initial state.
  void resetApp() {
    _appState = AppState.waiting;
    _contentMode = ContentMode.input;
    _currentStage = 0;
    _currentSettings.clear();
    _selectedRunId = null;
    _currentResults = {};
    _headerHeading = 'Getting started';
    _headerActionLabel = 'Continue';
    notifyListeners();
  }

  /// Select a history entry to view in Display mode.
  void selectHistoryEntry(String runId) {
    _selectedRunId = runId;
    _contentMode = ContentMode.display;
    final run = selectedRun;
    if (run != null) {
      _headerHeading = run.name;
    }
    _appState = AppState.waiting;
    notifyListeners();
  }

  /// Initiate a re-run from an existing run. Returns to Input mode
  /// with settings pre-loaded from the selected run.
  void initiateReRun(String runId) {
    final run = _runHistory.firstWhere((r) => r.id == runId);
    _currentSettings
      ..clear()
      ..addAll(run.settings);
    _contentMode = ContentMode.input;
    _currentStage = 0;
    _headerHeading = 'Getting started';
    _headerActionLabel = 'Continue';
    notifyListeners();
  }

  /// Delete a run and its results.
  void deleteRun(String runId) {
    _runHistory.removeWhere((r) => r.id == runId);
    if (_selectedRunId == runId) {
      if (_runHistory.isNotEmpty) {
        selectHistoryEntry(_runHistory.first.id);
      } else {
        _selectedRunId = null;
        _contentMode = ContentMode.input;
        _headerHeading = 'Getting started';
        _headerActionLabel = 'Continue';
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Navigate to the next input stage.
  void navigateToStage(int stage) {
    _currentStage = stage;
    notifyListeners();
  }

  /// Check if all required inputs for the current stage are provided.
  bool get isInputComplete {
    // Override in your app to check required fields.
    return _currentSettings.isNotEmpty;
  }
}
