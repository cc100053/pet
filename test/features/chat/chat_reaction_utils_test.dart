import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_message.dart';
import 'package:pet/features/chat/chat_reaction_utils.dart';

void main() {
  test('adds a new reaction when user has none', () {
    final next = toggleReactionSummaries(
      const <ChatMessageReactionSummary>[],
      '👍',
    );

    expect(next, hasLength(1));
    expect(next.single.emoji, '👍');
    expect(next.single.count, 1);
    expect(next.single.reactedByMe, isTrue);
  });

  test('replaces previous own reaction with a new emoji', () {
    final next = toggleReactionSummaries(const <ChatMessageReactionSummary>[
      ChatMessageReactionSummary(emoji: '👍', count: 2, reactedByMe: true),
      ChatMessageReactionSummary(emoji: '❤️', count: 1, reactedByMe: false),
    ], '❤️');

    expect(next, hasLength(2));
    expect(next[0].emoji, '❤️');
    expect(next[0].count, 2);
    expect(next[0].reactedByMe, isTrue);
    expect(next[1].emoji, '👍');
    expect(next[1].count, 1);
    expect(next[1].reactedByMe, isFalse);
  });

  test('removes own reaction when tapping the same emoji again', () {
    final next = toggleReactionSummaries(const <ChatMessageReactionSummary>[
      ChatMessageReactionSummary(emoji: '👍', count: 1, reactedByMe: true),
      ChatMessageReactionSummary(emoji: '❤️', count: 3, reactedByMe: false),
    ], '👍');

    expect(next, hasLength(1));
    expect(next.single.emoji, '❤️');
    expect(next.single.count, 3);
    expect(next.single.reactedByMe, isFalse);
  });
}
