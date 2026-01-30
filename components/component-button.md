# Component: Button

**Purpose**: Primary interactive element for actions.

---

## Layout

### Heights
- **Small**: 28px (from `design-tokens.md`)
- **Default**: 36px
- **Large**: 44px

### Padding
- **Small**: 6px (vertical) × 12px (horizontal)
- **Default**: 10px × 20px
- **Large**: 14px × 28px

### Spacing
- **Icon + text gap**: `space-sm` (8px)
- **Button-to-button gap**: `space-sm` (8px) in horizontal groups

### Border Radius
- **All sizes**: `radius-md` (8px)

---

## Visual Style

See [visual-style-light.md](../visual/visual-style-light.md#buttons) or [visual-style-dark.md](../visual/visual-style-dark.md#buttons)

### Variants
- Primary
- Secondary
- Ghost
- Subtle
- Danger

### States per Variant
- Default
- Hover
- Active
- Disabled

---

## Defaults

- **Default variant**: Primary
- **Default size**: Default (36px)
- **Default state**: Enabled
- **Default alignment**: Left-aligned in groups

---

## Behavior

### Hover
- Apply hover state from visual style
- Transition: `transition-fast` (0.15s ease)
- Change background color only (no scale, no shadow change)

### Click
- Show active state briefly
- Trigger action on mouseup
- If async action, show loading state

### Disabled
- Apply disabled visual state
- Prevent all interactions
- Cursor: not-allowed
- No hover, no click

### Focus
- Show focus ring: 2px solid `primary` at 2px offset
- Keyboard: Space or Enter activates

### Loading
- Replace icon with spinner
- Keep text visible
- Maintain button dimensions
- Disable interactions during loading

---

## Usage

### Icon Buttons

**Icon only (no text):**
- Use Medium (20px) or Large (24px) icon size
- Square or near-square button (36px × 36px for default size)
- Requires accessible label/tooltip

**Icon + text:**
- Icon size: Default (16px)
- Icon position: Left of text (default)
- Right of text: For "forward" actions (Next, Submit, Send)

### Button Groups

**Horizontal group:**
- Gap: `space-sm` (8px) between buttons
- Primary action: Leftmost position
- Destructive action: Separated or rightmost

**Vertical stack:**
- Gap: `space-sm` (8px) between buttons
- Primary action: Top position
- Full-width buttons in stack

### Width Behavior

**Default**: Natural width (sized to content + padding)

**Full-width**: Use only when:
- Button is alone in a narrow container
- Vertical stack of form actions
- Mobile contexts

**Fixed-width**: Avoid unless required for alignment in specific layouts

---

## Variants Usage

| Variant | When to Use |
|---------|-------------|
| **Primary** | Primary action (Save, Submit, Continue, Run) |
| **Secondary** | Secondary actions alongside primary |
| **Ghost** | Tertiary actions, low emphasis (Cancel, Skip) |
| **Subtle** | Background actions, toolbars, least emphasis |
| **Danger** | Destructive actions (Delete, Remove, Discard) |

**Rule**: Maximum one Primary button per view/section. Multiple primaries create confusion.

---

## Implementation Examples

### Flutter

```dart
ElevatedButton(
  onPressed: onSave,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
  ),
  child: Text('Save'),
)
```

### Flutter (Icon + Text)

```dart
ElevatedButton.icon(
  onPressed: onRun,
  icon: FaIcon(FontAwesomeIcons.play, size: 16),
  label: Text('Run'),
  // ... same style as above
)
```

---

## Accessibility

- **Label**: Required (text or aria-label for icon-only)
- **Keyboard**: Space/Enter activates
- **Focus**: Visible focus ring required
- **Disabled**: Use `disabled` attribute, not visual-only
- **Loading**: Announce state change to screen readers

---

## References

- **Heights**: [design-tokens.md](../foundation/design-tokens.md#control-heights)
- **Padding**: [design-tokens.md](../foundation/design-tokens.md#spacing)
- **Colors**: [visual-style-light.md](../visual/visual-style-light.md#buttons)
- **Icons**: [visual-style-icons.md](../visual/visual-style-icons.md#button-icons)
