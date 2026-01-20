# Skill 2: Tercen Real Implementation

**Purpose**: Integrate with Tercen platform API

**Extends**: [Skill 1: Tercen Mock Implementation](1-tercen-mock.md)

**Use When**: Connecting mock implementation to real Tercen API

## Overview

This skill covers Tercen-specific integration:
- Authentication using sci_tercen_client
- ServiceFactory usage
- URL path parsing (standalone vs workflow modes)
- File streaming and downloads
- Error handling with fallback to mocks
- Concurrency management

## Prerequisites - Auto-Fetch Repositories

**CRITICAL**: This skill automatically fetches Tercen repositories for reference.

### Essential Repositories

```bash
# Auto-fetch these repos when skill is invoked
gh repo clone tercen/sci_tercen_client --depth 1 /tmp/tercen-refs/sci_tercen_client
gh repo clone tercen/sci_http_client --depth 1 /tmp/tercen-refs/sci_http_client
gh repo clone tercen/sci_base --depth 1 /tmp/tercen-refs/sci_base
gh repo clone tercen/sci_tercen_model --depth 1 /tmp/tercen-refs/sci_tercen_model
```

### Key Files to Review

**From sci_tercen_client**:
- `lib/sci_service_factory_web.dart` - Web authentication
- `lib/sci_client_service_factory.dart` - ServiceFactory interface

**From sci_http_client**:
- `lib/http_auth_client.dart` - Token injection

**From sci_base**:
- `lib/sci_client_base.dart` - Service abstractions

## Pattern 1: Authentication

**See**: [Pattern: Authentication](../patterns/authentication.md)

**See**: [Issue #3: CORS Errors](../issues/3-cors-errors.md)

### Add Dependency

```yaml
# pubspec.yaml
dependencies:
  sci_tercen_client:
    git:
      url: https://github.com/tercen/sci_tercen_client.git
      ref: 1.7.0
      path: sci_tercen_client
```

### Initialize in Main

```dart
// lib/main.dart
import 'package:sci_tercen_client/sci_service_factory_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create Tercen service factory (handles authentication)
  final tercenFactory = await createServiceFactoryForWebApp();

  // Register with DI
  getIt.registerSingleton<ServiceFactory>(tercenFactory);

  // Register services
  setupServiceLocator(useMocks: false);

  runApp(MyApp());
}
```

### Development Mode Tokens

```html
<!-- web/index.html -->
<script>
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    const devToken = 'YOUR_DEV_TOKEN_HERE';
    const serviceUri = 'https://stage.tercen.com';

    localStorage.setItem('tercen.token', devToken);
    localStorage.setItem('tercen.serviceUri', serviceUri);

    console.log('🔧 DEV MODE: Set Tercen credentials in localStorage');
  }
</script>
```

## Pattern 2: URL Path Parsing

**See**: [Pattern: URL Path Parsing](../patterns/url-parsing.md)

### Two Deployment Modes

**Mode 1 (Standalone)**: `https://tercen.com/_w3op/{documentId}/`

**Mode 2 (Workflow)**: `https://tercen.com/w/{workflowId}/ds/{stepId}`

### URL Parser Implementation

```dart
// lib/utils/tercen_url_parser.dart
class TercenUrlParser {
  String? documentId;
  String? workflowId;
  String? stepId;
  bool isStandaloneMode = false;
  bool isWorkflowMode = false;

  TercenUrlParser() {
    _parseUrl();
  }

  void _parseUrl() {
    final pathSegments = Uri.base.pathSegments;

    print('🔍 Parsing URL: ${Uri.base}');
    print('📋 Path segments: $pathSegments');

    // Mode 1: Standalone - /_w3op/{documentId}/
    if (pathSegments.contains('_w3op')) {
      final index = pathSegments.indexOf('_w3op');
      if (index + 1 < pathSegments.length) {
        documentId = pathSegments[index + 1];
        isStandaloneMode = true;
        print('✓ Standalone mode: documentId=$documentId');
      }
    }
    // Mode 2: Workflow - /w/{workflowId}/ds/{stepId}
    else if (pathSegments.contains('w') && pathSegments.contains('ds')) {
      final wIndex = pathSegments.indexOf('w');
      final dsIndex = pathSegments.indexOf('ds');

      if (wIndex + 1 < pathSegments.length && dsIndex + 1 < pathSegments.length) {
        workflowId = pathSegments[wIndex + 1];
        stepId = pathSegments[dsIndex + 1];
        isWorkflowMode = true;
        print('✓ Workflow mode: workflowId=$workflowId, stepId=$stepId');
      }
    }
  }

  bool get hasValidContext => isStandaloneMode || isWorkflowMode;
}
```

### Register URL Parser

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final urlParser = TercenUrlParser();
  final tercenFactory = await createServiceFactoryForWebApp();

  getIt.registerSingleton<TercenUrlParser>(urlParser);
  getIt.registerSingleton<ServiceFactory>(tercenFactory);

  setupServiceLocator(useMocks: !urlParser.hasValidContext);

  runApp(MyApp());
}
```

## Pattern 3: File Streaming

**See**: [Pattern: File Streaming](../patterns/file-streaming.md)

**See**: [Pattern: Concurrency](../patterns/concurrency.md)

### Basic Download

```dart
Future<Uint8List> downloadFile(String fileId) async {
  final stream = _factory.fileService.download(fileId);
  final chunks = <List<int>>[];

  await for (final chunk in stream) {
    chunks.add(chunk);
  }

  return Uint8List.fromList(chunks.expand((x) => x).toList());
}
```

### With Concurrency Management

```dart
class TercenImageService implements ImageService {
  static const _maxConcurrentDownloads = 3;
  final _downloadQueue = <_DownloadRequest>[];
  int _activeDownloads = 0;

  Future<List<ImageMetadata>> downloadImages(List<FileDocument> files) async {
    final results = <ImageMetadata>[];
    final completers = <String, Completer<Uint8List?>>{};

    // Queue all downloads
    for (final file in files) {
      final completer = Completer<Uint8List?>();
      completers[file.id] = completer;

      _downloadQueue.add(_DownloadRequest(
        fileId: file.id,
        filename: file.name,
        completer: completer,
      ));
    }

    // Process queue
    _processQueue();

    // Wait for all completions
    final downloads = await Future.wait(completers.values.map((c) => c.future));

    // Convert to ImageMetadata
    for (int i = 0; i < files.length; i++) {
      if (downloads[i] != null) {
        results.add(ImageMetadataImpl(
          id: files[i].id,
          filename: files[i].name,
          bytes: downloads[i]!,
        ));
      }
    }

    return results;
  }

  void _processQueue() {
    while (_activeDownloads < _maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      final request = _downloadQueue.removeAt(0);
      _activeDownloads++;

      _downloadFile(request).then((_) {
        _activeDownloads--;
        _processQueue();
      });
    }
  }

  Future<void> _downloadFile(_DownloadRequest request) async {
    try {
      final stream = _factory.fileService.download(request.fileId);
      final chunks = <List<int>>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
      request.completer.complete(bytes);
    } catch (e) {
      print('✗ Download failed: ${request.filename} - $e');
      request.completer.complete(null);
    }
  }
}
```

## Pattern 4: Error Handling with Fallback

**See**: [Pattern: Error Handling](../patterns/error-handling.md)

### Service with Mock Fallback

```dart
class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final TercenUrlParser _urlParser;
  final ImageService _mockService;

  TercenImageService(this._factory, this._urlParser, this._mockService);

  @override
  Future<ImageCollection> loadImages() async {
    try {
      // Validate context
      if (!_urlParser.hasValidContext) {
        print('✗ No valid Tercen context - using mocks');
        return _mockService.loadImages();
      }

      print('🔍 Loading images from Tercen API...');

      // Find files
      final files = await _findFiles();

      if (files.isEmpty) {
        print('⚠️ No files found - using mocks');
        return _mockService.loadImages();
      }

      // Download files
      final images = await downloadImages(files);

      print('✓ Loaded ${images.length} images from Tercen');

      return ImageCollection(images: images);
    } catch (e) {
      print('✗ Error loading from Tercen: $e');
      print('Falling back to mock data');
      return _mockService.loadImages();
    }
  }

  Future<List<FileDocument>> _findFiles() async {
    final fileService = _factory.fileService;

    if (_urlParser.isWorkflowMode) {
      return await fileService.findFileByWorkflowIdAndStepId(
        startKey: [_urlParser.workflowId, _urlParser.stepId],
        endKey: [_urlParser.workflowId, _urlParser.stepId, {}],
      );
    } else if (_urlParser.isStandaloneMode) {
      // Load by document ID
      final document = await _factory.documentService.get(_urlParser.documentId!);
      // Process document to get files...
      return [];
    }

    return [];
  }
}
```

## Complete Service Implementation

```dart
// lib/implementations/services/tercen_image_service.dart
import 'dart:typed_data';
import 'package:sci_tercen_client/sci_client.dart';
import '../../domain/services/image_service.dart';
import '../../domain/models/image_collection.dart';
import '../../utils/tercen_url_parser.dart';

class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final TercenUrlParser _urlParser;
  final ImageService _mockService;

  static const _maxConcurrentDownloads = 3;
  final _downloadQueue = <_DownloadRequest>[];
  int _activeDownloads = 0;

  TercenImageService(
    this._factory,
    this._urlParser,
    this._mockService,
  );

  @override
  Future<ImageCollection> loadImages() async {
    try {
      if (!_urlParser.hasValidContext) {
        print('✗ No valid Tercen context');
        return _mockService.loadImages();
      }

      print('🔍 Loading from Tercen: ${Uri.base}');

      final files = await _findFiles();
      print('📋 Found ${files.length} files');

      if (files.isEmpty) {
        return _mockService.loadImages();
      }

      final images = await _downloadImages(files);
      print('✓ Downloaded ${images.length} images');

      return ImageCollection(images: images);
    } catch (e) {
      print('✗ Tercen error: $e');
      return _mockService.loadImages();
    }
  }

  Future<List<FileDocument>> _findFiles() async {
    final fileService = _factory.fileService;

    if (_urlParser.isWorkflowMode) {
      return await fileService.findFileByWorkflowIdAndStepId(
        startKey: [_urlParser.workflowId, _urlParser.stepId],
        endKey: [_urlParser.workflowId, _urlParser.stepId, {}],
      );
    }

    return [];
  }

  Future<List<ImageMetadata>> _downloadImages(List<FileDocument> files) async {
    final results = <ImageMetadata>[];
    final completers = <String, Completer<Uint8List?>>{};

    for (final file in files) {
      final completer = Completer<Uint8List?>();
      completers[file.id] = completer;

      _downloadQueue.add(_DownloadRequest(
        fileId: file.id,
        filename: file.name,
        completer: completer,
      ));
    }

    _processQueue();

    final downloads = await Future.wait(completers.values.map((c) => c.future));

    for (int i = 0; i < files.length; i++) {
      if (downloads[i] != null) {
        results.add(ImageMetadataImpl(
          id: files[i].id,
          filename: files[i].name,
          bytes: downloads[i]!,
        ));
      }
    }

    return results;
  }

  void _processQueue() {
    while (_activeDownloads < _maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      final request = _downloadQueue.removeAt(0);
      _activeDownloads++;

      _downloadFile(request).then((_) {
        _activeDownloads--;
        _processQueue();
      });
    }
  }

  Future<void> _downloadFile(_DownloadRequest request) async {
    try {
      print('🔍 Downloading [${_activeDownloads}/$_maxConcurrentDownloads]: ${request.filename}');

      final stream = _factory.fileService.download(request.fileId);
      final chunks = <List<int>>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
      print('✓ Downloaded: ${request.filename} (${bytes.length} bytes)');

      request.completer.complete(bytes);
    } catch (e) {
      print('✗ Failed: ${request.filename} - $e');
      request.completer.complete(null);
    }
  }
}

class _DownloadRequest {
  final String fileId;
  final String filename;
  final Completer<Uint8List?> completer;

  _DownloadRequest({
    required this.fileId,
    required this.filename,
    required this.completer,
  });
}
```

## Dependency Injection Setup

```dart
// lib/di/service_locator.dart
void setupServiceLocator({bool useMocks = false}) {
  if (useMocks) {
    getIt.registerSingleton<ImageService>(MockImageService());
  } else {
    // Real Tercen implementation
    getIt.registerSingleton<ImageService>(
      TercenImageService(
        getIt<ServiceFactory>(),
        getIt<TercenUrlParser>(),
        MockImageService(), // Fallback
      ),
    );
  }

  getIt.registerFactory<ImageOverviewProvider>(
    () => ImageOverviewProvider(getIt<ImageService>()),
  );
}
```

## Critical Operational Issues

### Issue #1: WASM Build & Testing Workflow

**See**: [Issue #1: WASM Build](../issues/1-wasm-build.md)

```bash
# REQUIRED for Tercen testing
flutter build web --wasm
git add build/web/
git commit -m "Update web build"
git push
# Wait for Tercen to refresh
```

### Issue #2: build/web/ Must Be Committed

**See**: [Issue #2: build/web/ Commit](../issues/2-build-web-commit.md)

```gitignore
/build/          # Ignore all
!/build/web/     # EXCEPT this - Tercen requirement
```

### Issue #3: CORS Errors

**See**: [Issue #3: CORS Errors](../issues/3-cors-errors.md)

**Always use sci_tercen_client** - never manual HTTP calls.

### Issue #4: index.html Line 17

**See**: [Issue #4: index.html Line 17](../issues/4-index-html-line17.md)

```html
<!--<base href="$FLUTTER_BASE_HREF"> -->
```

**MUST be commented** for Tercen deployment.

### Issue #5: Required File Structure

**See**: [Issue #5: Tercen File Structure](../issues/5-tercen-file-structure.md)

```json
// operator.json
{
  "name": "Your Operator",
  "isWebApp": true,
  "serve": "build/web",
  "urls": ["https://github.com/tercen/your-repo"]
}
```

## Checklist

Tercen integration:

- [ ] Auto-fetch sci_tercen_client and related repos
- [ ] Add sci_tercen_client dependency to pubspec.yaml
- [ ] Create ServiceFactory in main.dart with createServiceFactoryForWebApp()
- [ ] Create TercenUrlParser for deployment mode detection
- [ ] Implement TercenImageService with mock fallback
- [ ] Implement concurrency management (max 3 concurrent)
- [ ] Add comprehensive debug logging (🔍, ✓, ✗, 📋)
- [ ] Verify operator.json exists with correct fields
- [ ] Verify web/index.html line 17 is commented
- [ ] Verify .gitignore has !/build/web/ exception
- [ ] Test locally with mock data first
- [ ] Build with flutter build web --wasm
- [ ] Commit build/web/ directory
- [ ] Push to GitHub
- [ ] Test in Tercen environment (both modes if applicable)

## Related Skills

- [Skill 0: Flutter Foundation](0-flutter-foundation.md) - Architecture foundation
- [Skill 1: Tercen Mock Implementation](1-tercen-mock.md) - Mock-first development
- [Skill 3: Customer PamGene](3-customer-pamgene.md) - Domain-specific extensions

## Related Patterns

- [Pattern: Authentication](../patterns/authentication.md)
- [Pattern: URL Path Parsing](../patterns/url-parsing.md)
- [Pattern: File Streaming](../patterns/file-streaming.md)
- [Pattern: Concurrency](../patterns/concurrency.md)
- [Pattern: Error Handling](../patterns/error-handling.md)

## Related Issues

- [Issue #1: WASM Build](../issues/1-wasm-build.md)
- [Issue #2: build/web/ Commit](../issues/2-build-web-commit.md)
- [Issue #3: CORS Errors](../issues/3-cors-errors.md)
- [Issue #4: index.html Line 17](../issues/4-index-html-line17.md)
- [Issue #5: Tercen File Structure](../issues/5-tercen-file-structure.md)
- [Issue #7: Hot Reload Broken](../issues/7-hot-reload-broken.md)
- [Issue #8: Mandatory Workflow](../issues/8-mandatory-workflow.md)
