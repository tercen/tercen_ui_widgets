---
name: phase-3-tercen-integration
description: Replace mock services with real Tercen data services in a Phase 2 mock app. Handles SDK setup, context creation, data flows (projections, file downloads, write-back), build, and deploy. Use after a mock app is approved and a real Tercen taskId is available.
argument-hint: "[path to mock app]"
disable-model-invocation: true
---

**This file is READ-ONLY during app builds. Do NOT modify it. If you encounter a gap, error, workaround, or unexpected behaviour, append a one-line note to `_issues/session-log.md` and continue working. Do not stop to discuss the issue.**

Replace mock services with real Tercen data services. The Phase 2 mock app is your starting point.

**SDK**: sci_tercen_context (context API) + sci_tercen_client (low-level services) — always use the latest version from <https://github.com/tercen/sci_tercen_client>

## Additional resources

- For the complete sci_tercen_context API reference, see [api-reference.md](api-reference.md)

---

## Rules — read before writing any code

1. **No fallback chains in data access.** The real service has ONE fallback: Tercen fails entirely -> fall back to mock. Do NOT add fallback strategies within data access itself. Flow A and Flow B are different access patterns for different data, not fallback alternatives.
2. **Use `sci_tercen_context` for all data access.** Do NOT manually navigate task hierarchies (`RunWebAppTask` -> `CubeQueryTask`) or call `tableSchemaService.select()` directly. The context handles task navigation, schema resolution, system column filtering, and data fetching automatically.
3. **Always use explicit GetIt type parameters.** `getIt.registerSingleton<ServiceFactory>(factory)` not `getIt.registerSingleton(factory)`. Omitting the type defaults to `Object` and causes runtime type mismatches.
4. **Never use `dart:html` or `http` package for Tercen API calls.** Always use `sci_tercen_client` services — they handle auth and CORS.
5. **When data access fails: STOP.** Do not add workarounds. Run the diagnostic report (see bottom of this skill), present results to the user. The fix may require workflow reconfiguration, a different flow choice, or an SDK enhancement — not more code.

---

## Inputs

1. Working mock app (Phase 2 output)
2. Functional spec Section 2.2 (Data Source) — determines Flow A, B, or C
3. A real Tercen taskId for testing (user provides)

---

## Choose data flow

Read the functional spec Section 2.2.

| Flow | When | Method |
| ---- | ---- | ------ |
| A | App displays computed values, charts, grids from Tercen projections | `ctx.select()` + `ctx.cselect()` + `ctx.rselect()` |
| B | App downloads files (images, ZIPs, documents) referenced by `.documentId` | `ctx.cselect(names: ['.documentId'])` -> `fileService.download()` |
| C | App needs both | Flow A for data + Flow B for files, in separate resolver classes |

---

## Step 1: Update dependencies

In `pubspec.yaml`, add `sci_tercen_context` and update `sci_tercen_client` to the same version:

```yaml
dependencies:
  # Tercen context API — handles task navigation, schema resolution, data access
  sci_tercen_context:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: 1.12.0  # Update to latest version
      path: sci_tercen_context
  # Tercen client — needed for createServiceFactoryForWebApp()
  sci_tercen_client:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: 1.12.0  # Must match sci_tercen_context version
      path: sci_tercen_client
```

The single import `package:sci_tercen_context/sci_tercen_context.dart` gives you everything — all Tercen model classes (CubeQuery, Schema, Table, Column, etc.), `ServiceFactoryBase`, the context classes, and `OperatorContext.create()`.

---

## Step 2: main.dart

```dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: false);

  ServiceFactory? factory;
  String? taskId;

  if (!useMocks) {
    try {
      taskId = Uri.base.queryParameters['taskId'];
      if (taskId == null || taskId.isEmpty) {
        runApp(_buildErrorApp('Missing taskId parameter'));
        return;
      }
      factory = await createServiceFactoryForWebApp();
    } catch (e) {
      print('Tercen init failed: $e');
    }
  }

  setupServiceLocator(
    useMocks: factory == null,
    factory: factory,
    taskId: taskId,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(YourApp(prefs: prefs));
}
```

`createServiceFactoryForWebApp()` is lightweight (sets up HTTP client). The heavy work — `OperatorContext.create()` which fetches the task and resolves `RunWebAppTask` -> `CubeQueryTask` — happens lazily inside the data service when `loadData()` is first called. Use `print()` (not `debugPrint()`) for WASM console visibility.

---

## Step 3: service_locator.dart

```dart
import 'package:sci_tercen_client/sci_client_service_factory.dart';

void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? factory,
  String? taskId,
}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(() => MockDataService());
  } else {
    serviceLocator.registerLazySingleton<DataService>(
      () => TercenDataService(factory!, taskId!),
    );
  }
}
```

For multiple services that need Tercen access, pass the same `factory` and `taskId` to each. Each service creates its own context lazily.

---

## Step 4A: Flow A — cross-tab projections

### Read data

```dart
import 'package:sci_tercen_context/sci_tercen_context.dart';

final qtData  = await ctx.select(names: ['.y', '.ci', '.ri']);  // add '.x' if needed
final colData = await ctx.cselect();   // auto-filters system columns (int64/uint64)
final rowData = await ctx.rselect();   // auto-filters system columns
```

When `names` is empty, `cselect()` and `rselect()` return all non-system columns automatically. When `names` is explicit, exactly those columns are returned.

### Discover available columns

```dart
final columnFactors = await ctx.cnames;  // e.g. ['Image', 'spotRow', '.ci']
final rowFactors    = await ctx.rnames;   // e.g. ['variable', '.ri']
final mainCols      = await ctx.names;    // e.g. ['.y', '.ci', '.ri', '.x']
```

### Three-table join

The three tables are indexed by `.ci` and `.ri`:

| Table | Contains | Index |
| ----- | -------- | ----- |
| `ctx.select()` (qtHash) | `.y`, `.ci`, `.ri` projection data | — |
| `ctx.cselect()` (columnHash) | Per-column metadata (labels, attributes) | Indexed by `.ci` |
| `ctx.rselect()` (rowHash) | Per-row metadata (variable names, factors) | Indexed by `.ri` |

```dart
// Extract arrays from Table objects
final qtTable  = await ctx.select(names: ['.y', '.ci', '.ri']);
final colTable = await ctx.cselect();
final rowTable = await ctx.rselect();

// Build index maps from column/row tables
Map<int, Map<String, dynamic>> colMetadata = _buildIndexMap(colTable);
Map<int, Map<String, dynamic>> rowMetadata = _buildIndexMap(rowTable);

// Join
List<double> yValues = _getDoubleColumn(qtTable, '.y');
List<int> ciValues = _getIntColumn(qtTable, '.ci');
List<int> riValues = _getIntColumn(qtTable, '.ri');

for (int i = 0; i < yValues.length; i++) {
  final y  = yValues[i];
  final ci = ciValues[i];
  final ri = riValues[i];
  final colMeta = colMetadata[ci]; // e.g. {Image: "img1", spotRow: 3}
  final rowMeta = rowMetadata[ri]; // e.g. {variable: "gridX"}
  // Build your domain model
}
```

Helper to build index map from a Table:

```dart
Map<int, Map<String, dynamic>> _buildIndexMap(Table table) {
  final result = <int, Map<String, dynamic>>{};
  for (final col in table.columns) {
    final values = col.values as List?;
    if (values == null) continue;
    for (int i = 0; i < values.length; i++) {
      result.putIfAbsent(i, () => {});
      result[i]![col.name] = values[i];
    }
  }
  return result;
}
```

Column names may have namespace prefixes (e.g., `ds1.Image`). Strip with: `name.contains('.') ? name.split('.').last : name`

### Pagination (large datasets)

```dart
final page = await ctx.select(names: ['.y'], offset: 0, limit: 1000);
```

### Operator properties

Read user-configured settings from the Tercen UI:

```dart
final threshold = await ctx.opDoubleValue('threshold', defaultValue: 0.5);
final method    = await ctx.opStringValue('method', defaultValue: 'mean');
final showGrid  = await ctx.opBoolValue('showGrid', defaultValue: true);
final maxIter   = await ctx.opIntValue('maxIterations', defaultValue: 100);
```

### Visual metadata

```dart
final colors     = await ctx.colors;       // color factor names
final labels     = await ctx.labels;       // label factor names
final chartTypes = await ctx.chartTypes;   // chart type per axis query
final isPairwise = await ctx.isPairwise;   // scatter/pairwise mode?
```

---

## Step 4B: Flow B — file downloads

### Get document IDs

Try `ctx.cselect()` first — `.documentId` is often available in the column schema:

```dart
final colData = await ctx.cselect(names: ['.documentId']);
final docIds = (colData.columns.first.values as List)
    .map((v) => v.toString())
    .toSet()
    .toList();
```

If `.documentId` is not in the column schema (cselect throws or returns empty), navigate the relation tree as a fallback:

```dart
String? _findDocumentId(CubeQuery query) {
  final queryJson = query.toJson();
  var rel = queryJson['relation'] as Map?;

  for (int depth = 0; rel != null && depth < 20; depth++) {
    final kind = rel!['kind'] as String?;

    if (kind == 'InMemoryRelation' && rel['inMemoryTable'] != null) {
      for (final col in rel['inMemoryTable']['columns'] as List) {
        final name = col['name'] as String?;
        if (name == '.documentId' || (name != null && name.endsWith('..documentId'))) {
          return (col['values'] as List).first.toString();
        }
      }
      break;
    }

    if (rel['relation'] != null) {
      rel = rel['relation'] as Map?;
    } else if (kind == 'CompositeRelation' && rel['mainRelation'] != null) {
      rel = rel['mainRelation'] as Map?;
    } else {
      break;
    }
  }
  return null;
}

// Usage:
final query = await ctx.query;
final docId = _findDocumentId(query);
```

### Download files

Access file services through the context's service factory:

```dart
final stream = ctx.serviceFactory.fileService.download(documentId);
final chunks = <List<int>>[];
await for (final chunk in stream) { chunks.add(chunk); }
final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
```

ZIP files:

```dart
final entries = await ctx.serviceFactory.fileService.listZipContents(documentId);
final entryStream = ctx.serviceFactory.fileService.downloadZipEntry(documentId, entryPath);
```

Limit concurrent downloads to 3.

---

## Step 5: Real service

```dart
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';

class TercenDataService implements DataService {
  final ServiceFactoryBase _factory;
  final String _taskId;
  final MockDataService _mockService = MockDataService();
  AbstractOperatorContext? _ctx;

  TercenDataService(this._factory, this._taskId);

  Future<AbstractOperatorContext> _getContext() async {
    if (_ctx != null) return _ctx!;
    _ctx = await OperatorContext.create(serviceFactory: _factory, taskId: _taskId);
    return _ctx!;
  }

  @override
  Future<List<YourModel>> loadData() async {
    try {
      final ctx = await _getContext();
      final qtData  = await ctx.select(names: ['.y', '.ci', '.ri']);
      final colData = await ctx.cselect();
      final rowData = await ctx.rselect();

      final models = _joinAndBuild(qtData, colData, rowData);
      if (models.isEmpty) return _mockService.loadData();
      return models;
    } catch (e) {
      print('Tercen error: $e');
      await _printDiagnosticReport();
      return _mockService.loadData();
    }
  }
}
```

---

## Step 6: Saving results (Type 2 apps)

For operators that write data back to Tercen, use the context's save methods and column helpers.

### Build output tables

Use the static helpers to create columns with correct TSON binary types:

```dart
import 'package:sci_tercen_context/sci_tercen_context.dart';

final table = Table();
table.nRows = results.length;

// Integer column (e.g. .ci indices) — Int32List + I32Values + type='int32'
table.columns.add(
  AbstractOperatorContext.makeInt32Column('.ci', ciList));

// Double column (e.g. computed values) — Float64List + F64Values + type='double'
table.columns.add(
  AbstractOperatorContext.makeFloat64Column('mean', meanValues));

// String column (e.g. labels) — CStringList + StrValues + type='string'
table.columns.add(
  AbstractOperatorContext.makeStringColumn('label', labels));
```

### Add namespace prefix to output columns

```dart
final nsMap = await ctx.addNamespace(['gridX', 'gridY', '.ci']);
// {'gridX': 'ns.gridX', 'gridY': 'ns.gridY', '.ci': '.ci'}
// Use nsMap values as column names in output tables
```

### Save

```dart
// Single table
await ctx.saveTable(outputTable);

// Multiple tables
await ctx.saveTables([table1, table2]);

// Full OperatorResult with join operators
final result = OperatorResult();
result.tables.add(outputTable);
result.joinOperators.add(joinOp);
await ctx.save(result);
```

`save()` automatically normalizes columns (TSON binary types, column type inference, row count inference) before uploading. It handles the full task lifecycle: file upload, task update, run, and wait-for-done.

### Lifecycle logging

```dart
await ctx.log('Starting computation...');
await ctx.progress('Computing', actual: 0, total: 100);
// ... process ...
await ctx.progress('Saving', actual: 90, total: 100);
await ctx.saveTable(outputTable);
await ctx.log('Done');
```

---

## Step 7: Build and deploy

```bash
flutter build web --wasm
git add build/web/ && git commit -m "Update web build" && git push
```

The skeleton `.gitignore` already preserves `build/web/`.

### Required files

index.html line 17 must stay commented: `<!--<base href="$FLUTTER_BASE_HREF"> -->`

operator.json must have:

```json
{"name": "Your Operator", "isWebApp": true, "isViewOnly": false, "entryType": "app", "serve": "build/web", "urls": ["https://github.com/tercen/your-repo"]}
```

> `isViewOnly: false` and `entryType: "app"` are **required** for operators that save results (Type 2 apps). Without them, Tercen creates a CubeQueryTask instead of a RunWebAppTask, and save() will appear to succeed but produce no visible results.

Hot reload is broken for Tercen web apps. Always stop and restart with `flutter run -d chrome --web-port 8080`.

---

## Diagnostic report

Add this to every real service. Call it when data loading fails. Present the output to the user — do NOT try to fix the problem by adding code.

```dart
Future<void> _printDiagnosticReport() async {
  final q = await _ctx.query;
  print('=== TERCEN DIAGNOSTIC REPORT ===');
  print('Task: ${_ctx.taskId} (${_ctx.task?.runtimeType})');

  for (final entry in {'schema (qtHash)': _ctx.schema, 'cschema (columnHash)': _ctx.cschema, 'rschema (rowHash)': _ctx.rschema}.entries) {
    print('\n--- ${entry.key} ---');
    try {
      final s = await entry.value;
      print('Rows: ${s.nRows}, Columns: ${s.columns.map((c) => "${c.name}:${c.type}").join(', ')}');
    } catch (e) { print('ERROR: $e'); }
  }

  // Operator properties
  try {
    final ns = await _ctx.namespace;
    print('\nNamespace: $ns');
  } catch (e) { print('\nNamespace ERROR: $e'); }

  print('=== END REPORT ===');
}
```

---

## Checklist

- [ ] `sci_tercen_context` and `sci_tercen_client` in pubspec.yaml at matching versions
- [ ] `createServiceFactoryForWebApp()` in main.dart with try/catch
- [ ] taskId from `Uri.base.queryParameters['taskId']`
- [ ] Context created lazily via `OperatorContext.create()` inside data service (NOT in main.dart)
- [ ] `ServiceFactory` and `taskId` passed from main.dart through service locator to data service
- [ ] Data flow matches functional spec Section 2.2
- [ ] Real service uses `ctx.select()` / `ctx.cselect()` / `ctx.rselect()` — NOT manual tableSchemaService calls
- [ ] Real service falls back to mock on error
- [ ] Diagnostic report function included in every real service
- [ ] `print()` used instead of `debugPrint()` (required for WASM console output)
- [ ] `flutter build web --wasm` succeeds
- [ ] `build/web/` committed
- [ ] operator.json has `isViewOnly: false` and `entryType: "app"` (required for Type 2 save)
- [ ] index.html line 17 commented
- [ ] No `dart:html` or `http` package API calls
- [ ] No manual task navigation code (context handles it)
- [ ] Mock mode works (`--dart-define=USE_MOCKS=true`)

---

## Files created/modified

| File | Action |
| ---- | ------ |
| `pubspec.yaml` | Add `sci_tercen_context` dependency, verify `sci_tercen_client` version matches |
| `lib/main.dart` | Modify — create ServiceFactory, pass factory + taskId to service locator |
| `lib/di/service_locator.dart` | Modify — register context + real data service |
| `lib/implementations/services/tercen_*_service.dart` | Create — uses context for data access |
| `lib/utils/*_resolver.dart` | Create (if Flow B needs relation tree walking) |
