class PhotoViewerItem {
  const PhotoViewerItem({
    required this.imageUrl,
    this.caption,
    this.senderName,
    this.sentAt,
    this.localImagePath,
  });

  final String imageUrl;
  final String? caption;
  final String? senderName;
  final DateTime? sentAt;
  final String? localImagePath;

  bool get hasImageSource =>
      imageUrl.trim().isNotEmpty ||
      (localImagePath != null && localImagePath!.trim().isNotEmpty);
}
