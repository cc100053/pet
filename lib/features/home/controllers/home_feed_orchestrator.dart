part of '../home_view.dart';

extension _HomeFeedOrchestrator on _HomeViewState {
  Future<void> _refreshLatestRoomPhoto(String roomId) async {
    try {
      final rows = await Supabase.instance.client
          .from('messages')
          .select('image_url, caption, sender_id, created_at')
          .eq('room_id', roomId)
          .eq('type', 'image_feed')
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(3);

      if (rows.isEmpty) {
        return;
      }
      final latest = rows
          .map(
            (row) => (
              row['image_url'] as String?,
              row['caption'] as String?,
              row['sender_id'] as String?,
            ),
          )
          .where((entry) => entry.$1 != null && entry.$1!.isNotEmpty)
          .take(3)
          .toList(growable: false);
      if (latest.isEmpty) {
        return;
      }
      final latestUrls = latest
          .map((entry) => entry.$1!)
          .toList(growable: false);
      final latestCaptions = latest
          .map((entry) => entry.$2)
          .toList(growable: false);
      final latestSenderIds = latest
          .map((entry) => entry.$3)
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      final firstRow = rows.firstWhere(
        (row) => (row['image_url'] as String?)?.isNotEmpty ?? false,
      );
      final senderId = firstRow['sender_id'] as String?;
      final caption = firstRow['caption'] as String?;
      _setStateForFeedOrchestrator(() {
        _myRooms = _myRooms
            .map(
              (room) => room['id'] == roomId
                  ? {
                      ...room,
                      'latest_photo': latestUrls.first,
                      'latest_photos': latestUrls,
                      'latest_photo_captions': latestCaptions,
                      'latest_photo_sender_ids': latestSenderIds,
                      'latest_caption': caption,
                      'latest_sender_id': senderId,
                    }
                  : room,
            )
            .toList();
      });
      for (final latestSenderId in latestSenderIds) {
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
    if (_petDeparted) {
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
    _chatListKey.currentState?.refreshLatest();
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
    _armOverfedBubbleForFeedEvent();
    _optimisticFeedImageByTempId[entry.tempId] = entry.localImagePath;
    _optimisticFeedRoomByTempId[entry.tempId] = entry.roomId;
    final optimisticMessage = ChatMessage(
      id: entry.tempId,
      roomId: entry.roomId,
      senderId: entry.senderId,
      type: 'image_feed',
      body: null,
      imageUrl: null,
      caption: entry.caption,
      coinsAwarded: 0,
      createdAt: entry.clientCreatedAt,
      clientCreatedAt: entry.clientCreatedAt,
      labels: entry.labels,
      localImagePath: entry.localImagePath,
    );
    _chatListKey.currentState?.addOptimisticMessage(optimisticMessage);

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
      _latestFeedOptimisticPrevSenderId = _latestFeedSenderId;
      _latestFeedOptimisticPrevCaption = _latestFeedCaption;
      final latestFeed = _prependLatestFeedItem(
        imageUrl: entry.localImagePath,
        caption: entry.caption,
        senderId: entry.senderId,
        existingUrls: _latestFeedImageUrls,
        existingCaptions: _latestFeedCaptions,
        existingSenderIds: _latestFeedSenderIds,
      );
      _latestFeedImageUrl = entry.localImagePath;
      _latestFeedImageUrls = latestFeed.imageUrls;
      _latestFeedCaptions = latestFeed.captions;
      _latestFeedSenderIds = latestFeed.senderIds;
      _latestFeedSenderId = entry.senderId;
      _latestFeedCaption = entry.caption;
    });
    unawaited(_ensureProfileSummary(entry.senderId));
    unawaited(_playFeedSequence(entry.localImagePath));
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    _optimisticFeedImageByTempId.remove(result.tempId);
    final optimisticRoomId = _optimisticFeedRoomByTempId.remove(result.tempId);
    _chatListKey.currentState?.removeOptimisticMessage(result.tempId);
    _chatListKey.currentState?.refreshLatest();

    if (_latestFeedOptimisticTempId == result.tempId) {
      _latestFeedOptimisticTempId = null;
      _latestFeedOptimisticRoomId = null;
      _latestFeedOptimisticPrevImageUrl = null;
      _latestFeedOptimisticPrevImageUrls = null;
      _latestFeedOptimisticPrevCaptions = null;
      _latestFeedOptimisticPrevSenderIds = null;
      _latestFeedOptimisticPrevSenderId = null;
      _latestFeedOptimisticPrevCaption = null;
    }
    final roomId = _roomId;
    if (optimisticRoomId != null) {
      unawaited(_maybePromptFeedDoubleReward(result, optimisticRoomId));
    } else if (roomId != null) {
      unawaited(_maybePromptFeedDoubleReward(result, roomId));
    }
    final expectedReward = result.coinsAwarded > 0
        ? result.coinsAwarded
        : (_shouldOfferFeedDoubleReward(result)
              ? _HomeViewState._optimisticFeedRewardCoins
              : 0);
    unawaited(_loadCoins(expectedReward: expectedReward));
    if (roomId != null) {
      unawaited(_refreshLatestRoomPhoto(roomId));
      unawaited(_refreshLatestFeed(roomId));
      unawaited(_refreshPetState());
      unawaited(() async {
        final petId = _petId ?? await _loadPetId(roomId);
        if (petId != null) {
          await _loadPetInfo(petId, roomId: roomId);
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
    } finally {
      _showingFeedDoubleRewardPrompt = false;
    }
  }

  bool _shouldOfferFeedDoubleReward(FeedUploadResult result) {
    if (result.coinsAwarded > 0) {
      return true;
    }
    return result.rewardStatus?.toLowerCase() == 'granted';
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
    final overlay = Overlay.of(context, rootOverlay: true);

    final completer = Completer<_FeedDoubleRewardPromptAction>();
    late final OverlayEntry entry;
    Timer? timer;

    void complete(_FeedDoubleRewardPromptAction action) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(action);
      timer?.cancel();
      timer = null;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _FeedDoubleRewardPill(
        title: l10n.feedAdDoubleRewardTitle,
        message: l10n.feedAdDoubleRewardMessage(expectedExtra),
        watchLabel: l10n.storeAdRewardAction,
        onWatch: () => complete(_FeedDoubleRewardPromptAction.watch),
        onClose: () => complete(_FeedDoubleRewardPromptAction.cancel),
      ),
    );

    overlay.insert(entry);
    timer = Timer(
      const Duration(seconds: 6),
      () => complete(_FeedDoubleRewardPromptAction.cancel),
    );

    return completer.future;
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
    _optimisticFeedImageByTempId.remove(tempId);
    _optimisticFeedRoomByTempId.remove(tempId);
    _chatListKey.currentState?.removeOptimisticMessage(tempId);
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
          _latestFeedSenderId = _latestFeedOptimisticPrevSenderId;
          _latestFeedCaption = _latestFeedOptimisticPrevCaption;
        }
        _latestFeedOptimisticTempId = null;
        _latestFeedOptimisticRoomId = null;
        _latestFeedOptimisticPrevImageUrl = null;
        _latestFeedOptimisticPrevImageUrls = null;
        _latestFeedOptimisticPrevCaptions = null;
        _latestFeedOptimisticPrevSenderIds = null;
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
    try {
      final rows = await Supabase.instance.client
          .from('messages')
          .select('sender_id,image_url,caption,created_at')
          .eq('room_id', roomId)
          .eq('type', 'image_feed')
          .not('image_url', 'is', null)
          .order('created_at', ascending: false)
          .limit(3);

      final entries = rows
          .map(
            (row) => (
              row['image_url'] as String?,
              row['caption'] as String?,
              row['sender_id'] as String?,
            ),
          )
          .where((entry) => entry.$1 != null && entry.$1!.isNotEmpty)
          .take(3)
          .toList(growable: false);
      if (entries.isEmpty) {
        if (mounted) {
          _setStateForFeedOrchestrator(() {
            _latestFeedImageUrl = null;
            _latestFeedImageUrls = <String>[];
            _latestFeedCaptions = <String?>[];
            _latestFeedSenderIds = <String?>[];
            _latestFeedSenderId = null;
            _latestFeedCaption = null;
          });
        } else {
          _latestFeedImageUrl = null;
          _latestFeedImageUrls = <String>[];
          _latestFeedCaptions = <String?>[];
          _latestFeedSenderIds = <String?>[];
          _latestFeedSenderId = null;
          _latestFeedCaption = null;
        }
        return;
      }
      final imageUrls = entries
          .map((entry) => entry.$1!)
          .toList(growable: false);
      final captions = entries.map((entry) => entry.$2).toList(growable: false);
      final senderIds = entries
          .map((entry) => entry.$3)
          .toList(growable: false);
      final firstRow = rows.firstWhere(
        (row) => (row['image_url'] as String?)?.isNotEmpty ?? false,
      );
      final imageUrl = imageUrls.first;
      final senderId = firstRow['sender_id'] as String?;
      final caption = captions.first;
      if (mounted) {
        _setStateForFeedOrchestrator(() {
          _latestFeedImageUrl = imageUrl;
          _latestFeedImageUrls = imageUrls;
          _latestFeedCaptions = captions;
          _latestFeedSenderIds = senderIds;
          _latestFeedSenderId = senderId;
          _latestFeedCaption = caption;
        });
      } else {
        _latestFeedImageUrl = imageUrl;
        _latestFeedImageUrls = imageUrls;
        _latestFeedCaptions = captions;
        _latestFeedSenderIds = senderIds;
        _latestFeedSenderId = senderId;
        _latestFeedCaption = caption;
      }
      for (final latestSenderId in senderIds) {
        if (latestSenderId != null && latestSenderId.isNotEmpty) {
          await _ensureProfileSummary(latestSenderId);
        }
      }
    } catch (_) {
      // Best-effort.
    }
  }

  ({List<String> imageUrls, List<String?> captions, List<String?> senderIds})
  _prependLatestFeedItem({
    required String imageUrl,
    required String? caption,
    required String? senderId,
    required List<String> existingUrls,
    required List<String?> existingCaptions,
    required List<String?> existingSenderIds,
  }) {
    if (imageUrl.isEmpty) {
      return (
        imageUrls: existingUrls,
        captions: existingCaptions,
        senderIds: existingSenderIds,
      );
    }
    final nextUrls = <String>[imageUrl];
    final nextCaptions = <String?>[caption];
    final nextSenderIds = <String?>[senderId];
    for (var i = 0; i < existingUrls.length; i++) {
      final url = existingUrls[i];
      if (url.isEmpty || url == imageUrl) {
        continue;
      }
      nextUrls.add(url);
      nextCaptions.add(
        i < existingCaptions.length ? existingCaptions[i] : null,
      );
      nextSenderIds.add(
        i < existingSenderIds.length ? existingSenderIds[i] : null,
      );
      if (nextUrls.length >= 3) {
        break;
      }
    }
    return (
      imageUrls: nextUrls,
      captions: nextCaptions,
      senderIds: nextSenderIds,
    );
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
