import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/chat_message.dart';

/// Renders a single chat message bubble.
///
/// User messages: right-aligned with primary tint background.
/// Assistant messages: left-aligned with panel background, markdown rendered.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == MessageRole.user;

    if (isUser) {
      return _UserBubble(message: message, isDark: isDark);
    } else {
      return _AssistantBubble(message: message, isDark: isDark);
    }
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _UserBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColorsDark.primaryBg : AppColors.primaryBg;
    final borderColor =
        isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final timeColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.0),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: AppTextStyles.body.copyWith(color: textColor),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatTime(message.timestamp),
                style: AppTextStyles.bodySmall.copyWith(
                  color: timeColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _AssistantBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDark ? AppColorsDark.panelBackground : AppColors.panelBackground;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final timeColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.0),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MarkdownContent(
                content: message.content,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: timeColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders markdown content for assistant messages.
///
/// Uses flutter_markdown with theme-aware styling for code blocks,
/// inline code, links, headings, tables, and block quotes.
class _MarkdownContent extends StatelessWidget {
  final String content;
  final bool isDark;

  const _MarkdownContent({required this.content, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final linkColor = isDark ? AppColorsDark.link : AppColors.link;
    final codeBlockBg = isDark
        ? const Color(0xFF1A1D24)
        : const Color(0xFFF1F3F5);
    final inlineCodeBg = isDark
        ? const Color(0xFF252830)
        : const Color(0xFFE8EAED);
    final tableBorderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final blockQuoteBorderColor =
        isDark ? AppColorsDark.primary : AppColors.primary;

    return MarkdownBody(
      data: content,
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        // Paragraphs
        p: AppTextStyles.body.copyWith(color: textColor),
        // Headings
        h1: AppTextStyles.h1.copyWith(color: textColor),
        h2: AppTextStyles.h2.copyWith(color: textColor),
        h3: AppTextStyles.h3.copyWith(color: textColor),
        h4: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: textColor,
        ),
        // Bold / italic
        strong: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        // Links
        a: TextStyle(color: linkColor, decoration: TextDecoration.underline),
        // Inline code
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: secondaryColor,
          backgroundColor: inlineCodeBg,
        ),
        // Fenced code blocks
        codeblockDecoration: BoxDecoration(
          color: codeBlockBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        codeblockPadding: const EdgeInsets.all(AppSpacing.sm + 2),
        codeblockAlign: WrapAlignment.start,
        // Lists
        listBullet: AppTextStyles.body.copyWith(color: textColor),
        // Block quotes
        blockquote: AppTextStyles.body.copyWith(
          color: secondaryColor,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: blockQuoteBorderColor,
              width: 3.0,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(
          left: AppSpacing.sm + 2,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        // Tables
        tableHead: AppTextStyles.label.copyWith(color: textColor),
        tableBody: AppTextStyles.body.copyWith(color: textColor),
        tableBorder: TableBorder.all(color: tableBorderColor, width: 1.0),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        // Horizontal rule
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: tableBorderColor,
              width: 1.0,
            ),
          ),
        ),
        // Spacing
        h1Padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        h2Padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        h3Padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        pPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        blockSpacing: AppSpacing.sm,
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
