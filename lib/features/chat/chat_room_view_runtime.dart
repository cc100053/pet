import 'dart:async';

import 'chat_message.dart';

class ChatRoomViewRuntime {
  const ChatRoomViewRuntime({
    this.currentUserId,
    this.disableRealtime = false,
    this.loadBlockedUserIds,
    this.fetchMemberCount,
    this.incomingMessages,
    this.reactionMessageIds,
    this.fetchReplyPreviews,
  });

  final String? currentUserId;
  final bool disableRealtime;
  final Future<Set<String>> Function(String roomId)? loadBlockedUserIds;
  final Future<int> Function(String roomId)? fetchMemberCount;
  final Stream<ChatMessage>? incomingMessages;
  final Stream<String>? reactionMessageIds;
  final Future<Map<String, ChatReplyPreview>> Function(Set<String> replyIds)?
  fetchReplyPreviews;
}
