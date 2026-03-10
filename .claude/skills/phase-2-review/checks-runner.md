# Phase 2 Review -- Runner Widget Checks

**READ-ONLY. Do NOT modify this file.**

These checks apply to **runner** kind widgets. They are run in addition to the shared checks defined in `SKILL.md`.

Skeleton comparison path: `skeletons/runner/`

---

## Check Group A: Project Structure

### A1: Runner structure present

Required directories:
- `lib/core/theme/`
- `lib/core/utils/`
- `lib/core/version/`
- `lib/di/`
- `lib/domain/models/`
- `lib/domain/services/`
- `lib/implementations/services/`
- `lib/presentation/providers/`
- `lib/presentation/screens/`
- `lib/presentation/widgets/left_panel/`
- `lib/presentation/widgets/content_panel/`

### A2: Identity updated

`pubspec.yaml` name, `operator.json` name, and `version_info.dart` gitRepo must NOT contain `skeleton_type3_app`.

### A3: Assets registered

`pubspec.yaml` lists `assets/data/` and `assets/images/`. `assets/data/` has at least one file. `assets/images/running.gif` exists.

### A4: app_line_weights.dart present

`lib/core/theme/app_line_weights.dart` exists.

---

## Check Group B: DO-NOT-MODIFY Files

Each file must be **identical** to the runner skeleton (ignoring trailing whitespace). Read both versions and compare. Any non-whitespace difference: FAIL.

### B1: Theme files

`app_colors.dart`, `app_colors_dark.dart`, `app_spacing.dart`, `app_text_styles.dart`, `app_theme.dart`, `app_line_weights.dart`

### B2: Infrastructure files

`context_detector.dart`, `theme_provider.dart`

### B3: Panel mechanics

`left_panel.dart`, `left_panel_header.dart`, `left_panel_section.dart`

### B4: Runner framework files

`app_shell.dart`, `header_panel.dart`, `running_overlay.dart`

---

## Check Group C: Status Panel Sections

### C1: All 5 sections present

`home_screen.dart` must have PanelSection entries: ACTIONS, STATUS, CURRENT RUN, HISTORY, INFO.

### C2: Correct section order

Order: ACTIONS, STATUS, CURRENT RUN, HISTORY, INFO.

### C3: INFO section last

INFO must be the last PanelSection.

### C4: Section icons and labels

Every section has an icon and UPPERCASE label.

### C5: Sections match spec

Compare section names/content against spec Section 4.2.

---

## Check Group D: Header Panel Wiring

### D1: Header Panel not modified

`header_panel.dart` unchanged from skeleton (covered by B4).

### D2: onPrimaryAction wired

`home_screen.dart` passes `onPrimaryAction` callback to AppShell.

### D3: onReRun wired

`onReRun` callback passed to AppShell.

### D4: onExport wired

`onExport` callback passed to AppShell.

### D5: onDelete wired with confirmation

`onDelete` callback passed to AppShell. Must show confirmation dialog before deleting.

---

## Check Group E: Content Panel

### E1: ContentPanel mode switcher present

`content_panel.dart` switches between Input and Display based on `provider.contentMode`.

### E2: Input mode matches spec

Compare `input_content.dart` controls against spec Section 4.4. Every spec control must be present.

### E3: Input controls wired to provider

Every input control in `input_content.dart` must call `provider.updateSetting` or `provider.setXxx`.

### E4: Display mode matches spec

Compare `display_content.dart` layout against spec Section 4.5.

### E5: Display mode loads real data

Display content reads from provider/mock service -- no hardcoded placeholder text.

### E6: No controls in display mode results

Display mode must not contain state-changing input controls. Read-only filters/toggles are acceptable if spec allows.

---

## Check Group F: AppStateProvider

### F1: State machine present

`AppState` enum (running/waiting) and `ContentMode` enum (input/display) exist.

### F2: Required methods present

Has: `startRun()`, `stopRun()`, `resetApp()`, `selectHistoryEntry()`, `initiateReRun()`, `deleteRun()`.

### F3: Run history management

Maintains `RunEntry` list. `startRun()` creates entry, `deleteRun()` removes one.

### F4: Settings per control

Every spec control has a corresponding field or setting entry in the provider.

### F5: notifyListeners on every state change

Every setter/method that changes state calls `notifyListeners()`.

### F6: No Running simulation

`startRun()` transitions immediately to Display mode. Must NOT set appState to running, use timers, or simulate progress.

---

## Check Group G: Mock Data

### G1: Mock service is stateful

`mock_data_service.dart` implements the runner service interface (getRunHistory, getResults, etc.).

### G2: Real data from assets

Mock service loads from `assets/data/` via `rootBundle`. No inline placeholder data.

### G3: Pre-populated history

`getRunHistory()` returns 2+ entries with different settings.

### G4: Line weights use constants

Every `strokeWidth` in `.dart` files uses `AppLineWeights.*` -- no hardcoded numbers.

---

## Check Group H: Build Verification

### H1: No analysis errors

`flutter analyze` passes (no missing imports, undefined references).

### H2: Build succeeds

`flutter build web --wasm` succeeds (recorded; actual build run separately).

---

## Report Sections

Include these check groups in the conformance report (in addition to shared groups from SKILL.md):

```
### A: Project Structure
- A1: [PASS/FAIL] -- Runner structure present [detail if FAIL]
- A2: [PASS/FAIL] -- Identity updated [detail if FAIL]
- A3: [PASS/FAIL] -- Assets registered [detail if FAIL]
- A4: [PASS/FAIL] -- app_line_weights.dart present [detail if FAIL]

### B: DO-NOT-MODIFY Files
- B1: [PASS/FAIL] -- Theme files [list any modified files if FAIL]
- B2: [PASS/FAIL] -- Infrastructure files [list any modified files if FAIL]
- B3: [PASS/FAIL] -- Panel mechanics [list any modified files if FAIL]
- B4: [PASS/FAIL] -- Runner framework files [list any modified files if FAIL]

### C: Status Panel Sections
- C1: [PASS/FAIL] -- All 5 sections present [detail if FAIL]
- C2: [PASS/FAIL] -- Correct section order [detail if FAIL]
- C3: [PASS/FAIL] -- INFO section last [detail if FAIL]
- C4: [PASS/FAIL] -- Section icons and labels [detail if FAIL]
- C5: [PASS/FAIL] -- Sections match spec [detail if FAIL]

### D: Header Panel Wiring
- D1: [PASS/FAIL] -- Header Panel not modified [detail if FAIL]
- D2: [PASS/FAIL] -- onPrimaryAction wired [detail if FAIL]
- D3: [PASS/FAIL] -- onReRun wired [detail if FAIL]
- D4: [PASS/FAIL] -- onExport wired [detail if FAIL]
- D5: [PASS/FAIL] -- onDelete wired with confirmation [detail if FAIL]

### E: Content Panel
- E1: [PASS/FAIL] -- ContentPanel mode switcher present [detail if FAIL]
- E2: [PASS/FAIL] -- Input mode matches spec [detail if FAIL]
- E3: [PASS/FAIL] -- Input controls wired to provider [detail if FAIL]
- E4: [PASS/FAIL] -- Display mode matches spec [detail if FAIL]
- E5: [PASS/FAIL] -- Display mode loads real data [detail if FAIL]
- E6: [PASS/FAIL] -- No controls in display mode results [detail if FAIL]

### F: AppStateProvider
- F1: [PASS/FAIL] -- State machine present [detail if FAIL]
- F2: [PASS/FAIL] -- Required methods present [detail if FAIL]
- F3: [PASS/FAIL] -- Run history management [detail if FAIL]
- F4: [PASS/FAIL] -- Settings per control [detail if FAIL]
- F5: [PASS/FAIL] -- notifyListeners on every state change [detail if FAIL]
- F6: [PASS/FAIL] -- No Running simulation [detail if FAIL]

### G: Mock Data
- G1: [PASS/FAIL] -- Mock service is stateful [detail if FAIL]
- G2: [PASS/FAIL] -- Real data from assets [detail if FAIL]
- G3: [PASS/FAIL] -- Pre-populated history [detail if FAIL]
- G4: [PASS/FAIL] -- Line weights use constants [detail if FAIL]

### H: Build Verification
- H1: [PASS/FAIL] -- No analysis errors [detail if FAIL]
- H2: [PASS/FAIL] -- Build succeeds [detail if FAIL]
```
