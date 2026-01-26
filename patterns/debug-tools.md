# Pattern: Debug Tools and JSON Inspection

## Overview

Creating standalone debugging tools in the `tools/` directory is essential for understanding Tercen API responses without running the full application.

**Key benefits:**
- Inspect task structure before implementation
- Understand available columns and data
- Test API calls independently
- Debug production issues
- Document API behavior

## The tools/ Directory Pattern

```
project/
├── lib/                    # Application code
├── tools/                  # ← Debug tools here
│   ├── print_task_json.dart
│   ├── list_files.dart
│   └── inspect_schema.dart
├── pubspec.yaml
└── README.md
```

**Convention**: Tools are standalone Dart scripts with `main()` functions.

## Pattern: print_task_json.dart

**Purpose**: Fetch and inspect full task JSON structure

### Implementation

```dart
// tools/print_task_json.dart
import 'dart:io';
import 'dart:convert';

import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:sci_http_client/http_io_client.dart' as io_http;
import 'package:sci_tercen_client/sci_client.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

/// Fetches and pretty-prints a Tercen task as JSON
///
/// Usage:
///   dart run tools/print_task_json.dart <serviceUrl> <token> <taskId>
///
/// Example:
///   dart run tools/print_task_json.dart "https://stage.tercen.com" "eyJ..." "848a5d..."
void main(List<String> args) async {
  if (args.length != 3) {
    print('Usage: dart run tools/print_task_json.dart <serviceUrl> <token> <taskId>');
    print('');
    print('Example:');
    print('  dart run tools/print_task_json.dart "https://stage.tercen.com" "eyJ..." "848a5d..."');
    exit(1);
  }

  final serviceUrl = args[0];
  final token = args[1];
  final taskId = args[2];

  print('Fetching task from Tercen...');
  print('  Service URL: $serviceUrl');
  print('  Task ID: $taskId');
  print('');

  try {
    // Initialize ServiceFactory with auth token (standalone pattern)
    var factory = ServiceFactory();
    var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
    await factory.initializeWith(Uri.parse(serviceUrl), authClient);
    tercen.ServiceFactory.CURRENT = factory;

    // Fetch the task
    print('Calling taskService.get($taskId)...');
    final task = await tercen.ServiceFactory().taskService.get(taskId);

    // Convert to JSON and pretty print
    final encoder = JsonEncoder.withIndent('  ');
    final prettyJson = encoder.convert(task.toJson());

    print('');
    print('Task JSON:');
    print('═' * 80);
    print(prettyJson);
    print('═' * 80);

    // Print summary
    print('');
    print('Summary:');
    print('  Task ID: ${task.id}');
    print('  Task kind: ${task.kind}');
    print('  Task type: ${task.runtimeType}');

    if (task is RunWebAppTask) {
      print('  → RunWebAppTask');
      print('    cubeQueryTaskId: ${task.cubeQueryTaskId}');
      print('    operatorId: ${task.operatorId}');
    } else if (task is CubeQueryTask) {
      print('  → CubeQueryTask');
      print('    Has query: ${task.query != null}');
      if (task.query != null) {
        print('    columnHash: ${task.query!.columnHash}');
      }
    }

    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    exit(1);
  }
}
```

### Usage

```bash
# Get token from Tercen
# Login to Tercen → DevTools → Application → Local Storage → tercen.token

dart run tools/print_task_json.dart \
  "https://stage.tercen.com" \
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  "848a5d12-3456-7890-abcd-ef1234567890"
```

### What to Look For

**In the JSON output:**
```json
{
  "kind": "RunComputationTask",
  "id": "848a5d...",
  "query": {
    "relation": {
      "kind": "InMemoryRelation",
      "inMemoryTable": {
        "columns": [
          {
            "name": ".ri",
            "type": "int32",
            "values": [0]
          },
          {
            "name": ".documentId",
            "type": "string",
            "values": ["ac090f665b05f67626d73c27cf120de7"]
          },
          {
            "name": "documentId",
            "type": "string",
            "values": ["ac090f665b05f67626d73c27cf120de7"]
          }
        ]
      }
    }
  }
}
```

**Key things to find:**
- `.documentId` value (for file operations)
- Available columns (both user and internal)
- Task type and hierarchy
- Column data types
- Nested structure

## ServiceFactory Pattern for Tools

**Critical difference from web apps:**

```dart
// ❌ DON'T use in tools (web-specific)
import 'package:sci_tercen_client/sci_service_factory_web.dart';
final factory = await createServiceFactoryForWebApp();

// ✅ DO use in tools (standalone pattern)
import 'package:sci_http_client/http_auth_client.dart' as auth_http;
import 'package:sci_http_client/http_io_client.dart' as io_http;

var factory = ServiceFactory();
var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
await factory.initializeWith(Uri.parse(serviceUrl), authClient);
tercen.ServiceFactory.CURRENT = factory;
```

**See**: [Pattern: ServiceFactory Initialization](servicefactory-initialization.md)

## Additional Debugging Tools

### list_files.dart

```dart
// tools/list_files.dart
void main(List<String> args) async {
  if (args.length != 4) {
    print('Usage: dart run tools/list_files.dart <url> <token> <workflowId> <stepId>');
    exit(1);
  }

  final serviceUrl = args[0];
  final token = args[1];
  final workflowId = args[2];
  final stepId = args[3];

  // Initialize ServiceFactory
  var factory = ServiceFactory();
  var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
  await factory.initializeWith(Uri.parse(serviceUrl), authClient);
  tercen.ServiceFactory.CURRENT = factory;

  // List files
  final files = await tercen.ServiceFactory().fileService
      .findFileByWorkflowIdAndStepId(
    startKey: [workflowId, stepId],
    endKey: [workflowId, stepId, {}],
    limit: 50,
    descending: false,
  );

  print('Found ${files.length} files:');
  for (final file in files) {
    print('  ${file.name} (${file.id})');
    print('    Size: ${file.contentSize ?? 0} bytes');
    print('    Type: ${file.contentType ?? "unknown"}');
  }
}
```

### inspect_schema.dart

```dart
// tools/inspect_schema.dart
void main(List<String> args) async {
  if (args.length != 3) {
    print('Usage: dart run tools/inspect_schema.dart <url> <token> <columnHash>');
    exit(1);
  }

  final serviceUrl = args[0];
  final token = args[1];
  final columnHash = args[2];

  // Initialize ServiceFactory
  var factory = ServiceFactory();
  var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
  await factory.initializeWith(Uri.parse(serviceUrl), authClient);
  tercen.ServiceFactory.CURRENT = factory;

  // Get schema
  final schema = await tercen.ServiceFactory().tableSchemaService.get(columnHash);

  print('Schema for hash: $columnHash');
  print('Rows: ${schema.nRows}');
  print('Columns: ${schema.columns.length}');
  print('');

  for (final col in schema.columns) {
    print('Column: ${col.name}');
    print('  Type: ${col.type}');
  }
}
```

## Using toJson() for Debugging

All Tercen models implement `toJson()`:

```dart
// In your app code
final task = await taskService.get(taskId);

// Debug output
if (kDebugMode) {
  final encoder = JsonEncoder.withIndent('  ');
  print('Task structure:');
  print(encoder.convert(task.toJson()));
}
```

**Benefits:**
- See all fields and values
- Understand nested structure
- Find hidden columns (like `.documentId`)
- Verify API responses
- Document expected structure

## Conditional Debug Logging

```dart
// lib/utils/debug.dart
const bool kVerboseLogging = bool.fromEnvironment('VERBOSE', defaultValue: false);

void debugLog(String message, {Object? data}) {
  if (kVerboseLogging) {
    print(message);
    if (data != null) {
      final encoder = JsonEncoder.withIndent('  ');
      print(encoder.convert(data));
    }
  }
}

// Usage
debugLog('Fetched task', data: task.toJson());
```

**Enable:**
```bash
flutter run --dart-define=VERBOSE=true
```

## Common Debugging Scenarios

### Scenario 1: Find Available Columns
```bash
dart run tools/print_task_json.dart ... | grep '"name"'
```

### Scenario 2: Verify .documentId Exists
```bash
dart run tools/print_task_json.dart ... | grep '\.documentId'
```

### Scenario 3: Check Task Hierarchy
```bash
dart run tools/print_task_json.dart ... | grep '"kind"'
```

### Scenario 4: Inspect Column Values
```bash
dart run tools/print_task_json.dart ... | grep -A 5 '"columns"'
```

## Checklist

- [ ] Create tools/ directory in project
- [ ] Implement print_task_json.dart tool
- [ ] Use standalone ServiceFactory pattern for tools
- [ ] Accept command-line arguments (URL, token, ID)
- [ ] Pretty-print JSON with JsonEncoder.withIndent()
- [ ] Add usage instructions in comments
- [ ] Print summary information (task type, key fields)
- [ ] Handle errors gracefully with try/catch
- [ ] Document how to get dev token
- [ ] Create additional tools as needed (list_files, inspect_schema)

## Related

- **Pattern**: [ServiceFactory Initialization](servicefactory-initialization.md)
- **Pattern**: [Tercen Model Type System](tercen-model-types.md)
- **Pattern**: [Metadata-to-Data Resolution](metadata-data-resolution.md)
- **Pattern**: [Column Data Extraction](column-data-extraction.md)
