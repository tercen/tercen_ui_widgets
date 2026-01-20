# Skill 0: Flutter Foundation

**Purpose**: Generic Flutter patterns - Foundation for all Tercen projects

**Extends**: None (base skill)

**Use When**: Starting any new Flutter project

## Overview

This skill provides foundational Flutter patterns that apply to all Tercen projects:
- GetIt dependency injection
- Provider state management
- Clean architecture (Presentation → Domain → Implementation)
- Testing strategy (unit, widget, provider, integration)
- Mock vs Real implementation switching
- Directory structure conventions

## Prerequisites

No Tercen-specific prerequisites - this is generic Flutter.

## Architecture Pattern

### Clean Architecture Layers

```
Presentation Layer (UI)
    ↓ uses
Domain Layer (Abstract Interfaces)
    ↑ implements
Implementation Layer (Concrete Classes)
```

**Benefits**:
- Testability - can mock implementations
- Flexibility - swap implementations without changing UI
- Clear separation of concerns

### Directory Structure

```
lib/
├── main.dart                  # App entry point
│
├── di/                        # Dependency Injection
│   └── service_locator.dart   # GetIt registration
│
├── domain/                    # Abstract interfaces
│   ├── models/                # Data models (interfaces)
│   └── services/              # Service interfaces
│
├── implementations/           # Concrete implementations
│   ├── models/                # Data model implementations
│   ├── services/
│   │   ├── mock_*_service.dart   # Mock implementations
│   │   └── real_*_service.dart   # Real implementations
│
├── presentation/              # UI Layer
│   ├── providers/             # State management (Provider)
│   ├── screens/               # Full screens
│   └── widgets/               # Reusable widgets
│
├── core/                      # Cross-cutting concerns
│   └── theme/                 # Design system
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_spacing.dart
│
└── utils/                     # Utilities
    └── *.dart                 # Helper functions, converters
```

## Dependency Injection (GetIt)

### Setup

```yaml
# pubspec.yaml
dependencies:
  get_it: ^7.6.4
```

### Service Locator

```dart
// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator({bool useMocks = false}) {
  // Register services
  if (useMocks) {
    getIt.registerSingleton<ImageService>(MockImageService());
  } else {
    getIt.registerSingleton<ImageService>(RealImageService());
  }

  // Register providers (factories for new instances)
  getIt.registerFactory<ImageOverviewProvider>(
    () => ImageOverviewProvider(getIt<ImageService>()),
  );
}
```

### Usage in Main

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'di/service_locator.dart';

void main() {
  // Initialize dependency injection
  setupServiceLocator(useMocks: false); // or true for development

  runApp(MyApp());
}
```

## State Management (Provider)

### Setup

```yaml
# pubspec.yaml
dependencies:
  provider: ^6.1.1
```

### Provider Pattern

```dart
// lib/presentation/providers/image_overview_provider.dart
import 'package:flutter/foundation.dart';
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';

class ImageOverviewProvider with ChangeNotifier {
  final ImageService _imageService;

  ImageOverviewProvider(this._imageService);

  ImageCollection? _images;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  ImageCollection? get images => _images;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Actions
  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _images = await _imageService.loadImages();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load images: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Usage in UI

```dart
// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_overview_provider.dart';

class HomeScreen extends StatelessWidget {
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

## Abstract Service Interfaces

### Define Interface

```dart
// lib/domain/services/image_service.dart
import '../models/image_collection.dart';

abstract class ImageService {
  Future<ImageCollection> loadImages();
  Future<void> deleteImage(String id);
  // ... other methods
}
```

### Mock Implementation

```dart
// lib/implementations/services/mock_image_service.dart
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';

class MockImageService implements ImageService {
  @override
  Future<ImageCollection> loadImages() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));

    // Return hardcoded mock data
    return ImageCollection(images: _mockImages);
  }

  final _mockImages = [
    // ... mock data
  ];
}
```

### Real Implementation

```dart
// lib/implementations/services/real_image_service.dart
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';

class RealImageService implements ImageService {
  @override
  Future<ImageCollection> loadImages() async {
    // Real API call
    final response = await http.get(Uri.parse('/api/images'));
    return ImageCollection.fromJson(response.body);
  }
}
```

## Testing Strategy

### Unit Tests

Test individual functions/classes:

```dart
// test/unit/utils/filename_parser_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilenameParser', () {
    test('parses valid filename', () {
      final result = FilenameParser.parse('image_001.jpg');
      expect(result.name, 'image');
      expect(result.number, 1);
    });

    test('handles invalid filename', () {
      final result = FilenameParser.parse('invalid');
      expect(result, isNull);
    });
  });
}
```

### Widget Tests

Test individual widgets:

```dart
// test/widget/image_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ImageCard displays image', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImageCard(image: mockImage),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(mockImage.filename), findsOneWidget);
  });
}
```

### Provider Tests

Test state management:

```dart
// test/provider/image_overview_provider_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadImages sets loading state', () async {
    final provider = ImageOverviewProvider(mockService);

    expect(provider.isLoading, false);

    provider.loadImages();

    expect(provider.isLoading, true);

    await Future.delayed(Duration.zero); // Let async complete

    expect(provider.isLoading, false);
    expect(provider.images, isNotNull);
  });
}
```

### Integration Tests

Test full user flows:

```dart
// test/integration/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app flow', (tester) async {
    await tester.pumpWidget(MyApp());

    // Wait for images to load
    await tester.pumpAndSettle();

    // Verify images displayed
    expect(find.byType(ImageCard), findsWidgets);

    // Tap first image
    await tester.tap(find.byType(ImageCard).first);
    await tester.pumpAndSettle();

    // Verify detail view
    expect(find.text('Image Details'), findsOneWidget);
  });
}
```

## Mock vs Real Switching

### Environment-Based

```dart
// lib/main.dart
void main() {
  const bool useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: false);

  setupServiceLocator(useMocks: useMocks);

  runApp(MyApp());
}
```

### Run with Mocks

```bash
flutter run --dart-define=USE_MOCKS=true
```

### Run with Real Implementation

```bash
flutter run --dart-define=USE_MOCKS=false
```

## Best Practices

### 1. Always Define Interfaces

```dart
// ✓ Good
abstract class ImageService { ... }
class MockImageService implements ImageService { ... }
class RealImageService implements ImageService { ... }

// ✗ Bad
class ImageService { ... } // Concrete class, hard to mock
```

### 2. Inject Dependencies

```dart
// ✓ Good
class MyProvider {
  final ImageService _service;
  MyProvider(this._service); // Injected
}

// ✗ Bad
class MyProvider {
  final _service = RealImageService(); // Hard-coded
}
```

### 3. Keep UI Dumb

```dart
// ✓ Good
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyProvider>(...); // Just renders, no logic
  }
}

// ✗ Bad
class MyWidget extends StatefulWidget {
  // Complex business logic in widget
}
```

## Related Skills

- [Skill 1: Tercen Mock Implementation](1-tercen-mock.md) - Builds on this foundation
- [Skill 2: Tercen Real Implementation](2-tercen-real.md) - Extends architecture for Tercen
- [Skill 3: Customer PamGene](3-customer-pamgene.md) - Domain-specific extension

## Related Issues

- [Issue #7: Hot Reload Does NOT Work](../issues/7-hot-reload-broken.md) - Development workflow
- [Issue #8: Mandatory Development Workflow](../issues/8-mandatory-workflow.md) - Planning process
- [Issue #9: UI Design Standards](../issues/9-ui-design-standards.md) - Design system

## Checklist

Starting a new Flutter project:

- [ ] Create directory structure (di/, domain/, implementations/, presentation/)
- [ ] Add dependencies (get_it, provider)
- [ ] Create service interfaces in domain/
- [ ] Create mock implementations
- [ ] Set up GetIt service locator
- [ ] Create providers for state management
- [ ] Write tests (unit, widget, provider)
- [ ] Establish design system (see Issue #9)
- [ ] Follow mandatory workflow (see Issue #8)
