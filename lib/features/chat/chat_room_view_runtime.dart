import 'dart:async';

import 'chat_message.dart';
import 'chat_mentions.dart';

typedef ChatMentionCandidatesLoader =
    Future<List<ChatMentionCandidate>> Function(String roomId);

class ChatRoomViewRuntime {
  const ChatRoomViewRuntime({
    this.currentUserId,
    this.disableRealtime = false,
    this.loadBlockedUserIds,
    this.fetchMemberCount,
    this.fetchMentionCandidates,
    this.incomingMessages,
    this.updatedMessages,
    this.reactionMessageIds,
    this.fetchReplyPreviews,
  });

  final String? currentUserId;
  final bool disableRealtime;
  final Future<Set<String>> Function(String roomId)? loadBlockedUserIds;
  final Future<int> Function(String roomId)? fetchMemberCount;
  final ChatMentionCandidatesLoader? fetchMentionCandidates;
  final Stream<ChatMessage>? incomingMessages;
  final Stream<ChatMessage>? updatedMessages;
  final Stream<String>? reactionMessageIds;
  final Future<Map<String, ChatReplyPreview>> Function(Set<String> replyIds)?
  fetchReplyPreviews;
}
