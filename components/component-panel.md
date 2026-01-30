# Component: Panel

**Purpose**: Container for left panel with header, sections, and collapsible behavior.

---

## Layout

### Dimensions
- **Default width**: `panelWidth` (280px) from design-tokens.md
- **Min width**: `panelMinWidth` (280px)
- **Max width**: `panelMaxWidth` (400px)
- **Collapsed width**: `panelCollapsedWidth` (48px)
- **Header height**: `headerHeight` (48px)

### Structure
```
┌─────────────────────┐
│ Header (48px)       │
├─────────────────────┤
│ Section 1           │
│ Section 2           │
│ Section 3           │ ← Scrollable
│ ...                 │
└─────────────────────┘
  280px (resizable)
```

---

## Visual Style

### Panel Container
- **Background**: `white` (light), `neutral-900` (dark)
- **Border**: 1px solid `neutral-200` (light), `neutral-800` (dark)
- **Shadow**: `shadow-sm` (light), none (dark)

### Header
See [visual-style-light.md](../visual/visual-style-light.md#panel-header-accent-style)

**Accent style** (standard for Tercen apps):
- **Background**: `primary` (light), `primary-dark-theme` (dark)
- **Text/Icons**: `white`

---

## Defaults

- **Default state**: Expanded (280px)
- **Default persistence**: None (resets on page reload)
- **Default resize**: Enabled (280-400px range)
- **Default auto-collapse**: Disabled (manual only)

---

## Behavior

### Resize

**Drag right edge:**
- Cursor: `resize-column` on hover over edge (4px hit area)
- Min constraint: 280px
- Max constraint: 400px
- Live update: Width changes as user drags
- No persistence: Resets to 280px on page reload

**Implementation:**
```dart
GestureDetector(
  onHorizontalDragUpdate: (details) {
    final newWidth = panelWidth + details.delta.dx;
    setState(() {
      panelWidth = newWidth.clamp(280.0, 400.0);
    });
  },
  child: MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: Container(width: 4, color: Colors.transparent),
  ),
)
```

### Collapse

**CRITICAL**: Collapse MUST change panel width to 48px, not just hide content.

**Trigger**: Click chevron icon in header

**Expanded → Collapsed:**
1. Set panel width to 48px
2. Hide: app title, theme toggle, section labels, section content
3. Show: app icon (centered), section icons (vertical strip), chevron in footer
4. Animation: `transition-base` (0.2s ease)

**Collapsed → Expanded:**
1. Set panel width to 280px (or last user-resized width)
2. Show all hidden elements
3. Animation: `transition-base` (0.2s ease)

**Collapsed layout:**
```
┌────┐
│ 󰀘 │ ← App icon (clickable, expands panel)
├────┤
│ 󰈙 │ ← Section icons
│ 󰒓 │   (clickable, expand + scroll)
│ 󰁘 │
│ 󰓥 │
├────┤
│ ▶ │ ← Chevron (expands panel)
└────┘
 48px
```

**Common implementation error:**
❌ Hiding content but keeping panel at 280px
✓ Changing container width from 280px → 48px

### Expand and Scroll (from collapsed)

**When section icon clicked in collapsed state:**
1. Expand panel to 280px
2. Wait for animation (`transition-base` = 200ms)
3. Scroll to bring clicked section into view

**Implementation:**
```dart
void onSectionIconTap(String sectionId) {
  if (isCollapsed) {
    setState(() => isCollapsed = false);

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

---

## Panel Header Composition

**4 required elements (left to right):**

| Element | Position | Expanded | Collapsed |
|---------|----------|----------|-----------|
| App Icon | Left | Visible | Visible (centered) |
| App Title | Left (after icon) | Visible | Hidden |
| Theme Toggle | Right (before chevron) | Visible | Hidden |
| Collapse Chevron | Right (last) | Visible (header) | Visible (footer) |

**Collapsed header restructuring:**
- Move chevron from header to footer (prevents overflow in 48px width)
- Center app icon in header
- Icon + chevron + padding won't fit in 48px

---

## Panel Sections

**Structure**: Vertical stack, no tabs

**Section requirements:**
- Icon (from [visual-style-icons.md](../visual/visual-style-icons.md))
- Label (UPPERCASE, 11px, weight 600, `neutral-500`)
- Content (controls, lists, forms)

**Section behavior:**
- **No internal collapse**: Sections are always expanded
- **Scrolling**: Vertical scroll if content exceeds panel height
- **Borders**: 1px border between sections

**INFO Section** (required for all Tercen apps):
- Position: Last section (bottom of panel)
- Icon: `fa-info-circle`
- Label: "INFO" (uppercase)
- Content: GitHub link with version/tag/hash

---

## Implementation Template

```dart
class LeftPanel extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<PanelSection> sections;

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  double _panelWidth = 280.0;
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: _isCollapsed ? 48.0 : _panelWidth,
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
}
```

---

## References

- **Dimensions**: [design-tokens.md](../foundation/design-tokens.md#panel-dimensions)
- **Colors**: [visual-style-light.md](../visual/visual-style-light.md#panels--sections)
- **Pattern usage**: [pattern-left-panel.md](../patterns/pattern-left-panel.md)
