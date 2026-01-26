# Pattern: Task Hierarchy Navigation

## The Problem

Tercen tasks form an inheritance hierarchy. The `taskId` from URL parameters may point to different task types, and you often need to navigate this hierarchy to find the actual data.

**Task types commonly encountered:**
- `RunWebAppTask` - Wraps a CubeQueryTask for web app execution
- `CubeQueryTask` - Contains query and column data
- `RunComputationTask` - Extends CubeQueryTask with computation specifics

## Task Type Hierarchy

```
Task (base)
├── RunWebAppTask
│   └─> cubeQueryTaskId → CubeQueryTask
└── CubeQueryTask (base for queries)
    ├── RunComputationTask
    └── Other query types...
```

**Key insight**: A `RunWebAppTask` doesn't contain query data directly - it references another task via `cubeQueryTaskId`.

## The sci_tercen_client Model System

The library has **214+ generated Dart model classes** with strong typing throughout.

**Key characteristics:**
- All models extend base `Task` class
- Type hierarchy matches Tercen's architecture
- Models use `kind` field for JSON serialization
- All models implement `toJson()` for debugging
- Must use type checking before casting

## Basic Navigation Pattern

### Step 1: Fetch Initial Task
```dart
import 'package:sci_tercen_client/sci_client.dart';

final taskId = // from URL parameter
final task = await ServiceFactory().taskService.get(taskId);

print('Task ID: ${task.id}');
print('Task kind: ${task.kind}');
print('Task type: ${task.runtimeType}');
```

### Step 2: Navigate to CubeQueryTask
```dart
CubeQueryTask? cubeTask;

if (task is RunWebAppTask) {
  // Web app tasks wrap cube query tasks
  print('Found RunWebAppTask, navigating to cubeQueryTask...');

  // Validate reference exists
  if (task.cubeQueryTaskId.isEmpty) {
    throw Exception('RunWebAppTask has empty cubeQueryTaskId');
  }

  // Fetch the referenced task
  final cubeTaskObj = await ServiceFactory().taskService.get(task.cubeQueryTaskId);

  // Validate type
  if (cubeTaskObj is! CubeQueryTask) {
    throw Exception('Referenced task is not a CubeQueryTask: ${cubeTaskObj.runtimeType}');
  }

  cubeTask = cubeTaskObj as CubeQueryTask;
  print('✓ Navigated to CubeQueryTask: ${cubeTask.id}');

} else if (task is CubeQueryTask) {
  // Direct cube query task
  cubeTask = task as CubeQueryTask;
  print('✓ Task is already a CubeQueryTask');

} else {
  throw Exception('Task is neither RunWebAppTask nor CubeQueryTask: ${task.runtimeType}');
}
```

### Step 3: Access Query Data
```dart
if (cubeTask.query == null) {
  throw Exception('CubeQueryTask has no query');
}

final query = cubeTask.query!;
print('Column hash: ${query.columnHash}');
print('Row hash: ${query.rowHash}');

// Access column data
if (query.columnHash != null && query.columnHash!.isNotEmpty) {
  // Can now use tableSchemaService or extract from JSON
}
```

## Complete Navigation Function

```dart
/// Navigates task hierarchy to find CubeQueryTask containing query data
Future<CubeQueryTask> navigateToCubeQueryTask(String taskId) async {
  final serviceFactory = ServiceFactory();

  // Get initial task
  final task = await serviceFactory.taskService.get(taskId);

  // Handle different task types
  if (task is RunWebAppTask) {
    // Web app wrapper - navigate to underlying task
    if (task.cubeQueryTaskId.isEmpty) {
      throw StateError('RunWebAppTask has empty cubeQueryTaskId');
    }

    final cubeTaskObj = await serviceFactory.taskService.get(task.cubeQueryTaskId);

    if (cubeTaskObj is! CubeQueryTask) {
      throw TypeError('Expected CubeQueryTask, got ${cubeTaskObj.runtimeType}');
    }

    return cubeTaskObj as CubeQueryTask;

  } else if (task is CubeQueryTask) {
    // Already a cube query task
    return task as CubeQueryTask;

  } else {
    throw UnsupportedError('Unsupported task type: ${task.runtimeType}');
  }
}
```

## Advanced: Handling RunComputationTask

`RunComputationTask` extends `CubeQueryTask`, so it IS a `CubeQueryTask`:

```dart
if (task is RunComputationTask) {
  // RunComputationTask extends CubeQueryTask
  cubeTask = task as CubeQueryTask;

  // Access computation-specific fields if needed
  final computationTask = task as RunComputationTask;
  print('Computation operator: ${computationTask.operatorId}');
  print('State: ${computationTask.state}');
}
```

## Type Checking Best Practices

### DO: Check Before Casting
```dart
// ✅ Safe - check type first
if (task is CubeQueryTask) {
  final cubeTask = task as CubeQueryTask;
  // Use cubeTask
}
```

### DON'T: Blind Casting
```dart
// ❌ Unsafe - may throw if wrong type
final cubeTask = task as CubeQueryTask; // Might crash!
```

### DO: Handle All Cases
```dart
// ✅ Complete - handles all possibilities
if (task is RunWebAppTask) {
  // Handle web app wrapper
} else if (task is CubeQueryTask) {
  // Handle direct query task
} else {
  // Handle unexpected types
  throw Exception('Unexpected task type: ${task.runtimeType}');
}
```

### DO: Use Null-Safe Navigation
```dart
// ✅ Safe - checks for null
if (cubeTask.query != null) {
  final columnHash = cubeTask.query!.columnHash;
}

// Or use ?.
final columnHash = cubeTask.query?.columnHash;
```

## Debugging Task Structure

Use `toJson()` to inspect task structure:

```dart
import 'dart:convert';

final task = await taskService.get(taskId);

// Pretty print JSON structure
final encoder = JsonEncoder.withIndent('  ');
final prettyJson = encoder.convert(task.toJson());
print(prettyJson);
```

**Output shows:**
- All fields and their values
- Nested structure
- Available properties
- Hidden dot-prefixed columns (in inMemoryTable)

**See**: [Pattern: Debug Tools](debug-tools.md)

## Common Patterns

### Pattern 1: Navigate and Extract Column Data
```dart
final cubeTask = await navigateToCubeQueryTask(taskId);

if (cubeTask.query == null) {
  throw Exception('No query data available');
}

// Extract .documentId from JSON (bypasses schema filtering)
final taskJson = cubeTask.toJson();
final columns = taskJson['query']['relation']['inMemoryTable']['columns'];
// ... process columns
```

**See**: [Pattern: Metadata-to-Data Resolution](metadata-data-resolution.md)

### Pattern 2: Check Computation State
```dart
if (task is RunComputationTask) {
  final computationTask = task as RunComputationTask;

  if (computationTask.state != 'DONE') {
    throw Exception('Computation not complete: ${computationTask.state}');
  }

  // Access query data
  final cubeTask = computationTask as CubeQueryTask;
  // ... use cubeTask
}
```

### Pattern 3: Validate Task Readiness
```dart
Future<bool> isTaskReady(String taskId) async {
  final task = await taskService.get(taskId);

  if (task is RunWebAppTask) {
    return task.cubeQueryTaskId.isNotEmpty;
  } else if (task is CubeQueryTask) {
    return task.query != null && task.query!.columnHash != null;
  }

  return false;
}
```

## Error Handling

### Error 1: Empty Reference
```dart
if (task.cubeQueryTaskId.isEmpty) {
  print('⚠️ Empty cubeQueryTaskId - task may not be initialized yet');
  // Wait and retry, or use fallback strategy
}
```

### Error 2: Wrong Type
```dart
try {
  final cubeTask = task as CubeQueryTask;
} catch (e) {
  print('❌ Type cast failed: expected CubeQueryTask, got ${task.runtimeType}');
  print('   Task kind: ${task.kind}');
  // Handle gracefully or throw
}
```

### Error 3: Missing Query
```dart
if (cubeTask.query == null) {
  print('❌ CubeQueryTask has no query data');
  // This shouldn't happen in normal operation
  // May indicate incomplete task or API issue
}
```

## Integration with DocumentIdResolver

Typical usage in a resolver utility:

```dart
class DocumentIdResolver {
  Future<String?> resolveDocumentId() async {
    try {
      // Step 1: Get task
      final task = await _serviceFactory.taskService.get(_taskId);

      // Step 2: Navigate hierarchy
      CubeQueryTask? cubeTask;
      if (task is RunWebAppTask) {
        if (task.cubeQueryTaskId.isEmpty) {
          return null;
        }
        final cubeTaskObj = await _serviceFactory.taskService.get(task.cubeQueryTaskId);
        cubeTask = cubeTaskObj as CubeQueryTask;
      } else if (task is CubeQueryTask) {
        cubeTask = task as CubeQueryTask;
      } else {
        return null;
      }

      // Step 3: Extract data ID from JSON
      final taskJson = cubeTask.toJson();
      // ... extract .documentId

    } catch (e) {
      print('Error navigating task hierarchy: $e');
      return null;
    }
  }
}
```

## Testing Considerations

### Test Different Task Types
```dart
// Test with RunWebAppTask
final webAppTaskId = '...';
final result1 = await navigateToCubeQueryTask(webAppTaskId);
expect(result1, isA<CubeQueryTask>());

// Test with direct CubeQueryTask
final cubeQueryTaskId = '...';
final result2 = await navigateToCubeQueryTask(cubeQueryTaskId);
expect(result2, isA<CubeQueryTask>());

// Test with RunComputationTask
final computationTaskId = '...';
final result3 = await navigateToCubeQueryTask(computationTaskId);
expect(result3, isA<CubeQueryTask>());
```

### Mock Task Navigation
```dart
class MockTaskService {
  Map<String, Task> tasks = {};

  Future<Task> get(String id) async {
    return tasks[id] ?? throw Exception('Task not found');
  }
}

// Setup mock hierarchy
final mockService = MockTaskService();
mockService.tasks['web-app-id'] = RunWebAppTask(
  id: 'web-app-id',
  cubeQueryTaskId: 'cube-id',
);
mockService.tasks['cube-id'] = CubeQueryTask(
  id: 'cube-id',
  query: Query(columnHash: 'hash-123'),
);
```

## Checklist

- [ ] Understand task type hierarchy
- [ ] Always check task type before casting
- [ ] Handle RunWebAppTask → CubeQueryTask navigation
- [ ] Validate cubeQueryTaskId is not empty
- [ ] Handle cases where task is already CubeQueryTask
- [ ] Check for null query before accessing
- [ ] Use toJson() for debugging task structure
- [ ] Add proper error handling for type mismatches
- [ ] Test with different task types
- [ ] Document expected task types in code comments

## Related

- **Pattern**: [Metadata-to-Data Resolution](metadata-data-resolution.md)
- **Pattern**: [Column Data Extraction](column-data-extraction.md)
- **Pattern**: [Tercen Model Type System](tercen-model-types.md)
- **Pattern**: [Debug Tools](debug-tools.md)
- **Issue**: [#10 Metadata-to-Data Resolution](../issues/10-metadata-data-resolution.md)
- **Issue**: [#11 Schema Service Filtering](../issues/11-schema-filtering.md)
