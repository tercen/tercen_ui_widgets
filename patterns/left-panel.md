# Pattern: Left Panel

**Purpose**: Standard left panel component for all Tercen Flutter apps

**Prerequisites**:
1. Read [app-frame.md](app-frame.md) first for overall screen structure
2. Read [../components/component-panel.md](../components/component-panel.md) for complete panel specifications

---

## Overview

All Tercen apps use a **left panel** for controls, filters, and navigation. This pattern defines how to compose and use the panel component.

For overall app structure (container, main content, top bar, app types), see [app-frame.md](app-frame.md).

For complete panel specifications (dimensions, styling, behavior), see [component-panel.md](../components/component-panel.md).

---

## Dimensions

All dimensions reference [design-tokens.md](../foundation/design-tokens.md#panel-dimensions):
- Default width: `panelWidth` (280px)
- Min/max width: `panelMinWidth` / `panelMaxWidth` (280-400px)
- Collapsed width: `panelCollapsedWidth` (48px)
- Header height: `headerHeight` (48px)

---

## Header Composition

The header contains exactly 4 elements (left to right):

| Element | Required | Position | Behavior |
|---------|----------|----------|----------|
| App Icon | Yes | Left | Clicking expands panel when collapsed |
| App Title | Yes | Left (after icon) | Hidden when collapsed |
| Theme Toggle | Yes | Right | Hidden when collapsed |
| Collapse Chevron | Yes | Right (last) | Always visible |

### Header Styling

See [visual-style-light.md](../visual/visual-style-light.md#panel-header-accent-style) for complete styling specification.

**Key requirement**:
- Background: Accent color (`primary`)
- Text/Icons: White (reversed out)

### Theme Toggle Icons

| Current Theme | Icon Shown | Action |
|---------------|------------|--------|
| Light | Moon (`fa-moon`) | Switch to dark |
| Dark | Sun (`fa-sun`) | Switch to light |

**Rule**: The icon represents what you're switching TO, not the current state.

### Implementation Example

```dart
Container(
  height: AppSpacing.leftPanelHeaderHeight,
  color: AppColors.primary,
  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  child: Row(
    children: [
      // App Icon (required)
      GestureDetector(
        onTap: isCollapsed ? expandPanel : null,
        child: Icon(appIcon, color: Colors.white),
      ),
      SizedBox(width: AppSpacing.sm),

      // App Title (hidden when collapsed)
      if (!isCollapsed)
        Expanded(
          child: Text(
            appTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

      // Theme Toggle (hidden when collapsed)
      if (!isCollapsed)
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            color: Colors.white,
          ),
          onPressed: toggleTheme,
        ),

      // Collapse Chevron (always visible)
      IconButton(
        icon: Icon(
          isCollapsed ? Icons.chevron_right : Icons.chevron_left,
          color: Colors.white,
        ),
        onPressed: toggleCollapse,
      ),
    ],
  ),
)
```

---

## Section Requirements

### Section Structure

Each section has:

| Element | Required | Notes |
|---------|----------|-------|
| Section Icon | Yes | FontAwesome, defined in Functional Spec |
| Section Label | Yes | UPPERCASE, describes section purpose |
| Section Content | Yes | Controls, forms, lists, etc. |

See [visual-style-icons.md](../visual/visual-style-icons.md#tercen-specific-icons) for icon selection.

### Section Behavior

| Property | Value |
|----------|-------|
| Internal collapsing | **NO** - sections are always expanded |
| Visibility | All sections always visible |
| Navigation | Vertical scroll (no tabs) |
| Borders | Bottom border between sections |

### Section Styling Example

```dart
class LeftPanelSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: AppColors.surfaceElevated,
          child: Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              SizedBox(width: AppSpacing.sm),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Section Content
        Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: content,
        ),
      ],
    );
  }
}
```

---

## Standard Sections

All Tercen apps MUST include an **INFO** section as the last section in the left panel.

### INFO Section Requirements

| Element | Requirement |
| ------- | ----------- |
| Icon | `fa-info-circle` |
| Label | "INFO" (uppercase) |
| Position | Last section (bottom of panel) |

**Content Requirements:**

1. **GitHub Line** (required for all apps):
   - **Label**: "GitHub" (left-aligned)
   - **Value**: Hyperlink to the GitHub repository
   - **Link Text**:
     - Git tag if available (e.g., "v1.2.3")
     - OR 7-character short commit hash (e.g., "6f8c872")
     - OR blank/empty if unknown (during development)

### INFO Section Implementation

Use a build-time script to capture git information:

```dart
// lib/core/version/version_info.dart
class VersionInfo {
  static const String gitRepo = 'https://github.com/tercen/my-app';
  static const String gitVersion = '6f8c872'; // or 'v1.2.3' or ''
}
```

**Build Script** (add to `scripts/generate_version.dart`):

```dart
import 'dart:io';

void main() async {
  final gitTag = await _runGit(['describe', '--tags', '--exact-match']);
  final gitHash = await _runGit(['rev-parse', '--short=7', 'HEAD']);
  final gitRemote = await _runGit(['config', '--get', 'remote.origin.url']);

  final version = gitTag ?? gitHash ?? '';
  final repo = _formatRepoUrl(gitRemote ?? '');

  final content = '''
// GENERATED FILE - Do not edit
class VersionInfo {
  static const String gitRepo = '$repo';
  static const String gitVersion = '$version';
}
''';

  await File('lib/core/version/version_info.dart').writeAsString(content);
}

Future<String?> _runGit(List<String> args) async {
  try {
    final result = await Process.run('git', args);
    return result.exitCode == 0 ? result.stdout.toString().trim() : null;
  } catch (e) {
    return null;
  }
}

String _formatRepoUrl(String remote) {
  return remote
      .replaceAll('git@github.com:', 'https://github.com/')
      .replaceAll('.git', '');
}
```

**Display in INFO section:**

```dart
if (VersionInfo.gitVersion.isNotEmpty)
  Row(
    children: [
      Text('GitHub:', style: AppTextStyles.labelMedium),
      SizedBox(width: AppSpacing.xs),
      Expanded(
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(VersionInfo.gitRepo)),
          child: Text(
            VersionInfo.gitVersion,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ],
  ),
```

---

## Collapsed State

When collapsed, the panel transforms into an icon navigation strip.

**Complete collapse behavior**: See [component-panel.md](../components/component-panel.md#collapse)

> **CRITICAL**: The collapse must **change the panel width to 48px**, not just hide the content. If clicking the chevron only clears/hides the panel contents but the panel stays at 280px width, the implementation is wrong.

### Collapsed Layout

```
┌────────────────────┐
│    [App Icon]      │  ← Header (48px) - click expands
├────────────────────┤
│    [Section 1]     │  ← Section icons become
│    [Section 2]     │    vertical navigation
│    [Section 3]     │
│    [Section 4]     │
│        ...         │
├────────────────────┤
│    [Chevron →]     │  ← Footer - click expands
└────────────────────┘
     48px width
```

> **COMMON ERROR**: When collapsed, the **chevron moves from header to footer**. Do NOT keep the chevron in the header row when collapsed - icon (20px) + chevron button (32px) + padding won't fit in 48px. The collapsed header should contain ONLY the centered app icon.

### Collapsed Behavior

| Element | Visibility | Behavior |
|---------|------------|----------|
| App Icon | Visible | Click expands panel |
| App Title | Hidden | - |
| Theme Toggle | Hidden | - |
| Section Icons | Visible | Click expands AND scrolls to section |
| Section Labels | Hidden | - |
| Section Content | Hidden | - |
| Expand Chevron | Visible | Click expands panel |

### Click-to-Expand-and-Scroll

When a section icon is clicked in collapsed state:

1. Panel expands to default width (280px)
2. After animation completes (200ms - see `transition-base` in design-tokens.md)
3. Panel scrolls to bring that section into view

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

## Resize Behavior

Complete specification: [component-panel.md](../components/component-panel.md#resize)

| Property | Value |
|----------|-------|
| Resizable | Yes (drag right edge) |
| Min width | 280px |
| Max width | 400px |
| Persistence | No (resets on page reload) |
| Auto-collapse | No (manual only) |

---

## Functional Specification Requirements

The Functional Specification for each app MUST define:

| Item | Example |
|------|---------|
| App icon | `fa-images` (Image Overview) |
| App title | "Image Overview" |
| Section list | Filters, Display, View, Actions |
| Section icons | `fa-filter`, `fa-sliders`, `fa-eye`, `fa-bolt` |
| Section content | What controls appear in each section |

See [visual-style-icons.md](../visual/visual-style-icons.md) for icon selection guidance.

---

## Flutter Implementation Template

```dart
// lib/presentation/widgets/left_panel.dart
class LeftPanel extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<LeftPanelSection> sections;

  const LeftPanel({
    required this.appTitle,
    required this.appIcon,
    required this.sections,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  double _panelWidth = AppSpacing.leftPanelWidth;
  bool _isCollapsed = false;
  final Map<String, GlobalKey> _sectionKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: _isCollapsed
        ? AppSpacing.leftPanelCollapsedWidth
        : _panelWidth,
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

  // ... implementation details
}
```

---

## Checklist

When implementing a left panel:

- [ ] Read [app-frame.md](app-frame.md) first (overall structure)
- [ ] Read [component-panel.md](../components/component-panel.md) for complete specs
- [ ] Read Functional Specification for app icon, title, sections
- [ ] Set panel width to 280px default (from design-tokens.md)
- [ ] Implement header with all 4 required elements
- [ ] Use accent color for header background (see visual-style-light.md)
- [ ] Theme toggle shows moon (light) / sun (dark)
- [ ] Add section icons to all sections (see visual-style-icons.md)
- [ ] Section labels are UPPERCASE
- [ ] Sections do NOT collapse internally
- [ ] Implement collapsed state (48px icon strip)
- [ ] **VERIFY**: Collapse changes panel WIDTH to 48px (not just hiding content)
- [ ] App icon click expands when collapsed
- [ ] Section icon click expands AND scrolls
- [ ] Implement resize (280-400px range, see component-panel.md)
- [ ] Test both light and dark themes
- [ ] Add required INFO section as last section

---

## Related Documents

### Foundation
- [design-tokens.md](../foundation/design-tokens.md) - Panel dimensions, spacing, transitions
- [UI-DESIGN-MAP.md](../foundation/UI-DESIGN-MAP.md) - Navigation guide

### Visual Style
- [visual-style-light.md](../visual/visual-style-light.md) - Panel header styling, section colors
- [visual-style-dark.md](../visual/visual-style-dark.md) - Dark theme equivalents
- [visual-style-icons.md](../visual/visual-style-icons.md) - Icon selection for sections

### Components
- [component-panel.md](../components/component-panel.md) - Complete panel specifications
- [component-form-controls.md](../components/component-form-controls.md) - For section content

### Patterns
- [app-frame.md](app-frame.md) - Overall screen structure (read first)
