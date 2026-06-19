part of '../home_view.dart';

extension _HomeFeedOrchestrator on _HomeViewState {
  PetHomeGalleryFeedData _currentLatestFeedData() => PetHomeGalleryFeedData(
    imageUrls: List<String>.from(_latestFeedImageUrls),
    captions: List<String?>.from(_latestFeedCaptions),
    senderIds: List<String?>.from(_latestFeedSenderIds),
    sentAts: List<DateTime?>.from(_latestFeedSentAts),
    messageIds: List<String?>.from(_latestFeedMessageIds),
  );

  void _applyLatestFeedData(PetHomeGalleryFeedData data) {
    _latestFeedImageUrl = data.latestImageUrl;
    _latestFeedImageUrls = data.imageUrls;
    _latestFeedCaptions = data.captions;
    _latestFeedSenderIds = data.senderIds;
    _latestFeedSentAts = data.sentAts;
    _latestFeedMessageIds = data.messageIds;
    _latestFeedSenderId = data.latestSenderId;
    _latestFeedCaption = data.latestCaption;
  }

  void _updateRoomLatestFeedSnapshot(
    String roomId,
    PetHomeGalleryFeedData data,
  ) {
    _myRooms = _myRooms
        .map(
          (room) =>
              room['id'] == roomId ? data.applyToRoomSnapshot(room) : room,
        )
        .toList(growable: false);
  }

  PetHomeGalleryFeedData _latestFeedDataFromRows(List<dynamic> rows) {
    var data = const PetHomeGalleryFeedData.empty();
    for (final row in rows.reversed) {
      final imageUrl = row['image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        continue;
      }
      data = data.prependEntry(
        imageUrl: imageUrl,
        caption: row['caption'] as String?,
        senderId: row['sender_id'] as String?,
        sentAt: _parseOptionalDate(row['created_at']),
        messageId: row['id'] as String?,
      );
    }
    return data;
  }

  void _prunePendingOptimisticFeeds() {
    final expired = _pendingOptimisticFeedsByTempId.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final tempId in expired) {
      _pendingOptimisticFeedsByTempId.remove(tempId);
    }
  }

  PendingPetHomeOptimisticFeed? _pendingOptimisticFeedForInsert({
    required String roomId,
    required String? senderId,
    required String? caption,
    required String? messageId,
    required DateTime? clientCreatedAt,
    required DateTime? createdAt,
  }) {
    _prunePendingOptimisticFeeds();
    for (final pending in _pendingOptimisticFeedsByTempId.values) {
      if (pending.matchesRealtimeInsert(
        roomId: roomId,
        senderId: senderId,
        caption: caption,
        messageId: messageId,
        clientCreatedAt: clientCreatedAt,
        createdAt: createdAt,
      )) {
        return pending;
      }
    }
    return null;
  }

  void _handleFeedPhotoRecalled(String messageId) {
    final trimmed = messageId.trim();
    if (trimmed.isEmpty || !mounted) {
      return;
    }
    // Drop the recalled photo from the active room's gallery immediately, then
    // reconcile against the server (also catches the room snapshot).
    if (_latestFeedMessageIds.contains(trimmed)) {
      _setStateForFeedOrchestrator(() {
        final data = _currentLatestFeedData().removeByMessageId(trimmed);
        _applyLatestFeedData(data);
      });
    }
    final roomId = _roomId;
    if (roomId != null) {
      unawaited(_refreshLatestRoomPhoto(roomId));
      unawaited(_refreshLatestFeed(roomId));
    }
  }

  Future<void> _refreshLatestRoomPhoto(String roomId) async {
    try {
      final rows = await Supabase.instance.client
          .from('messages')
          .select('id, image_url, caption, sender_id, created_at')
          .eq('room_id', roomId)
          .eq('type', 'image_feed')
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(kPetHomeGalleryMaxPhotos);

      final latest = _latestFeedDataFromRows(rows);
      if (latest.imageUrls.isEmpty) {
        return;
      }
      if (!mounted) {
        return;
      }
      _setStateForFeedOrchestrator(() {
        _updateRoomLatestFeedSnapshot(roomId, latest);
      });
      for (final latestSenderId in latest.senderIds) {
        if (latestSenderId != null && latestSenderId.isNotEmpty) {
          unawaited(_ensureProfileSummary(latestSenderId));
        }
      }
    } catch (_) {
      // Best-effort. Latest photo updates are also driven by realtime.
    }
  }

  Future<void> _openFeedCamera() async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    if (_isRoomLocked(roomId)) {
      await _showRoomLockedDialog();
      return;
    }
    if (_effectivePetDeparted) {
      final l10n = AppLocalizations.of(context)!;
      await showAppDialog<void>(
        context: context,
        builder: (context) => AppDialog(
          tone: AppDialogTone.info,
          title: l10n.petDepartureFeedDisabledTitle,
          message: l10n.petDepartureFeedDisabledMessage,
          actions: [
            AppDialogAction.primary(
              label: l10n.commonClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCaptureView(
          roomId: roomId,
          onBeforeEnqueue: _tickPetStateBeforeFeed,
          onOptimisticMessage: _handleOptimisticFeed,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
  }

  /// Awaited before a feed is enqueued. Blocks only on the hunger-decay tick —
  /// the one piece the server-side feed must observe — then fires the full
  /// pet-state refresh in the background so the optimistic enqueue isn't held
  /// up by equipment/room reloads or the `pet_state` select.
  Future<void> _tickPetStateBeforeFeed() async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    final petId = _petId ?? await _loadPetId(roomId);
    if (petId == null || !mounted) {
      return;
    }
    await _tickPetStateRpc(petId);
    if (!mounted) {
      return;
    }
    unawaited(_refreshPetState(refreshCoins: false));
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
    if (!mounted) {
      return;
    }
    final alreadyPending = _pendingOptimisticFeedsByTempId.containsKey(
      entry.tempId,
    );
    _armOverfedBubbleForFeedEvent();
    _prunePendingOptimisticFeeds();
    if (!alreadyPending) {
      _setStateForFeedOrchestrator(() {
        _feedRewardPendingCount += 1;
      });
      _applyOptimisticFeedHunger(entry.roomId);
    }
    _pendingOptimisticFeedsByTempId[entry.tempId] =
        PendingPetHomeOptimisticFeed(
          tempId: entry.tempId,
          roomId: entry.roomId,
          senderId: entry.senderId,
          localImagePath: entry.localImagePath,
          caption: entry.caption,
          clientCreatedAt: entry.clientCreatedAt,
        );
    final roomId = _roomId;
    if (roomId == null || entry.roomId != roomId) {
      return;
    }
    if (kIsWeb) {
      return;
    }

    _setStateForFeedOrchestrator(() {
      _latestFeedOptimisticTempId = entry.tempId;
      _latestFeedOptimisticRoomId = entry.roomId;
      _latestFeedOptimisticPrevImageUrl = _latestFeedImageUrl;
      _latestFeedOptimisticPrevImageUrls = List<String>.from(
        _latestFeedImageUrls,
      );
      _latestFeedOptimisticPrevCaptions = List<String?>.from(
        _latestFeedCaptions,
      );
      _latestFeedOptimisticPrevSenderIds = List<String?>.from(
        _latestFeedSenderIds,
      );
      _latestFeedOptimisticPrevSentAts = List<DateTime?>.from(
        _latestFeedSentAts,
      );
      _latestFeedOptimisticPrevMessageIds = List<String?>.from(
        _latestFeedMessageIds,
      );
      _latestFeedOptimisticPrevSenderId = _latestFeedSenderId;
      _latestFeedOptimisticPrevCaption = _latestFeedCaption;
      final latestFeed = _currentLatestFeedData().prependEntry(
        imageUrl: entry.localImagePath,
        caption: entry.caption,
        senderId: entry.senderId,
        sentAt: entry.clientCreatedAt,
        messageId: null,
      );
      _applyLatestFeedData(latestFeed);
    });
    unawaited(_ensureProfileSummary(entry.senderId));
    unawaited(_playFeedSequence(entry.localImagePath));
  }

  void _handleFeedUploadQueueTransition(
    FeedUploadQueueState? previous,
    FeedUploadQueueState next,
  ) {
    _handleFeedUploadQueueTransitionInternal(previous, next);
  }

  void _handleFeedUploadQueueTransitionInternal(
    FeedUploadQueueState? previous,
    FeedUploadQueueState next, {
    bool replayTerminalEvents = false,
  }) {
    for (final event in FeedUploadQueueEvents.between(previous, next)) {
      switch (event) {
        case FeedUploadOptimisticReady():
          _handleQueuedFeedPending(event.job);
        case FeedUploadCompleted():
          _handleQueuedFeedCompleted(
            event,
            replayTerminalEvent: replayTerminalEvents,
          );
        case FeedUploadFailed():
          _handleQueuedFeedFailed(event);
      }
    }
  }

  void _replayUnacknowledgedFeedUploadEvents() {
    final queueState = ref.read(feedUploadQueueProvider);
    if (!queueState.loaded) {
      return;
    }
    _handleFeedUploadQueueTransitionInternal(
      null,
      queueState,
      replayTerminalEvents: true,
    );
  }

  void _handleQueuedFeedPending(FeedUploadJob job) {
    if (_pendingOptimisticFeedsByTempId.containsKey(job.tempId)) {
      return;
    }
    _handleOptimisticFeed(job.toOptimisticMessage());
  }

  void _handleQueuedFeedCompleted(
    FeedUploadCompleted event, {
    bool replayTerminalEvent = false,
  }) {
    if (_handledFeedUploadTerminalTempIds.add(event.job.tempId)) {
      _handleFeedUploadCompleted(
        replayTerminalEvent
            ? event.result.copyWith(reconciled: true)
            : event.result,
      );
    }
    unawaited(
      Future<void>.delayed(
        Duration.zero,
        () => _feedUploadQueue.acknowledge(event.job.tempId),
      ),
    );
  }

  void _handleQueuedFeedFailed(FeedUploadFailed event) {
    if (_handledFeedUploadTerminalTempIds.add(event.job.tempId)) {
      _handleFeedUploadFailed(event.job.tempId, event.error);
    }
    unawaited(
      Future<void>.delayed(
        Duration.zero,
        () => _feedUploadQueue.acknowledge(event.job.tempId),
      ),
    );
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    if (!mounted) {
      return;
    }
    _setStateForFeedOrchestrator(() {
      _feedRewardPendingCount = max(0, _feedRewardPendingCount - 1);
    });
    _prunePendingOptimisticFeeds();
    final pending = _pendingOptimisticFeedsByTempId[result.tempId];
    final optimisticRoomId = pending?.roomId;
    final canonicalImageUrl = result.imageUrl?.trim();
    if (pending != null &&
        canonicalImageUrl != null &&
        canonicalImageUrl.isNotEmpty) {
      final acknowledged = pending.withServerAck(
        messageId: result.messageId,
        remoteImageUrl: canonicalImageUrl,
      );
      _pendingOptimisticFeedsByTempId[result.tempId] = acknowledged;
      _setStateForFeedOrchestrator(() {
        final currentRoomId = pending.roomId;
        final roomSnapshot = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
          (room) => room?['id'] == currentRoomId,
          orElse: () => null,
        );
        final nextRoomData =
            PetHomeGalleryFeedData.fromRoomSnapshot(roomSnapshot).replaceImage(
              fromImageUrl: pending.localImagePath,
              toImageUrl: canonicalImageUrl,
              caption: pending.caption,
              senderId: pending.senderId,
              sentAt: pending.clientCreatedAt,
              messageId: acknowledged.messageId,
              prependIfMissing: true,
            );
        _updateRoomLatestFeedSnapshot(currentRoomId, nextRoomData);
        if (_roomId == currentRoomId) {
          final nextActiveData = _currentLatestFeedData().replaceImage(
            fromImageUrl: pending.localImagePath,
            toImageUrl: canonicalImageUrl,
            caption: pending.caption,
            senderId: pending.senderId,
            sentAt: pending.clientCreatedAt,
            messageId: acknowledged.messageId,
            prependIfMissing: true,
          );
          _applyLatestFeedData(nextActiveData);
          _latestFeedJumpToLatestEventId++;
        }
      });
      if (acknowledged.reconciledWithRealtime) {
        _pendingOptimisticFeedsByTempId.remove(result.tempId);
      }
    }

    if (_latestFeedOptimisticTempId == result.tempId) {
      _latestFeedOptimisticTempId = null;
      _latestFeedOptimisticRoomId = null;
      _latestFeedOptimisticPrevImageUrl = null;
      _latestFeedOptimisticPrevImageUrls = null;
      _latestFeedOptimisticPrevCaptions = null;
      _latestFeedOptimisticPrevSenderIds = null;
      _latestFeedOptimisticPrevSentAts = null;
      _latestFeedOptimisticPrevMessageIds = null;
      _latestFeedOptimisticPrevSenderId = null;
      _latestFeedOptimisticPrevCaption = null;
    }
    final roomId = _roomId;
    if (!result.reconciled && optimisticRoomId != null) {
      unawaited(_maybePromptFeedDoubleReward(result, optimisticRoomId));
    } else if (!result.reconciled && roomId != null) {
      unawaited(_maybePromptFeedDoubleReward(result, roomId));
    }
    if (result.coinsAwarded > 0 && !result.reconciled) {
      _applyCoinRewardFeedback(result.coinsAwarded);
    }
    unawaited(
      _loadCoinsInternal(
        expectedReward: result.reconciled
            ? null
            : (result.coinsAwarded > 0 ? null : 0),
      ),
    );
    final refreshRoomId = optimisticRoomId ?? roomId;
    // Apply the authoritative committed satiety value straight from the feed
    // response so the bar reflects the fed value immediately and deterministically,
    // instead of depending on a realtime event / refetch that can race and lose
    // on slow uploads. The freshness guard inside makes the follow-up refresh
    // below harmless (a staler read can no longer regress this value).
    final authoritativePetState = result.petState;
    if (authoritativePetState != null && refreshRoomId != null) {
      _applyAuthoritativeFeedPetState(refreshRoomId, authoritativePetState);
    }
    if (refreshRoomId != null) {
      unawaited(_refreshLatestRoomPhoto(refreshRoomId));
      unawaited(_refreshLatestFeed(refreshRoomId));
      unawaited(_refreshFeedRoomPetState(refreshRoomId));
      unawaited(() async {
        final petId = await _loadPetId(refreshRoomId);
        if (petId != null) {
          await _loadPetInfo(petId, roomId: refreshRoomId);
        }
      }());
    }
    unawaited(ReviewPromptService.instance.onFeedCompletedSuccessfully());
  }

  Future<void> _refreshFeedRoomPetState(String roomId) async {
    if (roomId == _roomId) {
      await _refreshPetState();
      return;
    }
    try {
      final petId = _petIdByRoom[roomId] ?? await _loadPetId(roomId);
      if (petId == null) {
        return;
      }
      final state = await _fetchPetState(petId);
      if (state == null) {
        return;
      }
      _cachePetState(roomId, petId, state);
      final hunger = state['hunger'] as num?;
      final healthValue = _healthValueFromHunger(hunger);
      if (!mounted) {
        return;
      }
      _setStateForFeedOrchestrator(() {
        _myRooms = _myRooms
            .map(
              (room) => room['id'] == roomId
                  ? {...room, 'pet_health': healthValue}
                  : room,
            )
            .toList(growable: false);
      });
    } catch (_) {
      // Best-effort; room entry and room-selection refresh also reload state.
    }
  }

  Future<void> _maybePromptFeedDoubleReward(
    FeedUploadResult result,
    String roomId,
  ) async {
    if (!mounted) {
      return;
    }
    if (!AdMobIds.isSupported || _hasProPlanAccess) {
      return;
    }
    final messageId = result.messageId?.trim();
    if (messageId == null ||
        messageId.isEmpty ||
        !_shouldOfferFeedDoubleReward(result) ||
        _showingFeedDoubleRewardPrompt) {
      return;
    }
    _showingFeedDoubleRewardPrompt = true;
    try {
      final service = ref.read(rewardedAdsServiceProvider);
      await service.preload(RewardedAdPlacement.doubleCoins);
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final expectedExtra = result.coinsAwarded > 0
          ? result.coinsAwarded
          : _HomeViewState._optimisticFeedRewardCoins;
      final promptAction = await _showFeedDoubleRewardToast(
        l10n: l10n,
        expectedExtra: expectedExtra,
      );
      if (!mounted || promptAction != _FeedDoubleRewardPromptAction.watch) {
        return;
      }

      final adResult = await service.show(
        const RewardedAdRequest(placement: RewardedAdPlacement.doubleCoins),
      );
      if (!mounted) {
        return;
      }
      switch (adResult.status) {
        case RewardedAdResultStatus.rewarded:
          try {
            final claimPayload = await Supabase.instance.client.rpc(
              'claim_feed_double_reward',
              params: {'p_room_id': roomId, 'p_message_id': messageId},
            );
            final claim = _FeedDoubleRewardClaim.fromPayload(claimPayload);
            if (!mounted) {
              return;
            }
            if (claim.extraReward > 0) {
              _applyCoinRewardFeedback(
                claim.extraReward,
                displayAmount: claim.totalReward,
                displayLabel: l10n.feedAdDoubleRewardClaimed(claim.totalReward),
              );
              unawaited(_loadCoinsInternal());
              unawaited(_refreshLatestRoomPhoto(roomId));
              unawaited(_refreshLatestFeed(roomId));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.storeAdRewardCooldown)),
              );
            }
          } catch (error) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.feedAdDoubleRewardFailed(
                    userFacingError(context, error),
                  ),
                ),
              ),
            );
          }
          return;
        case RewardedAdResultStatus.dismissed:
          return;
        case RewardedAdResultStatus.failed:
        case RewardedAdResultStatus.unavailable:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.feedAdDoubleRewardFailed(
                  adResult.errorMessage ?? l10n.storeAdRewardUnavailable,
                ),
              ),
            ),
          );
          return;
      }
    } catch (error) {
      debugPrint('[ads] failed to present feed double reward prompt: $error');
    } finally {
      _showingFeedDoubleRewardPrompt = false;
    }
  }

  bool _shouldOfferFeedDoubleReward(FeedUploadResult result) {
    final messageId = result.messageId?.trim();
    if (messageId == null || messageId.isEmpty) {
      return false;
    }
    return result.coinsAwarded > 0;
  }

  Future<_FeedDoubleRewardPromptAction> _showFeedDoubleRewardToast({
    required AppLocalizations l10n,
    required int expectedExtra,
  }) async {
    if (!mounted) {
      return _FeedDoubleRewardPromptAction.cancel;
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return _FeedDoubleRewardPromptAction.cancel;
    }
    final action = await showGeneralDialog<_FeedDoubleRewardPromptAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.commonClose,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _FeedDoubleRewardPrompt(
          title: l10n.feedAdDoubleRewardTitle,
          message: l10n.feedAdDoubleRewardMessage(expectedExtra),
          watchLabel: l10n.storeAdRewardAction,
          cancelLabel: l10n.commonCancel,
          onWatch: () => Navigator.of(
            dialogContext,
          ).pop(_FeedDoubleRewardPromptAction.watch),
          onCancel: () => Navigator.of(
            dialogContext,
          ).pop(_FeedDoubleRewardPromptAction.cancel),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
    return action ?? _FeedDoubleRewardPromptAction.cancel;
  }

  void _applyCoinRewardFeedback(
    int amount, {
    int? displayAmount,
    String? displayLabel,
  }) {
    if (amount <= 0 || !mounted) {
      return;
    }
    int? rewardEventIdToClear;
    _setStateForFeedOrchestrator(() {
      _coins += amount;
      _coinReward = displayAmount ?? amount;
      _coinRewardLabel = displayLabel;
      _coinRewardEventId++;
      rewardEventIdToClear = _coinRewardEventId;
    });
    if (rewardEventIdToClear == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_coinRewardEventId != rewardEventIdToClear) {
        return;
      }
      if (_coinReward == null) {
        return;
      }
      _setStateForFeedOrchestrator(() {
        _coinReward = null;
        _coinRewardLabel = null;
      });
    });
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    if (!mounted) {
      return;
    }
    _setStateForFeedOrchestrator(() {
      _feedRewardPendingCount = max(0, _feedRewardPendingCount - 1);
    });
    _pendingOptimisticFeedsByTempId.remove(tempId);
    if (_latestFeedOptimisticTempId == tempId) {
      final shouldRestore =
          _roomId != null && _roomId == _latestFeedOptimisticRoomId;
      _setStateForFeedOrchestrator(() {
        if (shouldRestore) {
          _latestFeedImageUrl = _latestFeedOptimisticPrevImageUrl;
          _latestFeedImageUrls = _latestFeedOptimisticPrevImageUrls == null
              ? <String>[]
              : List<String>.from(_latestFeedOptimisticPrevImageUrls!);
          _latestFeedCaptions = _latestFeedOptimisticPrevCaptions == null
              ? <String?>[]
              : List<String?>.from(_latestFeedOptimisticPrevCaptions!);
          _latestFeedSenderIds = _latestFeedOptimisticPrevSenderIds == null
              ? <String?>[]
              : List<String?>.from(_latestFeedOptimisticPrevSenderIds!);
          _latestFeedSentAts = _latestFeedOptimisticPrevSentAts == null
              ? <DateTime?>[]
              : List<DateTime?>.from(_latestFeedOptimisticPrevSentAts!);
          _latestFeedMessageIds = _latestFeedOptimisticPrevMessageIds == null
              ? <String?>[]
              : List<String?>.from(_latestFeedOptimisticPrevMessageIds!);
          _latestFeedSenderId = _latestFeedOptimisticPrevSenderId;
          _latestFeedCaption = _latestFeedOptimisticPrevCaption;
        }
        _latestFeedOptimisticTempId = null;
        _latestFeedOptimisticRoomId = null;
        _latestFeedOptimisticPrevImageUrl = null;
        _latestFeedOptimisticPrevImageUrls = null;
        _latestFeedOptimisticPrevCaptions = null;
        _latestFeedOptimisticPrevSenderIds = null;
        _latestFeedOptimisticPrevSentAts = null;
        _latestFeedOptimisticPrevMessageIds = null;
        _latestFeedOptimisticPrevSenderId = null;
        _latestFeedOptimisticPrevCaption = null;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.feedUploadFailed(userFacingError(context, error)),
        ),
      ),
    );
    // A "failure" can still mean the server committed the feed (e.g. a slow
    // upload that exceeded the client retry budget). Reconcile pet state and
    // coins so the satiety bar / balance recover instead of staying stale; the
    // freshness guard keeps this from regressing a newer value.
    final roomId = _roomId;
    if (roomId != null) {
      unawaited(_refreshFeedRoomPetState(roomId));
      unawaited(_loadCoinsInternal());
    }
  }

  Future<void> _refreshLatestFeed(String roomId) async {
    final shouldShowLoading = roomId == _roomId && !_showRoomSelection;
    final refreshToken = ++_latestFeedRefreshToken;
    if (shouldShowLoading) {
      if (mounted) {
        _setStateForFeedOrchestrator(() {
          _latestFeedRefreshInFlight = true;
          _latestFeedRefreshingRoomId = roomId;
        });
      } else {
        _latestFeedRefreshInFlight = true;
        _latestFeedRefreshingRoomId = roomId;
      }
    }
    try {
      final rows = await Supabase.instance.client
          .from('messages')
          .select('id,sender_id,image_url,caption,created_at')
          .eq('room_id', roomId)
          .eq('type', 'image_feed')
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(kPetHomeGalleryMaxPhotos);

      final data = _latestFeedDataFromRows(rows);

      void applyRoomSnapshotUpdate() {
        _updateRoomLatestFeedSnapshot(roomId, data);
      }

      if (data.imageUrls.isEmpty) {
        if (mounted) {
          _setStateForFeedOrchestrator(() {
            applyRoomSnapshotUpdate();
            if (roomId != _roomId) {
              return;
            }
            _applyLatestFeedData(const PetHomeGalleryFeedData.empty());
          });
        } else {
          applyRoomSnapshotUpdate();
          _applyLatestFeedData(const PetHomeGalleryFeedData.empty());
        }
        unawaited(_cacheHomeBootstrapSnapshot());
        return;
      }
      if (mounted) {
        _setStateForFeedOrchestrator(() {
          applyRoomSnapshotUpdate();
          if (roomId != _roomId) {
            return;
          }
          _applyLatestFeedData(data);
        });
      } else {
        applyRoomSnapshotUpdate();
        _applyLatestFeedData(data);
      }
      unawaited(_cacheHomeBootstrapSnapshot());
      for (final latestSenderId in data.senderIds) {
        if (latestSenderId != null && latestSenderId.isNotEmpty) {
          await _ensureProfileSummary(latestSenderId);
        }
      }
    } catch (_) {
      // Best-effort.
    } finally {
      if (_latestFeedRefreshingRoomId == roomId &&
          _latestFeedRefreshToken == refreshToken) {
        if (mounted) {
          _setStateForFeedOrchestrator(() {
            _latestFeedRefreshInFlight = false;
            _latestFeedRefreshingRoomId = null;
          });
        } else {
          _latestFeedRefreshInFlight = false;
          _latestFeedRefreshingRoomId = null;
        }
      }
    }
  }

  void _handleOverfedState() {
    final lastOverfed = _parseOptionalDate(
      _petState?['last_overfed_at'],
    )?.toUtc();
    if (lastOverfed == null) {
      return;
    }
    if (_lastOverfedAt != null && !lastOverfed.isAfter(_lastOverfedAt!)) {
      return;
    }
    if (DateTime.now().toUtc().difference(lastOverfed) >
        const Duration(minutes: 10)) {
      _lastOverfedAt = lastOverfed;
      return;
    }
    final armedAt = _overfedFeedEventArmedAt;
    if (armedAt == null ||
        DateTime.now().toUtc().difference(armedAt) >
            _HomeViewState._overfedFeedEventWindow) {
      _lastOverfedAt = lastOverfed;
      return;
    }
    _lastOverfedAt = lastOverfed;
    _overfedFeedEventArmedAt = null;
    _overfedBubbleTimer?.cancel();
    _setStateForFeedOrchestrator(() => _showOverfedBubble = true);
    _overfedBubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      _setStateForFeedOrchestrator(() => _showOverfedBubble = false);
    });
  }

  void _armOverfedBubbleForFeedEvent() {
    _overfedFeedEventArmedAt = DateTime.now().toUtc();
  }

  /// Predicts the +25 satiety gain locally on enqueue so a slow upload still
  /// shows immediate feedback. Skipped when the pet was fed within the 10-minute
  /// burst window (the next feed is likely overfed -> no gain); either way the
  /// authoritative `feed_validate` value reconciles the true result on
  /// completion. Deliberately does NOT advance the freshness clock, so a genuine
  /// newer server snapshot can still apply over this prediction.
  void _applyOptimisticFeedHunger(String feedRoomId) {
    if (!mounted) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null || feedRoomId != roomId) {
      return;
    }
    final petState = _petState;
    if (petState == null) {
      return;
    }
    final current = (petState['hunger'] as num?)?.toDouble();
    if (current == null) {
      return;
    }
    final lastFeed = _parseOptionalDate(petState['last_feed_at'])?.toUtc();
    final recentlyFed =
        lastFeed != null &&
        DateTime.now().toUtc().difference(lastFeed) <
            const Duration(minutes: 10);
    if (recentlyFed) {
      return;
    }
    final optimistic = min(
      100,
      current.round() + _HomeViewState._feedHungerGain,
    );
    if (optimistic <= current.round()) {
      return;
    }
    final healthValue = _healthValueFromHunger(optimistic);
    _setStateForFeedOrchestrator(() {
      _petState = {...petState, 'hunger': optimistic};
      _myRooms = _myRooms
          .map(
            (room) => room['id'] == roomId
                ? {...room, 'pet_health': healthValue}
                : room,
          )
          .toList(growable: false);
    });
    _syncPetStateProvider();
  }

  Offset _pickFoodPlacement(Size fieldSize) {
    final current = _currentPetNormalized();
    var best = const Offset(0.72, 0.72);
    var bestDistance = -1.0;
    for (var i = 0; i < 16; i++) {
      final candidate = Offset(
        0.12 + (_random.nextDouble() * 0.76),
        0.24 + (_random.nextDouble() * 0.62),
      );
      final candidatePx = _positionFromNormalizedSized(
        candidate,
        fieldSize,
        _HomeViewState._photoFoodSize,
      );
      final petPx = _positionFromNormalized(current, fieldSize);
      final distance = (candidatePx - petPx).distance;
      if (distance > bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }
    return best;
  }

  Future<void> _playFeedSequence(String? imageSource) async {
    if (!mounted || _petDeparted) {
      return;
    }
    final source = imageSource?.trim();
    if (source == null || source.isEmpty) {
      return;
    }
    final fieldSize = _petFieldSize();
    if (fieldSize == null || fieldSize.isEmpty) {
      return;
    }
    final token = ++_feedingAnimationToken;
    final foodTarget = _pickFoodPlacement(fieldSize);

    _setStateForFeedOrchestrator(() {
      _photoFoodImageSource = source;
      _photoFoodNormalizedPosition = foodTarget;
      _photoFoodBiteStage = 0;
      _photoFoodDropping = true;
      _petEating = false;
    });

    await Future<void>.delayed(24.ms);
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }
    _setStateForFeedOrchestrator(() => _photoFoodDropping = false);

    await Future<void>.delayed(_HomeViewState._foodDropDuration + 120.ms);
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }

    final current = _currentPetNormalized();
    final currentPx = _positionFromNormalized(current, fieldSize);
    final targetPx = _positionFromNormalizedSized(
      foodTarget,
      fieldSize,
      _HomeViewState._photoFoodSize,
    );
    final hunger = (_petState?['hunger'] as num?)?.toDouble() ?? 50;
    final approachDuration = _durationForFoodApproach(
      distance: (targetPx - currentPx).distance,
      hunger: hunger,
    );

    // Extras converge on the food at the same time as the main pet.
    _summonExtraPetsToFood(foodTarget, fieldSize);

    await _animatePetToAndWait(
      foodTarget,
      fieldSize,
      userInitiated: false,
      duration: approachDuration,
    );
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }

    _setStateForFeedOrchestrator(() {
      _petMoveController.stop();
      _petMoveAnimation = null;
      _petNormalizedPosition = foodTarget;
      _petNormalizedTarget = foodTarget;
      _petEating = true;
      _petIsMoving = false;
      _petStationaryState = _PetStationaryState.staying;
    });
    unawaited(AppSfx.playEating());
    final biteStepDuration = Duration(
      milliseconds: (_HomeViewState._petEatingStayDuration.inMilliseconds / 3)
          .round(),
    );
    for (var stage = 1; stage <= 3; stage++) {
      await Future<void>.delayed(biteStepDuration);
      if (!mounted || token != _feedingAnimationToken) {
        return;
      }
      _setStateForFeedOrchestrator(() => _photoFoodBiteStage = stage);
    }
    if (!mounted || token != _feedingAnimationToken) {
      return;
    }
    _setStateForFeedOrchestrator(() {
      _photoFoodImageSource = null;
      _photoFoodNormalizedPosition = null;
      _photoFoodDropping = false;
      _photoFoodBiteStage = 0;
      _petEating = false;
      _petStationaryState = _PetStationaryState.staying;
    });
  }
}

class _FeedDoubleRewardClaim {
  const _FeedDoubleRewardClaim({
    required this.extraReward,
    required this.totalReward,
    required this.alreadyClaimed,
  });

  final int extraReward;
  final int totalReward;
  final bool alreadyClaimed;

  factory _FeedDoubleRewardClaim.fromPayload(dynamic payload) {
    if (payload is List && payload.isNotEmpty) {
      return _FeedDoubleRewardClaim.fromPayload(payload.first);
    }
    if (payload is Map) {
      return _FeedDoubleRewardClaim(
        extraReward: _parseInt(payload['extra_reward']),
        totalReward: _parseInt(payload['total_reward']),
        alreadyClaimed: payload['already_claimed'] == true,
      );
    }
    return const _FeedDoubleRewardClaim(
      extraReward: 0,
      totalReward: 0,
      alreadyClaimed: false,
    );
  }

  static int _parseInt(dynamic value) {
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
}
