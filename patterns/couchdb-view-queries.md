# Pattern: CouchDB View Queries

## Overview

Tercen's file service uses **CouchDB-style view queries** for finding files. Understanding the startKey/endKey pattern is essential for file discovery operations.

**Key concept**: Views use compound keys (arrays) to create hierarchical indexes, and you query ranges using `startKey` and `endKey`.

## Basic View Query Pattern

### The FileService API

```dart
Future<List<FileDocument>> findFileByWorkflowIdAndStepId({
  required List startKey,
  required List endKey,
  int limit = 20,
  bool descending = false,
  int skip = 0,
})
```

**Parameters:**
- `startKey` - Beginning of range (inclusive)
- `endKey` - End of range (inclusive)
- `limit` - Maximum results to return
- `descending` - Sort order (IMPORTANT: affects results!)
- `skip` - Number of results to skip (pagination)

## Understanding Compound Keys

Files are indexed by `[workflowId, stepId, ...]` structure:

```
Index Structure:
[workflowId-1, stepId-A, fileId-1]
[workflowId-1, stepId-A, fileId-2]
[workflowId-1, stepId-B, fileId-3]
[workflowId-2, stepId-C, fileId-4]
```

### Query Examples

**Example 1: All files for specific workflow + step**
```dart
final files = await fileService.findFileByWorkflowIdAndStepId(
  startKey: [workflowId, stepId],
  endKey: [workflowId, stepId, {}],  // {} means "everything after"
  limit: 100,
  descending: false,
);
```

**Example 2: All files for specific workflow (all steps)**
```dart
final files = await fileService.findFileByWorkflowIdAndStepId(
  startKey: [workflowId],
  endKey: [workflowId, {}],
  limit: 100,
  descending: false,
);
```

**Example 3: Single file lookup**
```dart
final files = await fileService.findFileByWorkflowIdAndStepId(
  startKey: [workflowId, stepId, fileId],
  endKey: [workflowId, stepId, fileId],
  limit: 1,
  descending: false,
);
```

## The Wildcard: `{}`

The empty map `{}` acts as a **wildcard** meaning "match everything after this key prefix".

```dart
// Match all files in workflow w1, step s1
startKey: ['w1', 's1']
endKey: ['w1', 's1', {}]

// Matches:
['w1', 's1', 'file1']
['w1', 's1', 'file2']
['w1', 's1', 'file3']

// Does NOT match:
['w1', 's2', 'file4']  // Different step
['w2', 's1', 'file5']  // Different workflow
```

**Why it works**: In CouchDB collation, `{}` sorts after all other values at that position.

## The descending Parameter

**CRITICAL**: The `descending` parameter affects which results you get, not just sort order!

### descending: false (Ascending - RECOMMENDED)

```dart
final files = await fileService.findFileByWorkflowIdAndStepId(
  startKey: [workflowId, stepId],
  endKey: [workflowId, stepId, {}],
  descending: false,  // ← Recommended
);
```

**Behavior:**
- Starts at `startKey` and moves forward
- Stops at `endKey`
- Returns results in ascending order
- ✅ Intuitive behavior

### descending: true (Descending - USE WITH CAUTION)

```dart
final files = await fileService.findFileByWorkflowIdAndStepId(
  startKey: [workflowId, stepId, {}],  // ← Note: keys are SWAPPED!
  endKey: [workflowId, stepId],
  descending: true,
);
```

**Behavior:**
- Starts at what you specify as `startKey` (which should be the high end)
- Moves backward
- Stops at what you specify as `endKey` (which should be the low end)
- Keys effectively swap meaning
- ⚠️ Confusing and error-prone

**Common bug**: Forgetting to swap keys when using `descending: true`

**Common pitfall:**
- Using `descending: true` often fails due to key ordering confusion
- Using `descending: false` is more reliable
- **Recommendation**: Always use `descending: false` unless you have a specific reason

## Complete Implementation Patterns

### Pattern 1: Find ZIP Files for Workflow Step

```dart
Future<List<FileDocument>> findZipFilesForStep(
  String workflowId,
  String stepId,
) async {
  try {
    final files = await fileService.findFileByWorkflowIdAndStepId(
      startKey: [workflowId, stepId],
      endKey: [workflowId, stepId, {}],
      limit: 50,
      descending: false,
    );

    // Filter for ZIP files
    return files.where((f) => f.name.toLowerCase().endsWith('.zip')).toList();
  } catch (e) {
    print('Error finding files: $e');
    return [];
  }
}
```

### Pattern 2: Find First File (Any Type)

```dart
Future<FileDocument?> findFirstFile(
  String workflowId,
  String stepId,
) async {
  final files = await fileService.findFileByWorkflowIdAndStepId(
    startKey: [workflowId, stepId],
    endKey: [workflowId, stepId, {}],
    limit: 1,
    descending: false,
  );

  return files.isEmpty ? null : files.first;
}
```

### Pattern 3: Find Files with Pagination

```dart
Future<List<FileDocument>> findAllFilesPaginated(
  String workflowId,
  String stepId, {
  int batchSize = 50,
}) async {
  final allFiles = <FileDocument>[];
  int skip = 0;

  while (true) {
    final batch = await fileService.findFileByWorkflowIdAndStepId(
      startKey: [workflowId, stepId],
      endKey: [workflowId, stepId, {}],
      limit: batchSize,
      descending: false,
      skip: skip,
    );

    if (batch.isEmpty) break;

    allFiles.addAll(batch);
    skip += batch.length;

    // Safety: prevent infinite loop
    if (allFiles.length > 1000) {
      print('⚠️ More than 1000 files found, stopping pagination');
      break;
    }
  }

  return allFiles;
}
```

### Pattern 4: Find Specific File Type

```dart
Future<FileDocument?> findFileByType(
  String workflowId,
  String stepId,
  String extension, // e.g., '.zip', '.tif', '.png'
) async {
  final files = await fileService.findFileByWorkflowIdAndStepId(
    startKey: [workflowId, stepId],
    endKey: [workflowId, stepId, {}],
    limit: 100,
    descending: false,
  );

  return files
      .where((f) => f.name.toLowerCase().endsWith(extension.toLowerCase()))
      .firstOrNull;
}
```

## Error Handling

### No Files Found

```dart
final files = await fileService.findFileByWorkflowIdAndStepId(
  startKey: [workflowId, stepId],
  endKey: [workflowId, stepId, {}],
  limit: 10,
  descending: false,
);

if (files.isEmpty) {
  print('⚠️ No files found for workflow/step');
  print('   Workflow: $workflowId');
  print('   Step: $stepId');
  // Use fallback strategy
}
```

### Invalid Keys

```dart
try {
  final files = await fileService.findFileByWorkflowIdAndStepId(
    startKey: [workflowId, stepId],
    endKey: [workflowId, stepId, {}],
    descending: false,
  );
} catch (e) {
  if (e.toString().contains('404') || e.toString().contains('not found')) {
    print('❌ Workflow or step not found');
  } else if (e.toString().contains('400') || e.toString().contains('bad request')) {
    print('❌ Invalid query parameters');
  } else {
    print('❌ Error querying files: $e');
  }
}
```

## FileDocument Structure

Results are `FileDocument` objects:

```dart
class FileDocument {
  String id;           // Document ID (use for download)
  String name;         // Filename
  int? contentSize;    // File size in bytes
  String? contentType; // MIME type
  String workflowId;   // Parent workflow
  String stepId;       // Parent step
  // ... other fields
}
```

### Using Results

```dart
final files = await fileService.findFileByWorkflowIdAndStepId(...);

for (final file in files) {
  print('File: ${file.name}');
  print('  ID: ${file.id}');
  print('  Size: ${file.contentSize ?? 0} bytes');
  print('  Type: ${file.contentType ?? "unknown"}');

  // Download file
  final stream = fileService.download(file.id);
  // ... process stream
}
```

## Performance Considerations

### Limit Small, Paginate if Needed

```dart
// ✅ Good - small limit with pagination if needed
final batch1 = await findFiles(limit: 20);
if (needMore) {
  final batch2 = await findFiles(limit: 20, skip: 20);
}

// ❌ Bad - large limit may be slow
final allFiles = await findFiles(limit: 10000);
```

### Filter After Query

```dart
// ✅ Good - query small, filter in memory
final files = await findFiles(limit: 100);
final zipFiles = files.where((f) => f.name.endsWith('.zip')).toList();

// ❌ Bad - no way to filter in query, must fetch all
// CouchDB views don't support filename filtering
```

### Cache Results

```dart
class FileCache {
  final Map<String, List<FileDocument>> _cache = {};

  Future<List<FileDocument>> getFiles(String workflowId, String stepId) async {
    final key = '$workflowId:$stepId';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final files = await fileService.findFileByWorkflowIdAndStepId(
      startKey: [workflowId, stepId],
      endKey: [workflowId, stepId, {}],
      descending: false,
    );

    _cache[key] = files;
    return files;
  }
}
```

## Testing

### Mock File Service

```dart
class MockFileService implements FileService {
  Map<String, List<FileDocument>> mockFiles = {};

  @override
  Future<List<FileDocument>> findFileByWorkflowIdAndStepId({
    required List startKey,
    required List endKey,
    int limit = 20,
    bool descending = false,
    int skip = 0,
  }) async {
    final workflowId = startKey[0] as String;
    final stepId = startKey.length > 1 ? startKey[1] as String : '';

    final key = '$workflowId:$stepId';
    final files = mockFiles[key] ?? [];

    return files.skip(skip).take(limit).toList();
  }
}

// Setup mock
final mockService = MockFileService();
mockService.mockFiles['wf-1:step-1'] = [
  FileDocument(id: 'f1', name: 'data.zip'),
  FileDocument(id: 'f2', name: 'images.zip'),
];
```

### Test Different Key Patterns

```dart
test('finds files with exact workflow and step', () async {
  final files = await fileService.findFileByWorkflowIdAndStepId(
    startKey: ['wf-1', 'step-1'],
    endKey: ['wf-1', 'step-1', {}],
    descending: false,
  );

  expect(files.length, greaterThan(0));
  expect(files.every((f) => f.workflowId == 'wf-1'), isTrue);
  expect(files.every((f) => f.stepId == 'step-1'), isTrue);
});

test('returns empty list when no files found', () async {
  final files = await fileService.findFileByWorkflowIdAndStepId(
    startKey: ['nonexistent', 'step'],
    endKey: ['nonexistent', 'step', {}],
    descending: false,
  );

  expect(files, isEmpty);
});
```

## Common Issues

### Issue 1: Using descending: true Incorrectly
**Symptom**: No results or wrong results
**Cause**: Keys not swapped when using `descending: true`
**Fix**: Use `descending: false` or swap startKey/endKey

### Issue 2: Forgetting Wildcard
**Symptom**: Only gets exact match
**Fix**: Add `{}` to endKey

```dart
// ❌ Wrong - only exact match
endKey: [workflowId, stepId]

// ✅ Right - all files for workflow/step
endKey: [workflowId, stepId, {}]
```

### Issue 3: Large Limit Performance
**Symptom**: Slow queries
**Fix**: Use smaller limit with pagination

## Checklist

- [ ] Understand CouchDB compound key structure
- [ ] Use `{}` wildcard in endKey for range queries
- [ ] Use `descending: false` (recommended)
- [ ] Handle empty results gracefully
- [ ] Filter results by filename/type after query
- [ ] Implement pagination for large result sets
- [ ] Cache results when appropriate
- [ ] Test with both existing and non-existent keys
- [ ] Log query parameters for debugging
- [ ] Set reasonable limit (< 100)

## Related

- **Pattern**: [Metadata-to-Data Resolution](metadata-data-resolution.md)
- **Pattern**: [File Streaming](file-streaming.md)
- **Pattern**: [Debug Tools](debug-tools.md)
- **Skill**: [2 Tercen Real Implementation](../skills/2-tercen-real.md)
