---
name: phase-4-catalog
description: Phase 4 — Translate a Phase 2 HTML mock widget (header or window) into an SDUI catalog.json template. Performs primitive gap analysis, creates missing SDUI primitives, and authors the catalog entry with real data connections.
argument-hint: "[path to Phase 2 mock widget]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Translate a Phase 2 mock widget into an SDUI catalog.json template. The mock is a standalone Flutter app — the output is a JSON entry in `catalog.json` that renders inside the orchestrator.

Determine the widget kind from the project's `skeleton.yaml`. Load the kind-specific guide.

| Kind | Guide |
|------|-------|
| header | `integrate-header.md` |
| window | `integrate-window.md` |

---

## Rules — read before writing any JSON

1. **The mock is a visual reference, not code to port.** Do not try to convert Dart widgets 1:1 into JSON nodes. Rebuild the UI using SDUI primitives and behavior widgets.
2. **Semantic tokens only.** No hex colors, no pixel font sizes, no numeric spacing values. Use M3 ColorScheme tokens (`primary`, `onSurface`, `surfaceContainerHigh`), TextTheme slot names (`bodySmall`, `labelMedium`), and spacing tokens (`xs`, `sm`, `md`, `lg`).
3. **Every node needs a unique `id`.** Use `{{widgetId}}-suffix` for all IDs. Inside `ForEach`, use `{{item.id}}` or `{{_index}}` suffixes.
4. **Use `{{context.username}}` and `{{context.userId}}`** for user-specific data. These are provided by the orchestrator's JWT context.
5. **Use exact service method names.** Call `discover_methods(serviceName)` via the MCP discovery server before writing any DataSource node. Copy exact method names.
6. **No standalone Flutter app.** The output is catalog.json only. No pubspec.yaml, no main.dart, no Dart code (unless creating a missing SDUI primitive).

---

## Inputs

1. Working Phase 2 mock widget (standalone Flutter app)
2. Functional spec (Phase 1 output)
3. Access to the SDUI package at `/home/martin/tercen/sdui/`
4. Access to the widget catalog at `/home/martin/tercen/tercen_ui_widgets/catalog.json`

---

## Step 1: Inventory the mock

Read the Phase 2 mock code thoroughly. For each visual element and interaction, record:

| Mock element | Description | SDUI primitive needed |
|---|---|---|
| e.g., SVG brand mark | Tercen logo with theme-aware fill | `SvgImage` or `Image` |
| e.g., identicon avatar | Hash-based geometric avatar | `CircleAvatar` or custom |
| e.g., dropdown menu | Overlay menu with items | `PopupMenu` |
| e.g., click handler | Tap to navigate home | `Action` |

Also record:
- **Data sources**: What services/methods does the mock call? (from the mock service)
- **Events**: What EventBus channels does it publish/subscribe to?
- **State**: What mutable state does it manage? (dropdown open/closed, selection, etc.)

---

## Step 2: Gap analysis

Read the available SDUI primitives:

1. Read `/home/martin/tercen/sdui/lib/src/registry/builtin_widgets.dart` — all `registry.register(...)` calls
2. Read `/home/martin/tercen/sdui/lib/src/registry/behavior_widgets.dart` — all `registry.registerScope(...)` calls
3. Read the existing `catalog.json` — check if any existing Tier 2 template provides what you need

For each element from Step 1, classify:

| Element | Available? | Primitive | Notes |
|---|---|---|---|
| Text label | YES | `Text` | — |
| SVG image | NO | — | Need to create `SvgImage` primitive |
| Popup menu | YES | `PopupMenu` | — |

**Output:** A gap list — primitives that need to be created before the catalog template can be authored.

If the gap list is empty, skip to Step 4.

---

## Step 3: Create missing primitives

For each missing primitive, create it in the SDUI package following this standardised pattern.

### 3.1 Where to add the code

Add the builder function and registration to:
`/home/martin/tercen/sdui/lib/src/registry/builtin_widgets.dart`

This keeps all Tier 1 primitives in one place. Follow the exact pattern used by existing primitives.

### 3.2 Registration pattern

```dart
registry.register('NewWidget', _buildNewWidget,
    metadata: const WidgetMetadata(
      type: 'NewWidget',
      description: 'Clear description of what this widget does',
      props: {
        'propName': PropSpec(type: 'string', required: true, description: 'What this prop does'),
        'optionalProp': PropSpec(type: 'number', defaultValue: 24),
      },
    ));
```

### 3.3 Builder function pattern

```dart
Widget _buildNewWidget(SduiNode node, List<Widget> children, SduiRenderContext ctx) {
  final propValue = node.props['propName'] as String? ?? 'default';
  final size = PropConverter.to<double>(node.props['size']) ?? 24.0;
  final color = ctx.theme.resolveColor(node.props['color'] as String?);

  return YourFlutterWidget(
    prop: propValue,
    size: size,
    color: color,
    // Wrap children if this is a container widget
    child: children.isEmpty ? null : children.first,
  );
}
```

### 3.4 Rules for new primitives

- **Use PropConverter** for all numeric/bool conversions — never raw `as int`
- **Use `ctx.theme.resolveColor()`** for color props — never hardcode hex
- **Use `ctx.theme.resolveTextStyle()`** for text style props
- **Use `ctx.theme.resolveSpacing()`** for spacing/padding props
- **Keep it generic.** The primitive should be reusable, not specific to one widget.
- **Add metadata.** Every primitive needs a `WidgetMetadata` with accurate `description` and `props`.
- **Test the build.** Run `cd /home/martin/tercen/sdui && dart analyze` after adding the primitive.

### 3.5 If new Flutter packages are needed

If the primitive requires a new Flutter package (e.g., `flutter_svg` for SVG rendering):

1. Add it to `/home/martin/tercen/sdui/pubspec.yaml`
2. Run `cd /home/martin/tercen/sdui && dart pub get`
3. Import it in `builtin_widgets.dart`

### 3.6 Exporting new primitives

If the new primitive needs types exported from the sdui package, update:
`/home/martin/tercen/sdui/lib/sdui.dart`

In most cases, primitives only use Flutter built-in types and don't need new exports.

---

## Step 4: Author the catalog.json entry

Build the catalog entry using the structure documented in `SDUI_CATALOG_AUTHORING_GUIDE.md` (attached to this project).

### 4.1 Metadata

```json
{
  "metadata": {
    "type": "WidgetName",
    "tier": 2,
    "description": "Clear description from the functional spec",
    "props": { ... },
    "emittedEvents": [ ... ],
    "acceptedActions": [ ... ],
    "handlesIntent": [ ... ]
  },
  "template": { ... }
}
```

- Copy the description from the functional spec Section 1.1
- Props: only include props that a **caller** would pass. Internal state is not a prop.
- `handlesIntent`: if this widget should open in response to an intent, define the mapping
- For header widgets: `handlesIntent` is usually empty (the header is always visible)

### 4.2 Template tree

Build the SDUI node tree that recreates the mock's visual design. Use:

- **Layout primitives**: `Row`, `Column`, `Container`, `Expanded`, `SizedBox`, `Padding`, `Spacer`
- **Display primitives**: `Text`, `Icon`, `CircleAvatar`, `Divider`, `Image`, `Chip`, `Tooltip`
- **Interactive primitives**: `ElevatedButton`, `TextButton`, `IconButton`, `PopupMenu`, `TextField`, `Switch`, `Checkbox`, `DropdownButton`
- **Behavior widgets**: `DataSource`, `ForEach`, `Action`, `ReactTo`, `Conditional`, `StateHolder`, `Sort`, `Filter`, `PromptRequired`

### 4.3 Data connections

Replace mock data with `DataSource` nodes. Use the correct args pattern:

**Pattern 1: `get(id)`**
```json
"args": ["the-object-id"]
```

**Pattern 2: `findStartKeys` (range query)**
```json
"args": [["{{projectId}}", ""], ["{{projectId}}", "\uf000"], 50]
```

**Pattern 3: `findKeys` (key lookup)**
```json
"args": [["{{context.userId}}"]]
```

Check `discover_methods` output to determine which pattern applies.

### 4.4 State management

Replace Provider/ChangeNotifier state with `StateHolder` behavior widgets:

```json
{
  "type": "StateHolder",
  "id": "{{widgetId}}-state",
  "props": {
    "initialState": { "dropdownOpen": false, "selectedItem": null }
  },
  "children": [ ... ]
}
```

Mutations via `Action` publishing to `state.<nodeId>.set`:

```json
{
  "type": "Action",
  "id": "{{widgetId}}-toggle",
  "props": {
    "gesture": "onTap",
    "channel": "state.{{widgetId}}-state.set",
    "payload": { "op": "toggle", "key": "dropdownOpen" }
  }
}
```

### 4.5 Event wiring

Replace EventBus publish/subscribe from the mock with `Action` and `ReactTo` nodes:

- Mock `eventBus.publish(channel, payload)` → `Action` node with `channel` and `payload` props
- Mock `eventBus.subscribe(channel)` → `ReactTo` node with `channel` and `match` props

---

## Step 5: Insert into catalog.json

1. Read the current `/home/martin/tercen/tercen_ui_widgets/catalog.json`
2. Add the new widget entry to the `widgets` array
3. If this is a home widget (header, default window), add/update the `home` section
4. Validate the JSON parses cleanly — use `dart run` or similar check
5. Ensure no duplicate widget `type` names in the catalog

### Home configuration

For widgets that should appear automatically when the orchestrator starts:

```json
{
  "widgets": [ ... ],
  "home": {
    "windows": [
      {
        "type": "WidgetName",
        "id": "home-widgetname",
        "size": "medium",
        "align": "center",
        "title": "Window Title"
      }
    ]
  }
}
```

Header widgets are special — they are not floating windows. The orchestrator renders them in the shell's header slot. Check the kind-specific guide for header integration details.

---

## Step 6: Validate

1. **JSON validity**: Parse catalog.json — must not error
2. **Node ID uniqueness**: Every `id` in the template must be unique (check for duplicates)
3. **Binding correctness**: Every `{{...}}` expression must reference a variable available in that scope:
   - `{{props.X}}` — only in template root (from caller)
   - `{{data}}`, `{{loading}}`, `{{ready}}`, `{{error}}` — only inside `DataSource` children
   - `{{item}}`, `{{_index}}` — only inside `ForEach` children
   - `{{state}}` — only inside `StateHolder` children
   - `{{context.username}}`, `{{context.userId}}` — always available
   - `{{widgetId}}` — always available in templates
4. **Semantic tokens**: No hex colors, no pixel font sizes, no numeric spacing
5. **Service method names**: Cross-check every DataSource `method` against `discover_methods` output
6. **SDUI primitives**: Every node `type` must be either a registered Tier 1 primitive or a Tier 2 template in the catalog

---

## Step 7: Clean up

1. The Phase 2 mock widget directory is **not deleted** — it remains as a visual reference
2. If new primitives were created in the SDUI package, verify `dart analyze` passes
3. Update `_issues/session-log.md` with any primitives created and gaps encountered
4. Present the completed catalog entry to the user for review

---

## Diagnostic: when things don't render

If the widget doesn't render correctly in the orchestrator:

1. Check browser console for SDUI renderer errors — missing widget types, binding failures
2. Verify the catalog was loaded: look for `[catalog] Auto-loaded N widget(s)` in console
3. Check node IDs for duplicates — the renderer warns about these
4. Check DataSource errors — wrong method names, wrong args patterns
5. Check scope — are you using `{{data}}` outside a DataSource? `{{item}}` outside ForEach?
6. Check the primitive exists — is the new primitive registered in `registerBuiltinWidgets()`?
