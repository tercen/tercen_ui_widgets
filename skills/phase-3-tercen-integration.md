# Phase 3: Tercen Integration

**This file is READ-ONLY during app builds. Do NOT modify it. If you encounter a gap or error, note it in the app's `_local/skill-feedback.md` and continue.**

Replace mock services with real Tercen data services. The Phase 2 mock app is your starting point.

**SDK**: sci_tercen_client — always use the latest version from <https://github.com/tercen/sci_tercen_client>

---

## Rules — read before writing any code

1. **No fallback chains in data access.** The real service has ONE fallback: Tercen fails entirely → fall back to mock. Do NOT add fallback strategies within data access itself. Flow A and Flow B are different access patterns for different data, not fallback alternatives.
2. **Never navigate the JSON relation tree for tabular data.** The relation tree contains `SimpleRelation` nodes — references to stored tables, not embedded data. Use `tableSchemaService.select()` with the appropriate hash (qtHash, columnHash, rowHash). The ONLY use of JSON relation tree navigation is to find `.documentId` for file downloads (Flow B).
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

| Flow | When | Source |
| ---- | ---- | ------ |
| A | App displays computed values, charts, grids of data from Tercen projections | `query.qtHash` + `query.columnHash` + `query.rowHash` via `tableSchemaService.select()` |
| B | App downloads files (images, ZIPs, documents) referenced by `.documentId` | `query.relation` JSON tree → InMemoryTable → `.documentId` → `fileService.download()` |
| C | App needs both | Flow A for data + Flow B for files, in separate resolver classes |

---

## Step 1: main.dart

```dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: false);

  ServiceFactory? tercenFactory;
  String? taskId;

  if (!useMocks) {
    try {
      tercenFactory = await createServiceFactoryForWebApp();
      taskId = Uri.base.queryParameters['taskId'];

      if (taskId == null || taskId.isEmpty) {
        runApp(_buildErrorApp('Missing taskId parameter'));
        return;
      }
    } catch (e) {
      debugPrint('Tercen init failed: $e');
    }
  }

  setupServiceLocator(
    useMocks: tercenFactory == null,
    tercenFactory: tercenFactory,
    taskId: taskId,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(YourApp(prefs: prefs));
}
```

---

## Step 2: service_locator.dart

```dart
import 'package:sci_tercen_client/sci_client_service_factory.dart';

void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? tercenFactory,
  String? taskId,
}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(() => MockDataService());
  } else {
    serviceLocator.registerSingleton<ServiceFactory>(tercenFactory!);
    serviceLocator.registerLazySingleton<DataService>(
      () => TercenDataService(tercenFactory, taskId: taskId),
    );
  }
}
```

For multiple services, register each with the same factory.

---

## Step 3: Task navigation

Put in `lib/utils/` or inline in your resolver.

```dart
import 'package:sci_tercen_client/sci_client.dart' show CubeQueryTask, RunWebAppTask;
import 'package:sci_tercen_client/sci_client_service_factory.dart' show ServiceFactory;

Future<CubeQueryTask> navigateToCubeQueryTask(
  ServiceFactory factory,
  String taskId,
) async {
  final task = await factory.taskService.get(taskId);
  if (task is CubeQueryTask) return task;
  if (task is RunWebAppTask) {
    if (task.cubeQueryTaskId.isEmpty) {
      throw StateError('RunWebAppTask has empty cubeQueryTaskId');
    }
    final cubeTask = await factory.taskService.get(task.cubeQueryTaskId);
    if (cubeTask is! CubeQueryTask) {
      throw StateError('Expected CubeQueryTask, got ${cubeTask.runtimeType}');
    }
    return cubeTask;
  }
  throw StateError('Unsupported task type: ${task.runtimeType}');
}
```

---

## Step 4A: Flow A — cross-tab projections

### Three hashes

| Hash | Contains | Index |
| ---- | -------- | ----- |
| `query.qtHash` | `.x`, `.y`, `.ri`, `.ci` projection data | — |
| `query.columnHash` | Per-column metadata (group labels, upstream operator attributes) | Indexed by `.ci` |
| `query.rowHash` | Per-row metadata (variable names, gene names) | Indexed by `.ri` |

### Read from a hash

This pattern works for all three hashes:

```dart
Future<Map<int, Map<String, dynamic>>> _readFactorTable(
  ServiceFactory factory,
  String hash,
) async {
  if (hash.isEmpty) return {};
  final schema = await factory.tableSchemaService.get(hash);
  final names = schema.columns
      .map((c) => c.name)
      .where((n) => !n.startsWith('.'))
      .toList();
  if (names.isEmpty || schema.nRows == 0) return {};

  final table = await factory.tableSchemaService.select(
    hash, names, 0, schema.nRows,
  );

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

### Read projections from qtHash

```dart
final query = cubeTask.query;
final qtSchema = await factory.tableSchemaService.get(query.qtHash);
final nRows = qtSchema.nRows;

final qtData = await factory.tableSchemaService.select(
  query.qtHash, ['.y', '.ri', '.ci'], 0, nRows,  // add '.x' if needed
);

List ciValues = [], riValues = [];
List<double> yValues = [];
for (final col in qtData.columns) {
  switch (col.name) {
    case '.y': yValues = (col.values as List).map((v) => (v as num).toDouble()).toList();
    case '.ri': riValues = col.values as List;
    case '.ci': ciValues = col.values as List;
  }
}
```

### Three-table join

Combine projections with column and row metadata:

```dart
final colMetadata = await _readFactorTable(factory, query.columnHash);
final rowMetadata = await _readFactorTable(factory, query.rowHash);

for (int i = 0; i < nRows; i++) {
  final ci = (ciValues[i] as num).toInt();
  final ri = (riValues[i] as num).toInt();
  final y = yValues[i];
  final colMeta = colMetadata[ci]; // e.g. {Image: "img1", spotRow: 3}
  final rowMeta = rowMetadata[ri]; // e.g. {variable: "gridX"}
  // Build your domain model
}
```

---

## Step 4B: Flow B — file downloads

`.documentId` is filtered from the schema API. Extract it from the relation tree JSON.

### Navigate relation tree

```dart
String? _findDocumentId(CubeQueryTask cubeTask) {
  final taskJson = cubeTask.toJson();
  var rel = taskJson['query']['relation'] as Map?;

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
  return null; // If null, try recursive search through joinOperators[].rightRelation
}
```

### SDK helper for alias resolution

```dart
import 'package:sci_tercen_client/sci_client.dart' show Relation;
final actualDocId = cubeTask.query.relation.findDocumentId(aliasValue);
```

### Download files

```dart
final stream = factory.fileService.download(documentId);
final chunks = <List<int>>[];
await for (final chunk in stream) { chunks.add(chunk); }
final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
```

ZIP files:

```dart
final entries = await factory.fileService.listZipContents(documentId);
final entryStream = factory.fileService.downloadZipEntry(documentId, entryPath);
```

Limit concurrent downloads to 3.

---

## Step 5: Real service

```dart
class TercenDataService implements DataService {
  final ServiceFactory _factory;
  final String? _taskId;
  final MockDataService _mockService;

  TercenDataService(this._factory, {String? taskId})
      : _taskId = taskId, _mockService = MockDataService();

  @override
  Future<List<YourModel>> loadData() async {
    try {
      if (_taskId == null || _taskId!.isEmpty) return _mockService.loadData();
      final cubeTask = await navigateToCubeQueryTask(_factory, _taskId!);
      final data = await _extractData(cubeTask);
      if (data.isEmpty) return _mockService.loadData();
      return data;
    } catch (e) {
      debugPrint('Tercen error: $e');
      await _printDiagnosticReport(_factory, cubeTask);
      return _mockService.loadData();
    }
  }
}
```

---

## Step 6: Build and deploy

```bash
flutter build web --wasm
git add build/web/ && git commit -m "Update web build" && git push
```

The skeleton `.gitignore` already preserves `build/web/`.

### Required files

index.html line 17 must stay commented: `<!--<base href="$FLUTTER_BASE_HREF"> -->`

operator.json must have:

```json
{"name": "Your Operator", "isWebApp": true, "serve": "build/web", "urls": ["https://github.com/tercen/your-repo"]}
```

Hot reload is broken for Tercen web apps. Always stop and restart with `flutter run -d chrome --web-port 8080`.

---

## Diagnostic report

Add this to every real service. Call it when data loading fails. Present the output to the user — do NOT try to fix the problem by adding code.

```dart
Future<void> _printDiagnosticReport(ServiceFactory factory, CubeQueryTask cubeTask) async {
  final q = cubeTask.query;
  print('=== TERCEN DIAGNOSTIC REPORT ===');
  print('Task: ${cubeTask.id} (${cubeTask.runtimeType})');
  for (final entry in {'qtHash': q.qtHash, 'columnHash': q.columnHash, 'rowHash': q.rowHash}.entries) {
    print('\n--- ${entry.key}: ${entry.value} ---');
    if (entry.value.isNotEmpty) {
      try {
        final s = await factory.tableSchemaService.get(entry.value);
        print('Rows: ${s.nRows}, Columns: ${s.columns.map((c) => c.name).join(', ')}');
      } catch (e) { print('ERROR: $e'); }
    } else { print('EMPTY'); }
  }
  print('\n--- relation tree ---');
  _printRel(cubeTask.toJson()['query']?['relation'] as Map?, 0, 3);
  print('=== END REPORT ===');
}

void _printRel(Map? r, int d, int max) {
  if (r == null || d >= max) return;
  final pad = '  ' * d;
  print('$pad${r['kind']}');
  if (r['kind'] == 'CompositeRelation') {
    _printRel(r['mainRelation'] as Map?, d + 1, max);
    for (final j in (r['joinOperators'] as List? ?? [])) {
      _printRel((j as Map)['rightRelation'] as Map?, d + 1, max);
    }
  } else if (r['relation'] != null) { _printRel(r['relation'] as Map?, d + 1, max); }
}
```

### Known patterns

| Pattern | Source | Method |
| ------- | ------ | ------ |
| Projections (.x, .y, .ri, .ci) | `query.qtHash` | `tableSchemaService.select()` |
| Column metadata | `query.columnHash` | `tableSchemaService.select()` |
| Row metadata | `query.rowHash` | `tableSchemaService.select()` |
| Three-table join | qtHash + columnHash + rowHash | Join by `.ci` and `.ri` |
| File document IDs | `query.relation` JSON | Navigate to InMemoryTable → `.documentId` |

If data doesn't match these patterns, report it. `SimpleRelation` in the tree is normal — it's a reference, not data.

---

## API reference

| Service | Method | Returns |
| ------- | ------ | ------- |
| `taskService.get(id)` | Fetch task | `Task` → cast to `RunWebAppTask` or `CubeQueryTask` |
| `tableSchemaService.get(hash)` | Schema | `TableSchema` (.columns, .nRows) |
| `tableSchemaService.select(hash, cols, offset, limit)` | Column data | `InMemoryTable` (.columns[].values) |
| `fileService.download(id)` | File bytes | `Stream<List<int>>` |
| `fileService.listZipContents(id)` | ZIP listing | `List<ZipEntry>` |
| `fileService.downloadZipEntry(id, path)` | ZIP entry | `Stream<List<int>>` |

| `query` field | Contains |
| ------------- | -------- |
| `qtHash` | Cross-tab output table |
| `columnHash` | Column factor table (indexed by .ci) |
| `rowHash` | Row factor table (indexed by .ri) |
| `relation` | Input data relation tree |

| Constant | Value |
| -------- | ----- |
| `Relation.DocumentId` | `'.documentId'` |
| `Relation.DocumentIdAlias` | `'documentId'` |
| `relation.findDocumentId(alias)` | Resolves alias → .documentId |

---

## Checklist

- [ ] `createServiceFactoryForWebApp()` in main.dart with try/catch
- [ ] taskId from `Uri.base.queryParameters['taskId']`
- [ ] `<ServiceFactory>` explicit type on GetIt registration
- [ ] Task navigation handles RunWebAppTask and CubeQueryTask
- [ ] Data flow matches functional spec Section 2.2
- [ ] Real service falls back to mock on error
- [ ] Diagnostic report function included in every real service
- [ ] `flutter build web --wasm` succeeds
- [ ] `build/web/` committed
- [ ] operator.json correct
- [ ] index.html line 17 commented
- [ ] No `dart:html` or `http` package API calls
- [ ] Mock mode works (`--dart-define=USE_MOCKS=true`)

---

## Files created/modified

| File | Action |
| ---- | ------ |
| `lib/implementations/services/tercen_*_service.dart` | Create |
| `lib/utils/*_resolver.dart` | Create |
| `lib/di/service_locator.dart` | Modify |
| `lib/main.dart` | Modify |
| `pubspec.yaml` | Verify SDK ref is latest |
