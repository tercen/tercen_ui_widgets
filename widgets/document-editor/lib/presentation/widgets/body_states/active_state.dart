import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/edit_mode.dart';
import '../../providers/document_provider.dart';
import '../source_editor.dart';
import '../rendered_editor.dart';

/// Active body state: routes to source or rendered editor based on edit mode.
class ActiveState extends StatelessWidget {
  const ActiveState({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    return Column(
      children: [
        // Inline save error banner.
        if (provider.saveError != null)
          _SaveErrorBanner(message: provider.saveError!),
        Expanded(
          child: provider.editMode == EditMode.source
              ? const SourceEditor()
              : const RenderedEditor(),
        ),
      ],
    );
  }
}

/// Inline error banner for save failures.
class _SaveErrorBanner extends StatelessWidget {
  final String message;

  const _SaveErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorBg = isDark ? const Color(0xFF3B1111) : const Color(0xFFFEE2E2);
    final errorFg = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: errorBg,
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: errorFg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: errorFg),
            ),
          ),
        ],
      ),
    );
  }
}
