import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/widgets/deterministic_chat_list.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  Widget buildList({
    required ScrollController controller,
    required List<fc.Message> messages,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 240,
          child: DeterministicChatList(
            itemBuilder:
                (
                  context,
                  renderedMessage,
                  index,
                  animation, {
                  isRemoved,
                  messageGroupingTimeoutInSeconds,
                  messagesGroupingMode,
                }) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text((renderedMessage as fc.TextMessage).text),
                  );
                },
            messages: messages,
            scrollController: controller,
            topPadding: 0,
            bottomPadding: 0,
          ),
        ),
      ),
    );
  }

  test('shows jump-to-latest only when far enough from bottom', () {
    expect(
      shouldShowChatScrollToLatestButton(pixels: 240, maxScrollExtent: 900),
      false,
    );
    expect(
      shouldShowChatScrollToLatestButton(pixels: 520, maxScrollExtent: 900),
      true,
    );
  });

  group('shouldRejoinLatestOnScroll', () {
    test('rejoins when scrolled to the newest end in history mode', () {
      expect(
        shouldRejoinLatestOnScroll(
          pixels: 0,
          minScrollExtent: 0,
          isHistoryMode: true,
          pendingLiveMessageCount: 0,
        ),
        true,
      );
    });

    test(
      'rejoins when buffered live messages exist and back at the bottom',
      () {
        expect(
          shouldRejoinLatestOnScroll(
            pixels: 10,
            minScrollExtent: 0,
            isHistoryMode: false,
            pendingLiveMessageCount: 3,
          ),
          true,
        );
      },
    );

    test('does not rejoin while still scrolled up in history', () {
      expect(
        shouldRejoinLatestOnScroll(
          pixels: 400,
          minScrollExtent: 0,
          isHistoryMode: true,
          pendingLiveMessageCount: 0,
        ),
        false,
      );
    });

    test('does not rejoin in live mode with nothing buffered', () {
      expect(
        shouldRejoinLatestOnScroll(
          pixels: 0,
          minScrollExtent: 0,
          isHistoryMode: false,
          pendingLiveMessageCount: 0,
        ),
        false,
      );
    });
  });

  testWidgets('deterministic list forwards long press for rendered messages', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    String? pressedMessageId;
    final message = fc.TextMessage(
      id: 'm1',
      authorId: 'u1',
      createdAt: DateTime(2026, 3, 10, 12),
      text: 'hello world',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: DeterministicChatList(
              itemBuilder:
                  (
                    context,
                    renderedMessage,
                    index,
                    animation, {
                    isRemoved,
                    messageGroupingTimeoutInSeconds,
                    messagesGroupingMode,
                  }) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text((renderedMessage as fc.TextMessage).text),
                    );
                  },
              messages: <fc.Message>[message],
              scrollController: controller,
              topPadding: 0,
              bottomPadding: 0,
              onMessageLongPress: (message, details) {
                pressedMessageId = message.id;
              },
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('hello world'));
    await tester.pump();

    expect(pressedMessageId, 'm1');
  });

  testWidgets('messages from one day render one separator', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final now = DateTime.now();

    await tester.pumpWidget(
      buildList(
        controller: controller,
        messages: <fc.Message>[
          fc.TextMessage(
            id: 'm1',
            authorId: 'u1',
            createdAt: DateTime(now.year, now.month, now.day, 9),
            text: 'first',
          ),
          fc.TextMessage(
            id: 'm2',
            authorId: 'u2',
            createdAt: DateTime(now.year, now.month, now.day, 14),
            text: 'second',
          ),
        ],
      ),
    );

    final label = formatChatDateSeparatorLabel(
      tester.element(find.byType(DeterministicChatList)),
      now,
    );
    expect(find.text(label), findsOneWidget);
  });

  testWidgets('crossing a day boundary renders separators in order', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final now = DateTime.now();
    final previousDay = now.subtract(const Duration(days: 2));
    final currentDay = now;

    await tester.pumpWidget(
      buildList(
        controller: controller,
        messages: <fc.Message>[
          fc.TextMessage(
            id: 'm1',
            authorId: 'u1',
            createdAt: previousDay,
            text: 'older',
          ),
          fc.TextMessage(
            id: 'm2',
            authorId: 'u2',
            createdAt: currentDay,
            text: 'newer',
          ),
        ],
      ),
    );

    final context = tester.element(find.byType(DeterministicChatList));
    final previousLabel = formatChatDateSeparatorLabel(context, previousDay);
    final currentLabel = formatChatDateSeparatorLabel(context, currentDay);
    expect(find.text(previousLabel), findsOneWidget);
    expect(find.text(currentLabel), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(previousLabel)).dy,
      greaterThan(tester.getTopLeft(find.text(currentLabel)).dy),
    );
  });

  testWidgets('today and yesterday separators use localized labels', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final today = now;

    await tester.pumpWidget(
      buildList(
        controller: controller,
        messages: <fc.Message>[
          fc.TextMessage(
            id: 'm1',
            authorId: 'u1',
            createdAt: yesterday,
            text: 'yesterday',
          ),
          fc.TextMessage(
            id: 'm2',
            authorId: 'u2',
            createdAt: today,
            text: 'today',
          ),
        ],
      ),
    );

    final context = tester.element(find.byType(DeterministicChatList));
    expect(
      find.text(formatChatDateSeparatorLabel(context, today)),
      findsOneWidget,
    );
    expect(
      find.text(formatChatDateSeparatorLabel(context, yesterday)),
      findsOneWidget,
    );
  });

  group('chatListRawIndexForMessageId', () {
    fc.Message messageAt(String id, DateTime createdAt) =>
        fc.TextMessage(id: id, authorId: 'u1', createdAt: createdAt, text: id);

    test('skips the date separators interleaved between bubbles', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      // Descending visual order: newest -> oldest, as the reversed list wants.
      final messages = <fc.Message>[
        messageAt('newest', DateTime(today.year, today.month, today.day, 14)),
        messageAt('middle', DateTime(today.year, today.month, today.day, 9)),
        messageAt(
          'oldest',
          DateTime(yesterday.year, yesterday.month, yesterday.day, 20),
        ),
      ];

      expect(chatListRawIndexForMessageId(messages, 'newest'), 0);
      expect(chatListRawIndexForMessageId(messages, 'middle'), 1);
      // A separator sits between the two days, so the oldest message is at 3.
      expect(chatListRawIndexForMessageId(messages, 'oldest'), 3);
    });

    test('matches the message index when every message shares a day', () {
      final today = DateTime.now();
      final messages = <fc.Message>[
        messageAt('a', DateTime(today.year, today.month, today.day, 14)),
        messageAt('b', DateTime(today.year, today.month, today.day, 12)),
        messageAt('c', DateTime(today.year, today.month, today.day, 9)),
      ];

      expect(chatListRawIndexForMessageId(messages, 'a'), 0);
      expect(chatListRawIndexForMessageId(messages, 'b'), 1);
      expect(chatListRawIndexForMessageId(messages, 'c'), 2);
    });

    test('returns null for a message outside the loaded window', () {
      final today = DateTime.now();
      final messages = <fc.Message>[
        messageAt('a', DateTime(today.year, today.month, today.day, 14)),
      ];

      expect(chatListRawIndexForMessageId(messages, 'missing'), isNull);
      expect(chatListRawIndexForMessageId(const <fc.Message>[], 'a'), isNull);
    });
  });
}
