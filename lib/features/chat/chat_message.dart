class ChatMessage {
  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.body,
    required this.imageUrl,
    required this.caption,
    required this.coinsAwarded,
    required this.createdAt,
    required this.clientCreatedAt,
    required this.labels,
    required this.localImagePath,
    this.replyToMessageId,
    this.replyPreview,
    this.reactions = const <ChatMessageReactionSummary>[],
  });

  final String id;
  final String roomId;
  final String? senderId;
  final String type;
  final String? body;
  final String? imageUrl;
  final String? caption;
  final int coinsAwarded;
  final DateTime createdAt;
  final DateTime? clientCreatedAt;
  final List<Map<String, dynamic>> labels;
  final String? localImagePath;
  final String? replyToMessageId;
  final ChatReplyPreview? replyPreview;
  final List<ChatMessageReactionSummary> reactions;

  bool get isSystem => type == 'system';
  bool get isImageFeed => type == 'image_feed';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as String?) ?? '',
      roomId: (json['room_id'] as String?) ?? '',
      senderId: json['sender_id'] as String?,
      type: (json['type'] as String?) ?? '',
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      coinsAwarded: (json['coins_awarded'] as int?) ?? 0,
      createdAt: _parseDate(json['created_at']),
      clientCreatedAt: _parseOptionalDate(json['client_created_at']),
      labels: _parseLabels(json['labels']),
      localImagePath: json['local_image_path'] as String?,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyPreview: _parseReplyPreview(json['reply_to']),
      reactions: _parseReactionSummaries(json['reactions']),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? type,
    String? body,
    String? imageUrl,
    String? caption,
    int? coinsAwarded,
    DateTime? createdAt,
    DateTime? clientCreatedAt,
    List<Map<String, dynamic>>? labels,
    String? localImagePath,
    String? replyToMessageId,
    ChatReplyPreview? replyPreview,
    List<ChatMessageReactionSummary>? reactions,
    bool clearReplyPreview = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      createdAt: createdAt ?? this.createdAt,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      labels: labels ?? this.labels,
      localImagePath: localImagePath ?? this.localImagePath,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyPreview: clearReplyPreview
          ? null
          : (replyPreview ?? this.replyPreview),
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toCacheJson() {
    // Cache uses snake_case keys matching API payload; timestamps are ISO-8601.
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'type': type,
      'body': body,
      'image_url': imageUrl,
      'caption': caption,
      'coins_awarded': coinsAwarded,
      'created_at': createdAt.toUtc().toIso8601String(),
      'client_created_at': clientCreatedAt?.toUtc().toIso8601String(),
      'labels': labels,
      'local_image_path': localImagePath,
      'reply_to_message_id': replyToMessageId,
      'reply_to': replyPreview?.toJson(),
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
    };
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

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<Map<String, dynamic>> _parseLabels(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return const [];
  }

  static ChatReplyPreview? _parseReplyPreview(dynamic value) {
    if (value is Map) {
      return ChatReplyPreview.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static List<ChatMessageReactionSummary> _parseReactionSummaries(
    dynamic value,
  ) {
    if (value is! List) {
      return const <ChatMessageReactionSummary>[];
    }
    return value
        .whereType<Map>()
        .map(
          (entry) => ChatMessageReactionSummary.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .where((reaction) => reaction.emoji.isNotEmpty && reaction.count > 0)
        .toList();
  }
}

class ChatMessageReactionSummary {
  const ChatMessageReactionSummary({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });

  final String emoji;
  final int count;
  final bool reactedByMe;

  factory ChatMessageReactionSummary.fromJson(Map<String, dynamic> json) {
    return ChatMessageReactionSummary(
      emoji: (json['emoji'] as String? ?? '').trim(),
      count: (json['count'] as int?) ?? 0,
      reactedByMe: json['reacted_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'emoji': emoji, 'count': count, 'reacted_by_me': reactedByMe};
  }
}

class ChatReplyPreview {
  ChatReplyPreview({
    required this.id,
    required this.senderId,
    required this.type,
    required this.body,
    required this.imageUrl,
    required this.caption,
  });

  final String id;
  final String? senderId;
  final String type;
  final String? body;
  final String? imageUrl;
  final String? caption;

  bool get isImageFeed => type == 'image_feed';

  factory ChatReplyPreview.fromJson(Map<String, dynamic> json) {
    return ChatReplyPreview(
      id: (json['id'] as String?) ?? '',
      senderId: json['sender_id'] as String?,
      type: (json['type'] as String?) ?? '',
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
    );
  }

  factory ChatReplyPreview.fromMessage(ChatMessage message) {
    return ChatReplyPreview(
      id: message.id,
      senderId: message.senderId,
      type: message.type,
      body: message.body,
      imageUrl: message.imageUrl,
      caption: message.caption,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'type': type,
      'body': body,
      'image_url': imageUrl,
      'caption': caption,
    };
  }
}

class ChatReplyTarget {
  const ChatReplyTarget({required this.message, this.senderName});

  final ChatMessage message;
  final String? senderName;
}
