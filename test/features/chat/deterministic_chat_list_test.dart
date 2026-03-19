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
            loadingMore: false,
          ),
        ),
      ),
    );
  }

  test('shows jump-to-latest only when far enough from bottom', () {
    expect(
      shouldShowChatScrollToLatestButton(pixels: 640, maxScrollExtent: 900),
      false,
    );
    expect(
      shouldShowChatScrollToLatestButton(pixels: 520, maxScrollExtent: 900),
      true,
    );
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
              loadingMore: false,
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
      lessThan(tester.getTopLeft(find.text(currentLabel)).dy),
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
}
