import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_dark.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/models/chat_message.dart';
import '../providers/chat_provider.dart';
import 'chat_message_bubble.dart';

/// Vertically scrollable message list with auto-scroll behaviour.
///
/// Auto-scrolls to bottom when new messages arrive, unless the user
/// has manually scrolled up to review earlier messages.
class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _userScrolledUp = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Consider "at bottom" if within 50px of the end
    _userScrolledUp = (maxScroll - currentScroll) > 50;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.messages;
    final isSending = provider.isSending;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      if (!_userScrolledUp) {
        _scrollToBottom();
      }
    }

    // Also scroll when sending indicator appears/disappears
    if (isSending && !_userScrolledUp) {
      _scrollToBottom();
    }

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        // Sending indicator at the end
        if (index == messages.length && isSending) {
          return _SendingIndicator(isDark: isDark);
        }

        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ChatMessageBubble(message: message),
        );
      },
    );
  }
}

/// Animated dots indicator shown while waiting for assistant response.
class _SendingIndicator extends StatefulWidget {
  final bool isDark;

  const _SendingIndicator({required this.isDark});

  @override
  State<_SendingIndicator> createState() => _SendingIndicatorState();
}

class _SendingIndicatorState extends State<_SendingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? AppColorsDark.panelBackground
        : AppColors.panelBackground;
    final dotColor = widget.isDark
        ? AppColorsDark.textMuted
        : AppColors.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.sm,
          right: 80,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                // Stagger each dot by 0.2
                final delay = i * 0.2;
                final t = (_controller.value + delay) % 1.0;
                final opacity = (1.0 - (t - 0.5).abs() * 2.0).clamp(0.3, 1.0);
                return Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4.0 : 0),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
