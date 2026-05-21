class PhotoViewerItem {
  const PhotoViewerItem({
    required this.imageUrl,
    this.caption,
    this.senderName,
    this.senderId,
    this.sentAt,
    this.localImagePath,
    this.roomId,
    this.messageId,
    this.selectedReactionEmoji,
  });

  final String imageUrl;
  final String? caption;
  final String? senderName;
  final String? senderId;
  final DateTime? sentAt;
  final String? localImagePath;
  final String? roomId;
  final String? messageId;
  final String? selectedReactionEmoji;

  bool get hasImageSource =>
      imageUrl.trim().isNotEmpty ||
      (localImagePath != null && localImagePath!.trim().isNotEmpty);

  bool get canChatInteract {
    final room = roomId?.trim() ?? '';
    final message = messageId?.trim() ?? '';
    return room.isNotEmpty && message.isNotEmpty;
  }
}
