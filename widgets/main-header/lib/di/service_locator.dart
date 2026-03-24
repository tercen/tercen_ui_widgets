import 'package:get_it/get_it.dart';

import '../domain/services/event_bus.dart';
import '../domain/services/header_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Register services. Called once from main() after init-context is received.
///
/// Both [eventBus] and [dataService] are required — no fallback to mocks.
void setupServiceLocator({
  required EventBus eventBus,
  required HeaderDataService dataService,
}) {
  if (serviceLocator.isRegistered<EventBus>()) {
    print('[ServiceLocator] WARNING: services already registered, skipping');
    return;
  }

  serviceLocator.registerSingleton<EventBus>(eventBus);
  serviceLocator.registerSingleton<HeaderDataService>(dataService);

  print('[ServiceLocator] registered EventBus and HeaderDataService');
}
