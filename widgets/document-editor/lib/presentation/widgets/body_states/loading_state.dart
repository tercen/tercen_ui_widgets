import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';

/// Loading body state: skeleton shimmer placeholders that mimic the document
/// layout the user will see once loading completes.
class LoadingState extends StatefulWidget {
  final String message;

  const LoadingState({super.key, this.message = 'Loading...'});

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

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title skeleton
              _SkeletonLine(
                width: 280,
                height: 24,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 20),
              // Paragraph lines
              _SkeletonLine(
                widthFraction: 1.0,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 10),
              _SkeletonLine(
                widthFraction: 0.92,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 10),
              _SkeletonLine(
                widthFraction: 0.85,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 10),
              _SkeletonLine(
                widthFraction: 0.6,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 24),
              // Sub-heading skeleton
              _SkeletonLine(
                width: 180,
                height: 18,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 16),
              // More paragraph lines
              _SkeletonLine(
                widthFraction: 1.0,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 10),
              _SkeletonLine(
                widthFraction: 0.78,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 10),
              _SkeletonLine(
                widthFraction: 0.95,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
              const SizedBox(height: 10),
              _SkeletonLine(
                widthFraction: 0.45,
                height: 14,
                baseColor: baseColor,
                highlightColor: highlightColor,
                progress: _shimmerController.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single skeleton placeholder bar with shimmer effect.
class _SkeletonLine extends StatelessWidget {
  final double? width;
  final double? widthFraction;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final double progress;

  const _SkeletonLine({
    this.width,
    this.widthFraction,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = width ?? (constraints.maxWidth * (widthFraction ?? 1.0));
        return Container(
          width: w,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * progress, 0),
              end: Alignment(-1.0 + 2.0 * progress + 0.6, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
