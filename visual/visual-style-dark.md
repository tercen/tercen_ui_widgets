# Visual Style: Dark Theme

**Purpose**: Color application for dark theme.

**Rule**: Structure mirrors [visual-style-light.md](visual-style-light.md). Only color values differ.

---

## Dark Theme Color Tokens

| Light Token | Dark Equivalent | Dark Value |
|-------------|-----------------|------------|
| `primary` | `primary-dark-theme` | #6D28D9 (violet) |
| `primary-dark` | `primary-dark-hover` | #5B21B6 |
| `primary-light` | `primary-dark-active` | #7C3AED |
| `link` | `link-dark` | #2DD4BF (teal) |
| `neutral-900` | `neutral-50` | #F9FAFB |
| `neutral-700` | `neutral-200` | #E5E7EB |
| `neutral-500` | `neutral-400` | #9CA3AF |
| `neutral-300` | `neutral-600` | #4B5563 |
| `neutral-100` | `neutral-800` | #1F2937 |
| `neutral-50` | `neutral-900` | #111827 |
| `white` | `neutral-900` | #111827 |

**Note**: Accent colors (green, teal, amber, red, violet) remain the same but are used on dark backgrounds.

---

## Buttons

### Primary Button
- **Background**: `primary-dark-theme` (#6D28D9)
- **Text**: `white`
- **Hover background**: `primary-dark-hover` (#5B21B6)
- **Active background**: `primary-dark-active` (#7C3AED)

### Secondary Button
- **Background**: transparent
- **Text**: `primary-dark-theme`
- **Border**: 1.5px solid `primary-dark-theme`
- **Hover background**: rgba(109, 40, 217, 0.1)

### Ghost Button
- **Background**: transparent
- **Text**: `primary-dark-theme`
- **Hover background**: rgba(109, 40, 217, 0.1)

### Subtle Button
- **Background**: `neutral-800` (#1F2937)
- **Text**: `neutral-200` (#E5E7EB)
- **Hover background**: `neutral-700`

### Danger Button
- **Background**: `red` (#B91C1C)
- **Text**: `white`
- **Hover background**: #991B1B

---

## Badges

Same structure as light theme, backgrounds adjust for dark:

### Success Badge
- **Background**: rgba(4, 120, 87, 0.15)
- **Text**: #10B981 (green-light for dark)
- **Dot**: #10B981

### Error Badge
- **Background**: rgba(185, 28, 28, 0.15)
- **Text**: #F87171 (red-light for dark)
- **Dot**: #F87171

### Warning Badge
- **Background**: rgba(180, 83, 9, 0.15)
- **Text**: #FBBF24 (amber-light for dark)
- **Dot**: #FBBF24

### Info Badge
- **Background**: rgba(14, 116, 144, 0.15)
- **Text**: #2DD4BF (teal-light for dark)
- **Dot**: #2DD4BF

---

## Alerts (Inline, Bordered)

### Success Alert
- **Background**: `neutral-900` (#111827)
- **Border**: 1px solid `neutral-700`, left: 4px solid `green`
- **Icon background**: rgba(4, 120, 87, 0.15)
- **Icon color**: #10B981
- **Title text**: `neutral-50`
- **Message text**: `neutral-200`

### Error Alert
- **Background**: `neutral-900`
- **Border**: 1px solid `neutral-700`, left: 4px solid `red`
- **Icon background**: rgba(185, 28, 28, 0.15)
- **Icon color**: #F87171
- **Title text**: `neutral-50`
- **Message text**: `neutral-200`

### Warning Alert
- **Background**: `neutral-900`
- **Border**: 1px solid `neutral-700`, left: 4px solid `amber`
- **Icon background**: rgba(180, 83, 9, 0.15)
- **Icon color**: #FBBF24
- **Title text**: `neutral-50`
- **Message text**: `neutral-200`

### Info Alert
- **Background**: `neutral-900`
- **Border**: 1px solid `neutral-700`, left: 4px solid `teal`
- **Icon background**: rgba(14, 116, 144, 0.15)
- **Icon color**: #2DD4BF
- **Title text**: `neutral-50`
- **Message text**: `neutral-200`

---

## Toast Notifications

Same as light theme (inverted style with solid backgrounds).

---

## Form Controls

### Text Input / Textarea
- **Background**: `neutral-900` (#111827)
- **Border**: 1px solid `neutral-700`
- **Text**: `neutral-50`
- **Placeholder**: `neutral-500`
- **Focus border**: `primary-dark-theme`
- **Error border**: `red`
- **Disabled background**: `neutral-800`
- **Disabled text**: `neutral-600`

### Select / Dropdown
- **Background**: `neutral-900`
- **Border**: 1px solid `neutral-700`
- **Text**: `neutral-50`
- **Hover background**: `neutral-800`
- **Focus border**: `primary-dark-theme`

### Checkbox
- **Background (unchecked)**: `neutral-900`
- **Border (unchecked)**: 1.5px solid `neutral-600`
- **Background (checked)**: `primary-dark-theme`
- **Border (checked)**: `primary-dark-theme`
- **Checkmark**: `white`

### Radio
- **Background (unchecked)**: `neutral-900`
- **Border (unchecked)**: 1.5px solid `neutral-600`
- **Background (checked)**: `neutral-900`
- **Border (checked)**: 1.5px solid `primary-dark-theme`
- **Dot (checked)**: `primary-dark-theme`

### Switch / Toggle
- **Background (off)**: `neutral-700`
- **Background (on)**: `primary-dark-theme`
- **Knob**: `white`

---

## Panels & Sections

### Panel
- **Background**: `neutral-900` (#111827)
- **Border**: 1px solid `neutral-800`
- **Shadow**: none (or subtle glow)

### Panel Header (Accent Style)
- **Background**: `primary-dark-theme` (#6D28D9)
- **Text**: `white`
- **Icons**: `white`

### Panel Header (Subtle Style)
- **Background**: `neutral-800`
- **Text**: `neutral-50`
- **Icons**: `neutral-400`
- **Border bottom**: 1px solid `neutral-700`

### Section Header
- **Background**: `neutral-800`
- **Text**: `neutral-400` (uppercase)
- **Icon**: `neutral-400`
- **Border bottom**: 1px solid `neutral-700`

---

## Tables

### Table Header
- **Background**: `neutral-800`
- **Text**: `neutral-200` (weight 600)
- **Border bottom**: 2px solid `neutral-700`

### Table Row
- **Background**: `neutral-900`
- **Text**: `neutral-200`
- **Border bottom**: 1px solid `neutral-800`
- **Hover background**: `neutral-800`
- **Selected background**: rgba(109, 40, 217, 0.15)

---

## Links

- **Text**: `link-dark` (#2DD4BF - teal)
- **Hover text**: #14B8A6 (teal-dark)
- **Visited**: `violet-light`
- **Disabled text**: `neutral-600`

---

## Icons

### Contextual Colors
- **Default**: `neutral-400`
- **Muted**: `neutral-500`
- **Emphasized**: `neutral-50`
- **Primary action**: `primary-dark-theme`
- **Success**: #10B981
- **Warning**: #FBBF24
- **Error**: #F87171
- **Info**: #2DD4BF

---

## Status Indicators

### Success
- **Color**: #10B981 (green-light for dark)
- **Background**: rgba(4, 120, 87, 0.15)

### Error
- **Color**: #F87171 (red-light for dark)
- **Background**: rgba(185, 28, 28, 0.15)

### Warning
- **Color**: #FBBF24 (amber-light for dark)
- **Background**: rgba(180, 83, 9, 0.15)

### Info
- **Color**: #2DD4BF (teal-light for dark)
- **Background**: rgba(14, 116, 144, 0.15)

---

## Emphasis & Hierarchy

### Text Hierarchy
- **Primary text**: `neutral-50` (headings, primary content)
- **Secondary text**: `neutral-200` (body text, descriptions)
- **Tertiary text**: `neutral-400` (supporting text, labels)
- **Muted text**: `neutral-500` (metadata, captions)
- **Disabled text**: `neutral-600`

### Background Hierarchy
- **Surface**: `neutral-900` (cards, panels, modals)
- **Surface elevated**: `neutral-800` (section headers, subtle emphasis)
- **Page background**: #0A0A0A (darker than neutral-900, behind surfaces)
- **Hover overlay**: `neutral-800` (interactive rows, items)

---

## Accent Usage

**Accent color**: `primary-dark-theme` (#6D28D9 - violet) used for:
- Left panel header background
- Primary buttons
- Links (use teal #2DD4BF for better dark mode contrast)
- Focus rings
- Active states
- Selection indicators

---

## Light-to-Dark Mapping Table

| Component | Light | Dark |
|-----------|-------|------|
| Primary button bg | #1E40AF (blue) | #6D28D9 (violet) |
| Link color | #1E40AF (blue) | #2DD4BF (teal) |
| Text (primary) | #111827 | #F9FAFB |
| Text (body) | #374151 | #E5E7EB |
| Surface | #FFFFFF | #111827 |
| Page background | #F3F4F6 | #0A0A0A |
| Border | #D1D5DB | #4B5563 |

---

## References

- **Light theme**: [visual-style-light.md](visual-style-light.md)
- **All dimensions**: [design-tokens.md](../foundation/design-tokens.md)
