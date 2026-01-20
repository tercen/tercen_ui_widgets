# TIFF Conversion Pattern

**Context**: Convert 16-bit grayscale TIFF images to 8-bit PNG for web display

**Related Skills**: [Skill 3: Customer PamGene](../skills/3-customer-pamgene.md)

## Problem

PamGene microscopy images are stored as:
- 16-bit grayscale TIFF format
- 12-bit data stored in 16-bit container
- EXIF metadata embedded
- Too large for efficient web display

Web browsers need:
- 8-bit PNG format
- Smaller file sizes
- Fast rendering

## Solution

Custom TIFF decoder that converts 16-bit to 8-bit PNG.

## Pattern Implementation

### TIFF Converter Utility

```dart
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

    // Read TIFF header
    final byteOrder = _readByteOrder(byteData);
    if (byteOrder == null) return null;

    // Read magic number (42)
    final magic = byteOrder == Endian.little
        ? byteData.getUint16(2, Endian.little)
        : byteData.getUint16(2, Endian.big);

    if (magic != 42) return null;

    // Read IFD offset
    final ifdOffset = byteOrder == Endian.little
        ? byteData.getUint32(4, Endian.little)
        : byteData.getUint32(4, Endian.big);

    // Parse IFD entries
    final ifd = _parseIFD(byteData, ifdOffset, byteOrder);
    if (ifd == null) return null;

    // Get image dimensions
    final width = ifd['ImageWidth'] as int?;
    final height = ifd['ImageLength'] as int?;
    final bitsPerSample = ifd['BitsPerSample'] as int? ?? 16;

    if (width == null || height == null) return null;

    // Get strip offsets and byte counts
    final stripOffsets = ifd['StripOffsets'] as List<int>?;
    final stripByteCounts = ifd['StripByteCounts'] as List<int>?;

    if (stripOffsets == null || stripByteCounts == null) return null;

    // Read image data
    final imageData = _readStrips(
      byteData,
      stripOffsets,
      stripByteCounts,
      byteOrder,
    );

    // Convert to 8-bit image
    return _convertTo8Bit(imageData, width, height, bitsPerSample);
  }

  static Endian? _readByteOrder(ByteData byteData) {
    final byte0 = byteData.getUint8(0);
    final byte1 = byteData.getUint8(1);

    if (byte0 == 0x49 && byte1 == 0x49) {
      return Endian.little; // II (Intel)
    } else if (byte0 == 0x4D && byte1 == 0x4D) {
      return Endian.big; // MM (Motorola)
    }

    return null;
  }

  static Map<String, dynamic>? _parseIFD(
    ByteData byteData,
    int offset,
    Endian byteOrder,
  ) {
    final ifd = <String, dynamic>{};

    // Read number of directory entries
    final numEntries = byteData.getUint16(offset, byteOrder);

    int currentOffset = offset + 2;

    for (int i = 0; i < numEntries; i++) {
      final tag = byteData.getUint16(currentOffset, byteOrder);
      final type = byteData.getUint16(currentOffset + 2, byteOrder);
      final count = byteData.getUint32(currentOffset + 4, byteOrder);
      final valueOffset = byteData.getUint32(currentOffset + 8, byteOrder);

      // Map tag to field name
      final fieldName = _getTagName(tag);

      // Read value based on type
      final value = _readIFDValue(byteData, type, count, valueOffset, byteOrder);

      if (fieldName != null) {
        ifd[fieldName] = value;
      }

      currentOffset += 12;
    }

    return ifd;
  }

  static String? _getTagName(int tag) {
    const tagMap = {
      256: 'ImageWidth',
      257: 'ImageLength',
      258: 'BitsPerSample',
      259: 'Compression',
      262: 'PhotometricInterpretation',
      273: 'StripOffsets',
      277: 'SamplesPerPixel',
      278: 'RowsPerStrip',
      279: 'StripByteCounts',
      282: 'XResolution',
      283: 'YResolution',
      296: 'ResolutionUnit',
    };

    return tagMap[tag];
  }

  static dynamic _readIFDValue(
    ByteData byteData,
    int type,
    int count,
    int valueOffset,
    Endian byteOrder,
  ) {
    // Type 3: SHORT (16-bit unsigned)
    if (type == 3) {
      if (count == 1) {
        // Value is in offset field (lower 16 bits)
        return valueOffset & 0xFFFF;
      } else {
        // Multiple values at offset
        final values = <int>[];
        for (int i = 0; i < count; i++) {
          values.add(byteData.getUint16(valueOffset + (i * 2), byteOrder));
        }
        return values;
      }
    }
    // Type 4: LONG (32-bit unsigned)
    else if (type == 4) {
      if (count == 1) {
        return valueOffset;
      } else {
        final values = <int>[];
        for (int i = 0; i < count; i++) {
          values.add(byteData.getUint32(valueOffset + (i * 4), byteOrder));
        }
        return values;
      }
    }

    return null;
  }

  static Uint16List _readStrips(
    ByteData byteData,
    List<int> stripOffsets,
    List<int> stripByteCounts,
    Endian byteOrder,
  ) {
    final totalBytes = stripByteCounts.reduce((a, b) => a + b);
    final pixelCount = totalBytes ~/ 2; // 16-bit = 2 bytes per pixel

    final imageData = Uint16List(pixelCount);
    int pixelIndex = 0;

    for (int i = 0; i < stripOffsets.length; i++) {
      final offset = stripOffsets[i];
      final byteCount = stripByteCounts[i];
      final pixelsInStrip = byteCount ~/ 2;

      for (int j = 0; j < pixelsInStrip; j++) {
        imageData[pixelIndex++] = byteData.getUint16(
          offset + (j * 2),
          byteOrder,
        );
      }
    }

    return imageData;
  }

  static img.Image _convertTo8Bit(
    Uint16List data16,
    int width,
    int height,
    int bitsPerSample,
  ) {
    final image = img.Image(width: width, height: height);

    // PamGene uses 12-bit data in 16-bit container
    // Convert to 8-bit by right-shifting 4 bits (divide by 16)
    // Or multiply by 16 to scale 12-bit to 8-bit range

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final value16 = data16[index];

        // Convert 12-bit (0-4095) to 8-bit (0-255)
        // Right-shift by 4: value16 >> 4
        // Or divide by 16: value16 ~/ 16
        final value8 = (value16 >> 4).clamp(0, 255);

        // Set pixel (grayscale)
        image.setPixelRgba(x, y, value8, value8, value8, 255);
      }
    }

    return image;
  }
}
```

## Usage in Service

```dart
class TercenImageService implements ImageService {
  @override
  Future<ImageMetadata> loadImage(String fileId) async {
    // Download TIFF file
    final tiffBytes = await _downloadFile(fileId);

    // Convert to PNG
    final pngBytes = TiffConverter.convertToPng(tiffBytes);

    if (pngBytes == null) {
      throw Exception('Failed to convert TIFF to PNG');
    }

    return ImageMetadataImpl(
      id: fileId,
      bytes: pngBytes,
      format: ImageFormat.png,
    );
  }
}
```

## Mock Implementation

For development, pre-convert TIFF files to PNG:

```dart
class MockImageService implements ImageService {
  @override
  Future<ImageMetadata> loadImage(String fileId) async {
    // Load pre-converted PNG from assets
    final bytes = await rootBundle.load('assets/$fileId.png');

    return ImageMetadataImpl(
      id: fileId,
      bytes: bytes.buffer.asUint8List(),
      format: ImageFormat.png,
    );
  }
}
```

## Bit Depth Conversion

### Understanding 12-bit in 16-bit Container

PamGene TIFFs:
- Store 12-bit intensity data (range 0-4095)
- Use 16-bit container (range 0-65535)
- Actual values use lower 12 bits

### Conversion Strategies

```dart
// Strategy 1: Right-shift (divide by 16)
final value8 = value16 >> 4; // 12-bit to 8-bit

// Strategy 2: Scale proportionally
final value8 = (value16 * 255) ~/ 4095; // Preserves full dynamic range

// Strategy 3: Direct divide (simpler)
final value8 = value16 ~/ 16; // Same as right-shift
```

For PamGene images, right-shift by 4 works well:
```dart
final value8 = (value16 >> 4).clamp(0, 255);
```

## EXIF Metadata Extraction

```dart
static Map<String, dynamic> extractExifMetadata(Uint8List tiffBytes) {
  final metadata = <String, dynamic>{};

  // Parse TIFF and read EXIF tags
  // Tag 270: ImageDescription
  // Tag 306: DateTime
  // Tag 42036: PamGene custom tags

  return metadata;
}
```

## Performance Considerations

### Caching Converted Images

```dart
class TiffConverter {
  static final _cache = <String, Uint8List>{};

  static Uint8List? convertToPng(Uint8List tiffBytes, {String? cacheKey}) {
    if (cacheKey != null && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final pngBytes = _convertToPngInternal(tiffBytes);

    if (pngBytes != null && cacheKey != null) {
      _cache[cacheKey] = pngBytes;
    }

    return pngBytes;
  }
}
```

### Async Conversion

For better UI responsiveness:

```dart
Future<Uint8List?> convertToPngAsync(Uint8List tiffBytes) async {
  return await compute(_convertInIsolate, tiffBytes);
}

Uint8List? _convertInIsolate(Uint8List tiffBytes) {
  return TiffConverter.convertToPng(tiffBytes);
}
```

## Testing

```dart
void main() {
  test('Converts 16-bit TIFF to PNG', () {
    final tiffBytes = File('test_data/sample.tif').readAsBytesSync();
    final pngBytes = TiffConverter.convertToPng(tiffBytes);

    expect(pngBytes, isNotNull);
    expect(pngBytes!.length, greaterThan(0));

    // Verify PNG header
    expect(pngBytes[0], 0x89);
    expect(pngBytes[1], 0x50); // 'P'
    expect(pngBytes[2], 0x4E); // 'N'
    expect(pngBytes[3], 0x47); // 'G'
  });

  test('Handles invalid TIFF', () {
    final invalidBytes = Uint8List.fromList([0, 1, 2, 3]);
    final result = TiffConverter.convertToPng(invalidBytes);

    expect(result, isNull);
  });
}
```

## Common Issues

### Wrong Byte Order

```dart
// CRITICAL: Respect TIFF byte order (Endian)
final byteOrder = _readByteOrder(byteData);

// Always use detected byte order when reading
final width = byteData.getUint16(offset, byteOrder); // ✓ Correct
final width = byteData.getUint16(offset, Endian.little); // ✗ Wrong
```

### Bit Shift Direction

```dart
// 12-bit to 8-bit: RIGHT-shift (divide)
final value8 = value16 >> 4; // ✓ Correct

// 8-bit to 12-bit: LEFT-shift (multiply)
final value12 = value8 << 4; // ✓ Correct

// Wrong direction
final value8 = value16 << 4; // ✗ Wrong (makes values bigger!)
```

## See Also

- [Skill 3: Customer PamGene](../skills/3-customer-pamgene.md)
- [Pattern: File Streaming](file-streaming.md)
- [Issue #9: UI Design Standards](../issues/9-ui-design-standards.md)
