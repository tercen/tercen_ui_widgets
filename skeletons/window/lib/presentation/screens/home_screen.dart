import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/content_state.dart';
import '../providers/window_state_provider.dart';
import '../widgets/window_shell.dart';

/// Demo screen that wires the WindowShell with placeholder toolbar
/// actions and a state-cycle button for testing all four body states.
///
/// Replace this with your window type's screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start in empty state — press "Load" in the toolbar to trigger loading.
  }

  void _cycleState() {
    final provider = context.read<WindowStateProvider>();
    final states = ContentState.values;
    final next =
        states[(provider.contentState.index + 1) % states.length];
    if (next == ContentState.loading) {
      provider.loadData();
    } else {
      provider.setContentState(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WindowShell(
        toolbarActions: [
          ToolbarAction(
            icon: Icons.play_arrow,
            tooltip: 'Load data',
            isPrimary: true,
            onPressed: () =>
                context.read<WindowStateProvider>().loadData(),
          ),
          ToolbarAction(
            icon: Icons.stop,
            tooltip: 'Stop',
          ),
          ToolbarAction(
            icon: Icons.add,
            tooltip: 'Add item',
          ),
          ToolbarAction(
            icon: Icons.download,
            tooltip: 'Export',
            label: 'Export',
          ),
          ToolbarAction(
            icon: Icons.swap_vert,
            tooltip: 'Cycle body state',
            onPressed: _cycleState,
          ),
        ],
        emptyIcon: Icons.inbox_outlined,
        emptyMessage: 'No content loaded',
        emptyDetail: 'Press the play button in the toolbar to load data',
        emptyActionLabel: 'Load Data',
        onEmptyAction: () =>
            context.read<WindowStateProvider>().loadData(),
      ),
    );
  }
}
