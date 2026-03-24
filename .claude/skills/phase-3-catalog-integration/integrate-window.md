# Phase 3 Catalog Integration — Window Widget

Kind-specific guide for translating a Phase 2 window mock into a catalog.json template.

---

## Window widget characteristics

- **Floating window.** Rendered by the WindowManager inside the orchestrator workspace.
- **Has window chrome.** Title bar with minimize/close is provided by the orchestrator's `FloatingWindow` — the template only defines the content inside.
- **Four body states.** Loading, empty, active, error — use `Conditional` nodes with DataSource scope variables.
- **Toolbar + body layout.** Toolbar at top, body fills remaining space.
- **Intent-driven.** Windows typically open in response to intents — define `handlesIntent` in metadata.
- **EventBus communication.** Windows publish selection events and subscribe to commands.

---

## Step 1 specifics: Inventory the window mock

Common window mock elements and their SDUI mappings:

| Mock element | Typical mock implementation | SDUI approach |
|---|---|---|
| Toolbar with action buttons | Custom toolbar row with `IconButton`s | `Row` with `IconButton` primitives |
| Toolbar search field | Custom `ToolbarSearchField` widget | `TextField` primitive or custom search primitive |
| Body state switching | `switch` on `ContentState` enum | `Conditional` nodes with `{{loading}}`, `{{ready}}`, `{{error}}` |
| Loading spinner | `CircularProgressIndicator` | `LoadingIndicator` primitive |
| Empty state | Custom widget with icon + message | `Column` with `Icon` + `Text` + `ElevatedButton` |
| Error state with retry | Custom widget with error + retry button | `Column` with `Icon` + `Text` + `ElevatedButton` |
| List/tree view | `ListView.builder` with custom tiles | `ForEach` + item layout nodes |
| Selection highlighting | `Provider` state + conditional styling | `ReactTo` with `overrideProps` |
| Data fetching | `DataService` via GetIt | `DataSource` behavior widget |
| State management | `ChangeNotifier` + `Provider` | `StateHolder` behavior widget |
| Tab type icon | Custom `TabTypeIcon` widget | `Container` with color prop |
| Font Awesome icons | `FaIcon` widget | `Icon` primitive (already supports FA) |

---

## Step 2 specifics: Common window gaps

Primitives that window widgets commonly need but may not exist:

| Element | Likely status | Resolution |
|---|---|---|
| `IconButton` | EXISTS | Use icon, channel, tooltip props |
| `PopupMenu` | EXISTS | Use for overflow menus |
| `TextField` | EXISTS | Use for search fields |
| `DataTable` | EXISTS | Use for tabular data |
| `Divider` | EXISTS | Use between toolbar and body |
| Tree view | CHECK | May need `TreeView` primitive for hierarchical data |
| Resizable columns | CHECK | May need `ResizableTable` primitive |
| Drag-and-drop | CHECK | May need `Draggable`/`DragTarget` primitives |
| Collapsible search | CHECK | May need a `SearchField` variant with collapse behavior |

Always verify against current `builtin_widgets.dart`.

---

## Step 4 specifics: Window template structure

### Standard window layout with four body states

```json
{
  "type": "Column",
  "id": "{{widgetId}}-root",
  "props": { "crossAxisAlignment": "stretch" },
  "children": [
    {
      "type": "Container",
      "id": "{{widgetId}}-toolbar",
      "props": { "color": "surfaceContainerHigh", "padding": "sm" },
      "children": [{
        "type": "Row",
        "id": "{{widgetId}}-toolbar-row",
        "children": [
          { "toolbar buttons here": "..." },
          { "type": "Spacer", "id": "{{widgetId}}-toolbar-spacer" },
          { "trailing controls here": "..." }
        ]
      }]
    },
    { "type": "Divider", "id": "{{widgetId}}-div", "props": { "height": 1, "color": "outlineVariant" } },
    {
      "type": "Expanded",
      "id": "{{widgetId}}-body",
      "children": [{
        "type": "DataSource",
        "id": "{{widgetId}}-ds",
        "props": {
          "service": "serviceName",
          "method": "methodName",
          "args": ["..."]
        },
        "children": [
          {
            "type": "Conditional", "id": "{{widgetId}}-loading",
            "props": { "visible": "{{loading}}" },
            "children": [{ "type": "Center", "id": "{{widgetId}}-spinner", "children": [{ "type": "LoadingIndicator", "id": "{{widgetId}}-li", "props": { "variant": "skeleton", "text": "Loading…" } }] }]
          },
          {
            "type": "Conditional", "id": "{{widgetId}}-error",
            "props": { "visible": "{{error}}" },
            "children": [{
              "type": "Center", "id": "{{widgetId}}-err-center",
              "children": [{
                "type": "Column", "id": "{{widgetId}}-err-col", "props": { "mainAxisAlignment": "center" },
                "children": [
                  { "type": "Icon", "id": "{{widgetId}}-err-icon", "props": { "icon": "error_outline", "size": 32, "color": "error" } },
                  { "type": "SizedBox", "id": "{{widgetId}}-err-gap", "props": { "height": 8 } },
                  { "type": "Text", "id": "{{widgetId}}-err-text", "props": { "text": "{{errorMessage}}", "textStyle": "bodySmall", "color": "error" } }
                ]
              }]
            }]
          },
          {
            "type": "Conditional", "id": "{{widgetId}}-ready",
            "props": { "visible": "{{ready}}" },
            "children": [{ "active content here": "..." }]
          }
        ]
      }]
    }
  ]
}
```

### Data list with selection highlighting

The most common window pattern — fetch data, iterate, make tappable, highlight selected:

```json
{
  "type": "ListView", "id": "{{widgetId}}-lv", "props": { "padding": "xs" },
  "children": [{
    "type": "ForEach", "id": "{{widgetId}}-fe",
    "props": { "items": "{{data}}" },
    "children": [{
      "type": "Action", "id": "tap-{{item.id}}",
      "props": {
        "gesture": "onTap",
        "channel": "navigator.focusChanged",
        "payload": { "nodeId": "{{item.id}}", "nodeType": "{{item.kind}}", "nodeName": "{{item.name}}" }
      },
      "children": [{
        "type": "ReactTo", "id": "rt-{{item.id}}",
        "props": {
          "channel": "navigator.focusChanged",
          "match": { "nodeId": "{{item.id}}" },
          "overrideProps": { "color": "primaryContainer" }
        },
        "children": [{
          "type": "Padding", "id": "pad-{{item.id}}", "props": { "padding": "sm" },
          "children": [{
            "type": "Row", "id": "row-{{item.id}}",
            "children": [
              { "type": "Icon", "id": "icon-{{item.id}}", "props": { "icon": "description", "size": 16, "color": "onSurfaceVariant" } },
              { "type": "SizedBox", "id": "gap-{{item.id}}", "props": { "width": 8 } },
              { "type": "Expanded", "id": "exp-{{item.id}}", "children": [{ "type": "Text", "id": "name-{{item.id}}", "props": { "text": "{{item.name}}", "textStyle": "bodySmall" } }] }
            ]
          }]
        }]
      }]
    }]
  }]
}
```

### Toolbar with search and actions

```json
{
  "type": "Row",
  "id": "{{widgetId}}-toolbar-row",
  "children": [
    {
      "type": "IconButton", "id": "{{widgetId}}-btn-refresh",
      "props": { "icon": "refresh", "tooltip": "Refresh", "channel": "widget.{{widgetId}}.refresh" }
    },
    {
      "type": "IconButton", "id": "{{widgetId}}-btn-add",
      "props": { "icon": "add", "tooltip": "New item", "channel": "widget.{{widgetId}}.add" }
    },
    { "type": "Spacer", "id": "{{widgetId}}-toolbar-spacer" },
    {
      "type": "TextField", "id": "{{widgetId}}-search",
      "props": { "hint": "Search…", "autofocus": false }
    }
  ]
}
```

### Detail window on double-tap

```json
{
  "type": "Action", "id": "dbl-{{item.id}}",
  "props": {
    "gesture": "onDoubleTap",
    "channel": "system.intent",
    "payload": {
      "intent": "openDocument",
      "documentId": "{{item.id}}",
      "documentName": "{{item.name}}"
    }
  },
  "children": [{ "... wrapped content ..." : "" }]
}
```

---

## Step 4.1 specifics: Intent handling

Window widgets typically respond to intents. Define `handlesIntent` in metadata:

```json
"handlesIntent": [
  {
    "intent": "openFileNavigator",
    "propsMap": { "projectId": "projectId" },
    "windowTitle": "Files: {{projectName}}",
    "windowSize": "medium",
    "windowAlign": "center"
  }
]
```

The `propsMap` maps intent parameters (from the event payload) to widget props. The IntentRouter uses this to create the window with the right props.

---

## Step 5 specifics: Window in the home configuration

Add to the `home.windows` array if this window should open on startup:

```json
"home": {
  "windows": [
    {
      "type": "FileNavigator",
      "id": "home-file-nav",
      "size": "medium",
      "align": "centerLeft",
      "title": "Files",
      "props": {
        "projectId": "default-project-id"
      }
    }
  ]
}
```

Size presets: `small`, `medium`, `large`, `full`.
Align presets: `center`, `centerLeft`, `centerRight`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight`.

---

## PromptRequired for configurable windows

If the window needs a runtime value (projectId, workflowId) that may not be in context:

```json
{
  "type": "PromptRequired",
  "id": "{{widgetId}}-prompt",
  "props": {
    "fields": [
      { "name": "projectId", "label": "Project ID", "default": "some-default-id" }
    ]
  },
  "children": [{ "... rest of template ..." : "" }]
}
```

When opened via intent (with `propsMap`), the value is injected automatically — no prompt shown. When opened without context, the user gets a configure dialog.

---

## Checklist (window-specific)

- [ ] Template has toolbar + divider + body layout
- [ ] All four body states handled: loading (`{{loading}}`), error (`{{error}}`), ready (`{{ready}}`), empty (via ForEach empty state or Conditional)
- [ ] DataSource nodes use exact method names (verified via `discover_methods`)
- [ ] DataSource args follow correct pattern (findStartKeys vs findKeys vs get)
- [ ] Selection events use `Action` + `ReactTo` pattern with matching channels and keys
- [ ] `handlesIntent` defined in metadata if window opens via intents
- [ ] Toolbar actions use `IconButton` with `channel` and `tooltip` props
- [ ] `PromptRequired` wraps template if it needs configurable IDs
- [ ] All colors use semantic tokens, not hex
- [ ] All text uses `textStyle` tokens, not `fontSize`
- [ ] All spacing uses tokens, not pixel values
- [ ] Home section updated if this is a default window
- [ ] Icon names are valid (Material icon names or Font Awesome names depending on `Icon` primitive implementation)
