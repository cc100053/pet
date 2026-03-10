import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;

import 'chat_keyboard_dismiss_shell.dart';

typedef DeterministicChatListItemLongPressCallback =
    void Function(fc.Message message, LongPressStartDetails details);

bool shouldShowChatScrollToLatestButton({
  required double pixels,
  required double maxScrollExtent,
  double threshold = 300,
}) {
  return (maxScrollExtent - pixels) > threshold;
}

class DeterministicChatList extends StatelessWidget {
  const DeterministicChatList({
    super.key,
    required this.itemBuilder,
    required this.messages,
    required this.scrollController,
    required this.topPadding,
    required this.bottomPadding,
    required this.loadingMore,
    this.onMessageLongPress,
  });

  final fc.ChatItem itemBuilder;
  final List<fc.Message> messages;
  final ScrollController scrollController;
  final double topPadding;
  final double bottomPadding;
  final bool loadingMore;
  final DeterministicChatListItemLongPressCallback? onMessageLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loadingMore)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            for (var index = 0; index < messages.length; index += 1)
              _DeterministicChatListItem(
                message: messages[index],
                onLongPress: onMessageLongPress,
                child: itemBuilder(
                  context,
                  messages[index],
                  index,
                  const AlwaysStoppedAnimation<double>(1),
                ),
              ),
          ],
        );

        return SingleChildScrollView(
          controller: scrollController,
          keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - topPadding - bottomPadding)
                  .clamp(0, double.infinity),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, topPadding, 0, bottomPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [content],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeterministicChatListItem extends StatelessWidget {
  const _DeterministicChatListItem({
    required this.message,
    required this.child,
    this.onLongPress,
  });

  final fc.Message message;
  final Widget child;
  final DeterministicChatListItemLongPressCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (onLongPress == null) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onLongPressStart: (details) => onLongPress!(message, details),
      child: child,
    );
  }
}
