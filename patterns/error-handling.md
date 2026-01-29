# Error Handling Pattern

**Context**: Graceful degradation and fallback strategies for Tercen API integration

**Related Patterns**: [Authentication](authentication.md), [File Streaming](file-streaming.md)

**Related Skills**: [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)

## Problem

Tercen API integration can fail for various reasons:
- Authentication issues
- Network errors
- Server errors (500, 503)
- Wrong document type accessed
- Missing workflow context
- CORS issues

Apps should handle errors gracefully and provide fallback options.

## Solution

Implement layered error handling with fallback to mock data.

## Pattern Implementation

### Service with Mock Fallback

```dart
class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final ImageService _mockService;

  TercenImageService(this._factory, this._mockService);

  @override
  Future<ImageCollection> loadImages() async {
    try {
      print('🔍 Attempting to load images from Tercen API...');

      final images = await _loadFromTercen();

      print('✓ Successfully loaded ${images.length} images from Tercen');

      return ImageCollection(images: images);
    } catch (e) {
      print('✗ Error loading from Tercen: $e');
      print('Falling back to mock data');

      return _mockService.loadImages();
    }
  }

  Future<List<ImageMetadata>> _loadFromTercen() async {
    // Actual implementation...
  }
}
```

### Layered Error Handling

```dart
@override
Future<ImageCollection> loadImages() async {
  // Layer 1: Top-level try/catch with fallback
  try {
    // Layer 2: Validate context
    if (!_hasValidContext()) {
      throw Exception('No valid Tercen context detected');
    }

    // Layer 3: Find files with error handling
    final files = await _findFilesWithRetry();

    if (files.isEmpty) {
      throw Exception('No files found in Tercen context');
    }

    // Layer 4: Download files with error handling
    final images = await _downloadImagesWithRetry(files);

    if (images.isEmpty) {
      throw Exception('Failed to download any images');
    }

    return ImageCollection(images: images);
  } on AuthenticationException catch (e) {
    print('✗ Authentication failed: $e');
    return _mockService.loadImages();
  } on NetworkException catch (e) {
    print('✗ Network error: $e');
    return _mockService.loadImages();
  } on TimeoutException catch (e) {
    print('✗ Request timeout: $e');
    return _mockService.loadImages();
  } catch (e) {
    print('✗ Unexpected error: $e');
    return _mockService.loadImages();
  }
}
```

### Context Validation

```dart
bool _hasValidContext() {
  if (_urlParser.isStandaloneMode && _urlParser.documentId != null) {
    return true;
  }
  if (_urlParser.isWorkflowMode &&
      _urlParser.workflowId != null &&
      _urlParser.stepId != null) {
    return true;
  }
  return false;
}
```

### Retry Logic

```dart
Future<List<FileDocument>> _findFilesWithRetry({int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await _factory.fileService.findFileByWorkflowIdAndStepId(
        startKey: [_urlParser.workflowId, _urlParser.stepId],
        endKey: [_urlParser.workflowId, _urlParser.stepId, {}],
      );
    } catch (e) {
      print('✗ Find files attempt $attempt/$maxRetries failed: $e');

      if (attempt == maxRetries) {
        rethrow; // Exhausted retries
      }

      // Exponential backoff
      await Future.delayed(Duration(seconds: attempt));
    }
  }

  return []; // Should never reach here
}
```

### Individual Download Error Handling

```dart
Future<List<ImageMetadata>> _downloadImages(List<FileDocument> files) async {
  final images = <ImageMetadata>[];

  for (final file in files) {
    try {
      final bytes = await _downloadFile(file.id);

      if (bytes != null) {
        images.add(ImageMetadataImpl(
          id: file.id,
          filename: file.name,
          bytes: bytes,
        ));
      }
    } catch (e) {
      // Don't fail entire batch due to one file
      print('✗ Failed to download ${file.name}: $e');
      // Continue with next file
    }
  }

  return images;
}
```

## Tercen-Specific Error Types

### HTTP Error Codes

Tercen API returns standard HTTP errors with specific meanings:

```dart
// 404 Not Found - Wrong ID used (metadata vs data ID)
try {
  final bytes = await fileService.download(documentId); // Using metadata ID
} catch (e) {
  if (e.toString().contains('404') || e.toString().contains('not found')) {
    print('❌ File not found - likely using documentId instead of .documentId');
    // Retry with .documentId from task JSON
  }
}

// 500 Internal Server Error - Infrastructure issue
try {
  final stream = fileService.download(fileId);
} catch (e) {
  if (e.toString().contains('500') || e.toString().contains('internal server')) {
    print('❌ Server error - physical file may be missing from storage');
    print('   This is a server-side issue, not application code problem');
    // Fallback to mock or notify user
  }
}
```

**Common scenarios:**

| Error | Cause | Fix |
| ----- | ----- | --- |
| 404 | Using `documentId` instead of `.documentId` | Extract `.documentId` from task JSON |
| 404 | File deleted or moved | Check file exists, use fallback |
| 500 | Physical file missing from storage | Server-side issue, use mock data |
| 401 | Authentication failure | Check token, re-authenticate |
| 403 | Permission denied | Check user permissions |
| CORS | Manual HTTP call (not using client) | Always use ServiceFactory |

### Data Loading Error Reference

Standard handling for common data loading errors:

| Error | User Message | Handling |
|-------|--------------|----------|
| Invalid documentId | "Unable to access the requested file" | Display error, prevent further loading |
| ZIP download failure | "Failed to download file. Please try again." | Display error with retry button |
| ZIP extraction failure | "Unable to read the uploaded file" | Display error message |

### Parameter Validation

Validate required URL parameters before attempting API calls:

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse URL parameters
  final uri = Uri.base;
  final taskId = uri.queryParameters['taskId'];

  // Validate required parameters
  if (taskId == null || taskId.isEmpty) {
    print('❌ Error: Missing required parameter "taskId"');
    runApp(_buildErrorApp(
      'Missing Required Parameter',
      'This operator requires a "taskId" parameter.\n\n'
      'Please launch this operator from a Tercen workflow step.',
    ));
    return;
  }

  // Continue with normal initialization
  final tercenFactory = await createServiceFactoryForWebApp();
  // ...
}
```

### User-Friendly Error Screens

```dart
/// Builds an error screen with clear messaging
Widget _buildErrorApp(String title, String message) {
  return MaterialApp(
    title: 'Image Overview - Error',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    home: Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

### Specific Error Detection in Operations

```dart
Future<Uint8List?> _downloadAndConvertImage(String imageId) async {
  try {
    final bytes = await _downloadImage(imageId);
    return await _convertImage(bytes);
  } on TimeoutException {
    print('⏱️ Timeout downloading image $imageId (exceeded 30 seconds)');
    return null;
  } on StateError catch (e) {
    print('⚠️ Image metadata error for $imageId: $e');
    return null;
  } catch (e) {
    final errorMsg = e.toString().toLowerCase();

    // Provide specific error messages based on error type
    if (errorMsg.contains('format') || errorMsg.contains('invalid') ||
        errorMsg.contains('corrupt')) {
      print('❌ Corrupted image file $imageId: $e');
      print('   The file may be damaged or in an unsupported format');
    } else if (errorMsg.contains('not found') || errorMsg.contains('404')) {
      print('❌ Image file not found $imageId: $e');
      print('   File may have been deleted or ID is incorrect');
    } else if (errorMsg.contains('zip')) {
      print('❌ ZIP entry error for $imageId: $e');
      print('   The ZIP archive may be corrupted or entry path invalid');
    } else if (errorMsg.contains('permission') || errorMsg.contains('access')) {
      print('❌ Permission error accessing $imageId: $e');
      print('   Check file permissions or access rights');
    } else {
      print('❌ Error fetching image $imageId: $e');
    }

    return null;
  }
}
```

### ZIP File Error Handling

```dart
Future<List<ImageMetadata>> _loadImagesFromZip(String zipFileId) async {
  final images = <ImageMetadata>[];

  try {
    final zipEntries = await fileService.listZipContents(zipFileId);

    if (zipEntries.isEmpty) {
      print('⚠️ ZIP file is empty or could not be read');
      return images;
    }

    // Process entries...

    if (images.isEmpty && zipEntries.isNotEmpty) {
      print('⚠️ No valid files found in ZIP (${zipEntries.length} total entries)');
    }

    return images;

  } on TimeoutException {
    print('❌ Timeout reading ZIP file: Operation took too long');
    print('   The file may be very large or network is slow');
    return images;
  } catch (e) {
    final errorMsg = e.toString().toLowerCase();

    if (errorMsg.contains('format') || errorMsg.contains('invalid') ||
        errorMsg.contains('corrupt') || errorMsg.contains('magic')) {
      print('❌ ZIP file appears to be corrupted or invalid: $e');
      print('   Please check that the uploaded file is a valid ZIP archive');
    } else if (errorMsg.contains('permission') || errorMsg.contains('access')) {
      print('❌ Permission error accessing ZIP file: $e');
      print('   The file may be locked or access rights are insufficient');
    } else if (errorMsg.contains('not found') || errorMsg.contains('404')) {
      print('❌ ZIP file not found: $e');
      print('   The file may have been deleted or moved');
    } else {
      print('❌ Error loading images from ZIP: $e');
    }

    return images;
  }
}
```

## Debug Logging

Use consistent emoji prefixes for visual scanning:

```dart
// Starting operations
print('🔍 Searching for files...');
print('🔍 Parsing URL...');
print('🔍 Downloading file...');

// Success
print('✓ Found 10 files');
print('✓ Download complete');
print('✓ Authentication successful');

// Errors
print('✗ Authentication failed');
print('✗ Network error');
print('✗ File not found');

// Information
print('📋 Path segments: $pathSegments');
print('📋 Files: ${files.length}');

// Development mode
print('🔧 DEV MODE: Using localhost');
print('🔧 DEV MODE: Mock data enabled');

// Warnings
print('⚠️ No files found, using defaults');
print('⚠️ Partial download failure');
```

## Error Types

### Custom Exception Classes

```dart
class TercenException implements Exception {
  final String message;
  final dynamic originalError;

  TercenException(this.message, [this.originalError]);

  @override
  String toString() => 'TercenException: $message${originalError != null ? " ($originalError)" : ""}';
}

class AuthenticationException extends TercenException {
  AuthenticationException(String message, [dynamic originalError])
      : super(message, originalError);
}

class NetworkException extends TercenException {
  NetworkException(String message, [dynamic originalError])
      : super(message, originalError);
}

class ContextException extends TercenException {
  ContextException(String message, [dynamic originalError])
      : super(message, originalError);
}
```

### Exception Usage

```dart
Future<ServiceFactory> _createFactory() async {
  try {
    return await createServiceFactoryForWebApp();
  } catch (e) {
    throw AuthenticationException('Failed to create service factory', e);
  }
}

Future<List<FileDocument>> _findFiles() async {
  try {
    return await _factory.fileService.findFileByWorkflowIdAndStepId(...);
  } on SocketException catch (e) {
    throw NetworkException('Network connectivity issue', e);
  } on TimeoutException catch (e) {
    throw NetworkException('Request timeout', e);
  } catch (e) {
    throw TercenException('Failed to find files', e);
  }
}
```

## User-Friendly Error Messages

### Provider with Error State

```dart
class ImageOverviewProvider with ChangeNotifier {
  ImageCollection? _images;
  String? _errorMessage;
  bool _isLoading = false;

  ImageCollection? get images => _images;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;

  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _images = await _imageService.loadImages();
      _errorMessage = null;
    } on AuthenticationException {
      _errorMessage = 'Authentication failed. Please check your credentials.';
    } on NetworkException {
      _errorMessage = 'Network error. Please check your connection.';
    } on ContextException {
      _errorMessage = 'Invalid context. Please open from a Tercen workflow.';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Using sample data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### UI Error Display

```dart
Widget build(BuildContext context) {
  return Consumer<ImageOverviewProvider>(
    builder: (context, provider, child) {
      // Error state
      if (provider.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.loadImages(),
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }

      // Loading state
      if (provider.isLoading) {
        return Center(child: CircularProgressIndicator());
      }

      // Success state
      return ImageGrid(images: provider.images!);
    },
  );
}
```

## Partial Failure Handling

```dart
class DownloadResult {
  final List<ImageMetadata> successful;
  final List<FileDocument> failed;

  DownloadResult({
    required this.successful,
    required this.failed,
  });

  bool get hasFailures => failed.isNotEmpty;
  bool get hasAnySuccess => successful.isNotEmpty;
}

Future<DownloadResult> downloadImages(List<FileDocument> files) async {
  final successful = <ImageMetadata>[];
  final failed = <FileDocument>[];

  for (final file in files) {
    try {
      final bytes = await _downloadFile(file.id);
      successful.add(ImageMetadataImpl(
        id: file.id,
        filename: file.name,
        bytes: bytes,
      ));
    } catch (e) {
      print('✗ Failed: ${file.name}');
      failed.add(file);
    }
  }

  if (successful.isEmpty && failed.isNotEmpty) {
    throw TercenException('All downloads failed');
  }

  if (failed.isNotEmpty) {
    print('⚠️ Partial failure: ${successful.length}/${files.length} succeeded');
  }

  return DownloadResult(successful: successful, failed: failed);
}
```

## Testing Error Scenarios

```dart
void main() {
  test('Falls back to mock on authentication error', () async {
    final mockFactory = MockServiceFactory()
      ..throwAuthError = true;

    final service = TercenImageService(mockFactory, mockService);

    final result = await service.loadImages();

    // Should return mock data, not throw
    expect(result.images, isNotEmpty);
    expect(result.images, equals(mockService.loadImages().images));
  });

  test('Retries failed requests', () async {
    int attempts = 0;
    final mockFactory = MockServiceFactory()
      ..onFindFiles = () {
        attempts++;
        if (attempts < 3) throw NetworkException('Simulated failure');
        return [];
      };

    await service.loadImages();

    expect(attempts, equals(3)); // Retried 3 times
  });
}
```

## See Also

- [Pattern: Authentication](authentication.md)
- [Pattern: File Streaming](file-streaming.md)
- [Pattern: Concurrency](concurrency.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
- [Issue #3: CORS Errors](../issues/3-cors-errors.md)
