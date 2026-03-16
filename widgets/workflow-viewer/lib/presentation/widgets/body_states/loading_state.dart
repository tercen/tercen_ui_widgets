import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';

/// Loading body state: skeleton shimmer that mimics a flowchart layout
/// (header circle + connected node rectangles) while the workflow loads.
class LoadingState extends StatefulWidget {
  final String message;

  const LoadingState({super.key, this.message = 'Loading workflow...'});

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColorsDark.neutral700 : AppColors.neutral200;
    final highlightColor =
        isDark ? AppColorsDark.neutral600 : AppColors.neutral100;
    final lineColor = isDark ? AppColorsDark.neutral700 : AppColors.neutral200;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = _shimmerController.value;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header: circle badge (workflow root)
              _ShimmerCircle(
                diameter: 48,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: progress,
              ),
              _ConnectorLine(height: 12, color: lineColor),

              // Row 1: single spine node
              _ShimmerRect(
                width: 120,
                height: 36,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: progress,
              ),
              _ConnectorLine(height: 12, color: lineColor),

              // Row 2: single spine node
              _ShimmerRect(
                width: 140,
                height: 36,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: progress,
              ),
              _ConnectorLine(height: 12, color: lineColor),

              // Row 3: fan-out — 3 nodes side by side with connector fork
              _FanOutRow(
                widths: const [80, 100, 80],
                baseColor: baseColor,
                highlightColor: highlightColor,
                lineColor: lineColor,
                progress: progress,
              ),

              const SizedBox(height: 12),

              // Row 4: two more nodes below the fan
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ShimmerRect(
                    width: 60,
                    height: 28,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    progress: progress,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 48),
                  _ShimmerRect(
                    width: 90,
                    height: 36,
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    progress: progress,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vertical connector line between skeleton nodes.
class _ConnectorLine extends StatelessWidget {
  final double height;
  final Color color;

  const _ConnectorLine({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, height: height, color: color);
  }
}

/// Shimmer circle (mimics circleBadge workflow header).
class _ShimmerCircle extends StatelessWidget {
  final double diameter;
  final Color baseColor;
  final Color highlightColor;
  final double progress;

  const _ShimmerCircle({
    required this.diameter,
    required this.baseColor,
    required this.highlightColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _shimmerGradient(baseColor, highlightColor, progress),
      ),
    );
  }
}

/// Shimmer rounded rectangle (mimics step nodes).
class _ShimmerRect extends StatelessWidget {
  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final double progress;
  final double borderRadius;

  const _ShimmerRect({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    required this.progress,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: _shimmerGradient(baseColor, highlightColor, progress),
      ),
    );
  }
}

/// Fan-out row: one connector splits into multiple branches.
class _FanOutRow extends StatelessWidget {
  final List<double> widths;
  final Color baseColor;
  final Color highlightColor;
  final Color lineColor;
  final double progress;

  const _FanOutRow({
    required this.widths,
    required this.baseColor,
    required this.highlightColor,
    required this.lineColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FanOutPainter(
        count: widths.length,
        lineColor: lineColor,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < widths.length; i++) ...[
              if (i > 0) const SizedBox(width: 24),
              _ShimmerRect(
                width: widths[i],
                height: 36,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: progress,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Paints the fan-out connector lines above the row of nodes.
class _FanOutPainter extends CustomPainter {
  final int count;
  final Color lineColor;

  _FanOutPainter({required this.count, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    const topY = 0.0;
    const forkY = 8.0;

    // Vertical stub from top center
    canvas.drawLine(Offset(centerX, topY), Offset(centerX, forkY), paint);

    // Horizontal bar across all children
    final spacing = (size.width - 24) / max(count - 1, 1);
    final leftX = 12.0;
    final rightX = size.width - 12.0;
    canvas.drawLine(Offset(leftX, forkY), Offset(rightX, forkY), paint);

    // Vertical stubs down to each child
    for (int i = 0; i < count; i++) {
      final childX = leftX + i * spacing;
      canvas.drawLine(Offset(childX, forkY), Offset(childX, 16), paint);
    }
  }

  @override
  bool shouldRepaint(_FanOutPainter oldDelegate) => false;
}

/// Shared shimmer gradient.
LinearGradient _shimmerGradient(
    Color baseColor, Color highlightColor, double progress) {
  return LinearGradient(
    begin: Alignment(-1.0 + 2.0 * progress, 0),
    end: Alignment(-1.0 + 2.0 * progress + 0.6, 0),
    colors: [baseColor, highlightColor, baseColor],
    stops: const [0.0, 0.5, 1.0],
  );
}
