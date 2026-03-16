import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/document_provider.dart';

/// Rendered mode: live-edit WYSIWYG experience.
///
/// For the Phase 2 mock, this shows a split view: an editable text area
/// (the same TextField as source mode) and a live-rendered markdown preview.
/// The user edits in the text area and sees the formatted result update
/// in real time below. Toolbar formatting actions insert markdown syntax
/// into the text area.
///
/// For .txt files, displays plain editable text with no markdown formatting.
class RenderedEditor extends StatelessWidget {
  const RenderedEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doc = provider.document;

    if (doc == null) return const SizedBox.shrink();

    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;

    // Plain text files: editable text, no markdown rendering.
    if (doc.isPlainText) {
      return _PlainTextEditor(provider: provider);
    }

    // Markdown files: editable text area + live rendered preview.
    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Editable text area (compact, resizable via drag).
          Container(
            constraints: const BoxConstraints(
              minHeight: 80,
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TextField(
              controller: provider.textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: isDark
                    ? AppColorsDark.textSecondary
                    : AppColors.textSecondary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.sm),
                fillColor: isDark
                    ? AppColorsDark.surfaceElevated
                    : AppColors.panelBackground,
                filled: true,
                hintText: 'Edit markdown source here...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColorsDark.textMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
          // Live rendered preview.
          Expanded(
            child: Markdown(
              data: provider.content,
              selectable: true,
              softLineBreak: true,
              padding: const EdgeInsets.all(AppSpacing.md),
              onTapLink: (text, href, title) {
                if (href != null) _launchUrl(href);
              },
              styleSheet: _buildStyleSheet(context, isDark),
              // ignore: deprecated_member_use
              imageBuilder: (uri, title, alt) {
                return _MarkdownImage(uri: uri, alt: alt);
              },
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDark) {
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final codeBlockBg = isDark
        ? AppColorsDark.surfaceElevated
        : AppColors.panelBackground;
    final codeBg = isDark
        ? AppColorsDark.surfaceElevated
        : const Color(0xFFF1F5F9);
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final linkColor = isDark ? AppColorsDark.link : AppColors.link;
    final blockquoteBorder =
        isDark ? AppColorsDark.primary : AppColors.primary;

    return MarkdownStyleSheet(
      h1: AppTextStyles.h1.copyWith(color: textColor),
      h2: AppTextStyles.h2.copyWith(color: textColor),
      h3: AppTextStyles.h3.copyWith(color: textColor),
      p: AppTextStyles.body.copyWith(color: textColor),
      a: AppTextStyles.body.copyWith(color: linkColor),
      strong: AppTextStyles.body
          .copyWith(color: textColor, fontWeight: FontWeight.w700),
      em: AppTextStyles.body
          .copyWith(color: textColor, fontStyle: FontStyle.italic),
      del: AppTextStyles.body.copyWith(
        color: secondaryColor,
        decoration: TextDecoration.lineThrough,
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: textColor,
        backgroundColor: codeBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBlockBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: borderColor),
      ),
      codeblockPadding: const EdgeInsets.all(AppSpacing.md),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: blockquoteBorder,
            width: 3.0,
          ),
        ),
      ),
      blockquotePadding:
          const EdgeInsets.only(left: AppSpacing.md, top: 4, bottom: 4),
      tableBorder: TableBorder.all(color: borderColor, width: 1.0),
      tableHead: AppTextStyles.label.copyWith(color: textColor),
      tableBody: AppTextStyles.body.copyWith(color: textColor),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      listBullet: AppTextStyles.body.copyWith(color: textColor),
    );
  }

  void _launchUrl(String href) {
    try {
      web.window.open(href, '_blank');
    } catch (_) {}
  }
}

/// Plain text editable display for .txt files.
class _PlainTextEditor extends StatelessWidget {
  final DocumentProvider provider;

  const _PlainTextEditor({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;

    return Container(
      color: bgColor,
      child: TextField(
        controller: provider.textController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: AppTextStyles.body.copyWith(color: textColor, height: 1.6),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          fillColor: bgColor,
          filled: true,
        ),
      ),
    );
  }
}

/// Image widget for markdown images.
class _MarkdownImage extends StatelessWidget {
  final Uri uri;
  final String? alt;

  const _MarkdownImage({required this.uri, this.alt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final textColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Image.network(
          uri.toString(),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 20, color: textColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      alt ?? uri.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
