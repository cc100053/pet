import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
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

/// Whether scrolling back down to the newest end should rejoin the live latest
/// window. Once history mode trims the live tail (or new messages are buffered
/// while reading history), the bottom of the loaded window is no longer the
/// real latest, so the user otherwise has to tap the jump-to-latest button.
bool shouldRejoinLatestOnScroll({
  required double pixels,
  required double minScrollExtent,
  required bool isHistoryMode,
  required int pendingLiveMessageCount,
  double threshold = 24,
}) {
  if (!isHistoryMode && pendingLiveMessageCount <= 0) {
    return false;
  }
  // In a reversed list, minScrollExtent (~0) is the newest end (bottom).
  return pixels <= minScrollExtent + threshold;
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

DateTime? chatSeparatorTimeFor(fc.Message message) {
  return message.resolvedTime ?? message.createdAt;
}

/// Whether a date separator follows [messages]`[index]`. [messages] are in
/// descending visual order (newest -> oldest), so "after" means "older".
bool shouldShowChatDateSeparatorAfter(List<fc.Message> messages, int index) {
  final currentTime = chatSeparatorTimeFor(messages[index]);
  if (currentTime == null) {
    return false;
  }
  // In a reversed list, "after" an item actually means "above" it in time.
  // If it's the last item in the list (index == messages.length - 1),
  // it's the oldest message, so it definitely needs a separator.
  if (index == messages.length - 1) {
    return true;
  }
  final nextTime = chatSeparatorTimeFor(messages[index + 1]);
  if (nextTime == null) {
    return true;
  }
  return !isSameLocalChatDay(nextTime, currentTime);
}

/// Raw `ListView` item index of [messageId], or null when the message is not in
/// [messages]. [messages] must be the same descending list handed to
/// [DeterministicChatList], and the result accounts for the date separators
/// interleaved between bubbles. Callers that scroll by index (e.g. the
/// reply-jump) need this because the timeline holds more items than messages.
int? chatListRawIndexForMessageId(List<fc.Message> messages, String messageId) {
  var rawIndex = 0;
  for (var index = 0; index < messages.length; index += 1) {
    if (messages[index].id == messageId) {
      return rawIndex;
    }
    rawIndex += 1;
    if (shouldShowChatDateSeparatorAfter(messages, index)) {
      rawIndex += 1;
    }
  }
  return null;
}

class DeterministicChatList extends StatefulWidget {
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
  State<DeterministicChatList> createState() => _DeterministicChatListState();
}

class _DeterministicChatListState extends State<DeterministicChatList> {
  /// Day of the topmost visible item, shown Telegram-style while dragging.
  final ValueNotifier<DateTime?> _floatingDate = ValueNotifier<DateTime?>(null);
  final ValueNotifier<bool> _floatingDateVisible = ValueNotifier<bool>(false);
  Timer? _floatingDateHideTimer;

  /// Day per raw list index (messages and separators), rebuilt with the items.
  List<DateTime?> _rawItemDates = const <DateTime?>[];

  @override
  void dispose() {
    _floatingDateHideTimer?.cancel();
    _floatingDate.dispose();
    _floatingDateVisible.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    final isUserScroll =
        (notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null);
    if (isUserScroll) {
      _floatingDateHideTimer?.cancel();
      _floatingDateVisible.value = true;
    } else if (notification is ScrollEndNotification &&
        _floatingDateVisible.value) {
      _floatingDateHideTimer?.cancel();
      _floatingDateHideTimer = Timer(
        const Duration(milliseconds: 900),
        () => _floatingDateVisible.value = false,
      );
    }
    return false;
  }

  void _handleObserve(ListViewObserveModel model) {
    // Reversed list: the highest index is the oldest, i.e. the topmost item.
    // Skip items that sit entirely under the top bar (the top padding).
    var topIndex = -1;
    for (final child in model.displayingChildModelList) {
      final bottomFromTop = child.trailingMarginToViewport + child.mainAxisSize;
      if (bottomFromTop > widget.topPadding && child.index > topIndex) {
        topIndex = child.index;
      }
    }
    if (topIndex >= 0 && topIndex < _rawItemDates.length) {
      final date = _rawItemDates[topIndex];
      if (date != null &&
          (_floatingDate.value == null ||
              !isSameLocalChatDay(_floatingDate.value!, date))) {
        _floatingDate.value = date;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    final itemBuilder = widget.itemBuilder;
    final onMessageLongPress = widget.onMessageLongPress;
    // RangeMaintainingScrollPhysics can sometimes overcompensate and cause jumps
    // in a reverse: true list when elements are added to the maxScrollExtent.
    // Using the default physics allows the native bottom-anchoring to work smoothly.
    final physics = ScrollConfiguration.of(context).getScrollPhysics(context);

    // Group messages with date separators. `messages` are expected in
    // descending visual order (newest -> oldest) so the reversed ListView can
    // keep the newest content anchored at the bottom. When we forward a
    // message into flutter_chat_ui's itemBuilder, we must translate the visual
    // index back to the canonical ascending index used by ChatController.
    final List<Widget> items = [];
    final List<DateTime?> rawItemDates = [];
    for (var index = 0; index < messages.length; index += 1) {
      final message = messages[index];
      final canonicalIndex = messages.length - 1 - index;

      items.add(
        _DeterministicChatListItem(
          key: ValueKey('chatItem_${message.id}'),
          message: message,
          onLongPress: onMessageLongPress,
          child: itemBuilder(
            context,
            message,
            canonicalIndex,
            const AlwaysStoppedAnimation<double>(1),
          ),
        ),
      );
      rawItemDates.add(chatSeparatorTimeFor(message));

      if (shouldShowChatDateSeparatorAfter(messages, index)) {
        final time = chatSeparatorTimeFor(message);
        if (time != null) {
          rawItemDates.add(time);
          items.add(
            _DateSeparator(
              key: ValueKey('dateSeparator_${time.toIso8601String()}'),
              date: time,
            ),
          );
        }
      }
    }

    // NOTE: Do not wrap this in a LayoutBuilder. Its `constraints` are not
    // needed here, and a LayoutBuilder builds its child during the layout
    // phase. When the chat route is popped (returning to Home), tearing down
    // that subtree can leave an InheritedElement below the LayoutBuilder with
    // live dependents, tripping framework.dart's `_dependents.isEmpty`
    // assertion during deactivation.
    _rawItemDates = rawItemDates;
    final list = ListViewObserver(
      controller: widget.observerController,
      onObserve: _handleObserve,
      triggerOnObserveType: ObserverTriggerOnObserveType.directly,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onBackgroundTap,
          child: ListView.builder(
            key: const ValueKey('chatTimelineList'),
            controller: widget.scrollController,
            physics: physics,
            reverse: true, // Key to anchoring at the bottom
            // Keep a modest off-screen buffer to smooth load-more without
            // holding many full-size image bubbles decoded in memory at once.
            // A large extent (e.g. 2500) kept ~14 image bubbles live and
            // could trip the iOS memory limit while scrolling long history.
            scrollCacheExtent: const ScrollCacheExtent.pixels(600),
            padding: EdgeInsets.fromLTRB(
              0,
              widget.topPadding,
              0,
              widget.bottomPadding,
            ),
            keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        list,
        Positioned(
          top: widget.topPadding + 4,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ValueListenableBuilder<bool>(
              valueListenable: _floatingDateVisible,
              builder: (context, visible, child) => AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: Duration(milliseconds: visible ? 120 : 280),
                child: child,
              ),
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: _floatingDate,
                builder: (context, date, _) => Center(
                  child: date == null
                      ? const SizedBox.shrink()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: _DatePill(
                            key: ValueKey<String>(
                              'chatFloatingDate_${formatChatDateSeparatorLabel(context, date)}',
                            ),
                            date: date,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
        child: _DatePill(
          key: ValueKey<String>(
            'chat_date_separator_${date!.toLocal().toIso8601String()}',
          ),
          date: date!,
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        formatChatDateSeparatorLabel(context, date),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
