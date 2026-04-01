# SDUI Primitive Gaps — Project Navigator

**Generated:** 2026-04-01
**Source:** Audit of catalog.json against SduiTheme.dart and builtin_widgets.dart

---

## GAP: IconButton — no variant prop (primary/secondary)

**Mock needs:** Toolbar with 3 icon-only buttons: Upload (filled primary background), Download (filled primary background), Team (outlined secondary border).
**SDUI has:** `IconButton` primitive renders a bare Material `IconButton` — transparent background, no border, ghost styling only. Props: icon, size, color, tooltip, channel, enabled.
**Missing:** `variant` prop accepting `primary`, `secondary`, `ghost`. When `variant: "primary"`, should render 32x32 filled button using `ctx.theme.window.toolbarButtonSize`, `ctx.theme.window.toolbarButtonRadius`, `ctx.theme.colors.primary` background, `ctx.theme.colors.onPrimary` icon. When `variant: "secondary"`, outlined with `ctx.theme.window.toolbarButtonBorderWidth` border.
**Suggested fix:** In `_buildIconButton()` in `builtin_widgets.dart`, read `variant` prop. If `primary`: wrap icon in `Container` with primary fill, borderRadius from `ctx.theme.window.toolbarButtonRadius`. If `secondary`: add `Border.all` with primary colour. Default (`ghost`): current behaviour.
**Blocking:** `{{widgetId}}-tb-upload`, `{{widgetId}}-tb-download`, `{{widgetId}}-tb-team`

---

## GAP: IconButton — does not read SduiWindowTokens

**Mock needs:** Toolbar buttons sized 32x32 with 16px icons, 8px radius.
**SDUI has:** `_buildIconButton()` uses `props['size']` for icon size (default 24) but does not read `ctx.theme.window.toolbarButtonSize` for overall button dimensions or `ctx.theme.window.toolbarButtonRadius` for border radius.
**Missing:** Builder should use window tokens for sizing when rendered inside a toolbar context, or when a `toolbarButton: true` prop is set.
**Suggested fix:** Read `ctx.theme.window` tokens in the builder. Apply `toolbarButtonSize` as the button constraint and `toolbarButtonRadius` as the border radius.
**Blocking:** All toolbar IconButton nodes

---

## GAP: Icon — no font weight variant (regular vs solid)

**Mock needs:** Regular (line) weight icons for files (`fa-regular fa-file`), sub-folders (`fa-regular fa-folder-open`). Solid weight for projects, teams, workflows, datasets.
**SDUI has:** `Icon` widget maps icon names to `FontAwesomeIcons` constants — solid weight only. No `weight` or `style` prop.
**Missing:** `weight` prop accepting `solid` (default) or `regular` to select FontAwesome weight variant.
**Suggested fix:** In `_buildIcon()`, read `weight` prop. Map to `FontAwesomeIcons.{name}` (solid) or the regular variant. FontAwesome Flutter package exposes both.
**Blocking:** All file and sub-folder icon nodes in the tree

---

## INFO: Known limitations (not blocking)

- **TreeView**: No dedicated TreeView primitive. Composed from ListView + ForEach + Conditional + Container indentation. Works but verbose. Consider a dedicated TreeView primitive for future widgets.
- **SearchField prefix icon**: TextField has no `prefixIcon` prop. Composed with Row + Icon + TextField. Works.
- **PopupMenu per-item icon colour**: PopupMenu items support `icon` but not per-item `iconColor`. Active/inactive colour differentiation for filter dropdown requires SDUI fix or is handled by the renderer defaulting to theme colours.
