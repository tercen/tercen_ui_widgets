---
name: phase-3-review
description: Review a Phase 3 Tercen integration for conformance against SDK rules, data flow patterns, and deployment configuration. Runs as a read-only reviewer agent that produces a PASS/FAIL conformance report. Use after Tercen integration is complete. Assumes Phase 2 conformance has already been verified.
argument-hint: "[path to built app] [path to functional spec]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**This file is READ-ONLY during reviews. Do NOT modify it.**

## Kind dispatch

Determine the widget kind from the spec header or `skeleton.yaml`:

| Kind | Checklist |
|------|-----------|
| panel | This file (Groups A–I below) |
| runner | This file (Groups A–M below) |
| header | `checks-catalog.md` — **stop here and follow that file instead** |
| window | `checks-catalog.md` — **stop here and follow that file instead** |

If the kind is **header** or **window**, do NOT use the checks below. Load and follow `checks-catalog.md` in this same skill directory. It has its own complete workflow, check groups, and report format designed for catalog.json integrations.

---

## Inputs (panel/runner only)

- **Built app directory** — the Phase 3 output (app project folder)
- **Functional spec** — the Phase 1 output document (markdown file)

If missing, ask the user.

---

## Workflow (panel/runner only)

1. Read the functional spec. Identify widget kind (panel/runner) and data flow (A/B/C/D/E) from Section 2.2.
2. Read `pubspec.yaml`, `lib/main.dart`, `lib/di/service_locator.dart`, `operator.json`, `web/index.html`, `.gitignore`. Glob `lib/implementations/services/*.dart` and read each result.
3. Grep `lib/` for banned patterns: `dart:html`, `tableSchemaService`, `taskService.get`, `RunWebAppTask`, `CubeQueryTask`, `package:http/`, `sci_tercen_context`, `Phase 3:`. For runner widgets, also grep for `OperatorContext` (should NOT appear).
4. Spot-check: read `lib/core/theme/app_theme.dart`, `lib/presentation/widgets/left_panel/left_panel.dart`, `lib/core/theme/app_line_weights.dart` from both skeleton and app.
5. Produce the conformance report and save to `_local/phase-3-conformance-report.md` in the app directory.

---

## Check Group A: Dependencies

### A1: sci_tercen_context in pubspec.yaml

N/A for runner widgets (Flow E does not use sci_tercen_context).

`pubspec.yaml` must contain a `sci_tercen_context` dependency pointing to the `sci_tercen_client` git repo with `path: sci_tercen_context`.

### A2: sci_tercen_client in pubspec.yaml

`pubspec.yaml` must contain a `sci_tercen_client` dependency pointing to the `sci_tercen_client` git repo with `path: sci_tercen_client`.

### A3: Version match

N/A for runner widgets if only sci_tercen_client is used.

Both `sci_tercen_context` and `sci_tercen_client` must use the same `ref:` value. Mismatch is a FAIL.

### A4: No dart:html imports

Grep `lib/` for `import ['"]dart:html`. Any occurrence is a FAIL.

### A5: No http package for Tercen calls

Grep `lib/` for `import ['"]package:http/`. If found, read the file — FAIL only if used for Tercen API calls (auth, data fetch, file download). Non-Tercen usage (external resources described in spec) is acceptable.

---

## Check Group B: main.dart Integration

**N/A for runner widgets — see Group J.**

### B1: Factory creation

`main.dart` must call `createServiceFactoryForWebApp()` from `package:sci_tercen_client/sci_service_factory_web.dart`.

### B2: Context creation

`main.dart` must create a `ServiceFactory` via `createServiceFactoryForWebApp()` and pass it (along with `taskId`) to `setupServiceLocator`. Context creation happens lazily inside the data service via `OperatorContext.create()`.

### B3: taskId from URL

`main.dart` must extract `taskId` from `Uri.base.queryParameters['taskId']`.

### B4: Null/empty taskId handling

`main.dart` must check for null or empty `taskId` before attempting context creation. Missing check is a FAIL.

### B5: Try-catch around Tercen init

Factory creation must be wrapped in a try-catch. If init fails, the app must fall back to mock mode (not crash).

### B6: Factory and taskId passed to service locator

`setupServiceLocator` must receive the `ServiceFactory` and `taskId`:

```dart
setupServiceLocator(useMocks: factory == null, factory: factory, taskId: taskId);
```

or equivalent logic where `useMocks` is true when factory creation failed. Context must NOT be created in main.dart — it is created lazily in the data service.

### B7: No manual task navigation

`main.dart` must NOT contain code that manually navigates `RunWebAppTask` to `CubeQueryTask` or calls `taskService.get()`. `OperatorContext.create()` handles this inside the data service.

---

## Check Group C: service_locator.dart

**N/A for runner widgets — see Group J.**

### C1: Accepts factory and taskId parameters

`setupServiceLocator` must accept `ServiceFactory?` and `String?` parameters (not commented out).

### C2: Real service receives factory and taskId

When not using mocks, must register a real data service that receives factory and taskId:

```dart
serviceLocator.registerLazySingleton<DataService>(
  () => TercenDataService(factory!, taskId!),
);
```

### C3: Real service registered

When not using mocks, at least one real data service must be registered.

### C4: Guard against double registration

Must check `if (serviceLocator.isRegistered<DataService>()) return;` (or equivalent) before registering.

### C5: Import present

Must import `package:sci_tercen_client/sci_client_service_factory.dart` (not commented out).

---

## Check Group D: Data Flow

Determine flow from spec Section 2.2:

| Flow | When | Expected methods |
| ---- | ---- | ---------------- |
| A | Computed values, charts, grids from projections | `ctx.select()`, `ctx.cselect()`, `ctx.rselect()` |
| B | File downloads via `.documentId` | `ctx.cselect(names: ['.documentId'])`, `fileService.download()` |
| C | Both | Flow A + Flow B in separate resolver classes |
| D | In-project app receiving context via postMessage | Same as A/B/C but with orchestrated init |
| E | Runner workflow execution (clone, upload, run, monitor) | `workflowService.copyApp()`, `taskService.runTask()`, `eventService.listenTaskChannel()` |

### D1: Correct flow identified

Determine from the spec which flow applies. Record it.

### D2: Flow A — select/cselect/rselect usage (if applicable)

Real data service must call `ctx.select()`, `ctx.cselect()`, `ctx.rselect()` on the `AbstractOperatorContext` instance, NOT via manual `tableSchemaService.select()`.

### D3: Flow B — file download usage (if applicable)

Real data service must:
- Obtain document IDs via `ctx.cselect(names: ['.documentId'])` or relation tree walking
- Download files via `ctx.serviceFactory.fileService.download()` (not `dart:html` or `http`)
- Limit concurrent downloads (max 3)

### D4: No manual tableSchemaService calls

N/A for runner / Flow E (Flow E legitimately uses `tableSchemaService.select()` for step output reading).

Grep `lib/` for `tableSchemaService`. Any direct call to `tableSchemaService.select()` or `tableSchemaService.get()` is a FAIL. All data access must go through the context API.

### D5: No manual task hierarchy navigation

N/A for runner / Flow E (Flow E uses `taskService` directly for workflow execution — this is correct, not a ban violation).

Grep `lib/` for: `taskService.get(`, `RunWebAppTask`, `CubeQueryTask`, `.state.taskId`.

Any code that manually walks the task hierarchy is a FAIL (the context handles this).

Exception: `RunWebAppTask` or `CubeQueryTask` in import statements from `sci_tercen_context` is acceptable. Read the file to verify matches are in imports, not in logic.

---

## Check Group E: Real Data Service

**N/A for runner widgets — see Group K.**

Glob `lib/implementations/services/*.dart` and read each result.

### E1: Real service exists

At least one file must implement a real Tercen data service (not the mock).

### E2: Real service receives factory and taskId

Constructor must accept `ServiceFactoryBase` and `String` parameters (factory + taskId). Must create context lazily via `OperatorContext.create()` inside a `_getContext()` method or equivalent — NOT receive a pre-built context.

### E3: Error handling — diagnostic + rethrow

The real service must NOT fall back to mock data at runtime. Verify:
- Try-catch around Tercen data access
- Catch block prints a diagnostic report and rethrows the error
- UI shows error state (via `AppStateProvider._error`) — does NOT silently show mock data

Mock mode is handled at startup in `main.dart` (`USE_MOCKS` flag), not at runtime inside the data service.

### E4: Diagnostic report present

Must contain a `_printDiagnosticReport()` method (or equivalent) that prints:
- Task ID and type
- Schema info (qtHash, columnHash, rowHash) with column names and types
- Namespace

Must be called in the catch block when data access fails.

### E5: No workaround code

Must NOT contain commented-out alternative approaches, multiple retry strategies, or progressively degraded data access paths. If Tercen fails, it falls back to mock — period.

---

## Check Group F: Write-Back Specifics

If widget does NOT write back to Tercen, mark all F checks as N/A.

### F1: Output table construction

Grep real service for `makeInt32Column`, `makeFloat64Column`, `makeStringColumn`. Must build output tables using these static column helpers.

### F2: Save method used

Grep real service for `saveTable`, `saveTables`, or `ctx.save`. Output must be saved via context methods, NOT via manual file upload or task service calls.

### F3: Namespace applied

Grep real service for `addNamespace`. Should use `ctx.addNamespace()` to prefix column names.

### F4: Lifecycle logging

Grep real service for `ctx.log` and `ctx.progress`. Write-back widgets should report status to the Tercen UI.

---

## Check Group G: Build and Deploy Configuration

### G1: operator.json isWebApp

`operator.json` must have `"isWebApp": true`.

### G2: operator.json serve

`operator.json` must have `"serve": "build/web"`.

### G3: operator.json isViewOnly

Must have `"isViewOnly": false` for write-back widgets. For read-only widgets, note but do not FAIL if missing.

### G4: operator.json entryType

Must have `"entryType": "app"` for write-back widgets. For read-only widgets, note but do not FAIL if missing.

### G5: index.html base href commented

`web/index.html` must contain the base href line commented out:

```html
<!--<base href="$FLUTTER_BASE_HREF">-->
```

If uncommented or missing, FAIL.

### G6: .gitignore preserves build/web

`.gitignore` must contain `!build/web/`.

### G7: build/web committed (if build was done)

Glob `build/web/` for content. If it exists, it should contain Flutter web build output. If missing, note but do not FAIL — the build may not have been run yet.

---

## Check Group H: Import Hygiene

### H1: Single context import pattern

N/A for runner widgets (Flow E does not use sci_tercen_context).

Grep `lib/` for `sci_tercen_context`. Files that use it should import via:

```dart
import 'package:sci_tercen_context/sci_tercen_context.dart';
```

This single import re-exports all models. Importing individual model files is unnecessary (note but do not FAIL — it still works).

### H2: Factory import

`main.dart` must import:

```dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';
```

### H3: No stale commented-out Phase 3 stubs

N/A for runner widgets (runner skeleton has different stubs — checked by Group J).

Grep `service_locator.dart` for `Phase 3:`. Skeleton stubs like `// Phase 3: uncomment to accept context` must have been replaced with actual code. If these comments remain, FAIL.

---

## Check Group I: DO-NOT-MODIFY Files (Spot Check)

Targeted spot check to ensure integration work did not accidentally modify protected files. Phase 2 review covers the full comparison.

### I1: main.dart structure preserved

Modified for Tercen integration, but must retain:
- `WidgetsFlutterBinding.ensureInitialized()`
- `SharedPreferences` initialization
- `ChangeNotifierProvider` for `ThemeProvider`
- App class with `MaterialApp`

### I2: service_locator.dart structure preserved

Modified for real services, but must retain:
- `GetIt serviceLocator = GetIt.instance` declaration
- Guard check
- Mock registration when `useMocks` is true

### I3: Theme files untouched

`lib/core/theme/app_theme.dart` must be identical to skeleton version. Phase 3 has no reason to touch theme files.

### I4: Panel files untouched

`lib/presentation/widgets/left_panel/left_panel.dart` must be identical to skeleton version.

### I5: app_line_weights.dart present and untouched

`lib/core/theme/app_line_weights.dart` must exist and be identical to skeleton version.

### I6: Header panel untouched (runner only)

N/A for panel widgets.

`lib/presentation/widgets/header_panel.dart` must be identical to skeleton version. Phase 3 has no reason to modify the header panel.

### I7: Content panel structure untouched (runner only)

N/A for panel widgets.

`lib/presentation/widgets/content_panel/` directory structure must match skeleton. Files within may be modified for real data, but no files should be deleted or added.

---

## Check Group J: Runner main.dart and service_locator.dart

**N/A for panel widgets.** Replaces Groups B and C for runner widgets.

### J1: projectId from URL or postMessage

`main.dart` must extract `projectId` from `Uri.base.queryParameters['projectId']` (standalone mode) or receive it via `init-context` postMessage (orchestrated mode). At least one path must be present.

### J2: No OperatorContext creation

Grep entire `lib/` for `OperatorContext`. Any occurrence (create, import, type annotation) is a FAIL. Runner widgets do not use OperatorContext.

### J3: ServiceFactory + projectId passed to service locator

`setupServiceLocator` must receive `ServiceFactory` and `projectId`:

```dart
setupServiceLocator(useMocks: factory == null, factory: factory, projectId: projectId);
```

### J4: Null/empty projectId handling

`main.dart` must check for null or empty `projectId` before passing to service locator. Missing check is a FAIL.

### J5: Try-catch around init

Factory creation must be wrapped in a try-catch. If init fails, the app must fall back to mock mode (not crash).

### J6: service_locator registers TercenWorkflowService

When not using mocks, must register a real workflow service that receives factory and projectId:

```dart
serviceLocator.registerLazySingleton<WorkflowDataService>(
  () => TercenWorkflowService(factory!, projectId!),
);
```

### J7: service_locator registers ServiceFactory

`ServiceFactory` itself must be registered in the service locator (runner services access it for task/event/file operations):

```dart
serviceLocator.registerSingleton<ServiceFactoryBase>(factory!);
```

---

## Check Group K: Runner Workflow Service

**N/A for panel widgets.** Replaces Group E for runner widgets.

Glob `lib/implementations/services/*.dart` and read each result.

### K1: Real workflow service exists

At least one file must implement a real Tercen workflow service (not the mock).

### K2: Receives ServiceFactory + projectId

Constructor must accept `ServiceFactoryBase` and `String` parameters (factory + projectId). Must NOT accept or create an OperatorContext.

### K3: Template cloning via copyApp

Must call `factory.workflowService.copyApp(templateWorkflowId, projectId)` to clone a template workflow for each run.

### K4: RunWorkflowTask construction

Must construct a `RunWorkflowTask` with at minimum: `workflowId`, `workflowRev`, `projectId`. Should set `stepsToRun` and/or `stepsToReset` as appropriate.

### K5: Task lifecycle — create + runTask

Must call `factory.taskService.create(task)` followed by `factory.taskService.runTask(taskId)`. Must NOT skip the create step.

### K6: Progress monitoring via event stream

Must call `factory.eventService.listenTaskChannel(taskId, ...)` or `factory.eventService.onTaskState(taskId)` to monitor execution. Must dispatch by event type (`TaskLogEvent`, `TaskProgressEvent`, `TaskStateEvent`).

### K7: Terminal state detection

Must check for terminal states: `DoneState` (success) and `FailedState` (failure). Must extract error info from `FailedState` (`.reason` or `.error`).

### K8: Task cancellation

Must implement cancellation via `factory.taskService.cancelTask(taskId)`. Must be callable from the UI (connected to Stop button via provider).

### K9: Error handling — diagnostic + rethrow

Try-catch around Tercen operations. Catch block must print diagnostic info (projectId, workflowId, task state) and rethrow. Must NOT silently swallow errors or fall back to mock data at runtime.

---

## Check Group L: Runner Output Reading

**N/A for panel widgets. N/A if app does not read step outputs (check spec).**

### L1: step.computedRelation navigation

Must access step output via `step.computedRelation`. Must cast step to `DataStep` before accessing `computedRelation`.

### L2: tableSchemaService.select() for output data

Must call `factory.tableSchemaService.select(hash, columnNames, offset, limit)` to read data from step output schemas.

### L3: Relation tree walker present

Must have a method that walks the `Relation` tree to extract `SimpleRelation` objects (which contain the schema hashes). This can be a recursive method or iterative loop.

---

## Check Group M: Runner operator.json

**N/A for panel widgets.** Common checks (isWebApp, serve) are covered by Group G — this group covers runner-specific fields only.

### M1: isViewOnly noted

Note whether `"isViewOnly"` is present and its value. Do not FAIL — runner widgets may vary. Record for informational purposes.

---

## Conformance Report Format

Produce the report in this exact format. List every check — do not abbreviate or truncate with "...".

```markdown
# Phase 3 Conformance Report

**App:** [app name from pubspec.yaml]
**Spec:** [spec filename]
**Date:** [review date]
**Data Flow:** [A / B / C / D / E — determined from spec]
**Widget Kind:** [panel / runner / window — determined from spec]

## Summary

| Result | Count |
|--------|-------|
| PASS | [n] |
| FAIL | [n] |
| N/A | [n] |
| **Total** | [n] |

**Verdict:** [CONFORMING / NON-CONFORMING]

An app is CONFORMING only if every check is PASS or N/A. Any FAIL makes it NON-CONFORMING.

---

## Results

### A: Dependencies
- A1: [PASS/FAIL/N/A] — sci_tercen_context in pubspec [detail if FAIL]
- A2: [PASS/FAIL] — sci_tercen_client in pubspec [detail if FAIL]
- A3: [PASS/FAIL/N/A] — Version match [detail if FAIL]
- A4: [PASS/FAIL] — No dart:html [detail if FAIL]
- A5: [PASS/FAIL] — No http for Tercen calls [detail if FAIL]

### B: main.dart Integration (N/A for runner — see J)
- B1: [PASS/FAIL/N/A] — Factory creation [detail if FAIL]
- B2: [PASS/FAIL/N/A] — Context creation [detail if FAIL]
- B3: [PASS/FAIL/N/A] — taskId from URL [detail if FAIL]
- B4: [PASS/FAIL/N/A] — Null/empty taskId handling [detail if FAIL]
- B5: [PASS/FAIL/N/A] — Try-catch around init [detail if FAIL]
- B6: [PASS/FAIL/N/A] — Factory and taskId passed to service locator [detail if FAIL]
- B7: [PASS/FAIL/N/A] — No manual task navigation [detail if FAIL]

### C: service_locator.dart (N/A for runner — see J)
- C1: [PASS/FAIL/N/A] — Accepts factory and taskId parameters [detail if FAIL]
- C2: [PASS/FAIL/N/A] — Real service receives factory and taskId [detail if FAIL]
- C3: [PASS/FAIL/N/A] — Real service registered [detail if FAIL]
- C4: [PASS/FAIL/N/A] — Guard against double registration [detail if FAIL]
- C5: [PASS/FAIL/N/A] — Import present [detail if FAIL]

### D: Data Flow
- D1: [PASS/FAIL] — Correct flow identified: [A/B/C/D/E] [detail if FAIL]
- D2: [PASS/FAIL/N/A] — Flow A usage [detail if FAIL]
- D3: [PASS/FAIL/N/A] — Flow B usage [detail if FAIL]
- D4: [PASS/FAIL/N/A] — No manual tableSchemaService calls [detail if FAIL]
- D5: [PASS/FAIL/N/A] — No manual task navigation [detail if FAIL]

### E: Real Data Service (N/A for runner — see K)
- E1: [PASS/FAIL/N/A] — Real service exists [detail if FAIL]
- E2: [PASS/FAIL/N/A] — Receives factory and taskId, lazy context [detail if FAIL]
- E3: [PASS/FAIL/N/A] — Single fallback strategy [detail if FAIL]
- E4: [PASS/FAIL/N/A] — Diagnostic report present [detail if FAIL]
- E5: [PASS/FAIL/N/A] — No workaround code [detail if FAIL]

### F: Write-Back Specifics
- F1: [PASS/FAIL/N/A] — Output table construction [detail if FAIL]
- F2: [PASS/FAIL/N/A] — Save method [detail if FAIL]
- F3: [PASS/FAIL/N/A] — Namespace applied [detail if FAIL]
- F4: [PASS/FAIL/N/A] — Lifecycle logging [detail if FAIL]

### G: Build and Deploy
- G1: [PASS/FAIL] — operator.json isWebApp [detail if FAIL]
- G2: [PASS/FAIL] — operator.json serve [detail if FAIL]
- G3: [PASS/FAIL/N/A] — operator.json isViewOnly [detail if FAIL]
- G4: [PASS/FAIL/N/A] — operator.json entryType [detail if FAIL]
- G5: [PASS/FAIL] — index.html base href commented [detail if FAIL]
- G6: [PASS/FAIL] — .gitignore preserves build/web [detail if FAIL]
- G7: [PASS/FAIL] — build/web committed [detail if FAIL]

### H: Import Hygiene
- H1: [PASS/FAIL/N/A] — Single context import [detail if FAIL]
- H2: [PASS/FAIL] — Factory import [detail if FAIL]
- H3: [PASS/FAIL/N/A] — No stale Phase 3 stubs [detail if FAIL]

### I: DO-NOT-MODIFY Spot Check
- I1: [PASS/FAIL] — main.dart structure [detail if FAIL]
- I2: [PASS/FAIL] — service_locator.dart structure [detail if FAIL]
- I3: [PASS/FAIL] — Theme files untouched [detail if FAIL]
- I4: [PASS/FAIL] — Panel files untouched [detail if FAIL]
- I5: [PASS/FAIL] — app_line_weights.dart untouched [detail if FAIL]
- I6: [PASS/FAIL/N/A] — Header panel untouched (runner only) [detail if FAIL]
- I7: [PASS/FAIL/N/A] — Content panel structure untouched (runner only) [detail if FAIL]

### J: Runner main.dart and service_locator (N/A for panel)
- J1: [PASS/FAIL/N/A] — projectId from URL or postMessage [detail if FAIL]
- J2: [PASS/FAIL/N/A] — No OperatorContext [detail if FAIL]
- J3: [PASS/FAIL/N/A] — Factory + projectId to service locator [detail if FAIL]
- J4: [PASS/FAIL/N/A] — Null/empty projectId handling [detail if FAIL]
- J5: [PASS/FAIL/N/A] — Try-catch around init [detail if FAIL]
- J6: [PASS/FAIL/N/A] — TercenWorkflowService registered [detail if FAIL]
- J7: [PASS/FAIL/N/A] — ServiceFactory registered [detail if FAIL]

### K: Runner Workflow Service (N/A for panel)
- K1: [PASS/FAIL/N/A] — Real workflow service exists [detail if FAIL]
- K2: [PASS/FAIL/N/A] — Receives factory + projectId [detail if FAIL]
- K3: [PASS/FAIL/N/A] — Template cloning via copyApp [detail if FAIL]
- K4: [PASS/FAIL/N/A] — RunWorkflowTask construction [detail if FAIL]
- K5: [PASS/FAIL/N/A] — Task lifecycle create + runTask [detail if FAIL]
- K6: [PASS/FAIL/N/A] — Progress monitoring via event stream [detail if FAIL]
- K7: [PASS/FAIL/N/A] — Terminal state detection [detail if FAIL]
- K8: [PASS/FAIL/N/A] — Task cancellation [detail if FAIL]
- K9: [PASS/FAIL/N/A] — Error handling diagnostic + rethrow [detail if FAIL]

### L: Runner Output Reading (N/A for panel or if widget doesn't read outputs)
- L1: [PASS/FAIL/N/A] — step.computedRelation navigation [detail if FAIL]
- L2: [PASS/FAIL/N/A] — tableSchemaService.select() usage [detail if FAIL]
- L3: [PASS/FAIL/N/A] — Relation tree walker [detail if FAIL]

### M: Runner operator.json (N/A for panel)
- M1: [N/A] — isViewOnly noted [informational only]

---

## Failures Detail

[For each FAIL, provide:]

### [Check ID]: [Check name]
**File:** [file path]
**Line:** [line number if applicable]
**Expected:** [what should be there]
**Found:** [what was found]
**Spec Reference:** [which spec section this relates to, if applicable]
```

---

## Rules

1. **Read the spec first.** Understand widget kind and data flow before starting checks.
2. **Report only.** Never edit app files.
3. **Only check what this skill defines.** Do not add opinions about code quality, naming, or architecture beyond what is specified here.
4. **All failures are equal.** Every check is PASS or FAIL. N/A only when the skill explicitly allows it (e.g., write-back checks for a read-only widget, Flow B checks for a Flow A widget).
5. **Cite file paths and line numbers in failures.** Phase 2 is assumed passing — do not re-check Phase 2 requirements.
