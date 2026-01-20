# File Streaming Pattern

**Context**: Download large files from Tercen API using async streams

**Related Patterns**: [Authentication](authentication.md), [Concurrency](concurrency.md)

**Related Skills**: [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)

## Problem

Tercen stores large files (images, data files) that need to be:
- Downloaded efficiently without blocking UI
- Streamed in chunks to manage memory
- Handled asynchronously for better performance

## Solution

Use `ServiceFactory.fileService.download()` which returns a `Stream<List<int>>`.

## Pattern Implementation

### Basic Stream Download

```dart
Future<Uint8List> downloadFile(String fileId) async {
  final fileService = _factory.fileService;

  print('🔍 Starting download: $fileId');

  // Get stream from file service
  final stream = fileService.download(fileId);

  // Collect all chunks
  final chunks = <List<int>>[];

  await for (final chunk in stream) {
    chunks.add(chunk);
    print('  📦 Received chunk: ${chunk.length} bytes');
  }

  // Flatten into single byte array
  final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());

  print('✓ Download complete: ${bytes.length} bytes');

  return bytes;
}
```

### With Progress Tracking

```dart
Future<Uint8List> downloadFileWithProgress(
  String fileId,
  void Function(int bytesReceived, int? totalBytes)? onProgress,
) async {
  final fileService = _factory.fileService;

  final stream = fileService.download(fileId);
  final chunks = <List<int>>[];
  int bytesReceived = 0;

  await for (final chunk in stream) {
    chunks.add(chunk);
    bytesReceived += chunk.length;

    // Report progress
    onProgress?.call(bytesReceived, null); // Total size unknown from stream
  }

  return Uint8List.fromList(chunks.expand((x) => x).toList());
}
```

### With Error Handling

```dart
Future<Uint8List?> downloadFileSafe(String fileId) async {
  try {
    final stream = _factory.fileService.download(fileId);
    final chunks = <List<int>>[];

    await for (final chunk in stream) {
      chunks.add(chunk);
    }

    return Uint8List.fromList(chunks.expand((x) => x).toList());
  } on TimeoutException catch (e) {
    print('✗ Download timeout for $fileId: $e');
    return null;
  } on IOException catch (e) {
    print('✗ Download IO error for $fileId: $e');
    return null;
  } catch (e) {
    print('✗ Download failed for $fileId: $e');
    return null;
  }
}
```

### With Timeout

```dart
Future<Uint8List> downloadFileWithTimeout(
  String fileId,
  Duration timeout = const Duration(seconds: 30),
) async {
  final stream = _factory.fileService.download(fileId);
  final chunks = <List<int>>[];

  await for (final chunk in stream.timeout(timeout)) {
    chunks.add(chunk);
  }

  return Uint8List.fromList(chunks.expand((x) => x).toList());
}
```

## Complete Service Implementation

```dart
class TercenImageService implements ImageService {
  final ServiceFactory _factory;
  final ImageService _mockService;

  TercenImageService(this._factory, this._mockService);

  @override
  Future<ImageCollection> loadImages() async {
    try {
      // 1. Find files in workflow context
      final files = await _findFiles();

      print('📋 Found ${files.length} files to download');

      // 2. Download files with concurrency management
      final images = await _downloadImages(files);

      return ImageCollection(images: images);
    } catch (e) {
      print('✗ Error loading images: $e');
      print('Falling back to mock data');
      return _mockService.loadImages();
    }
  }

  Future<List<FileDocument>> _findFiles() async {
    final fileService = _factory.fileService;

    final files = await fileService.findFileByWorkflowIdAndStepId(
      startKey: [workflowId, stepId],
      endKey: [workflowId, stepId, {}],
    );

    return files;
  }

  Future<List<ImageMetadata>> _downloadImages(List<FileDocument> files) async {
    final images = <ImageMetadata>[];

    for (final file in files) {
      final bytes = await _downloadFile(file.id);

      if (bytes != null) {
        final image = ImageMetadataImpl(
          id: file.id,
          filename: file.name,
          bytes: bytes,
          // Parse metadata from filename...
        );
        images.add(image);
      }
    }

    return images;
  }

  Future<Uint8List?> _downloadFile(String fileId) async {
    try {
      final stream = _factory.fileService.download(fileId);
      final chunks = <List<int>>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      return Uint8List.fromList(chunks.expand((x) => x).toList());
    } catch (e) {
      print('✗ Failed to download $fileId: $e');
      return null;
    }
  }
}
```

## Key Concepts

### Stream vs Future

```dart
// Stream - processes data in chunks as it arrives
Stream<List<int>> download(String fileId);

// Must consume stream with async iteration
await for (final chunk in stream) {
  // Process each chunk
}

// Future - waits for complete result
Future<Uint8List> getData();
```

### Memory Efficiency

```dart
// Efficient - processes chunks incrementally
await for (final chunk in stream) {
  chunks.add(chunk); // Small allocations
}

// Less efficient - waits for entire file in memory
final allBytes = await file.readAsBytes(); // Large allocation
```

### Chunk Processing

```dart
// Option 1: Collect all chunks then flatten
final chunks = <List<int>>[];
await for (final chunk in stream) {
  chunks.add(chunk);
}
final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());

// Option 2: Stream directly to file (for very large files)
final file = File('output.dat');
final sink = file.openWrite();
await for (final chunk in stream) {
  sink.add(chunk);
}
await sink.close();
```

## Common Mistakes

### ❌ WRONG: Not consuming stream

```dart
// DON'T DO THIS - stream not consumed
final stream = fileService.download(fileId);
// Stream never iterated, download never completes!
```

### ❌ WRONG: Synchronous processing

```dart
// DON'T DO THIS - missing await
for (final chunk in stream) { // Error: stream is not Iterable
  chunks.add(chunk);
}
```

### ✅ CORRECT: Async iteration

```dart
// DO THIS - properly consume async stream
await for (final chunk in stream) {
  chunks.add(chunk);
}
```

## Testing

### Mock Stream Service

```dart
class MockFileService implements FileService {
  @override
  Stream<List<int>> download(String fileId) async* {
    // Simulate chunked download
    final data = _getMockFileData(fileId);

    // Yield in chunks of 1024 bytes
    for (int i = 0; i < data.length; i += 1024) {
      final end = (i + 1024 < data.length) ? i + 1024 : data.length;
      yield data.sublist(i, end);

      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 10));
    }
  }
}
```

## Performance Considerations

### Concurrency

Download multiple files concurrently for better performance:

```dart
// See concurrency.md pattern for queue management
final futures = files.map((file) => _downloadFile(file.id));
final results = await Future.wait(futures);
```

But limit concurrency to avoid overwhelming server (see [Concurrency Pattern](concurrency.md)).

### Caching

Cache downloaded files to avoid redundant downloads:

```dart
final _cache = <String, Uint8List>{};

Future<Uint8List> downloadFile(String fileId) async {
  if (_cache.containsKey(fileId)) {
    print('✓ Using cached file: $fileId');
    return _cache[fileId]!;
  }

  final bytes = await _downloadFileFromStream(fileId);
  _cache[fileId] = bytes;
  return bytes;
}
```

## See Also

- [Pattern: Concurrency Management](concurrency.md)
- [Pattern: Authentication](authentication.md)
- [Pattern: Error Handling](error-handling.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
