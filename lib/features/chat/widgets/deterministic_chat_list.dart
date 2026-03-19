import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:intl/intl.dart';
import 'package:pet/l10n/app_localizations.dart';

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

bool isSameLocalChatDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();
  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}

String formatChatDateSeparatorLabel(
  BuildContext context,
  DateTime date, {
  DateTime? now,
}) {
  final current = (now ?? DateTime.now()).toLocal();
  final localDate = date.toLocal();
  final l10n = AppLocalizations.of(context)!;

  if (isSameLocalChatDay(localDate, current)) {
    return l10n.calendarToday;
  }

  final yesterday = current.subtract(const Duration(days: 1));
  if (isSameLocalChatDay(localDate, yesterday)) {
    return l10n.calendarYesterday;
  }

  if (localDate.year == current.year) {
    return DateFormat.MMMd().format(localDate);
  }
  return DateFormat.yMMMd().format(localDate);
}

class DeterministicChatList extends StatelessWidget {
  const DeterministicChatList({
    super.key,
    required this.itemBuilder,
    required this.messages,
    required this.scrollController,
    required this.topPadding,
    required this.bottomPadding,
    this.onMessageLongPress,
  });

  final fc.ChatItem itemBuilder;
  final List<fc.Message> messages;
  final ScrollController scrollController;
  final double topPadding;
  final double bottomPadding;
  final DeterministicChatListItemLongPressCallback? onMessageLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < messages.length; index += 1) ...[
              if (_shouldShowDateSeparatorBefore(index))
                _DateSeparator(date: _separatorTimeFor(messages[index])),
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

  bool _shouldShowDateSeparatorBefore(int index) {
    final currentTime = _separatorTimeFor(messages[index]);
    if (currentTime == null) {
      return false;
    }
    if (index == 0) {
      return true;
    }
    final previousTime = _separatorTimeFor(messages[index - 1]);
    if (previousTime == null) {
      return true;
    }
    return !isSameLocalChatDay(previousTime, currentTime);
  }

  DateTime? _separatorTimeFor(fc.Message message) {
    return message.resolvedTime ?? message.createdAt;
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

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          key: ValueKey<String>(
            'chat_date_separator_${date!.toLocal().toIso8601String()}',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formatChatDateSeparatorLabel(context, date!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
