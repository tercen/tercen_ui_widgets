# Phase 2 Review -- Panel Widget Checks

**READ-ONLY. Do NOT modify this file.**

These checks apply to **panel** kind widgets. They are run in addition to the shared checks defined in `SKILL.md`.

Skeleton comparison path: `skeletons/panel/`

---

## Check Group A: DO-NOT-MODIFY File Integrity

These files must be identical to their skeleton originals. Read each file in both the skeleton and the widget, then compare.

| # | File |
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
| A13 | `lib/core/theme/app_line_weights.dart` |

Any difference (whitespace, comments, import order) is a FAIL. Cite the line and difference.

---

## Check Group B: Structural Integrity

### B1: Required directories exist

These directories must exist and have content:

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

These files must NOT exist:

- `lib/presentation/widgets/left_panel/controls_section.dart`
- `lib/presentation/widgets/left_panel/buttons_section.dart`
- `lib/presentation/widgets/left_panel/settings_section.dart`
- `lib/presentation/widgets/left_panel/filters_section.dart`

Exception: if the functional spec explicitly defines a section called CONTROLS, BUTTONS, SETTINGS, or FILTERS, the corresponding file may exist -- but its content must be widget-specific, not the skeleton demo.

### B3: InfoSection exists

`lib/presentation/widgets/left_panel/info_section.dart` must exist.

### B4: Mock data files exist

`assets/data/` must contain at least one data file (not just `.gitkeep`). Files should match spec Section 7.3.

### B5: Assets registered in pubspec.yaml

`pubspec.yaml` must include `assets/data/` under `flutter: assets:`.

---

## Check Group D: Spec Conformance

Cross-reference spec against built code.

### D1: All sections present

Each section in spec 4.2 must have a widget file in `lib/presentation/widgets/left_panel/` AND be in the `sections:` list in `home_screen.dart`.

### D2: Section order matches spec

`PanelSection` order in `home_screen.dart` must match the spec, INFO always last.

### D3: Section icons and labels

Each section: `label:` UPPERCASE, `icon:` present, matching spec.

### D4: All controls present

Every control in spec 4.2 must exist in the corresponding section widget with correct type and default.

### D5: No extra controls

No controls in the widget that aren't in spec 4.2.

### D6: Main content matches spec

`_MainContent` in `home_screen.dart` must implement spec Section 4.3.

### D7: Feature coverage

Every "Must Have" in spec Section 6 must be implemented.

### D8: INFO section has correct GitHub URL

`info_section.dart` URL must match `operator.json` `urls` field.

---

## Check Group E: Wiring Pattern Conformance

### E1: Provider field pattern

In `app_state_provider.dart`, every control field must follow: private field + getter + setter calling `notifyListeners()`. Missing `notifyListeners()` is a FAIL.

### E2: One field per control

Every control from spec 4.2 must have a corresponding provider field. No missing, no unexplained extras.

### E3: Wiring golden rule

Verify one-way flow: `control.onChanged -> provider.setXxx(value) -> notifyListeners() -> Consumer rebuilds`. Controls must read from provider (not local state). Grep for `setState` in section widgets -- any `setState` for control values is a FAIL.

### E4: Main content reads from provider

`_MainContent` must use `context.watch<AppStateProvider>()` or `Consumer<AppStateProvider>`. Must NOT use `context.read()` for reactive values.

---

## Check Group F: Data Layer Conformance

### F1: DataService interface updated

`data_service.dart` must NOT return `Map<String, dynamic>`. Must return domain-specific types.

### F2: Domain models exist

`lib/domain/models/` must have at least one model class corresponding to spec Section 2.2.

### F3: MockDataService loads real data

`mock_data_service.dart` must load from `assets/data/` via `rootBundle`, return domain model instances, NOT hardcoded placeholders.

### F4: Service registered in GetIt

`service_locator.dart` must register with explicit type: `registerLazySingleton<DataService>(...)` -- omitting the type parameter defaults to `Object`.

---

## Check Group G: UI Rules

### G1: No controls in main content

Grep `home_screen.dart` for `TextField`, `DropdownButton`, `Slider`, `Switch`, `Checkbox`, `Radio`, `SegmentedButton` inside `_MainContent`. Any is a FAIL. Exception: spec-described read-only interactions (hover, click-to-select, zoom) are allowed.

### G2: No tabs in left panel

Grep `lib/presentation/widgets/left_panel/` for `TabBar`, `TabBarView`, `DefaultTabController`. Any is a FAIL.

### G3: Left panel loading pattern

`home_screen.dart` must call `loadData()` on provider during init and handle `isLoading`/`error` states.

### G4: Line weights use constants

Grep `lib/` for `strokeWidth`. Every occurrence must use `AppLineWeights.*` -- no hardcoded numbers. N/A if no custom painting.

---

## Report Sections

Include these check groups in the conformance report (in addition to shared groups from SKILL.md):

```
### A: DO-NOT-MODIFY File Integrity
- A1: [PASS/FAIL] -- left_panel.dart [detail if FAIL]
- A2: [PASS/FAIL] -- left_panel_header.dart [detail if FAIL]
- A3: [PASS/FAIL] -- left_panel_section.dart [detail if FAIL]
- A4: [PASS/FAIL] -- app_shell.dart [detail if FAIL]
- A5: [PASS/FAIL] -- top_bar.dart [detail if FAIL]
- A6: [PASS/FAIL] -- app_colors.dart [detail if FAIL]
- A7: [PASS/FAIL] -- app_colors_dark.dart [detail if FAIL]
- A8: [PASS/FAIL] -- app_spacing.dart [detail if FAIL]
- A9: [PASS/FAIL] -- app_text_styles.dart [detail if FAIL]
- A10: [PASS/FAIL] -- app_theme.dart [detail if FAIL]
- A11: [PASS/FAIL] -- context_detector.dart [detail if FAIL]
- A12: [PASS/FAIL] -- theme_provider.dart [detail if FAIL]
- A13: [PASS/FAIL] -- app_line_weights.dart [detail if FAIL]

### B: Structural Integrity
- B1: [PASS/FAIL] -- Required directories [detail if FAIL]
- B2: [PASS/FAIL] -- Skeleton demo files removed [detail if FAIL]
- B3: [PASS/FAIL] -- InfoSection exists [detail if FAIL]
- B4: [PASS/FAIL] -- Mock data files exist [detail if FAIL]
- B5: [PASS/FAIL] -- Assets registered in pubspec.yaml [detail if FAIL]

### D: Spec Conformance
- D1: [PASS/FAIL] -- All sections present [detail if FAIL]
  [include the section table]
- D2: [PASS/FAIL] -- Section order matches spec [detail if FAIL]
- D3: [PASS/FAIL] -- Section icons and labels [detail if FAIL]
- D4: [PASS/FAIL] -- All controls present [detail if FAIL]
  [include the control table]
- D5: [PASS/FAIL] -- No extra controls [detail if FAIL]
- D6: [PASS/FAIL] -- Main content matches spec [detail if FAIL]
- D7: [PASS/FAIL] -- Feature coverage [detail if FAIL]
  [include the feature table]
- D8: [PASS/FAIL] -- INFO section GitHub URL [detail if FAIL]

### E: Wiring Pattern
- E1: [PASS/FAIL] -- Provider field pattern [detail if FAIL]
- E2: [PASS/FAIL] -- One field per control [detail if FAIL]
- E3: [PASS/FAIL] -- Wiring golden rule [detail if FAIL]
- E4: [PASS/FAIL] -- Main content reads from provider [detail if FAIL]

### F: Data Layer
- F1: [PASS/FAIL] -- DataService interface updated [detail if FAIL]
- F2: [PASS/FAIL] -- Domain models exist [detail if FAIL]
- F3: [PASS/FAIL] -- MockDataService loads real data [detail if FAIL]
- F4: [PASS/FAIL] -- Service registered with explicit type [detail if FAIL]

### G: UI Rules
- G1: [PASS/FAIL] -- No controls in main content [detail if FAIL]
- G2: [PASS/FAIL] -- No tabs in left panel [detail if FAIL]
- G3: [PASS/FAIL] -- Left panel loading pattern [detail if FAIL]
- G4: [PASS/FAIL] -- Line weights use constants [detail if FAIL]
```
