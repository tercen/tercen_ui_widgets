# Component: Table

**Purpose**: Display tabular data with rows and columns.

---

## Layout

### Row Heights

| Density | Height | Usage |
|---------|--------|-------|
| Compact | 32px | Information-dense, many rows |
| Default | 40px | Standard tables, balanced |
| Comfortable | 48px | Spacious, less data |

### Cell Padding

| Density | Horizontal Padding |
|---------|-------------------|
| Compact | 12px |
| Default | 12px |
| Comfortable | 16px |

### Column Widths

**Content-based sizing:**
- Short values (status, codes): 80-120px
- Medium values (names, titles): 150-250px
- Long values (descriptions, paths): 250-400px
- Actions column: 80-120px (fixed)

**Flexible columns:**
- Use `min-width` to prevent too-narrow columns
- Allow flex-grow for description/text columns
- Pin action columns to fixed width

---

## Visual Style

See [visual-style-light.md](../visual/visual-style-light.md#tables) or [visual-style-dark.md](../visual/visual-style-dark.md#tables)

### Table Header
- **Background**: `neutral-50` (light), `neutral-800` (dark)
- **Text**: `neutral-700` (light), `neutral-200` (dark)
- **Font weight**: 600
- **Border bottom**: 2px solid `neutral-200` (light), `neutral-700` (dark)
- **Text alignment**: Left (default), right for numbers

### Table Row
- **Background**: `white` (light), `neutral-900` (dark)
- **Text**: `neutral-700` (light), `neutral-200` (dark)
- **Border bottom**: 1px solid `neutral-100` (light), `neutral-800` (dark)

### Hover State
- **Background**: `neutral-50` (light), `neutral-800` (dark)
- **Transition**: `transition-fast` (0.15s ease)

### Selected State
- **Background**: `primary-bg` (light), rgba(109, 40, 217, 0.15) (dark)
- **Border left**: 3px solid `primary` (optional emphasis)

---

## Defaults

- **Default density**: Default (40px rows)
- **Default sorting**: None (or first column ascending if applicable)
- **Default selection**: None
- **Default pagination**: Optional, depends on data size

---

## Behavior

### Sorting

**Click header:**
- First click: Sort ascending
- Second click: Sort descending
- Third click: Remove sort (return to default order)

**Visual indicator:**
- Arrow icon: `fa-chevron-up` (ascending), `fa-chevron-down` (descending)
- Icon position: Right side of header text
- Color: `neutral-600` (light), `neutral-400` (dark)

**Implementation:**
```dart
void onHeaderTap(String columnId) {
  setState(() {
    if (sortColumn == columnId) {
      if (sortDirection == SortDirection.ascending) {
        sortDirection = SortDirection.descending;
      } else if (sortDirection == SortDirection.descending) {
        sortColumn = null;
        sortDirection = null;
      }
    } else {
      sortColumn = columnId;
      sortDirection = SortDirection.ascending;
    }
  });
}
```

### Selection

**Click row:**
- Single-select: Deselect others, select this row
- Multi-select: Ctrl/Cmd + click adds to selection
- Range-select: Shift + click selects range

**Checkbox column (optional):**
- First column: Checkbox for explicit multi-select
- Header checkbox: Select/deselect all visible rows

### Hover

**Row hover:**
- Apply hover background
- Transition: `transition-fast`
- Show action buttons (optional, but must have non-hover affordance)

### Pagination

**When rows > 50 (recommended threshold):**
- Show pagination controls below table
- Options: 25, 50, 100 rows per page
- Display: "Showing 1-25 of 247" text
- Controls: Previous, Next, page numbers

---

## Table Structure

### Basic Table

```
┌─────────────────────────────────────────────────────┐
│ Name       │ Status   │ Date       │ Actions       │ ← Header
├─────────────────────────────────────────────────────┤
│ Item 1     │ Active   │ 2026-01-30 │ [⋮]          │ ← Row
│ Item 2     │ Pending  │ 2026-01-29 │ [⋮]          │
│ Item 3     │ Active   │ 2026-01-28 │ [⋮]          │
└─────────────────────────────────────────────────────┘
```

### With Selection

```
┌───────────────────────────────────────────────────────┐
│ ☐ │ Name     │ Status  │ Date       │ Actions      │ ← Header with select-all
├───────────────────────────────────────────────────────┤
│ ☐ │ Item 1   │ Active  │ 2026-01-30 │ [⋮]         │
│ ☑ │ Item 2   │ Pending │ 2026-01-29 │ [⋮]         │ ← Selected
│ ☐ │ Item 3   │ Active  │ 2026-01-28 │ [⋮]         │
└───────────────────────────────────────────────────────┘
```

---

## Cell Content

### Text

**Overflow handling:**
- Short columns: Truncate with ellipsis
- Long columns: Allow wrap or truncate (specify max-height)
- Tooltip: Show full text on hover (optional)

### Numbers

**Alignment**: Right-aligned
**Formatting**: Use consistent decimal places, thousands separators

### Status/Badges

**Use badge component:**
- Success (green), Warning (amber), Error (red), Info (teal)
- Keep badges small (12px font)
- Fixed width for status column

### Actions

**Overflow menu (⋮):**
- Always visible (not hover-only)
- Opens menu below row
- Common actions: Edit, Delete, Duplicate, View

**Icon buttons:**
- Max 2-3 visible icon buttons
- More actions in overflow menu
- Icon size: 16px

---

## Empty State

**When table has no data:**
- Center empty state message
- Icon: `fa-table` or context-appropriate icon (48px)
- Text: "No items found" or context-specific message
- Action: Optional "Add item" button

---

## Implementation Examples

### Flutter Table

```dart
DataTable(
  columns: [
    DataColumn(label: Text('Name')),
    DataColumn(label: Text('Status')),
    DataColumn(label: Text('Date')),
    DataColumn(label: Text('Actions')),
  ],
  rows: items.map((item) {
    return DataRow(
      cells: [
        DataCell(Text(item.name)),
        DataCell(_buildStatusBadge(item.status)),
        DataCell(Text(item.date)),
        DataCell(_buildActionsMenu(item)),
      ],
    );
  }).toList(),
)
```

### HTML Table

```html
<table class="data-table">
  <thead>
    <tr>
      <th>Name</th>
      <th>Status</th>
      <th>Date</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Item 1</td>
      <td><span class="badge badge-success">Active</span></td>
      <td>2026-01-30</td>
      <td><button class="btn-icon">⋮</button></td>
    </tr>
  </tbody>
</table>
```

---

## Accessibility

- **Semantic HTML**: Use `<table>`, `<thead>`, `<tbody>`, `<th>`, `<tr>`, `<td>`
- **Headers**: Associate headers with `scope="col"` or `scope="row"`
- **Sorting**: Announce sort state to screen readers
- **Selection**: Support keyboard (Space to select, arrow keys to navigate)
- **Actions**: Ensure overflow menu accessible via keyboard

---

## References

- **Row heights**: [design-tokens.md](../foundation/design-tokens.md#grid--table)
- **Colors**: [visual-style-light.md](../visual/visual-style-light.md#tables)
- **Badges**: [component-button.md](component-button.md) (see badges section)
- **Icons**: [visual-style-icons.md](../visual/visual-style-icons.md)
