import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/chat_session.dart';
import '../providers/chat_provider.dart';

/// History popover button that shows a dropdown of past chat sessions.
///
/// Sessions are listed in reverse chronological order.
/// The active session is highlighted.
class HistoryPopoverButton extends StatelessWidget {
  const HistoryPopoverButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ChatProvider>();
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    return PopupMenuButton<String>(
        tooltip: 'Chat History',
        offset: const Offset(0, 40),
        constraints: const BoxConstraints(
          minWidth: 240,
          maxWidth: 320,
          maxHeight: 400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        color: isDark ? AppColorsDark.surface : AppColors.surface,
        itemBuilder: (context) {
          final sessions = provider.sessions;
          final currentId = provider.currentSession?.id;

          if (sessions.isEmpty) {
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'No chat history',
                  style: AppTextStyles.body.copyWith(
                    color: isDark
                        ? AppColorsDark.textMuted
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ];
          }

          // Sort by most recent first
          final sorted = List<ChatSession>.from(sessions)
            ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

          return sorted.map((session) {
            final isActive = session.id == currentId;
            return PopupMenuItem<String>(
              value: session.id,
              child: _SessionEntry(
                session: session,
                isActive: isActive,
                isDark: isDark,
              ),
            );
          }).toList();
        },
        onSelected: (sessionId) {
          provider.switchSession(sessionId);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 16,
              color: primaryColor,
            ),
          ),
        ),
    );
  }
}


class _SessionEntry extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final bool isDark;

  const _SessionEntry({
    required this.session,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final activeBg =
        isDark ? AppColorsDark.primaryBg : AppColors.primaryBg;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.xs,
      ),
      decoration: isActive
          ? BoxDecoration(
              color: activeBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            session.title,
            style: AppTextStyles.body.copyWith(
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _relativeTime(session.lastMessageAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: mutedColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
