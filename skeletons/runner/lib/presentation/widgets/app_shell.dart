import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'header_panel.dart';
import 'running_overlay.dart';
import 'left_panel/left_panel.dart';

/// Type 3 App frame: Row → [LeftPanel, Expanded(Column → [HeaderPanel, Content])]
///
/// The HeaderPanel and Content are wrapped in a RunningOverlay that blocks
/// interaction and dims the content when the app is in Running state.
/// The Status Panel (LeftPanel) remains fully interactive during Running.
class AppShell extends StatelessWidget {
  final String appTitle;
  final List<PanelSection> sections;
  final Widget content;

  /// Header Panel callbacks — wired from home_screen.dart
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onReRun;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  final VoidCallback? onExit;
  final VoidCallback? onToggleTheme;

  const AppShell({
    super.key,
    required this.appTitle,
    required this.sections,
    required this.content,
    this.onPrimaryAction,
    this.onReRun,
    this.onExport,
    this.onDelete,
    this.onExit,
    this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = context.watch<AppStateProvider>().isRunning;

    return Scaffold(
      body: Row(
        children: [
          // Status Panel — always visible and interactive, even during Running
          LeftPanel(
            appTitle: appTitle,
            sections: sections,
          ),
          // Right column: Header + Content, wrapped in running overlay
          Expanded(
            child: RunningOverlay(
              isRunning: isRunning,
              child: Column(
                children: [
                  HeaderPanel(
                    onPrimaryAction: onPrimaryAction,
                    onReRun: onReRun,
                    onExport: onExport,
                    onDelete: onDelete,
                    onExit: onExit,
                    onToggleTheme: onToggleTheme,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
