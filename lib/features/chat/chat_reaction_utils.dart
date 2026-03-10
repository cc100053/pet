import 'chat_message.dart';

List<ChatMessageReactionSummary> toggleReactionSummaries(
  List<ChatMessageReactionSummary> reactions,
  String emoji,
) {
  final nextByEmoji = <String, ChatMessageReactionSummary>{};
  String? myPreviousEmoji;

  for (final reaction in reactions) {
    if (reaction.reactedByMe) {
      myPreviousEmoji = reaction.emoji;
      final remainingCount = reaction.count - 1;
      if (remainingCount > 0) {
        nextByEmoji[reaction.emoji] = ChatMessageReactionSummary(
          emoji: reaction.emoji,
          count: remainingCount,
          reactedByMe: false,
        );
      }
    } else {
      nextByEmoji[reaction.emoji] = reaction;
    }
  }

  if (myPreviousEmoji != emoji) {
    final existing = nextByEmoji[emoji];
    nextByEmoji[emoji] = ChatMessageReactionSummary(
      emoji: emoji,
      count: (existing?.count ?? 0) + 1,
      reactedByMe: true,
    );
  }

  final next = nextByEmoji.values.toList()
    ..sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.emoji.compareTo(b.emoji);
    });
  return next;
}
