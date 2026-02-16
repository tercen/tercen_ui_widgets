# Review: Phase 2 Mock Build Conformance

**This file is READ-ONLY during reviews. Do NOT modify it.**

You are a reviewer agent running in Claude Code. Your job is to read a built app, compare it against the skeleton and functional spec, and produce a conformance report.

---

## Inputs Required

Before starting, confirm you have:

1. **Built app directory** — the Phase 2 output (the app project folder)
2. **Skeleton directory** — the `skeleton/` directory from tercen-flutter-skills
3. **Functional spec** — the Phase 1 output document (markdown file)

If the user has not provided all three paths, use the AskUserQuestion tool to request missing paths.

---

## Execution Strategy

Follow this order:

1. Use the **Read** tool to read the entire functional spec file.
2. **Check Group A (DO-NOT-MODIFY files):** For each of the 12 file pairs, use the **Read** tool to read both the skeleton version and the app version. You can read multiple files in parallel by making parallel Read tool calls. Compare the content — they must be identical. Any difference is a FAIL.
3. **Check Groups B–C (structural, placeholder):** Use the **Glob** tool to verify directories exist. Use the **Read** tool to read `pubspec.yaml`, `operator.json`, `version_info.dart`, `main.dart`, and `home_screen.dart`.
4. **Check Groups D–G (spec conformance, wiring, data, UI):** Use the **Read** tool to read each section widget, the provider, and service files. Use the **Grep** tool when searching for patterns across `lib/` (e.g., checking for `setState` calls or tab widgets).
5. **Check Groups H–I (config, service locator):** Use the **Read** tool to read `web/index.html`, `.gitignore`, `analysis_options.yaml`, and `service_locator.dart`.
6. Produce the **Conformance Report** (format at the bottom of this skill).
7. Use the **Write** tool to save the report to `_local/phase-2-conformance-report.md` in the app directory.

**Parallelism:** When reading DO-NOT-MODIFY file pairs in Check Group A, read as many files in parallel as possible. Do not read them one at a time.

---

## Check Group A: DO-NOT-MODIFY File Integrity

These files must be identical to their skeleton originals. Use the **Read** tool to read each file in both the skeleton and the built app, then compare content.

| # | File (relative to project root) |
|---|---|
| A1 | `lib/presentation/widgets/left_panel/left_panel.dart` |
| A2 | `lib/presentation/widgets/left_panel/left_panel_header.dart` |
| A3 | `lib/presentation/widgets/left_panel/left_panel_section.dart` |
| A4 | `lib/presentation/widgets/app_shell.dart` |
| A5 | `lib/presentation/widgets/top_bar.dart` |
| A6 | `lib/core/theme/app_colors.dart` |
| A7 | `lib/core/theme/app_colors_dark.dart` |
| A8 | `lib/core/theme/app_spacing.dart` |
| A9 | `lib/core/theme/app_text_styles.dart` |
| A10 | `lib/core/theme/app_theme.dart` |
| A11 | `lib/core/utils/context_detector.dart` |
| A12 | `lib/presentation/providers/theme_provider.dart` |

**How to check:** Read both files with the Read tool. Compare the full text content. Any difference (even whitespace, comments, or import order) is a FAIL.

**FAIL message format:** `A[n] FAIL — [filename] differs from skeleton. [Brief description of difference, e.g. "line 42: added import"]`

---

## Check Group B: Structural Integrity

### B1: Required directories exist

Use the **Glob** tool with a pattern like `lib/domain/models/*` to verify each directory has content. These directories must exist in the built app:

- `lib/domain/models/`
- `lib/domain/services/`
- `lib/implementations/services/`
- `lib/presentation/providers/`
- `lib/presentation/screens/`
- `lib/presentation/widgets/left_panel/`
- `lib/core/theme/`
- `lib/core/utils/`
- `lib/core/version/`
- `lib/di/`
- `assets/data/`

### B2: Skeleton demo files removed

Use the **Glob** tool to check these files do NOT exist in the built app:

- `lib/presentation/widgets/left_panel/controls_section.dart`
- `lib/presentation/widgets/left_panel/buttons_section.dart`
- `lib/presentation/widgets/left_panel/settings_section.dart`
- `lib/presentation/widgets/left_panel/filters_section.dart`

Exception: if the functional spec explicitly defines a section called CONTROLS, BUTTONS, SETTINGS, or FILTERS, the corresponding file may exist — but its content must be app-specific, not the skeleton demo.

### B3: InfoSection exists

`lib/presentation/widgets/left_panel/info_section.dart` must exist. Use the **Glob** tool to verify.

### B4: Mock data files exist

`assets/data/` must contain at least one data file (not just `.gitkeep`). Use the **Glob** tool with pattern `assets/data/*` to check. Files should match what the functional spec Section 7.3 describes.

### B5: Assets registered in pubspec.yaml

Use the **Read** tool on `pubspec.yaml`. It must include `assets/data/` under `flutter: assets:`.

---

## Check Group C: Placeholder Replacement

Use the **Read** tool to read each file, then check for skeleton defaults.

### C1: pubspec.yaml

- `name:` must NOT be `skeleton_app`
- `description:` must NOT contain "skeleton"

### C2: operator.json

- `name` must NOT be `"Skeleton App"`
- `description` must NOT contain "skeleton"
- `urls` must NOT contain `skeleton_app`
- `isWebApp` must be `true`
- `isViewOnly` must be `false`
- `entryType` must be `"app"`
- `serve` must be `"build/web"`

### C3: version_info.dart

- `gitRepo` must NOT contain `skeleton_app`
- `version` must NOT be `'dev'` (should be `'0.1.0'` or later)

### C4: main.dart class name

- Must NOT contain a class named `SkeletonApp`
- The class name should reflect the app's name

### C5: home_screen.dart app identity

- `appTitle:` must NOT be `'Skeleton'` or `'Skeleton App'`
- `appIcon:` must be set (not the skeleton default)

---

## Check Group D: Spec Conformance

Use the **Read** tool to read the functional spec and cross-reference against the built code.

### D1: All sections present

Read the spec Section 4.2 (Left Panel Sections). Each section listed in the spec must have a corresponding widget file in `lib/presentation/widgets/left_panel/` AND be wired into the `sections:` list in `home_screen.dart`.

Record each section from the spec and whether it exists in code:

| Spec Section | Widget File | In sections list | PASS/FAIL |
|---|---|---|---|

### D2: Section order matches spec

The order of `PanelSection` entries in `home_screen.dart` must match the spec's section order, with INFO always last.

### D3: Section icons and labels

For each section in `home_screen.dart`:
- `label:` must be UPPERCASE
- `icon:` must be present (not null or placeholder)
- Labels and icons should correspond to what the spec describes

### D4: All controls present

For every control listed in spec Section 4.2, use the **Read** tool to read the corresponding section widget. Verify:
- The control exists in the corresponding section widget
- The control type matches the spec (dropdown, slider, toggle, etc.)
- The default value matches the spec

Record each control:

| Spec Control | Expected Type | Found In Widget | Correct Type | Correct Default | PASS/FAIL |
|---|---|---|---|---|---|

### D5: No extra controls

The app should not have controls that are not in the spec. Check each section widget for controls not listed in spec Section 4.2.

### D6: Main content matches spec

Read spec Section 4.3 (Main Panel). Use the **Read** tool to read `home_screen.dart` and verify that `_MainContent` implements what the spec describes (chart type, grid layout, image display, etc.).

### D7: Feature coverage

Read spec Section 6 (Feature Summary). Every "Must Have" feature must be implemented. List each must-have and its status:

| Must Have Feature | Implemented | PASS/FAIL |
|---|---|---|

### D8: INFO section has correct GitHub URL

Use the **Read** tool to read `info_section.dart` and `operator.json`. The `InfoSection` widget must contain a URL matching the `urls` field in `operator.json`.

---

## Check Group E: Wiring Pattern Conformance

### E1: Provider field pattern

Use the **Read** tool to read `app_state_provider.dart`. For each control state field, verify the pattern:

```dart
Type _fieldName = defaultValue;
Type get fieldName => _fieldName;
void setFieldName(Type value) {
  _fieldName = value;
  notifyListeners();
}
```

Every setter MUST call `notifyListeners()`. A missing `notifyListeners()` is a FAIL.

### E2: One field per control

Every control from spec Section 4.2 must have a corresponding field in the provider. No missing fields, no extra unexplained fields.

### E3: Wiring golden rule

For each control widget (read with the **Read** tool), verify the one-way data flow:

```
control.onChanged → provider.setXxx(value) → notifyListeners() → Consumer rebuilds
```

Check that:
- Controls call `provider.setXxx()` in their `onChanged` callbacks
- Controls read their current value from the provider (not from local state)
- No `setState()` calls for control values (all state lives in the provider)

Use the **Grep** tool to search for `setState` across all section widget files. Any `setState` used for control values is a FAIL.

### E4: Main content reads from provider

`_MainContent` must use `context.watch<AppStateProvider>()` or `Consumer<AppStateProvider>` to read state. It must NOT use `context.read<AppStateProvider>()` for values that should trigger rebuilds.

---

## Check Group F: Data Layer Conformance

### F1: DataService interface updated

Use the **Read** tool to read `lib/domain/services/data_service.dart`. It must NOT return `Map<String, dynamic>` (the skeleton placeholder). It should return domain-specific types.

### F2: Domain models exist

Use the **Glob** tool with pattern `lib/domain/models/*.dart` to verify at least one model class exists. Use the **Read** tool to verify models correspond to spec Section 2.2.

### F3: MockDataService loads real data

Use the **Read** tool to read `lib/implementations/services/mock_data_service.dart`. It must:
- Load from `assets/data/` using `rootBundle.loadString()` or `rootBundle.load()`
- NOT return hardcoded placeholder values
- Return instances of the domain model (not `Map<String, dynamic>`)

### F4: Service registered in GetIt

Use the **Read** tool to read `service_locator.dart`. It must register the `DataService` with explicit type parameter:
```dart
serviceLocator.registerLazySingleton<DataService>(() => MockDataService());
```
Not:
```dart
serviceLocator.registerLazySingleton(() => MockDataService());  // BAD — defaults to Object
```

---

## Check Group G: UI Rules

### G1: No controls in main content

Use the **Grep** tool to search `home_screen.dart` for input control widgets: `TextField`, `DropdownButton`, `DropdownButtonFormField`, `Slider`, `Switch`, `Checkbox`, `Radio`, `SegmentedButton`. Any found inside `_MainContent` is a FAIL.

Exception: if the spec explicitly describes interactive visualization elements (click-to-select, hover tooltips, zoom), those are allowed as they are feedback interactions, not input controls.

### G2: No tabs in left panel

Use the **Grep** tool to search `lib/presentation/widgets/left_panel/` for `TabBar`, `TabBarView`, `DefaultTabController`. Any occurrence is a FAIL. Sections scroll vertically as a single list.

### G3: Left panel loading pattern

Use the **Read** tool to read `home_screen.dart`. It should call `loadData()` on the provider during initialization and handle `isLoading` and `error` states.

---

## Check Group H: Configuration Files

### H1: index.html base href

Use the **Read** tool to read `web/index.html`. It must contain the base href line commented out:
```html
<!--<base href="$FLUTTER_BASE_HREF">-->
```

### H2: .gitignore preserves build/web

Use the **Read** tool to read `.gitignore`. It must contain `!build/web/` to preserve the web build output.

### H3: analysis_options.yaml exists

Use the **Glob** tool to verify `analysis_options.yaml` exists.

---

## Check Group I: service_locator.dart structure

### I1: Guard against double registration

Use the **Read** tool to read `service_locator.dart`. `setupServiceLocator` must check `if (serviceLocator.isRegistered<DataService>()) return;` (or equivalent guard) before registering.

### I2: Phase 3 readiness

`service_locator.dart` should accept optional parameters for Phase 3 integration (`useMocks`, `factory`, `taskId`), either as active parameters or commented-out stubs. The function signature must NOT block Phase 3 modifications.

---

## Conformance Report Format

Produce the report in this exact format. List every check — do not abbreviate or truncate with "...".

```markdown
# Phase 2 Conformance Report

**App:** [app name from pubspec.yaml]
**Spec:** [spec filename]
**Date:** [review date]

## Summary

| Result | Count |
|--------|-------|
| PASS | [n] |
| FAIL | [n] |
| **Total** | [n] |

**Verdict:** [CONFORMING / NON-CONFORMING]

An app is CONFORMING only if every check is PASS. Any FAIL makes it NON-CONFORMING.

---

## Results

### A: DO-NOT-MODIFY File Integrity
- A1: [PASS/FAIL] — left_panel.dart [detail if FAIL]
- A2: [PASS/FAIL] — left_panel_header.dart [detail if FAIL]
- A3: [PASS/FAIL] — left_panel_section.dart [detail if FAIL]
- A4: [PASS/FAIL] — app_shell.dart [detail if FAIL]
- A5: [PASS/FAIL] — top_bar.dart [detail if FAIL]
- A6: [PASS/FAIL] — app_colors.dart [detail if FAIL]
- A7: [PASS/FAIL] — app_colors_dark.dart [detail if FAIL]
- A8: [PASS/FAIL] — app_spacing.dart [detail if FAIL]
- A9: [PASS/FAIL] — app_text_styles.dart [detail if FAIL]
- A10: [PASS/FAIL] — app_theme.dart [detail if FAIL]
- A11: [PASS/FAIL] — context_detector.dart [detail if FAIL]
- A12: [PASS/FAIL] — theme_provider.dart [detail if FAIL]

### B: Structural Integrity
- B1: [PASS/FAIL] — Required directories [detail if FAIL]
- B2: [PASS/FAIL] — Skeleton demo files removed [detail if FAIL]
- B3: [PASS/FAIL] — InfoSection exists [detail if FAIL]
- B4: [PASS/FAIL] — Mock data files exist [detail if FAIL]
- B5: [PASS/FAIL] — Assets registered in pubspec.yaml [detail if FAIL]

### C: Placeholder Replacement
- C1: [PASS/FAIL] — pubspec.yaml [detail if FAIL]
- C2: [PASS/FAIL] — operator.json [detail if FAIL]
- C3: [PASS/FAIL] — version_info.dart [detail if FAIL]
- C4: [PASS/FAIL] — main.dart class name [detail if FAIL]
- C5: [PASS/FAIL] — home_screen.dart app identity [detail if FAIL]

### D: Spec Conformance
- D1: [PASS/FAIL] — All sections present [detail if FAIL]
  [include the section table]
- D2: [PASS/FAIL] — Section order matches spec [detail if FAIL]
- D3: [PASS/FAIL] — Section icons and labels [detail if FAIL]
- D4: [PASS/FAIL] — All controls present [detail if FAIL]
  [include the control table]
- D5: [PASS/FAIL] — No extra controls [detail if FAIL]
- D6: [PASS/FAIL] — Main content matches spec [detail if FAIL]
- D7: [PASS/FAIL] — Feature coverage [detail if FAIL]
  [include the feature table]
- D8: [PASS/FAIL] — INFO section GitHub URL [detail if FAIL]

### E: Wiring Pattern
- E1: [PASS/FAIL] — Provider field pattern [detail if FAIL]
- E2: [PASS/FAIL] — One field per control [detail if FAIL]
- E3: [PASS/FAIL] — Wiring golden rule [detail if FAIL]
- E4: [PASS/FAIL] — Main content reads from provider [detail if FAIL]

### F: Data Layer
- F1: [PASS/FAIL] — DataService interface updated [detail if FAIL]
- F2: [PASS/FAIL] — Domain models exist [detail if FAIL]
- F3: [PASS/FAIL] — MockDataService loads real data [detail if FAIL]
- F4: [PASS/FAIL] — Service registered with explicit type [detail if FAIL]

### G: UI Rules
- G1: [PASS/FAIL] — No controls in main content [detail if FAIL]
- G2: [PASS/FAIL] — No tabs in left panel [detail if FAIL]
- G3: [PASS/FAIL] — Left panel loading pattern [detail if FAIL]

### H: Configuration
- H1: [PASS/FAIL] — index.html base href [detail if FAIL]
- H2: [PASS/FAIL] — .gitignore preserves build/web [detail if FAIL]
- H3: [PASS/FAIL] — analysis_options.yaml exists [detail if FAIL]

### I: Service Locator
- I1: [PASS/FAIL] — Guard against double registration [detail if FAIL]
- I2: [PASS/FAIL] — Phase 3 readiness [detail if FAIL]

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
2. **Read all inputs first.** Read the entire functional spec before starting checks so you understand what the app should be.
3. **Parallelize reads.** When reading DO-NOT-MODIFY file pairs, make multiple parallel Read tool calls.
4. **Be precise.** Cite file paths and line numbers in failures.
5. **Do not fix.** Report only. Never edit app files.
6. **Do not invent requirements.** Only check what the spec and this skill define. Do not add your own opinions about code quality, naming conventions, or architecture beyond what is specified here.
7. **Compare literally.** For DO-NOT-MODIFY checks, compare file content exactly. Do not accept "equivalent" code.
8. **All failures are equal.** There is no distinction between warnings and failures. Every check is PASS or FAIL.
9. **Save the report.** Use the Write tool to save the completed report to `_local/phase-2-conformance-report.md` in the app directory.
