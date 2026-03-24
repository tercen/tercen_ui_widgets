---
name: phase-3-sdui-integration
description: Convert a Phase 2 window widget design into a real SDUI JSON template in catalog.json. Handles DataSource wiring, Tier 1 primitive composition, intent routing, home config, and testing. Use after a window widget mock is approved.
argument-hint: "[path to widget spec or mock]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Convert a Phase 2 window widget mock into a real SDUI template entry in `catalog.json`.

**Architecture:** Window widgets are JSON templates composed from Tier 1 primitives. The SDUI orchestrator renders them — no compiled Dart from the widget library runs inside the orchestrator. Data fetching happens through `DataSource` nodes that call the Tercen API automatically when the orchestrator is authenticated.

---

## Rules — read before writing any template

1. **Templates are JSON, not Dart.** You are editing `catalog.json` entries, not writing Flutter code.
2. **Use exact API method names.** Verify with `discover_methods()` via the MCP discovery server before writing `DataSource` nodes. `findByOwner` vs `findTeamByOwner` will fail silently.
3. **All node IDs must be unique.** Use the `{{widgetId}}-suffix` pattern for every child node.
4. **DataSource handles auth.** The orchestrator's JWT token is what makes real API calls work. Templates don't change between mock and real mode.
5. **Compose Tier 1 primitives only.** If a template references an unknown `type`, the renderer silently drops it. Check the primitives table below.
6. **When a DataSource fails: check method name and args first.** The most common cause is an incorrect method name or wrong arg format.

---

## Inputs

1. Working mock widget (Phase 2 output) — for UI structure and data shape reference
2. Functional spec Section 1.4 (Data Source) — determines which API services/methods to call
3. A real Tercen instance with valid JWT token for testing

---

## Available Tier 1 Primitives

These are the building blocks your templates compose. Using any type not listed here will fail silently.

| Category | Widgets |
|----------|---------|
| Layout | `Row`, `Column`, `Container`, `Expanded`, `SizedBox`, `Center`, `Spacer`, `ListView`, `Grid`, `Card`, `Padding` |
| Display | `Text`, `SelectableText`, `Icon`, `Divider`, `Chip`, `CircleAvatar`, `Image`, `Tooltip`, `ProgressBar`, `Placeholder`, `LoadingIndicator` |
| Interactive | `TextField`, `ElevatedButton`, `TextButton`, `IconButton`, `Switch`, `Checkbox`, `DropdownButton` |
| Behaviour | `DataSource`, `ForEach`, `Action`, `ReactTo`, `Conditional`, `PromptRequired`, `StateHolder`, `Sort`, `Filter` |
| Domain | `DataTable`, `DirectedGraph`, `ImageViewer`, `TabbedImageViewer`, `TabbedDataTable` |
| Orchestrator | `ChatPanel` |

Domain primitives handle complex rendering (scroll-synced grids, graph layouts, image zoom/pan). Your templates compose these — the hard UI work is already done.

---

## Available API Methods

These are the methods `DataSource` nodes can call. If a method is not listed, the orchestrator's `ServiceCallDispatcher` does not support it yet.

### tableSchemaService

| Method | Args | Returns |
|--------|------|---------|
| `select` | `[schemaId, columnNames, offset, limit]` | `{nRows, columns: [{name, type, values}]}` — **column-major** |
| `selectCSV` | `[schemaId, columnNames, offset, limit, separator?, quote?, encoding?]` | `{csv: String, schemaId}` — defaults: `,`, `true`, `utf-8` |
| `getStepImages` | `[workflowId, stepId]` | `{stepName, images: [{schemaId, filename, mimetype, url}]}` |

### fileService

| Method | Args | Returns |
|--------|------|---------|
| `download` | `[fileDocumentId]` | `{content: String, fileId}` — UTF-8 text only |
| `downloadUrl` | `[fileDocumentId]` | `{url: String, fileId}` — authenticated URL for any file type |

### operatorContext (write data back)

| Method | Args | Returns |
|--------|------|---------|
| `saveTable` | `[taskId, columns]` | `{success: bool, taskId}` |
| `saveTables` | `[taskId, tablesList]` | `{success: bool, taskId}` |

Column format for write-back:
```json
[taskId, [
  {"name": ".ri", "type": "int32", "values": [0, 1, 2]},
  {"name": ".ci", "type": "int32", "values": [0, 0, 0]},
  {"name": "corrected", "type": "double", "values": [1.5, 2.3, 0.8]}
]]
```

Column types: `int32`, `double` (or `float64`), `string`.

### Generic methods (all services)

| Method | Args | Notes |
|--------|------|-------|
| `get` | `[id]` | Single object by ID |
| `list` | `[ids]` | Batch get |
| `findStartKeys` variants | `[startKey, endKey, limit?, skip?, descending?]` | Range query — method name varies per service |
| `findKeys` variants | `[keys]` | Key lookup — method name varies per service |

Service-specific handlers exist for: `projectService`, `teamService`, `workflowService`, `userService`, `projectDocumentService`, `operatorService`. Use `discover_methods()` to find exact signatures.

---

## Step 1: Analyse the mock and spec

Read the functional spec and the Phase 2 mock to determine:

1. **What data the widget needs** — which Tercen API services and methods
2. **Which domain primitives render the data** — `DataTable`, `DirectedGraph`, `ImageViewer`, etc.
3. **What user input is required** — props that need `PromptRequired` (e.g., projectId, workflowId)
4. **What events the widget emits** — for `emittedEvents` and `handlesIntent` in metadata
5. **Whether it should appear in the home config**

---

## Step 2: Verify API method names

Before writing any `DataSource` node, verify the exact method names using the MCP discovery server:

```bash
cd tercen_ui_orchestrator/server
claude --mcp-config '{"mcpServers":{"tercen":{"type":"stdio","command":"dart","args":["run","bin/mcp_discover.dart"]}}}'
```

Then:
- `discover_services()` — list all available services
- `discover_methods("tableSchemaService")` — get exact method signatures

If the MCP server is not available, use the API methods table above and cross-reference with the method names in `catalog.json` entries that already work.

---

## Step 3: Write the metadata block

Every `catalog.json` entry has a `metadata` + `template` structure.

```json
{
  "metadata": {
    "type": "MyWidget",
    "tier": 2,
    "description": "What it does — the AI reads this to decide when to use it",
    "props": {
      "projectId": {"type": "string", "required": false, "description": "Project ID"}
    },
    "emittedEvents": ["system.selection.project"],
    "acceptedActions": ["onTap"],
    "handlesIntent": [
      {
        "intent": "openProject",
        "propsMap": {"projectId": "projectId"},
        "windowTitle": "Project: {{projectName}}",
        "windowSize": "large"
      }
    ]
  },
  "template": { ... }
}
```

### Metadata fields

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Widget type name (PascalCase, unique in catalog) |
| `tier` | Yes | Always `2` for composed templates |
| `description` | Yes | What the widget does — orchestrator AI uses this for routing |
| `props` | No | Input properties with type, required flag, and description |
| `emittedEvents` | No | Event types this widget publishes |
| `acceptedActions` | No | Actions the widget handles (e.g., `onTap`) |
| `handlesIntent` | No | Intents that open this widget as a new window |

### handlesIntent

Maps an intent name to props the widget receives when opened via that intent:

| Field | Description |
|-------|-------------|
| `intent` | Intent name that triggers this widget |
| `propsMap` | Maps intent payload keys → widget prop names |
| `windowTitle` | Title bar text (supports `{{propName}}` bindings) |
| `windowSize` | `small`, `medium`, `large`, `column`, `row`, `full` |

---

## Step 4: Write the template tree

### Data flow pattern

Every data-connected template follows this pattern:

```json
{
  "type": "DataSource",
  "id": "{{widgetId}}-ds",
  "props": {
    "service": "workflowService",
    "method": "getWorkflowGraph",
    "args": ["{{workflowId}}"]
  },
  "children": [
    {"type": "Conditional", "id": "{{widgetId}}-loading", "props": {"visible": "{{loading}}"}, "children": [
      {"type": "Center", "id": "{{widgetId}}-spinner", "children": [
        {"type": "LoadingIndicator", "id": "{{widgetId}}-li", "props": {"text": "Loading..."}}
      ]}
    ]},
    {"type": "Conditional", "id": "{{widgetId}}-error", "props": {"visible": "{{error}}"}, "children": [
      {"type": "Text", "id": "{{widgetId}}-err", "props": {"text": "{{errorMessage}}", "color": "error"}}
    ]},
    {"type": "Conditional", "id": "{{widgetId}}-ready", "props": {"visible": "{{ready}}"}, "children": [
      ...actual content using {{data}}...
    ]}
  ]
}
```

`DataSource` exposes to children:
- `{{data}}` — API response
- `{{loading}}` — true while fetching
- `{{error}}` — true if call failed
- `{{errorMessage}}` — error text
- `{{ready}}` — data is available

### PromptRequired (for user-provided IDs)

Wrap the template in `PromptRequired` when the widget needs an ID the user must provide:

```json
{
  "type": "PromptRequired",
  "id": "{{widgetId}}-prompt",
  "props": {
    "fields": [
      {"name": "workflowId", "label": "Workflow ID", "default": ""}
    ]
  },
  "children": [ ...template using {{workflowId}}... ]
}
```

If the widget receives props via `handlesIntent`, the prompt is skipped when the intent provides the value.

### Template bindings

| Binding | Source |
|---------|--------|
| `{{props.myProp}}` | Caller's props (from metadata defaults or explicit values) |
| `{{widgetId}}` | The caller's node ID (use for unique child IDs) |
| `{{context.username}}` / `{{context.userId}}` | Logged-in user |
| `{{data}}` | From parent `DataSource` |
| `{{item}}` / `{{_index}}` | From parent `ForEach` |

### ForEach for lists

```json
{
  "type": "ForEach",
  "id": "{{widgetId}}-loop",
  "props": {"items": "{{data.projects}}"},
  "children": [
    {"type": "Card", "id": "{{widgetId}}-card-{{_index}}", "children": [
      {"type": "Text", "id": "{{widgetId}}-name-{{_index}}", "props": {"text": "{{item.name}}"}}
    ]}
  ]
}
```

### Multiple DataSources

Nest or sequence DataSource nodes for widgets that need data from multiple services:

```json
{
  "type": "Column",
  "id": "{{widgetId}}-root",
  "children": [
    {"type": "DataSource", "id": "{{widgetId}}-ds1", "props": {"service": "userService", "method": "get", "args": ["{{context.userId}}"]}, "children": [...]},
    {"type": "DataSource", "id": "{{widgetId}}-ds2", "props": {"service": "projectService", "method": "findStartKeys", "args": [...]}, "children": [...]}
  ]
}
```

---

## Step 5: Add to catalog.json

1. Read the current `catalog.json`
2. Add the new widget entry to the `"widgets"` array
3. Validate JSON syntax (use a JSON parser, not visual inspection)
4. If the widget should open on startup, add it to the `"home"` config

### Home configuration

```json
{
  "widgets": [ ... ],
  "home": {
    "windows": [
      {"type": "ChatPanel", "id": "chat-1", "size": "column", "align": "right", "title": "Claude Code"},
      {"type": "WorkflowViewer", "id": "wv-1", "size": "medium", "align": "center", "props": {}}
    ]
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Widget type (must match a `metadata.type` in the catalog) |
| `id` | No | Window ID (auto-generated if omitted) |
| `size` | No | `small` (30%x40%), `medium` (40%x50%), `large` (60%x70%), `column` (30%x100%), `row` (100%x40%), `full` (100%x100%) |
| `align` | No | Initial position: `center`, `left`, `right`, `top`, `bottom` |
| `title` | No | Window title bar text |
| `props` | No | Props passed to the widget |

---

## Step 6: Test

After updating `catalog.json`:

1. Push to the widget library repo (or commit locally if using a local path)
2. Restart the orchestrator server (it re-fetches the catalog on startup)
3. The Flutter app auto-loads the catalog after auth
4. Home windows open automatically

### Console log verification

Check browser console for:
- `[catalog] Auto-loaded N widget(s)` — catalog loaded
- `[home] Opening N home window(s)` — home config applied
- `[SduiRenderer] >>> expanding template "YourWidget"` — template rendering
- `[DataSource]` logs — API calls executing

### Common pitfalls

| Problem | Fix |
|---------|-----|
| `DataSource` returns unexpected results | Verify method name is exact. Check `findStartKeys` vs `findKeys` arg format. |
| Template shows nothing | Check console for `[SduiRenderer] UNKNOWN type` — widget type not registered |
| Data loads in mock but not real mode | Check orchestrator has `TERCEN_TOKEN` set. Look for `[auth]` logs. |
| `select()` data looks wrong | Column-major: each column has a `values` array. `TabbedDataTable` handles this. |
| Images don't load | Use `downloadUrl` (returns authenticated URL), not `download` (returns text). |
| `findStartKeys` vs `findKeys` | `discover_methods` output shows `(startKeys)` or `(keys)` — use matching arg format |

---

## Step 7: Verify and commit

1. Confirm the widget renders correctly with real data in the orchestrator
2. Verify all three DataSource states work (loading spinner, error display, ready content)
3. Test `handlesIntent` if defined — can other widgets open this one via intent?
4. Test `emittedEvents` — do actions publish the expected events?
5. Commit `catalog.json` and push

---

## Widget priority reference

| Widget | Status | Approach |
|--------|--------|----------|
| **workflow-viewer** | Template exists | Verify `getWorkflowGraph` with real data |
| **data-table** | Template exists | Verify `TabbedDataTable` handles column-major data |
| **file-navigator** | Template needed | `projectDocumentService` methods + `ForEach` layout |
| **home-panel** | Template needed | Multiple `DataSource` nodes for projects, user info |
| **png-viewer** | Template needed | `fileService.downloadUrl` → `ImageViewer` |
| **audit-trail** | Template needed | Use `discover_methods('activityService')` first |
| **document-editor** | Template needed | `fileService.download` for text, `downloadUrl` for binary |
| **chat-box** | Built-in | `ChatPanel` is Tier 1. Add to home config. |
| **main-header** | Template needed | Static branding: `Row` + `Image`/`Icon` + `Text` |
