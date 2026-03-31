---
name: phase-4-catalog
description: Phase 4 — Translate a Phase 2 HTML mock widget (header or window) into an SDUI catalog.json template. Performs primitive gap analysis, creates missing SDUI primitives, and authors the catalog entry with real data connections.
argument-hint: "[path to Phase 2 mock widget]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Translate Phase 2 mock into SDUI catalog.json template. Mock is a visual reference — output is a JSON entry in `catalog.json` rendered by the orchestrator.

Determine widget kind from `skeleton.yaml`. Load kind-specific guide:

| Kind | Guide |
|------|-------|
| header | `integrate-header.md` |
| window | `integrate-window.md` |

## Rules

1. Mock is a visual reference, not code to port. Rebuild UI from SDUI primitives.
2. Semantic tokens only: M3 ColorScheme tokens (`primary`, `onSurface`, `surfaceContainerHigh`), TextTheme slots (`bodySmall`, `labelMedium`), spacing tokens (`xs`, `sm`, `md`, `lg`). No hex colors, pixel font sizes, numeric spacing.
3. Every node needs unique `id`: `{{widgetId}}-suffix`. Inside `ForEach`: `{{item.id}}`/`{{_index}}` suffixes.
4. Use `{{context.username}}`/`{{context.userId}}` for user-specific data.
5. Call `discover_methods(serviceName)` before writing any DataSource node. Use exact method names.
6. Output is catalog.json only. No pubspec.yaml, main.dart, or Dart code (unless creating missing primitives).

## Inputs

1. Phase 2 mock widget
2. Functional spec (Phase 1)
3. SDUI package: `/home/martin/tercen/sdui/`
4. Widget catalog: `/home/martin/tercen/tercen_ui_widgets/catalog.json`

## Step 1: Inventory the mock

For each visual element and interaction, record:

| Mock element | Description | SDUI primitive needed |
|---|---|---|

Also record: data sources (services/methods), events (EventBus channels), state (mutable state).

## Step 2: Gap analysis

Read available primitives:
1. `/home/martin/tercen/sdui/lib/src/registry/builtin_widgets.dart` — `registry.register(...)` calls
2. `/home/martin/tercen/sdui/lib/src/registry/behavior_widgets.dart` — `registry.registerScope(...)` calls
3. Existing `catalog.json` — check for reusable Tier 2 templates

Classify each element: Available? Which primitive? Output a gap list. If empty, skip to Step 4.

## Step 3: Create missing primitives

Add to `/home/martin/tercen/sdui/lib/src/registry/builtin_widgets.dart`.

### Registration pattern
```dart
registry.register('NewWidget', _buildNewWidget,
    metadata: const WidgetMetadata(
      type: 'NewWidget',
      description: 'What this widget does',
      props: {
        'propName': PropSpec(type: 'string', required: true, description: 'What this prop does'),
      },
    ));
```

### Builder pattern
```dart
Widget _buildNewWidget(SduiNode node, List<Widget> children, SduiRenderContext ctx) {
  final propValue = node.props['propName'] as String? ?? 'default';
  final size = PropConverter.to<double>(node.props['size']) ?? 24.0;
  final color = ctx.theme.resolveColor(node.props['color'] as String?);
  return YourFlutterWidget(prop: propValue, size: size, color: color,
    child: children.isEmpty ? null : children.first);
}
```

### Primitive rules
- `PropConverter` for all numeric/bool conversions — never raw `as int`
- `ctx.theme.resolveColor()` for colors, `resolveTextStyle()` for text, `resolveSpacing()` for spacing
- Keep generic and reusable
- Add `WidgetMetadata` with accurate `description` and `props`
- Run `cd /home/martin/tercen/sdui && dart analyze`
- New packages: add to `pubspec.yaml`, run `dart pub get`, import in `builtin_widgets.dart`
- New exports: update `/home/martin/tercen/sdui/lib/sdui.dart` if needed

## Step 4: Author catalog.json entry

### Metadata
```json
{
  "metadata": {
    "type": "WidgetName", "tier": 2,
    "description": "From functional spec",
    "props": { }, "emittedEvents": [ ], "acceptedActions": [ ],
    "handlesIntent": [ ]
  },
  "template": { }
}
```
- Props: only caller-facing props, not internal state
- `handlesIntent`: define if widget opens in response to intent; usually empty for headers

### Template tree primitives
- **Layout**: `Row`, `Column`, `Container`, `Expanded`, `SizedBox`, `Padding`, `Spacer`
- **Display**: `Text`, `Icon`, `CircleAvatar`, `Divider`, `Image`, `Chip`, `Tooltip`
- **Interactive**: `ElevatedButton`, `TextButton`, `IconButton`, `PopupMenu`, `TextField`, `Switch`, `Checkbox`, `DropdownButton`
- **Behavior**: `DataSource`, `ForEach`, `Action`, `ReactTo`, `Conditional`, `StateHolder`, `Sort`, `Filter`, `PromptRequired`

### Data connections

Replace mock data with `DataSource` nodes:

| Pattern | Args example |
|---------|-------------|
| `get(id)` | `["the-object-id"]` |
| `findStartKeys` (range) | `[["{{projectId}}", ""], ["{{projectId}}", "\uf000"], 50]` |
| `findKeys` (key lookup) | `[["{{context.userId}}"]]` |

### State management

Replace Provider/ChangeNotifier with `StateHolder`:
```json
{ "type": "StateHolder", "id": "{{widgetId}}-state",
  "props": { "initialState": { "dropdownOpen": false } }, "children": [ ] }
```
Mutations via `Action` publishing to `state.<nodeId>.set`:
```json
{ "type": "Action", "id": "{{widgetId}}-toggle",
  "props": { "gesture": "onTap", "channel": "state.{{widgetId}}-state.set",
    "payload": { "op": "toggle", "key": "dropdownOpen" } } }
```

### Event wiring
- Mock `eventBus.publish(channel, payload)` -> `Action` node with `channel`/`payload`
- Mock `eventBus.subscribe(channel)` -> `ReactTo` node with `channel`/`match`

## Step 5: Insert into catalog.json

1. Read `/home/martin/tercen/tercen_ui_widgets/catalog.json`
2. Add new entry to `widgets` array
3. If home widget: add/update `home` section
4. Validate JSON parses cleanly
5. No duplicate widget `type` names

Home config for auto-display widgets:
```json
{ "home": { "windows": [{ "type": "WidgetName", "id": "home-widgetname",
    "size": "medium", "align": "center", "title": "Window Title" }] } }
```
Headers render in shell's header slot, not as floating windows — see kind-specific guide.

## Step 6: Validate

1. JSON validity — must parse without error
2. Node ID uniqueness — no duplicates
3. Binding correctness — `{{...}}` must reference in-scope variables:
   - `{{props.X}}` — template root only
   - `{{data}}`, `{{loading}}`, `{{ready}}`, `{{error}}` — inside `DataSource` only
   - `{{item}}`, `{{_index}}` — inside `ForEach` only
   - `{{state}}` — inside `StateHolder` only
   - `{{context.username}}`, `{{context.userId}}`, `{{widgetId}}` — always available
4. Semantic tokens only
5. Cross-check DataSource `method` against `discover_methods` output
6. Every node `type` must be registered Tier 1 primitive or Tier 2 template

## Step 7: Clean up

1. Phase 2 mock directory retained as visual reference
2. New primitives: verify `dart analyze` passes
3. Update `_issues/session-log.md` with primitives created and gaps encountered
4. Present completed catalog entry for review

## Diagnostic: rendering issues

1. Browser console for SDUI renderer errors
2. Verify catalog loaded: `[catalog] Auto-loaded N widget(s)` in console
3. Check node IDs for duplicates
4. Check DataSource errors (wrong method names, wrong args)
5. Check scope (`{{data}}` outside DataSource? `{{item}}` outside ForEach?)
6. Check primitive registered in `registerBuiltinWidgets()`
