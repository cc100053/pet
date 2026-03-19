bool shouldIncrementHomeUnreadForIncomingMessage({
  required String roomId,
  required String? openChatRoomId,
  required String? currentUserId,
  required String? senderId,
}) {
  final fromSelf =
      currentUserId != null &&
      currentUserId.isNotEmpty &&
      senderId != null &&
      senderId == currentUserId;
  return !fromSelf && openChatRoomId != roomId;
}
