# Component: Grid

**Purpose**: Display items (images, cards, files) in a grid layout.

---

## Layout

### Gap Spacing
- **Cell gap**: 4px (both horizontal and vertical)
- **Container padding**: 16px around entire grid

**Rule**: Gaps MUST be equal in both directions.

### Grid Structure
```
┌─────────────────────────────────┐
│ 16px padding                    │
│  ┌────┬────┬────┬────┐          │
│  │ 1  │ 2  │ 3  │ 4  │          │
│  ├────┼────┼────┼────┤  4px gap │
│  │ 5  │ 6  │ 7  │ 8  │  (equal) │
│  ├────┼────┼────┼────┤          │
│  │ 9  │ 10 │ 11 │ 12 │          │
│  └────┴────┴────┴────┘          │
│                                 │
└─────────────────────────────────┘
```

### Column Calculation

**Responsive columns by container width:**

| Container Width | Recommended Columns | Notes |
|----------------|---------------------|-------|
| < 400px | 2-3 | Or 1 for larger items |
| 400-600px | 3-4 | |
| 600-900px | 4-6 | |
| > 900px | 6-8 | Or set max-width on grid |

**Principle**: Items should not be too small (unusable) or too large (wasteful).

**For 80-120px items**: Use table above
**For larger items (200px+)**: Reduce column count proportionally

### Cell Sizing

**Fixed aspect ratio (recommended for images):**
- Define aspect ratio (e.g., 270:200 = 1.35:1)
- Calculate height from available width
- Or calculate width from target rows to fit on screen

**Equal sizing:**
- All cells same size in grid
- Use CSS Grid with `grid-template-columns: repeat(N, 1fr)`

**Auto-fit:**
- Cells adjust to fill available space
- Use `grid-template-columns: repeat(auto-fit, minmax(120px, 1fr))`
- Min value prevents cells from becoming too small

---

## Visual Style

### Cell Container
- **Background**: `white` (light), `neutral-900` (dark)
- **Border**: 1px solid `neutral-200` (light), `neutral-800` (dark)
- **Border radius**: `radius-sm` (4px)
- **Shadow**: none (flat) or `shadow-sm` (subtle lift)

### Grid Container
- **Background**: `neutral-50` (light), `neutral-800` (dark)
- **Padding**: 16px
- **Border**: Optional 1px solid `neutral-200`

---

## Defaults

- **Default gap**: 4px (both directions)
- **Default padding**: 16px
- **Default columns**: Calculated by container width
- **Default overflow**: Horizontal scroll if grid exceeds container

---

## Behavior

### Horizontal Scroll

**When grid width > container width:**
- Enable horizontal scroll
- Keep vertical alignment of all rows
- Maintain 4px gap consistency

### Item Selection

**Click:**
- Add selection border or background change
- Trigger onSelect callback
- Support multi-select with Ctrl/Cmd + click

**Hover:**
- Subtle background change (optional)
- Show additional controls (optional, but must have non-hover affordance)

---

## Grid Types

### Image Grid

**Typical for PS12 Image Overview:**
- Row headers (Well numbers): W1, W2, W3, W4
- Column headers (Barcodes): 641024305, 641024309, etc.
- Cells: Images with metadata overlay

**Structure:**
```
      [Barcode1] [Barcode2] [Barcode3]
[W1]  [Image]    [Image]    [Image]
[W2]  [Image]    [Image]    [Image]
[W3]  [Image]    [Image]    [Image]
[W4]  [Image]    [Image]    [Image]
```

**Header styling:**
- Font size: 12px
- Font weight: 600
- Color: `neutral-600` (light), `neutral-400` (dark)
- Alignment: Centered

**Empty cells:**
- Show placeholder icon (`fa-image-not-supported`)
- Background: `neutral-50` (light), `neutral-800` (dark)
- Center icon vertically and horizontally

### Card Grid

**For documents, files, projects:**
- Card includes: icon, title, metadata
- Gap: 4px between cards
- Card padding: 12px internal
- Card hover: Lift with `shadow-md`

### File Grid

**For file browsers:**
- Thumbnail + filename below
- Selection: Checkbox overlay or border
- Context menu: Right-click or overflow menu

---

## Aspect Ratio Maintenance

**For image grids:**

### CSS (Web)
```css
.grid-cell {
  aspect-ratio: 270 / 200; /* 1.35:1 */
  width: 100%;
}
```

### Flutter
```dart
AspectRatio(
  aspectRatio: 270 / 200, // 1.35:1
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(4),
    ),
    child: image,
  ),
)
```

---

## Implementation Examples

### Flutter Grid

```dart
GridView.builder(
  padding: EdgeInsets.all(16),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
    childAspectRatio: 270 / 200,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return _buildGridCell(items[index]);
  },
)
```

### CSS Grid (Web)

```css
.grid-container {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 4px;
  padding: 16px;
}

.grid-cell {
  aspect-ratio: 270 / 200;
  border: 1px solid var(--neutral-200);
  border-radius: 4px;
}
```

---

## Accessibility

- **Keyboard navigation**: Arrow keys move between cells
- **Selection**: Space/Enter selects current cell
- **Screen readers**: Announce grid structure (rows, columns)
- **Images**: Require alt text or aria-label

---

## References

- **Gap spacing**: [design-tokens.md](../foundation/design-tokens.md#grid--table)
- **Colors**: [visual-style-light.md](../visual/visual-style-light.md)
- **Icons**: [visual-style-icons.md](../visual/visual-style-icons.md)
