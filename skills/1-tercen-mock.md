# Skill 1: Tercen Mock Implementation

**Purpose**: Build UI with mock data first - rapid iteration without backend

**Extends**: [Skill 0: Flutter Foundation](0-flutter-foundation.md)

**Use When**: Creating UI/UX before Tercen API integration

## Overview

Mock-first development workflow:
- Build and test UI with mock data
- Iterate quickly without Tercen API dependency
- Establish design system during this phase
- User approves UI before moving to real implementation

## Prerequisites

From Skill 0:
- Directory structure established
- GetIt dependency injection configured
- Provider state management setup
- Abstract service interfaces defined

## Mock-First Workflow

### Phase 1: Define Interface

```dart
// lib/domain/services/image_service.dart
abstract class ImageService {
  Future<ImageCollection> loadImages();
  Future<ImageMetadata> getImageDetails(String id);
  // ... other methods
}
```

### Phase 2: Create Mock Implementation

```dart
// lib/implementations/services/mock_image_service.dart
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';

class MockImageService implements ImageService {
  final Map<String, ImageMetadata> _cache = {};

  MockImageService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Load from assets or generate programmatically
    _cache['img_001'] = ImageMetadataImpl(
      id: 'img_001',
      filename: '641070616_W1_F1_T100_P94_I493_A30.png',
      imagePath: 'assets/641070616_W1_F1_T100_P94_I493_A30.png',
      barcode: '641070616',
      well: 1,
      field: 1,
      cycle: 94,
      exposureTime: 493,
    );
    // ... more mock images
  }

  @override
  Future<ImageCollection> loadImages() async {
    // Simulate realistic network delay
    await Future.delayed(Duration(milliseconds: 500));

    return ImageCollection(images: _cache.values.toList());
  }

  @override
  Future<ImageMetadata> getImageDetails(String id) async {
    await Future.delayed(Duration(milliseconds: 200));

    if (!_cache.containsKey(id)) {
      throw Exception('Image not found: $id');
    }

    return _cache[id]!;
  }
}
```

### Phase 3: Register Mock in DI

```dart
// lib/di/service_locator.dart
void setupServiceLocator({bool useMocks = true}) {
  if (useMocks) {
    getIt.registerSingleton<ImageService>(MockImageService());
  } else {
    // Real implementation (later)
    getIt.registerSingleton<ImageService>(TercenImageService(...));
  }
}
```

### Phase 4: Build UI

```dart
// lib/presentation/screens/image_overview_screen.dart
class ImageOverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<ImageOverviewProvider>()..loadImages(),
      child: Scaffold(
        appBar: AppBar(title: Text('Image Overview')),
        body: Consumer<ImageOverviewProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (provider.hasError) {
              return Center(child: Text(provider.errorMessage!));
            }

            return ImageGrid(images: provider.images!);
          },
        ),
      ),
    );
  }
}
```

## Asset-Based Mock Data

### Using Real Assets

For realistic UI testing, use actual converted images:

```dart
class MockImageService implements ImageService {
  @override
  Future<ImageCollection> loadImages() async {
    // Load actual PNG files from assets
    final images = [
      await _loadFromAsset('assets/sample1.png', 'sample1.png'),
      await _loadFromAsset('assets/sample2.png', 'sample2.png'),
      // ...
    ];

    return ImageCollection(images: images);
  }

  Future<ImageMetadata> _loadFromAsset(String path, String filename) async {
    final bytes = await rootBundle.load(path);

    return ImageMetadataImpl(
      id: filename,
      filename: filename,
      bytes: bytes.buffer.asUint8List(),
      // Parse metadata from filename if needed
    );
  }
}
```

### pubspec.yaml Assets

```yaml
flutter:
  assets:
    - assets/
    - assets/images/
```

## Realistic Mock Behaviors

### Simulate Network Delays

```dart
Future<ImageCollection> loadImages() async {
  // Simulate varying network conditions
  final delay = Random().nextInt(1000) + 300; // 300-1300ms
  await Future.delayed(Duration(milliseconds: delay));

  return ImageCollection(images: _mockImages);
}
```

### Simulate Errors

```dart
class MockImageService implements ImageService {
  bool _shouldFail = false;
  int _callCount = 0;

  @override
  Future<ImageCollection> loadImages() async {
    _callCount++;

    // Simulate intermittent failures
    if (_callCount % 5 == 0) {
      throw Exception('Simulated network error');
    }

    await Future.delayed(Duration(milliseconds: 500));
    return ImageCollection(images: _mockImages);
  }
}
```

### Simulate Pagination

```dart
class MockImageService implements ImageService {
  int _currentPage = 0;
  static const _pageSize = 20;

  @override
  Future<ImageCollection> loadImages({int page = 0}) async {
    await Future.delayed(Duration(milliseconds: 500));

    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, _allImages.length);

    return ImageCollection(
      images: _allImages.sublist(start, end),
      hasMore: end < _allImages.length,
    );
  }
}
```

## Mock Data Generation

### Programmatic Generation

```dart
void _initializeMockData() {
  // Generate realistic test data
  final barcodes = ['641070616', '641070617', '641070618'];
  final wells = [1, 2, 3, 4];
  final fields = [1, 2, 3];

  for (final barcode in barcodes) {
    for (final well in wells) {
      for (final field in fields) {
        final id = '${barcode}_W${well}_F${field}';
        _cache[id] = ImageMetadataImpl(
          id: id,
          filename: '${id}_T100_P94_I493_A30.png',
          barcode: barcode,
          well: well,
          field: field,
          cycle: 94,
          exposureTime: 493,
        );
      }
    }
  }
}
```

## Design System Establishment

**CRITICAL**: Establish design system during mock phase using Tercen's official style specifications.

### Required Reading: Tercen Style Specifications

Before creating any UI, read and apply these specifications from `_local/tercen-style/specifications/`:

| Specification | Purpose | Key Content |
|---------------|---------|-------------|
| `Tercen-Style-Guide.html` | Visual identity | Colors, typography, component styles |
| `Tercen-Layout-Principles.html` | Spatial design | C.R.A.P. principles, 8px spacing grid, component sizing |
| `Tercen-Icon-Semantic-Map.html` | Icon usage | FontAwesome + 6 Tercen-specific icons |

### Key Layout Principles (from Tercen-Layout-Principles v2.0)

**Part A: Design Fundamentals**
1. **C.R.A.P. Principles** - Contrast, Repetition, Alignment, Proximity guide all decisions
2. **8px Spacing Grid** - Use values: 4, 8, 16, 24, 32, 48 (never arbitrary like 10px, 15px)
3. **Equal Gap Rule** - Within grids, horizontal and vertical gaps must match
4. **Size to Content** - Components sized for expected content, not "expand to fill"
5. **Density Levels** - Compact (4px gaps) for data, Standard (16px) for forms, Spacious for emphasis

**Part B: Structural Layout**
1. **Corner-Out Design** - All layouts anchor from top-left (0,0)
2. **Left-Out Approach** - No right sidebars; all panels on left
3. **No Stretch** - Elements have natural widths; empty space on right is OK

### Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Unequal grid gaps | 4px horizontal, 12px vertical | Always use equal gaps |
| Stretched controls | `Expanded` on dropdowns | Size based on expected content |
| Arbitrary spacing | 10px, 15px, 22px values | Use scale: 4, 8, 16, 24, 32, 48 |

### Create Theme Files

```
lib/core/theme/
├── app_theme.dart        # Material Design 3 configuration
├── app_colors.dart       # Color palette (from Tercen-Style-Guide)
├── app_text_styles.dart  # Typography (from Tercen-Style-Guide)
└── app_spacing.dart      # Spacing constants (8px grid from Layout Principles)
```

### Apply Theme

```dart
// lib/main.dart
import 'core/theme/app_theme.dart';

void main() {
  setupServiceLocator(useMocks: true);

  runApp(MaterialApp(
    theme: AppTheme.lightTheme,
    home: HomeScreen(),
  ));
}
```

### User Approval

User reviews and approves:
1. Visual design (colors, typography, spacing)
2. UI layout and flow
3. Component styling
4. Mock data realism

Lock design system before moving to real implementation.

## Development Workflow

### CRITICAL: Stop and Restart Required

**Hot reload does NOT work** - See [Issue #7: Hot Reload Broken](../issues/7-hot-reload-broken.md)

```bash
# Make changes
# Ctrl+C (stop)
flutter run -d chrome
# Changes now visible
```

### Quick Iteration

```bash
# 1. Make UI changes
# 2. Stop app (Ctrl+C)
# 3. Restart: flutter run -d chrome
# 4. Verify changes (5-10 seconds total)
```

## Testing with Mocks

### Unit Test Mock Service

```dart
// test/unit/services/mock_image_service_test.dart
void main() {
  test('returns mock images', () async {
    final service = MockImageService();
    final result = await service.loadImages();

    expect(result.images, isNotEmpty);
    expect(result.images.length, greaterThan(0));
  });

  test('simulates delay', () async {
    final service = MockImageService();
    final stopwatch = Stopwatch()..start();

    await service.loadImages();

    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, greaterThan(300));
  });
}
```

### Widget Test with Mock

```dart
// test/widget/image_grid_test.dart
void main() {
  setUp(() {
    setupServiceLocator(useMocks: true);
  });

  testWidgets('displays mock images', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ImageOverviewScreen()));

    // Wait for loading
    await tester.pumpAndSettle();

    // Verify images displayed
    expect(find.byType(ImageCard), findsWidgets);
  });
}
```

## Benefits of Mock-First

### 1. Fast Iteration

- No backend dependency
- No authentication setup
- No network issues
- 5-10 second iteration cycle

### 2. Early User Feedback

- User sees UI immediately
- Can approve/reject design early
- Cheaper to change in mock phase

### 3. Parallel Development

- Frontend team works on UI
- Backend team works on API
- No blocking dependencies

### 4. Better Testing

- Predictable mock data
- Test edge cases easily
- Simulate errors consistently

## Transition to Real Implementation

When mocks are approved:

### 1. Keep Mock Implementation

```dart
// Don't delete mocks - keep for testing
class MockImageService implements ImageService {
  // Keep this implementation
}
```

### 2. Create Real Implementation

```dart
// Add alongside mock
class TercenImageService implements ImageService {
  // New real implementation
}
```

### 3. Switch in DI

```dart
void setupServiceLocator({bool useMocks = false}) {
  if (useMocks) {
    getIt.registerSingleton<ImageService>(MockImageService());
  } else {
    getIt.registerSingleton<ImageService>(TercenImageService(...));
  }
}
```

### 4. Test Both

```bash
# Test with mocks
flutter run --dart-define=USE_MOCKS=true

# Test with real API
flutter run --dart-define=USE_MOCKS=false
```

## Common Patterns

### Mock with Filters

```dart
class MockImageService implements ImageService {
  @override
  Future<ImageCollection> loadImages({
    String? barcode,
    int? cycle,
    int? exposureTime,
  }) async {
    var filtered = _allImages;

    if (barcode != null) {
      filtered = filtered.where((img) => img.barcode == barcode).toList();
    }

    if (cycle != null) {
      filtered = filtered.where((img) => img.cycle == cycle).toList();
    }

    if (exposureTime != null) {
      filtered = filtered.where((img) => img.exposureTime == exposureTime).toList();
    }

    return ImageCollection(images: filtered);
  }
}
```

### Mock with Sorting

```dart
@override
Future<ImageCollection> loadImages({String sortBy = 'filename'}) async {
  final sorted = List.of(_allImages);

  switch (sortBy) {
    case 'filename':
      sorted.sort((a, b) => a.filename.compareTo(b.filename));
      break;
    case 'cycle':
      sorted.sort((a, b) => a.cycle.compareTo(b.cycle));
      break;
    case 'exposureTime':
      sorted.sort((a, b) => a.exposureTime.compareTo(b.exposureTime));
      break;
  }

  return ImageCollection(images: sorted);
}
```

## Checklist

Mock implementation phase:

- [ ] Define service interface in domain/
- [ ] Create mock implementation in implementations/services/
- [ ] Add realistic delays (300-1000ms)
- [ ] Use actual assets if available
- [ ] Generate realistic mock data
- [ ] Simulate edge cases (errors, empty states)
- [ ] Establish design system (colors, typography, spacing)
- [ ] Build UI with mock data
- [ ] Test with mocks (unit, widget, integration)
- [ ] Get user approval (UI design and functionality)
- [ ] Remember: Stop and restart (NOT hot reload)

## Related Skills

- [Skill 0: Flutter Foundation](0-flutter-foundation.md) - Architecture foundation
- [Skill 2: Tercen Real Implementation](2-tercen-real.md) - Next: Connect to Tercen API
- [Skill 3: Customer PamGene](3-customer-pamgene.md) - Domain-specific mocks

## Related Issues

- [Issue #7: Hot Reload Broken](../issues/7-hot-reload-broken.md) - Stop and restart workflow
- [Issue #8: Mandatory Workflow](../issues/8-mandatory-workflow.md) - Planning before implementation
- [Issue #9: UI Design Standards](../issues/9-ui-design-standards.md) - Establish during mock phase

## Related Patterns

- [Pattern: Error Handling](../patterns/error-handling.md) - Mock error scenarios
