# Concurrency Management Pattern

**Context**: Download multiple files concurrently without overwhelming server

**Related Patterns**: [File Streaming](file-streaming.md)

**Related Skills**: [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)

## Problem

When downloading many files from Tercen:
- Downloading sequentially is too slow (one at a time)
- Downloading all concurrently overwhelms server and network
- Need to balance performance with resource constraints

## Solution

Use a queue pattern with maximum concurrent downloads (typically 3).

## Pattern Implementation

### Queue-Based Concurrency Manager

```dart
class TercenImageService implements ImageService {
  final ServiceFactory _factory;

  // Concurrency control
  static const _maxConcurrentDownloads = 3;
  final _downloadQueue = <_DownloadRequest>[];
  int _activeDownloads = 0;

  Future<List<ImageMetadata>> downloadImages(List<FileDocument> files) async {
    final results = <ImageMetadata>[];
    final completers = <String, Completer<Uint8List?>>{};

    // Queue all download requests
    for (final file in files) {
      final completer = Completer<Uint8List?>();
      completers[file.id] = completer;

      _downloadQueue.add(_DownloadRequest(
        fileId: file.id,
        filename: file.name,
        completer: completer,
      ));
    }

    // Start processing queue
    _processQueue();

    // Wait for all downloads to complete
    final downloads = await Future.wait(completers.values.map((c) => c.future));

    // Convert to ImageMetadata
    for (int i = 0; i < files.length; i++) {
      final bytes = downloads[i];
      if (bytes != null) {
        results.add(ImageMetadataImpl(
          id: files[i].id,
          filename: files[i].name,
          bytes: bytes,
        ));
      }
    }

    return results;
  }

  void _processQueue() {
    // Process as many items as concurrency allows
    while (_activeDownloads < _maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      final request = _downloadQueue.removeAt(0);
      _activeDownloads++;

      _downloadFile(request).then((_) {
        _activeDownloads--;
        _processQueue(); // Process next item
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
      request.completer.complete(null); // Complete with null on error
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

## Key Concepts

### Completer Pattern

```dart
// Completer allows manual control of Future completion
final completer = Completer<Uint8List?>();

// Start async operation
_downloadFile(fileId).then((bytes) {
  completer.complete(bytes); // Complete the future
});

// Wait for completion elsewhere
final result = await completer.future;
```

### Queue Processing

```dart
void _processQueue() {
  // Only start new downloads if:
  // 1. Under concurrency limit
  // 2. Items remain in queue
  while (_activeDownloads < _maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
    final request = _downloadQueue.removeAt(0);
    _activeDownloads++;

    // Start download, then recursively process queue when done
    _startDownload(request).then((_) {
      _activeDownloads--;
      _processQueue(); // Continue processing
    });
  }
}
```

### Concurrency Slot Management

```dart
// Track active downloads
int _activeDownloads = 0;
static const _maxConcurrentDownloads = 3;

// Before starting download
if (_activeDownloads < _maxConcurrentDownloads) {
  _activeDownloads++;
  // Start download
}

// After completing download
_activeDownloads--;
_processQueue(); // Try to start next download
```

## Alternative: Simple Parallel with Limit

For simpler cases without queue:

```dart
Future<List<ImageMetadata>> downloadImagesSimple(List<FileDocument> files) async {
  final results = <ImageMetadata>[];

  // Process in batches of 3
  for (int i = 0; i < files.length; i += 3) {
    final batch = files.skip(i).take(3).toList();

    // Download batch concurrently
    final futures = batch.map((file) => _downloadFile(file.id));
    final downloads = await Future.wait(futures);

    // Process results
    for (int j = 0; j < batch.length; j++) {
      if (downloads[j] != null) {
        results.add(ImageMetadataImpl(
          id: batch[j].id,
          filename: batch[j].name,
          bytes: downloads[j]!,
        ));
      }
    }
  }

  return results;
}
```

## Configuration

### Adjust Concurrency Based on Environment

```dart
class ConcurrencyConfig {
  static int get maxConcurrentDownloads {
    // More aggressive in production
    if (kReleaseMode) {
      return 5;
    }
    // Conservative in development
    else {
      return 3;
    }
  }

  static int get maxConcurrentUploads => 2; // Always conservative

  static Duration get downloadTimeout => Duration(seconds: 30);
}
```

## Progress Tracking

```dart
class TercenImageService implements ImageService {
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Future<void> _downloadFile(_DownloadRequest request) async {
    try {
      // Notify progress: started
      _progressController.add(DownloadProgress(
        fileId: request.fileId,
        status: DownloadStatus.inProgress,
        bytesReceived: 0,
      ));

      final stream = _factory.fileService.download(request.fileId);
      final chunks = <List<int>>[];
      int totalBytes = 0;

      await for (final chunk in stream) {
        chunks.add(chunk);
        totalBytes += chunk.length;

        // Notify progress: receiving
        _progressController.add(DownloadProgress(
          fileId: request.fileId,
          status: DownloadStatus.inProgress,
          bytesReceived: totalBytes,
        ));
      }

      final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());

      // Notify progress: completed
      _progressController.add(DownloadProgress(
        fileId: request.fileId,
        status: DownloadStatus.completed,
        bytesReceived: totalBytes,
      ));

      request.completer.complete(bytes);
    } catch (e) {
      // Notify progress: failed
      _progressController.add(DownloadProgress(
        fileId: request.fileId,
        status: DownloadStatus.failed,
        error: e.toString(),
      ));

      request.completer.complete(null);
    }
  }

  void dispose() {
    _progressController.close();
  }
}

class DownloadProgress {
  final String fileId;
  final DownloadStatus status;
  final int? bytesReceived;
  final String? error;

  DownloadProgress({
    required this.fileId,
    required this.status,
    this.bytesReceived,
    this.error,
  });
}

enum DownloadStatus { pending, inProgress, completed, failed }
```

## Error Handling

### Retry Failed Downloads

```dart
Future<void> _downloadFile(_DownloadRequest request, {int retries = 3}) async {
  for (int attempt = 1; attempt <= retries; attempt++) {
    try {
      final bytes = await _performDownload(request.fileId);
      request.completer.complete(bytes);
      return;
    } catch (e) {
      print('✗ Download attempt $attempt/$retries failed: ${request.filename}');

      if (attempt == retries) {
        print('✗ All retries exhausted for: ${request.filename}');
        request.completer.complete(null);
      } else {
        // Exponential backoff
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }
}
```

### Timeout Handling

```dart
Future<void> _downloadFile(_DownloadRequest request) async {
  try {
    final bytes = await _performDownload(request.fileId)
        .timeout(Duration(seconds: 30));

    request.completer.complete(bytes);
  } on TimeoutException {
    print('✗ Download timeout: ${request.filename}');
    request.completer.complete(null);
  } catch (e) {
    print('✗ Download error: ${request.filename} - $e');
    request.completer.complete(null);
  }
}
```

## Common Mistakes

### ❌ WRONG: Unbounded concurrency

```dart
// DON'T DO THIS - will overwhelm server with 100s of requests
final futures = files.map((file) => downloadFile(file.id));
await Future.wait(futures); // All at once!
```

### ❌ WRONG: Sequential downloads

```dart
// DON'T DO THIS - too slow for many files
for (final file in files) {
  await downloadFile(file.id); // One at a time
}
```

### ✅ CORRECT: Managed concurrency

```dart
// DO THIS - balanced approach
_downloadQueue.addAll(requests);
_processQueue(); // Max 3 concurrent
```

## Testing

```dart
void main() {
  test('Respects concurrency limit', () async {
    final service = TercenImageService(mockFactory);

    // Track concurrent downloads
    int maxConcurrent = 0;
    int currentConcurrent = 0;

    service._onDownloadStart = () {
      currentConcurrent++;
      maxConcurrent = max(maxConcurrent, currentConcurrent);
    };

    service._onDownloadEnd = () {
      currentConcurrent--;
    };

    // Download 10 files
    await service.downloadImages(generate10Files());

    // Should never exceed limit
    expect(maxConcurrent, lessThanOrEqualTo(3));
  });
}
```

## See Also

- [Pattern: File Streaming](file-streaming.md)
- [Pattern: Error Handling](error-handling.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
