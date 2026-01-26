# Pattern: Tercen Model Type System

## Overview

The `sci_tercen_model` package contains **214+ generated Dart model classes** representing all Tercen data structures. Understanding this type system is essential for working with the Tercen API.

**Key characteristics:**
- Strong typing throughout (no dynamic maps)
- Extensive inheritance hierarchy
- Generated from Tercen's schema definitions
- All models implement `toJson()` and `fromJson()`
- Uses `kind` field for polymorphic serialization

## Model Categories

### 1. Task Models
```dart
Task (base)
├── RunWebAppTask
├── CubeQueryTask
│   └── RunComputationTask
├── CreateGitOperatorTask
├── SaveTask
└── 30+ other task types
```

### 2. Document Models
```dart
Document (base)
├── FileDocument
├── TableDocument
├── Operator
├── Project
├── Workflow
└── 50+ other document types
```

### 3. Relation Models
```dart
Relation (base)
├── InMemoryRelation
├── JoinOperator
├── GatherRelation
├── TableRelation
└── 20+ other relation types
```

### 4. Schema Models
```dart
TableSchema
├── columns: List<Column>
├── nRows: int
└── properties: Map

Column
├── name: String
├── type: String (int32, double, string, etc.)
├── values: List<dynamic>?
└── 10+ other fields
```

## Type Checking Pattern

Always check types before casting:

```dart
import 'package:sci_tercen_client/sci_client.dart';

// ✅ Safe type checking
if (task is RunWebAppTask) {
  final webAppTask = task as RunWebAppTask;
  print('Cube query task: ${webAppTask.cubeQueryTaskId}');
} else if (task is CubeQueryTask) {
  final cubeTask = task as CubeQueryTask;
  print('Query hash: ${cubeTask.query?.columnHash}');
}

// ❌ Unsafe - might throw
final cubeTask = task as CubeQueryTask; // Can crash!
```

## The `kind` Field

All models have a `kind` field for serialization:

```dart
final task = await taskService.get(taskId);
print('Task kind: ${task.kind}'); // e.g., "RunWebAppTask"
print('Task type: ${task.runtimeType}'); // e.g., RunWebAppTask
```

**Use cases:**
- Debugging (know what you're working with)
- Logging
- Error messages
- Understanding JSON structure

## Common Model Types

### RunWebAppTask
```dart
class RunWebAppTask extends Task {
  String cubeQueryTaskId;  // Reference to CubeQueryTask
  String operatorId;       // Operator being run
  String state;            // PENDING, RUNNING, DONE, etc.
  // ... many other fields
}
```

### CubeQueryTask
```dart
class CubeQueryTask extends Task {
  Query? query;           // Contains columnHash, rowHash
  String? state;
  // ... many other fields
}
```

### FileDocument
```dart
class FileDocument extends Document {
  String name;            // Filename
  int? contentSize;       // File size in bytes
  String? contentType;    // MIME type
  String workflowId;      // Parent workflow
  String stepId;          // Parent step
  // ... many other fields
}
```

### TableSchema
```dart
class TableSchema {
  List<Column> columns;   // Column definitions
  int nRows;              // Number of rows
  Map properties;         // Additional metadata
}
```

### Column
```dart
class Column {
  String name;            // Column name
  String type;            // int32, double, string, etc.
  List<dynamic>? values;  // Column data (if fetched)
}
```

## Using toJson() for Debugging

All models implement `toJson()`:

```dart
import 'dart:convert';

final task = await taskService.get(taskId);

// Convert to JSON
final json = task.toJson();

// Pretty print
final encoder = JsonEncoder.withIndent('  ');
print(encoder.convert(json));
```

**Shows:**
- All fields and values
- Nested structures
- Hidden internal columns
- Useful for understanding structure

**See**: [Pattern: Debug Tools](debug-tools.md)

## Type Hierarchy Navigation

Models have parent-child relationships:

```dart
// RunComputationTask IS A CubeQueryTask
if (task is RunComputationTask) {
  // Can cast to parent type
  final cubeTask = task as CubeQueryTask;

  // Access CubeQueryTask fields
  print('Column hash: ${cubeTask.query?.columnHash}');

  // Access RunComputationTask fields
  final compTask = task as RunComputationTask;
  print('Operator: ${compTask.operatorId}');
}
```

**See**: [Pattern: Task Hierarchy Navigation](task-hierarchy-navigation.md)

## Null Safety

Models use Dart null safety:

```dart
class CubeQueryTask extends Task {
  Query? query;  // May be null
}

// Safe access
if (cubeTask.query != null) {
  final hash = cubeTask.query!.columnHash;
}

// Or use ?.
final hash = cubeTask.query?.columnHash;
final hashOrDefault = cubeTask.query?.columnHash ?? 'default';
```

## Common Patterns

### Pattern 1: Type Checking Chain
```dart
Future<CubeQueryTask?> getCubeQueryTask(String taskId) async {
  final task = await taskService.get(taskId);

  if (task is RunWebAppTask) {
    final cubeTaskId = task.cubeQueryTaskId;
    if (cubeTaskId.isEmpty) return null;

    final cubeTaskObj = await taskService.get(cubeTaskId);
    return cubeTaskObj is CubeQueryTask ? cubeTaskObj as CubeQueryTask : null;
  } else if (task is CubeQueryTask) {
    return task as CubeQueryTask;
  }

  return null;
}
```

### Pattern 2: Model Validation
```dart
bool isValidCubeQueryTask(Task task) {
  if (task is! CubeQueryTask) return false;

  final cubeTask = task as CubeQueryTask;
  if (cubeTask.query == null) return false;
  if (cubeTask.query!.columnHash == null) return false;

  return true;
}
```

### Pattern 3: Safe Field Access
```dart
String? getColumnHash(Task task) {
  if (task is! CubeQueryTask) return null;

  final cubeTask = task as CubeQueryTask;
  return cubeTask.query?.columnHash;
}
```

## Testing with Models

### Create Test Models
```dart
// Create test task
final testTask = RunWebAppTask()
  ..id = 'test-task-id'
  ..cubeQueryTaskId = 'cube-task-id'
  ..operatorId = 'op-123'
  ..state = 'DONE';

// Create test file
final testFile = FileDocument()
  ..id = 'file-123'
  ..name = 'test.zip'
  ..contentSize = 1024
  ..workflowId = 'wf-1'
  ..stepId = 'step-1';
```

### Mock Service with Models
```dart
class MockTaskService implements TaskService {
  Map<String, Task> tasks = {};

  @override
  Future<Task> get(String id) async {
    return tasks[id] ?? throw NotFoundException('Task not found');
  }
}

// Setup
final mockService = MockTaskService();
mockService.tasks['task-1'] = CubeQueryTask()
  ..id = 'task-1'
  ..query = Query()..columnHash = 'hash-123';
```

## Error Handling

### Wrong Type Errors
```dart
try {
  final cubeTask = task as CubeQueryTask;
} on TypeError catch (e) {
  print('Type cast failed: ${task.runtimeType} is not CubeQueryTask');
  // Handle gracefully
}
```

### Missing Fields
```dart
if (task is CubeQueryTask) {
  final cubeTask = task as CubeQueryTask;

  if (cubeTask.query == null) {
    print('CubeQueryTask missing query field');
    // Handle gracefully
  }
}
```

## Checklist

- [ ] Understand 214+ model classes exist
- [ ] Know main model categories (Task, Document, Relation, Schema)
- [ ] Always check types before casting
- [ ] Use `kind` field for debugging
- [ ] Use `toJson()` to inspect structure
- [ ] Handle null fields properly
- [ ] Understand type hierarchy (parent/child)
- [ ] Create mock models for testing
- [ ] Add proper error handling for type mismatches

## Related

- **Pattern**: [Task Hierarchy Navigation](task-hierarchy-navigation.md)
- **Pattern**: [Column Data Extraction](column-data-extraction.md)
- **Pattern**: [Debug Tools](debug-tools.md)
- **Skill**: [2 Tercen Real Implementation](../skills/2-tercen-real.md)
