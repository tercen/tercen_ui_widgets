# URL Path Parsing Pattern

**Context**: Tercen web apps support two deployment modes with different URL structures

**Related Skills**: [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)

## Problem

Tercen deploys Flutter web apps in two different modes:

1. **Standalone mode**: App operates independently
2. **Workflow mode**: App embedded in Tercen workflow context

Each mode uses different URL path structures to identify data sources. Apps must parse URLs correctly to determine which mode and extract relevant IDs.

## Two Deployment Modes

### Mode 1: Standalone (_w3op)

**URL Pattern**: `https://tercen.com/_w3op/{documentId}/`

**Example**: `https://stage.tercen.com/_w3op/abc123def456/`

**Use case**: Operator launched directly, not from workflow

### Mode 2: Workflow (w/ds)

**URL Pattern**: `https://tercen.com/w/{workflowId}/ds/{stepId}`

**Example**: `https://stage.tercen.com/w/workflow123/ds/step456`

**Use case**: Operator embedded in workflow, step context provided

## Pattern Implementation

### Full URL Parsing Logic

```dart
// lib/main.dart or lib/utils/url_parser.dart

class TercenUrlParser {
  String? documentId;
  String? workflowId;
  String? stepId;
  String? taskId;  // Present when running in Data Step context
  bool isStandaloneMode = false;
  bool isWorkflowMode = false;

  TercenUrlParser() {
    _parseUrl();
  }

  /// Returns true if app is running inside a Data Step (has taskId parameter)
  bool get isInDataStep => taskId != null;

  /// Returns true if app should show its own top bar (not in Data Step)
  bool get shouldShowTopBar => !isInDataStep;

  void _parseUrl() {
    final uri = Uri.base;
    final pathSegments = uri.pathSegments;

    print('🔍 Parsing URL: ${uri.toString()}');
    print('📋 Path segments: $pathSegments');

    // Check for Data Step context (taskId in query parameters)
    taskId = uri.queryParameters['taskId'];
    if (taskId != null) {
      print('✓ Data Step context detected: taskId=$taskId');
    }

    // Mode 1: Standalone - /_w3op/{documentId}/
    if (pathSegments.contains('_w3op')) {
      final index = pathSegments.indexOf('_w3op');
      if (index + 1 < pathSegments.length) {
        documentId = pathSegments[index + 1];
        isStandaloneMode = true;
        print('✓ Standalone mode detected: documentId=$documentId');
      }
    }
    // Mode 2: Workflow - /w/{workflowId}/ds/{stepId}
    else if (pathSegments.contains('w') && pathSegments.contains('ds')) {
      final wIndex = pathSegments.indexOf('w');
      final dsIndex = pathSegments.indexOf('ds');

      if (wIndex + 1 < pathSegments.length && dsIndex + 1 < pathSegments.length) {
        workflowId = pathSegments[wIndex + 1];
        stepId = pathSegments[dsIndex + 1];
        isWorkflowMode = true;
        print('✓ Workflow mode detected: workflowId=$workflowId, stepId=$stepId');
      }
    }
    // Development mode (localhost)
    else if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      print('🔧 DEV MODE: localhost detected, will use mock data or query params');
    }
    else {
      print('✗ No valid Tercen URL pattern detected');
    }
  }

  bool get hasValidContext => isStandaloneMode || isWorkflowMode;
}
```

### Usage in Main

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse URL to determine deployment mode
  final urlParser = TercenUrlParser();

  // Create service factory
  final tercenFactory = await createServiceFactoryForWebApp();

  // Pass parsed context to services
  getIt.registerSingleton<ServiceFactory>(tercenFactory);
  getIt.registerSingleton<TercenUrlParser>(urlParser);

  runApp(MyApp());
}
```

### Using Parsed IDs in Services

```dart
class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final TercenUrlParser _urlParser;

  TercenImageService(this._factory, this._urlParser);

  Future<List<FileDocument>> loadFiles() async {
    final fileService = _factory.fileService;

    if (_urlParser.isWorkflowMode) {
      // Load files by workflow and step IDs
      final files = await fileService.findFileByWorkflowIdAndStepId(
        startKey: [_urlParser.workflowId, _urlParser.stepId],
        endKey: [_urlParser.workflowId, _urlParser.stepId, {}],
      );
      return files;
    }
    else if (_urlParser.isStandaloneMode) {
      // Load files by document ID
      final document = await _factory.documentService.get(_urlParser.documentId!);
      // Process document...
      return [];
    }
    else {
      throw Exception('No valid Tercen context detected');
    }
  }
}
```

## Debug Logging

Add comprehensive logging to troubleshoot URL parsing issues:

```dart
void _parseUrl() {
  final uri = Uri.base;
  final pathSegments = uri.pathSegments;

  print('🔍 URL Parsing Debug:');
  print('  Full URL: ${uri.toString()}');
  print('  Host: ${uri.host}');
  print('  Path: ${uri.path}');
  print('  Segments: $pathSegments');
  print('  Query params: ${uri.queryParameters}');

  // ... parsing logic with success/failure prints
}
```

## Common Mistakes

### ❌ WRONG: Query parameter parsing

```dart
// DON'T DO THIS - Tercen uses path segments, not query params
final workflowId = Uri.base.queryParameters['workflowId'];
```

### ❌ WRONG: Hardcoded indices

```dart
// DON'T DO THIS - path structure can vary
final workflowId = pathSegments[2]; // Fragile!
```

### ✅ CORRECT: Search for segment names

```dart
// DO THIS - robust to path variations
if (pathSegments.contains('w')) {
  final wIndex = pathSegments.indexOf('w');
  workflowId = pathSegments[wIndex + 1];
}
```

## Testing Different Modes

### Test Standalone Mode

```dart
// Simulate standalone URL in tests
void testStandaloneMode() {
  // Mock Uri.base to return: https://tercen.com/_w3op/doc123/
  final parser = TercenUrlParser();
  expect(parser.isStandaloneMode, true);
  expect(parser.documentId, 'doc123');
}
```

### Test Workflow Mode

```dart
// Simulate workflow URL in tests
void testWorkflowMode() {
  // Mock Uri.base to return: https://tercen.com/w/wf123/ds/step456
  final parser = TercenUrlParser();
  expect(parser.isWorkflowMode, true);
  expect(parser.workflowId, 'wf123');
  expect(parser.stepId, 'step456');
}
```

## Development Mode Handling

```dart
// For local development, use query params or hardcoded values
void _parseUrl() {
  final uri = Uri.base;

  // Development mode (localhost)
  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    // Option 1: Read from query params for testing
    workflowId = uri.queryParameters['workflowId'];
    stepId = uri.queryParameters['stepId'];

    // Option 2: Hardcoded for quick testing
    workflowId ??= 'dev-workflow-123';
    stepId ??= 'dev-step-456';

    isWorkflowMode = true;
    print('🔧 DEV MODE: Using workflowId=$workflowId, stepId=$stepId');
    return;
  }

  // Production URL parsing...
}
```

## Error Handling

```dart
Future<List<FileDocument>> loadFiles() async {
  if (!_urlParser.hasValidContext) {
    print('✗ No valid Tercen context - falling back to mock data');
    return _mockService.loadImages();
  }

  try {
    // Attempt to load from Tercen...
  } catch (e) {
    print('✗ Error loading from Tercen: $e');
    print('Falling back to mock data');
    return _mockService.loadImages();
  }
}
```

## Context Detection (Data Step vs Full Screen)

In addition to deployment mode, apps need to detect their execution context to determine UI behaviour.

### The Rule

**If `Uri.base` contains the `taskId` query parameter, the app is running inside a Data Step.**

This was confirmed by the Tercen platform team (January 2026).

### Implementation

```dart
// Add to TercenUrlParser class
String? taskId;

bool get isInDataStep => taskId != null;
bool get shouldShowTopBar => !isInDataStep;

void _parseUrl() {
  final uri = Uri.base;

  // Check for Data Step context
  taskId = uri.queryParameters['taskId'];

  // ... rest of URL parsing
}
```

### UI Behaviour by Context

| Context | `taskId` | Top Bar | Close Button |
|---------|----------|---------|--------------|
| Data Step (embedded) | Present | Hidden | Not needed |
| Full screen | Absent | Visible | Required |

### Example URLs

```
# Data Step context (has taskId)
https://tercen.com/w/wf123/ds/step456?taskId=task789
→ isInDataStep = true
→ shouldShowTopBar = false

# Full screen context (no taskId)
https://tercen.com/w/wf123/ds/step456
→ isInDataStep = false
→ shouldShowTopBar = true
```

See [Pattern: App Frame](app-frame.md) for complete top bar implementation.

## See Also

- [Pattern: App Frame](app-frame.md)
- [Pattern: Authentication](authentication.md)
- [Pattern: Error Handling](error-handling.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
- [Issue #8: Mandatory Workflow](../issues/8-mandatory-workflow.md)
