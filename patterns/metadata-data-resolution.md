# Pattern: Metadata-to-Data ID Resolution

## The Fundamental Problem

Tercen separates **data** from **metadata**. User-visible IDs (taskId, documentId, projectId) are metadata. File operations need data IDs (.documentId, .projectId, etc.).

**This is fundamental Tercen architecture, not a bug or workaround.**

## Data vs Metadata Architecture

| Layer | Example IDs | Purpose | Cloning Behavior |
|-------|------------|---------|------------------|
| **Metadata** | `taskId`, `projectId`, `workflowId`, `documentId` | User-facing, workflow context | DUPLICATED on clone |
| **Data** | `.taskId`, `.projectId`, `.workflowId`, `.documentId` | Actual data references | SHARED (not duplicated) |

**Why this exists:**
- When a project is cloned, Tercen creates NEW metadata pointing to ORIGINAL data
- Data is never duplicated - only metadata is replicated
- This enables efficient project cloning without copying large datasets
- Metadata provides project-specific context while data layer ensures single source of truth

## The Resolution Problem

### Symptom
```dart
// Using metadata ID for file operations
final bytes = await fileService.download(documentId); // 404 error!
```

### Root Cause
- URL parameters provide metadata IDs (`taskId`)
- File operations require data IDs (`.documentId`)
- These are NOT the same, especially in cloned projects

### Why Schema API Doesn't Help
```dart
// ❌ This doesn't work - schema filters dot-prefixed columns
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId');
// Result: Empty! Dot-prefixed columns are filtered out by design
```

The schema API intentionally filters out dot-prefixed columns because they're internal data references, not user-facing columns.

## General Resolution Pattern

### Step 1: Get Task Object
```dart
final task = await taskService.get(taskId); // taskId from URL parameter
```

### Step 2: Navigate to CubeQueryTask
```dart
CubeQueryTask? cubeTask;

if (task is RunWebAppTask) {
  // Web app tasks wrap CubeQueryTasks
  if (task.cubeQueryTaskId.isEmpty) {
    throw Exception('RunWebAppTask has empty cubeQueryTaskId');
  }

  final cubeTaskObj = await taskService.get(task.cubeQueryTaskId);
  if (cubeTaskObj is! CubeQueryTask) {
    throw Exception('Referenced task is not a CubeQueryTask');
  }

  cubeTask = cubeTaskObj as CubeQueryTask;
} else if (task is CubeQueryTask) {
  // Direct cube query task
  cubeTask = task as CubeQueryTask;
} else {
  throw Exception('Task is neither RunWebAppTask nor CubeQueryTask');
}
```

### Step 3: Extract Data ID from JSON (Bypass Schema Filtering)
```dart
final taskJson = cubeTask.toJson();
final queryJson = taskJson['query'] as Map?;

if (queryJson == null || queryJson['relation'] == null) {
  throw Exception('Task has no query relation');
}

String? dotDocumentId;
var currentRelation = queryJson['relation'] as Map?;

// Navigate through relation structure to find InMemoryTable
while (currentRelation != null) {
  if (currentRelation['kind'] == 'InMemoryRelation' &&
      currentRelation['inMemoryTable'] != null) {

    final inMemoryTable = currentRelation['inMemoryTable'] as Map;
    final columns = inMemoryTable['columns'] as List?;

    if (columns != null) {
      for (final col in columns) {
        final colMap = col as Map;
        final name = colMap['name'] as String?;
        final values = colMap['values'] as List?;

        if (name == '.documentId' && values != null && values.isNotEmpty) {
          dotDocumentId = values.first?.toString();
          break;
        }
      }
    }
    break;
  }

  // Navigate deeper into relation tree
  currentRelation = currentRelation['relation'] as Map?;
}

if (dotDocumentId == null || dotDocumentId.isEmpty) {
  throw Exception('Could not extract .documentId from task JSON');
}

print('✓ Extracted .documentId: $dotDocumentId');
```

### Step 4: Use Data ID for File Operations
```dart
// Now use the data ID for file operations
final fileDocument = await documentService.get(dotDocumentId);
final fileBytes = await fileService.download(dotDocumentId);
```

## Complete Implementation: DocumentIdResolver

Create: `lib/utils/document_id_resolver.dart`

### Hierarchical Fallback Strategy

```dart
class DocumentIdResolver {
  Future<ResolvedIds?> resolveDocumentId() async {
    // Strategy 1: Extract from task JSON (PRIMARY - PRODUCTION)
    final idsFromColumns = await _tryGetFromColumnData();
    if (idsFromColumns != null && idsFromColumns.hasAnyId) {
      return idsFromColumns;
    }

    // Strategy 2: Search files by workflow/step (AUTO-DISCOVERY FALLBACK)
    final docIdFromFiles = await _tryFindFilesByWorkflowStep();
    if (docIdFromFiles != null) {
      return ResolvedIds(documentId: docIdFromFiles);
    }

    // Strategy 3: Use development hardcoded ID (DEVELOPMENT)
    if (_devZipFileId != null && _devZipFileId!.isNotEmpty) {
      return ResolvedIds(documentId: _devZipFileId);
    }

    // Strategy 4: Return null for mock fallback
    return null;
  }
}
```

### Strategy 1: Extract from Task JSON
```dart
Future<ResolvedIds?> _tryGetFromColumnData() async {
  try {
    final task = await _serviceFactory.taskService.get(_taskId!);

    // Navigate to CubeQueryTask
    CubeQueryTask? cubeTask;
    if (task is RunWebAppTask) {
      final cubeTaskObj = await _serviceFactory.taskService.get(task.cubeQueryTaskId);
      cubeTask = cubeTaskObj as CubeQueryTask;
    } else if (task is CubeQueryTask) {
      cubeTask = task as CubeQueryTask;
    }

    if (cubeTask == null) return null;

    // Extract .documentId from JSON (bypasses schema filtering)
    final taskJson = cubeTask.toJson();
    final queryJson = taskJson['query'] as Map?;

    if (queryJson != null && queryJson['relation'] != null) {
      String? dotDocumentId;
      var currentRelation = queryJson['relation'] as Map?;

      while (currentRelation != null) {
        if (currentRelation['kind'] == 'InMemoryRelation' &&
            currentRelation['inMemoryTable'] != null) {
          final inMemoryTable = currentRelation['inMemoryTable'] as Map;
          final columns = inMemoryTable['columns'] as List?;

          if (columns != null) {
            for (final col in columns) {
              final colMap = col as Map;
              final name = colMap['name'] as String?;
              final values = colMap['values'] as List?;

              if (name == '.documentId' && values != null && values.isNotEmpty) {
                dotDocumentId = values.first?.toString();
              }
            }
          }
          break;
        }
        currentRelation = currentRelation['relation'] as Map?;
      }

      if (dotDocumentId != null && dotDocumentId.isNotEmpty) {
        return ResolvedIds(documentId: dotDocumentId);
      }
    }

    return null;
  } catch (e) {
    print('Error extracting documentId: $e');
    return null;
  }
}
```

### Strategy 2: Search Files by Workflow/Step
```dart
Future<String?> _tryFindFilesByWorkflowStep() async {
  try {
    if (_workflowId == null || _stepId == null) {
      return null;
    }

    final files = await _serviceFactory.fileService
        .findFileByWorkflowIdAndStepId(
      startKey: [_workflowId, _stepId],
      endKey: [_workflowId, _stepId, {}],
      limit: 10,
      descending: false,
    );

    if (files.isEmpty) return null;

    // Prefer zip files
    final zipFiles = files.where((f) => f.name.toLowerCase().endsWith('.zip')).toList();
    if (zipFiles.isNotEmpty) {
      return zipFiles.first.id;
    }

    // Fallback to first file
    return files.first.id;
  } catch (e) {
    print('Error searching files: $e');
    return null;
  }
}
```

## Future Extensions

This pattern applies to other Tercen resources:

- **Projects**: `projectId` (metadata) → `.projectId` (data)
- **Workflows**: `workflowId` (metadata) → `.workflowId` (data)
- **Tasks**: `taskId` (metadata) → `.taskId` (data)

**General Principle**: If accessing actual data/files, look for dot-prefixed IDs in task JSON.

## Debugging Tools

Create standalone tools to inspect task JSON structure:

### tools/print_task_json.dart
```dart
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

  // Initialize ServiceFactory (standalone pattern)
  var factory = ServiceFactory();
  var authClient = auth_http.HttpAuthClient(token, io_http.HttpIOClient());
  await factory.initializeWith(Uri.parse(serviceUrl), authClient);
  tercen.ServiceFactory.CURRENT = factory;

  // Fetch and print task JSON
  final task = await tercen.ServiceFactory().taskService.get(taskId);
  final encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(task.toJson()));
}
```

**Usage:**
```bash
dart run tools/print_task_json.dart "https://stage.tercen.com" "eyJ..." "848a5d..."
```

**See**: [Pattern: Debug Tools](debug-tools.md)

## Common Errors

### Error 1: 404 Not Found
**Symptom**: File download returns 404
**Cause**: Using `documentId` (metadata alias) instead of `.documentId` (fundamental data ID)
**Fix**: Extract `.documentId` from task JSON

### Error 2: Empty Column Result
**Symptom**: Schema query returns no `.documentId` column
**Cause**: Schema API filters dot-prefixed columns by design
**Fix**: Extract from task JSON directly, not schema

### Error 3: Works in Original, Fails in Clone
**Symptom**: Operator works in original project but fails with 404 in cloned project
**Cause**: Using metadata ID (`documentId`) which changed during clone
**Fix**: Resolve metadata ID → data ID (`.documentId`) first

### Error 4: File Exists But Can't Access
**Symptom**: File metadata retrieved but download fails
**Cause**: Using metadata reference that points to wrong data after cloning
**Fix**: Always use `.documentId` (data ID) for file operations

## Testing Considerations

**CRITICAL**: Always test with cloned projects

### Test Procedure
1. Create test project in Tercen with sample data
2. Test operator in original project ✓
3. Clone the project in Tercen
4. Test operator in cloned project ✓
5. Verify both work identically

### What Changes on Clone
- ✅ Metadata IDs change (`documentId`, `taskId`, `projectId`)
- ✅ Data IDs remain the same (`.documentId` points to original data)
- ✅ Your operator should work in both if using data IDs correctly

## Reference Implementation

**Full implementation**: [document_id_resolver.dart](../../lib/utils/document_id_resolver.dart)

**Container class**:
```dart
class ResolvedIds {
  final String? documentId;
  final String? id;

  ResolvedIds({this.documentId, this.id});

  bool get hasAnyId => documentId != null || id != null;
}
```

## Checklist

- [ ] Understand data vs metadata architecture
- [ ] Extract .documentId from task JSON (not schema)
- [ ] Implement DocumentIdResolver utility with hierarchical fallback
- [ ] Handle task hierarchy navigation (RunWebAppTask → CubeQueryTask)
- [ ] Add fallback strategies (task JSON → file search → dev ID → mock)
- [ ] Handle resolution failures gracefully
- [ ] Create debug tools to inspect task structure
- [ ] Test with both original and cloned projects
- [ ] Document why metadata IDs may return 404

## Related

- **Issue**: [#10 Metadata-to-Data ID Resolution](../issues/10-metadata-data-resolution.md)
- **Issue**: [#11 Schema Service Filtering](../issues/11-schema-filtering.md)
- **Pattern**: [Task Hierarchy Navigation](task-hierarchy-navigation.md)
- **Pattern**: [Column Data Extraction](column-data-extraction.md)
- **Pattern**: [Debug Tools](debug-tools.md)
