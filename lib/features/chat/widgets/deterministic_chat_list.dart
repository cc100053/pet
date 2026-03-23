import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:intl/intl.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import 'chat_keyboard_dismiss_shell.dart';

typedef DeterministicChatListItemLongPressCallback =
    void Function(fc.Message message, LongPressStartDetails details);

bool shouldShowChatScrollToLatestButton({
  required double pixels,
  required double maxScrollExtent,
  double threshold = 300,
}) {
  // In a reversed list, 0 is the newest (bottom).
  // If we've scrolled away from 0 by more than the threshold, show the button.
  return pixels > threshold;
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
    this.observerController,
    this.onMessageLongPress,
    this.onBackgroundTap,
  });

  final fc.ChatItem itemBuilder;
  final List<fc.Message> messages;
  final ScrollController scrollController;
  final double topPadding;
  final double bottomPadding;
  final ListObserverController? observerController;
  final DeterministicChatListItemLongPressCallback? onMessageLongPress;
  final VoidCallback? onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    // RangeMaintainingScrollPhysics can sometimes overcompensate and cause jumps 
    // in a reverse: true list when elements are added to the maxScrollExtent.
    // Using the default physics allows the native bottom-anchoring to work smoothly.
    final physics = ScrollConfiguration.of(context).getScrollPhysics(context);

    // Group messages with date separators
    final List<Widget> items = [];
    for (var index = 0; index < messages.length; index += 1) {
      final message = messages[index];
      
      items.add(
        _DeterministicChatListItem(
          key: ValueKey('chatItem_${message.id}'),
          message: message,
          onLongPress: onMessageLongPress,
          child: itemBuilder(
            context,
            message,
            index,
            const AlwaysStoppedAnimation<double>(1),
          ),
        ),
      );

      if (_shouldShowDateSeparatorAfter(index)) {
        final time = _separatorTimeFor(message);
        if (time != null) {
          items.add(
            _DateSeparator(
              key: ValueKey('dateSeparator_${time.toIso8601String()}'),
              date: time,
            ),
          );
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListViewObserver(
          controller: observerController,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBackgroundTap,
            child: ListView.builder(
              controller: scrollController,
              physics: physics,
              reverse: true, // Key to anchoring at the bottom
              cacheExtent: 2500, // Pre-render items to prevent jitter on load-more
              padding: EdgeInsets.fromLTRB(0, topPadding, 0, bottomPadding),
              keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
              itemCount: items.length,
              itemBuilder: (context, index) => items[index],
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowDateSeparatorAfter(int index) {
    final currentTime = _separatorTimeFor(messages[index]);
    if (currentTime == null) {
      return false;
    }
    // In a reversed list, "after" an item actually means "above" it in time.
    // If it's the last item in the list (index == messages.length - 1), 
    // it's the oldest message, so it definitely needs a separator.
    if (index == messages.length - 1) {
      return true;
    }
    final nextTime = _separatorTimeFor(messages[index + 1]);
    if (nextTime == null) {
      return true;
    }
    return !isSameLocalChatDay(nextTime, currentTime);
  }

  DateTime? _separatorTimeFor(fc.Message message) {
    return message.resolvedTime ?? message.createdAt;
  }
}

class _DeterministicChatListItem extends StatelessWidget {
  const _DeterministicChatListItem({
    super.key,
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
  const _DateSeparator({super.key, required this.date});

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
