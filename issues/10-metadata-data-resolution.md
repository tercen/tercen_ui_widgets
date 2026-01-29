# Issue #10: Metadata-to-Data ID Resolution

**Severity**: CRITICAL - FOUNDATIONAL CONCEPT
**Frequency**: Every operator that accesses files or data

## The Architecture

Tercen separates data from metadata:

**Metadata IDs (User-facing):**
- `taskId` - User-visible task reference
- `documentId` - File alias (may return 404)
- `projectId` - Project reference
- `workflowId` - Workflow reference

**Data IDs (Actual data):**
- `.taskId` - Actual task data
- `.documentId` - **Fundamental file reference (use this!)**
- `.projectId` - Actual project data
- `.workflowId` - Actual workflow data

**Cloning behavior:**
- Project cloned → NEW metadata created → ORIGINAL data reused
- No data duplication, only metadata duplication
- This is why you need to resolve: metadata ID → data ID

## The Problem

File operations need data IDs (`.documentId`), but:

1. Users only see metadata IDs (`taskId` in URL)
2. Schema API intentionally filters out dot-prefixed columns
3. Using alias `documentId` often returns 404 (points to wrong data)

### Why 404 Errors Occur

```dart
// ❌ Using metadata ID - returns 404 in cloned projects
final bytes = await fileService.download(documentId);
// Error: 404 Not Found

// ✅ Using data ID - works in original and cloned projects
final bytes = await fileService.download(dotDocumentId);
// Success!
```

**Root cause**: When project is cloned:
- `documentId` (metadata) gets new value
- `.documentId` (data) stays the same (shared data)
- File service needs `.documentId` to find actual file

## The Solution

**Always extract dot-prefixed IDs from task JSON:**

```dart
// ❌ WRONG - Schema API filters dot-prefixed columns
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId'); // Empty!

// ✅ RIGHT - Extract from task JSON
final taskJson = cubeTask.toJson();
final columns = taskJson['query']['relation']['inMemoryTable']['columns'];

for (final col in columns) {
  if (col['name'] == '.documentId') {
    return col['values'].first; // This works!
  }
}
```

## Why This Matters

This is NOT a workaround - it's **fundamental Tercen architecture**:

- Enables efficient project cloning (no data duplication)
- Separates user context (metadata) from actual data
- Will apply to other resources (projects, workflows, tasks)

**You will encounter this in EVERY operator that accesses files.**

## Implementation

Create `lib/utils/document_id_resolver.dart` with hierarchical fallback:

1. **Primary**: Extract `.documentId` from task JSON (production)
2. **Fallback 1**: Try `documentId` alias from schema (may 404)
3. **Fallback 2**: Search files by workflowId/stepId
4. **Fallback 3**: Use development hardcoded ID
5. **Final**: Return null for mock data fallback

**See**: [Pattern: Metadata-to-Data Resolution](../patterns/metadata-data-resolution.md)

## Future Implications

Expect similar patterns for:

- Project cloning: `projectId` → `.projectId`
- Workflow operations: `workflowId` → `.workflowId`
- Task data access: `taskId` → `.taskId` (potentially)

**General principle**: User-facing IDs are metadata; file operations need data IDs (dot-prefixed).

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

### Common Clone Failures

**Symptom**: Operator works in original, fails with 404 in clone
**Cause**: Using `documentId` (metadata) instead of `.documentId` (data)
**Fix**: Implement proper metadata → data ID resolution

**Symptom**: Cloned project shows different data
**Cause**: Using metadata reference that changed during clone
**Fix**: Resolve to data ID first, then access files

## Related

- **Pattern**: [Metadata-to-Data Resolution](../patterns/metadata-data-resolution.md)
- **Pattern**: [Task Hierarchy Navigation](../patterns/task-hierarchy-navigation.md)
- **Pattern**: [Column Data Extraction](../patterns/column-data-extraction.md)
- **Issue**: [#11 Schema Service Filtering](11-schema-filtering.md)
- **Skill**: [2 Tercen Real Implementation](../skills/2-tercen-real.md)
