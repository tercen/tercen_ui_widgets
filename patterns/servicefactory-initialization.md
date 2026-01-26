# Pattern: ServiceFactory Initialization

## Overview

The `ServiceFactory` is the central access point for all Tercen API services. It uses a **singleton pattern** and requires different initialization approaches for different use cases.

**Two initialization patterns:**
1. **Web App Pattern** - For Flutter web apps running in Tercen
2. **Standalone Tool Pattern** - For CLI tools and debugging scripts

## The Singleton Pattern

```dart
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

// Access singleton
tercen.ServiceFactory();

// Or via CURRENT static
tercen.ServiceFactory.CURRENT;
```

**All services accessed through this singleton:**
```dart
// Task operations
await tercen.ServiceFactory().taskService.get(taskId);

// File operations
await tercen.ServiceFactory().fileService.download(fileId);

// Table operations
await tercen.ServiceFactory().tableSchemaService.get(hash);

// Document operations
await tercen.ServiceFactory().documentService.get(docId);
```

## Pattern A: Web App Initialization

**Use case**: Flutter web apps running in Tercen platform

### Setup

```dart
// lib/main.dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'package:sci_tercen_client/sci_client.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ServiceFactory for web app
  final tercenFactory = await createServiceFactoryForWebApp();

  // Register with dependency injection
  getIt.registerSingleton<ServiceFactory>(tercenFactory);

  // Register services
  setupServiceLocator(useMocks: false);

  runApp(MyApp());
}
```

### How It Works

`createServiceFactoryForWebApp()` automatically:
1. Reads authentication token from localStorage
2. Detects service URI from current location
3. Creates authenticated HTTP client
4. Initializes ServiceFactory singleton
5. Sets `ServiceFactory.CURRENT`

**No manual token management required.**

### Development Mode

For local development, inject credentials via `web/index.html`:

```html
<!-- web/index.html -->
<script>
  if (window.location.hostname === 'localhost' ||
      window.location.hostname === '127.0.0.1') {

    const devToken = 'YOUR_DEV_TOKEN_HERE';
    const serviceUri = 'https://stage.tercen.com';

    localStorage.setItem('tercen.token', devToken);
    localStorage.setItem('tercen.serviceUri', serviceUri);

    console.log('🔧 DEV MODE: Set Tercen credentials in localStorage');
  }
</script>
```

**Get dev token:**
1. Login to Tercen in browser
2. Open DevTools → Application → Local Storage
3. Find `tercen.token`
4. Copy value

### Accessing Services

```dart
// Direct access (anywhere in app)
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

final task = await tercen.ServiceFactory().taskService.get(taskId);
```

Or via dependency injection:

```dart
// In service class
class TercenImageService {
  final ServiceFactory _factory;

  TercenImageService(this._factory);

  Future<void> doSomething() async {
    final task = await _factory.taskService.get(taskId);
  }
}

// Registration
getIt.registerSingleton<ImageService>(
  TercenImageService(getIt<ServiceFactory>()),
);
```

## Pattern B: Standalone Tool Initialization

**Use case**: CLI debugging tools, scripts, standalone Dart programs

### Setup

```dart
// tools/print_task_json.dart
import 'dart:io';
import 'dart:convert';
import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:sci_http_client/http_io_client.dart' as io_http;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

void main(List<String> args) async {
  if (args.length != 3) {
    print('Usage: dart run tools/print_task_json.dart <serviceUrl> <token> <taskId>');
    exit(1);
  }

  final serviceUrl = args[0];
  final token = args[1];
  final taskId = args[2];

  // Initialize ServiceFactory with manual auth
  var factory = ServiceFactory();
  var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
  await factory.initializeWith(Uri.parse(serviceUrl), authClient);
  tercen.ServiceFactory.CURRENT = factory;

  // Now use services
  final task = await tercen.ServiceFactory().taskService.get(taskId);
  print(JsonEncoder.withIndent('  ').convert(task.toJson()));
}
```

### How It Works

1. Create `ServiceFactory` instance
2. Create `HttpAuthClient` with token
3. Wrap with `HttpIOClient` for non-browser environments
4. Initialize factory with URI and auth client
5. Set global singleton
6. Services now available

### Key Differences from Web Pattern

| Aspect | Web App | Standalone Tool |
|--------|---------|-----------------|
| Import | `sci_service_factory_web.dart` | Base `ServiceFactory` |
| HTTP Client | Browser-based (automatic) | `HttpIOClient` (manual) |
| Auth | From localStorage | Command-line argument |
| Initialization | `createServiceFactoryForWebApp()` | `factory.initializeWith()` |
| Use Case | Production app | Debug/development |

## Common Patterns

### Pattern 1: Web App with Mock Fallback

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ServiceFactory? tercenFactory;
  bool useMocks = false;

  try {
    // Try to initialize Tercen
    tercenFactory = await createServiceFactoryForWebApp();
    getIt.registerSingleton<ServiceFactory>(tercenFactory);
    print('✓ Connected to Tercen');
  } catch (e) {
    print('⚠️ Could not connect to Tercen: $e');
    print('   Falling back to mock data');
    useMocks = true;
  }

  setupServiceLocator(useMocks: useMocks);
  runApp(MyApp());
}
```

### Pattern 2: Conditional Initialization Based on Environment

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isProduction = const bool.fromEnvironment('PRODUCTION', defaultValue: false);

  if (isProduction) {
    // Production: use Tercen
    final tercenFactory = await createServiceFactoryForWebApp();
    getIt.registerSingleton<ServiceFactory>(tercenFactory);
    setupServiceLocator(useMocks: false);
  } else {
    // Development: use mocks
    setupServiceLocator(useMocks: true);
  }

  runApp(MyApp());
}
```

### Pattern 3: Lazy Initialization

```dart
class TercenService {
  ServiceFactory? _factory;

  Future<ServiceFactory> get factory async {
    if (_factory != null) return _factory!;

    _factory = await createServiceFactoryForWebApp();
    return _factory!;
  }

  Future<Task> getTask(String taskId) async {
    final sf = await factory;
    return sf.taskService.get(taskId);
  }
}
```

## Service Access

Once initialized, access these services:

```dart
// Task Service
final taskService = tercen.ServiceFactory().taskService;
final task = await taskService.get(taskId);

// File Service
final fileService = tercen.ServiceFactory().fileService;
final stream = fileService.download(fileId);
final files = await fileService.findFileByWorkflowIdAndStepId(...);

// Table Schema Service
final schemaService = tercen.ServiceFactory().tableSchemaService;
final schema = await schemaService.get(columnHash);
final data = await schemaService.select(columnHash, ['col1'], 0, 10);

// Document Service
final docService = tercen.ServiceFactory().documentService;
final doc = await docService.get(documentId);

// Project Service
final projectService = tercen.ServiceFactory().projectService;
final project = await projectService.get(projectId);

// User Service
final userService = tercen.ServiceFactory().userService;
final user = await userService.get(userId);
```

## Error Handling

### Web App Initialization Failure

```dart
try {
  final tercenFactory = await createServiceFactoryForWebApp();
  getIt.registerSingleton<ServiceFactory>(tercenFactory);
} on TercenException catch (e) {
  print('❌ Tercen initialization failed: ${e.message}');
  // Fallback to mocks
} on Exception catch (e) {
  print('❌ Unexpected error: $e');
  // Fallback to mocks
}
```

### Service Call Failure

```dart
try {
  final task = await tercen.ServiceFactory().taskService.get(taskId);
} on NotFoundException catch (e) {
  print('❌ Task not found: $taskId');
} on UnauthorizedException catch (e) {
  print('❌ Not authorized to access task');
} on TercenException catch (e) {
  print('❌ Tercen error: ${e.message}');
}
```

## Testing

### Mock ServiceFactory

```dart
class MockServiceFactory implements ServiceFactory {
  @override
  TaskService get taskService => MockTaskService();

  @override
  FileService get fileService => MockFileService();

  // ... other services
}

// In tests
void main() {
  setUp(() {
    final mockFactory = MockServiceFactory();
    getIt.registerSingleton<ServiceFactory>(mockFactory);
  });

  test('service uses factory', () async {
    final service = TercenImageService(getIt<ServiceFactory>());
    // Test with mock
  });
}
```

### Test Web App Initialization

```dart
testWidgets('initializes ServiceFactory', (tester) async {
  // Mock localStorage for test
  mockLocalStorage({
    'tercen.token': 'test-token',
    'tercen.serviceUri': 'https://test.tercen.com',
  });

  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  // Verify factory initialized
  expect(getIt.isRegistered<ServiceFactory>(), isTrue);
});
```

## Debugging

### Check Initialization Status

```dart
void main() async {
  print('🔍 Initializing ServiceFactory...');

  try {
    final factory = await createServiceFactoryForWebApp();
    print('✓ ServiceFactory initialized');
    print('  Services available:');
    print('    - taskService: ${factory.taskService != null}');
    print('    - fileService: ${factory.fileService != null}');
    print('    - tableSchemaService: ${factory.tableSchemaService != null}');
  } catch (e, stackTrace) {
    print('❌ Initialization failed: $e');
    print('Stack trace:');
    print(stackTrace);
  }
}
```

### Verify Authentication

```dart
try {
  // Try a simple API call
  final user = await tercen.ServiceFactory().userService.whoAmI();
  print('✓ Authenticated as: ${user.name}');
} catch (e) {
  print('❌ Authentication failed: $e');
}
```

## Common Issues

### Issue 1: CORS Errors
**Symptom**: "CORS policy" errors in console
**Cause**: Not using ServiceFactory, making manual HTTP calls
**Fix**: Always use ServiceFactory services, never manual fetch()

### Issue 2: Authentication Failures
**Symptom**: 401 Unauthorized errors
**Cause**: Token not in localStorage or expired
**Fix**: Check localStorage, refresh token, verify dev credentials

### Issue 3: Singleton Not Set
**Symptom**: `ServiceFactory.CURRENT` is null
**Cause**: Forgot to call initialization
**Fix**: Call `createServiceFactoryForWebApp()` or `factory.initializeWith()`

### Issue 4: Wrong Initialization Pattern
**Symptom**: "Unsupported operation" in standalone tools
**Cause**: Using web-specific imports in CLI tools
**Fix**: Use `HttpIOClient` for standalone tools, not web pattern

## Checklist

- [ ] Understand two initialization patterns
- [ ] Use web pattern for Flutter apps
- [ ] Use standalone pattern for tools
- [ ] Initialize before first service call
- [ ] Register with dependency injection (if using)
- [ ] Add dev credentials for local testing
- [ ] Handle initialization failures gracefully
- [ ] Test with mock fallback
- [ ] Verify authentication after init
- [ ] Use ServiceFactory for all API calls (avoid CORS)

## Related

- **Pattern**: [Authentication](authentication.md)
- **Pattern**: [Debug Tools](debug-tools.md)
- **Issue**: [#3 CORS Errors](../issues/3-cors-errors.md)
- **Skill**: [2 Tercen Real Implementation](../skills/2-tercen-real.md)
