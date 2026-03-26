# HomePanel — Real Implementation Plan

**Status:** Revised Draft
**Date:** 2026-03-26
**Target server:** stage.tercen.com
**Widget kind:** window (SDUI catalog.json template)

---

## Overview

Replace the placeholder HomePanel catalog.json template with a real implementation that connects to a Tercen server via authenticated service calls. The widget displays six cards (Welcome, Quick Actions, Recent Projects, Featured Apps, Help & Docs, Recent Activity) in a responsive 2-column grid, with a toolbar providing quick actions (New Project, Teams, Audit).

---

## Current State

- **catalog.json** has a HomePanel entry with a single `DataSource` calling `homeService.getHomeDashboard()` — a service that does not exist
- Template uses placeholder text bindings (`{{data.projectsSummary}}`, etc.) instead of iterable data
- `home.windows` already references HomePanel with `"size": "large", "align": "left"`
- Auth is handled: orchestrator exposes `{{context.username}}`, `{{context.userId}}`, `{{context.token}}`, `{{context.isAdmin}}`, `{{context.isDark}}`

---

## Mock → SDUI Visual Audit

The approved mock (in `widgets/home-panel/lib/presentation/`) is the source of truth.
Every visual element below is mapped to its SDUI primitive or flagged as a gap.

### Icon Mapping (Mock FontAwesome → SDUI `_iconMap` key)

| Mock Icon (FontAwesome) | Used In | SDUI Key | Status |
|---|---|---|---|
| `FontAwesomeIcons.folderOpen` | Recent Projects card title | `folder_open` | OK |
| `FontAwesomeIcons.folder` | Project row icon | `folder` | OK |
| `FontAwesomeIcons.puzzlePiece` | Featured Apps card title + row icon | `extension` or `widgets` | OK (both map to `FontAwesomeIcons.puzzlePiece`) |
| `FontAwesomeIcons.circleQuestion` | Help & Docs card title | `help` | OK (maps to `FontAwesomeIcons.circleQuestion`) |
| `FontAwesomeIcons.clockRotateLeft` | Recent Activity card title | — | **GAP: not in `_iconMap`** |
| `FontAwesomeIcons.bolt` | Quick Actions card title | — | **GAP: not in `_iconMap`** |
| `FontAwesomeIcons.plus` | New Project toolbar button | `plus` | OK |
| `FontAwesomeIcons.users` | Teams toolbar button | `people` | OK (maps to `FontAwesomeIcons.users`) |
| `FontAwesomeIcons.clipboardList` | Audit toolbar button | `checklist` or `list_check` | OK (maps to `FontAwesomeIcons.listCheck`) |
| `FontAwesomeIcons.folderPlus` | Quick Actions New Project | — | **GAP: not in `_iconMap`** |
| `FontAwesomeIcons.magnifyingGlass` | Card search toggle (off) | `magnifying_glass` | OK |
| `FontAwesomeIcons.xmark` | Card search toggle (on) | `xmark` | OK |
| `FontAwesomeIcons.arrowUpRightFromSquare` | Help link external icon | `open_in_new` or `launch` | OK |
| `FontAwesomeIcons.codeBranch` | New Project dialog git toggle | `account_tree` | OK (close enough, or add alias) |
| `FontAwesomeIcons.solidSun` | Theme toggle (light) | `sun` | OK |
| `FontAwesomeIcons.solidMoon` | Theme toggle (dark) | `moon` | OK |
| `Icons.search` (Material) | CardSearchField prefix | `search` | OK |
| `Icons.close` (Material) | CardSearchField clear | `close` | OK |
| `Icons.error_outline` | Error state | `error_outline` | OK |

**Icons to add to SDUI `_iconMap`:**
1. `clock_rotate_left` → `FontAwesomeIcons.clockRotateLeft` (Recent Activity title)
2. `bolt` → `FontAwesomeIcons.bolt` (Quick Actions title)
3. `folder_plus` → `FontAwesomeIcons.folderPlus` (Quick Actions New Project button)

### Layout Mapping (Mock Widget → SDUI Primitive)

| Mock Widget | Used For | SDUI Primitive | Status |
|---|---|---|---|
| `Column` | Root layout, card internals | `Column` | OK |
| `Row` | Toolbar, card headers, data rows | `Row` | OK |
| `Expanded` | Body area below toolbar | `Expanded` | OK |
| `Spacer` | Toolbar push-right | `Spacer` | OK |
| `Divider` | Between toolbar/body, card sections | `Divider` | OK |
| `Container` | Card wrapper, icon containers, chips | `Container` | OK (supports color, border, borderRadius, elevation, padding, width, height) |
| `SizedBox` | Fixed spacing, icon containers | `SizedBox` | OK |
| `Padding` | Card body padding | `Padding` | OK |
| `ListView` | Scrollable card area | `ListView` | OK |
| `LayoutBuilder` + responsive 2-col | Dashboard grid at ≥600px | `Grid` | **GAP: see below** |
| `IntrinsicHeight` | Equal-height card columns | — | **GAP: not available** |
| `Wrap` | Help links, Quick Action buttons | — | **GAP: not in SDUI** |
| `CircularProgressIndicator` | Loading states | `LoadingIndicator` (variant: "spinner") | OK |
| `Center` | Loading/empty/error states | `Center` | OK |

### Grid Widget Gap

The SDUI `Grid` widget exists but has critical limitations vs the mock:

1. **Uses `GridView.count`** which forces **equal aspect ratio** (default 1:1) on all children. The mock's cards have variable heights. This will either clip or distort cards.
2. **No `childAspectRatio` prop** exposed — can't override the 1:1 default.
3. **No `NeverScrollableScrollPhysics`** — Grid inside ListView will fight for scroll gestures.
4. **No responsive column collapse** — fixed `columns` count, no `minColumnWidth` breakpoint.

**Required fix:** Replace the `GridView.count` implementation with a `LayoutBuilder` + `Row`/`Column` approach (matching the mock's `IntrinsicHeight` + `Row` pattern), or add `childAspectRatio` + `physics` props and a responsive column calculation.

### Text & Typography Mapping

| Mock Style | Font Size | Weight | SDUI `textStyle` Token | Status |
|---|---|---|---|---|
| `AppTextStyles.h1` | 24px | w600 | `headlineLarge` | OK |
| `AppTextStyles.h2` | 20px | w600 | `headlineMedium` | OK |
| `AppTextStyles.h3` | 16px | w600 | `headlineSmall` | OK |
| `AppTextStyles.body` | 14px | w400 | `bodyMedium` | OK |
| `AppTextStyles.bodySmall` | 12px | w400 | `bodySmall` | OK |
| `AppTextStyles.label` | 14px | w500 | `labelLarge` | OK |
| `AppTextStyles.labelSmall` | 12px | w500 | `labelSmall` | OK |
| `AppTextStyles.sectionHeader` | 12px | w600 | `sectionHeader` | OK |
| Activity type chip text | 10px | w600 | — | **GAP: `micro` is 8px; no 10px token. Use `fontSize` override on `bodySmall`** |

### Color Mapping (Mock Semantic → SDUI Color Token)

All colors must use SDUI semantic tokens, never hardcoded hex values.

| Mock Color | Purpose | SDUI Token | Status |
|---|---|---|---|
| `AppColors.primary` | Icons, active states, links | `primary` | OK |
| `AppColors.primarySurface` | Card highlight bg, button hover | `primaryContainer` | OK |
| `AppColors.primaryBg` | Welcome card bg | `primaryContainer` (lighter variant needed?) | Check |
| `AppColors.textPrimary` | Main text | `onSurface` | OK |
| `AppColors.textSecondary` | Secondary text | `onSurfaceVariant` | OK |
| `AppColors.textTertiary` | Tertiary/muted text | `textTertiary` | OK |
| `AppColors.textMuted` | Muted text, hints | `onSurfaceMuted` | OK |
| `AppColors.textDisabled` | Disabled text | `onSurfaceDisabled` | OK |
| `AppColors.surface` | Card background | `surface` | OK |
| `AppColors.neutral100` / card header bg | Card header background | `surfaceContainerLow` | OK |
| `AppColors.surfaceElevated` | Hover row bg (dark mode) | `surfaceContainerHigh` | OK |
| `AppColors.neutral50` | Hover row bg (light mode) | `surfaceContainerLowest` | OK |
| `AppColors.border` | Card borders | `outline` or `border` | OK |
| `AppColors.borderSubtle` | Internal borders | `outlineVariant` or `borderSubtle` | OK |
| `AppColors.success` | Create/complete activity chip | `success` | OK |
| `AppColors.error` | Delete activity chip, error icon | `error` | OK |
| `AppColors.warning` | Run activity chip | `warning` | OK |
| `AppColors.info` | Update activity chip | `info` | OK |
| `AppColors.successLight` | Create chip bg | `successContainer` | OK |
| `AppColors.errorLight` | Delete chip bg | `errorContainer` | OK |
| `AppColors.warningLight` | Run chip bg | `warningContainer` | OK |
| `AppColors.infoLight` | Update chip bg | `infoContainer` | OK |
| `AppColors.link` | Hyperlink text | `link` | OK |

### Interaction & Behavior Mapping

| Mock Interaction | SDUI Behavior | Status |
|---|---|---|
| Tap to navigate (project row, activity row) | `Action` → EventBus publish | OK |
| Page size selector (5/10/20 buttons) | `StateHolder` + `Action` emitting `state.<id>.set` | OK |
| Card search field (real-time filter) | `TextField` + `Filter` behavior | **GAP: see below** |
| Hover background on rows | `MouseRegion` in mock | **GAP: `Action` has no hover styling** |
| Hyperlink underline on hover | Text decoration in mock | **GAP: `Text` has no `decoration` prop** |
| Responsive column collapse at 600px | `LayoutBuilder` in mock | **GAP: `Grid` has no responsive breakpoint** |
| New Project dialog (form + dropdown) | Native Flutter dialog | **Not SDUI — orchestrator handles this** |
| External URL open (Help links) | `system.intent` → orchestrator | OK (needs `openUrl` intent handler) |

### Card Search + Filter Gap

The mock has a `CardSearchField` widget in each card that filters rows in real-time. In SDUI this requires:

1. A `TextField` with a value that can be read by other widgets
2. A `Filter` behavior widget that uses that value as its `contains` prop

Current SDUI `Filter` takes `contains` as a static prop. To work with live TextField input:
- **Option A:** TextField emits value changes to EventBus → Filter listens on same channel and uses event payload as `contains`. Requires Filter to support `refreshOn` or a reactive `contains` binding.
- **Option B:** Use `StateHolder` as intermediary — TextField emits to `state.<id>.set`, Filter reads `{{state}}` as `contains`. Requires Filter's `contains` prop to support template expressions.
- **Option C (simplest):** Defer card search to a later iteration. Ship without search, add it when SDUI Filter supports reactive bindings.

**Recommendation:** Option C for initial release. Card search is a polish feature, not core.

### Hover & Underline Gaps

The mock shows:
- Row hover: background color change on `MouseRegion` enter/exit
- Link hover: text underline on mouse enter

Neither is supported by SDUI `Action` or `Text`. Two options:
1. **Add hover props to Action**: `hoverColor` prop that wraps child in `MouseRegion` + animated `Container`
2. **Accept visual difference:** Ship without hover states; functional behavior (tap to navigate) works fine

**Recommendation:** Add `hoverColor` prop to `Action` widget — it's a small change with high visual impact. Defer text underline (lower priority).

---

## SDUI Gaps Summary (Must Fix Before Implementation)

| # | Gap | SDUI Component | Change Required | Priority |
|---|---|---|---|---|
| G1 | Missing icons: `clock_rotate_left`, `bolt`, `folder_plus` | `_iconMap` in builtin_widgets.dart | Add 3 entries | **P0** |
| G2 | Grid forces equal aspect ratio, not responsive | `_buildGrid` in builtin_widgets.dart | Rewrite to use `LayoutBuilder` + `Row`/`Column` with `IntrinsicHeight`, add `minColumnWidth` prop | **P0** |
| G3 | ForEach has no `limit`/`offset` | `_buildForEach` in behavior_widgets.dart | Add optional `limit` and `offset` props with template expression support | **P0** |
| G4 | WindowState has no object-form size | `window_state.dart` | Support `{"width": 0.70, "height": 1.0}` alongside string presets | **P1** |
| G5 | Action has no hover visual feedback | `_buildAction` in behavior_widgets.dart | Add optional `hoverColor` prop | **P1** |
| G6 | No `Wrap` layout widget | builtin_widgets.dart | Add `Wrap` widget with `spacing` and `runSpacing` props | **P1** |
| G7 | Text has no `decoration` prop (underline) | `_buildText` in builtin_widgets.dart | Add `decoration` prop (`none`, `underline`, `lineThrough`) | **P2** |
| G8 | Filter `contains` not reactive to TextField input | `_buildFilter` in behavior_widgets.dart | Support template expressions in `contains` prop, or add `refreshOn` | **P2** (deferred — ship without card search) |

---

## Changes Required

### 1. SDUI Primitives (`/home/martin/tercen/sdui`)

#### 1a. Add missing icons (G1)

**File:** `lib/src/registry/builtin_widgets.dart`, `_iconMap`

```dart
'clock_rotate_left': FontAwesomeIcons.clockRotateLeft,
'bolt': FontAwesomeIcons.bolt,
'folder_plus': FontAwesomeIcons.folderPlus,
```

#### 1b. Rewrite Grid widget for variable-height children (G2)

**File:** `lib/src/registry/builtin_widgets.dart`, `_buildGrid`

Replace `GridView.count` with a responsive layout:

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `columns` | int | 2 | Max columns at full width |
| `minColumnWidth` | double | 300 | Collapse threshold per column |
| `spacing` | double | 16 | Horizontal gap |
| `runSpacing` | double | 16 | Vertical gap |

**Behavior:**
- `LayoutBuilder` measures available width
- Computes actual column count: `min(columns, max(1, (width / minColumnWidth).floor()))`
- Distributes children across columns round-robin
- Each column is `Expanded` inside a `Row`, children in a `Column`
- Wraps row in `IntrinsicHeight` so columns match height per row
- Adds `NeverScrollableScrollPhysics` (parent ListView handles scroll)

#### 1c. Extend ForEach with `limit` and `offset` (G3)

**File:** `lib/src/registry/behavior_widgets.dart`

Add to ForEach props:

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `limit` | int | 0 (unlimited) | Max items to render |
| `offset` | int | 0 | Items to skip |

Both must support template expressions (e.g., `"{{state}}"`) for StateHolder-driven pagination.

#### 1d. Extend WindowState for object-form size (G4)

**File:** `lib/src/window/window_state.dart`

Support `"size": {"width": 0.70, "height": 1.0}` alongside existing string presets.

#### 1e. Add `hoverColor` to Action (G5)

**File:** `lib/src/registry/behavior_widgets.dart`, `_buildAction`

Add optional `hoverColor` prop. When set, wrap child in `StatefulBuilder` with `MouseRegion` that toggles an animated `Container` background color on hover.

#### 1f. Add Wrap widget (G6)

**File:** `lib/src/registry/builtin_widgets.dart`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `spacing` | double | 8 | Horizontal gap |
| `runSpacing` | double | 8 | Vertical gap |
| `alignment` | string | "start" | Main axis alignment |

Maps directly to Flutter's `Wrap` widget.

#### 1g. Add `decoration` to Text (G7) — P2, defer if needed

Add optional `decoration` prop to `_buildText`: values `none`, `underline`, `lineThrough`.

---

### 2. Orchestrator (`/home/martin/tercen/tercen_ui_orchestrator`)

#### 2a. Enrich user context

**File:** `lib/main.dart`, `_fetchUserRoles()` or `_setUserContext()`

Add after existing context:
- `displayName` — `user.name.isNotEmpty ? user.name : username`
- `email` — `user.email`
- `teams` — list of team names from `teamService`

#### 2b. Dispatcher handlers — already exist

Verified in dispatcher:
- `projectService.recentProjects` — **already registered**, takes `[username]`
- `documentService.getLibrary` — **already registered** (not `getTercenAppLibrary`), takes `(query, authors[], folders[], kinds[], offset, limit)`
- `activityService` — **already has base CRUD + `findStartKeys`**, will work for activity queries

**No dispatcher changes needed.**

#### 2c. Handle `createProject` intent

**File:** `lib/main.dart`

Listen on `system.intent` for `"createProject"`. Show native Flutter dialog (SDUI has no form/dialog primitive). Dialog fields from mock:
- Project name (required)
- Team dropdown (searchable, from `context.teams`)
- Description (optional)
- Public toggle
- Collapsible git section (repo URL, branch, tag, commit, token)

On submit: call `projectService.create()`, then emit `openProject` intent.

#### 2d. Handle `openProject` intent routing

Ensure FileNavigator catalog entry has `handlesIntent` for `openProject`.

#### 2e. Handle `openUrl` intent

Listen for `"openUrl"` intent, call `url_launcher` or `html.window.open()` with the URL from payload.

---

### 3. Catalog Template (`/home/martin/tercen/tercen_ui_widgets/catalog.json`)

#### 3a. Update home window config

```json
{"type": "HomePanel", "id": "home-panel", "size": {"width": 0.70, "height": 1.0}, "align": "left", "title": "Home"}
```

#### 3b. Rewrite HomePanel template

**Structure matching the approved mock:**

```
WindowShell (root — provides toolbar frame)
├── toolbarActions: [
│     {icon: "plus", label: "New Project", channel: "system.intent", payload: {intent: "createProject"}},
│     {icon: "people", label: "Teams", channel: "system.intent", payload: {intent: "showTeams"}},
│     {icon: "checklist", label: "Audit", channel: "system.intent", payload: {intent: "showAudit"}}
│   ]
└── body:
    ListView (padding: 16)
    ├── [Card 0] Welcome Card
    │   └── Container (color: "primaryContainer", borderColor: "primaryContainer", borderRadius: 8)
    │       └── Padding (24h, 16v)
    │           └── Text "Welcome, {{context.displayName}}" (textStyle: "headlineMedium", color: "primary")
    │
    ├── SizedBox (height: 16)
    │
    ├── [Card 1] Quick Actions
    │   └── Container (card styling)
    │       ├── Row (header: Icon "bolt" + Text "Quick Actions")
    │       ├── Divider
    │       └── Padding
    │           └── Wrap (spacing: 8, runSpacing: 8)               ← NEEDS G6
    │               ├── Action → Container+Row [Icon "folder_plus" + Text "New Project"]  ← NEEDS G1
    │               ├── Action → Container+Row [Icon "people" + Text "Teams"]
    │               └── Action → Container+Row [Icon "checklist" + Text "Audit"]
    │
    ├── SizedBox (height: 16)
    │
    └── Grid (columns: 2, minColumnWidth: 300, spacing: 16, runSpacing: 16)  ← NEEDS G2
        ├── [Card 2] Recent Projects
        │   └── Container (card styling: color "surface", borderColor "outline", borderRadius 8, elevation 1)
        │       ├── Container (header: color "surfaceContainerLow", borderColor "outlineVariant")
        │       │   └── Row
        │       │       ├── Icon "folder_open" (size: 14, color: "primary")
        │       │       ├── SizedBox (width: 8)
        │       │       └── Text "Recent Projects" (textStyle: "headlineSmall")
        │       ├── StateHolder (id: "hp-proj-ps", initial: 5)
        │       │   └── DataSource
        │       │       ├── service: "projectService"
        │       │       ├── method: "recentProjects"
        │       │       ├── args: ["{{context.username}}"]
        │       │       ├── refreshOn: "home-panel.refresh"
        │       │       └── children:
        │       │           ├── Conditional (visible: "{{loading}}") → Center → LoadingIndicator
        │       │           ├── Conditional (visible: "{{error}}") → Center → Text "{{errorMessage}}"
        │       │           └── Conditional (visible: "{{ready}}")
        │       │               └── ForEach (items: "{{data}}", limit: "{{state}}")  ← NEEDS G3
        │       │                   └── Action (channel: "system.intent",
        │       │                   │   payload: {intent: "openProject", projectId: "{{item.id}}", projectName: "{{item.name}}"},
        │       │                   │   hoverColor: "surfaceContainerLowest")          ← NEEDS G5
        │       │                   └── Padding (padding: 8)
        │       │                       └── Row
        │       │                           ├── Container (width: 32, height: 32, borderColor: "outlineVariant", borderRadius: 8)
        │       │                           │   └── Center → Icon "folder" (size: 14, color: "primary")
        │       │                           ├── SizedBox (width: 8)
        │       │                           ├── Expanded
        │       │                           │   └── Column
        │       │                           │       ├── Text "{{item.name}}" (textStyle: "labelLarge")
        │       │                           │       └── Text "{{item.owner}}" (textStyle: "bodySmall", color: "textTertiary")
        │       │                           └── Text "{{item.lastModifiedDate}}" (textStyle: "bodySmall", color: "textTertiary")
        │       ├── Divider
        │       └── Padding (padding: 8)
        │           └── Row (footer)
        │               ├── Text "Show:" (textStyle: "bodySmall")
        │               ├── Action → TextButton "5"  (channel: "state.hp-proj-ps.set", payload: {value: 5})
        │               ├── Action → TextButton "10" (channel: "state.hp-proj-ps.set", payload: {value: 10})
        │               └── Action → TextButton "20" (channel: "state.hp-proj-ps.set", payload: {value: 20})
        │
        ├── [Card 3] Featured Apps
        │   Same card structure as Recent Projects:
        │   - Header icon: "extension" (maps to puzzlePiece)
        │   - DataSource: service "documentService", method "getLibrary", args: ["", [], [], [], 0, 50]
        │   - ForEach row: Icon "extension" + name + description (textStyle: "bodySmall")
        │   - Action payload: {intent: "openApp", appId: "{{item.id}}", appName: "{{item.name}}"}
        │   - StateHolder id: "hp-apps-ps", initial: 5
        │
        ├── [Card 4] Help & Docs
        │   └── Container (card styling)
        │       ├── Container (header: Icon "help" + Text "Help & Documentation")
        │       └── Padding
        │           └── Wrap (spacing: 16, runSpacing: 8)               ← NEEDS G6
        │               ├── Action → Row [Icon "open_in_new" (size: 12) + Text "Documentation"]
        │               │   channel: "system.intent", payload: {intent: "openUrl", url: "https://docs.tercen.com"}
        │               ├── Action → Row [Icon "open_in_new" + Text "Getting Started"]
        │               │   channel: "system.intent", payload: {intent: "openUrl", url: "https://docs.tercen.com/getting-started"}
        │               ├── Action → Row [Icon "open_in_new" + Text "Tutorials"]
        │               │   channel: "system.intent", payload: {intent: "openUrl", url: "https://docs.tercen.com/tutorials"}
        │               └── Action → Row [Icon "open_in_new" + Text "Community"]
        │                   channel: "system.intent", payload: {intent: "openUrl", url: "https://community.tercen.com"}
        │
        └── [Card 5] Recent Activity
            └── Container (card styling)
                ├── Container (header: Icon "clock_rotate_left" + Text "Recent Activity")  ← NEEDS G1
                ├── StateHolder (id: "hp-activity-ps", initial: 10)
                │   └── DataSource
                │       ├── service: "activityService"
                │       ├── method: "findStartKeys"
                │       ├── args: ["by_user_and_date", ["{{context.userId}}", ""], ["{{context.userId}}", "\uf000"], 100, 0, true]
                │       ├── refreshOn: "home-panel.refresh"
                │       └── Conditional (visible: "{{ready}}")
                │           └── ForEach (items: "{{data}}", limit: "{{state}}")  ← NEEDS G3
                │               └── Action (hoverColor: "surfaceContainerLowest")  ← NEEDS G5
                │                   └── Padding (padding: 8)
                │                       └── Row
                │                           ├── [Color square — TabTypeIcon pattern]
                │                           │   Container (width: 8, height: 8, borderRadius: 2)
                │                           │   Color per type via stacked Conditionals:
                │                           │   - Conditional visible:"{{item.type}}==create"   → color:"success"
                │                           │   - Conditional visible:"{{item.type}}==update"   → color:"info"
                │                           │   - Conditional visible:"{{item.type}}==delete"   → color:"error"
                │                           │   - Conditional visible:"{{item.type}}==run"      → color:"warning"
                │                           │   - Conditional visible:"{{item.type}}==complete" → color:"success"
                │                           │   NOTE: Conditional equality matching ("==") is unverified in SDUI.
                │                           │   If not supported, need to extend Conditional or find alternative.
                │                           ├── SizedBox (width: 8)
                │                           ├── Text "{{item.type}}" (textStyle: "bodySmall", color: "onSurfaceMuted")
                │                           ├── SizedBox (width: 8)
                │                           ├── Expanded (flex: 3) → Text "{{item.objectName}}"
                │                           ├── Expanded (flex: 1) → Text "{{item.userName}}"
                │                           ├── Expanded (flex: 2) → Text "{{item.projectName}}"
                │                           └── SizedBox (width: 72) → Text "{{item.date}}" (textStyle: "bodySmall")
                ├── Divider
                └── Row (footer: page size 5|10|20, same pattern as Recent Projects)
```

---

## Intent Summary

| Intent | Emitted By | Handled By |
|---|---|---|
| `openProject` | Project row click, activity project click | FileNavigator (`handlesIntent`) |
| `openApp` | App row click | TBD — may need new widget or intent handler |
| `createProject` | New Project toolbar button / Quick Actions | Orchestrator native dialog |
| `showTeams` | Teams toolbar button / Quick Actions | TBD — team management widget |
| `showAudit` | Audit toolbar button | AuditTrail (`handlesIntent`) |
| `openUrl` | Help link click | Orchestrator → browser open |
| `home-panel.refresh` | Refresh toolbar button | DataSource `refreshOn` channels |

---

## Execution Order

1. **SDUI gap fixes (P0)** — Icons (G1), Grid rewrite (G2), ForEach limit/offset (G3)
2. **SDUI gap fixes (P1)** — WindowState object size (G4), Action hoverColor (G5), Wrap widget (G6)
3. **Orchestrator context enrichment** — displayName, email, teams
4. **Orchestrator intent handlers** — createProject dialog, openUrl handler, openProject routing
5. **Catalog template rewrite** — HomePanel with real data bindings using SDUI tokens
6. **Catalog home config** — update window size to object form
7. **Integration test** — connect to stage.tercen.com, verify all cards render correctly

---

## Dependencies

- `sci_tercen_client` — no changes needed
- `sdui` — 7 changes: 3 icon entries (G1), Grid rewrite (G2), ForEach extension (G3), WindowState extension (G4), Action hoverColor (G5), Wrap widget (G6), Text decoration (G7, P2)
- `tercen_ui_orchestrator` — 3 changes: context enrichment, intent handlers (createProject, openUrl)
- `tercen_ui_widgets/catalog.json` — template rewrite + home config update

**No dispatcher changes needed** — `projectService.recentProjects`, `documentService.getLibrary`, and `activityService.findStartKeys` are all already registered.

---

## Open Items

- [ ] Verify `Conditional` supports equality matching (`{{item.type}}==create`) for activity type chips — if not, need to extend Conditional or find alternative
- [ ] Confirm `recentProjects()` return shape — verify field names (`id`, `name`, `owner`, `lastModifiedDate`) accessible via `{{item.fieldName}}`
- [ ] Confirm `documentService.getLibrary()` return shape — verify field names for app rows
- [ ] Confirm `activityService.findStartKeys` with `by_user_and_date` view works — test against stage
- [ ] Decide: should `openApp` open a new workflow from the app, or show app details?
- [ ] Decide: what does "Teams" quick action open?
- [ ] Card search (G8) deferred — revisit when Filter supports reactive `contains` binding
- [ ] Text underline decoration (G7) deferred — ship without hyperlink underline styling
