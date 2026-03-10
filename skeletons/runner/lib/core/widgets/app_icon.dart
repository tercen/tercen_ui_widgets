import 'package:flutter/material.dart';

/// Tercen App icon — 4×4 pixel-art grid. Hardcoded and non-configurable.
///
/// DO NOT MODIFY this widget. It is the standard Tercen app icon
/// and must appear before the app name in the left panel header.
class AppIcon extends StatelessWidget {
  final double size;

  const AppIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppIconPainter()),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  static const _colors = [
    // Row 0
    Color(0xFFFF0000), Color(0xFFFF8200), Color(0xFF99FF00), Color(0xFFFFBF00),
    // Row 1
    Color(0xFF9333EA), Color(0xFF0099FF), Color(0xFF6D0000), Color(0xFF66FF7F),
    // Row 2
    Color(0xFFE040FB), Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFF0D9488),
    // Row 3
    Color(0xFFFF4F00), Color(0xFFEC4899), Color(0xFFFFF8DC), Color(0xFFFFDD00),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / 4;
    final cellH = size.height / 4;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 16; i++) {
      final row = i ~/ 4;
      final col = i % 4;
      paint.color = _colors[i];
      canvas.drawRect(
        Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
