# Skill 3: Customer PamGene

**Purpose**: PamGene-specific patterns and conventions

**Extends**: [Skill 2: Tercen Real Implementation](2-tercen-real.md)

**Use When**: Building PamGene-specific features or microscopy image tools

## Overview

This skill covers PamGene domain-specific patterns:
- PamGene filename parsing (`{barcode}_W{well}_F{field}...`)
- TIFF conversion utilities (16-bit → 8-bit PNG)
- Grid layout patterns (270px × 200px cells)
- Well/Field/Array mapping
- Filter defaults (latest cycle, longest exposure)
- Domain-specific UI patterns

## Prerequisites - Auto-Fetch Example Project

```bash
# Auto-fetch ps12 working example
gh repo clone tercen/ps12_image_overview_flutter_operator --depth 1 /tmp/tercen-refs/ps12
```

**Key files to review**:
- `lib/utils/tiff_converter.dart` - TIFF conversion utility
- `lib/implementations/services/mock_image_service.dart` - Filename parsing examples
- `lib/implementations/services/tercen_image_service.dart` - Complete implementation
- `assets/` - Real PamGene PNG samples

## Pattern 1: PamGene Filename Convention

### Filename Format

```
{barcode}_W{well}_F{field}_T{temperature}_P{pumpCycle}_I{intensity}_A{array}.tif

Example: 641070616_W1_F1_T100_P94_I493_A30.tif

Components:
- barcode: 641070616 (9 digits, unique plate identifier)
- well: 1 (W1 = well 1, range: W1-W4)
- field: 1 (F1 = field 1, microscopy field of view)
- temperature: 100 (T100 = 100°C)
- pumpCycle: 94 (P94 = pump cycle 94)
- intensity: 493 (I493 = exposure intensity 493ms)
- array: 30 (A30 = array type 30)
```

### Filename Parser

```dart
// lib/utils/pamgene_filename_parser.dart
class PamGeneFilenameParser {
  static final _pattern = RegExp(
    r'(\d+)_W(\d+)_F(\d+)_T(\d+)_P(\d+)_I(\d+)_A(\d+)',
  );

  static Map<String, dynamic>? parse(String filename) {
    final match = _pattern.firstMatch(filename);

    if (match == null) return null;

    return {
      'barcode': match.group(1)!,
      'well': int.parse(match.group(2)!),
      'field': int.parse(match.group(3)!),
      'temperature': int.parse(match.group(4)!),
      'pumpCycle': int.parse(match.group(5)!),
      'intensity': int.parse(match.group(6)!),
      'array': int.parse(match.group(7)!),
    };
  }

  static String getBarcode(String filename) {
    final parsed = parse(filename);
    return parsed?['barcode'] ?? '';
  }

  static int getWell(String filename) {
    final parsed = parse(filename);
    return parsed?['well'] ?? 0;
  }

  static int getPumpCycle(String filename) {
    final parsed = parse(filename);
    return parsed?['pumpCycle'] ?? 0;
  }

  static int getExposureTime(String filename) {
    final parsed = parse(filename);
    return parsed?['intensity'] ?? 0;
  }
}
```

### Using Parser in Service

```dart
class TercenImageService implements ImageService {
  Future<List<ImageMetadata>> _processFiles(List<FileDocument> files) async {
    final images = <ImageMetadata>[];

    for (final file in files) {
      final parsed = PamGeneFilenameParser.parse(file.name);

      if (parsed != null) {
        final bytes = await _downloadFile(file.id);

        images.add(ImageMetadataImpl(
          id: file.id,
          filename: file.name,
          barcode: parsed['barcode'],
          well: parsed['well'],
          field: parsed['field'],
          cycle: parsed['pumpCycle'], // Temperature = cycle in PamGene
          exposureTime: parsed['intensity'],
          bytes: bytes,
        ));
      }
    }

    return images;
  }
}
```

## Pattern 2: TIFF Conversion

**See**: [Pattern: TIFF Conversion](../patterns/tiff-conversion.md)

### Problem

PamGene TIFFs:
- 16-bit grayscale format
- 12-bit data in 16-bit container (range 0-4095)
- Too large for web display

Need: 8-bit PNG for efficient web rendering

### Conversion Utility

```dart
// lib/utils/tiff_converter.dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TiffConverter {
  /// Convert 16-bit TIFF to 8-bit PNG
  static Uint8List? convertToPng(Uint8List tiffBytes) {
    final image = decode16BitGrayscaleTiff(tiffBytes);
    if (image == null) return null;

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Decode 16-bit grayscale TIFF
  static img.Image? decode16BitGrayscaleTiff(Uint8List bytes) {
    if (bytes.length < 8) return null;

    final byteData = ByteData.sublistView(bytes);

    // Read TIFF header and determine byte order
    final byteOrder = _readByteOrder(byteData);
    if (byteOrder == null) return null;

    // Read IFD (Image File Directory)
    final ifdOffset = byteData.getUint32(4, byteOrder);
    final ifd = _parseIFD(byteData, ifdOffset, byteOrder);
    if (ifd == null) return null;

    // Extract image dimensions
    final width = ifd['ImageWidth'] as int?;
    final height = ifd['ImageLength'] as int?;

    if (width == null || height == null) return null;

    // Read image data strips
    final stripOffsets = ifd['StripOffsets'] as List<int>?;
    final stripByteCounts = ifd['StripByteCounts'] as List<int>?;

    if (stripOffsets == null || stripByteCounts == null) return null;

    final imageData = _readStrips(byteData, stripOffsets, stripByteCounts, byteOrder);

    // Convert 12-bit to 8-bit
    return _convertTo8Bit(imageData, width, height);
  }

  static Endian? _readByteOrder(ByteData byteData) {
    final byte0 = byteData.getUint8(0);
    final byte1 = byteData.getUint8(1);

    if (byte0 == 0x49 && byte1 == 0x49) return Endian.little; // II
    if (byte0 == 0x4D && byte1 == 0x4D) return Endian.big;    // MM

    return null;
  }

  static img.Image _convertTo8Bit(Uint16List data16, int width, int height) {
    final image = img.Image(width: width, height: height);

    // PamGene uses 12-bit data in 16-bit container
    // Convert to 8-bit by right-shifting 4 bits (divide by 16)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final value16 = data16[index];

        // Right-shift 4 bits: 12-bit (0-4095) → 8-bit (0-255)
        final value8 = (value16 >> 4).clamp(0, 255);

        // Set grayscale pixel
        image.setPixelRgba(x, y, value8, value8, value8, 255);
      }
    }

    return image;
  }

  // ... (full implementation in pattern file)
}
```

### Using Converter in Service

```dart
class TercenImageService implements ImageService {
  Future<ImageMetadata> _processFile(FileDocument file) async {
    // Download TIFF
    final tiffBytes = await _downloadFile(file.id);

    // Convert to PNG
    final pngBytes = TiffConverter.convertToPng(tiffBytes);

    if (pngBytes == null) {
      throw Exception('Failed to convert TIFF: ${file.name}');
    }

    // Parse metadata from filename
    final parsed = PamGeneFilenameParser.parse(file.name);

    return ImageMetadataImpl(
      id: file.id,
      filename: file.name,
      bytes: pngBytes, // PNG, not TIFF
      barcode: parsed?['barcode'] ?? '',
      well: parsed?['well'] ?? 0,
      // ...
    );
  }
}
```

## Pattern 3: Grid Layout Requirements

### PamGene Grid Structure

**Rows**: Organized by well (W1, W2, W3, W4) - always 4 rows

**Columns**: Organized by barcode (unique plate IDs) - variable count

**Cell Aspect Ratio**: Approximately 270:200 (1.35:1) optimized for microscopy images

### Grid Cell Metadata Display

Each cell should display:
- Image thumbnail
- Well and Field identifiers (e.g., "W1 F1")
- Cycle and Exposure time (e.g., "Cycle 94 • 493ms")

### UI Implementation

**IMPORTANT**: For the actual UI implementation (widgets, layout structure), follow the Tercen design guidelines:

- **`_local/tercen-style/specifications/Tercen-Layout-Principles.html`** - App structure, left panel layout
- **`_local/tercen-style/specifications/Tercen-Style-Guide.html`** - Colors, typography, components

The grid must fit within the Tercen left-panel + content-area structure defined in the Layout Principles.

## Pattern 4: Well Mapping

### Well to Column Mapping

```dart
// PamGene convention: W1 = column 0, W2 = column 1, etc.
int wellToColumn(int well) => well - 1;

int columnToWell(int column) => column + 1;
```

### Organizing Images by Well

```dart
class ImageOrganizer {
  static Map<int, List<ImageMetadata>> groupByWell(List<ImageMetadata> images) {
    final grouped = <int, List<ImageMetadata>>{};

    for (final image in images) {
      grouped.putIfAbsent(image.well, () => []).add(image);
    }

    return grouped;
  }

  static Map<String, List<ImageMetadata>> groupByBarcode(List<ImageMetadata> images) {
    final grouped = <String, List<ImageMetadata>>{};

    for (final image in images) {
      grouped.putIfAbsent(image.barcode, () => []).add(image);
    }

    return grouped;
  }
}
```

## Pattern 5: Filter Defaults

### Latest Cycle and Longest Exposure

```dart
class PamGeneFilterDefaults {
  static int getDefaultCycle(List<ImageMetadata> images) {
    if (images.isEmpty) return 0;

    // Default to latest (highest) cycle
    return images.map((img) => img.cycle).reduce((a, b) => a > b ? a : b);
  }

  static int getDefaultExposureTime(List<ImageMetadata> images) {
    if (images.isEmpty) return 0;

    // Default to longest (highest) exposure time
    return images.map((img) => img.exposureTime).reduce((a, b) => a > b ? a : b);
  }

  static List<int> getAvailableCycles(List<ImageMetadata> images) {
    return images.map((img) => img.cycle).toSet().toList()..sort();
  }

  static List<int> getAvailableExposureTimes(List<ImageMetadata> images) {
    return images.map((img) => img.exposureTime).toSet().toList()..sort();
  }
}
```

### Filter Implementation

```dart
class ImageOverviewProvider with ChangeNotifier {
  List<ImageMetadata> _allImages = [];
  int? _selectedCycle;
  int? _selectedExposureTime;

  void setImages(List<ImageMetadata> images) {
    _allImages = images;

    // Set defaults on first load
    if (_selectedCycle == null) {
      _selectedCycle = PamGeneFilterDefaults.getDefaultCycle(images);
    }
    if (_selectedExposureTime == null) {
      _selectedExposureTime = PamGeneFilterDefaults.getDefaultExposureTime(images);
    }

    notifyListeners();
  }

  List<ImageMetadata> get filteredImages {
    return _allImages.where((img) {
      if (_selectedCycle != null && img.cycle != _selectedCycle) {
        return false;
      }
      if (_selectedExposureTime != null && img.exposureTime != _selectedExposureTime) {
        return false;
      }
      return true;
    }).toList();
  }

  void setCycle(int cycle) {
    _selectedCycle = cycle;
    notifyListeners();
  }

  void setExposureTime(int exposureTime) {
    _selectedExposureTime = exposureTime;
    notifyListeners();
  }
}
```

## Pattern 6: Filter Requirements

### PamGene Filter Controls

The app requires two filter controls:
- **Cycle filter**: Dropdown with available pump cycle values
- **Exposure Time filter**: Dropdown with available exposure times in milliseconds

### Filter Placement

**IMPORTANT**: Filter controls must be placed according to Tercen Layout Principles:
- Filters go in the **LEFT PANEL** (not a top toolbar)
- See `_local/tercen-style/specifications/Tercen-Layout-Principles.html` for the correct app structure

### PamGene-Specific Constants

These domain-specific values should be used when implementing the grid:

| Constant | Value | Purpose |
|----------|-------|---------|
| Cell aspect ratio | 270:200 (1.35:1) | Optimized for microscopy images |
| Grid spacing | 8px | Per Tercen spacing grid |
| Border radius | 4px | Per Tercen style guide |

## Mock Data for PamGene

```dart
// lib/implementations/services/mock_image_service.dart
class MockImageService implements ImageService {
  void _initializeMockData() {
    final barcodes = ['641070616', '641070617', '641070618'];
    final wells = [1, 2, 3, 4];
    final fields = [1, 2, 3];
    final cycles = [50, 75, 94];
    final exposureTimes = [250, 350, 493];

    for (final barcode in barcodes) {
      for (final well in wells) {
        for (final field in fields) {
          final cycle = cycles.last; // Latest
          final exposure = exposureTimes.last; // Longest

          final filename = '${barcode}_W${well}_F${field}_T100_P${cycle}_I${exposure}_A30.png';

          _mockImages.add(ImageMetadataImpl(
            id: filename,
            filename: filename,
            imagePath: 'assets/$filename', // Pre-converted PNG
            barcode: barcode,
            well: well,
            field: field,
            cycle: cycle,
            exposureTime: exposure,
          ));
        }
      }
    }
  }
}
```

## Complete Example

Reference implementation: `ps12_image_overview_flutter_operator`

**Review these files**:
- `lib/utils/tiff_converter.dart` - Complete TIFF conversion
- `lib/utils/pamgene_filename_parser.dart` - Filename parsing
- `lib/presentation/providers/image_overview_provider.dart` - Filtering logic
- `lib/presentation/widgets/image_grid.dart` - Grid layout
- `lib/implementations/services/tercen_image_service.dart` - Full integration

## Checklist

PamGene-specific implementation:

- [ ] Auto-fetch ps12 example project for reference
- [ ] Implement PamGeneFilenameParser utility
- [ ] Implement TiffConverter utility (16-bit → 8-bit)
- [ ] Test TIFF conversion with sample files
- [ ] Implement grid layout with 270:200 aspect ratio
- [ ] Implement well-to-column mapping
- [ ] Set default filters (latest cycle, longest exposure)
- [ ] Implement filter UI (cycle, exposure time dropdowns)
- [ ] Create mock data with realistic PamGene filenames
- [ ] Test grid with multiple barcodes and wells
- [ ] Apply PamGene design standards (cell size, spacing)
- [ ] Verify filter behavior (latest cycle selected by default)

## Related Skills

- [Skill 0: Flutter Foundation](0-flutter-foundation.md) - Architecture
- [Skill 1: Tercen Mock Implementation](1-tercen-mock.md) - Mock-first approach
- [Skill 2: Tercen Real Implementation](2-tercen-real.md) - Tercen integration

## Related Patterns

- [Pattern: TIFF Conversion](../patterns/tiff-conversion.md) - Complete conversion utility
- [Pattern: File Streaming](../patterns/file-streaming.md) - Download TIFF files
- [Pattern: Error Handling](../patterns/error-handling.md) - Handle conversion failures

## Related Issues

- [Issue #9: UI Design Standards](../issues/9-ui-design-standards.md) - Design system
