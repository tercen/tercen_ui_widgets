# Pattern: Lazy Loading with FutureBuilder

## Overview

Lazy loading prevents loading all data upfront by loading resources only when needed. In Flutter, this is commonly implemented with `FutureBuilder` for on-demand widget data.

**Key benefits:**
- Reduced initial load time
- Lower memory usage
- Better performance with large datasets
- Improved user experience (faster initial render)

## The Problem

```dart
// ❌ Bad - loads all images upfront
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final images = await imageService.loadAll(); // Loads 500+ images!

    return GridView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) => Image.memory(images[index].bytes),
    );
  }
}
```

**Issues:**
- High memory usage (all images in memory)
- Slow initial load
- Browser may crash with large datasets

## The Solution: FutureBuilder Pattern

Load data on-demand when widgets become visible:

```dart
// ✅ Good - loads images on demand
class ImageGridCell extends StatelessWidget {
  final ImageMetadata metadata; // Only lightweight metadata
  final ImageService imageService;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: imageService.fetchAndConvertImage(metadata.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorIndicator('Failed to load');
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorIndicator('Invalid image');
            },
          );
        }

        return _buildErrorIndicator('No data');
      },
    );
  }

  Widget _buildErrorIndicator(String message) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 32),
            SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
```

## How It Works

### Two-Phase Loading

**Phase 1: Load Metadata (Upfront)**
```dart
// Lightweight - only file names, IDs, etc.
final metadata = await imageService.loadMetadata();
// Result: 528 entries, ~10KB total

print('Loaded ${metadata.length} image metadata entries');
```

**Phase 2: Load Actual Data (On-Demand)**
```dart
// Triggered when cell becomes visible
FutureBuilder<Uint8List?>(
  future: imageService.fetchAndConvertImage(metadata.id),
  // Fetches and converts only when this widget builds
)
```

### Verification

Console output confirms lazy loading:

```
Found 532 entries in zip file
Extracted 528 TIFF files from zip

Found 3 unique barcodes

Converted and cached image ...478_A29 (234 KB)  ← Only 36 images
Converted and cached image ...019_A29 (189 KB)
... (total ~36 images, not 528!)
```

**Key observation**: Only ~36 images converted out of 528 total, proving lazy loading works.

## Implementation Pattern

### Service Layer

```dart
class TercenImageService implements ImageService {
  final _cache = ImageCache();

  @override
  Future<ImageCollection> loadImages() async {
    // Load metadata only (lightweight)
    final zipEntries = await _loadZipMetadata();
    final metadata = zipEntries.map((entry) => ImageMetadata(
      id: entry.name,
      filename: entry.name,
      // No bytes field - will load on demand
    )).toList();

    return ImageCollection(images: metadata);
  }

  @override
  Future<Uint8List?> fetchAndConvertImage(String imageId) async {
    // Check cache first
    final cached = _cache.get(imageId);
    if (cached != null) return cached;

    // Load on demand
    final tiffBytes = await _extractFromZip(imageId);
    if (tiffBytes == null) return null;

    // Convert format if needed
    final pngBytes = await _convertTiffToPng(tiffBytes);

    // Cache result
    if (pngBytes != null) {
      _cache.put(imageId, pngBytes);
    }

    return pngBytes;
  }
}
```

### Widget Layer

```dart
class ImageGrid extends StatelessWidget {
  final ImageCollection collection;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.35,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: collection.images.length,
      itemBuilder: (context, index) {
        final metadata = collection.images[index];

        // Each cell loads its image independently
        return ImageGridCell(
          metadata: metadata,
          imageService: locator<ImageService>(),
        );
      },
    );
  }
}
```

## Caching Strategy

### In-Memory Cache

```dart
class ImageCache {
  final Map<String, Uint8List> _cache = {};
  final int _maxSize = 100; // Limit cache size

  Uint8List? get(String key) => _cache[key];

  void put(String key, Uint8List value) {
    if (_cache.length >= _maxSize) {
      // Remove oldest entry (simple LRU)
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[key] = value;
  }

  void clear() => _cache.clear();
}
```

### Benefits

- ✅ Repeated views don't reload
- ✅ Scroll back = instant display
- ✅ Bounded memory usage (max cache size)

## Performance Optimization

### Debounce Rapid Scrolling

```dart
class ImageGridCell extends StatefulWidget {
  @override
  _ImageGridCellState createState() => _ImageGridCellState();
}

class _ImageGridCellState extends State<ImageGridCell> {
  Timer? _debounceTimer;
  Future<Uint8List?>? _loadFuture;

  @override
  void initState() {
    super.initState();
    // Delay loading slightly to avoid loading during fast scroll
    _debounceTimer = Timer(Duration(milliseconds: 100), () {
      setState(() {
        _loadFuture = widget.imageService.fetchAndConvertImage(widget.metadata.id);
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFuture == null) {
      return Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Uint8List?>(
      future: _loadFuture,
      builder: (context, snapshot) {
        // ... same as before
      },
    );
  }
}
```

### Preload Adjacent Items

```dart
class SmartImageGrid extends StatefulWidget {
  @override
  _SmartImageGridState createState() => _SmartImageGridState();
}

class _SmartImageGridState extends State<SmartImageGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Calculate visible range
    final visibleStart = _scrollController.offset;
    final visibleEnd = visibleStart + _scrollController.position.viewportDimension;

    // Preload next few items
    // ... preloading logic
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      // ... rest of grid
    );
  }
}
```

## Error Handling

### Graceful Degradation

```dart
FutureBuilder<Uint8List?>(
  future: imageService.fetchAndConvertImage(metadata.id),
  builder: (context, snapshot) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingIndicator();
    }

    // Error state - show placeholder, don't crash
    if (snapshot.hasError) {
      print('⚠️ Failed to load ${metadata.id}: ${snapshot.error}');
      return ErrorPlaceholder();
    }

    // Empty state
    if (!snapshot.hasData || snapshot.data == null) {
      return EmptyPlaceholder();
    }

    // Success state
    return Image.memory(snapshot.data!);
  },
)
```

## Testing

### Test Lazy Loading Behavior

```dart
test('loads metadata without loading images', () async {
  final service = TercenImageService();

  final collection = await service.loadImages();

  // Should have metadata
  expect(collection.images.length, greaterThan(0));

  // Should NOT have loaded image bytes yet
  // (This test depends on your implementation)
});

test('loads image on demand', () async {
  final service = TercenImageService();
  final collection = await service.loadImages();
  final firstImage = collection.images.first;

  // Load on demand
  final bytes = await service.fetchAndConvertImage(firstImage.id);

  expect(bytes, isNotNull);
  expect(bytes!.length, greaterThan(0));
});
```

### Test Caching

```dart
test('caches loaded images', () async {
  final service = TercenImageService();
  final imageId = 'test-image-1';

  // First load
  final bytes1 = await service.fetchAndConvertImage(imageId);

  // Second load (should be cached)
  final bytes2 = await service.fetchAndConvertImage(imageId);

  // Should be same instance (from cache)
  expect(identical(bytes1, bytes2), isTrue);
});
```

## Checklist

- [ ] Load metadata upfront (lightweight)
- [ ] Load actual data on-demand (FutureBuilder)
- [ ] Implement loading states (waiting, error, success)
- [ ] Add in-memory caching to avoid reloading
- [ ] Limit cache size to prevent memory issues
- [ ] Show loading indicators for pending data
- [ ] Show error placeholders for failures
- [ ] Test with large datasets (500+ items)
- [ ] Verify memory usage stays low
- [ ] Confirm only visible items load

## Related

- **Pattern**: [Error Handling](error-handling.md)
- **Pattern**: [File Streaming](file-streaming.md)
- **Pattern**: [Concurrency](concurrency.md)
- **Skill**: [1 Tercen Mock Implementation](../skills/1-tercen-mock.md)
- **Skill**: [2 Tercen Real Implementation](../skills/2-tercen-real.md)
