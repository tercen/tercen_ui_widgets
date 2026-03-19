import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/window_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_line_weights.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/annotation_model.dart';
import '../../domain/models/content_state.dart';
import '../providers/png_viewer_provider.dart';
import '../providers/window_state_provider.dart';
import '../widgets/body_states/active_state.dart';
import '../widgets/window_shell.dart';

/// Home screen for the PNG Viewer window.
///
/// Builds a custom toolbar with drawing tools + zoom controls,
/// and uses WindowShell for body state routing (loading/empty/active/error).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WindowStateProvider>() as PngViewerProvider;
    final isActive = provider.contentState == ContentState.active;
    final hasAnnotations = provider.hasAnnotations;

    return Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: WindowConstants.minWidgetWidth,
        ),
        child: Container(
          color: isDark ? const Color(0xFF181A20) : Colors.white,
          child: Column(
            children: [
              // Custom toolbar with tool toggles, actions, and zoom controls.
              _PngViewerToolbar(
                provider: provider,
                isActive: isActive,
                hasAnnotations: hasAnnotations,
                isDark: isDark,
              ),
              Divider(
                height: AppLineWeights.lineSubtle,
                thickness: AppLineWeights.lineSubtle,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
              // WindowShell with toolbar hidden (we rendered it above).
              Expanded(
                child: WindowShell(
                  showToolbar: false,
                  activeContent: const ActiveState(),
                  emptyIcon: FontAwesomeIcons.image,
                  emptyMessage: 'No image loaded',
                  emptyDetail:
                      'Open a PNG from the File Navigator or a step output.',
                  onRetry: () => provider.retryLoad(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom toolbar that renders annotation tool toggles with primary/secondary
/// visual distinction, plus action buttons and trailing zoom controls.
class _PngViewerToolbar extends StatelessWidget {
  final PngViewerProvider provider;
  final bool isActive;
  final bool hasAnnotations;
  final bool isDark;

  const _PngViewerToolbar({
    required this.provider,
    required this.isActive,
    required this.hasAnnotations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WindowConstants.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          // 6 drawing tool toggles — primary filled when active.
          _ToolToggleButton(
            icon: FontAwesomeIcons.drawPolygon,
            tooltip: 'Polygon',
            isActive: provider.activeTool == DrawingTool.polygon,
            onPressed: isActive
                ? () => provider.setActiveTool(DrawingTool.polygon)
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.borderAll,
            tooltip: 'Rectangle',
            isActive: provider.activeTool == DrawingTool.rectangle,
            onPressed: isActive
                ? () => provider.setActiveTool(DrawingTool.rectangle)
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.circle,
            tooltip: 'Circle',
            isActive: provider.activeTool == DrawingTool.circle,
            onPressed: isActive
                ? () => provider.setActiveTool(DrawingTool.circle)
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.arrowRight,
            tooltip: 'Arrow',
            isActive: provider.activeTool == DrawingTool.arrow,
            onPressed: isActive
                ? () => provider.setActiveTool(DrawingTool.arrow)
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.penFancy,
            tooltip: 'Freehand',
            isActive: provider.activeTool == DrawingTool.freehand,
            onPressed: isActive
                ? () => provider.setActiveTool(DrawingTool.freehand)
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.font,
            tooltip: 'Text',
            isActive: provider.activeTool == DrawingTool.text,
            onPressed: isActive
                ? () => provider.setActiveTool(DrawingTool.text)
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          // Clear All — secondary style (never toggled).
          _ToolToggleButton(
            icon: FontAwesomeIcons.trashCan,
            tooltip: 'Clear All',
            isActive: false,
            onPressed: isActive && hasAnnotations
                ? () => provider.clearAllAnnotations()
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          // Send to Chat — secondary style.
          _ToolToggleButton(
            icon: FontAwesomeIcons.paperPlane,
            tooltip: 'Send to Chat',
            isActive: false,
            onPressed: isActive && hasAnnotations
                ? () => provider.sendToChat()
                : null,
            isDark: isDark,
          ),
          // Spacer pushes zoom controls to the right.
          const SizedBox(width: WindowConstants.toolbarGap),
          const Spacer(),
          // Trailing zoom controls.
          _ToolToggleButton(
            icon: FontAwesomeIcons.magnifyingGlassPlus,
            tooltip: 'Zoom In',
            isActive: false,
            onPressed: isActive ? () => provider.zoomIn() : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.magnifyingGlassMinus,
            tooltip: 'Zoom Out',
            isActive: false,
            onPressed: isActive ? () => provider.zoomOut() : null,
            isDark: isDark,
          ),
          const SizedBox(width: WindowConstants.toolbarGap),
          _ToolToggleButton(
            icon: FontAwesomeIcons.expand,
            tooltip: 'Fit to Window',
            isActive: false,
            onPressed: isActive
                ? () {
                    provider.setZoomLevel(1.0);
                    provider.setPanOffset(Offset.zero);
                  }
                : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Toolbar button that switches between primary (filled) and secondary
/// (outlined) styling based on [isActive].
class _ToolToggleButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onPressed;
  final bool isDark;

  const _ToolToggleButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    this.onPressed,
    required this.isDark,
  });

  @override
  State<_ToolToggleButton> createState() => _ToolToggleButtonState();
}

class _ToolToggleButtonState extends State<_ToolToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final isDark = widget.isDark;
    final active = widget.isActive;

    final Color iconColor;
    final Color bgColor;
    final Color? borderColor;

    if (disabled) {
      // Disabled: muted icon, muted border, transparent bg.
      iconColor = isDark ? AppColorsDark.neutral600 : AppColors.neutral400;
      bgColor = Colors.transparent;
      borderColor = isDark ? AppColorsDark.neutral600 : AppColors.neutral300;
    } else if (active) {
      // Active (ON): primary filled background, white icon, no border.
      final primary = isDark ? AppColorsDark.primary : AppColors.primary;
      bgColor = _hovered
          ? (isDark ? AppColorsDark.primaryDarker : AppColors.primaryDarker)
          : primary;
      iconColor = Colors.white;
      borderColor = null;
    } else {
      // Inactive (OFF): secondary outlined, primary icon + border.
      final primary = isDark ? AppColorsDark.primary : AppColors.primary;
      iconColor = primary;
      bgColor = _hovered
          ? (isDark ? AppColorsDark.primarySurface : AppColors.primarySurface)
          : Colors.transparent;
      borderColor = primary;
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: disabled ? null : (_) => setState(() => _hovered = true),
        onExit: disabled ? null : (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.ease,
            width: WindowConstants.toolbarButtonSize,
            height: WindowConstants.toolbarButtonSize,
            decoration: BoxDecoration(
              color: bgColor,
              border: borderColor != null
                  ? Border.all(
                      color: borderColor,
                      width: AppLineWeights.lineStandard,
                    )
                  : null,
              borderRadius:
                  BorderRadius.circular(WindowConstants.toolbarButtonRadius),
            ),
            child: Center(
              child: FaIcon(
                widget.icon,
                size: WindowConstants.toolbarButtonIconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
