const int kPetHomeGalleryMaxPhotos = 10;
const int kPetHomeGalleryMinSlots = 3;
const int kHomeSummaryPhotoPreviewMaxPhotos = 3;

const Duration _kOptimisticClientCreatedAtTolerance = Duration(seconds: 2);
const Duration _kOptimisticServerCreatedAtTolerance = Duration(seconds: 45);

class PendingPetHomeOptimisticFeed {
  const PendingPetHomeOptimisticFeed({
    required this.tempId,
    required this.roomId,
    required this.senderId,
    required this.localImagePath,
    required this.caption,
    required this.clientCreatedAt,
    this.messageId,
    this.remoteImageUrl,
    this.reconciledWithRealtime = false,
  });

  final String tempId;
  final String roomId;
  final String senderId;
  final String localImagePath;
  final String? caption;
  final DateTime clientCreatedAt;
  final String? messageId;
  final String? remoteImageUrl;
  final bool reconciledWithRealtime;

  PendingPetHomeOptimisticFeed withServerAck({
    String? messageId,
    String? remoteImageUrl,
  }) {
    return PendingPetHomeOptimisticFeed(
      tempId: tempId,
      roomId: roomId,
      senderId: senderId,
      localImagePath: localImagePath,
      caption: caption,
      clientCreatedAt: clientCreatedAt,
      messageId: messageId ?? this.messageId,
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      reconciledWithRealtime: reconciledWithRealtime,
    );
  }

  PendingPetHomeOptimisticFeed markRealtimeReconciled() {
    if (reconciledWithRealtime) {
      return this;
    }
    return PendingPetHomeOptimisticFeed(
      tempId: tempId,
      roomId: roomId,
      senderId: senderId,
      localImagePath: localImagePath,
      caption: caption,
      clientCreatedAt: clientCreatedAt,
      messageId: messageId,
      remoteImageUrl: remoteImageUrl,
      reconciledWithRealtime: true,
    );
  }

  bool get hasServerAck =>
      (messageId?.isNotEmpty ?? false) || (remoteImageUrl?.isNotEmpty ?? false);

  bool get isExpired =>
      DateTime.now().toUtc().difference(clientCreatedAt.toUtc()) >
      const Duration(minutes: 5);

  bool matchesRealtimeInsert({
    required String roomId,
    required String? senderId,
    required String? caption,
    required String? messageId,
    required DateTime? clientCreatedAt,
    required DateTime? createdAt,
  }) {
    if (roomId != this.roomId || senderId != this.senderId) {
      return false;
    }
    if (_normalizeCaption(caption) != _normalizeCaption(this.caption)) {
      return false;
    }

    final expectedMessageId = this.messageId?.trim();
    final incomingMessageId = messageId?.trim();
    if (expectedMessageId != null &&
        expectedMessageId.isNotEmpty &&
        incomingMessageId != null &&
        incomingMessageId.isNotEmpty) {
      return expectedMessageId == incomingMessageId;
    }

    final pendingClientCreatedAt = this.clientCreatedAt.toUtc();
    final incomingClientCreatedAt = clientCreatedAt?.toUtc();
    if (incomingClientCreatedAt != null) {
      return incomingClientCreatedAt.difference(pendingClientCreatedAt).abs() <=
          _kOptimisticClientCreatedAtTolerance;
    }

    final incomingCreatedAt = createdAt?.toUtc();
    if (incomingCreatedAt != null) {
      return incomingCreatedAt.difference(pendingClientCreatedAt).abs() <=
          _kOptimisticServerCreatedAtTolerance;
    }

    return false;
  }
}

class PetHomeGalleryFeedData {
  const PetHomeGalleryFeedData({
    required this.imageUrls,
    required this.captions,
    required this.senderIds,
    required this.sentAts,
    required this.messageIds,
  });

  const PetHomeGalleryFeedData.empty()
    : imageUrls = const <String>[],
      captions = const <String?>[],
      senderIds = const <String?>[],
      sentAts = const <DateTime?>[],
      messageIds = const <String?>[];

  final List<String> imageUrls;
  final List<String?> captions;
  final List<String?> senderIds;
  final List<DateTime?> sentAts;
  final List<String?> messageIds;

  String? get latestImageUrl => imageUrls.isEmpty ? null : imageUrls.first;
  String? get latestCaption => captions.isEmpty ? null : captions.first;
  String? get latestSenderId => senderIds.isEmpty ? null : senderIds.first;

  factory PetHomeGalleryFeedData.fromRoomSnapshot(
    Map<String, dynamic>? roomSnapshot, {
    int maxItems = kPetHomeGalleryMaxPhotos,
  }) {
    if (roomSnapshot == null) {
      return const PetHomeGalleryFeedData.empty();
    }
    final imageUrls =
        ((roomSnapshot['latest_photos'] as List?)
                    ?.whereType<String>()
                    .where((url) => url.isNotEmpty)
                    .take(maxItems)
                    .toList() ??
                const <String>[])
            .toList(growable: false);
    final snapshotCaptions =
        ((roomSnapshot['latest_photo_captions'] as List?)
                    ?.map((entry) => entry as String?)
                    .take(maxItems)
                    .toList() ??
                const <String?>[])
            .toList(growable: false);
    final captions = snapshotCaptions.isEmpty
        ? (imageUrls.isEmpty
              ? const <String?>[]
              : <String?>[
                  roomSnapshot['latest_caption'] as String?,
                  ...List<String?>.filled(imageUrls.length - 1, null),
                ])
        : List<String?>.generate(
            imageUrls.length,
            (index) => index < snapshotCaptions.length
                ? snapshotCaptions[index]
                : null,
          );
    final snapshotSenderIds =
        ((roomSnapshot['latest_photo_sender_ids'] as List?)
                    ?.map((entry) => entry as String?)
                    .take(maxItems)
                    .toList() ??
                const <String?>[])
            .toList(growable: false);
    final latestSenderId = roomSnapshot['latest_sender_id'] as String?;
    final senderIds = snapshotSenderIds.isEmpty
        ? (imageUrls.isEmpty
              ? const <String?>[]
              : <String?>[
                  latestSenderId,
                  ...List<String?>.filled(imageUrls.length - 1, null),
                ])
        : List<String?>.generate(
            imageUrls.length,
            (index) => index < snapshotSenderIds.length
                ? snapshotSenderIds[index]
                : null,
          );
    final snapshotSentAtValues =
        ((roomSnapshot['latest_photo_created_ats'] as List?)
                    ?.take(maxItems)
                    .toList() ??
                const <dynamic>[])
            .toList(growable: false);
    final snapshotMessageIds =
        ((roomSnapshot['latest_photo_message_ids'] as List?)
                    ?.map((entry) => entry as String?)
                    .take(maxItems)
                    .toList() ??
                const <String?>[])
            .toList(growable: false);
    final sentAts = List<DateTime?>.generate(imageUrls.length, (index) {
      if (index >= snapshotSentAtValues.length) {
        return null;
      }
      final raw = snapshotSentAtValues[index];
      if (raw is DateTime) {
        return raw;
      }
      if (raw is String) {
        return DateTime.tryParse(raw);
      }
      return null;
    });
    return PetHomeGalleryFeedData(
      imageUrls: imageUrls,
      captions: captions,
      senderIds: senderIds,
      sentAts: sentAts,
      messageIds: List<String?>.generate(
        imageUrls.length,
        (index) => index < snapshotMessageIds.length
            ? snapshotMessageIds[index]
            : null,
      ),
    );
  }

  Map<String, dynamic> applyToRoomSnapshot(Map<String, dynamic> roomSnapshot) {
    final updated = Map<String, dynamic>.from(roomSnapshot);
    if (imageUrls.isEmpty) {
      updated.remove('latest_photo');
      updated.remove('latest_photos');
      updated.remove('latest_photo_captions');
      updated.remove('latest_photo_sender_ids');
      updated.remove('latest_photo_created_ats');
      updated.remove('latest_photo_message_ids');
      updated.remove('latest_caption');
      updated.remove('latest_sender_id');
      return updated;
    }

    updated['latest_photo'] = latestImageUrl;
    updated['latest_photos'] = imageUrls;
    updated['latest_photo_captions'] = captions;
    updated['latest_photo_sender_ids'] = senderIds;
    updated['latest_photo_created_ats'] = sentAts
        .map((entry) => entry?.toUtc().toIso8601String())
        .toList(growable: false);
    updated['latest_photo_message_ids'] = messageIds;
    updated['latest_caption'] = latestCaption;
    updated['latest_sender_id'] = latestSenderId;
    return updated;
  }

  PetHomeGalleryFeedData prependEntry({
    required String imageUrl,
    required String? caption,
    required String? senderId,
    required DateTime? sentAt,
    String? messageId,
    int maxItems = kPetHomeGalleryMaxPhotos,
  }) {
    if (imageUrl.isEmpty) {
      return this;
    }
    final entries = <_PetHomeGalleryFeedEntry>[
      _PetHomeGalleryFeedEntry(
        imageUrl: imageUrl,
        caption: caption,
        senderId: senderId,
        sentAt: sentAt,
        messageId: messageId,
      ),
      ..._entries.where((entry) => entry.imageUrl != imageUrl),
    ];
    return _fromEntries(entries, maxItems: maxItems);
  }

  PetHomeGalleryFeedData replaceImage({
    required String fromImageUrl,
    required String toImageUrl,
    required String? caption,
    required String? senderId,
    required DateTime? sentAt,
    String? messageId,
    bool prependIfMissing = false,
    int maxItems = kPetHomeGalleryMaxPhotos,
  }) {
    if (toImageUrl.isEmpty) {
      return this;
    }
    final entries = _entries.toList(growable: true);
    var replaced = false;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].imageUrl != fromImageUrl) {
        continue;
      }
      entries[i] = _PetHomeGalleryFeedEntry(
        imageUrl: toImageUrl,
        caption: caption,
        senderId: senderId,
        sentAt: sentAt,
        messageId: messageId,
      );
      replaced = true;
      break;
    }
    if (!replaced && prependIfMissing && !containsImageUrl(toImageUrl)) {
      entries.insert(
        0,
        _PetHomeGalleryFeedEntry(
          imageUrl: toImageUrl,
          caption: caption,
          senderId: senderId,
          sentAt: sentAt,
          messageId: messageId,
        ),
      );
    }
    return _fromEntries(entries, maxItems: maxItems);
  }

  bool containsImageUrl(String imageUrl) =>
      imageUrl.isNotEmpty && imageUrls.contains(imageUrl);

  PetHomeGalleryRealtimeReconcileResult reconcilePendingRealtime({
    required PendingPetHomeOptimisticFeed pending,
    required String roomId,
    required String imageUrl,
    required String? caption,
    required String? senderId,
    required String? messageId,
    required DateTime? clientCreatedAt,
    required DateTime? createdAt,
    int maxItems = kPetHomeGalleryMaxPhotos,
  }) {
    final matchedPending = pending.matchesRealtimeInsert(
      roomId: roomId,
      senderId: senderId,
      caption: caption,
      messageId: messageId,
      clientCreatedAt: clientCreatedAt,
      createdAt: createdAt,
    );
    if (!matchedPending) {
      return PetHomeGalleryRealtimeReconcileResult(
        data: this,
        matchedPending: false,
      );
    }
    if (containsImageUrl(imageUrl) &&
        !containsImageUrl(pending.localImagePath)) {
      return PetHomeGalleryRealtimeReconcileResult(
        data: this,
        matchedPending: true,
      );
    }
    final next = replaceImage(
      fromImageUrl: pending.localImagePath,
      toImageUrl: imageUrl,
      caption: caption,
      senderId: senderId,
      sentAt: clientCreatedAt ?? createdAt ?? pending.clientCreatedAt,
      messageId: messageId ?? pending.messageId,
      prependIfMissing: !containsImageUrl(imageUrl),
      maxItems: maxItems,
    );
    return PetHomeGalleryRealtimeReconcileResult(
      data: next,
      matchedPending: true,
    );
  }

  Iterable<_PetHomeGalleryFeedEntry> get _entries sync* {
    for (var i = 0; i < imageUrls.length; i++) {
      yield _PetHomeGalleryFeedEntry(
        imageUrl: imageUrls[i],
        caption: i < captions.length ? captions[i] : null,
        senderId: i < senderIds.length ? senderIds[i] : null,
        sentAt: i < sentAts.length ? sentAts[i] : null,
        messageId: i < messageIds.length ? messageIds[i] : null,
      );
    }
  }

  static PetHomeGalleryFeedData _fromEntries(
    Iterable<_PetHomeGalleryFeedEntry> entries, {
    required int maxItems,
  }) {
    final deduped = <_PetHomeGalleryFeedEntry>[];
    final seen = <String>{};
    for (final entry in entries) {
      if (entry.imageUrl.isEmpty || !seen.add(entry.imageUrl)) {
        continue;
      }
      deduped.add(entry);
      if (deduped.length >= maxItems) {
        break;
      }
    }
    return PetHomeGalleryFeedData(
      imageUrls: deduped.map((entry) => entry.imageUrl).toList(growable: false),
      captions: deduped.map((entry) => entry.caption).toList(growable: false),
      senderIds: deduped.map((entry) => entry.senderId).toList(growable: false),
      sentAts: deduped.map((entry) => entry.sentAt).toList(growable: false),
      messageIds: deduped
          .map((entry) => entry.messageId)
          .toList(growable: false),
    );
  }
}

class PetHomeGalleryRealtimeReconcileResult {
  const PetHomeGalleryRealtimeReconcileResult({
    required this.data,
    required this.matchedPending,
  });

  final PetHomeGalleryFeedData data;
  final bool matchedPending;
}

List<String> compactSummaryPhotoUrls(Iterable<String> imageUrls) => imageUrls
    .where((url) => url.isNotEmpty)
    .take(kHomeSummaryPhotoPreviewMaxPhotos)
    .toList(growable: false);

String _normalizeCaption(String? caption) => caption?.trim() ?? '';

class _PetHomeGalleryFeedEntry {
  const _PetHomeGalleryFeedEntry({
    required this.imageUrl,
    required this.caption,
    required this.senderId,
    required this.sentAt,
    required this.messageId,
  });

  final String imageUrl;
  final String? caption;
  final String? senderId;
  final DateTime? sentAt;
  final String? messageId;
}
