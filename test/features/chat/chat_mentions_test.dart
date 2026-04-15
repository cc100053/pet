import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/chat/chat_mentions.dart';

void main() {
  const alice = ChatMentionCandidate(userId: 'alice', displayName: 'Alice');
  const alina = ChatMentionCandidate(userId: 'alina', displayName: 'Alina');
  const bob = ChatMentionCandidate(userId: 'bob', displayName: 'Bob');

  group('activeChatMentionToken', () {
    test('detects @ token at cursor after whitespace', () {
      final token = activeChatMentionToken(
        'hello @Al',
        const TextSelection.collapsed(offset: 9),
      );

      expect(token, isNotNull);
      expect(token!.start, 6);
      expect(token.end, 9);
      expect(token.query, 'Al');
    });

    test('ignores @ inside words or after whitespace in query', () {
      expect(
        activeChatMentionToken(
          'email@Al',
          const TextSelection.collapsed(offset: 8),
        ),
        isNull,
      );
      expect(
        activeChatMentionToken(
          '@Alice hi',
          const TextSelection.collapsed(offset: 9),
        ),
        isNull,
      );
    });
  });

  test('filterChatMentionCandidates matches display names in order', () {
    final filtered = filterChatMentionCandidates(
      candidates: const <ChatMentionCandidate>[alice, bob, alina],
      query: 'ali',
    );

    expect(filtered.map((candidate) => candidate.userId), ['alice', 'alina']);
  });

  test(
    'replaceChatMentionToken inserts display mention and trailing space',
    () {
      final token = activeChatMentionToken(
        'hey @Al',
        const TextSelection.collapsed(offset: 7),
      )!;

      final replacement = replaceChatMentionToken(
        text: 'hey @Al',
        token: token,
        candidate: alice,
      );

      expect(replacement.text, 'hey @Alice ');
      expect(replacement.selectionOffset, replacement.text.length);
    },
  );

  test('buildChatMentionSpans highlights exact known mentions', () {
    final spans = buildChatMentionSpans(
      text: 'Hi @Alice and @Bobcat',
      baseStyle: const TextStyle(fontWeight: FontWeight.w400),
      mentionStyle: const TextStyle(fontWeight: FontWeight.w700),
      candidates: const <ChatMentionCandidate>[alice, bob],
    );

    expect(
      spans.where((span) => span.style?.fontWeight == FontWeight.w700),
      hasLength(1),
    );
    expect(
      spans.map((span) => (span as TextSpan).text).join(),
      'Hi @Alice and @Bobcat',
    );
  });
}
