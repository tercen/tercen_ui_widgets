# Phase 2 Mock Build — Window Widget

Steps 2-7 for building a window widget. Step 1 (Copy and Rename) is in `SKILL.md`.

Source skeleton: `skeletons/window/`

For shared patterns: `_references/global-rules.md` and `_references/window-design.md`.

---

## Step 2: Define Domain Models

Read the spec's domain descriptions — typically found in the **Active** body state (Section 2.4) and **Data Source** (Section 1.4).

Create model classes in `lib/domain/models/` from the spec's domain descriptions. Keep `content_state.dart` and `window_identity.dart` unchanged — add new model files alongside them.

Update `lib/domain/services/data_service.dart` — replace the placeholder `Map<String, dynamic>` return type with your domain types. Add multiple methods if the spec requires distinct data operations (e.g. fetch teams, fetch project contents, upload file).

---

## Step 3: Build Mock Service

Read the spec's **Data Source** (Section 1.4) and **Mock Data** (Section 3).

1. Replace `mock_data_service.dart` — implement all methods from the updated `DataService` interface.
2. Return realistic mock data that exercises the full UI: multiple items, varied states, edge cases.
3. Use `Future.delayed` to simulate network latency (300-500ms).
4. If the spec requires assets (icons, sample files), put them in `assets/data/` and register in `pubspec.yaml` under `flutter: assets:`.

---

## Step 4: Build Provider

Read the spec's **Body States** (Section 2.4) and **Active** state description — every state field becomes a provider field.

**Option A: Extend `WindowStateProvider`** — if the window has simple state, extend the base class and add domain-specific fields.

**Option B: Create a dedicated provider** — if the window has complex state (tree data, filters, selection), create a new provider in `lib/presentation/providers/` that extends `WindowStateProvider`. Register it in place of the base provider in `main.dart`.

For each state field: private field + getter + setter calling `notifyListeners()`.

Keep the base class infrastructure: `loadData`, `contentState`, `errorMessage`, `identity`, EventBus integration.

Wiring: `control.onChanged → provider.setXxx(value) → notifyListeners() → Consumer rebuilds`. See `_references/global-rules.md`.

---

## Step 5: Build Toolbar

Read the spec's **Toolbar** section (Section 2.3).

The skeleton provides `WindowShell` which accepts a `toolbarActions` list. Each `ToolbarAction` has: `icon`, `tooltip`, `onPressed`, optional `label`. All buttons render with primary accent styling (there is no primary/secondary distinction).

**Icons:** Use FontAwesome 6 icons (`font_awesome_flutter` package) for all toolbar icons, not Material Icons. See `_references/window-design.md` for icon colour conventions.

In `home_screen.dart`, build the `toolbarActions` list to match the spec's toolbar buttons. Wire each button's `onPressed` to the provider or EventBus.

**Toolbar search field:** The skeleton provides `ToolbarSearchField` — a responsive search widget that collapses to 36px (icon only) when narrow and expands to a configurable max width. Use it via the toolbar's `trailing` widget slot rather than building a custom search field.

**Custom trailing controls:** For controls beyond icon buttons (dropdowns, filters), use the `WindowToolbar`'s `trailing` parameter. Action buttons go in the `toolbarActions` list (left-aligned), non-button controls go in `trailing` (right-aligned via Spacer).

**Minimum width:** Wrap the Scaffold body in `ConstrainedBox(constraints: BoxConstraints(minWidth: WindowConstants.minWidgetWidth))` to prevent layout overflow in narrow containers.

Disable buttons based on state (pass `onPressed: null` when the action is unavailable).

---

## Step 6: Build Active Content

Read the spec's **Active** body state (Section 2.4) and the **Window Structure** diagram (Section 2.1).

Replace the placeholder `ActiveState` widget in `lib/presentation/widgets/body_states/active_state.dart` with the window's actual content.

The content widget:
- Reads from the provider via `context.watch<YourProvider>()`
- Renders the spec's primary UI (tree view, list, grid, etc.)
- Handles user interactions (click, double-click, drag) by calling provider methods
- Is theme-aware: uses `AppColors` / `AppColorsDark` tokens, `AppTextStyles`, `AppSpacing`
- Uses FontAwesome icons with theme palette colours (see `_references/window-design.md`)
- Text overflow: item names use `Flexible` + `TextOverflow.ellipsis` + `maxLines: 1`
- Inline indicators: use `Flexible` on the name (not `Expanded`), flow inline after name with `AppSpacing.sm` padding

Wire the `activeContent` parameter of `WindowShell` to your content widget, OR replace `ActiveState` directly — both approaches work.

Configure the empty state in `WindowShell`: set `emptyIcon`, `emptyMessage`, `emptyDetail`, and `emptyActionLabel` to match the spec's empty state description.

Configure the error state: wire `onRetry` to trigger a data reload.

**Line weights:** All `strokeWidth` values must use `AppLineWeights.*` constants — no hardcoded numbers.

---

## Step 7: Wire EventBus Communication

Read the spec's **EventBus Communication** section (Section 2.5).

### Emitted events

For each event the window emits, add a method to the provider that publishes to the EventBus:

```dart
void emitFocusChanged({required String nodeId, required String nodeType, ...}) {
  _eventBus.publish('navigator.intent', EventPayload(
    type: 'focusChanged',
    sourceWidgetId: windowId,
    data: {'nodeId': nodeId, 'nodeType': nodeType, ...},
  ));
}
```

Use the skeleton's `WindowChannels` for standard window intents (close, maximize, openResource). Define new channel constants for domain-specific events.

### Listened events

For each event the window listens to, subscribe in the provider constructor:

```dart
_eventBus.subscribe('navigator.command').listen((payload) {
  if (payload.type == 'navigateTo') { ... }
  if (payload.type == 'refreshTree') { ... }
});
```

In mock mode, EventBus events won't arrive from a real frame — this is expected. The wiring must be in place for Phase 3.

---

## Step 8: Verify

Run `flutter run -d chrome`. Verify against the checklist below.

---

## DO NOT MODIFY

Copy these files unchanged from `skeletons/window/`.

| File | What it does |
|---|---|
| `lib/presentation/widgets/window_shell.dart` | Window frame: toolbar + divider + body |
| `lib/presentation/widgets/window_body.dart` | Body state routing (loading/empty/active/error) |
| `lib/presentation/widgets/window_toolbar.dart` | Toolbar button rendering and hover states |
| `lib/presentation/widgets/body_states/loading_state.dart` | Centred spinner |
| `lib/presentation/widgets/body_states/empty_state.dart` | Centred icon + message + action button |
| `lib/presentation/widgets/body_states/error_state.dart` | Error icon + message + retry button |
| `lib/core/theme/app_colors.dart` | Light theme colour tokens |
| `lib/core/theme/app_colors_dark.dart` | Dark theme colour tokens |
| `lib/core/theme/app_spacing.dart` | Spacing and dimension tokens |
| `lib/core/theme/app_text_styles.dart` | Typography tokens |
| `lib/core/theme/app_theme.dart` | Material 3 ThemeData (light + dark) |
| `lib/core/theme/app_line_weights.dart` | Line weight constants |
| `lib/core/constants/window_constants.dart` | Toolbar, tab, body dimension constants |
| `lib/core/widgets/tab_type_icon.dart` | Coloured square tab icon |
| `lib/domain/models/content_state.dart` | Four content state enum |
| `lib/domain/models/window_identity.dart` | Window identity (typeId, colour, label) |
| `lib/domain/services/event_bus.dart` | Channel-based pub/sub EventBus |
| `lib/domain/services/event_payload.dart` | EventPayload data class |
| `lib/domain/services/window_channels.dart` | Standard channel name constants |
| `lib/presentation/providers/theme_provider.dart` | Theme persistence |
| `lib/presentation/widgets/toolbar_search_field.dart` | Reusable responsive search field |

If toolbar rendering, body state switching, search field, or theme toggle breaks — a DO NOT MODIFY file was changed. Revert.

---

## Files You Create or Replace

| File | Action |
|---|---|
| `lib/domain/models/*.dart` | Create — domain model classes from spec |
| `lib/domain/services/data_service.dart` | Replace — update return types and methods for your domain |
| `lib/implementations/services/mock_data_service.dart` | Replace — mock implementation with realistic data |
| `lib/presentation/providers/*_provider.dart` | Create or extend — domain state extending WindowStateProvider |
| `lib/presentation/screens/home_screen.dart` | Replace — toolbar actions + active content + empty/error config |
| `lib/presentation/widgets/body_states/active_state.dart` | Replace — window's actual content |
| `lib/di/service_locator.dart` | Edit — register new services (keep guard + structure) |
| `lib/main.dart` | Edit — rename class + title, register domain provider |
| `pubspec.yaml` | Edit — name, description, assets if needed |
| `operator.json` | Edit — name, description, urls |
| `lib/core/version/version_info.dart` | Edit — gitRepo, version |
| `assets/data/*` | Create — mock data files if needed |

Delete the skeleton's demo `ActiveState` placeholder content after replacing it.

---

## Checklist

Before completing Phase 2:

- [ ] Widget runs with `flutter run -d chrome` — no errors
- [ ] All four body states work: loading (spinner), empty (icon + message + action), active (content), error (message + retry)
- [ ] Toolbar buttons match spec with correct icons, tooltips, and enabled/disabled states
- [ ] Active content matches spec wireframe and interactions
- [ ] Mock data is realistic and exercises varied states
- [ ] Provider state fields match spec's state section
- [ ] EventBus emit methods are wired (even if no listener in mock mode)
- [ ] EventBus subscribe handlers are wired (even if no publisher in mock mode)
- [ ] Window identity is set: correct typeId, typeColor, label
- [ ] Theme toggle works (light + dark)
- [ ] No modifications to DO NOT MODIFY files
- [ ] `flutter build web --wasm` succeeds

---

## Note: SDUI Integration Path (Phase 3)

Window widgets integrate via **SDUI JSON templates** in `catalog.json`, not compiled Flutter apps. The Phase 2 mock serves as a visual reference and data shape specification for the Phase 3 SDUI integrator, which will:

1. Map the mock's data service methods → `DataSource` nodes with real API service/method/args
2. Map the mock's UI components → Tier 1 primitives (`DataTable`, `DirectedGraph`, `ForEach`+`Card`, etc.)
3. Map the mock's EventBus events → `emittedEvents` and `handlesIntent` in template metadata

When writing the mock, keep the data service interface clear and well-documented — it directly informs the `DataSource` node configuration in Phase 3. Document in the mock service what Tercen API call each method represents (e.g., `// Maps to workflowService.getWorkflowGraph(workflowId)`).
