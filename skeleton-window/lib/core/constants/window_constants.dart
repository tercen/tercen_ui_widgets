import 'package:flutter/material.dart';
import '../theme/app_line_weights.dart';
import '../theme/app_spacing.dart';

/// Dimension and styling constants for the Feature Window.
///
/// These values match the Feature Window spec and HTML mockups.
/// All window types must use these — no hardcoded overrides.
class WindowConstants {
  WindowConstants._();

  // ── Tab dimensions (defined here for reference; rendered by Frame) ──
  static const double tabHeight = 30.0;
  static const double tabStripHeight = 34.0; // tabHeight + 4px top spacing
  static const double tabMaxWidth = 220.0;
  static const double tabCornerRadius = 6.0;
  static const double tabBorderWidth = AppLineWeights.lineEmphasis;
  static const double tabButtonSize = 20.0;
  static const double tabButtonIconSize = 11.0;
  static const double tabIconSize = 8.0;
  static const double tabIconRadius = 2.0;
  static const double tabFontSize = 11.0;

  // ── Toolbar ──
  static const double toolbarHeight = AppSpacing.headerHeight; // 48px
  static const double toolbarButtonSize = 32.0;
  static const double toolbarButtonIconSize = 14.0;
  static const double toolbarButtonRadius = AppSpacing.radiusSm;
  static const double toolbarButtonBorderWidth = AppLineWeights.lineSubtle;
  static const double toolbarGap = AppSpacing.sm;

  // ── Body ──
  static const double bodyStateIconSize = 32.0;
  static const double bodyStateMaxWidth = 280.0;
  static const double spinnerSize = 28.0;
  static const double spinnerStrokeWidth = 3.0;

  // ── Font weights for tab states ──
  static const FontWeight tabWeightFocused = FontWeight.w700;
  static const FontWeight tabWeightBlurred = FontWeight.w500;
  static const FontWeight tabWeightInactive = FontWeight.w400;
}
