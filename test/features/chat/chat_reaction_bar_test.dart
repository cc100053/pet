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

  testWidgets('live count change bounces the chip; history does not', (
    tester,
  ) async {
    double chipScale() => tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.text('👍'),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    Widget bar(int count, {Map<String, DateTime>? pulses}) => _wrap(
      ChatReactionBar(
        reactions: [
          ChatMessageReactionSummary(
            emoji: '👍',
            count: count,
            reactedByMe: false,
          ),
        ],
        pulses: pulses,
      ),
    );

    await tester.pumpWidget(bar(1));
    expect(chipScale(), 1);

    await tester.pumpWidget(bar(2, pulses: {'👍': DateTime.now()}));
    await tester.pump(const Duration(milliseconds: 120));
    expect(chipScale(), greaterThan(1));

    await tester.pumpAndSettle();
    expect(chipScale(), 1);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
