# UI Design Map

**Purpose**: Master navigation for Tercen UI design system.

**Rule**: Start here. Follow the hierarchy. Don't skip layers.

---

## Hierarchy

```
1. FOUNDATION (read first)
   ├── design-tokens.md ← START HERE
   └── UI-DESIGN-MAP.md (this file)

2. VISUAL STYLE (colors, typography applied)
   ├── visual-style-light.md
   ├── visual-style-dark.md
   └── visual-style-icons.md

3. COMPONENTS (what exists, how it works)
   ├── component-button.md
   ├── component-panel.md
   ├── component-panel-header.md
   ├── component-section-header.md
   ├── component-form-controls.md
   ├── component-grid.md
   └── component-table.md

4. PATTERNS (how components compose)
   ├── pattern-app-frame.md
   ├── pattern-left-panel.md
   └── pattern-content-flow.md
```

---

## Decision Tree: Which File Do I Read?

### Need a specific value (color, spacing, dimension)?
→ **[design-tokens.md](design-tokens.md)**

### Need to know what color to use for a button/badge/alert?
→ **[visual-style-light.md](../visual/visual-style-light.md)** or **[visual-style-dark.md](../visual/visual-style-dark.md)**

### Need complete spec for a UI element (button, panel, form)?
→ **Components**: [component-button.md](../components/component-button.md), [component-panel.md](../components/component-panel.md), etc.

### Need to know how to structure an entire app screen?
→ **Patterns**: [pattern-app-frame.md](../patterns/pattern-app-frame.md), [pattern-left-panel.md](../patterns/pattern-left-panel.md)

### Building a new Tercen app from scratch?
→ Read in order:
1. [design-tokens.md](design-tokens.md) - understand the system
2. [visual-style-light.md](../visual/visual-style-light.md) - understand visual language
3. [pattern-app-frame.md](../patterns/pattern-app-frame.md) - understand app structure
4. [pattern-left-panel.md](../patterns/pattern-left-panel.md) - understand left panel pattern
5. Relevant component files as needed

---

## Checklist by Layer

### Foundation ✓
- [ ] Read design-tokens.md
- [ ] Understand spacing scale (4, 8, 16, 24, 32, 48)
- [ ] Understand component dimensions (28/36/44px heights)
- [ ] Understand color tokens (primary, accent, neutrals)

### Visual Style ✓
- [ ] Read visual-style-light.md (or dark)
- [ ] Understand how colors apply to components
- [ ] Understand typography application
- [ ] Understand state styling (hover, focus, disabled)

### Components ✓
- [ ] Identify which components your app needs
- [ ] Read complete spec for each (Layout, Visual, Defaults, Behavior)
- [ ] Understand component APIs and props
- [ ] Understand component state management

### Patterns ✓
- [ ] Read pattern-app-frame.md for overall structure
- [ ] Read pattern-left-panel.md if app has left panel
- [ ] Understand composition rules
- [ ] Understand context detection (embedded vs full screen)

---

## Quick Reference Table

| Need... | File | Section |
|---------|------|---------|
| Spacing value | design-tokens.md | Spacing |
| Button height | design-tokens.md | Component Dimensions → Control Heights |
| Panel width | design-tokens.md | Component Dimensions → Panel Dimensions |
| Primary color hex | design-tokens.md | Colors → Primary |
| Button color (light) | visual-style-light.md | Buttons |
| Button color (dark) | visual-style-dark.md | Buttons |
| Button complete spec | component-button.md | All sections |
| Panel collapse behavior | component-panel.md | Behavior |
| Left panel pattern | pattern-left-panel.md | All sections |
| App structure | pattern-app-frame.md | All sections |
| Icon colors | visual-style-icons.md | Icon Semantic Map |

---

## File Relationships

### design-tokens.md is referenced by:
- All visual-style-*.md files (for color/typography values)
- All component-*.md files (for dimensions/spacing)
- All pattern-*.md files (for layout values)

### visual-style-light.md is referenced by:
- All component-*.md files (for color application)
- All pattern-*.md files (for styling context)

### component-*.md files are referenced by:
- pattern-*.md files (for composition)

### Deprecated Files (Do Not Use):
- `_local/tercen-style/specifications/*.html` - Visual reference only, not authoritative
- See individual pattern files for migration notes

---

## Implementation Flow

```
1. Read design-tokens.md
   ↓
2. Read visual-style-light.md (or dark)
   ↓
3. Read pattern-app-frame.md
   ↓
4. Read pattern-left-panel.md (if applicable)
   ↓
5. Read component-*.md files as needed
   ↓
6. Implement with references to tokens
```

---

## Validation Checklist

Before considering UI implementation complete:

- [ ] All spacing uses tokens from design-tokens.md (no hardcoded 10px, 15px, etc.)
- [ ] All colors reference tokens (no hardcoded hex values)
- [ ] All component dimensions match specs in component-*.md files
- [ ] Panel widths: 280px default, 280-400px range, 48px collapsed
- [ ] Left panel header: accent background, white text/icons, 4 required elements
- [ ] Grid gaps: equal in both directions (typically 4px)
- [ ] No right sidebars (left-out pattern)
- [ ] All interactive elements have visible affordances (no hover-only features)

---

## Getting Help

**Found a conflict or ambiguity?**
- File an issue - these docs should be unambiguous

**Need a value not documented?**
- Check design-tokens.md first
- If missing, propose addition (don't invent arbitrary values)

**Pattern doesn't fit your use case?**
- Describe the use case
- We'll determine if pattern needs extension or if different pattern applies
