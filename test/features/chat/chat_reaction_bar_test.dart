import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/widgets/chat_reaction_bar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders counts and forwards tap callback', (tester) async {
    ChatMessageReactionSummary? tappedReaction;

    await tester.pumpWidget(
      _wrap(
        ChatReactionBar(
          reactions: const <ChatMessageReactionSummary>[
            ChatMessageReactionSummary(
              emoji: '👍',
              count: 2,
              reactedByMe: true,
            ),
            ChatMessageReactionSummary(
              emoji: '❤️',
              count: 1,
              reactedByMe: false,
            ),
          ],
          onReactionTap: (reaction) => tappedReaction = reaction,
        ),
      ),
    );

    expect(find.text('👍'), findsOneWidget);
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('👍'));
    await tester.pump();

    expect(tappedReaction?.emoji, '👍');
    expect(tappedReaction?.reactedByMe, isTrue);
  });
}
