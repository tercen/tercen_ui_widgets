# Pattern: App Frame

**Purpose**: Overall screen structure for all Tercen Flutter apps

**Read this FIRST** before reading component patterns (left-panel.md, etc.)

**Reference**: `_local/left-panel-testboard.html` (v3.1) - Interactive demonstration

## Overview

All Tercen apps share a common frame structure. This pattern defines the overall layout that contains all UI components.

## Reading Order

When building a Tercen app UI, Claude should read patterns in this order:

```
1. app-frame.md        ← You are here (overall structure)
2. left-panel.md       ← Left panel component
3. Functional Spec     ← App-specific content
```

## Frame Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      App Container                          │
│  ┌──────────────┬────────────────────────────────────────┐  │
│  │              │  ┌──────────────────────────────────┐  │  │
│  │              │  │      Top Bar (conditional)       │  │  │
│  │              │  └──────────────────────────────────┘  │  │
│  │  Left Panel  │  ┌──────────────────────────────────┐  │  │
│  │  (component) │  │                                  │  │  │
│  │              │  │       Main Content Area          │  │  │
│  │              │  │                                  │  │  │
│  │              │  │                                  │  │  │
│  │              │  └──────────────────────────────────┘  │  │
│  └──────────────┴────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Container Rules

| Property | Value |
|----------|-------|
| Layout | Flex row |
| Width | 100vw (full viewport) |
| Height | 100vh (full viewport) |
| Overflow | Hidden (components handle their own scroll) |

```dart
// lib/presentation/screens/app_frame.dart
class AppFrame extends StatelessWidget {
  final Widget leftPanel;
  final Widget mainContent;
  final bool showTopBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel (component)
          leftPanel,

          // Main Panel (top bar + content)
          Expanded(
            child: Column(
              children: [
                if (showTopBar) TopBar(),
                Expanded(child: mainContent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Component Composition

### Left Panel

- **Position**: Left edge, full height
- **Width**: 280px default (see [left-panel.md](left-panel.md))
- **Behaviour**: Can collapse to 48px icon strip
- **Contains**: App header, sections with controls

### Main Panel

- **Position**: Right of left panel, fills remaining width
- **Contains**: Optional top bar + main content area
- **Layout**: Flex column

### Top Bar (Conditional)

- **Position**: Top of main panel (NOT spanning full width)
- **Visibility**: Only when app is NOT embedded
- **Height**: 48px (aligns with left panel header)
- **Contains**: Context info + Close button

### Main Content Area

- **Position**: Below top bar (or top of main panel if no top bar)
- **Size**: Fills remaining space
- **Scroll**: Handles its own scrolling as needed
- **Background**: `--background` colour

## Three App Types

### Type 1: Simple App

Single screen with basic interactions. Most common type.

```
┌──────────────┬────────────────────────────────────────┐
│              │                                        │
│  Left Panel  │         Main Content Area              │
│              │                                        │
│  [Filters]   │    (Grid, chart, form, etc.)           │
│  [Options]   │                                        │
│  [Actions]   │                                        │
│              │                                        │
└──────────────┴────────────────────────────────────────┘
```

**Examples**: Image Overview, Data Viewer, Report Generator

**Characteristics**:
- Single main content view
- Left panel for configuration
- No step navigation
- Content flows from top-left

### Type 2: Runner App

Step-based workflow with navigation between steps.

```
┌──────────────┬────────────────────────────────────────┐
│              │  [Step 1] [Step 2] [Step 3] [Step 4]   │
│  Left Panel  ├────────────────────────────────────────┤
│              │                                        │
│  [Config]    │         Step Content Area              │
│  [Params]    │                                        │
│  [Status]    │    (Changes based on active step)      │
│              │                                        │
└──────────────┴────────────────────────────────────────┘
```

**Examples**: Pipeline Runner, Analysis Wizard, Import Workflow

**Characteristics**:
- Step tabs/navigation at top of main content
- Left panel shows step-relevant options
- Progress indication
- Can navigate forward/back

### Type 3: Data Step

Complex multi-modal, typically embedded in Tercen workflow.

```
┌──────────────┬────────────────────────────────────────┐
│              │                                        │
│  Left Panel  │         Data Visualisation             │
│              │                                        │
│  [Filters]   │    (Grid, chart, table, or combo)      │
│  [View]      │                                        │
│  [Export]    │                                        │
│              │                                        │
└──────────────┴────────────────────────────────────────┘
```

**Examples**: Image Overview (embedded), Scatter Plot, Heatmap

**Characteristics**:
- Usually runs embedded in Tercen Data Step
- No top bar needed (Tercen provides chrome)
- Focus on data visualisation
- Left panel for filtering/configuration

## Context Detection

Apps need to detect whether they're running embedded in a Data Step or in full screen mode.

### Embedded vs Full Screen

| Context | Top Bar | Close Button | Provided By |
|---------|---------|--------------|-------------|
| Embedded in Data Step | Hidden | Not needed | Tercen platform |
| Full Screen | Visible | Required | App itself |

### Detection Method (Confirmed)

**Check for `taskId` parameter in the URL:**

```dart
// lib/utils/context_detector.dart
class AppContextDetector {
  /// Returns true if the app is running inside a Data Step
  bool get isInDataStep => Uri.base.queryParameters.containsKey('taskId');

  /// Returns true if the app is running in full screen mode
  bool get isFullScreen => !isInDataStep;

  /// Determines whether to show the app's own top bar
  bool get shouldShowTopBar => isFullScreen;
}
```

| URL Pattern | `taskId` Present | Context | Top Bar |
|-------------|------------------|---------|---------|
| `https://tercen.com/...?taskId=abc123` | Yes | Data Step | Hidden |
| `https://tercen.com/...` | No | Full screen | Visible |

**Note**: This method was confirmed by the Tercen platform team (January 2026). The `WebAppOperator.entryType` property exists but URL parameter checking is the recommended approach.

See `_local/investigation-context-detection.md` for full investigation details.

## Top Bar Specification

Only shown when app is NOT embedded.

### Dimensions

| Property | Value |
|----------|-------|
| Height | 48px |
| Position | Top of main panel |
| Width | Full width of main panel |

### Content

| Element | Position | Purpose |
|---------|----------|---------|
| Context Badge | Left | Shows "FULL SCREEN MODE" or similar |
| Context Info | Centre | Optional descriptive text |
| Close Button | Right | Closes the app (X icon) |

### Styling

```dart
Container(
  height: 48,
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border(
      bottom: BorderSide(color: AppColors.border),
    ),
  ),
  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
  child: Row(
    children: [
      // Context badge
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'FULL SCREEN MODE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),

      Spacer(),

      // Close button
      IconButton(
        icon: Icon(Icons.close, color: AppColors.textMuted),
        onPressed: () => closeApp(),
        tooltip: 'Close',
      ),
    ],
  ),
)
```

## Main Content Area

### Flow Direction

Content flows from **top-left**, growing **right** then **down**.

```
┌────────────────────────────────────┐
│ Start here →  →  →  →  →  →  →  →  │
│ ↓                                  │
│ Then down                          │
│ ↓                                  │
│ Continue                           │
└────────────────────────────────────┘
```

### Sizing Principles

From Tercen Layout Principles:

| Principle | Description |
|-----------|-------------|
| Size to content | Components take space they need, no more |
| No "expand to fill" | Avoid stretching to fill available space |
| Left-out approach | Leave out features until proven necessary |
| 8px grid | All spacing uses 4, 8, 16, 24, 32, 48 |

### Background

- Light theme: `#F3F4F6` (--background)
- Dark theme: `#0F172A` (--background)

### Overflow Behaviour

When content exceeds the visible area, **standard scrollbars** appear automatically.

| Property | Value |
|----------|-------|
| Overflow mode | `auto` (scrollbars appear only when needed) |
| Horizontal scroll | Yes, when content exceeds width |
| Vertical scroll | Yes, when content exceeds height |
| Scroll type | Standard browser scrollbars |
| Pan/drag | No (not a canvas interaction) |

**Rules**:

1. **Scrollbars hidden by default** - Only appear when content overflows
2. **Both directions supported** - Content can overflow right AND down
3. **Standard scrollbars** - Use native browser/OS scrollbar styling
4. **No pan/drag** - This is not a canvas; users scroll, not drag

```dart
// Main content area with auto-scroll
Container(
  color: Theme.of(context).colorScheme.background,
  child: SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: widget.content,
    ),
  ),
)

// Or for grid/list content, use appropriate scrollable widget
GridView.builder(
  // GridView handles its own scrolling
)
```

```css
/* CSS implementation */
.main-content {
  flex: 1;
  overflow: auto;  /* Scrollbars appear only when needed */
  background: var(--background);
}
```

**Visual diagram**:

```text
Content fits:                    Content overflows:
┌────────────────────┐           ┌────────────────────┬─┐
│                    │           │                    │▲│
│   Content          │           │   Content ───────► │ │
│                    │           │       │            │ │
│                    │           │       ▼            │▼│
└────────────────────┘           ├────────────────────┴─┤
  No scrollbars                  │◄─────────────────────►│
                                 └──────────────────────┘
                                   Scrollbars appear
```

## Flutter Implementation

```dart
// lib/presentation/screens/app_shell.dart
class AppShell extends StatefulWidget {
  final String appTitle;
  final IconData appIcon;
  final List<LeftPanelSection> sections;
  final Widget content;

  const AppShell({
    required this.appTitle,
    required this.appIcon,
    required this.sections,
    required this.content,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showTopBar = false;

  @override
  void initState() {
    super.initState();
    _detectContext();
  }

  void _detectContext() {
    // Check if running in Data Step (taskId in URL) or full screen
    setState(() {
      _showTopBar = !_isInDataStep();
    });
  }

  bool _isInDataStep() {
    // Platform-confirmed method: check for taskId parameter in URL
    return Uri.base.queryParameters.containsKey('taskId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel
          LeftPanel(
            appTitle: widget.appTitle,
            appIcon: widget.appIcon,
            sections: widget.sections,
          ),

          // Main Panel
          Expanded(
            child: Column(
              children: [
                // Top Bar (conditional)
                if (_showTopBar)
                  TopBar(onClose: () => _closeApp()),

                // Main Content
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: widget.content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _closeApp() {
    // Close the app window/tab
    html.window.close();
  }
}
```

## CSS Variables Reference

For HTML/web implementations:

```css
:root {
  /* Frame */
  --app-min-width: 800px;
  --app-min-height: 600px;

  /* Top Bar */
  --top-bar-height: 48px;

  /* See left-panel.md for panel variables */
}

.app-container {
  display: flex;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
}

.main-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.top-bar {
  height: var(--top-bar-height);
  min-height: var(--top-bar-height);
  /* ... */
}

.main-content {
  flex: 1;
  overflow: auto;
  background: var(--background);
}
```

## Checklist

When implementing an app frame:

- [ ] Read this pattern first (app-frame.md)
- [ ] Determine app type (Simple, Runner, Data Step)
- [ ] Set up flex container (100vw × 100vh)
- [ ] Add left panel placeholder
- [ ] Add main panel with flex column
- [ ] Implement context detection
- [ ] Add top bar if not embedded
- [ ] Set main content background colour
- [ ] Read left-panel.md for left panel implementation
- [ ] Test both embedded and full screen modes
- [ ] Test both light and dark themes

## Related Documents

- [Pattern: Left Panel](left-panel.md) - Left panel component specification
- `_local/left-panel-testboard.html` - Interactive demonstration
- `_local/investigation-context-detection.md` - Context detection research
- `_local/tercen-style/specifications/Tercen-Layout-Principles.html` - Design principles