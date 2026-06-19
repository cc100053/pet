enum FeedUploadJobStatus { pending, uploading, completed, failed }

class FeedOptimisticMessage {
  const FeedOptimisticMessage({
    required this.tempId,
    required this.roomId,
    required this.senderId,
    required this.localImagePath,
    required this.caption,
    required this.clientCreatedAt,
    required this.labels,
  });

  final String tempId;
  final String roomId;
  final String senderId;
  final String localImagePath;
  final String? caption;
  final DateTime clientCreatedAt;
  final List<Map<String, dynamic>> labels;
}

class FeedUploadResult {
  const FeedUploadResult({
    required this.tempId,
    required this.coinsAwarded,
    this.messageId,
    this.imageUrl,
    this.rewardStatus,
    this.cooldownActive = false,
    this.lastFedAt,
    this.nextEligibleAt,
    this.reconciled = false,
    this.petState,
    this.overfed = false,
  });

  final String tempId;
  final int coinsAwarded;
  final String? messageId;
  final String? imageUrl;
  final String? rewardStatus;
  final bool cooldownActive;
  final String? lastFedAt;
  final String? nextEligibleAt;
  final bool reconciled;

  /// Authoritative committed pet state (hunger/mood/last_decay_at/…) returned by
  /// `feed_validate`. Transient only: deliberately excluded from [toJson] so the
  /// durable queue shape stays stable and a stale snapshot is never replayed
  /// from disk on a later app run.
  final Map<String, dynamic>? petState;

  /// True when the server applied no hunger gain (fed again inside the burst
  /// window). Also transient/not persisted.
  final bool overfed;

  FeedUploadResult copyWith({
    String? tempId,
    int? coinsAwarded,
    String? messageId,
    String? imageUrl,
    String? rewardStatus,
    bool? cooldownActive,
    String? lastFedAt,
    String? nextEligibleAt,
    bool? reconciled,
    Map<String, dynamic>? petState,
    bool? overfed,
  }) {
    return FeedUploadResult(
      tempId: tempId ?? this.tempId,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      messageId: messageId ?? this.messageId,
      imageUrl: imageUrl ?? this.imageUrl,
      rewardStatus: rewardStatus ?? this.rewardStatus,
      cooldownActive: cooldownActive ?? this.cooldownActive,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      nextEligibleAt: nextEligibleAt ?? this.nextEligibleAt,
      reconciled: reconciled ?? this.reconciled,
      petState: petState ?? this.petState,
      overfed: overfed ?? this.overfed,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'temp_id': tempId,
      'coins_awarded': coinsAwarded,
      'message_id': messageId,
      'image_url': imageUrl,
      'reward_status': rewardStatus,
      'cooldown_active': cooldownActive,
      'last_fed_at': lastFedAt,
      'next_eligible_at': nextEligibleAt,
      'reconciled': reconciled,
    };
  }

  factory FeedUploadResult.fromJson(Map<String, dynamic> json) {
    return FeedUploadResult(
      tempId: json['temp_id'] as String? ?? '',
      coinsAwarded: _parseInt(json['coins_awarded']),
      messageId: _parseString(json['message_id']),
      imageUrl: _parseString(json['image_url']),
      rewardStatus: _parseString(json['reward_status']),
      cooldownActive: json['cooldown_active'] == true,
      lastFedAt: _parseString(json['last_fed_at']),
      nextEligibleAt: _parseString(json['next_eligible_at']),
      reconciled: json['reconciled'] == true,
    );
  }
}

class FeedUploadJob {
  const FeedUploadJob({
    required this.tempId,
    required this.roomId,
    required this.senderId,
    required this.localImagePath,
    required this.caption,
    required this.clientCreatedAt,
    required this.labels,
    required this.status,
    required this.retryCount,
    required this.updatedAt,
    this.lastError,
    this.result,
  });

  final String tempId;
  final String roomId;
  final String senderId;
  final String localImagePath;
  final String? caption;
  final DateTime clientCreatedAt;
  final List<Map<String, dynamic>> labels;
  final FeedUploadJobStatus status;
  final int retryCount;
  final DateTime updatedAt;
  final String? lastError;
  final FeedUploadResult? result;

  FeedOptimisticMessage toOptimisticMessage() {
    return FeedOptimisticMessage(
      tempId: tempId,
      roomId: roomId,
      senderId: senderId,
      localImagePath: localImagePath,
      caption: caption,
      clientCreatedAt: clientCreatedAt,
      labels: labels,
    );
  }

  FeedUploadJob copyWith({
    FeedUploadJobStatus? status,
    int? retryCount,
    DateTime? updatedAt,
    String? lastError,
    bool clearLastError = false,
    FeedUploadResult? result,
    bool clearResult = false,
  }) {
    return FeedUploadJob(
      tempId: tempId,
      roomId: roomId,
      senderId: senderId,
      localImagePath: localImagePath,
      caption: caption,
      clientCreatedAt: clientCreatedAt,
      labels: labels,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      result: clearResult ? null : (result ?? this.result),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'temp_id': tempId,
      'room_id': roomId,
      'sender_id': senderId,
      'local_image_path': localImagePath,
      'caption': caption,
      'client_created_at': clientCreatedAt.toUtc().toIso8601String(),
      'labels': labels,
      'status': status.name,
      'retry_count': retryCount,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'last_error': lastError,
      'result': result?.toJson(),
    };
  }

  factory FeedUploadJob.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    return FeedUploadJob(
      tempId: json['temp_id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      localImagePath: json['local_image_path'] as String? ?? '',
      caption: _parseString(json['caption']),
      clientCreatedAt:
          DateTime.tryParse(
            json['client_created_at'] as String? ?? '',
          )?.toUtc() ??
          DateTime.now().toUtc(),
      labels:
          (json['labels'] as List?)
              ?.whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList(growable: false) ??
          const <Map<String, dynamic>>[],
      status: FeedUploadJobStatus.values.firstWhere(
        (entry) => entry.name == statusName,
        orElse: () => FeedUploadJobStatus.pending,
      ),
      retryCount: _parseInt(json['retry_count']),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      lastError: _parseString(json['last_error']),
      result: json['result'] is Map
          ? FeedUploadResult.fromJson(
              Map<String, dynamic>.from(json['result'] as Map),
            )
          : null,
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String? _parseString(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}
