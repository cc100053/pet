import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/widgets/deterministic_chat_list.dart';

void main() {
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
}
