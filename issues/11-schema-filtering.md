# Issue #11: Schema Service Filtering Behavior

**Severity**: CRITICAL - ARCHITECTURAL
**Frequency**: Any operation needing dot-prefixed columns
**First Discovered**: ps12_image_overview_flutter_operator (2026-01-26)

## The Behavior

`tableSchemaService.get()` **intentionally filters out dot-prefixed columns**.

**This is by design, not a bug.**

## What Gets Filtered

**Filtered (not returned by schema API):**

- `.documentId` - Fundamental file reference
- `.ri` - Row index
- `.ci` - Column index
- `.y` - Y axis values
- Any column starting with `.` prefix

**Not filtered (returned by schema API):**

- `documentId` - Alias column (may exist but often 404s)
- `barcode` - User column
- `filename` - User column
- Any user-defined columns without `.` prefix

## Why It Exists

Dot-prefixed columns are **internal Tercen metadata**:

- `.documentId` = Fundamental data reference (actual file ID)
- `.ri`, `.ci` = Internal indexing
- `.y` = Internal data values

The schema service provides a **user-facing interface**, hiding internal implementation details.

**Design rationale**: Clean API separation between user data and system internals.

## The Problem

```dart
// Try to get .documentId from schema
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId');

print(col); // Empty! Filtered out by design
```

**Result**: Cannot access `.documentId` through normal schema API, even though it exists in the underlying data.

## When You Hit This

You'll encounter this when:

- Accessing `.documentId` for file operations
- Accessing `.ri`, `.ci` for row/column indices
- Any internal Tercen metadata column
- Debugging why expected columns aren't in schema

## The Solution

**Use `task.toJson()` to access unfiltered column data:**

```dart
// ❌ Filtered - no dot-prefixed columns
final schema = await tableSchemaService.get(columnHash);
// schema.columns won't include .documentId

// ✅ Unfiltered - all columns including dot-prefixed
final taskJson = cubeTask.toJson();
final columns = taskJson['query']['relation']['inMemoryTable']['columns'];

for (final col in columns) {
  if (col['name'] == '.documentId') {
    // Found it! This works.
    final documentId = col['values'].first;
  }
}
```

## Three Column Access APIs

Tercen provides three ways to access columns, with different filtering:

| API | Method | Filters `.documentId`? | Use Case |
| --- | ------ | ---------------------- | -------- |
| Schema Get | `tableSchemaService.get()` | ✅ YES (filtered) | User column discovery |
| Schema Select | `tableSchemaService.select()` | ✅ YES (filtered) | User column data |
| Direct JSON | `task.toJson()` | ❌ NO (unfiltered) | Internal columns |

**See**: [Pattern: Column Data Extraction](../patterns/column-data-extraction.md)

## Common Errors

### Error 1: Column Not Found

```dart
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId').firstOrNull;

if (col == null) {
  // ⚠️ This is expected behavior!
  print('Column not in schema - dot-prefixed columns are filtered');
  // Solution: Use task.toJson() instead
}
```

### Error 2: documentId vs .documentId

```dart
// May exist in schema (but is alias, may 404)
final docId = schema.columns.where((c) => c.name == 'documentId');

// Will NOT exist in schema (fundamental, but filtered)
final dotDocId = schema.columns.where((c) => c.name == '.documentId');
```

**Best practice**: Always use `.documentId` from task JSON for file operations.

## Debugging

### Inspect Task JSON Structure

```bash
# Use print_task_json tool
dart run tools/print_task_json.dart "https://stage.tercen.com" "token" "taskId"
```

**Look for**:

```json
{
  "query": {
    "relation": {
      "inMemoryTable": {
        "columns": [
          {"name": ".documentId", "values": ["ac090f..."]},
          {"name": "documentId", "values": ["ac090f..."]},
          {"name": "barcode", "values": ["641070511"]}
        ]
      }
    }
  }
}
```

Note both `.documentId` and `documentId` present in JSON, but only `documentId` in schema API.

**See**: [Pattern: Debug Tools](../patterns/debug-tools.md)

## Performance Implications

**Schema APIs are faster:**

```dart
// Fast - schema only
final schema = await tableSchemaService.get(columnHash);

// Slower - full task with nested data
final taskJson = cubeTask.toJson();
```

**Rule of thumb:**

- Use schema APIs for user columns (faster)
- Use direct JSON only when necessary (internal columns)

## Checklist

- [ ] Understand schema filtering is intentional
- [ ] Know which columns are filtered (dot-prefixed)
- [ ] Use task.toJson() for .documentId extraction
- [ ] Use schema APIs for user columns (performance)
- [ ] Don't expect .documentId in schema results
- [ ] Create debug tools to inspect task JSON
- [ ] Test with both metadata and data IDs

## Related

- **Pattern**: [Metadata-to-Data Resolution](../patterns/metadata-data-resolution.md)
- **Pattern**: [Column Data Extraction](../patterns/column-data-extraction.md)
- **Pattern**: [Task Hierarchy Navigation](../patterns/task-hierarchy-navigation.md)
- **Pattern**: [Debug Tools](../patterns/debug-tools.md)
- **Issue**: [#10 Metadata-to-Data Resolution](10-metadata-data-resolution.md)
- **Skill**: [2 Tercen Real Implementation](../skills/2-tercen-real.md)
