import '../../domain/models/user_state.dart';
import '../../domain/services/header_data_service.dart';

/// Real HeaderDataService backed by data from the orchestrator's init-context.
///
/// User state and LLM status are passed in at construction time from the
/// init-context postMessage payload. No async service calls needed — the
/// orchestrator provides everything the header needs at startup.
class TercenHeaderDataService implements HeaderDataService {
  final UserState _userState;
  final bool _llmConnected;

  TercenHeaderDataService({
    required UserState userState,
    required bool llmConnected,
  })  : _userState = userState,
        _llmConnected = llmConnected {
    print('[TercenHeaderDataService] initialized: '
        'user=${_userState.displayName}, '
        'identity=${_userState.identityString}, '
        'admin=${_userState.isAdmin}, '
        'llm=$_llmConnected');
  }

  @override
  UserState getUserState() {
    return _userState;
  }

  @override
  bool isLlmConnected() {
    return _llmConnected;
  }
}
