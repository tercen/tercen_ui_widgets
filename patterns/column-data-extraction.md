# Pattern: Column Data Extraction

## The Problem

Tercen provides **three different APIs** for accessing column data, each with different filtering behavior and use cases:

1. **Schema API** (`tableSchemaService.get()`) - Filtered, user-facing columns
2. **Schema Select API** (`tableSchemaService.select()`) - Filtered, fetch by name
3. **Direct JSON** (`task.toJson()`) - Unfiltered, includes internal columns

**Critical**: Dot-prefixed columns (`.documentId`, `.ri`, `.ci`) are **filtered out** by schema APIs but present in direct JSON.

## The Three APIs

### API 1: Schema Get (Filtered Structure)

**Purpose**: Get column schema/metadata for user-facing columns

```dart
final columnHash = cubeTask.query?.columnHash;
final schema = await tableSchemaService.get(columnHash);

print('Columns: ${schema.columns.length}');
for (final col in schema.columns) {
  print('  ${col.name}: ${col.type}');
}
```

**Characteristics:**
- ✅ Returns column metadata (name, type)
- ❌ Filters out dot-prefixed columns
- ✅ Fast, returns schema only (no data)
- ✅ Good for discovering user columns

**When to use:**
- Discovering available user-facing columns
- Getting column types
- Checking if specific (non-dot) columns exist

**When NOT to use:**
- Accessing `.documentId` or other internal columns
- Need actual column values (only returns schema)

### API 2: Schema Select (Filtered Data)

**Purpose**: Fetch data for specific columns by name

```dart
final columnHash = cubeTask.query?.columnHash;
final data = await tableSchemaService.select(
  columnHash,
  ['documentId', 'barcode', 'filename'],  // Column names
  0,  // Offset
  1,  // Limit (rows)
);

print('Rows: ${data.nRows}');
for (final col in data.columns) {
  print('${col.name}: ${col.values}');
}
```

**Characteristics:**
- ✅ Returns actual column values
- ❌ Filters out dot-prefixed columns (may fail for `.documentId`)
- ✅ Can specify which columns to fetch
- ✅ Supports pagination (offset, limit)
- ⚠️ May succeed but return alias data (not fundamental data)

**When to use:**
- Fetching user column values
- Need pagination
- Fetching multiple rows
- Columns without dot prefix

**When NOT to use:**
- Need guaranteed access to `.documentId`
- Internal Tercen columns

### API 3: Direct JSON (Unfiltered)

**Purpose**: Access all columns including internal dot-prefixed ones

```dart
final taskJson = cubeTask.toJson();
final queryJson = taskJson['query'] as Map?;

var currentRelation = queryJson?['relation'] as Map?;
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

        if (name == '.documentId') {
          final docId = values?.first?.toString();
          print('Found .documentId: $docId');
        }
      }
    }
    break;
  }
  currentRelation = currentRelation['relation'] as Map?;
}
```

**Characteristics:**
- ✅ Returns ALL columns (including dot-prefixed)
- ✅ Access to fundamental data IDs
- ✅ No filtering
- ❌ More complex to navigate
- ❌ Returns JSON maps (not typed objects)
- ⚠️ May only contain first page of data

**When to use:**
- Need `.documentId` or other internal columns
- Schema API fails or returns empty
- Debugging column structure
- Fundamental data IDs required

**When NOT to use:**
- Need pagination of large datasets
- Prefer typed objects over JSON maps
- Simple user column access

## Decision Tree

```
Need to access column data?
├─ Is it .documentId or other dot-prefixed column?
│  └─ YES → Use Direct JSON (API 3)
│
├─ Do you need actual values or just schema?
│  ├─ Just schema → Use Schema Get (API 1)
│  └─ Need values → Continue...
│
├─ Do you need pagination or many rows?
│  ├─ YES → Use Schema Select (API 2)
│  └─ NO → Continue...
│
└─ Is it a user-facing column?
   ├─ YES → Use Schema Select (API 2)
   └─ NO → Use Direct JSON (API 3)
```

## Common Patterns

### Pattern 1: Extract .documentId (Direct JSON)

**Use case**: Get fundamental file ID for file operations

```dart
Future<String?> extractDocumentId(CubeQueryTask cubeTask) async {
  try {
    final taskJson = cubeTask.toJson();
    final queryJson = taskJson['query'] as Map?;

    if (queryJson == null || queryJson['relation'] == null) {
      return null;
    }

    var currentRelation = queryJson['relation'] as Map?;

    // Navigate to InMemoryTable
    while (currentRelation != null) {
      if (currentRelation['kind'] == 'InMemoryRelation' &&
          currentRelation['inMemoryTable'] != null) {

        final inMemoryTable = currentRelation['inMemoryTable'] as Map;
        final columns = inMemoryTable['columns'] as List?;

        if (columns != null) {
          for (final col in columns) {
            final colMap = col as Map;
            if (colMap['name'] == '.documentId') {
              final values = colMap['values'] as List?;
              if (values != null && values.isNotEmpty) {
                return values.first?.toString();
              }
            }
          }
        }
        break;
      }
      currentRelation = currentRelation['relation'] as Map?;
    }

    return null;
  } catch (e) {
    print('Error extracting .documentId: $e');
    return null;
  }
}
```

**See**: [Pattern: Metadata-to-Data Resolution](metadata-data-resolution.md)

### Pattern 2: List Available User Columns (Schema Get)

**Use case**: Discover what columns user has available

```dart
Future<List<String>> listUserColumns(CubeQueryTask cubeTask) async {
  final columnHash = cubeTask.query?.columnHash;
  if (columnHash == null || columnHash.isEmpty) {
    return [];
  }

  final schema = await tableSchemaService.get(columnHash);
  return schema.columns.map((col) => col.name).toList();
}

// Usage
final columns = await listUserColumns(cubeTask);
print('Available columns: ${columns.join(", ")}');
// Output: Available columns: barcode, filename, well, field
```

### Pattern 3: Fetch User Column Values (Schema Select)

**Use case**: Get actual data from user columns

```dart
Future<Map<String, List<dynamic>>> fetchColumnValues(
  CubeQueryTask cubeTask,
  List<String> columnNames,
  {int limit = 100}
) async {
  final columnHash = cubeTask.query?.columnHash;
  if (columnHash == null || columnHash.isEmpty) {
    return {};
  }

  final data = await tableSchemaService.select(
    columnHash,
    columnNames,
    0,
    limit,
  );

  final result = <String, List<dynamic>>{};
  for (final col in data.columns) {
    result[col.name] = col.values ?? [];
  }

  return result;
}

// Usage
final values = await fetchColumnValues(
  cubeTask,
  ['barcode', 'filename'],
  limit: 10,
);

print('Barcodes: ${values['barcode']}');
print('Filenames: ${values['filename']}');
```

### Pattern 4: Fallback Strategy (Try Schema, Then JSON)

**Use case**: Maximize compatibility when column may or may not be filtered

```dart
Future<String?> getDocumentIdWithFallback(CubeQueryTask cubeTask) async {
  // Try 1: Schema Select (for documentId alias)
  try {
    final columnHash = cubeTask.query?.columnHash;
    if (columnHash != null && columnHash.isNotEmpty) {
      final data = await tableSchemaService.select(
        columnHash,
        ['documentId'],
        0,
        1,
      );

      final docIdCol = data.columns.where((c) => c.name == 'documentId').firstOrNull;
      if (docIdCol?.values != null && docIdCol!.values.isNotEmpty) {
        final docId = docIdCol.values.first?.toString();
        if (docId != null && docId.isNotEmpty) {
          print('✓ Got documentId from schema: $docId');
          return docId;
        }
      }
    }
  } catch (e) {
    print('⚠️ Schema select failed: $e');
  }

  // Try 2: Direct JSON (for .documentId fundamental)
  try {
    final docId = await extractDocumentId(cubeTask);
    if (docId != null && docId.isNotEmpty) {
      print('✓ Got .documentId from JSON: $docId');
      return docId;
    }
  } catch (e) {
    print('⚠️ JSON extraction failed: $e');
  }

  print('❌ Could not extract documentId from any source');
  return null;
}
```

## Schema Filtering Behavior

### Why Filtering Exists

Dot-prefixed columns are **internal Tercen metadata**:
- `.documentId` - Fundamental file reference
- `.ri` - Row index
- `.ci` - Column index
- `.y` - Y axis values
- Other internal columns

The schema API intentionally hides these to provide a clean user-facing interface.

**This is architectural design, not a bug.**

### What Gets Filtered

**Filtered (not in schema API):**
- `.documentId`
- `.ri`
- `.ci`
- `.y`
- Any column starting with `.`

**Not filtered (in schema API):**
- `documentId` (alias column)
- `barcode`
- `filename`
- User-defined columns
- Any column without `.` prefix

### Implications

```dart
// ❌ This will NOT find .documentId
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId');
// Result: Empty!

// ✅ This WILL find .documentId
final taskJson = cubeTask.toJson();
// Navigate to columns and search for '.documentId'
```

## Performance Considerations

### Schema APIs are Faster
```dart
// Fast - only fetches schema metadata
final schema = await tableSchemaService.get(columnHash);

// Fast - fetches only requested columns/rows
final data = await tableSchemaService.select(columnHash, ['col1'], 0, 10);

// Slower - fetches entire task with all nested data
final taskJson = cubeTask.toJson();
```

**Rule of thumb:**
- Use schema APIs when possible (user columns)
- Use direct JSON only when necessary (internal columns)

### Pagination

Only Schema Select supports pagination:

```dart
// Fetch in batches
for (int offset = 0; offset < totalRows; offset += batchSize) {
  final data = await tableSchemaService.select(
    columnHash,
    ['col1', 'col2'],
    offset,
    batchSize,
  );
  // Process batch
}
```

Direct JSON cannot paginate - it returns first page only.

## Error Handling

### Error 1: Column Not Found in Schema
```dart
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId').firstOrNull;

if (col == null) {
  print('⚠️ Column not in schema - likely dot-prefixed');
  print('   Falling back to direct JSON extraction');
  // Use API 3 (direct JSON)
}
```

### Error 2: Empty Column Values
```dart
final data = await tableSchemaService.select(columnHash, ['documentId'], 0, 1);

if (data.nRows == 0) {
  print('❌ No rows returned');
  return null;
}

final col = data.columns.where((c) => c.name == 'documentId').firstOrNull;
if (col == null || col.values == null || col.values.isEmpty) {
  print('❌ Column has no values');
  return null;
}
```

### Error 3: JSON Navigation Fails
```dart
try {
  final taskJson = cubeTask.toJson();
  final queryJson = taskJson['query'] as Map?;

  if (queryJson == null) {
    print('❌ Task has no query in JSON');
    return null;
  }

  // Continue navigation...
} catch (e) {
  print('❌ Error navigating JSON structure: $e');
  return null;
}
```

## Testing

### Test All Three APIs

```dart
test('Schema Get returns user columns only', () async {
  final schema = await tableSchemaService.get(columnHash);

  // Should have user columns
  expect(schema.columns.any((c) => c.name == 'barcode'), isTrue);

  // Should NOT have internal columns
  expect(schema.columns.any((c) => c.name == '.documentId'), isFalse);
});

test('Schema Select fetches column values', () async {
  final data = await tableSchemaService.select(
    columnHash,
    ['barcode'],
    0,
    1,
  );

  expect(data.nRows, greaterThan(0));
  expect(data.columns.length, equals(1));
  expect(data.columns.first.name, equals('barcode'));
});

test('Direct JSON includes dot-prefixed columns', () async {
  final taskJson = cubeTask.toJson();
  final columns = extractColumnsFromJson(taskJson);

  // Should have internal columns
  expect(columns.any((c) => c['name'] == '.documentId'), isTrue);
  expect(columns.any((c) => c['name'] == '.ri'), isTrue);
});
```

## Debugging

Use `print_task_json.dart` to inspect full structure:

```bash
dart run tools/print_task_json.dart "https://stage.tercen.com" "token" "taskId"
```

Look for:
- `query.relation.inMemoryTable.columns` array
- Column names (both user and dot-prefixed)
- Column values
- Data types

**See**: [Pattern: Debug Tools](debug-tools.md)

## Checklist

- [ ] Understand three column data APIs
- [ ] Know when each API is appropriate
- [ ] Understand dot-prefixed column filtering
- [ ] Use direct JSON for .documentId extraction
- [ ] Use schema APIs for user columns
- [ ] Implement fallback strategies
- [ ] Handle empty results gracefully
- [ ] Test with both filtered and unfiltered columns
- [ ] Consider performance implications
- [ ] Use pagination for large datasets

## Related

- **Pattern**: [Metadata-to-Data Resolution](metadata-data-resolution.md)
- **Pattern**: [Task Hierarchy Navigation](task-hierarchy-navigation.md)
- **Pattern**: [Debug Tools](debug-tools.md)
- **Issue**: [#11 Schema Service Filtering](../issues/11-schema-filtering.md)
- **Issue**: [#10 Metadata-to-Data Resolution](../issues/10-metadata-data-resolution.md)
