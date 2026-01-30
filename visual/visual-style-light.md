# Visual Style: Light Theme

**Purpose**: Color and typography application for light theme.

**Rule**: All values reference [design-tokens.md](../foundation/design-tokens.md). No hardcoded colors.

---

## Buttons

### Primary Button
- **Background**: `primary` (#1E40AF)
- **Text**: `white`
- **Border**: none
- **Hover background**: `primary-dark` (#1E3A8A)
- **Active background**: `primary-light` (#2563EB)
- **Disabled background**: `neutral-200`
- **Disabled text**: `neutral-400`

### Secondary Button
- **Background**: transparent
- **Text**: `primary`
- **Border**: 1.5px solid `primary`
- **Hover background**: `primary-bg`
- **Active background**: `primary-surface`

### Ghost Button
- **Background**: transparent
- **Text**: `primary`
- **Border**: none
- **Hover background**: `primary-bg`
- **Active background**: `primary-surface`

### Subtle Button
- **Background**: `neutral-100`
- **Text**: `neutral-700`
- **Border**: none
- **Hover background**: `neutral-200`
- **Active background**: `neutral-300`

### Danger Button
- **Background**: `red` (#B91C1C)
- **Text**: `white`
- **Border**: none
- **Hover background**: #991B1B (red-dark)
- **Active background**: `red-light`

---

## Badges

### Success Badge
- **Background**: `green-light` (#D1FAE5)
- **Text**: `green` (#047857)
- **Dot**: `green`

### Info Badge
- **Background**: `teal-light` (#CFFAFE)
- **Text**: `teal` (#0E7490)
- **Dot**: `teal`

### Warning Badge
- **Background**: `amber-light` (#FEF3C7)
- **Text**: `amber` (#B45309)
- **Dot**: `amber`

### Error Badge
- **Background**: `red-light` (#FEE2E2)
- **Text**: `red` (#B91C1C)
- **Dot**: `red`

### Primary Badge
- **Background**: `primary-surface` (#DBEAFE)
- **Text**: `primary` (#1E40AF)
- **Dot**: `primary`

### Neutral Badge
- **Background**: `neutral-100` (#F3F4F6)
- **Text**: `neutral-600` (#4B5563)
- **Dot**: `neutral-400`

---

## Alerts (Inline, Bordered)

### Success Alert
- **Background**: `white`
- **Border**: 1px solid `neutral-200`, left: 4px solid `green`
- **Icon background**: `green-light`
- **Icon color**: `green`
- **Title text**: `neutral-900`
- **Message text**: `neutral-700`

### Info Alert
- **Background**: `white`
- **Border**: 1px solid `neutral-200`, left: 4px solid `teal`
- **Icon background**: `teal-light`
- **Icon color**: `teal`
- **Title text**: `neutral-900`
- **Message text**: `neutral-700`

### Warning Alert
- **Background**: `white`
- **Border**: 1px solid `neutral-200`, left: 4px solid `amber`
- **Icon background**: `amber-light`
- **Icon color**: `amber`
- **Title text**: `neutral-900`
- **Message text**: `neutral-700`

### Error Alert
- **Background**: `white`
- **Border**: 1px solid `neutral-200`, left: 4px solid `red`
- **Icon background**: `red-light`
- **Icon color**: `red`
- **Title text**: `neutral-900`
- **Message text**: `neutral-700`

---

## Toast Notifications (Bold, Inverted)

### Success Toast
- **Background**: `green` (#047857)
- **Text**: `white`
- **Icon background**: rgba(255, 255, 255, 0.2)
- **Shadow**: `shadow-lg`

### Info Toast
- **Background**: `teal` (#0E7490)
- **Text**: `white`
- **Icon background**: rgba(255, 255, 255, 0.2)
- **Shadow**: `shadow-lg`

### Warning Toast
- **Background**: `amber` (#B45309)
- **Text**: `white`
- **Icon background**: rgba(255, 255, 255, 0.2)
- **Shadow**: `shadow-lg`

### Error Toast
- **Background**: `red` (#B91C1C)
- **Text**: `white`
- **Icon background**: rgba(255, 255, 255, 0.2)
- **Shadow**: `shadow-lg`

---

## Form Controls

### Text Input / Textarea
- **Background**: `white`
- **Border**: 1px solid `neutral-300`
- **Text**: `neutral-900`
- **Placeholder**: `neutral-500`
- **Focus border**: `primary`
- **Error border**: `red`
- **Disabled background**: `neutral-50`
- **Disabled text**: `neutral-400`

### Select / Dropdown
- **Background**: `white`
- **Border**: 1px solid `neutral-300`
- **Text**: `neutral-900`
- **Hover background**: `neutral-50`
- **Focus border**: `primary`
- **Disabled background**: `neutral-50`
- **Disabled text**: `neutral-400`

### Checkbox
- **Background (unchecked)**: `white`
- **Border (unchecked)**: 1.5px solid `neutral-400`
- **Background (checked)**: `primary`
- **Border (checked)**: `primary`
- **Checkmark**: `white`
- **Disabled background**: `neutral-200`
- **Disabled border**: `neutral-300`

### Radio
- **Background (unchecked)**: `white`
- **Border (unchecked)**: 1.5px solid `neutral-400`
- **Background (checked)**: `white`
- **Border (checked)**: 1.5px solid `primary`
- **Dot (checked)**: `primary`
- **Disabled background**: `neutral-200`
- **Disabled border**: `neutral-300`

### Switch / Toggle
- **Background (off)**: `neutral-300`
- **Background (on)**: `primary`
- **Knob**: `white`
- **Disabled background**: `neutral-200`

---

## Panels & Sections

### Panel
- **Background**: `white`
- **Border**: 1px solid `neutral-200`
- **Shadow**: `shadow-sm`

### Panel Header (Accent Style)
- **Background**: `primary` (#1E40AF)
- **Text**: `white`
- **Icons**: `white`
- **Border bottom**: none

### Panel Header (Subtle Style)
- **Background**: `neutral-50`
- **Text**: `neutral-900`
- **Icons**: `neutral-600`
- **Border bottom**: 1px solid `neutral-200`

### Section Header
- **Background**: `neutral-50`
- **Text**: `neutral-500` (uppercase, 11px, weight 600)
- **Icon**: `neutral-500` (12px size)
- **Border bottom**: 1px solid `neutral-200`

---

## Tables

### Table Header
- **Background**: `neutral-50`
- **Text**: `neutral-700` (weight 600)
- **Border bottom**: 2px solid `neutral-200`

### Table Row
- **Background**: `white`
- **Text**: `neutral-700`
- **Border bottom**: 1px solid `neutral-100`
- **Hover background**: `neutral-50`
- **Selected background**: `primary-bg`

### Table Cell
- **Padding**: 12px (compact) / 16px (comfortable)
- **Text alignment**: left (default)

---

## Links

- **Text**: `primary` (#1E40AF)
- **Hover text**: `primary-dark` (#1E3A8A)
- **Visited**: `violet` (#6D28D9)
- **Underline**: optional, on hover
- **Disabled text**: `neutral-400`

---

## Icons

### Contextual Colors
- **Default**: `neutral-600`
- **Muted**: `neutral-500`
- **Emphasized**: `neutral-900`
- **Primary action**: `primary`
- **Success**: `green`
- **Warning**: `amber`
- **Error**: `red`
- **Info**: `teal`

### On Colored Backgrounds
- **On primary**: `white`
- **On accent colors**: `white`
- **On light backgrounds**: inherit from context

---

## Status Indicators

### Success
- **Color**: `green` (#047857)
- **Background**: `green-light` (#D1FAE5)
- **Icon**: checkmark, check-circle

### Error
- **Color**: `red` (#B91C1C)
- **Background**: `red-light` (#FEE2E2)
- **Icon**: x-mark, alert-triangle

### Warning
- **Color**: `amber` (#B45309)
- **Background**: `amber-light` (#FEF3C7)
- **Icon**: alert-triangle, exclamation

### Info
- **Color**: `teal` (#0E7490)
- **Background**: `teal-light` (#CFFAFE)
- **Icon**: info-circle, lightbulb

### Neutral
- **Color**: `neutral-600` (#4B5563)
- **Background**: `neutral-100` (#F3F4F6)
- **Icon**: minus-circle, dot

---

## Emphasis & Hierarchy

### Text Hierarchy
- **Primary text**: `neutral-900` (headings, primary content)
- **Secondary text**: `neutral-700` (body text, descriptions)
- **Tertiary text**: `neutral-600` (supporting text, labels)
- **Muted text**: `neutral-500` (metadata, captions)
- **Disabled text**: `neutral-400`

### Background Hierarchy
- **Surface**: `white` (cards, panels, modals)
- **Surface elevated**: `neutral-50` (section headers, subtle emphasis)
- **Page background**: `neutral-100` (body, behind surfaces)
- **Hover overlay**: `neutral-50` (interactive rows, items)

---

## Accent Usage

**Accent color**: `primary` (#1E40AF) used for:
- Left panel header background
- Primary buttons
- Links
- Focus rings
- Active states
- Selection indicators

**Rule**: Accent should be used sparingly for emphasis. Not every interactive element needs accent color.

---

## References

- **All color values**: [design-tokens.md](../foundation/design-tokens.md)
- **Component dimensions**: See component-*.md files
- **Dark theme equivalents**: [visual-style-dark.md](visual-style-dark.md)
