import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../domain/models/content_state.dart';
import '../../domain/models/window_identity.dart';
import '../../domain/services/data_service.dart';

/// Manages the window's content state and identity.
///
/// Extend this provider for your window type to add domain-specific state.
class WindowStateProvider extends ChangeNotifier {
  final DataService _dataService = serviceLocator<DataService>();

  /// The window's identity — type, colour, label.
  /// Set these in your window type's constructor.
  final WindowIdentity identity;

  /// Current body content state.
  ContentState _contentState = ContentState.empty;
  ContentState get contentState => _contentState;

  /// Data loaded from the service (placeholder type — replace with your model).
  Map<String, dynamic>? _data;
  Map<String, dynamic>? get data => _data;

  /// Error message when in error state.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WindowStateProvider({required this.identity});

  /// Transition to a content state.
  void setContentState(ContentState state) {
    _contentState = state;
    notifyListeners();
  }

  /// Update the window label. In production, this triggers a
  /// `contentChanged` event via the event bus so the Frame updates the tab.
  void updateLabel(String newLabel) {
    identity.label = newLabel;
    notifyListeners();
    // TODO: emit contentChanged via event bus
  }

  /// Load data from the service.
  /// Transitions: empty/error -> loading -> active/error.
  Future<void> loadData() async {
    _contentState = ContentState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _dataService.loadData();
      _contentState = ContentState.active;
    } catch (e) {
      _errorMessage = e.toString();
      _contentState = ContentState.error;
    }
    notifyListeners();
  }
}
