import 'package:flutter/material.dart';

class ChatMentionCandidate {
  const ChatMentionCandidate({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  String get mentionText => '@${displayName.trim()}';
}

class ChatMentionToken {
  const ChatMentionToken({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}

class ChatMentionReplacement {
  const ChatMentionReplacement({
    required this.text,
    required this.selectionOffset,
  });

  final String text;
  final int selectionOffset;
}

ChatMentionToken? activeChatMentionToken(String text, TextSelection selection) {
  if (!selection.isValid || !selection.isCollapsed) {
    return null;
  }
  final cursor = selection.baseOffset;
  if (cursor < 0 || cursor > text.length) {
    return null;
  }

  final beforeCursor = text.substring(0, cursor);
  final atIndex = beforeCursor.lastIndexOf('@');
  if (atIndex < 0) {
    return null;
  }
  if (atIndex > 0 && !RegExp(r'\s').hasMatch(text[atIndex - 1])) {
    return null;
  }

  final query = beforeCursor.substring(atIndex + 1);
  if (query.contains(RegExp(r'\s'))) {
    return null;
  }

  return ChatMentionToken(start: atIndex, end: cursor, query: query);
}

List<ChatMentionCandidate> filterChatMentionCandidates({
  required Iterable<ChatMentionCandidate> candidates,
  required String query,
  int limit = 5,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = <ChatMentionCandidate>[];
  for (final candidate in candidates) {
    final displayName = candidate.displayName.trim();
    if (displayName.isEmpty) {
      continue;
    }
    if (normalizedQuery.isNotEmpty &&
        !displayName.toLowerCase().contains(normalizedQuery)) {
      continue;
    }
    filtered.add(candidate);
    if (filtered.length >= limit) {
      break;
    }
  }
  return filtered;
}

ChatMentionReplacement replaceChatMentionToken({
  required String text,
  required ChatMentionToken token,
  required ChatMentionCandidate candidate,
}) {
  final mentionText = '${candidate.mentionText} ';
  final nextText = text.replaceRange(token.start, token.end, mentionText);
  return ChatMentionReplacement(
    text: nextText,
    selectionOffset: token.start + mentionText.length,
  );
}

List<InlineSpan> buildChatMentionSpans({
  required String text,
  required TextStyle baseStyle,
  required TextStyle mentionStyle,
  required Iterable<ChatMentionCandidate> candidates,
}) {
  final mentionTexts =
      candidates
          .map((candidate) => candidate.mentionText.trim())
          .where((mention) => mention.length > 1)
          .toSet()
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  if (text.isEmpty || mentionTexts.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }

  final spans = <InlineSpan>[];
  var index = 0;
  while (index < text.length) {
    String? matchedMention;
    for (final mention in mentionTexts) {
      if (!text.startsWith(mention, index)) {
        continue;
      }
      final beforeOk = index == 0 || RegExp(r'\s').hasMatch(text[index - 1]);
      final end = index + mention.length;
      final afterOk = end == text.length || RegExp(r'\s').hasMatch(text[end]);
      if (beforeOk && afterOk) {
        matchedMention = mention;
        break;
      }
    }

    if (matchedMention == null) {
      final nextMentionIndex = _nextMentionStart(text, index + 1);
      final end = nextMentionIndex == -1 ? text.length : nextMentionIndex;
      spans.add(TextSpan(text: text.substring(index, end), style: baseStyle));
      index = end;
      continue;
    }

    spans.add(TextSpan(text: matchedMention, style: mentionStyle));
    index += matchedMention.length;
  }

  return spans;
}

int _nextMentionStart(String text, int start) {
  for (var index = start; index < text.length; index += 1) {
    if (text.codeUnitAt(index) != 64) {
      continue;
    }
    if (index == 0 || RegExp(r'\s').hasMatch(text[index - 1])) {
      return index;
    }
  }
  return -1;
}
