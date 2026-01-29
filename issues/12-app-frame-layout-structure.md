# Issue #12: App Frame Layout Structure

**Category**: UI Layout

**Severity**: High - Causes visual breaks and missing functionality

## Problem

Developers implement main content areas but miss critical app frame structural details:

1. **Conditional top bar**: Should show in standalone mode, hide when embedded in Tercen
2. **Left panel collapsed state**: Chevron button moves from header to footer when collapsed

These details are documented in [app-frame.md](../patterns/app-frame.md) and [left-panel.md](../patterns/left-panel.md) but are easily overlooked when focusing on main content implementation.

## Impact

- **Missing top bar**: App appears incomplete in standalone/mock mode; users can't see app title or access theme toggle
- **Collapsed panel overflow**: "RIGHT OVERFLOWED BY X PIXELS" error when header tries to fit icon + chevron in 48px width

## Root Cause

Both patterns require reading layout diagrams carefully:
- Top bar conditional logic is specified but not prominent
- Collapsed state restructuring is shown in ASCII diagram but easy to miss

## Solution

### 1. Conditional Top Bar

**Documentation**: [app-frame.md lines 95-102](../patterns/app-frame.md)

The top bar is context-dependent:
- **Show top bar**: In standalone mode (no `taskId` in URL parameters)
- **Hide top bar**: When embedded in Tercen (`taskId` present)

```dart
// Context detection
final taskId = Uri.base.queryParameters['taskId'];
final isEmbedded = taskId != null && taskId.isNotEmpty;

// In build method
return Scaffold(
  body: Column(
    children: [
      if (!isEmbedded) const TopBar(),  // Conditional!
      Expanded(
        child: Row(
          children: [
            const LeftPanel(),
            Expanded(child: MainContent()),
          ],
        ),
      ),
    ],
  ),
);
```

### 2. Left Panel Collapsed State

**Documentation**: [left-panel.md](../patterns/left-panel.md)

When collapsed, the panel restructures completely:

| Element | Expanded Location | Collapsed Location |
|---------|-------------------|-------------------|
| App icon | Header (left) | Header (centred) |
| App title | Header (centre) | Hidden |
| Theme toggle | Header (right) | Footer |
| Chevron | Header (right) | Footer |
| Section icons | With labels | Icon strip (centred) |

**Critical**: The collapsed header contains ONLY the centred app icon. Everything else moves.

```
EXPANDED (280px):              COLLAPSED (48px):
┌─────────────────────┐        ┌────────┐
│ [icon] Title [◀][☀]│        │  [i]   │  ← Icon only, centred
├─────────────────────┤        ├────────┤
│ [□] Filters         │        │  [□]   │
│ [□] Settings        │        │  [□]   │
│ ...                 │        │  ...   │
├─────────────────────┤        ├────────┤
│                     │        │ [☀][▶] │  ← Theme + chevron in footer
└─────────────────────┘        └────────┘
```

## Pre-Implementation Checklist

Before implementing app layout:

- [ ] Read app-frame.md completely, not just main content section
- [ ] Implement context detection (`taskId` check)
- [ ] Add conditional top bar for standalone mode
- [ ] Read left-panel.md collapsed state diagram
- [ ] Implement header restructuring when collapsed (icon only)
- [ ] Move chevron and theme toggle to footer when collapsed
- [ ] Test collapsed state for overflow errors

## Examples

### Top Bar

#### ❌ WRONG: Skip straight to main content

```dart
// Missing top bar entirely
return Scaffold(
  body: Row(
    children: [
      const LeftPanel(),
      Expanded(child: ImageGrid()),
    ],
  ),
);
```

#### ✅ CORRECT: Include conditional top bar

```dart
final isEmbedded = Uri.base.queryParameters['taskId']?.isNotEmpty ?? false;

return Scaffold(
  body: Column(
    children: [
      if (!isEmbedded) const TopBar(),
      Expanded(
        child: Row(
          children: [
            const LeftPanel(),
            Expanded(child: ImageGrid()),
          ],
        ),
      ),
    ],
  ),
);
```

### Left Panel Collapsed Header

#### ❌ WRONG: Keep all elements in header when collapsed

```dart
// Causes overflow: 20px icon + 32px chevron + padding > 48px
Widget _buildHeader() {
  return Row(
    children: [
      Icon(icon),
      if (!isCollapsed) Text(title),
      IconButton(icon: Icon(Icons.chevron)),  // Still in header!
    ],
  );
}
```

#### ✅ CORRECT: Restructure completely when collapsed

```dart
Widget _buildHeader() {
  if (isCollapsed) {
    // Collapsed: icon only, centred
    return Center(child: Icon(icon));
  }
  // Expanded: full header
  return Row(
    children: [
      Icon(icon),
      Expanded(child: Text(title)),
      ThemeToggle(),
      CollapseButton(),
    ],
  );
}

Widget _buildFooter() {
  if (!isCollapsed) return SizedBox.shrink();
  // Collapsed: theme + chevron move here
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ThemeToggle(),
      ExpandButton(),
    ],
  );
}
```

## Testing

After implementation, verify:

1. **Standalone mode**: Run without `?taskId=xxx` - top bar should appear
2. **Embedded mode**: Run with `?taskId=test` - top bar should be hidden
3. **Collapse panel**: Click chevron - no overflow errors
4. **Collapsed state**: Only icon in header, chevron in footer
5. **Expand panel**: Click chevron in footer - full header restored

## See Also

- [Pattern: App Frame](../patterns/app-frame.md)
- [Pattern: Left Panel](../patterns/left-panel.md)
- [Issue #9: UI Design Standards](9-ui-design-standards.md)
