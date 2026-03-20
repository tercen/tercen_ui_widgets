import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/left_panel/left_panel.dart';
import '../widgets/left_panel/actions_section.dart';
import '../widgets/left_panel/status_section.dart';
import '../widgets/left_panel/current_run_section.dart';
import '../widgets/left_panel/history_section.dart';
import '../widgets/left_panel/info_section.dart';
import '../widgets/content_panel/content_panel.dart';

/// Home screen: assembles the Type 3 three-panel layout.
///
/// Replace appTitle and content panel widgets with your app's specific content.
/// The Status Panel sections (left) and Content Panel (right) are the two things you customize.
///
/// Exit button and theme toggle are pre-wired. Error dialogs for advanceError
/// are handled automatically via provider listener.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppStateProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AppStateProvider>();
    // Listen for advance errors and show dialog
    _provider.addListener(_onProviderChanged);
    // Load data on startup (pre-populates run history in mock)
    Future.microtask(() {
      if (!mounted) return;
      _provider.loadData();
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    final error = _provider.advanceError;
    if (error != null && mounted) {
      _provider.clearAdvanceError();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(error),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppStateProvider>();

    return AppShell(
      appTitle: 'Skeleton Type3',
      sections: const [
        // Status Panel sections — 5 sections in order
        PanelSection(
          icon: Icons.play_circle_outline,
          label: 'ACTIONS',
          content: ActionsSection(),
        ),
        PanelSection(
          icon: Icons.monitor_heart,
          label: 'STATUS',
          content: StatusSection(),
        ),
        PanelSection(
          icon: Icons.settings_applications,
          label: 'CURRENT RUN',
          content: CurrentRunSection(),
        ),
        PanelSection(
          icon: Icons.history,
          label: 'HISTORY',
          content: HistorySection(),
        ),
        PanelSection(
          icon: Icons.info_outline,
          label: 'INFO',
          content: InfoSection(),
        ),
      ],
      content: const ContentPanel(),
      // Header Panel callbacks
      onPrimaryAction: () {
        // Input mode: advance stage or start run
        provider.startRun();
      },
      onReRun: () {
        final runId = provider.selectedRunId;
        if (runId != null) {
          provider.initiateReRun(runId);
        }
      },
      onExport: () {
        // TODO: implement export for your app
      },
      onDelete: () {
        final runId = provider.selectedRunId;
        if (runId != null) {
          _confirmDelete(context, provider, runId);
        }
      },
      onExit: () => _doExit(provider),
      onToggleTheme: () {
        context.read<ThemeProvider>().toggleTheme();
      },
    );
  }

  /// Exit navigation — works for all Type 3 apps.
  /// No project created yet: go back to previous Tercen screen.
  /// Project exists: navigate to the project page.
  void _doExit(AppStateProvider provider) {
    // Apps should override this with their projectId and teamId.
    // Default: browser back.
    web.window.history.back();
  }

  void _confirmDelete(BuildContext context, AppStateProvider provider, String runId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete run?'),
        content: const Text(
          'This will permanently delete this run and its results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.deleteRun(runId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
