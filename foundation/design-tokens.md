# Design Tokens

**Purpose**: Single source of truth for all dimension, color, and style values.

**Rule**: All other files REFERENCE these tokens. Never duplicate values.

---

## Spacing

**Base grid**: 8px
**Tight contexts**: 4px

| Token | Value | Usage |
|-------|-------|-------|
| `space-xs` | 4px | Grid gaps, icon-to-text, inline elements |
| `space-sm` | 8px | Related elements, list items, tight groups |
| `space-md` | 16px | Component padding, form field spacing |
| `space-lg` | 24px | Section spacing, card groups |
| `space-xl` | 32px | Page margins, major sections |
| `space-2xl` | 48px | Major page regions |

**Rule**: Use only these values. Never: 10px, 12px, 15px, 18px, 22px.

---

## Component Dimensions

### Control Heights

| Size | Height | Usage |
|------|--------|-------|
| Small | 28px | Table cells, dense toolbars, inline forms |
| Default | 36px | Standard forms, most contexts |
| Large | 44px | Primary actions, emphasis, hero inputs |

### Panel Dimensions

| Property | Value |
|----------|-------|
| `panelWidth` | 280px |
| `panelMinWidth` | 280px |
| `panelMaxWidth` | 400px |
| `panelCollapsedWidth` | 48px |

### Header Dimensions

| Property | Value |
|----------|-------|
| `headerHeight` | 48px |
| `topBarHeight` | 48px |

### Container Dimensions

| Property | Value |
|----------|-------|
| `appContainerWidth` | 100vw |
| `appContainerHeight` | 100vh |

---

## Colors

### Primary

| Token | Value | Usage |
|-------|-------|-------|
| `primary` | #1E40AF | Primary actions, links, focus |
| `primary-dark` | #1E3A8A | Hover states, emphasis |
| `primary-light` | #2563EB | Active states |
| `primary-surface` | #DBEAFE | Subtle backgrounds |
| `primary-bg` | #EFF6FF | Large area backgrounds |

### Accent Colors

| Token | Value | Usage |
|-------|-------|-------|
| `green` | #047857 | Success, positive, enabled |
| `green-light` | #D1FAE5 | Success backgrounds |
| `teal` | #0E7490 | Info, neutral status |
| `teal-light` | #CFFAFE | Info backgrounds |
| `amber` | #B45309 | Warning, caution |
| `amber-light` | #FEF3C7 | Warning backgrounds |
| `red` | #B91C1C | Error, danger, destructive |
| `red-light` | #FEE2E2 | Error backgrounds |
| `violet` | #6D28D9 | Tertiary, new features |
| `violet-light` | #EDE9FE | Tertiary backgrounds |

### Neutrals

| Token | Value | Usage |
|-------|-------|-------|
| `neutral-900` | #111827 | Primary text, headings |
| `neutral-800` | #1F2937 | Dark text |
| `neutral-700` | #374151 | Body text |
| `neutral-600` | #4B5563 | Secondary text |
| `neutral-500` | #6B7280 | Muted text, placeholders |
| `neutral-400` | #9CA3AF | Disabled text |
| `neutral-300` | #D1D5DB | Borders, dividers |
| `neutral-200` | #E5E7EB | Subtle borders |
| `neutral-100` | #F3F4F6 | Backgrounds, hover states |
| `neutral-50` | #F9FAFB | Subtle backgrounds |
| `white` | #FFFFFF | Surfaces, reversed text |

---

## Typography

### Font Families

| Token | Value |
|-------|-------|
| `font-family` | 'Fira Sans', -apple-system, BlinkMacSystemFont, sans-serif |
| `font-mono` | 'SF Mono', 'Consolas', 'Monaco', monospace |

### Font Sizes

| Token | Value | Usage |
|-------|-------|-------|
| `text-xs` | 11px | Labels, captions, metadata |
| `text-sm` | 13px | Secondary text, table cells |
| `text-base` | 14px | Body text, form inputs |
| `text-md` | 16px | Emphasis, large body |
| `text-lg` | 18px | Subheadings, card titles |
| `text-xl` | 24px | Section titles |
| `text-2xl` | 32px | Page titles |

### Font Weights

| Token | Value | Usage |
|-------|-------|-------|
| `weight-light` | 300 | Light text, large headings |
| `weight-regular` | 400 | Body text, default |
| `weight-medium` | 500 | Emphasis, buttons |
| `weight-semibold` | 600 | Headings, labels |
| `weight-bold` | 700 | Strong emphasis, titles |

### Line Heights

| Token | Value | Usage |
|-------|-------|-------|
| `leading-tight` | 1.25 | Headings, compact text |
| `leading-normal` | 1.5 | Body text, default |
| `leading-relaxed` | 1.75 | Comfortable reading |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 4px | Badges, small elements |
| `radius-md` | 8px | Buttons, inputs, cards |
| `radius-lg` | 12px | Panels, large cards |
| `radius-xl` | 16px | Modals, major containers |
| `radius-full` | 9999px | Pills, circular elements |

---

## Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `shadow-sm` | 0 1px 2px rgba(0,0,0,0.05) | Subtle elevation |
| `shadow-md` | 0 4px 6px rgba(0,0,0,0.07) | Cards, dropdowns |
| `shadow-lg` | 0 10px 15px rgba(0,0,0,0.1) | Modals, popovers |
| `shadow-xl` | 0 20px 25px rgba(0,0,0,0.15) | High elevation |

---

## Grid & Table

### Image Grid

| Property | Value |
|----------|-------|
| Cell gap | 4px (both horizontal and vertical) |
| Container padding | 16px |

**Rule**: Gaps must be equal in both directions.

### Data Table

| Property | Value |
|----------|-------|
| Row height (compact) | 32px |
| Row height (default) | 40px |
| Row height (comfortable) | 48px |
| Cell horizontal padding | 12px (compact) / 16px (comfortable) |

---

## Transitions

| Property | Value | Usage |
|----------|-------|-------|
| `transition-fast` | 0.15s ease | Button hover, color changes |
| `transition-base` | 0.2s ease | Panel collapse, smooth interactions |
| `transition-slow` | 0.3s ease | Scroll animations |

---

## References

Used by:
- [visual-style-light.md](../visual/visual-style-light.md)
- [visual-style-dark.md](../visual/visual-style-dark.md)
- [component-button.md](../components/component-button.md)
- [component-panel.md](../components/component-panel.md)
- [component-form-controls.md](../components/component-form-controls.md)
- [component-grid.md](../components/component-grid.md)
- [component-table.md](../components/component-table.md)
- [pattern-app-frame.md](../patterns/pattern-app-frame.md)
- [pattern-left-panel.md](../patterns/pattern-left-panel.md)
