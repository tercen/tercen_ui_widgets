# Authentication Pattern

**Context**: Tercen web app authentication using sci_tercen_client

**Related Issues**: [Issue #3: CORS Errors](../issues/3-cors-errors.md)

**Related Skills**: [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)

## Problem

Flutter web apps need to authenticate with Tercen platform API. Manual HTTP authentication causes:
- CORS errors in browser
- Token management complexity
- Different behavior between dev/production environments

## Solution

Use `sci_tercen_client` package with `createServiceFactoryForWebApp()` pattern.

**See also**: [Pattern: ServiceFactory Initialization](servicefactory-initialization.md) for detailed initialization patterns.

## ServiceFactory Singleton

The ServiceFactory uses a **singleton pattern** for global access:

```dart
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

// Access singleton anywhere
final task = await tercen.ServiceFactory().taskService.get(taskId);
```

**All services accessed through this singleton:**

- `taskService` - Task operations
- `fileService` - File operations
- `tableSchemaService` - Table/column operations
- `documentService` - Document operations
- `projectService` - Project operations
- And 10+ other services

## Pattern

### 1. Add Dependency

```yaml
# pubspec.yaml
dependencies:
  sci_tercen_client:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: 1.7.0
      path: sci_tercen_client
```

### 2. Web App Authentication

```dart
// lib/main.dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create service factory - handles auth automatically
  final tercenFactory = await createServiceFactoryForWebApp();

  // Register with dependency injection
  getIt.registerSingleton<ServiceFactory>(tercenFactory);

  runApp(MyApp());
}
```

### 3. Token Source

`createServiceFactoryForWebApp()` reads token from:

1. **URL Query Parameters** (Tercen deployment):
   - `?token=xxx&serviceUri=https://stage.tercen.com`

2. **localStorage** (Development mode):
   - `localStorage.getItem('tercen.token')`
   - `localStorage.getItem('tercen.serviceUri')`

### 4. Development Mode Setup

```html
<!-- web/index.html -->
<script>
  // Check if we're in development mode (localhost)
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    // Set the Tercen token for local development
    const devToken = 'YOUR_DEV_TOKEN_HERE';
    const serviceUri = 'https://stage.tercen.com';

    localStorage.setItem('tercen.token', devToken);
    localStorage.setItem('tercen.serviceUri', serviceUri);

    console.log('🔧 DEV MODE: Set Tercen credentials in localStorage');
  }
</script>
```

### 5. Using Services

```dart
// Access services via factory
class TercenImageService implements ImageService {
  final ServiceFactory _factory;

  TercenImageService(this._factory);

  Future<List<FileDocument>> loadFiles() async {
    final fileService = _factory.fileService;

    final files = await fileService.findFileByWorkflowIdAndStepId(
      startKey: [workflowId, stepId],
      endKey: [workflowId, stepId, {}],
    );

    return files;
  }

  Future<Uint8List> downloadFile(String fileId) async {
    final stream = _factory.fileService.download(fileId);
    // See file-streaming.md pattern
  }
}
```

## Key Points

- **Never** implement authentication manually - always use `sci_tercen_client`
- **Never** make direct HTTP calls - CORS will block them
- `ServiceFactory` provides pre-authenticated services (fileService, workflowService, etc.)
- Token management is handled automatically
- Works in both development (localStorage) and production (URL params)

## Repository Reference

**Auto-fetch for examples**:

```bash
# Clone sci_tercen_client for reference
gh repo clone tercen/sci_tercen_client --depth 1 /tmp/tercen-refs/sci_tercen_client
```

**Key files**:
- `lib/sci_service_factory_web.dart` - Web authentication implementation
- `lib/sci_client_service_factory.dart` - ServiceFactory interface

## Common Mistakes

### ❌ WRONG: Manual HTTP calls

```dart
// DON'T DO THIS - will cause CORS errors
final response = await http.get(
  Uri.parse('https://tercen.com/api/files/$fileId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

### ✅ CORRECT: Use ServiceFactory

```dart
// DO THIS - CORS handled automatically
final fileService = _factory.fileService;
final file = await fileService.get(fileId);
```

## Testing

### Local Testing

1. Get token from Tercen (login to stage.tercen.com, inspect network tab)
2. Add to web/index.html development script
3. Run `flutter run -d chrome`
4. Verify auth works with API calls

### Production Testing

1. Build with `flutter build web --wasm`
2. Commit build/web/
3. Push to GitHub
4. Tercen passes token via URL parameters automatically

## Error Handling

```dart
try {
  final factory = await createServiceFactoryForWebApp();
  // Use factory...
} catch (e) {
  print('✗ Authentication failed: $e');
  // Fall back to mock data if needed
}
```

## See Also

- [Issue #3: CORS Errors](../issues/3-cors-errors.md)
- [Pattern: Error Handling](error-handling.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
