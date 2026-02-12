import 'package:get_it/get_it.dart';
import '../domain/services/data_service.dart';
import '../implementations/services/mock_data_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Register services. Called once from main().
///
/// Mock mode: registers MockDataService.
/// Real mode: registers Tercen service with factory and taskId.
///
/// To add real Tercen service in Phase 3:
///   import 'package:sci_tercen_client/sci_client_service_factory.dart';
///   serviceLocator.registerSingleton<ServiceFactory>(tercenFactory);
///   serviceLocator.registerLazySingleton<DataService>(
///     () => TercenDataService(tercenFactory, taskId: taskId),
///   );
void setupServiceLocator({bool useMocks = true}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(
      () => MockDataService(),
    );
  }
  // Phase 3: add else branch for real Tercen service
}
