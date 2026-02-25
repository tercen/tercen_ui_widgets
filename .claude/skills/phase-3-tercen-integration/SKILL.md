---
name: phase-3-tercen-integration
description: Replace mock services with real Tercen data services in a Phase 2 mock app. Handles SDK setup, context creation, data flows (projections, file downloads, write-back), build, and deploy. Use after a mock app is approved and a real Tercen taskId is available.
argument-hint: "[path to mock app]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Replace mock services with real Tercen data services. Phase 2 mock app is the starting point.

**SDK**: `sci_tercen_context` (context API) + `sci_tercen_client` (low-level) — always latest from <https://github.com/tercen/sci_tercen_client>. API reference: [api-reference.md](api-reference.md).

---

## Rules — read before writing any code

1. **No mock fallback in real services.** When Tercen data access fails, rethrow the error and let the UI show an error state. Do NOT silently return mock data — it hides real problems. Use the `USE_MOCKS` flag in `main.dart` for local development only. Flow A and Flow B are different access patterns for different data, not fallback alternatives.
2. **Use `sci_tercen_context` for all data access.** Do NOT manually navigate task hierarchies (`RunWebAppTask` -> `CubeQueryTask`) or call `tableSchemaService.select()` directly. The context handles task navigation, schema resolution, system column filtering, and data fetching automatically.
3. **Always use explicit GetIt type parameters.** `getIt.registerSingleton<ServiceFactory>(factory)` not `getIt.registerSingleton(factory)`. Omitting the type defaults to `Object` and causes runtime type mismatches.
4. **Never use `dart:html` or `http` package for Tercen API calls.** Always use `sci_tercen_client` services — they handle auth and CORS.
5. **When data access fails: STOP.** Do not add workarounds. Run the diagnostic report (see bottom of this skill), present results to the user. The fix may require workflow reconfiguration, a different flow choice, or an SDK enhancement — not more code.

---

## Inputs

1. Working mock app (Phase 2 output)
2. Functional spec Section 2.2 (Data Source) — determines Flow A, B, C, or D
3. A real Tercen taskId (Flows A/B/C) or projectId (Flow D) for testing (user provides)

---

## Choose data flow

Read the functional spec Section 2.2.

| Flow | When | Method |
| ---- | ---- | ------ |
| A | App displays computed values, charts, grids from Tercen projections | `ctx.select()` + `ctx.cselect()` + `ctx.rselect()` |
| B | App downloads files (images, ZIPs, documents) referenced by `.documentId` | `ctx.cselect(names: ['.documentId'])` -> `fileService.download()` |
| C | App needs both | Flow A for data + Flow B for files, in separate resolver classes |
| D | App browses/navigates Tercen objects (projects, workflows, steps, folders, documents) | Entity services (`projectService`, `workflowService`, `folderService`, etc.) with `startKey`/`endKey` range queries. No CubeQueryTask — uses `projectId` instead of `taskId`. |

---

## Step 1: Update dependencies

In `pubspec.yaml`, add `sci_tercen_context` and update `sci_tercen_client`. Always use the latest version from <https://github.com/tercen/sci_tercen_client> — check the repo's tags for the most recent release. Both packages must use the same `ref`:

```yaml
dependencies:
  # Tercen context API — handles task navigation, schema resolution, data access
  sci_tercen_context:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: <latest-version>  # e.g. 1.13.0 — check repo tags
      path: sci_tercen_context
  # Tercen client — needed for createServiceFactoryForWebApp()
  sci_tercen_client:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: <latest-version>  # Must match sci_tercen_context ref
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

`createServiceFactoryForWebApp()` is lightweight. `OperatorContext.create()` (heavy) happens lazily inside the data service. Use `print()` not `debugPrint()` for WASM console.

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

Empty `names` = all non-system columns. Explicit `names` = exactly those columns.

### Discover available columns

```dart
final columnFactors = await ctx.cnames;  // e.g. ['Image', 'spotRow', '.ci']
final rowFactors    = await ctx.rnames;   // e.g. ['variable', '.ri']
final mainCols      = await ctx.names;    // e.g. ['.y', '.ci', '.ri', '.x']
```

### Three-table join

Three tables indexed by `.ci`/`.ri`: `select()` = projection data, `cselect()` = per-column metadata (by `.ci`), `rselect()` = per-row metadata (by `.ri`).

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

## Step 4D: Flow D — entity navigation

Flow D: browse/navigate Tercen objects. Uses `projectId`/`teamId` (not `taskId`), entity services directly.

### App lifecycle

Apps run as iframes inside an orchestrator. Orchestrator reads URL params/`--dart-define`, passes context via `postMessage`.

Lifecycle: orchestrator loads iframe → app waits → orchestrator sends `init-context` (token, teamId, projectId) → app creates factory → registers services → sends `app-ready` back.

Dev: build sub-apps, run orchestrator with `--dart-define` flags.

```bash
# Build a sub-app
cd apps/project_nav && flutter build web --release

# Run orchestrator (which loads the built sub-apps)
cd apps/orchestrator
flutter run -d chrome --web-port 8080 \
  --dart-define=TERCEN_TOKEN=xxx \
  --dart-define=TEAM_ID=thiago_library \
  --dart-define=PROJECT_ID=abc123
```

**Mock mode:** `--dart-define=USE_MOCKS=true` on the sub-app build skips the postMessage wait and uses mock data directly.

### postMessage protocol

Envelope: small JSON, one `type`, flat `payload`:

```json
{"type": "init-context", "source": "orchestrator", "target": "project-nav",
 "payload": {"token": "xxx", "teamId": "thiago_library", "projectId": "abc123"}}
```

```json
{"type": "app-ready", "source": "project-nav", "target": "orchestrator",
 "payload": {}}
```

```json
{"type": "step-selected", "source": "project-nav", "target": "*",
 "payload": {"projectId": "abc123", "workflowId": "wf1", "stepId": "s1"}}
```

**Envelope shape:**

| Field | Type | Description |
| ----- | ---- | ----------- |
| `type` | `String` | Message kind — the only field receivers switch on |
| `source` | `String` | Sender app ID (e.g., `"orchestrator"`, `"project-nav"`) |
| `target` | `String` | Receiver app ID, or `"*"` for broadcast |
| `payload` | `Map` | Flat key/value data specific to the message type |

### Listening for messages (receive)

```dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:convert';

void _listenForMessages(void Function(String type, Map<String, dynamic> payload) onMessage) {
  web.window.addEventListener('message', (web.Event event) {
    final msgEvent = event as web.MessageEvent;
    final data = msgEvent.data;
    if (data == null) return;

    // Convert JS object to Dart map
    final jsonStr = web.window['JSON'].callMethod('stringify'.toJS, data) as JSString;
    final map = json.decode(jsonStr.toDart) as Map<String, dynamic>;

    final type = map['type'] as String?;
    final payload = map['payload'] as Map<String, dynamic>? ?? {};
    if (type != null) {
      onMessage(type, payload);
    }
  }.toJS);
}
```

### Sending messages (emit)

```dart
void _postToOrchestrator(String type, String sourceAppId, Map<String, dynamic> payload, {String target = 'orchestrator'}) {
  final message = {
    'type': type,
    'source': sourceAppId,
    'target': target,
    'payload': payload,
  };
  web.window.parent?.postMessage(message.jsify(), '*'.toJS);
}
```

### main.dart for Flow D

```dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: false);

  if (useMocks) {
    setupServiceLocator(useMocks: true);
    final prefs = await SharedPreferences.getInstance();
    runApp(YourApp(prefs: prefs));
    return;
  }

  // Wait for init-context from orchestrator
  _listenForMessages((type, payload) async {
    if (type == 'init-context') {
      try {
        final token = payload['token'] as String;
        final teamId = payload['teamId'] as String;
        final projectId = payload['projectId'] as String?;

        final factory = await createServiceFactoryForWebApp(tercenToken: token);

        setupServiceLocator(
          useMocks: false,
          tercenFactory: factory,
          teamId: teamId,
          projectId: projectId,
        );

        final prefs = await SharedPreferences.getInstance();
        runApp(YourApp(prefs: prefs));

        _postToOrchestrator('app-ready', 'project-nav', {});
      } catch (e) {
        print('Tercen init failed: $e');
        runApp(_buildErrorApp('Initialization failed: $e'));
      }
    }
  });
}
```

### service_locator.dart for Flow D

```dart
void setupServiceLocator({
  bool useMocks = true,
  ServiceFactory? tercenFactory,
  String? projectId,
  String? teamId,
}) {
  if (serviceLocator.isRegistered<DataService>()) return;

  if (useMocks) {
    serviceLocator.registerLazySingleton<DataService>(() => MockDataService());
  } else {
    serviceLocator.registerSingleton<ServiceFactory>(tercenFactory!);
    serviceLocator.registerLazySingleton<DataService>(
      () => TercenDataService(
        tercenFactory,
        projectId: projectId,
        teamId: teamId!,
      ),
    );
  }
}
```

### Sending domain messages from providers

```dart
// In AppStateProvider — when user clicks a data step:
void selectStep(TreeNode step) {
  _selectedStepId = step.id;
  notifyListeners();

  _postToOrchestrator('step-selected', 'project-nav', {
    'projectId': _findAncestorId(step, TreeNodeType.project),
    'workflowId': _findAncestorId(step, TreeNodeType.workflow),
    'stepId': step.id,
  }, target: '*');
}
```

### The startKey/endKey pattern

Entity services use CouchDB-style range queries. Method name encodes key structure: `find<Entity>By<Key1><Key2>` → `startKey: [key1, key2]`, `endKey: [key1, key2]`.

Range conventions: `[prefix, ""]` to `[prefix, "\uf000"]` for all items. `"\uf000"` is a Unicode high char upper bound.

### List projects for a team/user

`teamId` comes from the `init-context` payload (production) or `--dart-define=TEAM_ID` (dev).

```dart
// teamId = "thiago_library" (from init-context payload or --dart-define)
final projects = await factory.projectService.findProjectByOwnerNameStream(
  startKeyOwner: teamId,
  endKeyOwner: teamId,
  startKeyName: "",
  endKeyName: "\uf000",
).toList();
// Returns all projects owned by "thiago_library"
```

### List folders in a project

```dart
final folders = await factory.folderService.findFolderByParentFolderAndName(
  startKey: [projectId, parentFolderId, ""],
  endKey: [projectId, parentFolderId, "\uf000"],
);
```

### List documents (workflows, schemas, files) in a folder

```dart
// Workflows
final workflows = await factory.projectDocumentService
    .findWorkflowByProjectIdFolderStream(
      startKeyProjectId: projectId, endKeyProjectId: projectId,
      startKeyFolderId: folderId,   endKeyFolderId: folderId,
    ).toList();

// Schemas
final schemas = await factory.projectDocumentService
    .findSchemaByProjectIdFolderStream(
      startKeyProjectId: projectId, endKeyProjectId: projectId,
      startKeyFolderId: folderId,   endKeyFolderId: folderId,
    ).toList();

// File documents
final files = await factory.projectDocumentService
    .findFileDocumentByProjectIdFolderStream(
      startKeyProjectId: projectId, endKeyProjectId: projectId,
      startKeyFolderId: folderId,   endKeyFolderId: folderId,
    ).toList();
```

### Get a workflow and its steps

```dart
final workflow = await factory.workflowService.get(workflowId);
// workflow.steps is List<Step> — iterate to find DataStep instances
for (final step in workflow.steps) {
  if (step is DataStep) {
    // step.id, step.name, step.state, step.computedRelation
  }
}
```

### Get multiple workflows at once

```dart
final workflowList = await factory.workflowService.list(workflowIds);
```

### Access data from a workflow step (bridging Flow D → Flow A)

When a user selects a data step, you may need its output data:

```dart
final workflow = await factory.workflowService.get(workflowId);
final step = workflow.steps.firstWhere((s) => s.id == stepId) as DataStep;

// Get output schemas from the step's computed relation
final relations = _getSimpleRelations(step.computedRelation);
final schemaList = await factory.tableSchemaService.list(
  relations.map((r) => r.id).toList(),
);

// Select data from a specific schema
final targetSchema = schemaList.firstWhere((s) => s.name == "TargetTable");
final table = await factory.tableSchemaService.select(
  targetSchema.id,
  targetSchema.columns.map((c) => c.name).toList(),
  0,
  targetSchema.nRows,
);
```

### Helper: extract simple relations from nested structure

```dart
List<Relation> _getSimpleRelations(Relation relation) {
  final result = <Relation>[];
  void _walk(Relation? r) {
    if (r == null) return;
    if (r is SimpleRelation || r is ReferenceRelation) {
      result.add(r);
    } else if (r is JoinRelation) {
      _walk(r.left);
      _walk(r.right);
    } else if (r is WhereRelation || r is RenameRelation) {
      _walk(r.relation);
    } else if (r is CompositeRelation) {
      _walk(r.mainRelation);
      for (final j in r.joinOperators) {
        _walk(j.rightRelation);
      }
    }
  }
  _walk(relation);
  return result;
}
```

### Folder tree caching pattern (for navigation apps)

Load full folder structure once, navigate in memory:

```dart
class ProjectStructureCache {
  final ServiceFactory _factory;
  final String _projectId;
  List<FolderDocument>? _folders;
  List<ProjectDocument>? _documents;

  ProjectStructureCache(this._factory, this._projectId);

  Future<void> load() async {
    _folders = await _fetchAllFolders(_projectId, "");
    _documents = await _fetchAllDocuments(_projectId, "");
  }

  Future<List<FolderDocument>> _fetchAllFolders(String projectId, String parentId) async {
    final folders = await _factory.folderService.findFolderByParentFolderAndName(
      startKey: [projectId, parentId, ""],
      endKey: [projectId, parentId, "\uf000"],
    );
    final children = <FolderDocument>[];
    for (final folder in folders) {
      children.addAll(await _fetchAllFolders(projectId, folder.id));
    }
    return [...folders, ...children];
  }

  Future<List<ProjectDocument>> _fetchAllDocuments(String projectId, String folderId) async {
    return await _factory.projectDocumentService
        .findProjectObjectsByFolderAndName(
          startKey: [projectId, folderId, ""],
          endKey: [projectId, folderId, "\uf000"],
        );
  }
}
```

### Diagnostic report for Flow D

```dart
Future<void> _printFlowDDiagnostic(ServiceFactory factory, String projectId) async {
  print('=== TERCEN DIAGNOSTIC REPORT (Flow D) ===');
  print('ProjectId: $projectId');

  try {
    final project = await factory.projectService.get(projectId);
    print('Project: ${project.name} (owner: ${project.acl.owner})');
  } catch (e) { print('Project fetch ERROR: $e'); }

  try {
    final folders = await factory.folderService.findFolderByParentFolderAndName(
      startKey: [projectId, "", ""], endKey: [projectId, "", "\uf000"],
    );
    print('Root folders: ${folders.length}');
    for (final f in folders) { print('  - ${f.name} (${f.id})'); }
  } catch (e) { print('Folder list ERROR: $e'); }

  print('=== END REPORT ===');
}
```

---

## Step 5: Real service

No mock fallback on error — rethrow and let UI show error state. `USE_MOCKS` in `main.dart` handles local dev.

```dart
import 'package:sci_tercen_client/sci_client_service_factory.dart';
import 'package:sci_tercen_context/sci_tercen_context.dart';

class TercenDataService implements DataService {
  final ServiceFactoryBase _factory;
  final String _taskId;
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

      return _joinAndBuild(qtData, colData, rowData);
    } catch (e) {
      print('Tercen error: $e');
      await _printDiagnosticReport();
      rethrow; // Let the UI handle the error state
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

`save()` normalizes columns and handles the full lifecycle (upload, task update, run, wait-for-done).

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

Required: `index.html` base href commented out. `operator.json`: `isWebApp: true`, `isViewOnly: false`, `entryType: "app"`, `serve: "build/web"`. Type 2 apps MUST have `isViewOnly: false` + `entryType: "app"` or `save()` silently fails.

Hot reload broken for Tercen web apps — always stop and restart.

---

## Diagnostic report

Add to every real service. Call on data loading failure. Present output to user — do NOT fix with code.

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

### All flows

- [ ] `createServiceFactoryForWebApp()` in main.dart with try/catch
- [ ] Data flow matches functional spec Section 2.2
- [ ] Real service rethrows errors (no mock fallback) — UI shows error state
- [ ] Diagnostic report function included in every real service
- [ ] `print()` used instead of `debugPrint()` (required for WASM console output)
- [ ] `flutter build web --wasm` succeeds
- [ ] `build/web/` committed
- [ ] operator.json correct
- [ ] index.html line 17 commented
- [ ] No `dart:html` or `http` package API calls
- [ ] Mock mode works (`--dart-define=USE_MOCKS=true`)

### Flows A/B/C specific

- [ ] `sci_tercen_context` and `sci_tercen_client` in pubspec.yaml at latest matching version (same `ref`)
- [ ] taskId from `Uri.base.queryParameters['taskId']`
- [ ] Context created lazily via `OperatorContext.create()` inside data service (NOT in main.dart)
- [ ] `ServiceFactory` and `taskId` passed from main.dart through service locator to data service
- [ ] Real service uses `ctx.select()` / `ctx.cselect()` / `ctx.rselect()` — NOT manual tableSchemaService calls
- [ ] No manual task navigation code (context handles it)
- [ ] operator.json has `isViewOnly: false` and `entryType: "app"` (required for Type 2 save)

### Flow D specific

- [ ] App waits for `init-context` postMessage before initializing (no standalone credential resolution)
- [ ] `createServiceFactoryForWebApp(tercenToken: token)` uses token from `init-context` payload
- [ ] teamId and projectId extracted from `init-context` payload
- [ ] `app-ready` message sent to orchestrator after successful init
- [ ] Domain messages (e.g., `step-selected`) sent via `_postToOrchestrator()` with correct envelope
- [ ] Mock mode (`--dart-define=USE_MOCKS=true`) skips postMessage wait and uses mock data
- [ ] startKey/endKey range queries return expected data
- [ ] Entity service finder methods match the key order from the method name

---

## Files created/modified

| File | Action |
| ---- | ------ |
| `pubspec.yaml` | Add `sci_tercen_context` dependency, verify `sci_tercen_client` version matches |
| `lib/main.dart` | Modify — create ServiceFactory, pass factory + taskId to service locator |
| `lib/di/service_locator.dart` | Modify — register context + real data service |
| `lib/implementations/services/tercen_*_service.dart` | Create — uses context for data access |
| `lib/utils/*_resolver.dart` | Create (if Flow B needs relation tree walking) |
