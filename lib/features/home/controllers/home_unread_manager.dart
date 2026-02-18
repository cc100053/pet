part of '../home_view.dart';

extension _HomeUnreadManager on _HomeViewState {
  void _syncMessageSubscriptions(List<String> roomIds) {
    final target = roomIds.toSet();
    final existing = _messageChannels.keys.toList(growable: false);
    for (final roomId in existing) {
      if (!target.contains(roomId)) {
        _messageChannels[roomId]?.unsubscribe();
        _messageChannels.remove(roomId);
      }
    }

    for (final roomId in target) {
      if (_messageChannels.containsKey(roomId)) {
        continue;
      }
      final channel = Supabase.instance.client.channel('messages_$roomId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (payload) => _handleMessageInsert(payload.newRecord),
      );
      channel.subscribe();
      _messageChannels[roomId] = channel;
    }
  }

  int _roomUnreadCount(String? roomId) {
    if (roomId == null) {
      return 0;
    }
    final room = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
      (entry) => entry?['id'] == roomId,
      orElse: () => null,
    );
    final unread = room?['unread_count'];
    if (unread is int) {
      return unread;
    }
    if (unread is num) {
      return unread.toInt();
    }
    return room?['has_unread'] == true ? 1 : 0;
  }

  bool _roomHasUnread(String? roomId) {
    return _roomUnreadCount(roomId) > 0;
  }

  int _totalUnreadCount([List<Map<String, dynamic>>? rooms]) {
    final source = rooms ?? _myRooms;
    var total = 0;
    for (final room in source) {
      final unread = room['unread_count'];
      if (unread is int) {
        total += unread;
        continue;
      }
      if (unread is num) {
        total += unread.toInt();
        continue;
      }
      if (room['has_unread'] == true) {
        total += 1;
      }
    }
    return total;
  }

  void _syncAppIconBadge({List<Map<String, dynamic>>? rooms}) {
    final target = _totalUnreadCount(rooms);
    unawaited(_syncAppIconBadgeWithRetry(target));
  }

  Future<void> _syncAppIconBadgeWithRetry(int count, {int attempt = 0}) async {
    final ok = await AppBadgeService.instance.setBadgeCount(count);
    if (ok || !mounted || attempt >= 3) {
      return;
    }
    await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
    if (!mounted) {
      return;
    }
    await _syncAppIconBadgeWithRetry(count, attempt: attempt + 1);
  }

  void _scheduleUnreadReconcile({Duration delay = const Duration(seconds: 2)}) {
    _unreadReconcileTimer?.cancel();
    _unreadReconcileTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      unawaited(_reconcileUnreadStateFromServer());
    });
  }

  Future<void> _reconcileUnreadStateFromServer() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    final roomIds = _myRooms
        .map((room) => room['id'])
        .whereType<String>()
        .toList(growable: false);
    if (roomIds.isEmpty) {
      _syncAppIconBadge(rooms: const <Map<String, dynamic>>[]);
      return;
    }
    try {
      final unreadByRoom = await _fetchRoomUnreadCounts(roomIds, userId);
      if (!mounted) {
        return;
      }
      final nextRooms = _myRooms
          .map((room) {
            final roomId = room['id'] as String?;
            if (roomId == null) {
              return room;
            }
            final unread = unreadByRoom[roomId] ?? 0;
            return {...room, 'unread_count': unread, 'has_unread': unread > 0};
          })
          .toList(growable: false);
      _setRoomsState(nextRooms);
      _syncAppIconBadge(rooms: nextRooms);
    } catch (error) {
      debugPrint('[chat] reconcile unread failed: $error');
    }
  }

  void _markRoomAsRead(String roomId) {
    if (!mounted) {
      return;
    }
    final nextRooms = _myRooms
        .map(
          (room) => room['id'] == roomId
              ? {...room, 'unread_count': 0, 'has_unread': false}
              : room,
        )
        .toList(growable: false);
    _setRoomsState(nextRooms);
    _syncAppIconBadge(rooms: nextRooms);
    _markRoomAsReadOnServer(roomId);
  }

  void _markRoomAsReadOnServer(String roomId) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    unawaited(() async {
      try {
        await Supabase.instance.client.rpc(
          'mark_room_read',
          params: {'p_room_id': roomId},
        );
        await _reconcileUnreadStateFromServer();
        _scheduleUnreadReconcile();
      } catch (error) {
        debugPrint('[chat] mark_room_read failed: $error');
      }
    }());
  }

  void _incrementRoomUnreadCount(String roomId) {
    if (!mounted) {
      return;
    }
    final nextRooms = _myRooms
        .map(
          (room) => room['id'] == roomId
              ? {
                  ...room,
                  'unread_count':
                      ((room['unread_count'] as num?)?.toInt() ?? 0) + 1,
                  'has_unread': true,
                }
              : room,
        )
        .toList(growable: false);
    _setRoomsState(nextRooms);
    _syncAppIconBadge(rooms: nextRooms);
  }

  void _handleMessageInsert(Map<String, dynamic> record) {
    if (!mounted || record.isEmpty) {
      return;
    }
    final roomId = record['room_id'] as String?;
    if (roomId == null || roomId.isEmpty) {
      return;
    }
    final senderId = record['sender_id'] as String?;
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    final fromSelf = senderId != null && senderId == myUserId;
    final shouldMarkUnread = !fromSelf && _chatOpenRoomId != roomId;
    final type = record['type'] as String?;
    if (type == 'system') {
      if (shouldMarkUnread) {
        _incrementRoomUnreadCount(roomId);
      }
      _handleSystemMessageInsert(record);
      _chatListKey.currentState?.refreshLatest();
      return;
    }
    if (type != 'image_feed') {
      if (shouldMarkUnread) {
        _incrementRoomUnreadCount(roomId);
      }
      return;
    }
    final imageUrl = record['image_url'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      return;
    }
    final caption = record['caption'] as String?;
    _setStateForUnreadMutation(() {
      if (roomId == _roomId) {
        final latestFeed = _prependLatestFeedItem(
          imageUrl: imageUrl,
          caption: caption,
          senderId: senderId,
          existingUrls: _latestFeedImageUrls,
          existingCaptions: _latestFeedCaptions,
          existingSenderIds: _latestFeedSenderIds,
        );
        _latestFeedImageUrl = imageUrl;
        _latestFeedImageUrls = latestFeed.imageUrls;
        _latestFeedCaptions = latestFeed.captions;
        _latestFeedSenderIds = latestFeed.senderIds;
        _latestFeedSenderId = senderId;
        _latestFeedCaption = caption;
      }
      _myRooms = _myRooms.map((room) {
        if (room['id'] != roomId) {
          return room;
        }
        final existingUrls =
            ((room['latest_photos'] as List?)
                        ?.whereType<String>()
                        .where((url) => url.isNotEmpty)
                        .toList() ??
                    const <String>[])
                .toList(growable: false);
        final existingCaptions =
            ((room['latest_photo_captions'] as List?)
                        ?.map((entry) => entry as String?)
                        .toList() ??
                    const <String?>[])
                .toList(growable: false);
        final existingSenderIds =
            ((room['latest_photo_sender_ids'] as List?)
                        ?.map((entry) => entry as String?)
                        .toList() ??
                    const <String?>[])
                .toList(growable: false);
        final next = _prependLatestFeedItem(
          imageUrl: imageUrl,
          caption: caption,
          senderId: senderId,
          existingUrls: existingUrls,
          existingCaptions: existingCaptions,
          existingSenderIds: existingSenderIds,
        );
        return {
          ...room,
          'latest_photo': imageUrl,
          'latest_photos': next.imageUrls,
          'latest_photo_captions': next.captions,
          'latest_photo_sender_ids': next.senderIds,
          'latest_caption': caption,
          'latest_sender_id': senderId,
          'unread_count': shouldMarkUnread
              ? ((room['unread_count'] as num?)?.toInt() ?? 0) + 1
              : ((room['unread_count'] as num?)?.toInt() ?? 0),
          'has_unread': shouldMarkUnread ? true : (room['has_unread'] == true),
        };
      }).toList();
    });
    if (shouldMarkUnread) {
      _syncAppIconBadge();
    }

    if (roomId == _roomId) {
      unawaited(() async {
        final petId = _petId ?? await _loadPetId(roomId);
        if (petId != null) {
          await _loadPetInfo(petId, roomId: roomId);
        }
      }());
    }

    if (senderId != null && senderId.isNotEmpty) {
      unawaited(_ensureProfileSummary(senderId));
    }

    _chatListKey.currentState?.refreshLatest();
  }

  void _handleSystemMessageInsert(Map<String, dynamic> record) {
    final messageId = record['id'] as String?;
    final parsed = _parseHungerAlertSystemBody(record['body'] as String?);
    if (messageId == null || parsed == null) {
      return;
    }
    if (_shownHungerAlertMessageIds.contains(messageId)) {
      return;
    }
    _shownHungerAlertMessageIds.add(messageId);
    _showHungerAlertSnackBar(level: parsed.level, petName: parsed.petName);
  }
}
