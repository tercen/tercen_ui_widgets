# Visual Style: Icons

**Purpose**: Icon selection and color mapping for Tercen UI.

**Icon library**: FontAwesome 6 (Free)

---

## Icon Colors by Context

| Context | Light Theme | Dark Theme |
|---------|-------------|------------|
| Default | `neutral-600` | `neutral-400` |
| Muted | `neutral-500` | `neutral-500` |
| Emphasized | `neutral-900` | `neutral-50` |
| Primary action | `primary` | `primary-dark-theme` |
| On accent background | `white` | `white` |
| Success | `green` | #10B981 |
| Warning | `amber` | #FBBF24 |
| Error | `red` | #F87171 |
| Info | `teal` | #2DD4BF |

---

## Semantic Icon Map

### Document Types

| Type | Icon | Color (Light) | Color (Dark) |
|------|------|---------------|---------------|
| Folder | `fa-folder` | `amber` | #FBBF24 |
| Project | `fa-folder-tree` | `amber` | #FBBF24 |
| Table | `fa-table` | `green` | #10B981 |
| File (generic) | `fa-file` | `neutral-600` | `neutral-400` |
| Workflow | `fa-diagram-project` | `primary` | `primary-dark-theme` |
| Operator | `fa-cube` | `violet` | `violet-light` |
| Data step | `fa-database` | `teal` | #2DD4BF |
| Image | `fa-image` | `violet` | `violet-light` |
| Chart | `fa-chart-simple` | `teal` | #2DD4BF |

### Actions

| Action | Icon | Color | Usage |
|--------|------|-------|-------|
| Add | `fa-plus` | `primary` | Create, add new |
| Delete | `fa-trash` | `red` | Remove, delete |
| Edit | `fa-pen` | `neutral-600` | Edit, modify |
| Save | `fa-floppy-disk` | `primary` | Save changes |
| Run | `fa-play` | `green` | Execute, start |
| Stop | `fa-stop` | `red` | Stop, cancel |
| Refresh | `fa-rotate` | `neutral-600` | Reload, refresh |
| Download | `fa-download` | `neutral-600` | Download, export |
| Upload | `fa-upload` | `neutral-600` | Upload, import |
| Copy | `fa-copy` | `neutral-600` | Duplicate, copy |
| Settings | `fa-gear` | `neutral-600` | Settings, config |
| Filter | `fa-filter` | `neutral-600` | Filter data |
| Search | `fa-magnifying-glass` | `neutral-600` | Search, find |
| Close | `fa-xmark` | `neutral-600` | Close, dismiss |

### Navigation

| Action | Icon | Usage |
|--------|------|-------|
| Expand | `fa-chevron-right` | Expand panel, navigate forward |
| Collapse | `fa-chevron-left` | Collapse panel, navigate back |
| Expand down | `fa-chevron-down` | Expand section downward |
| Collapse up | `fa-chevron-up` | Collapse section upward |
| Menu | `fa-bars` | Open menu |
| More | `fa-ellipsis` | More options (horizontal) |
| More (vertical) | `fa-ellipsis-vertical` | More options (vertical) |

### Status

| Status | Icon | Color (Light) | Color (Dark) |
|--------|------|---------------|---------------|
| Success | `fa-circle-check` | `green` | #10B981 |
| Error | `fa-circle-xmark` | `red` | #F87171 |
| Warning | `fa-triangle-exclamation` | `amber` | #FBBF24 |
| Info | `fa-circle-info` | `teal` | #2DD4BF |
| Pending | `fa-clock` | `neutral-500` | `neutral-500` |
| Loading | `fa-spinner` (animated) | `primary` | `primary-dark-theme` |

### UI Elements

| Element | Icon | Usage |
|---------|------|-------|
| User | `fa-user` | User profile, account |
| Theme (light) | `fa-sun` | Switch to dark mode |
| Theme (dark) | `fa-moon` | Switch to light mode |
| Help | `fa-circle-question` | Help, info |
| Info | `fa-info-circle` | Information section |
| Lock | `fa-lock` | Locked, secured |
| Unlock | `fa-unlock` | Unlocked, accessible |
| Eye (visible) | `fa-eye` | Show, visible |
| Eye (hidden) | `fa-eye-slash` | Hide, invisible |
| Pin | `fa-thumbtack` | Pin, keep visible |

---

## Icon Sizes

| Size | Value | Usage |
|------|-------|-------|
| Extra small | 10px | Inline, tight contexts |
| Small | 12px | Section headers, labels |
| Default | 16px | Standard UI, buttons |
| Medium | 20px | Prominent actions |
| Large | 24px | App icons, header icons |
| Extra large | 32px | Empty states, hero icons |

---

## Icon Usage Rules

### Pairing with Text

| Spacing | Value |
|---------|-------|
| Icon + text gap | `space-sm` (8px) |
| Icon + label gap | `space-xs` (4px) |

### Button Icons

- **Icon-only button**: Use Medium (20px) or Large (24px) size
- **Icon + text button**: Use Default (16px) size, `space-sm` gap
- **Icon position**: Left of text (default), right for "forward" actions

### Section Headers

- **Icon size**: Small (12px)
- **Icon color**: `neutral-500` (light), `neutral-400` (dark)
- **Icon + label gap**: `space-sm` (8px)

### Panel Headers

- **Icon size**: Large (24px) for app icon
- **Icon size**: Default (16px) for action icons
- **Icon color**: `white` (on accent background)

---

## Tercen-Specific Icons

### Left Panel Sections

| Section | Icon | Example Usage |
|---------|------|---------------|
| Filters | `fa-filter` | Image Overview filters |
| Display | `fa-sliders` | Display options, settings |
| View | `fa-eye` | View controls, visibility |
| Actions | `fa-bolt` | Action buttons, operations |
| Info | `fa-info-circle` | Info section (required for all apps) |
| Data | `fa-database` | Data selection, sources |
| Settings | `fa-gear` | Configuration, preferences |

### App Icons

| App Type | Icon | Color |
|----------|------|-------|
| Image viewer | `fa-images` | `violet` |
| Chart viewer | `fa-chart-line` | `teal` |
| Table viewer | `fa-table` | `green` |
| QC tool | `fa-check-circle` | `green` |
| Analysis | `fa-calculator` | `primary` |
| Transform | `fa-shuffle` | `violet` |

---

## Implementation

### Flutter (FontAwesome Flutter)

```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Usage
FaIcon(
  FontAwesomeIcons.filter,
  size: 12,
  color: AppColors.textMuted,
)
```

### Web (FontAwesome CDN)

```html
<i class="fa-solid fa-filter"></i>
```

```css
.section-icon {
  font-size: 12px;
  color: var(--neutral-500);
}
```

---

## References

- **Icon colors**: [visual-style-light.md](visual-style-light.md), [visual-style-dark.md](visual-style-dark.md)
- **Icon spacing**: [design-tokens.md](../foundation/design-tokens.md#spacing)
