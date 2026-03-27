# HomePanel — Real Implementation Plan

**Status:** Revised Draft
**Date:** 2026-03-27
**Target server:** stage.tercen.com
**Widget kind:** window (SDUI catalog.json template)

---

## Overview

Replace the placeholder HomePanel catalog.json template with a real implementation that connects to a Tercen server via authenticated service calls. The widget displays four cards (Recent Projects, Featured Apps, Help & Docs, Recent Activity) in a responsive 2×2 grid, with a toolbar providing quick actions (New Project, Teams, Audit).

---

## Current State

- **catalog.json** has a HomePanel entry with a single `DataSource` calling `homeService.getHomeDashboard()` — a service that does not exist
- Template uses placeholder text bindings (`{{data.projectsSummary}}`, etc.) instead of iterable data
- `home.windows` already references HomePanel with `"size": "large", "align": "left"`
- Auth is handled: orchestrator exposes `{{context.username}}`, `{{context.userId}}`, `{{context.token}}`, `{{context.isAdmin}}`, `{{context.isDark}}`

### Recent SDUI additions (since initial plan, as of 2026-03-27)

These don't close any gaps but are available for the template:

- **Container** now supports `maxWidth` and `maxHeight` props — useful for constraining card content width
- **Column** now supports `mainAxisSize` prop (`"min"` / `"max"`) — fixes unbounded height in windows
- **IconButton** has `isPrimary` prop — filled variant for primary toolbar actions
- **WindowShell** toolbar icon buttons now support `tooltip` prop
- **Pane system** introduced — windows live in panes with tab strips; `addWindow` still works (backward compatible)

### Recent orchestrator additions (since initial plan, as of 2026-03-27)

- **`navigateHome` intent** now wired — Tercen logo click clears panes and reloads home layout from cached catalog
- **`saveLayout` intent** now wired — saves current window layout as `.sdui.json` file
- **Catalog cached** — `_loadedCatalog` field stores fetched catalog for reuse by navigateHome
- **TaskMonitor** wired — task polling, event streaming, cancel via header intent

Still not wired: `openUrl` intent handler, `projectService.create` in dispatcher. No `teams` context enrichment. No object-form window size. (`createProject`, `openResource`, `openTeamManagement`, `openAuditTrail` are already handled by WindowManager via `window.intent`.)

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

Note: `bolt` and `folder_plus` were only needed by the Welcome/Quick Actions cards which are
not in the approved mock and have been removed from the plan.

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

#### Surface Hierarchy (verified against orchestrator, pane chrome, header, chat-box)

All other SDUI windows use `surface` (#FFFFFF light / #111827 dark) for toolbar, body, and
base backgrounds. HomePanel must conform to this, but needs card separation. The solution
is a tinted scroll area behind white cards:

| Element | Mock Color | SDUI Token | Light Hex | Rationale |
|---|---|---|---|---|
| Toolbar | (from WindowShell) | `surface` | `#FFFFFF` | Conforms with header, pane chrome, all other windows |
| Scroll area behind cards | `AppColors.panelBackground` (#F9FAFB) | `surfaceContainerLow` | `#F9FAFB` | Tinted bg gives white cards visual separation |
| Card body | `AppColors.surface` (#FFFFFF) | `surface` | `#FFFFFF` | White cards pop on tinted background |
| Card header | `AppColors.neutral100` (#F3F4F6) | `surfaceContainer` | `#F3F4F6` | Exact match to mock's neutral100 |

#### Other Colors

| Mock Color | Purpose | SDUI Token | Status |
|---|---|---|---|
| `AppColors.primary` | Icons, active states, links | `primary` | OK |
| `AppColors.primarySurface` | Card highlight bg, button hover | `primaryContainer` | OK |
| `AppColors.textPrimary` | Main text | `onSurface` | OK |
| `AppColors.textSecondary` | Secondary text | `onSurfaceVariant` | OK |
| `AppColors.textTertiary` | Tertiary/muted text | `textTertiary` | OK |
| `AppColors.textMuted` | Muted text, hints | `onSurfaceMuted` | OK |
| `AppColors.textDisabled` | Disabled text | `onSurfaceDisabled` | OK |
| `AppColors.surfaceElevated` | Hover row bg (dark mode) | `surfaceContainerHigh` | OK |
| `AppColors.neutral50` | Hover row bg (light mode) | `surfaceContainerLowest` | OK |
| `AppColors.border` | Card borders | `outline` or `border` | OK |
| `AppColors.borderSubtle` | Internal borders | `outlineVariant` or `borderSubtle` | OK |
| `AppColors.success` | Create/complete activity square | `success` | OK |
| `AppColors.error` | Delete activity square, error icon | `error` | OK |
| `AppColors.warning` | Run activity square | `warning` | OK |
| `AppColors.info` | Update activity square | `info` | OK |
| `AppColors.successLight` | Create chip bg (unused — chips removed) | `successContainer` | OK |
| `AppColors.errorLight` | Delete chip bg (unused) | `errorContainer` | OK |
| `AppColors.warningLight` | Run chip bg (unused) | `warningContainer` | OK |
| `AppColors.infoLight` | Update chip bg (unused) | `infoContainer` | OK |
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
| External URL open (Help links) | `window.intent` → WindowManager/orchestrator | OK (needs `openUrl` intent handler) |

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

**Last checked: 2026-03-27 — all 8 gaps remain open.**

| # | Gap | SDUI Component | Change Required | Priority |
|---|---|---|---|---|
| G1 | Missing icon: `clock_rotate_left` | `_iconMap` in builtin_widgets.dart | Add 1 entry | **P0** |
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
- `teams` — list of team names from `teamService` (for createProject dialog team dropdown)

#### 2b. Add write operations to base dispatcher

**File:** `lib/sdui/service/service_call_dispatcher.dart`, `_tryBaseMethod()`

The dispatcher currently only exposes read operations (`get`, `list`, `findStartKeys`, `findKeys`). Add the standard write operations so all services can create, update, and delete objects via SDUI:

```dart
case 'create':
  final obj = service.fromJson(args[0] as Map<String, dynamic>);
  final result = await service.create(obj);
  return service.toJson(result);

case 'update':
  final obj = service.fromJson(args[0] as Map<String, dynamic>);
  final result = await service.update(obj);
  return service.toJson(result);

case 'delete':
  final id = args[0] as String;
  await service.delete(id);
  return {'success': true, 'id': id};
```

This makes `create`, `update`, and `delete` available on **every** service (`projectService`, `documentService`, `teamService`, etc.) — not just for HomePanel but for all future SDUI templates.

**HomePanel uses:** `projectService.create` (createProject dialog).

#### 2c. Add activity `colorToken` post-processing

**File:** `lib/sdui/service/service_call_dispatcher.dart`

After fetching activity results via `findStartKeys`, map the activity `type` field to an SDUI color token string so templates can bind `color: "{{item.colorToken}}"` directly:

```dart
// In activity result post-processing:
for (final a in result) {
  a['colorToken'] = switch (a['type']) {
    'create' || 'complete' => 'success',
    'update' => 'info',
    'delete' => 'error',
    'run' => 'warning',
    _ => 'onSurfaceMuted',
  };
}
```

#### 2d. Existing dispatcher handlers (verified, no changes needed)

- `projectService.recentProjects` — **already registered**, takes `[username]`
- `documentService.getLibrary` — **already registered** (not `getTercenAppLibrary`), takes `(projectId, teamIds[], docTypes[], tags[], offset, limit)`
- `activityService` — **already has base CRUD + `findStartKeys`**, will work for activity queries

#### 2e. Handle `createProject` intent

**File:** `lib/main.dart`

Listen on `window.intent` for `"createProject"`. Show native Flutter dialog (SDUI has no form/dialog primitive). Dialog fields from mock:
- Project name (required)
- Team dropdown (searchable, from `context.teams`)
- Description (optional)
- Public toggle
- Collapsible git section (repo URL, branch, tag, commit, token)

On submit: call `projectService.create()` via dispatcher (now available from §2b), then emit `window.intent` with `{intent: "openResource", resourceType: "project", ...}`.

#### 2f. Handle `openUrl` intent

Add handler in WindowManager or orchestrator for `window.intent` with `intent: "openUrl"`. Call `url_launcher` or `html.window.open()` with the `url` field from payload. **This is the only missing intent handler.**

---

### 3. Catalog Template (`/home/martin/tercen/tercen_ui_widgets/catalog.json`)

#### 3a. Update home window config

```json
{"type": "HomePanel", "id": "home-panel", "size": {"width": 0.70, "height": 1.0}, "align": "left", "title": "Home"}
```

The pane tab title comes from the window config `title` field.

**Tab color square:** The catalog metadata already has `"typeColor": "#0D9488"` (teal) — this is
a unique color from the approved Tercen logo palette (row 2, position 4). Verified: no other
widget uses teal as its typeColor. The mock shows a multi-color gradient dot (cosmetic mock
behavior via `Colors.transparent`); in production SDUI the pane chrome renders a solid teal square.

#### 3b. Rewrite HomePanel template

**Structure matching the approved mock (verified via Playwright 2026-03-27):**

Note: The mock has `WelcomeCard` and `QuickActionsCard` source files but they are NOT used
in `_buildDashboard()`. The dashboard shows only 4 cards. The toolbar already provides the
quick action buttons, making a separate Quick Actions card redundant. Removed from plan.

```
WindowShell (root — provides toolbar frame)
├── toolbarActions: [
│     {icon: "plus", label: "New Project", channel: "window.intent", payload: {intent: "createProject"}},
│     {icon: "people", label: "Teams", channel: "window.intent", payload: {intent: "openTeamManagement"}},
│     {icon: "checklist", label: "Audit", channel: "window.intent", payload: {intent: "openAuditTrail"}}
│   ]
└── body:
    Container (color: "surfaceContainerLow")                       ← tinted bg for card separation
    └── ListView (padding: 8)                                      ← mock uses AppSpacing.sm (8px)
        └── Grid (columns: 2, minColumnWidth: 300, spacing: 16, runSpacing: 16)  ← NEEDS G2
        ├── [Card 1] Recent Projects
        │   └── Container (card styling: color "surface", borderColor "outline", borderRadius 8, elevation 1)
        │       ├── Container (header: color "surfaceContainer", borderColor "outlineVariant")
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
        │       │                   └── Action (channel: "window.intent",
        │       │                   │   payload: {intent: "openResource", resourceType: "project", resourceId: "{{item.id}}", resourceName: "{{item.name}}"},
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
        ├── [Card 2] Featured Apps
        │   Same card structure as Recent Projects:
        │   - Header icon: "extension" (maps to puzzlePiece)
        │   - DataSource: service "documentService", method "getLibrary", args: ["", [], [], [], 0, 50]
        │   - ForEach row: Icon "extension" + name + description (textStyle: "bodySmall")
        │   - Action channel: "window.intent", payload: {intent: "openApp", appId: "{{item.id}}", appName: "{{item.name}}"}
        │   - StateHolder id: "hp-apps-ps", initial: 5
        │
        ├── [Card 3] Help & Docs
        │   └── Container (card styling)
        │       ├── Container (header: Icon "help" + Text "Help & Documentation")
        │       └── Padding
        │           └── Wrap (spacing: 16, runSpacing: 8)               ← NEEDS G6
        │               ├── Action → Row [Icon "open_in_new" (size: 12) + Text "Learning Center"]
        │               │   channel: "window.intent", payload: {intent: "openUrl", url: "https://learn.tercen.com/en/"}
        │               ├── Action → Row [Icon "open_in_new" + Text "Starter Guide"]
        │               │   channel: "window.intent", payload: {intent: "openUrl", url: "https://github.com/tercen/starter_guide"}
        │               └── Action → Row [Icon "open_in_new" + Text "Public Projects"]
        │                   channel: "window.intent", payload: {intent: "openUrl", url: "https://tercen.com/explore"}
        │
        └── [Card 4] Recent Activity
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
                │                           │   Color resolved via dispatcher-computed field:
                │                           │   Container color: "{{item.colorToken}}"
                │                           │   Dispatcher maps type→token before returning:
                │                           │     create/complete → "success"
                │                           │     update → "info", delete → "error", run → "warning"
                │                           │   Template resolver resolves "{{item.colorToken}}" → "success",
                │                           │   then _resolveColor maps "success" → theme success color.
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

## Data I/O Verification (2026-03-27)

### Service Calls (Tercen API via Dispatcher)

| # | Card | Service.Method | Args (verified) | Dispatcher Status | Notes |
|---|---|---|---|---|---|
| S1 | Recent Projects | `projectService.recentProjects` | `["{{context.username}}"]` | **EXISTS** | Takes username string, returns `List<Project>` as JSON maps |
| S2 | Featured Apps | `documentService.getLibrary` | `["", [], [], [], 0, 50]` | **EXISTS** | Args: `[projectId, teamIds[], docTypes[], tags[], offset, limit]`. Empty projectId returns global library. |
| S3 | Recent Activity | `activityService.findStartKeys` | `["findByUserAndDate", ["{{context.userId}}", ""], ["{{context.userId}}", "\uf000"], 100, 0, true]` | **EXISTS** (generic handler) | View name `findByUserAndDate` — must test against stage to confirm |
| S4 | Create Project dialog | `projectService.create` | `(Project object)` | **DOES NOT EXIST** | Not in dispatcher. Must add, or handle entirely in orchestrator Dart code |

**Dot-notation binding verified:** Template resolver supports `{{item.name}}`, `{{item.id}}`, `{{item.acl.owner}}` etc. via Map path navigation.

### EventBus Input Signals (HomePanel Listens To)

| Channel | Listener | Purpose | Verified |
|---|---|---|---|
| `home-panel.refresh` | DataSource `refreshOn` | Trigger refetch on all cards | **YES** — DataSource accepts any arbitrary channel name |
| `state.hp-proj-ps.set` | StateHolder | Page size for Recent Projects | **YES** — pattern is `state.<nodeId>.set` |
| `state.hp-apps-ps.set` | StateHolder | Page size for Featured Apps | **YES** |
| `state.hp-activity-ps.set` | StateHolder | Page size for Recent Activity | **YES** |

StateHolder payload: implicit merge (e.g., `{value: 5}`) or explicit `{op: "merge", values: {value: 5}}`.

### EventBus Output Signals (HomePanel Emits)

**CRITICAL CORRECTION:** The plan previously used `system.intent` as the output channel. This is **wrong**. There are three intent channels with different purposes:

| Channel | Purpose | Handler |
|---|---|---|
| `header.intent` | Header menu actions (theme, navigate, save) | Orchestrator `_listenHeaderIntents()` |
| `system.intent` | Routes to registered catalog widgets via IntentRouter | IntentRouter (catalog-driven) |
| `window.intent` | Window management (open, create, close resources) | WindowManager |

**HomePanel must emit to `window.intent`** for all window/navigation operations.

| Feature | Channel | Intent Name | Payload | Handler Exists |
|---|---|---|---|---|
| Project row click | `window.intent` | `openResource` | `{resourceType: "project", resourceId: "{{item.id}}", resourceName: "{{item.name}}"}` | **YES** — WindowManager `_handleOpenResource()` |
| Activity project click | `window.intent` | `openResource` | `{resourceType: "project", resourceId: "{{item.projectId}}", resourceName: "{{item.projectName}}"}` | **YES** |
| New Project button | `window.intent` | `createProject` | `{}` | **YES** — WindowManager handles it |
| Teams button | `window.intent` | `openTeamManagement` | `{}` | **YES** — WindowManager handles it |
| Audit button | `window.intent` | `openAuditTrail` | `{}` | **YES** — WindowManager handles it |
| App row click | `window.intent` | `openApp` | `{appId: "{{item.id}}", appName: "{{item.name}}"}` | **PARTIAL** — published but no catalog widget registered |
| Help link click | `window.intent` | `openUrl` | `{url: "https://..."}` | **NO** — not found anywhere. Must add handler. |
| Refresh (future) | `home-panel.refresh` | — | `{}` | **YES** — DataSource `refreshOn` picks it up. No button in mock; channel reserved for future use. |
| Page size buttons | `state.<id>.set` | — | `{value: N}` | **YES** — StateHolder implicit merge |

### Activity Type Colors — Solved via Dispatcher

The activity type color-square initially seemed to require Conditional equality expressions (`{{item.type}}==create`), but SDUI Conditional only accepts booleans. **Solution:** compute a `colorToken` field in the dispatcher before returning activity data. The dispatcher maps `type` → SDUI color token string (e.g., `create` → `"success"`). The template then uses `color: "{{item.colorToken}}"` directly — template resolver produces `"success"`, and `_resolveColor` maps it to the theme color. No SDUI changes needed.

**Dispatcher addition** (in `activityService.findStartKeys` response post-processing):
```dart
for (final a in result) {
  a['colorToken'] = switch (a['type']) {
    'create' || 'complete' => 'success',
    'update' => 'info',
    'delete' => 'error',
    'run' => 'warning',
    _ => 'onSurfaceMuted',
  };
}
```

---

## SDUI Gaps Summary (Must Fix Before Implementation)

**Last checked: 2026-03-27 — 8 gaps remain.**

| # | Gap | SDUI Component | Change Required | Priority |
|---|---|---|---|---|
| G1 | Missing icon: `clock_rotate_left` | `_iconMap` in builtin_widgets.dart | Add 1 entry | **P0** |
| G2 | Grid forces equal aspect ratio, not responsive | `_buildGrid` in builtin_widgets.dart | Rewrite to `LayoutBuilder`+`Row`/`Column`+`IntrinsicHeight` | **P0** |
| G3 | ForEach has no `limit`/`offset` | `_buildForEach` in behavior_widgets.dart | Add optional `limit` and `offset` props with template expression support | **P0** |
| G4 | WindowState has no object-form size | `window_state.dart` | Support `{"width": 0.70, "height": 1.0}` alongside string presets | **P1** |
| G5 | Action has no hover visual feedback | `_buildAction` in behavior_widgets.dart | Add optional `hoverColor` prop | **P1** |
| G6 | No `Wrap` layout widget | builtin_widgets.dart | Add `Wrap` widget with `spacing` and `runSpacing` props | **P1** |
| G7 | Text has no `decoration` prop (underline) | `_buildText` in builtin_widgets.dart | Add `decoration` prop | **P2** |
| G8 | Filter `contains` not reactive to TextField input | `_buildFilter` in behavior_widgets.dart | Support template expressions in `contains` | **P2** (deferred) |

---

## Execution Order

1. **SDUI gap fixes (P0)** — Icons (G1), Grid rewrite (G2), ForEach limit/offset (G3)
2. **SDUI gap fixes (P1)** — WindowState object size (G4), Action hoverColor (G5), Wrap widget (G6)
3. **Orchestrator context enrichment** — displayName, teams
4. **Orchestrator dispatcher** — add `create`/`update`/`delete` to base methods, activity `colorToken` post-processing
5. **Orchestrator intent handlers** — `openUrl` handler (only missing one)
6. **Catalog template rewrite** — HomePanel with corrected channels (`window.intent`) and intent names
6. **Catalog home config** — update window size to object form
7. **Integration test** — connect to stage.tercen.com, verify all cards render correctly

---

## Dependencies

- `sci_tercen_client` — no changes needed
- `sdui` — 7 changes: 1 icon (G1), Grid (G2), ForEach (G3), WindowState (G4), Action hover (G5), Wrap (G6), Text decoration (G7, P2)
- `tercen_ui_orchestrator` — 4 changes: context enrichment, base CRUD write ops (`create`/`update`/`delete`) in dispatcher, activity `colorToken` post-processing, `openUrl` intent handler
- `tercen_ui_widgets/catalog.json` — template rewrite (corrected channels + intent names) + home config update

### Dispatcher status
- `projectService.recentProjects` — already registered
- `documentService.getLibrary` — already registered
- `activityService.findStartKeys` — already registered (generic handler)
- `create` / `update` / `delete` — **must add** to `_tryBaseMethod` (available on all services)

---

## Open Items

- [ ] Confirm `recentProjects()` return shape — verify field names (`id`, `name`, `owner`, `lastModifiedDate`) accessible via `{{item.fieldName}}`
- [ ] Confirm `documentService.getLibrary()` return shape — verify field names for app rows
- [ ] Confirm `activityService.findStartKeys` with `findByUserAndDate` view works — test against stage
- [ ] Confirm activity object field names for ForEach bindings (`type`, `objectName`, `userName`, `projectName`, `date`)
- [ ] Decide: should `openApp` open a new workflow from the app, or show app details? No catalog widget registered yet.
- [ ] `openUrl` intent handler — must add to orchestrator or WindowManager
- [ ] Card search (G8) deferred — revisit when Filter supports reactive `contains` binding
- [ ] Text underline decoration (G7) deferred — ship without hyperlink underline styling
