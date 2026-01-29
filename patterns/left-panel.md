# Pattern: Left Panel

**Purpose**: Standard left panel component for all Tercen Flutter apps

**Prerequisite**: Read [app-frame.md](app-frame.md) first for overall screen structure

**Reference**: `_local/left-panel-testboard.html` (v3.1) - Interactive demonstration

## Overview

All Tercen apps use a **left panel** for controls, filters, and navigation. This pattern defines the left panel component specifications.

For overall app structure (container, main content, top bar, app types), see [app-frame.md](app-frame.md).

## Dimensions

| Property | Value | Notes |
|----------|-------|-------|
| Default width | 280px | Initial panel width |
| Min width | 280px | Cannot resize smaller |
| Max width | 400px | Cannot resize larger |
| Collapsed width | 48px | Icon strip only |
| Header height | 48px | Aligns with optional top bar |

```dart
// lib/core/theme/app_spacing.dart
class AppSpacing {
  // Left Panel dimensions
  static const double leftPanelWidth = 280.0;
  static const double leftPanelMinWidth = 280.0;
  static const double leftPanelMaxWidth = 400.0;
  static const double leftPanelCollapsedWidth = 48.0;
  static const double leftPanelHeaderHeight = 48.0;
}
```

## Header Composition

The header contains exactly 4 elements (left to right):

| Element | Required | Position | Behavior |
|---------|----------|----------|----------|
| App Icon | Yes | Left | Clicking expands panel when collapsed |
| App Title | Yes | Left (after icon) | Hidden when collapsed |
| Theme Toggle | Yes | Right | Hidden when collapsed |
| Collapse Chevron | Yes | Right (last) | Always visible |

### Header Styling

- Background: Accent color (`--accent` / `AppColors.primary`)
- Text/Icons: White (`--on-accent` / `Colors.white`)
- Height: 48px

```dart
Container(
  height: AppSpacing.leftPanelHeaderHeight,
  color: AppColors.primary,
  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  child: Row(
    children: [
      // App Icon (required)
      GestureDetector(
        onTap: isCollapsed ? expandPanel : null,
        child: Icon(appIcon, color: Colors.white),
      ),
      SizedBox(width: AppSpacing.sm),

      // App Title (hidden when collapsed)
      if (!isCollapsed)
        Expanded(
          child: Text(
            appTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

      // Theme Toggle (hidden when collapsed)
      if (!isCollapsed)
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            color: Colors.white,
          ),
          onPressed: toggleTheme,
        ),

      // Collapse Chevron (always visible)
      IconButton(
        icon: Icon(
          isCollapsed ? Icons.chevron_right : Icons.chevron_left,
          color: Colors.white,
        ),
        onPressed: toggleCollapse,
      ),
    ],
  ),
)
```

### Theme Toggle Icons

| Current Theme | Icon Shown | Action |
|---------------|------------|--------|
| Light | Moon | Switch to dark |
| Dark | Sun | Switch to light |

**Rule**: The icon represents what you're switching TO, not the current state.

## Section Requirements

### Section Structure

Each section has:

| Element | Required | Notes |
|---------|----------|-------|
| Section Icon | Yes | FontAwesome, defined in Functional Spec |
| Section Label | Yes | UPPERCASE, describes section purpose |
| Section Content | Yes | Controls, forms, lists, etc. |

### Section Behavior

| Property | Value |
|----------|-------|
| Internal collapsing | **NO** - sections are always expanded |
| Visibility | All sections always visible |
| Navigation | Vertical scroll (no tabs) |
| Borders | Bottom border between sections |

```dart
class LeftPanelSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: AppColors.surfaceElevated,
          child: Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              SizedBox(width: AppSpacing.sm),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Section Content
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: content,
        ),
      ],
    );
  }
}
```

## Collapsed State

When collapsed, the panel transforms into an icon navigation strip.

> **COMMON ERROR - CHECK THIS**: The collapse must **change the panel width to 48px**, not just hide the content. If clicking the chevron only clears/hides the panel contents but the panel stays at 280px width, the implementation is wrong. The panel container itself must animate from 280px → 48px.
>
> **Inline styles gotcha**: If the panel is resizable, inline styles (`style.width`) will override CSS classes. When collapsing, you MUST clear inline styles so the `.collapsed` class can take effect:
>
> ```javascript
> // Clear inline styles when collapsing
> leftPanel.style.width = '';
> leftPanel.style.minWidth = '';
> ```

### Collapsed Layout

```
┌────────────────────┐
│    [App Icon]      │  ← Header (48px) - click expands
├────────────────────┤
│    [Section 1]     │  ← Section icons become
│    [Section 2]     │    vertical navigation
│    [Section 3]     │    (same icons, CSS transform)
│    [Section 4]     │
│        ...         │
├────────────────────┤
│    [Chevron →]     │  ← Footer - click expands
└────────────────────┘
     48px width
```

### Collapsed Behavior

| Element | Visibility | Behavior |
|---------|------------|----------|
| App Icon | Visible | Click expands panel |
| App Title | Hidden | - |
| Theme Toggle | Hidden | - |
| Section Icons | Visible | Click expands AND scrolls to section |
| Section Labels | Hidden | - |
| Section Content | Hidden | - |
| Expand Chevron | Visible | Click expands panel |

### Click-to-Expand-and-Scroll

When a section icon is clicked in collapsed state:

1. Panel expands to default width (280px)
2. After animation completes (~200ms)
3. Panel scrolls to bring that section into view

```dart
void onSectionIconTap(String sectionId) {
  if (isCollapsed) {
    // 1. Expand panel
    setState(() => isCollapsed = false);

    // 2. Scroll to section after animation
    Future.delayed(Duration(milliseconds: 200), () {
      final context = sectionKeys[sectionId]?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
}
```

## Resize Behavior

| Property | Value |
|----------|-------|
| Resizable | Yes (drag right edge) |
| Min width | 280px |
| Max width | 400px |
| Persistence | No (resets on page reload) |
| Auto-collapse | No (manual only) |

```dart
GestureDetector(
  onHorizontalDragUpdate: (details) {
    final newWidth = panelWidth + details.delta.dx;
    setState(() {
      panelWidth = newWidth.clamp(
        AppSpacing.leftPanelMinWidth,
        AppSpacing.leftPanelMaxWidth,
      );
    });
  },
  child: MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: Container(width: 4, color: Colors.transparent),
  ),
)
```

## Functional Specification Requirements

The Functional Specification for each app MUST define:

| Item | Example |
|------|---------|
| App icon | `fa-images` (Image Overview) |
| App title | "Image Overview" |
| Section list | Filters, Display, View, Actions |
| Section icons | `fa-filter`, `fa-sliders`, `fa-eye`, `fa-bolt` |
| Section content | What controls appear in each section |

## Flutter Implementation Template

```dart
// lib/presentation/widgets/left_panel.dart
class LeftPanel extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<LeftPanelSection> sections;

  const LeftPanel({
    required this.appTitle,
    required this.appIcon,
    required this.sections,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  double _panelWidth = AppSpacing.leftPanelWidth;
  bool _isCollapsed = false;
  final Map<String, GlobalKey> _sectionKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: _isCollapsed
        ? AppSpacing.leftPanelCollapsedWidth
        : _panelWidth,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isCollapsed
              ? _buildCollapsedIconStrip()
              : _buildExpandedContent(),
          ),
          if (_isCollapsed) _buildCollapseFooter(),
        ],
      ),
    );
  }

  // ... implementation details
}
```

## CSS Variables Reference

For HTML/web implementations, use these CSS variables:

```css
:root {
  --panel-width: 280px;
  --panel-min-width: 280px;
  --panel-max-width: 400px;
  --panel-collapsed-width: 48px;
  --header-height: 48px;
}
```

## Checklist

When implementing a left panel:

- [ ] Read [app-frame.md](app-frame.md) first (overall structure)
- [ ] Read Functional Specification for app icon, title, sections
- [ ] Set panel width to 280px default
- [ ] Implement header with all 4 required elements
- [ ] Use accent colour for header background
- [ ] Theme toggle shows moon (light) / sun (dark)
- [ ] Add section icons to all sections
- [ ] Section labels are UPPERCASE
- [ ] Sections do NOT collapse internally
- [ ] Implement collapsed state (48px icon strip)
- [ ] **VERIFY**: Collapse changes panel WIDTH to 48px (not just hiding content)
- [ ] App icon click expands when collapsed
- [ ] Section icon click expands AND scrolls
- [ ] Implement resize (280-400px range)
- [ ] Test both light and dark themes

## Related Documents

- [Pattern: App Frame](app-frame.md) - Overall screen structure (read first)
- `_local/left-panel-testboard.html` - Interactive HTML demonstration
- `_local/tercen-style/specifications/Tercen-Layout-Principles.html` - Layout fundamentals
- `_local/tercen-style/specifications/Tercen-Dark-Theme.html` - Dark theme colours
