# Panel Widget — Design Summary

> Condensed reference for panel widget skills.

---

## What Is a Panel Widget?

A **visualization and interaction** widget with a two-panel layout. It reads data from Tercen, displays it in the main content area, and optionally writes data back. Two modes:

- **Read-only (visualization):** Tercen → Widget → Screen (+ download)
- **Interactive (write-back):** Tercen → Widget → Screen → Write back to Tercen

---

## Two-Panel Layout

```
+----------------------------+------------------------------------+
| Left Panel (resizable)     | Main Content                       |
|                            |                                    |
| [Panel Header]             | [Visualization / Grid / Canvas]    |
|                            |                                    |
| > SECTION NAME             |                                    |
| +------------------------+ |                                    |
| | [Control] [Type]       | |                                    |
| +------------------------+ |                                    |
|                            |                                    |
| > INFO                     |                                    |
| +------------------------+ |                                    |
| | GitHub link            | |                                    |
| +------------------------+ |                                    |
+----------------------------+------------------------------------+
```

Structure: `Row → [LeftPanel, Expanded(MainContent)]`

Conditional top bar shown in standalone mode only.

---

## Left Panel Rules

1. **ALL controls go in the left panel.** Main content area is display only.
2. **Sections scroll vertically.** No tabs. No internal collapse.
3. **Every section has an icon and UPPERCASE label.**
4. **INFO section is mandatory** — always last, with GitHub link.
5. Left panel supports collapse, expand, and resize (skeleton mechanics).

---

## Main Content Rules

- Display only — no sliders, dropdowns, text inputs, state-changing buttons, toggles, checkboxes, or radio buttons.
- Allowed interactions: hover tooltips, click-to-select/highlight, zoom/pan, drag-to-select, context menus for export.
- Theme-aware chrome (background, status text, legends).
- Graph/chart containers: always force white background with light-mode colours.

---

## DO-NOT-MODIFY Files (Panel Skeleton)

| File | What it does |
|---|---|
| `lib/presentation/widgets/left_panel/left_panel.dart` | Collapse, expand, resize, LayoutBuilder, icon strip, footer chevron |
| `lib/presentation/widgets/left_panel/left_panel_header.dart` | 4-element header, collapsed header restructuring |
| `lib/presentation/widgets/left_panel/left_panel_section.dart` | Section header styling (background, text color, borders) |
| `lib/presentation/widgets/app_shell.dart` | Frame layout, conditional top bar |
| `lib/presentation/widgets/top_bar.dart` | Standalone mode indicator |
| `lib/core/theme/app_colors.dart` | Light theme color tokens |
| `lib/core/theme/app_colors_dark.dart` | Dark theme color tokens |
| `lib/core/theme/app_spacing.dart` | Spacing and dimension tokens |
| `lib/core/theme/app_text_styles.dart` | Typography tokens |
| `lib/core/theme/app_theme.dart` | Material 3 ThemeData (light + dark) |
| `lib/core/theme/app_line_weights.dart` | Line weight constants for UI and viz |
| `lib/core/utils/context_detector.dart` | Tercen embedded detection |
| `lib/presentation/providers/theme_provider.dart` | Theme persistence |

---

## AppStateProvider Shape (Panel)

```
- Data loading state: isLoading, error, data
- One field per control (private + getter + setter + notifyListeners)
- loadData() method for initial data fetch
- Data type: domain model (not Map<String, dynamic>)
```

---

## Phase 3 Integration Pattern

- Uses `sci_tercen_context` with `tercenCtx(serviceFactory, taskId)`
- `ctx.select()` / `ctx.cselect()` / `ctx.rselect()` for data access
- Write-back (if interactive): `ctx.saveTable()` / `ctx.save()`
- Flows A-D in the Phase 3 integration skill
