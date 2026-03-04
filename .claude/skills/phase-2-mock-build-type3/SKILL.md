---
name: phase-2-mock-build-type3
description: Build a mock Type 3 Flutter web app from a Phase 1 functional spec. Copies the skeleton-type3 template, wires Status Panel sections, Header Panel, and Content Panel modes to a stateful mock data service. Produces a runnable app with no Tercen dependency.
argument-hint: "[path to functional spec]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Copy skeleton-type3, replace placeholders, wire controls to stateful mock data service.

For design rules: `_references/type3-design-summary.md` and `_references/global-rules.md`.

## Inputs

1. **Functional spec** — Phase 1 Type 3 output
2. **Skeleton-type3** — `skeleton-type3/` from tercen-flutter-skills
3. **Target directory** — new app location
4. **Mock data** — real workflow data from spec Section 7.3

---

## Step 1: Copy and Rename

Copy the entire `skeleton-type3/` directory to the target project location, then update:

### pubspec.yaml
- `name:` — new app name in snake_case (e.g., `immuno_flutter_operator`)
- `description:` — one-line description from spec Section 1.1

### operator.json
- `name` — display name from spec
- `description` — one-line description
- `urls` — GitHub repository URL

### version_info.dart (`lib/core/version/version_info.dart`)
- `gitRepo` — GitHub repository URL
- `version` — set to `'0.1.0'`

### main.dart (`lib/main.dart`)
- Rename `SkeletonType3App` class -> `YourAppNameApp`
- Update `title:` in `MaterialApp`

### home_screen.dart (`lib/presentation/screens/home_screen.dart`)
- Update `appTitle:` — display name shown in panel header
- The App icon is hardcoded in `LeftPanelHeader` — do NOT modify it

---

## Step 2: Define Domain Models

Read spec **Section 2.2 (Workflow Template)** and **Section 7.3 (Mock Data)**.

Create domain models in `lib/domain/models/` representing:
- Run settings (parameters the user provides)
- Run results (output data from the workflow)
- Any intermediate data shown in Input mode visualizations

---

## Step 3: Build Mock Service

Read spec **Section 7.3 (Mock Data)**.

### Place mock data files
Put data files in `assets/data/`. Register in `pubspec.yaml`.

### Update DataService interface (`lib/domain/services/data_service.dart`)

The Type 3 service interface is stateful:

```dart
abstract class DataService {
  Future<List<RunEntry>> getRunHistory();
  Future<Map<String, dynamic>> getResults(String runId);
  Future<Map<String, dynamic>> getInputConfig(int stage);
  Future<int> submitInput(Map<String, dynamic> settings);
}
```

Adapt the methods to your app's specific needs. Add methods if the spec requires distinct operations (e.g., file upload handling, intermediate data loading).

### Create mock service (`lib/implementations/services/mock_data_service.dart`)

The mock service:
- Loads real data from `assets/data/` — not placeholder values
- Pre-populates 2-3 run history entries with different settings and results
- Tracks current input stage in memory
- Returns real result data for each run ID
- Uses `rootBundle.loadString()` for text, `rootBundle.load()` for binary

---

## Step 4: Build AppStateProvider

Read spec **Section 4.2 (Status Panel)** and **Section 4.4 (Input Stages)**.

Replace `lib/presentation/providers/app_state_provider.dart` with:

**Keep from skeleton:**
- `AppState` enum (running/waiting)
- `ContentMode` enum (input/display)
- `RunEntry` class
- State machine methods: `startRun()`, `stopRun()`, `resetApp()`, `selectHistoryEntry()`, `initiateReRun()`, `deleteRun()`
- Header panel config: `headerHeading`, `headerActionLabel`, `setHeaderConfig()`

**Add from spec:**
- One field per user-configurable setting from the input stages
- `setXxx()` method for each field — calls `notifyListeners()`
- Input completion logic — `isInputComplete` checks required fields
- Stage navigation — `navigateToStage()` updates heading/action label per stage
- Any app-specific state (selected files, parsed data previews, etc.)

### Wiring Rules

All state flows through AppStateProvider:

```
Input:    control.onChanged → provider.updateSetting(key, value) → notifyListeners()
Actions:  button.onPressed → provider.startRun()/stopRun()/resetApp() → notifyListeners()
History:  item.onTap → provider.selectHistoryEntry(runId) → notifyListeners()
Display:  reRun.onPressed → provider.initiateReRun(runId) → notifyListeners()
```

---

## Step 5: Build Status Panel Sections

Read spec **Section 4.2**.

### Replace demo sections in `lib/presentation/widgets/left_panel/`

For each of the 5 Status Panel sections, replace the skeleton demo with your app's specific content:

| File | Spec Section | What to customize |
|------|-------------|-------------------|
| `actions_section.dart` | 4.2 ACTIONS | Button labels, enabled conditions |
| `status_section.dart` | 4.2 STATUS | State labels, step descriptions |
| `current_run_section.dart` | 4.2 CURRENT RUN | Parameter display format |
| `history_section.dart` | 4.2 HISTORY | Entry format, metadata shown |
| `info_section.dart` | — | Keep unchanged (GitHub link) |

**Control styling** — use same pattern as Type 1/2 (see `_references/global-rules.md`).

---

## Step 6: Build Content Panel — Input Mode

Read spec **Section 4.4 (Input Stages)**.

### Replace `lib/presentation/widgets/content_panel/input_content.dart`

For each input stage in the spec:

1. **Heading** — set via `provider.setHeaderConfig(heading: '...', actionLabel: '...')`
2. **Description** — at top of Content Panel body
3. **Two-column layout:**
   - Left column: form with UPPERCASE section labels, controls from spec
   - Right column: visualization (optional — remove if spec doesn't include one)
4. **Primary action** — wired to Header Panel via `onPrimaryAction` callback

If the spec has multiple input stages, use `provider.currentStage` to switch between them in `input_content.dart`.

**Form sections** use the same 11 control types and styling as Type 1/2. Reference `_references/global-rules.md` for the control type table.

---

## Step 7: Build Content Panel — Display Mode

Read spec **Section 4.5 (Display Mode)**.

### Replace `lib/presentation/widgets/content_panel/display_content.dart`

Build the results layout from the spec:
- Load result data from mock service for the selected run
- Display visualizations, tables, images, or reports as specified
- Inline display controls (filters, view toggles) if spec requires them

**Action buttons** are in the Header Panel — do NOT add Re-Run/Export/Delete to the Content Panel.

**Theme rule:** Main panel chrome is theme-aware. Graph/chart containers force white background.

---

## Step 8: Wire Header Panel

The Header Panel widget is DO-NOT-MODIFY. Configure it via:

1. **AppStateProvider** — set `headerHeading` and `headerActionLabel` when changing stages/modes
2. **home_screen.dart** — wire callbacks:
   - `onPrimaryAction` → advance input stage or start run
   - `onReRun` → `provider.initiateReRun(runId)`
   - `onExport` → implement export (or no-op in mock)
   - `onDelete` → show confirmation dialog, then `provider.deleteRun(runId)`

---

## Step 9: Wire home_screen.dart

Update `lib/presentation/screens/home_screen.dart`:

1. Replace Status Panel sections list with your app's 5 sections
2. Content Panel already switches via `ContentPanel` widget
3. Wire Header Panel callbacks as described in Step 8
4. Keep the `loadData()` call in `initState`

---

## Step 10: Verify

Run `flutter run -d chrome`. Verify against the checklist below.

---

## DO NOT MODIFY

Copy these files unchanged from skeleton-type3.

| File | What it does |
|------|-------------|
| `lib/presentation/widgets/left_panel/left_panel.dart` | Collapse, expand, resize |
| `lib/presentation/widgets/left_panel/left_panel_header.dart` | Panel header layout |
| `lib/presentation/widgets/left_panel/left_panel_section.dart` | Section header styling |
| `lib/presentation/widgets/app_shell.dart` | Three-panel frame + running overlay |
| `lib/presentation/widgets/header_panel.dart` | Header Panel with mode switching |
| `lib/presentation/widgets/running_overlay.dart` | AbsorbPointer + dimming + gif |
| `lib/core/theme/app_colors.dart` | Light theme tokens |
| `lib/core/theme/app_colors_dark.dart` | Dark theme tokens |
| `lib/core/theme/app_spacing.dart` | Spacing tokens |
| `lib/core/theme/app_text_styles.dart` | Typography tokens |
| `lib/core/theme/app_theme.dart` | Material 3 ThemeData |
| `lib/core/theme/app_line_weights.dart` | Line weight constants |
| `lib/core/utils/context_detector.dart` | Tercen embedded detection |
| `lib/presentation/providers/theme_provider.dart` | Theme persistence |

If panel collapse, resize, theme toggle, or running overlay breaks — a DO-NOT-MODIFY file was changed. Revert.

---

## Files You Create or Replace

| File | Action |
|------|--------|
| `lib/domain/models/*.dart` | Create — domain models from spec |
| `lib/domain/services/data_service.dart` | Replace — Type 3 service interface |
| `lib/implementations/services/mock_data_service.dart` | Replace — stateful mock |
| `lib/presentation/providers/app_state_provider.dart` | Replace — app state + settings |
| `lib/presentation/screens/home_screen.dart` | Replace — sections + callbacks |
| `lib/presentation/widgets/left_panel/actions_section.dart` | Replace — app-specific |
| `lib/presentation/widgets/left_panel/status_section.dart` | Replace — app-specific |
| `lib/presentation/widgets/left_panel/current_run_section.dart` | Replace — app-specific |
| `lib/presentation/widgets/left_panel/history_section.dart` | Replace — app-specific |
| `lib/presentation/widgets/content_panel/input_content.dart` | Replace — input stages |
| `lib/presentation/widgets/content_panel/display_content.dart` | Replace — results layout |
| `lib/presentation/widgets/content_panel/content_panel.dart` | Keep or replace if adding stages |
| `assets/data/*` | Create — mock data files |
| `pubspec.yaml` | Edit — name, description, assets |
| `operator.json` | Edit — name, description, urls |
| `lib/core/version/version_info.dart` | Edit — gitRepo, version |

---

## Checklist

Before completing Phase 2:

- [ ] App runs with `flutter run -d chrome` — no errors
- [ ] All 5 Status Panel sections present with correct icons and UPPERCASE labels
- [ ] Header Panel shows correct content per mode (Input/Display)
- [ ] Content Panel Input mode has all controls from spec with correct types, defaults, ranges
- [ ] Content Panel Display mode shows results layout from spec
- [ ] Every control updates state via the provider (wiring rules)
- [ ] History entries clickable and switch to Display mode
- [ ] Re-Run returns to Input mode with settings pre-loaded
- [ ] Delete shows confirmation dialog and removes run
- [ ] Run button transitions immediately to Display (no Running simulation)
- [ ] Mock data loaded from assets (not placeholder values)
- [ ] 2-3 pre-populated run history entries
- [ ] Panel collapse/expand/resize works identically to skeleton
- [ ] Theme toggle works (light + dark)
- [ ] Line weights use `AppLineWeights` constants (no hardcoded strokeWidth)
- [ ] INFO section present with correct GitHub URL
- [ ] No modifications to DO-NOT-MODIFY files
- [ ] `flutter build web --wasm` succeeds
- [ ] User has reviewed and approved
