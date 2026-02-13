# Review: Phase 3 Tercen Integration Conformance

**This file is READ-ONLY during reviews. Do NOT modify it.**

You are a reviewer agent running in Claude Code. Your job is to read a built app and verify its Tercen integration conforms to all rules. This review assumes Phase 2 conformance has already been verified — it focuses only on Phase 3 integration concerns.

---

## Inputs Required

Before starting, confirm you have:

1. **Built app directory** — the Phase 3 output (the app project folder)
2. **Functional spec** — the Phase 1 output document (markdown file)

If the user has not provided both paths, use the AskUserQuestion tool to request missing paths.

---

## Execution Strategy

Follow this order:

1. Use the **Read** tool to read the entire functional spec file. Identify the app type (1/2/3) and data flow (A/B/C) from Section 2.2.
2. Use the **Read** tool to read the key integration files in parallel: `pubspec.yaml`, `lib/main.dart`, `lib/di/service_locator.dart`.
3. Use the **Glob** tool to find real service files: `lib/implementations/services/*.dart`.
4. Use the **Read** tool to read each real service file found.
5. Use the **Grep** tool for pattern searches (Check Groups D and H): search `lib/` for `dart:html`, `tableSchemaService`, `taskService.get`, `RunWebAppTask`, `CubeQueryTask`, `package:http/`.
6. **Check Group G (config):** Use the **Read** tool to read `operator.json`, `web/index.html`, `.gitignore`.
7. **Check Group I (spot check):** Use the **Read** tool to read `lib/core/theme/app_theme.dart` and `lib/presentation/widgets/left_panel/left_panel.dart` from both the skeleton and the app (for comparison). Read these in parallel.
8. Produce the **Conformance Report** (format at the bottom of this skill).
9. Use the **Write** tool to save the report to `_local/phase-3-conformance-report.md` in the app directory.

**Parallelism:** When reading multiple independent files (Steps 2, 5, 7), make parallel Read/Grep tool calls. Do not read files one at a time when they are independent.

---

## Check Group A: Dependencies

### A1: sci_tercen_context in pubspec.yaml

Use the **Read** tool to read `pubspec.yaml`. It must contain a `sci_tercen_context` dependency pointing to the `sci_tercen_client` git repo with a `path: sci_tercen_context`.

### A2: sci_tercen_client in pubspec.yaml

`pubspec.yaml` must contain a `sci_tercen_client` dependency pointing to the `sci_tercen_client` git repo with a `path: sci_tercen_client`.

### A3: Version match

Both `sci_tercen_context` and `sci_tercen_client` must use the same `ref:` value (version tag). Mismatched versions are a FAIL.

### A4: No dart:html imports

Use the **Grep** tool to search `lib/` for the pattern `import ['"]dart:html`. Any occurrence is a FAIL.

### A5: No http package for Tercen calls

Use the **Grep** tool to search `lib/` for the pattern `import ['"]package:http/`. If found, use the **Read** tool to read the file and verify it is NOT used for Tercen API calls. If it is used for Tercen API calls (auth, data fetch, file download), that is a FAIL. Usage for unrelated purposes (e.g., fetching external non-Tercen resources described in the spec) is acceptable.

---

## Check Group B: main.dart Integration

Use the **Read** tool to read `lib/main.dart` for all checks in this group.

### B1: Factory creation

`main.dart` must call `createServiceFactoryForWebApp()` from `package:sci_tercen_client/sci_service_factory_web.dart`.

### B2: Context creation

`main.dart` must call `tercenCtx(serviceFactory: factory, taskId: taskId)` from `package:sci_tercen_context/sci_tercen_context.dart`.

### B3: taskId from URL

`main.dart` must extract `taskId` from `Uri.base.queryParameters['taskId']`.

### B4: Null/empty taskId handling

`main.dart` must check for null or empty `taskId` before attempting context creation. Missing check is a FAIL.

### B5: Try-catch around Tercen init

The factory creation and context creation must be wrapped in a try-catch. If Tercen init fails, the app must fall back to mock mode (not crash).

### B6: Context passed to service locator

`setupServiceLocator` must be called with the context. The call should look like:

```dart
setupServiceLocator(useMocks: ctx == null, ctx: ctx);
```

or equivalent logic where `useMocks` is true when context creation failed.

### B7: No manual task navigation

`main.dart` must NOT contain code that manually navigates `RunWebAppTask` to `CubeQueryTask` or calls `taskService.get()`. The `tercenCtx()` factory handles this automatically.

---

## Check Group C: service_locator.dart

Use the **Read** tool to read `lib/di/service_locator.dart` for all checks in this group.

### C1: Accepts context parameter

`setupServiceLocator` must accept an `AbstractOperatorContext?` parameter (not commented out).

### C2: AbstractOperatorContext registered with explicit type

When not using mocks, the service locator must register the context with an explicit type parameter:

```dart
serviceLocator.registerSingleton<AbstractOperatorContext>(ctx!);
```

A registration without the type parameter (e.g., `registerSingleton(ctx!)`) is a FAIL.

### C3: Real service registered

When not using mocks, at least one real data service must be registered that receives the context.

### C4: Guard against double registration

`setupServiceLocator` must check `if (serviceLocator.isRegistered<DataService>()) return;` (or equivalent) before registering.

### C5: Import present

`service_locator.dart` must import `package:sci_tercen_context/sci_tercen_context.dart` (not commented out).

---

## Check Group D: Data Flow

Read the functional spec Section 2.2 to determine which data flow the app should use:

| Flow | When | Expected methods |
| ---- | ---- | ---------------- |
| A | Computed values, charts, grids from projections | `ctx.select()`, `ctx.cselect()`, `ctx.rselect()` |
| B | File downloads via `.documentId` | `ctx.cselect(names: ['.documentId'])`, `fileService.download()` |
| C | Both | Flow A + Flow B in separate resolver classes |

### D1: Correct flow identified

Determine from the spec which flow applies. Record it.

### D2: Flow A — select/cselect/rselect usage (if applicable)

If the app uses Flow A, use the **Read** tool to read the real data service. It must call:
- `ctx.select()` for main data
- `ctx.cselect()` for column metadata (if needed)
- `ctx.rselect()` for row metadata (if needed)

These must be called on the `AbstractOperatorContext` instance, NOT via manual `tableSchemaService.select()`.

### D3: Flow B — file download usage (if applicable)

If the app uses Flow B, use the **Read** tool to read the real data service. Verify:
- Document IDs are obtained via `ctx.cselect(names: ['.documentId'])` or relation tree walking
- File downloads use `ctx.serviceFactory.fileService.download()` (not `dart:html` or `http`)
- Concurrent downloads are limited (max 3)

### D4: No manual tableSchemaService calls

Use the **Grep** tool to search `lib/` for `tableSchemaService`. Any direct call to `tableSchemaService.select()` or `tableSchemaService.get()` is a FAIL. All data access must go through the context API.

### D5: No manual task hierarchy navigation

Use the **Grep** tool to search `lib/` for these patterns (run as separate Grep calls in parallel):
- `taskService.get(`
- `RunWebAppTask`
- `CubeQueryTask`
- `.state.taskId`

Any code that manually walks the task hierarchy is a FAIL (the context handles this).

Exception: `RunWebAppTask` or `CubeQueryTask` may appear in import statements from `sci_tercen_context` — that is acceptable. It must NOT appear in manually-written navigation logic. Use the **Read** tool on the file to verify if a match is in an import or in logic.

---

## Check Group E: Real Data Service

Use the **Glob** tool to find files matching `lib/implementations/services/*.dart`, then use the **Read** tool to read each one.

### E1: Real service exists

At least one file in `lib/implementations/services/` must implement a real Tercen data service (not the mock).

### E2: Real service receives context

The real service constructor must accept an `AbstractOperatorContext` parameter.

### E3: Single fallback strategy

The real service must have exactly ONE fallback: Tercen fails -> fall back to mock. Verify:
- There is a try-catch around Tercen data access
- The catch block falls back to mock data (calls `MockDataService` or equivalent)
- There are NO nested fallback chains (e.g., try Flow A, if fail try Flow B, if fail try manual query)

Flow A and Flow B are different access patterns for different data — they are NOT fallback alternatives for each other.

### E4: Diagnostic report present

The real service must contain a `_printDiagnosticReport()` method (or equivalent) that prints:
- Task ID and type
- Schema info (qtHash, columnHash, rowHash) with column names and types
- Namespace

The diagnostic report must be called in the catch block when data access fails.

### E5: No workaround code

The real service must NOT contain commented-out alternative approaches, multiple retry strategies, or progressively degraded data access paths. If Tercen fails, it falls back to mock — period.

---

## Check Group F: Type 2 Specifics (Write-Back)

Read the functional spec to determine the app type. If the app is NOT Type 2, mark all F checks as N/A.

### F1: Output table construction

If Type 2, use the **Grep** tool to search the real service for `makeInt32Column`, `makeFloat64Column`, `makeStringColumn`. The service must build output tables using these static column helpers.

### F2: Save method used

Use the **Grep** tool to search the real service for `saveTable`, `saveTables`, or `ctx.save`. Output must be saved via context methods, NOT via manual file upload or task service calls.

### F3: Namespace applied

If the service creates output columns, use the **Grep** tool to search for `addNamespace`. It should use `ctx.addNamespace()` to prefix column names.

### F4: Lifecycle logging

Use the **Grep** tool to search the real service for `ctx.log` and `ctx.progress`. Type 2 apps should report status to the Tercen UI.

---

## Check Group G: Build and Deploy Configuration

### G1: operator.json isWebApp

Use the **Read** tool to read `operator.json`. It must have `"isWebApp": true`.

### G2: operator.json serve

`operator.json` must have `"serve": "build/web"`.

### G3: index.html base href commented

Use the **Read** tool to read `web/index.html`. It must contain the base href line commented out:

```html
<!--<base href="$FLUTTER_BASE_HREF">-->
```

If the line is uncommented or missing, that is a FAIL.

### G4: .gitignore preserves build/web

Use the **Read** tool to read `.gitignore`. It must contain `!build/web/` to preserve the web build output.

### G5: build/web committed (if build was done)

Use the **Glob** tool to check if `build/web/` exists with content. If it exists, it should contain the Flutter web build output. If the directory does not exist, note it but do not FAIL — the build may not have been run yet.

---

## Check Group H: Import Hygiene

### H1: Single context import pattern

Use the **Grep** tool to search `lib/` for `sci_tercen_context`. Files that use it should import via:

```dart
import 'package:sci_tercen_context/sci_tercen_context.dart';
```

This single import re-exports all models. Importing individual model files from the package internals is unnecessary (note but do not FAIL for this — it still works, it's just not clean).

### H2: Factory import

Use the **Read** tool to verify `main.dart` imports:

```dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';
```

### H3: No stale commented-out Phase 3 stubs

Use the **Grep** tool to search `service_locator.dart` for `Phase 3:`. The skeleton's commented-out stubs like `// Phase 3: uncomment to accept context` and `// Phase 3: add else branch:` should have been replaced with actual code. If these comments still exist, that is a FAIL.

---

## Check Group I: DO-NOT-MODIFY Files (Spot Check)

Phase 2 review covers the full DO-NOT-MODIFY comparison. This Phase 3 review does a targeted spot check to ensure integration work did not accidentally modify protected files.

### I1: main.dart structure preserved

Use the **Read** tool to read `main.dart`. It should have been modified for Tercen integration, but the overall structure must remain:
- `WidgetsFlutterBinding.ensureInitialized()` present
- `SharedPreferences` initialization present
- `ChangeNotifierProvider` for `ThemeProvider` present
- App class with `MaterialApp` present

### I2: service_locator.dart structure preserved

`service_locator.dart` should have been modified to accept context and register real services, but:
- The `GetIt serviceLocator = GetIt.instance` declaration must remain
- The guard check must remain
- Mock registration must still work when `useMocks` is true

### I3: Theme files untouched

Use the **Read** tool to read `lib/core/theme/app_theme.dart` from both the skeleton and the app. Compare content — they must be identical. Phase 3 has no reason to touch theme files.

### I4: Panel files untouched

Use the **Read** tool to read `lib/presentation/widgets/left_panel/left_panel.dart` from both the skeleton and the app. Compare content — they must be identical.

---

## Conformance Report Format

Produce the report in this exact format. List every check — do not abbreviate or truncate with "...".

```markdown
# Phase 3 Conformance Report

**App:** [app name from pubspec.yaml]
**Spec:** [spec filename]
**Date:** [review date]
**Data Flow:** [A / B / C — determined from spec]
**App Type:** [1 / 2 / 3 — determined from spec]

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
- A1: [PASS/FAIL] — sci_tercen_context in pubspec [detail if FAIL]
- A2: [PASS/FAIL] — sci_tercen_client in pubspec [detail if FAIL]
- A3: [PASS/FAIL] — Version match [detail if FAIL]
- A4: [PASS/FAIL] — No dart:html [detail if FAIL]
- A5: [PASS/FAIL] — No http for Tercen calls [detail if FAIL]

### B: main.dart Integration
- B1: [PASS/FAIL] — Factory creation [detail if FAIL]
- B2: [PASS/FAIL] — Context creation [detail if FAIL]
- B3: [PASS/FAIL] — taskId from URL [detail if FAIL]
- B4: [PASS/FAIL] — Null/empty taskId handling [detail if FAIL]
- B5: [PASS/FAIL] — Try-catch around init [detail if FAIL]
- B6: [PASS/FAIL] — Context passed to service locator [detail if FAIL]
- B7: [PASS/FAIL] — No manual task navigation [detail if FAIL]

### C: service_locator.dart
- C1: [PASS/FAIL] — Accepts context parameter [detail if FAIL]
- C2: [PASS/FAIL] — Explicit type on registration [detail if FAIL]
- C3: [PASS/FAIL] — Real service registered [detail if FAIL]
- C4: [PASS/FAIL] — Guard against double registration [detail if FAIL]
- C5: [PASS/FAIL] — Import present [detail if FAIL]

### D: Data Flow
- D1: [PASS/FAIL] — Correct flow identified: [A/B/C] [detail if FAIL]
- D2: [PASS/FAIL/N/A] — Flow A usage [detail if FAIL]
- D3: [PASS/FAIL/N/A] — Flow B usage [detail if FAIL]
- D4: [PASS/FAIL] — No manual tableSchemaService calls [detail if FAIL]
- D5: [PASS/FAIL] — No manual task navigation [detail if FAIL]

### E: Real Data Service
- E1: [PASS/FAIL] — Real service exists [detail if FAIL]
- E2: [PASS/FAIL] — Receives context [detail if FAIL]
- E3: [PASS/FAIL] — Single fallback strategy [detail if FAIL]
- E4: [PASS/FAIL] — Diagnostic report present [detail if FAIL]
- E5: [PASS/FAIL] — No workaround code [detail if FAIL]

### F: Type 2 Specifics
- F1: [PASS/FAIL/N/A] — Output table construction [detail if FAIL]
- F2: [PASS/FAIL/N/A] — Save method [detail if FAIL]
- F3: [PASS/FAIL/N/A] — Namespace applied [detail if FAIL]
- F4: [PASS/FAIL/N/A] — Lifecycle logging [detail if FAIL]

### G: Build and Deploy
- G1: [PASS/FAIL] — operator.json isWebApp [detail if FAIL]
- G2: [PASS/FAIL] — operator.json serve [detail if FAIL]
- G3: [PASS/FAIL] — index.html base href commented [detail if FAIL]
- G4: [PASS/FAIL] — .gitignore preserves build/web [detail if FAIL]
- G5: [PASS/FAIL] — build/web committed [detail if FAIL]

### H: Import Hygiene
- H1: [PASS/FAIL] — Single context import [detail if FAIL]
- H2: [PASS/FAIL] — Factory import [detail if FAIL]
- H3: [PASS/FAIL] — No stale Phase 3 stubs [detail if FAIL]

### I: DO-NOT-MODIFY Spot Check
- I1: [PASS/FAIL] — main.dart structure [detail if FAIL]
- I2: [PASS/FAIL] — service_locator.dart structure [detail if FAIL]
- I3: [PASS/FAIL] — Theme files untouched [detail if FAIL]
- I4: [PASS/FAIL] — Panel files untouched [detail if FAIL]

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

## Rules for the Reviewer

1. **Use the correct tools.** Use the **Read** tool to read files (not Bash with `cat`/`head`/`tail`). Use the **Grep** tool to search file content (not Bash with `grep`/`rg`). Use the **Glob** tool to find files (not Bash with `find`/`ls`).
2. **Read the spec first.** Read the entire functional spec before starting checks to understand the app type and data flow.
3. **Parallelize.** When reading multiple independent files or running multiple Grep searches, make parallel tool calls.
4. **Be precise.** Cite file paths and line numbers in failures.
5. **Do not fix.** Report only. Never edit app files.
6. **Do not invent requirements.** Only check what the spec and this skill define. Do not add your own opinions about code quality, naming conventions, or architecture beyond what is specified here.
7. **All failures are equal.** There is no distinction between warnings and failures. Every check is PASS or FAIL.
8. **N/A is not a loophole.** Mark a check N/A only when the skill explicitly says it can be N/A (e.g., Type 2 checks for a Type 1 app, Flow B checks for a Flow A app).
9. **Phase 2 is assumed.** This review does not re-check all Phase 2 requirements. Run the Phase 2 review separately if needed.
10. **Save the report.** Use the Write tool to save the completed report to `_local/phase-3-conformance-report.md` in the app directory.
