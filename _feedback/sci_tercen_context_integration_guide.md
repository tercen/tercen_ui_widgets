# sci_tercen_context — Integration Guide for Flutter Operators

## What is this?

`sci_tercen_context` is a new Dart package that provides R/Python-style context
abstraction for Tercen Flutter operators. It lives at `sci_tercen_context/` in
the `sci_tercen_client` monorepo.

**The problem it solves**: Flutter operators currently require 30-80 lines of
boilerplate to do what R does in 3 lines. Developers must manually navigate task
hierarchies (`RunWebAppTask` → `CubeQueryTask`), resolve schema hashes, filter
system columns, and call `tableSchemaService.select()` with the right parameters.
This is error-prone and was the root cause of the grid-data-resolution blocker
(see `_local/Examples/grid-data-resolution-debug-log.md`).

**What it provides**: A `ctx` object (like R's `ctx`) that handles all of this
automatically.

### R equivalent

```r
ctx <- tercenCtx(taskId = taskId)
qtTable  <- ctx$select(c(".ci", ".ri", ".y"))
cTable   <- ctx$cselect()
rTable   <- ctx$rselect()
colors   <- ctx$colors
ns       <- ctx$namespace
thresh   <- ctx$op.value("threshold", as.double, 0.5)
```

### Dart equivalent (using sci_tercen_context)

```dart
final ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);
final qtTable  = await ctx.select(names: ['.ci', '.ri', '.y']);
final cTable   = await ctx.cselect();
final rTable   = await ctx.rselect();
final colors   = await ctx.colors;
final ns       = await ctx.namespace;
final thresh   = await ctx.opDoubleValue('threshold', defaultValue: 0.5);
```

---

## Current Phase Status

| Phase | Status | What it covers |
|-------|--------|----------------|
| **Phase 1** | **COMPLETE** | Data access (`select`, `cselect`, `rselect`), schema resolution, metadata, operator properties |
| **Phase 2** | **COMPLETE** | Task lifecycle — `log()`, `progress()`, `save()`, `saveRelation()`, `requestResources()`, TSON normalization, column metadata auto-inference |
| Phase 3 | Not started | Relation tree resolution (CompositeRelation/SimpleRelation walking) |
| Phase 4 | Not started | Streaming variants (`selectStream()`, etc.) |

Phases 1 and 2 cover the full **read + write** lifecycle. Operators can read data,
compute results, log/report progress, save results back to Tercen, and request
compute resources — all through the context object.

---

## Adding the dependency

In the Flutter operator's `pubspec.yaml`:

```yaml
dependencies:
  sci_tercen_context:
    git:
      ref: 1.12.0   # or latest tag
      url: https://github.com/tercen/sci_tercen_client
      path: sci_tercen_context
```

For local development alongside the monorepo:

```yaml
dependencies:
  sci_tercen_context:
    path: ../sci_tercen_client/sci_tercen_context
```

Import:

```dart
import 'package:sci_tercen_context/sci_tercen_context.dart';
```

This single import gives you everything — all Tercen model classes (CubeQuery,
Schema, Table, etc.), `ServiceFactoryBase`, and all context classes.

---

## Creating a context

The context needs a `ServiceFactoryBase` (or `ServiceFactory`, which extends it).
All three existing Flutter operators already create one via
`createServiceFactoryForWebApp()`.

### Production mode (taskId) — most common for deployed operators

```dart
final factory = await createServiceFactoryForWebApp();
final ctx = await tercenCtx(
  serviceFactory: factory,
  taskId: taskId,  // from URL query params or environment
);
```

This automatically:
- Fetches the task via `taskService.get(taskId)`
- Handles `RunWebAppTask` → navigates to `CubeQueryTask` via `cubeQueryTaskId`
- Handles direct `CubeQueryTask`
- Extracts the `CubeQuery` with all hashes

### Dev mode (workflowId + stepId) — for interactive development

```dart
final ctx = await tercenCtx(
  serviceFactory: factory,
  workflowId: workflowId,
  stepId: stepId,
);
```

This fetches the query via `workflowService.getCubeQuery(workflowId, stepId)`.

### Direct construction (if you need more control)

```dart
// Production
final ctx = await OperatorContext.create(
  serviceFactory: factory,
  taskId: taskId,
);

// Dev
final ctx = OperatorContextDev(
  serviceFactory: factory,
  workflowId: workflowId,
  stepId: stepId,
);
```

---

## Complete Phase 1 API Reference

### Data Selection

All selection methods return `Future<Table>`. When `names` is empty, they
auto-select all non-system columns (filters out `int64`/`uint64` types).

| Method | What it fetches | Schema hash used |
|--------|----------------|------------------|
| `ctx.select(names: [...])` | Main data table (`.y`, `.ci`, `.ri`, values) | `query.qtHash` |
| `ctx.cselect(names: [...])` | Column dimension (Image, spotRow, spotCol, etc.) | `query.columnHash` |
| `ctx.rselect(names: [...])` | Row dimension (variable names, row factors) | `query.rowHash` |
| `ctx.selectPairwise(names: [...])` | Pairwise data (for scatter plots) | `query.qtHash` |

All accept optional `offset` and `limit` parameters (default: 0 and -1 for all rows).

```dart
// Fetch specific columns
final data = await ctx.select(names: ['.y', '.ci', '.ri']);

// Fetch all non-system columns (auto-filtered)
final allData = await ctx.select();

// Fetch with pagination
final page = await ctx.select(names: ['.y'], offset: 0, limit: 1000);

// Column metadata
final colData = await ctx.cselect(names: ['Image', 'spotRow', 'spotCol']);

// Row metadata
final rowData = await ctx.rselect();
```

### Schemas (lazy-cached)

Schemas are fetched once and cached. Subsequent calls return the cached value.

| Property | Returns | Source |
|----------|---------|--------|
| `ctx.schema` | `Future<Schema>` | `tableSchemaService.get(query.qtHash)` |
| `ctx.cschema` | `Future<Schema>` | `tableSchemaService.get(query.columnHash)` |
| `ctx.rschema` | `Future<Schema>` | `tableSchemaService.get(query.rowHash)` |

```dart
final s = await ctx.schema;
print('Main table has ${s.nRows} rows, ${s.columns.length} columns');
```

### Column Name Discovery

| Property | Returns | Description |
|----------|---------|-------------|
| `ctx.names` | `Future<List<String>>` | Column names from main schema |
| `ctx.cnames` | `Future<List<String>>` | Column names from column dimension |
| `ctx.rnames` | `Future<List<String>>` | Column names from row dimension |

```dart
final columnFactors = await ctx.cnames;
// e.g. ['Image', 'spotRow', 'spotCol', 'ID', '.ci']

final rowFactors = await ctx.rnames;
// e.g. ['variable', '.ri']
```

### Axis and Visual Metadata

| Property | Returns | Source |
|----------|---------|--------|
| `ctx.colors` | `Future<List<String>>` | Color factor names from all axis queries |
| `ctx.labels` | `Future<List<String>>` | Label factor names from all axis queries |
| `ctx.errors` | `Future<List<String>>` | Error factor names from all axis queries |
| `ctx.xAxis` | `Future<List<String>>` | X-axis factor names (unique, non-empty) |
| `ctx.yAxis` | `Future<List<String>>` | Y-axis factor names (unique, non-empty) |
| `ctx.chartTypes` | `Future<List<String>>` | Chart type per axis query |
| `ctx.pointSizes` | `Future<List<int>>` | Point size per axis query |

### Data Shape Metadata

| Property | Returns | Description |
|----------|---------|-------------|
| `ctx.isPairwise` | `Future<bool>` | True if column and row names overlap (scatter/pairwise mode) |
| `ctx.hasXAxis` | `Future<bool>` | True if main schema has a `.x` column |
| `ctx.hasNumericXAxis` | `Future<bool>` | True if `.x` column exists and is type `double` |

### Operator Properties

Read values from `query.operatorSettings.operatorRef.propertyValues`. These are
the settings the user configures in the Tercen UI for the operator.

| Method | Returns |
|--------|---------|
| `ctx.opStringValue('name', defaultValue: '')` | `Future<String>` |
| `ctx.opDoubleValue('name', defaultValue: 0.0)` | `Future<double>` |
| `ctx.opIntValue('name', defaultValue: 0)` | `Future<int>` |
| `ctx.opBoolValue('name', defaultValue: false)` | `Future<bool>` |
| `ctx.opValue<T>(name: ..., converter: ..., defaultValue: ...)` | `Future<T>` (generic) |

```dart
final threshold = await ctx.opDoubleValue('threshold', defaultValue: 0.5);
final method = await ctx.opStringValue('method', defaultValue: 'mean');
final showGrid = await ctx.opBoolValue('showGrid', defaultValue: true);
```

### Namespace Helper

Adds the operator namespace prefix to column names (for output). System columns
starting with `.` are left unchanged.

```dart
final nsMap = await ctx.addNamespace(['gridX', 'gridY', '.ci']);
// e.g. {'gridX': 'ns.gridX', 'gridY': 'ns.gridY', '.ci': '.ci'}
```

### Other Properties

| Property | Returns | Description |
|----------|---------|-------------|
| `ctx.namespace` | `Future<String>` | Operator namespace from settings |
| `ctx.query` | `Future<CubeQuery>` | The underlying CubeQuery (for advanced use) |
| `ctx.task` | `Task?` | The task object (may be null in dev mode) |
| `ctx.taskId` | `String?` | Shorthand for `task?.id` |
| `ctx.serviceFactory` | `ServiceFactoryBase` | The service factory (for advanced use) |

---

## Before/After Migration Examples

### Example 1: Loading grid data (pamsoft_grid_flutter_operator)

**BEFORE** (~50 lines):

```dart
// 1. Manual task navigation
final task = await _factory.taskService.get(taskId);
CubeQueryTask cubeTask;
if (task is CubeQueryTask) {
  cubeTask = task;
} else if (task is RunWebAppTask) {
  final wrappedTask = await _factory.taskService.get(task.cubeQueryTaskId);
  if (wrappedTask is! CubeQueryTask) throw Exception('...');
  cubeTask = wrappedTask;
} else {
  throw Exception('...');
}

// 2. Manual schema resolution
final query = cubeTask.query;
final qtSchema = await _factory.tableSchemaService.get(query.qtHash);
final colSchema = await _factory.tableSchemaService.get(query.columnHash);
final rowSchema = await _factory.tableSchemaService.get(query.rowHash);

// 3. Manual column filtering
final colFactorNames = colSchema.columns
    .map((c) => c.name)
    .where((name) => !name.startsWith('.'))
    .toList();

// 4. Manual data fetching
final qtData = await _factory.tableSchemaService.select(
  query.qtHash, ['.ci', '.ri', '.y'], 0, qtSchema.nRows);
final colData = await _factory.tableSchemaService.select(
  query.columnHash, colFactorNames, 0, colSchema.nRows);
final rowData = await _factory.tableSchemaService.select(
  query.rowHash, rowFactorNames, 0, rowSchema.nRows);
```

**AFTER** (~5 lines):

```dart
final ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);

final qtData  = await ctx.select(names: ['.ci', '.ri', '.y']);
final colData = await ctx.cselect();   // auto-filters system columns
final rowData = await ctx.rselect();   // auto-filters system columns
```

### Example 2: Cross-tab data extraction (mean_and_cv_flutter_operator)

**BEFORE** (~40 lines):

```dart
Future<CubeQueryTask> _navigateToCubeQueryTask(String taskId) async {
  final task = await _serviceFactory.taskService.get(taskId);
  CubeQueryTask? cubeTask;
  if (task is RunWebAppTask) {
    final cubeTaskObj = await _serviceFactory.taskService.get(task.cubeQueryTaskId);
    if (cubeTaskObj is! CubeQueryTask) throw Exception('...');
    cubeTask = cubeTaskObj;
  } else if (task is CubeQueryTask) {
    cubeTask = task;
  } else {
    throw Exception('...');
  }
  return cubeTask;
}

// Then separately:
final cubeTask = await _navigateToCubeQueryTask(taskId);
final query = cubeTask.query;
final qtSchema = await _serviceFactory.tableSchemaService.get(query.qtHash);
final qtData = await _serviceFactory.tableSchemaService.select(
  query.qtHash, ['.y', '.ri', '.ci'], 0, qtSchema.nRows);
final colSchema = await _serviceFactory.tableSchemaService.get(query.columnHash);
final factorNames = colSchema.columns.map((c) => c.name)
    .where((name) => !name.startsWith('.')).toList();
final colData = await _serviceFactory.tableSchemaService.select(
  query.columnHash, factorNames, 0, colSchema.nRows);
```

**AFTER**:

```dart
final ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);

final qtData  = await ctx.select(names: ['.y', '.ri', '.ci']);
final colData = await ctx.cselect();
final cnames  = await ctx.cnames;  // for discovering available column names
```

### Example 3: Document ID resolution (ps12_image_overview_flutter_operator)

**BEFORE** (complex multi-strategy resolver, ~100 lines):

```dart
// Strategy 1: Navigate task hierarchy manually
final task = await _serviceFactory.taskService.get(taskId);
CubeQueryTask? cubeTask;
if (task is RunWebAppTask) { /* ... navigate ... */ }
final query = cubeTask.query;
final columnSchema = await _serviceFactory.tableSchemaService.get(query.columnHash);
// Check for .documentId column manually...
final columnData = await _serviceFactory.tableSchemaService.select(
  query.columnHash, ['.documentId'], 0, 1);
```

**AFTER**:

```dart
final ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);

// The context handles all task navigation. Just fetch what you need:
final columnData = await ctx.cselect(names: ['.documentId'], limit: 1);
```

---

## Phase 2 API Reference — Task Lifecycle

### Logging

Send log messages to the Tercen UI via the task's event channel.

```dart
await ctx.log('Starting computation...');
await ctx.log('Processing row 42 of 100');
```

No-op when `task` is null (dev mode without a task) or when `channelId` is empty.

### Progress Reporting

Report progress with actual/total counts to the Tercen UI.

```dart
await ctx.progress('Loading data', actual: 0, total: 100);
// ... process ...
await ctx.progress('Computing results', actual: 50, total: 100);
await ctx.progress('Done', actual: 100, total: 100);
```

No-op when `task` is null or `channelId` is empty.

### Building Output Tables

#### Recommended: Static helper methods

Use the static helper methods to create columns with correct TSON binary types.
These handle everything automatically — dual-wiring (`column.values` +
`column.cValues`), column `type`, and `nRows`:

```dart
import 'package:sci_tercen_context/sci_tercen_context.dart';

final table = Table();
table.nRows = 100;

// Integer column (e.g. .ci, .ri indices)
// Sets: values=Int32List, cValues=I32Values, type='int32', nRows=len
table.columns.add(
  AbstractOperatorContext.makeInt32Column('.ci', ciList));

// Double column (e.g. computed values)
// Sets: values=Float64List, cValues=F64Values, type='double', nRows=len
table.columns.add(
  AbstractOperatorContext.makeFloat64Column('mean', meanValues));

// String column (e.g. labels)
// Sets: values=CStringList, cValues=StrValues, type='string', nRows=len
table.columns.add(
  AbstractOperatorContext.makeStringColumn('label', labels));
```

#### Manual column construction (also works)

If you build columns manually (without helpers), `save()` / `saveTable()` /
`saveTables()` will automatically normalize columns before TSON encoding.
The normalization handles three things:

1. **TSON binary types**: Sets `column.values` from `column.cValues` with the
   correct TypedData type (`Int32List`, `Float64List`, `CStringList`)
2. **Column type inference**: Sets `column.type` from cValues kind when empty
   (`I32Values` → `"int32"`, `F64Values` → `"double"`, `StrValues` → `"string"`)
3. **Row count inference**: Sets `column.nRows` from data length when 0, and
   `table.nRows` from the first column when 0

So this minimal approach works correctly:

```dart
final table = Table();
// table.nRows auto-inferred from first column

final col = Column();
col.name = '.ci';
// col.type auto-inferred as 'int32'
// col.nRows auto-inferred as 3
final vals = I32Values();
vals.values.addAll([0, 1, 2]);
col.cValues = vals;
table.columns.add(col);

await ctx.saveTable(table);
// After save: col.values is Int32List, col.type is 'int32',
// col.nRows is 3, table.nRows is 3
```

Explicitly set values are never overwritten — if you set `col.type = 'custom'`
or `col.nRows = 999`, normalization will leave those untouched.

#### Why this matters

Without normalization, two issues occur:

1. **TSON serialization failure**: The typed value containers (`I32Values`,
   `F64Values`, `StrValues`) use `ListChangedBase<T>` internally, which strips
   TypedData type information. The TSON binary encoder dispatches on Dart runtime
   type — it needs `Int32List` (not `List<int>`) to emit the correct binary marker.
   Without this, the server rejects the upload with "Tbl deser failed".

2. **"Factor not available" in Tercen pipeline**: `ColumnSchema` defaults `type`
   to `""` and `nRows` to `0`. Without these metadata fields, the Tercen pipeline
   can't register output columns as available factors in downstream steps.

### Saving Results

Save computed results back to Tercen. Handles TSON serialization, file upload,
and task lifecycle (create/update/run/waitDone) automatically.

| Method | Use case |
|--------|----------|
| `ctx.save(OperatorResult)` | Full control — save an OperatorResult with tables and/or join operators |
| `ctx.saveTable(Table)` | Save a single output table |
| `ctx.saveTables(List<Table>)` | Save multiple output tables |
| `ctx.saveRelation(List<JoinOperator>)` | Save relation metadata (join operators) |

```dart
// Save a single table
final outputTable = Table();
// ... populate columns ...
await ctx.saveTable(outputTable);

// Save multiple tables
await ctx.saveTables([table1, table2, table3]);

// Full OperatorResult with both tables and join operators
final result = OperatorResult();
result.tables.add(outputTable);
result.joinOperators.add(joinOp);
await ctx.save(result);

// Save relation metadata only
await ctx.saveRelation([joinOp1, joinOp2]);
```

**Production mode** (`OperatorContext`):
- If the task has no `fileResultId`: creates new file, links to task, runs task, waits for completion
- If the task already has a `fileResultId`: re-uploads to the existing file (no task re-run)

**Dev mode** (`OperatorContextDev`):
- If no task exists: creates a `ComputationTask`, uploads file, runs and waits
- If task already exists: updates the existing task with new file, runs and waits

Both modes throw `StateError` if the task finishes in `FailedState`.

### Requesting Compute Resources

Request CPU, RAM, or RAM-per-CPU from the worker service.

```dart
// Request 4 CPUs
final env = await ctx.requestResources(nCpus: 4);

// Request RAM
await ctx.requestResources(ram: '8G');

// Request multiple resources
await ctx.requestResources(nCpus: 2, ram: '4G', ramPerCpu: '2G');
```

Returns the list of `Pair` objects. Returns empty list when `task` is null.

### Complete Lifecycle Example

```dart
final ctx = await tercenCtx(serviceFactory: factory, taskId: taskId);

// Phase 1: Read data
await ctx.log('Loading data...');
final data = await ctx.select(names: ['.y', '.ci', '.ri']);
final colData = await ctx.cselect();
final threshold = await ctx.opDoubleValue('threshold', defaultValue: 0.5);

// Phase 2: Process and write back
await ctx.progress('Computing', actual: 0, total: 100);

// ... compute results ...

await ctx.progress('Saving', actual: 90, total: 100);
await ctx.saveTable(outputTable);
await ctx.log('Done');
```

---

## What's NOT covered yet (Phase 3+)

### Relation tree walking (Phase 3)

If you need to walk `CompositeRelation`/`SimpleRelation` trees to resolve data
sources across joins, this is not yet handled by the context. The context uses
query hashes directly (which works for the standard select/cselect/rselect
pattern).

### Streaming (Phase 4)

For very large datasets, streaming variants (`selectStream()`, etc.) will
provide `Stream<Table>` with configurable chunk sizes. Until then, use
`offset`/`limit` parameters on `select()` for manual pagination.

---

## Architecture Notes

- `AbstractOperatorContext` is the base class — all shared logic lives here
- `OperatorContext` (production) and `OperatorContextDev` (dev) are subclasses
- `tercenCtx()` is the factory function that picks the right subclass
- All properties are `Future`-based (async) because schemas are fetched lazily
- Schemas are cached after first access — repeated calls to `ctx.schema` don't
  re-fetch
- The context accepts `ServiceFactoryBase` (the abstract interface), not
  `ServiceFactory` (the concrete class with zone-local factory). This makes it
  testable with mocks.

### Package location in the monorepo

```
sci_tercen_client/              (git repo root)
├── sci_http_client/            (HTTP client)
├── sci_base/                   (base models: Table, Column, etc.)
├── sci_tercen_model/           (180+ Tercen model classes)
├── sci_tercen_client/          (low-level service clients)
└── sci_tercen_context/    <─── NEW PACKAGE (this one)
    ├── lib/
    │   ├── sci_tercen_context.dart           # single import for everything
    │   └── src/
    │       ├── context/
    │       │   ├── abstract_operator_context.dart
    │       │   ├── operator_context.dart          # production (taskId)
    │       │   └── operator_context_dev.dart       # dev (workflowId + stepId)
    │       ├── factory/
    │       │   └── tercen_ctx.dart                 # tercenCtx() factory
    │       └── helpers/
    │           ├── async_lazy.dart
    │           ├── column_filter.dart
    │           └── operator_property.dart
    └── test/   (86 passing tests)
```

### Dependency chain

```
sci_http_client → sci_base → sci_tercen_model → sci_tercen_client → sci_tercen_context
```

The context package depends on `sci_tercen_client` and transitively gets access
to all model classes and service interfaces.
