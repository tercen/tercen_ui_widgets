import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/window_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_line_weights.dart';
import '../../domain/models/annotation_model.dart';
import '../../domain/models/content_state.dart';
import '../providers/png_viewer_provider.dart';
import '../providers/window_state_provider.dart';
import '../widgets/body_states/active_state.dart';
import '../widgets/window_shell.dart';
import '../widgets/window_toolbar.dart';

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
              // Toolbar with drawing tools and zoom controls.
              WindowToolbar(
                actions: _buildToolbarActions(provider, isActive, hasAnnotations),
                trailing: _buildTrailingZoomControls(
                    context, provider, isActive, isDark),
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

  List<ToolbarAction> _buildToolbarActions(
    PngViewerProvider provider,
    bool isActive,
    bool hasAnnotations,
  ) {
    return [
      // Drawing tool toggles.
      ToolbarAction(
        icon: FontAwesomeIcons.drawPolygon,
        tooltip: 'Polygon',
        isPrimary: provider.activeTool == DrawingTool.polygon,
        onPressed: isActive
            ? () => provider.setActiveTool(DrawingTool.polygon)
            : null,
      ),
      ToolbarAction(
        icon: FontAwesomeIcons.borderAll,
        tooltip: 'Rectangle',
        isPrimary: provider.activeTool == DrawingTool.rectangle,
        onPressed: isActive
            ? () => provider.setActiveTool(DrawingTool.rectangle)
            : null,
      ),
      ToolbarAction(
        icon: FontAwesomeIcons.circle,
        tooltip: 'Circle',
        isPrimary: provider.activeTool == DrawingTool.circle,
        onPressed: isActive
            ? () => provider.setActiveTool(DrawingTool.circle)
            : null,
      ),
      ToolbarAction(
        icon: FontAwesomeIcons.arrowRight,
        tooltip: 'Arrow',
        isPrimary: provider.activeTool == DrawingTool.arrow,
        onPressed: isActive
            ? () => provider.setActiveTool(DrawingTool.arrow)
            : null,
      ),
      ToolbarAction(
        icon: FontAwesomeIcons.penFancy,
        tooltip: 'Freehand',
        isPrimary: provider.activeTool == DrawingTool.freehand,
        onPressed: isActive
            ? () => provider.setActiveTool(DrawingTool.freehand)
            : null,
      ),
      ToolbarAction(
        icon: FontAwesomeIcons.font,
        tooltip: 'Text',
        isPrimary: provider.activeTool == DrawingTool.text,
        onPressed: isActive
            ? () => provider.setActiveTool(DrawingTool.text)
            : null,
      ),
      // Clear All.
      ToolbarAction(
        icon: FontAwesomeIcons.trashCan,
        tooltip: 'Clear All',
        onPressed: isActive && hasAnnotations
            ? () => provider.clearAllAnnotations()
            : null,
      ),
      // Send to Chat.
      ToolbarAction(
        icon: FontAwesomeIcons.paperPlane,
        tooltip: 'Send to Chat',
        onPressed: isActive && hasAnnotations
            ? () => provider.sendToChat()
            : null,
      ),
    ];
  }

  Widget _buildTrailingZoomControls(
    BuildContext context,
    PngViewerProvider provider,
    bool isActive,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ZoomButton(
          icon: FontAwesomeIcons.magnifyingGlassPlus,
          tooltip: 'Zoom In',
          onPressed: isActive ? () => provider.zoomIn() : null,
          isDark: isDark,
        ),
        const SizedBox(width: WindowConstants.toolbarGap),
        _ZoomButton(
          icon: FontAwesomeIcons.magnifyingGlassMinus,
          tooltip: 'Zoom Out',
          onPressed: isActive ? () => provider.zoomOut() : null,
          isDark: isDark,
        ),
        const SizedBox(width: WindowConstants.toolbarGap),
        _ZoomButton(
          icon: FontAwesomeIcons.expand,
          tooltip: 'Fit to Window',
          onPressed: isActive
              ? () {
                  provider.setZoomLevel(1.0);
                  provider.setPanOffset(Offset.zero);
                }
              : null,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Icon button for the trailing zoom controls area.
class _ZoomButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDark;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.isDark,
  });

  @override
  State<_ZoomButton> createState() => _ZoomButtonState();
}

class _ZoomButtonState extends State<_ZoomButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final isDark = widget.isDark;

    final Color iconColor;
    final Color bgColor;

    if (disabled) {
      iconColor = isDark ? AppColorsDark.neutral600 : AppColors.neutral400;
      bgColor = Colors.transparent;
    } else if (_hovered) {
      iconColor = isDark ? AppColorsDark.primary : AppColors.primary;
      bgColor = isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;
    } else {
      iconColor = isDark ? AppColorsDark.primary : AppColors.primary;
      bgColor = Colors.transparent;
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
              border: Border.all(
                color: disabled
                    ? (isDark
                        ? AppColorsDark.neutral600
                        : AppColors.neutral300)
                    : iconColor,
                width: AppLineWeights.lineStandard,
              ),
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
