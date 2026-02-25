---
name: phase-2-review-type3
description: Review a Phase 2 Type 3 mock app for conformance. Checks three-panel layout, Status Panel wiring, Header Panel modes, Content Panel modes, mock data, and DO-NOT-MODIFY file integrity. Produces a PASS/FAIL report.
argument-hint: "[path to app directory]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**This file is READ-ONLY during reviews. Do NOT modify it.**

Check a Type 3 mock app for conformance against Phase 2 rules.
Design rules: `_references/type3-design-summary.md` and `_references/global-rules.md`.

---

## Inputs Required

1. **App directory** — root of the Flutter project
2. **Functional spec** — the Phase 1 Type 3 spec used to build it

If not provided, use AskUserQuestion to request them.

---

## Execution Strategy

1. Read the spec, then Glob all `.dart` files in `lib/`.
2. Work through check groups A–H, reading every file before judging.
3. Save conformance report to `_local/review-2.md`.

---

## Check Group A: Project Structure

### A1: Skeleton-type3 structure present
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

Each file must be **identical** to skeleton-type3 (ignoring trailing whitespace). Read both versions and compare. Any non-whitespace difference: FAIL.

### B1: Theme files
`app_colors.dart`, `app_colors_dark.dart`, `app_spacing.dart`, `app_text_styles.dart`, `app_theme.dart`, `app_line_weights.dart`

### B2: Infrastructure files
`context_detector.dart`, `theme_provider.dart`

### B3: Panel mechanics
`left_panel.dart`, `left_panel_header.dart`, `left_panel_section.dart`

### B4: Type 3 framework files
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
Display content reads from provider/mock service — no hardcoded placeholder text.

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
`mock_data_service.dart` implements the Type 3 service interface (getRunHistory, getResults, etc.).

### G2: Real data from assets
Mock service loads from `assets/data/` via `rootBundle`. No inline placeholder data.

### G3: Pre-populated history
`getRunHistory()` returns 2+ entries with different settings.

### G4: Line weights use constants
Every `strokeWidth` in `.dart` files uses `AppLineWeights.*` — no hardcoded numbers.

---

## Check Group H: Build Verification

### H1: No analysis errors
`flutter analyze` passes (no missing imports, undefined references).

### H2: Build succeeds
`flutter build web --wasm` succeeds (recorded; actual build run separately).

---

## Conformance Report Format

```markdown
# Phase 2 Type 3 Conformance Report

**App:** [app name]
**Directory:** [path]
**Spec:** [spec filename]
**Date:** [review date]

## Summary

| Result | Count |
|--------|-------|
| PASS | [n] |
| FAIL | [n] |
| **Total** | [n] |

**Verdict:** [CONFORMING / NON-CONFORMING]

---

## Results

### A: Project Structure
- A1–A4: [PASS/FAIL each with detail if FAIL]

### B: DO-NOT-MODIFY Files
- B1–B4: [PASS/FAIL each, list any modified files]

### C: Status Panel Sections
- C1–C5: [PASS/FAIL each]

### D: Header Panel Wiring
- D1–D5: [PASS/FAIL each]

### E: Content Panel
- E1–E6: [PASS/FAIL each]

### F: AppStateProvider
- F1–F6: [PASS/FAIL each]

### G: Mock Data
- G1–G4: [PASS/FAIL each]

### H: Build Verification
- H1–H2: [PASS/FAIL each]

---

## Failures Detail

### [Check ID]: [Check name]
**Location:** [file path and line if applicable]
**Expected:** [what should be there]
**Found:** [what was found]
```

---

## Rules

1. Read every file before judging — never assume content.
2. Cite file paths and line numbers in failures.
3. Report only — do not fix.
4. Compare DO-NOT-MODIFY files against skeleton-type3 originals.
5. Save report to `_local/review-2.md`.
