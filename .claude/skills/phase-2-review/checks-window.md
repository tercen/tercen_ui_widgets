# Phase 2 Review -- Window Widget Checks

**READ-ONLY. Do NOT modify this file.**

These checks apply to **window** kind widgets. They are run in addition to the shared checks defined in `SKILL.md`.

Skeleton comparison path: `skeletons/window/`

---

## Check Group A: DO-NOT-MODIFY File Integrity

These files must be identical to their skeleton originals. Read each file in both the skeleton and the widget, then compare.

| # | File |
|---|------|
| A1 | `lib/presentation/widgets/window_shell.dart` |
| A2 | `lib/presentation/widgets/window_body.dart` |
| A3 | `lib/presentation/widgets/window_toolbar.dart` |
| A4 | `lib/presentation/widgets/body_states/loading_state.dart` |
| A5 | `lib/presentation/widgets/body_states/empty_state.dart` |
| A6 | `lib/presentation/widgets/body_states/error_state.dart` |
| A7 | `lib/core/theme/app_colors.dart` |
| A8 | `lib/core/theme/app_colors_dark.dart` |
| A9 | `lib/core/theme/app_spacing.dart` |
| A10 | `lib/core/theme/app_text_styles.dart` |
| A11 | `lib/core/theme/app_theme.dart` |
| A12 | `lib/core/theme/app_line_weights.dart` |
| A13 | `lib/core/constants/window_constants.dart` |
| A14 | `lib/core/widgets/tab_type_icon.dart` |
| A15 | `lib/domain/models/content_state.dart` |
| A16 | `lib/domain/models/window_identity.dart` |
| A17 | `lib/domain/services/event_bus.dart` |
| A18 | `lib/domain/services/event_payload.dart` |
| A19 | `lib/domain/services/window_channels.dart` |
| A20 | `lib/presentation/providers/theme_provider.dart` |
| A21 | `lib/presentation/widgets/toolbar_search_field.dart` |

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
- `lib/presentation/widgets/`
- `lib/presentation/widgets/body_states/`
- `lib/core/theme/`
- `lib/core/constants/`
- `lib/core/widgets/`
- `lib/core/version/`
- `lib/di/`

### B2: Skeleton demo ActiveState replaced

`lib/presentation/widgets/body_states/active_state.dart` must NOT contain the skeleton placeholder text "Active content placeholder. Replace this widget".

### B3: skeleton.yaml exists

`skeleton.yaml` must exist at the widget root with `kind: window`.

---

## Check Group D: Spec Conformance

Cross-reference spec against built code.

### D1: All four body states configured

`home_screen.dart` must configure `WindowShell` with:

- Empty state: `emptyIcon`, `emptyMessage`, `emptyDetail` matching spec
- Error state: `onRetry` wired to reload data
- Active state: `activeContent` set to the widget's content (or `ActiveState` replaced)

### D2: Toolbar buttons match spec

Every toolbar button from the spec's Toolbar section must appear in the `toolbarActions` list in `home_screen.dart` with correct icon, tooltip, and `isPrimary` flag.

### D3: No extra toolbar buttons

No toolbar buttons in the widget that aren't in the spec.

### D4: Active content matches spec

The active state widget must implement the spec's main content (tree view, list, etc.) including the layout described in the spec wireframe.

### D5: Toolbar button enable/disable logic

Buttons that should be conditionally enabled (per spec) must pass `onPressed: null` when inactive. Buttons that are always active must always have an `onPressed` handler.

### D6: Feature coverage

Every interaction in the spec (single-click, double-click, keyboard navigation, drag, filter, etc.) must be implemented in the active content widget or provider.

### D7: Window identity matches spec

In `main.dart`, the `WindowIdentity` must have:

- `typeId` matching the spec's window type
- `typeColor` matching the spec's tab colour
- `label` matching the spec's tab label

---

## Check Group E: Wiring Pattern Conformance

### E1: Provider state fields match spec

The provider must have a field (private + getter + setter with `notifyListeners()`) for every state item listed in the spec's State section.

### E2: No missing state fields

Every state field from the spec must exist in the provider. No omissions.

### E3: Wiring golden rule

Verify one-way flow: `control.onChanged -> provider.setXxx(value) -> notifyListeners() -> Consumer rebuilds`. Active content must read from provider (not local state). Grep for `setState` in content widgets -- any `setState` for domain state values is a FAIL. `setState` for UI-only state (hover, animation) is allowed.

### E4: Active content reads from provider

The active content widget must use `context.watch<Provider>()` or `Consumer<Provider>`. Must NOT use `context.read()` for reactive values.

---

## Check Group F: Data Layer Conformance

### F1: DataService interface updated

`data_service.dart` must NOT return `Map<String, dynamic>`. Must return domain-specific types.

### F2: Domain models exist

`lib/domain/models/` must have at least one model class corresponding to the spec's domain model section.

### F3: MockDataService implements all methods

`mock_data_service.dart` must implement every method defined in the updated `DataService` interface. Must return realistic mock data, not empty lists or placeholder values.

### F4: Service registered in GetIt

`service_locator.dart` must register with explicit type: `registerLazySingleton<DataService>(...)` -- omitting the type parameter defaults to `Object`.

---

## Check Group G: EventBus Conformance

### G1: Emitted events match spec

For every event the spec says the window emits, the provider must have a method that publishes to the EventBus with the correct channel and payload structure.

### G2: Listened events match spec

For every event the spec says the window listens to, the provider must subscribe and handle it (even if no publisher exists in mock mode).

### G3: EventBus accessed via service locator

EventBus must be obtained from `serviceLocator<EventBus>()`, not instantiated directly in the provider.

### G4: Line weights use constants

Grep `lib/` for `strokeWidth`. Every occurrence must use `AppLineWeights.*` -- no hardcoded numbers. N/A if no custom painting.

---

## Report Sections

Include these check groups in the conformance report (in addition to shared groups from SKILL.md):

```
### A: DO-NOT-MODIFY File Integrity
- A1: [PASS/FAIL] -- window_shell.dart [detail if FAIL]
- A2: [PASS/FAIL] -- window_body.dart [detail if FAIL]
- A3: [PASS/FAIL] -- window_toolbar.dart [detail if FAIL]
- A4: [PASS/FAIL] -- loading_state.dart [detail if FAIL]
- A5: [PASS/FAIL] -- empty_state.dart [detail if FAIL]
- A6: [PASS/FAIL] -- error_state.dart [detail if FAIL]
- A7: [PASS/FAIL] -- app_colors.dart [detail if FAIL]
- A8: [PASS/FAIL] -- app_colors_dark.dart [detail if FAIL]
- A9: [PASS/FAIL] -- app_spacing.dart [detail if FAIL]
- A10: [PASS/FAIL] -- app_text_styles.dart [detail if FAIL]
- A11: [PASS/FAIL] -- app_theme.dart [detail if FAIL]
- A12: [PASS/FAIL] -- app_line_weights.dart [detail if FAIL]
- A13: [PASS/FAIL] -- window_constants.dart [detail if FAIL]
- A14: [PASS/FAIL] -- tab_type_icon.dart [detail if FAIL]
- A15: [PASS/FAIL] -- content_state.dart [detail if FAIL]
- A16: [PASS/FAIL] -- window_identity.dart [detail if FAIL]
- A17: [PASS/FAIL] -- event_bus.dart [detail if FAIL]
- A18: [PASS/FAIL] -- event_payload.dart [detail if FAIL]
- A19: [PASS/FAIL] -- window_channels.dart [detail if FAIL]
- A20: [PASS/FAIL] -- theme_provider.dart [detail if FAIL]
- A21: [PASS/FAIL] -- toolbar_search_field.dart [detail if FAIL]

### B: Structural Integrity
- B1: [PASS/FAIL] -- Required directories [detail if FAIL]
- B2: [PASS/FAIL] -- Skeleton demo ActiveState replaced [detail if FAIL]
- B3: [PASS/FAIL] -- skeleton.yaml exists with kind: window [detail if FAIL]

### D: Spec Conformance
- D1: [PASS/FAIL] -- All four body states configured [detail if FAIL]
- D2: [PASS/FAIL] -- Toolbar buttons match spec [detail if FAIL]
- D3: [PASS/FAIL] -- No extra toolbar buttons [detail if FAIL]
- D4: [PASS/FAIL] -- Active content matches spec [detail if FAIL]
- D5: [PASS/FAIL] -- Toolbar button enable/disable logic [detail if FAIL]
- D6: [PASS/FAIL] -- Feature coverage [detail if FAIL]
- D7: [PASS/FAIL] -- Window identity matches spec [detail if FAIL]

### E: Wiring Pattern
- E1: [PASS/FAIL] -- Provider state fields match spec [detail if FAIL]
- E2: [PASS/FAIL] -- No missing state fields [detail if FAIL]
- E3: [PASS/FAIL] -- Wiring golden rule [detail if FAIL]
- E4: [PASS/FAIL] -- Active content reads from provider [detail if FAIL]

### F: Data Layer
- F1: [PASS/FAIL] -- DataService interface updated [detail if FAIL]
- F2: [PASS/FAIL] -- Domain models exist [detail if FAIL]
- F3: [PASS/FAIL] -- MockDataService implements all methods [detail if FAIL]
- F4: [PASS/FAIL] -- Service registered with explicit type [detail if FAIL]

### G: EventBus Conformance
- G1: [PASS/FAIL] -- Emitted events match spec [detail if FAIL]
- G2: [PASS/FAIL] -- Listened events match spec [detail if FAIL]
- G3: [PASS/FAIL] -- EventBus accessed via service locator [detail if FAIL]
- G4: [PASS/FAIL] -- Line weights use constants [detail if FAIL]
```
