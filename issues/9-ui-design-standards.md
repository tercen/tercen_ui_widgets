# Issue #9: UI Design Standards and Styling Conventions

**Category**: UI/UX Design

**Severity**: Medium - Ensures consistency

## Problem

Without standardized design system:
- Inconsistent font sizes, colors, spacing across screens
- Different developers make ad-hoc styling decisions
- No centralized theme management
- Hard to maintain visual consistency
- Inline hardcoded styles scattered throughout widgets

## Solution

Establish comprehensive design system during **mock implementation phase** (Skill 1) using the **official Tercen Style Specifications**.

## Official Tercen Style Specifications

**Location**: `_local/tercen-style/specifications/`

These HTML specifications are the authoritative source for Tercen UI design:

| Document | Purpose |
| -------- | ------- |
| `Tercen-Style-Guide.html` | Colors, typography, component styles, visual identity |
| `Tercen-Layout-Principles.html` | C.R.A.P. design principles, 8px spacing grid, component sizing, structural layout |
| `Tercen-Icon-Semantic-Map.html` | Icon usage: FontAwesome Solid + 6 Tercen-specific custom icons |
| `../ICON-GUIDELINES.md` | Quick reference for icon selection |

**When creating mock implementations, Claude MUST:**
1. Read `Tercen-Layout-Principles.html` for spacing and sizing rules
2. Read `Tercen-Style-Guide.html` for colors and typography
3. Apply these specifications to all UI code

## Foundation: Material Design 3

All Tercen Flutter apps use Material Design 3:
- Material components (Button, Card, AppBar, etc.)
- Material color system (ColorScheme.fromSeed)
- Material elevation system
- Material motion/animations

## Design System Files

Create during mock implementation:

```
lib/core/theme/
├── app_theme.dart        # Main theme configuration
├── app_colors.dart       # Color palette
├── app_text_styles.dart  # Typography
└── app_spacing.dart      # Spacing constants
```

## Core Design Decisions

### Typography (Material Design 3)

```dart
// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  static const fontFamily = 'Roboto';

  static const TextTheme textTheme = TextTheme(
    // Headlines
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),

    // Body text
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
    ),

    // Labels
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}
```

### Color Palette

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary brand color
  static const primary = Color(0xFF1976D2);
  static const onPrimary = Colors.white;

  // Secondary color
  static const secondary = Color(0xFF424242);
  static const onSecondary = Colors.white;

  // Background colors
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;

  // Semantic colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFD32F2F);
  static const info = Color(0xFF2196F3);

  // Text colors
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textDisabled = Color(0xFFBDBDBD);

  // Border colors
  static const border = Color(0xFFE0E0E0);
  static const divider = Color(0xFFBDBDBD);
}
```

### Spacing System (8-Point Grid)

```dart
// lib/core/theme/app_spacing.dart
class AppSpacing {
  // Base unit: 8px
  static const double xs = 4.0;   // 0.5 × base
  static const double s = 8.0;    // 1 × base
  static const double m = 16.0;   // 2 × base
  static const double l = 24.0;   // 3 × base
  static const double xl = 32.0;  // 4 × base
  static const double xxl = 48.0; // 6 × base

  // Common padding
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingS = EdgeInsets.all(s);
  static const EdgeInsets paddingM = EdgeInsets.all(m);
  static const EdgeInsets paddingL = EdgeInsets.all(l);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Common margins
  static const EdgeInsets marginXs = EdgeInsets.all(xs);
  static const EdgeInsets marginS = EdgeInsets.all(s);
  static const EdgeInsets marginM = EdgeInsets.all(m);
  static const EdgeInsets marginL = EdgeInsets.all(l);
  static const EdgeInsets marginXl = EdgeInsets.all(xl);
}
```

### Theme Configuration

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      textTheme: AppTextStyles.textTheme,
      fontFamily: AppTextStyles.fontFamily,

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Dark theme (future expansion)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      textTheme: AppTextStyles.textTheme,
      fontFamily: AppTextStyles.fontFamily,
    );
  }
}
```

### Main App Integration

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Tercen App',
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme, // Future
      home: HomeScreen(),
    );
  }
}
```

## Component Standards

### Buttons

```dart
// Primary action
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Action'),
)

// Secondary action
OutlinedButton(
  onPressed: () {},
  child: Text('Secondary Action'),
)

// Tertiary action
TextButton(
  onPressed: () {},
  child: Text('Tertiary Action'),
)
```

### Cards

```dart
Card(
  child: Padding(
    padding: AppSpacing.paddingM,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: AppSpacing.s),
        Text('Content', style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  ),
)
```

### Grid Layouts

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    childAspectRatio: 270 / 200,  // ps12: 270px × 200px cells
    crossAxisSpacing: AppSpacing.s,
    mainAxisSpacing: AppSpacing.s,
  ),
  itemBuilder: (context, index) {
    return GridCell(item: items[index]);
  },
)
```

## Usage Examples

### ❌ WRONG: Hardcoded inline styles

```dart
Container(
  padding: EdgeInsets.all(16),  // Magic number
  decoration: BoxDecoration(
    color: Color(0xFF1976D2),   // Hardcoded color
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Hello',
    style: TextStyle(
      fontSize: 14,              // Magic number
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### ✅ CORRECT: Use design system

```dart
Container(
  padding: AppSpacing.paddingM,
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primary,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.labelLarge,
  ),
)
```

## When to Establish Design System

**Phase**: During mock implementation (Skill 1)

**Why**:
- UI design is visual - needs to be seen to be approved
- Mock phase is rapid iteration - easy to try different styles
- Establishes visual consistency before real implementation
- User can approve design system alongside UI functionality

**Workflow**:
1. Create basic mock with Material Design defaults
2. Define custom theme/colors/spacing
3. Apply design system to mock UI
4. User reviews and approves visual design
5. Lock design system before real implementation
6. Real implementation inherits approved design system

## Future Expansion

Current standards are minimal. Future revisions will add:

- [ ] Dark mode support
- [ ] Comprehensive color palette (shades, tints)
- [ ] Icon system standards
- [ ] Animation standards
- [ ] Responsive breakpoints
- [ ] Accessibility standards (WCAG compliance)
- [ ] Customer-specific theming (PamGene branding)
- [ ] Loading state patterns
- [ ] Error state patterns
- [ ] Empty state patterns

## Customer-Specific Extensions

### PamGene (Skill 3)

```dart
// lib/core/theme/pamgene_theme.dart
class PamGeneTheme {
  // Grid layout standards for microscopy images
  static const gridCellAspectRatio = 270 / 200;
  static const gridSpacing = 8.0;

  // Image display standards
  static const imageBorderRadius = 4.0;
  static const imageBorder = Border.fromBorderSide(
    BorderSide(color: AppColors.border, width: 1),
  );
}
```

## Checklist

During mock implementation:

- [ ] Create `lib/core/theme/` directory
- [ ] Create `app_theme.dart` with Material Design 3 base
- [ ] Create `app_colors.dart` with color palette
- [ ] Create `app_text_styles.dart` with typography
- [ ] Create `app_spacing.dart` with spacing constants
- [ ] Apply theme in `main.dart`
- [ ] Define component standards (buttons, cards, etc.)
- [ ] Document any custom design decisions
- [ ] Apply theme consistently across all widgets
- [ ] Review with user before moving to real implementation

## See Also

- [Skill 1: Tercen Mock Implementation](../skills/1-tercen-mock.md)
- [Skill 3: Customer PamGene](../skills/3-customer-pamgene.md)
- [Issue #8: Mandatory Workflow](8-mandatory-workflow.md)
