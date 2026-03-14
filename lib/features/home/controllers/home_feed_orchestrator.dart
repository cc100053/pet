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
          onOptimisticMessage: _handleOptimisticFeed,
          onUploadCompleted: _handleFeedUploadCompleted,
          onUploadFailed: _handleFeedUploadFailed,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
    _armOverfedBubbleForFeedEvent();
    _prunePendingOptimisticFeeds();
    _setStateForFeedOrchestrator(() {
      _feedRewardPendingCount += 1;
    });
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

  void _handleFeedUploadCompleted(FeedUploadResult result) {
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
    if (optimisticRoomId != null) {
      unawaited(_maybePromptFeedDoubleReward(result, optimisticRoomId));
    } else if (roomId != null) {
      unawaited(_maybePromptFeedDoubleReward(result, roomId));
    }
    if (result.coinsAwarded > 0) {
      _applyCoinRewardFeedback(result.coinsAwarded);
    }
    unawaited(
      _loadCoinsInternal(expectedReward: result.coinsAwarded > 0 ? null : 0),
    );
    final refreshRoomId = optimisticRoomId ?? roomId;
    if (refreshRoomId != null) {
      unawaited(_refreshLatestRoomPhoto(refreshRoomId));
      unawaited(_refreshLatestFeed(refreshRoomId));
      unawaited(_refreshPetState());
      unawaited(() async {
        final petId = _petId ?? await _loadPetId(refreshRoomId);
        if (petId != null) {
          await _loadPetInfo(petId, roomId: refreshRoomId);
        }
      }());
    }
    unawaited(ReviewPromptService.instance.onFeedCompletedSuccessfully());
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
    if (!_shouldOfferFeedDoubleReward(result) ||
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
            final rewardResult = await Supabase.instance.client.rpc(
              'claim_action_reward',
              params: {'p_action_type': 'ad_reward', 'p_room_id': roomId},
            );
            final extraReward = _extractRewardAmount(rewardResult);
            if (!mounted) {
              return;
            }
            if (extraReward > 0) {
              _applyCoinRewardFeedback(extraReward);
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
    if (result.coinsAwarded > 0) {
      return true;
    }
    final rewardStatus = result.rewardStatus?.trim().toLowerCase();
    if (rewardStatus == 'granted') {
      return true;
    }
    if (rewardStatus == 'cooldown') {
      return false;
    }
    return !result.cooldownActive;
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

  void _applyCoinRewardFeedback(int amount) {
    if (amount <= 0 || !mounted) {
      return;
    }
    int? rewardEventIdToClear;
    _setStateForFeedOrchestrator(() {
      _coins += amount;
      _coinReward = amount;
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
      });
    });
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
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
    if (!mounted) {
      return;
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
