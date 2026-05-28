import 'package:flutter/material.dart';

/// Shared whitespace matcher. Hoisted to module scope so the per-row mention
/// scan does not allocate a fresh `RegExp` on every boundary check.
final RegExp _whitespacePattern = RegExp(r'\s');

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
  if (atIndex > 0 && !_whitespacePattern.hasMatch(text[atIndex - 1])) {
    return null;
  }

  final query = beforeCursor.substring(atIndex + 1);
  if (query.contains(_whitespacePattern)) {
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

/// A contiguous run of message text, flagged as a mention or plain text.
/// Segmentation is style-independent so it can be cached across rebuilds and
/// reused regardless of sender/brightness styling.
class ChatMentionSegment {
  const ChatMentionSegment({required this.text, required this.isMention});

  final String text;
  final bool isMention;
}

/// Module-level caches. The candidate list is shared across every row in a
/// chat room, so the derived mention-text set and per-message segmentation can
/// be cached globally and dropped wholesale via [invalidateChatMentionCache]
/// whenever the candidate list changes.
List<String>? _cachedMentionTexts;
const int _segmentCacheMaxEntries = 256;
// A plain Map is insertion-ordered in Dart; remove+reinsert gives us LRU.
final Map<String, List<ChatMentionSegment>> _segmentCache =
    <String, List<ChatMentionSegment>>{};

/// Drop cached mention data. Call when the mention candidate list changes so
/// stale segmentation is not reused.
void invalidateChatMentionCache() {
  _cachedMentionTexts = null;
  _segmentCache.clear();
}

List<String> _mentionTextsFor(Iterable<ChatMentionCandidate> candidates) {
  final cached = _cachedMentionTexts;
  if (cached != null) {
    return cached;
  }
  final texts =
      candidates
          .map((candidate) => candidate.mentionText.trim())
          .where((mention) => mention.length > 1)
          .toSet()
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  _cachedMentionTexts = texts;
  return texts;
}

/// Split [text] into mention / plain segments, caching the result by text.
List<ChatMentionSegment> segmentChatMentions({
  required String text,
  required Iterable<ChatMentionCandidate> candidates,
}) {
  if (text.isEmpty) {
    return const <ChatMentionSegment>[];
  }
  final cached = _segmentCache.remove(text);
  if (cached != null) {
    _segmentCache[text] = cached; // touch: mark as most-recently used
    return cached;
  }

  final segments = _computeMentionSegments(text, _mentionTextsFor(candidates));

  if (_segmentCache.length >= _segmentCacheMaxEntries) {
    _segmentCache.remove(_segmentCache.keys.first); // evict oldest
  }
  _segmentCache[text] = segments;
  return segments;
}

List<ChatMentionSegment> _computeMentionSegments(
  String text,
  List<String> mentionTexts,
) {
  if (mentionTexts.isEmpty) {
    return <ChatMentionSegment>[
      ChatMentionSegment(text: text, isMention: false),
    ];
  }

  final segments = <ChatMentionSegment>[];
  var index = 0;
  while (index < text.length) {
    String? matchedMention;
    for (final mention in mentionTexts) {
      if (!text.startsWith(mention, index)) {
        continue;
      }
      final beforeOk =
          index == 0 || _whitespacePattern.hasMatch(text[index - 1]);
      final end = index + mention.length;
      final afterOk =
          end == text.length || _whitespacePattern.hasMatch(text[end]);
      if (beforeOk && afterOk) {
        matchedMention = mention;
        break;
      }
    }

    if (matchedMention == null) {
      final nextMentionIndex = _nextMentionStart(text, index + 1);
      final end = nextMentionIndex == -1 ? text.length : nextMentionIndex;
      segments.add(
        ChatMentionSegment(text: text.substring(index, end), isMention: false),
      );
      index = end;
      continue;
    }

    segments.add(ChatMentionSegment(text: matchedMention, isMention: true));
    index += matchedMention.length;
  }

  return segments;
}

List<InlineSpan> buildChatMentionSpans({
  required String text,
  required TextStyle baseStyle,
  required TextStyle mentionStyle,
  required Iterable<ChatMentionCandidate> candidates,
}) {
  final segments = segmentChatMentions(text: text, candidates: candidates);
  if (segments.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
  }
  return <InlineSpan>[
    for (final segment in segments)
      TextSpan(
        text: segment.text,
        style: segment.isMention ? mentionStyle : baseStyle,
      ),
  ];
}

int _nextMentionStart(String text, int start) {
  for (var index = start; index < text.length; index += 1) {
    if (text.codeUnitAt(index) != 64) {
      continue;
    }
    if (index == 0 || _whitespacePattern.hasMatch(text[index - 1])) {
      return index;
    }
  }
  return -1;
}
