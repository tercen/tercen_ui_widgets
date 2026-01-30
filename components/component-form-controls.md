# Component: Form Controls

**Purpose**: Input elements for data entry and selection.

---

## Layout

### Control Heights
- **Small**: 28px (table cells, dense contexts)
- **Default**: 36px (standard forms)
- **Large**: 44px (primary inputs, emphasis)

### Control Widths

**Fixed-width by content type:**

| Content Type | Width | Example |
|--------------|-------|---------|
| Yes/No, On/Off | 80-100px | Boolean dropdowns |
| Short codes | 100-140px | Status values, enums |
| Names/Titles | 200-280px | File names, column names |
| Descriptions | 280-400px | Longer text, paths |
| Full width | 100% | Search bars (alone), multiline text |

**Rule**: Size controls to expected content, not available space.

---

## Visual Style

See [visual-style-light.md](../visual/visual-style-light.md#form-controls) or [visual-style-dark.md](../visual/visual-style-dark.md#form-controls)

---

## Defaults

### Text Input
- **Default size**: Default (36px)
- **Default width**: Sized to content (200-280px typical)
- **Default state**: Empty, enabled

### Select / Dropdown
- **Default size**: Default (36px)
- **Default width**: Sized to longest expected option
- **Default selection**: None (or first option if required)

### Checkbox
- **Default state**: Unchecked
- **Default size**: 16px × 16px

### Radio
- **Default state**: None selected (or first if required)
- **Default size**: 16px × 16px

### Switch / Toggle
- **Default state**: Off
- **Default size**: 20px height, 36px width

---

## Behavior

### Text Input / Textarea

**Focus:**
- Border changes to `primary` (2px)
- Show cursor
- No background color change

**Input:**
- Live validation (optional, for immediate feedback)
- Character counter (optional, for limited fields)

**Blur:**
- Validate input
- Show error state if invalid

**Error state:**
- Border: `red` (2px)
- Show error message below input
- Error message: 12px, `red` color

**Disabled:**
- Background: `neutral-50` (light), `neutral-800` (dark)
- Text: `neutral-400` (light), `neutral-600` (dark)
- Cursor: not-allowed

### Select / Dropdown

**Click:**
- Open dropdown menu below input (or above if insufficient space)
- Highlight current selection
- Support keyboard navigation (arrow keys)

**Selection:**
- Update displayed value
- Close dropdown
- Trigger onChange callback

**Search (optional):**
- For long lists, add search/filter input at top of dropdown

### Checkbox

**Click:**
- Toggle checked state
- Transition: `transition-fast` (0.15s ease)
- Trigger onChange callback

**Keyboard:**
- Space toggles state
- Tab navigates to next control

### Radio

**Click:**
- Select this option
- Deselect all other options in group
- Trigger onChange callback

**Keyboard:**
- Arrow keys navigate within group
- Space selects

### Switch / Toggle

**Click:**
- Toggle on/off state
- Knob slides with animation (`transition-fast`)
- Trigger onChange callback

**Keyboard:**
- Space toggles state

---

## Form Layout Patterns

### Label Placement

**Above input (recommended):**
```
Label
[Input field_________]
```
- Clear association
- Works well in narrow containers
- Consistent layout

**Beside input (use sparingly):**
```
Label:  [Input field__]
```
- Use only for very short forms
- Requires wider container
- Align labels right for cleaner edge

### Label Styling
- **Font size**: `text-sm` (13px) or `text-base` (14px)
- **Font weight**: `weight-medium` (500) or `weight-semibold` (600)
- **Color**: `neutral-700` (light), `neutral-200` (dark)
- **Margin below**: `space-xs` (4px)

### Error Messages
- **Position**: Below input, immediately after
- **Font size**: `text-sm` (13px)
- **Color**: `red`
- **Icon**: Optional `fa-triangle-exclamation`
- **Margin top**: `space-xs` (4px)

### Help Text
- **Position**: Below input (below error if present)
- **Font size**: `text-sm` (13px)
- **Color**: `neutral-500`
- **Margin top**: `space-xs` (4px)

### Field Spacing
- **Between fields**: `space-md` (16px)
- **Between field groups**: `space-lg` (24px)

---

## Validation States

| State | Border | Background | Icon | Message |
|-------|--------|------------|------|---------|
| Default | `neutral-300` | `white` | - | - |
| Focus | `primary` | `white` | - | - |
| Valid | `green` | `white` | `fa-circle-check` (optional) | - |
| Error | `red` | `white` | `fa-triangle-exclamation` | Required, below input |
| Disabled | `neutral-200` | `neutral-50` | - | - |

---

## Accessibility

### Text Input
- **Label**: Required (associated with `for` attribute or wrapping)
- **Placeholder**: Descriptive but not a replacement for label
- **Error**: Announce to screen readers (`aria-describedby`)

### Select
- **Label**: Required
- **Options**: Use semantic `<option>` elements
- **Keyboard**: Arrow keys navigate, Enter selects

### Checkbox / Radio
- **Label**: Required (clickable, increases hit area)
- **Grouping**: Use fieldset + legend for radio groups
- **Keyboard**: Space toggles, Tab navigates

### Switch
- **Label**: Required
- **Role**: `role="switch"` with `aria-checked`
- **Keyboard**: Space toggles

---

## Implementation Examples

### Flutter Text Input

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'you@example.com',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
  ),
)
```

### Flutter Dropdown

```dart
DropdownButton<String>(
  value: selectedValue,
  items: options.map((option) {
    return DropdownMenuItem(
      value: option,
      child: Text(option),
    );
  }).toList(),
  onChanged: (value) => setState(() => selectedValue = value),
)
```

---

## References

- **Heights**: [design-tokens.md](../foundation/design-tokens.md#control-heights)
- **Colors**: [visual-style-light.md](../visual/visual-style-light.md#form-controls)
- **Spacing**: [design-tokens.md](../foundation/design-tokens.md#spacing)
