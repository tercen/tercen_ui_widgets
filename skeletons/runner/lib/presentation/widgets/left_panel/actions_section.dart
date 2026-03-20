import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

/// ACTIONS section — Run/Stop/Reset buttons with state-driven enabled/disabled.
///
/// Replace or extend with your app's specific action buttons.
/// Keep the state-driven pattern: buttons read from AppStateProvider.
class ActionsSection extends StatelessWidget {
  const ActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final canRun = !provider.isRunning && provider.isInputComplete;
    final canStop = provider.isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.controlHeight,
          child: ElevatedButton.icon(
            onPressed: canRun ? () => provider.startRun() : null,
            icon: const FaIcon(FontAwesomeIcons.play, size: 14),
            label: const Text('Run'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.controlHeight,
          child: OutlinedButton.icon(
            onPressed: canStop ? () => provider.stopRun() : null,
            icon: const FaIcon(FontAwesomeIcons.stop, size: 14),
            label: const Text('Stop'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.controlHeight,
          child: TextButton.icon(
            onPressed: provider.isRunning
                ? null
                : () => provider.resetApp(),
            icon: FaIcon(
              FontAwesomeIcons.arrowsRotate,
              size: 14,
              color: provider.isRunning
                  ? null
                  : (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary),
            ),
            label: Text(
              'Reset',
              style: TextStyle(
                color: provider.isRunning
                    ? null
                    : (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
