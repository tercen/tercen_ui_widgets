# Issue #10: Metadata-to-Data ID Resolution

**Severity**: CRITICAL - FOUNDATIONAL CONCEPT
**Frequency**: Every operator that accesses files or data
**Status**: ✅ SOLVED (Feb 2026) - See Solution section below

## The Architecture

Tercen separates data from metadata:

**Metadata IDs (User-facing):**
- `taskId` - User-visible task reference
- `documentId` - File alias (changes on clone)
- `projectId` - Project reference
- `workflowId` - Workflow reference

**Data IDs (Actual data):**
- `.taskId` - Actual task data
- **`.documentId`** - **Fundamental file reference (use this!)**
- `.projectId` - Actual project data
- `.workflowId` - Actual workflow data

**Cloning behavior:**
- Project cloned → NEW metadata created → ORIGINAL data reused
- No data duplication, only metadata duplication
- This is why you need to resolve: metadata ID → data ID

## The Problem

File operations need data IDs (`.documentId`), but:

1. Users only see metadata IDs (`taskId` in URL)
2. URL `documentId` is the **WebAppOperator ID**, not a file ID
3. Schema API intentionally filters out dot-prefixed columns
4. Using alias `documentId` returns 500 Error: "WebAppOperator"

### Why Errors Occur

```dart
// ❌ Using URL documentId - returns 500 "WebAppOperator" error
final documentId = urlParser.documentId;  // This is WebAppOperator ID!
final bytes = await fileService.download(documentId);
// Error: 500 Invalid argument (bad kind error): "WebAppOperator"

// ❌ Using relation.inMemoryRelations getter - returns empty
final relations = relation.inMemoryRelations;  // Empty! Doesn't navigate wrappers

// ✅ Using .documentId from InMemoryTable - works everywhere
final documentId = extractFromInMemoryTable();  // Navigate manually
final bytes = await fileService.download(documentId);  // Success!
```

**Root cause**: When project is cloned:
- `documentId` (metadata) gets new value
- `.documentId` (data) stays the same (shared data)
- File service needs `.documentId` to find actual file

## The Solution ✅

### Understanding Relation Hierarchy

Tercen Relations are **expression trees**, not flat tables. You must manually navigate through wrappers to find the InMemoryTable:

```
Relation (abstract)
├── Leaf Relations (actual data)
│   └── InMemoryRelation    ← Contains InMemoryTable with columns
└── Unary Wrappers (transformations)
    ├── GatherRelation      ← Wide → Long pivot (wraps other relations)
    └── CompositeRelation   ← Has mainRelation + joinOperators
```

**Typical structure in production:**
```
GatherRelation (depth 0)
    └── CompositeRelation (depth 1)
            └── mainRelation: InMemoryRelation (depth 2)
                    └── InMemoryTable
                            └── columns[]
                                    ├── .documentId (actual file ID) ✓
                                    ├── documentId (alias)
                                    ├── Image
                                    └── ...
```

### Navigation Algorithm

**Step 1: Navigate through relation tree to find InMemoryTable**

```dart
// Start from task JSON (not Relation object!)
final taskJson = cubeTask.toJson();
var currentRelation = taskJson['query']['relation'] as Map?;
int depth = 0;

while (currentRelation != null && depth < 20) {
  final kind = currentRelation['kind'];
  print('📋 Relation[$depth] kind: $kind');

  // Found InMemoryRelation? Extract columns!
  if (kind == 'InMemoryRelation' && currentRelation['inMemoryTable'] != null) {
    final columns = currentRelation['inMemoryTable']['columns'] as List;

    // Search for .documentId column
    for (final col in columns) {
      final name = col['name'];
      if (name == '.documentId' || name.endsWith('..documentId')) {
        final documentId = col['values'].first;  // ← Use this!
        return documentId;
      }
    }
    break;
  }

  // Navigate deeper based on relation type:
  // 1. Most wrappers use 'relation' property
  // 2. CompositeRelation uses 'mainRelation' property
  if (currentRelation['relation'] != null) {
    currentRelation = currentRelation['relation'];
  } else if (kind == 'CompositeRelation' && currentRelation['mainRelation'] != null) {
    print('📋 CompositeRelation detected, navigating to mainRelation...');
    currentRelation = currentRelation['mainRelation'];
  } else {
    print('⚠️ No child relation found');
    break;
  }

  depth++;
}
```

**Step 2: Use Relation.findDocumentId() as fallback (SDK 1.11.0+)**

If `.documentId` is not in columns, but `documentId` aliases exist:

```dart
// Find documentId aliases in columns
for (final col in columns) {
  if (col['name'] == 'documentId' || col['name'].endsWith('.documentId')) {
    final alias = col['values'].first;

    // Resolve alias to actual .documentId
    final relation = cubeTask.query.relation;
    final actualDocId = relation.findDocumentId(alias);
    return actualDocId;
  }
}
```

**How `relation.findDocumentId()` works:**
- Searches InMemoryRelations for both `documentId` and `.documentId` columns
- Finds the index where alias matches in `documentId` column
- Returns the `.documentId` value at that same index

### Common Pitfalls

**❌ DON'T: Use relation.inMemoryRelations getter**
```dart
final relations = relation.inMemoryRelations;  // Empty! Doesn't navigate wrappers
```

**❌ DON'T: Use URL documentId**
```dart
final documentId = urlParser.documentId;  // This is WebAppOperator ID!
fileService.download(documentId);  // 500 Error: "WebAppOperator"
```

**❌ DON'T: Use tableSchemaService**
```dart
final schema = await tableSchemaService.get(columnHash);
final col = schema.columns.where((c) => c.name == '.documentId');  // Filtered out!
```

**✅ DO: Navigate manually through JSON to InMemoryTable**
```dart
var currentRelation = taskJson['query']['relation'];
// Navigate through wrappers...
final columns = currentRelation['inMemoryTable']['columns'];
// Extract .documentId from columns
```

## Why This Matters

This is NOT a workaround - it's **fundamental Tercen architecture**:

- Enables efficient project cloning (no data duplication)
- Separates user context (metadata) from actual data
- Relations are expression trees that must be navigated
- Will apply to other resources (projects, workflows, tasks)

**You will encounter this in EVERY operator that accesses files.**

## Implementation

See `lib/utils/document_id_resolver.dart` for complete implementation.

**Strategy order:**
1. **Primary**: Navigate to InMemoryTable and extract `.documentId` directly
2. **Fallback**: Find `documentId` aliases and resolve using `Relation.findDocumentId()`
3. **Development**: Use hardcoded ID for local testing
4. **NEVER**: Use URL documentId (it's the WebAppOperator ID!)

## Debugging

**Expected console logs when working correctly:**

```
📋 Relation[0] kind: GatherRelation
📋 Relation[1] kind: CompositeRelation
📋 CompositeRelation detected, navigating to mainRelation...
📋 Relation[2] kind: InMemoryRelation
✓ Found InMemoryRelation at depth 2
📋 InMemoryTable has 15 columns
📋 Found 1 .documentId value(s) in column "ds1..documentId": abc123...
✓ Using .documentId directly: abc123...
```

**If you see "WebAppOperator" error:**
- You're using URL documentId instead of table .documentId
- Check navigation reached InMemoryRelation
- Verify value is from `.documentId` column (with dot!)

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

## Dependencies

- **sci_tercen_client 1.11.0+**: Required for `Relation.findDocumentId()` method
- Manual JSON navigation for relation hierarchy

## Related

- **Pattern**: [Metadata-to-Data Resolution](../patterns/metadata-data-resolution.md)
- **Pattern**: [Task Hierarchy Navigation](../patterns/task-hierarchy-navigation.md)
- **Issue**: [#11 Schema Service Filtering](11-schema-filtering.md)
- **Reference**: [Tercen Relational Algebra](https://github.com/tercen/sci/blob/main/docs/TERCEN_RELATIONAL_ALGEBRA.md)
- **Example**: See pamsoft_grid_flutter_operator for complete working implementation
