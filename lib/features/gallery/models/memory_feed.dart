class MemoryFeed {
  MemoryFeed({
    required this.id,
    required this.senderId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String? senderId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  factory MemoryFeed.fromJson(Map<String, dynamic> json) {
    return MemoryFeed(
      id: (json['id'] as String?) ?? '',
      senderId: json['sender_id'] as String?,
      imageUrl: (json['image_url'] as String?) ?? '',
      caption: json['caption'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
