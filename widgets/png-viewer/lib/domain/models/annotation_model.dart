/// The six annotation drawing tools.
enum DrawingTool { polygon, rectangle, circle, arrow, freehand, text }

/// A point in image-pixel space.
class ImagePoint {
  final double x;
  final double y;

  const ImagePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// A single annotation drawn on the image.
class AnnotationModel {
  /// Annotation type.
  final DrawingTool type;

  /// Vertex coordinates in image-pixel space.
  final List<ImagePoint> points;

  /// Circle radius in image pixels (null for non-circle types).
  final double? radius;

  /// User-entered text string (null for non-text types).
  final String? label;

  const AnnotationModel({
    required this.type,
    required this.points,
    this.radius,
    this.label,
  });

  /// Convert to JSON-serializable map.
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'points': points.map((p) => p.toJson()).toList(),
        if (radius != null) 'radius': radius,
        if (label != null) 'label': label,
      };
}
