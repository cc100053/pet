part of 'chat_room_view_v2.dart';

/// Scroll/viewport domain for [_ChatRoomViewV2State]: scroll handling,
/// return-to-latest, and viewport sync / latest-message visibility.
/// Extracted from chat_room_view_v2.dart verbatim (behavior-preserving).
extension _ChatScrollViewport on _ChatRoomViewV2State {
  void _handleChatScroll() {
    if (!_chatScrollController.hasClients) {
      return;
    }
    final position = _chatScrollController.position;
    final showJumpButton = shouldShowChatScrollToLatestButton(
      pixels: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
    );
    if (showJumpButton != _showScrollToLatestButton && mounted) {
      _setStateChat(() => _showScrollToLatestButton = showJumpButton);
    }

    // Scrolling back down to the newest end while reading history should bring
    // the user back to the live latest, so they don't have to tap the
    // jump-to-latest button to see recent messages.
    if (!_returningToLatest &&
        !_isAnimatingExplicitLatest &&
        shouldRejoinLatestOnScroll(
          pixels: position.pixels,
          minScrollExtent: position.minScrollExtent,
          isHistoryMode: _isHistoryMode,
          pendingLiveMessageCount: _pendingLiveMessageCount,
        )) {
      unawaited(_returnToLatestFromScroll());
      return;
    }

    if (_loadingMore || _loading || !_hasMore) {
      return;
    }
    // In a reversed list, older messages are at the maxScrollExtent. Prefetch
    // before the user actually reaches the edge (~1.5 viewports of lead, with a
    // 600px floor) so older pages are usually ready and scrolling back stays
    // smooth instead of stalling at the boundary.
    final viewportLead = position.viewportDimension * 1.5;
    final prefetchLead = viewportLead > 600.0 ? viewportLead : 600.0;
    if (position.pixels >= position.maxScrollExtent - prefetchLead) {
      unawaited(_loadMore());
    }
  }

  Future<void> _returnToLatestFromScroll() async {
    if (_returningToLatest) {
      return;
    }
    _returningToLatest = true;
    try {
      // Flush buffered live messages into the window locally and apply right
      // away — no network round-trip, no content swap — so scrolling back to
      // the newest end stays smooth. When nothing is buffered this is just a
      // mode flip with no visible change (no more needless refetch flash).
      _historyGroupingBoundaryMessageId = null;
      _window.flushBufferedToLatest();
      await _applyWindowToChat(animated: false);
      if (!mounted) {
        return;
      }
      _scheduleViewportSync(stickToLatest: true, animated: false);
      // Reconcile against the server in the background to recover any live
      // event realtime might have missed. Merge mode (not resetWindow) keeps
      // the current window in place, so reconciliation does not flash.
      unawaited(_refreshLatest());
    } finally {
      _returningToLatest = false;
    }
  }

  void _handleComposerHeightChanged(double height) {
    if ((_composerHeight - height).abs() <= 1) {
      return;
    }
    if (!mounted) {
      return;
    }
    final shouldKeepLatestVisible = _shouldKeepLatestVisible();
    _chatObserver.standby();
    _setStateChat(() => _composerHeight = height);
    if (shouldKeepLatestVisible) {
      _scheduleViewportSync(
        stickToLatest: true,
        animated: false,
        followUpFrames: 2,
      );
    }
  }

  bool _shouldKeepLatestVisible({double tolerance = 72}) {
    if (!_window.isLiveMode) {
      return false;
    }
    if (!_chatScrollController.hasClients) {
      return true;
    }
    final position = _chatScrollController.position;
    // In a reversed list, 0 is the bottom (latest).
    return position.pixels <= tolerance;
  }

  void _scheduleViewportSync({
    required bool stickToLatest,
    required bool animated,
    dynamic anchor,
    int followUpFrames = 0,
  }) {
    if (stickToLatest &&
        !animated &&
        anchor == null &&
        _isAnimatingExplicitLatest) {
      _needsLatestCorrectionAfterAnimation = true;
      return;
    }
    final requestId = ++_viewportSyncRequestId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          !_chatScrollController.hasClients ||
          requestId != _viewportSyncRequestId) {
        return;
      }
      await _runViewportSyncStep(
        stickToLatest: stickToLatest,
        anchor: anchor,
        animated: animated,
      );
      for (var frame = 0; frame < followUpFrames; frame += 1) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted ||
            !_chatScrollController.hasClients ||
            requestId != _viewportSyncRequestId) {
          return;
        }
        await _runViewportSyncStep(
          stickToLatest: stickToLatest,
          anchor: anchor,
          animated: false,
        );
      }
    });
  }

  void _scheduleExplicitLatestAnimation({
    int settleFrames = 2,
    bool reuseExistingLock = false,
    Future<void> Function()? onSettled,
  }) {
    final requestId = ++_viewportSyncRequestId;
    if (!reuseExistingLock) {
      _isAnimatingExplicitLatest = true;
      _needsLatestCorrectionAfterAnimation = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (var frame = 0; frame < settleFrames; frame += 1) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted ||
            !_chatScrollController.hasClients ||
            requestId != _viewportSyncRequestId) {
          _isAnimatingExplicitLatest = false;
          return;
        }
      }
      await _scrollLatestMessageToVisibleBottom(animated: true);
      if (!mounted || requestId != _viewportSyncRequestId) {
        _isAnimatingExplicitLatest = false;
        return;
      }
      _isAnimatingExplicitLatest = false;
      if (_needsLatestCorrectionAfterAnimation) {
        _needsLatestCorrectionAfterAnimation = false;
        _scheduleViewportSync(
          stickToLatest: true,
          animated: false,
          followUpFrames: 1,
        );
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted ||
          !_chatScrollController.hasClients ||
          requestId != _viewportSyncRequestId) {
        return;
      }
      await _scrollLatestMessageToVisibleBottom(animated: false);
      if (!mounted ||
          !_chatScrollController.hasClients ||
          requestId != _viewportSyncRequestId) {
        return;
      }
      if (onSettled != null) {
        await onSettled();
      }
    });
  }

  Future<void> _runViewportSyncStep({
    required bool stickToLatest,
    required dynamic anchor,
    required bool animated,
  }) async {
    if (!_chatScrollController.hasClients || !mounted) {
      return;
    }
    if (!stickToLatest) {
      return;
    }
    await _scrollLatestMessageToVisibleBottom(animated: animated);
  }

  Rect? _globalRectForKey(GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  Future<void> _scrollLatestMessageToVisibleBottom({
    required bool animated,
  }) async {
    if (!_chatScrollController.hasClients) {
      return;
    }
    final position = _chatScrollController.position;
    final target = 0.0; // In a reversed list, 0 is the newest message.
    if ((position.pixels - target).abs() <= 1) {
      return;
    }
    if (!animated) {
      _chatScrollController.jumpTo(target);
      return;
    }
    await _chatScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  _MessagePreviewPresentation _previewPresentationForMessage(
    ChatMessage message,
  ) {
    final ascendingMessages = _toAscendingMessages(_messages);
    final index = ascendingMessages.indexWhere(
      (entry) => entry.id == message.id,
    );
    final isSentByMe = message.senderId == _currentUserId;
    if (index == -1) {
      return _MessagePreviewPresentation(
        isSentByMe: isSentByMe,
        isGroupedWithPrevious: false,
        isGroupedWithNext: false,
        showSenderName: true,
      );
    }
    final previous = index > 0 ? ascendingMessages[index - 1] : null;
    final next = index < ascendingMessages.length - 1
        ? ascendingMessages[index + 1]
        : null;
    final isGroupedWithPrevious =
        previous != null && _canGroupPreviewMessages(previous, message);
    final isGroupedWithNext =
        next != null && _canGroupPreviewMessages(message, next);
    return _MessagePreviewPresentation(
      isSentByMe: isSentByMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
      showSenderName:
          isSentByMe ||
          message.id == _historyGroupingBoundaryMessageId ||
          !isGroupedWithPrevious,
    );
  }

  ChatMessageActionSheetAnchor _buildMessageActionSheetAnchor(
    ChatMessage message, {
    LongPressStartDetails? details,
    required bool isMine,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlayContext = navigator.overlay?.context ?? context;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;
    final media = MediaQuery.of(overlayContext);
    final fallbackTouch = details?.globalPosition ?? Offset.zero;
    if (overlayBox == null || !overlayBox.hasSize) {
      return ChatMessageActionSheetAnchor(
        messageRect: const Rect.fromLTWH(12, 120, 220, 48),
        touchPosition: fallbackTouch,
        alignment: isMine
            ? ChatMessageActionSheetAlignment.right
            : ChatMessageActionSheetAlignment.left,
        safePadding: media.padding,
      );
    }

    final messageRender =
        _messageAnchorKey(message.id).currentContext?.findRenderObject()
            as RenderBox?;
    final localTouch = details != null
        ? overlayBox.globalToLocal(details.globalPosition)
        : Offset(overlayBox.size.width / 2, overlayBox.size.height / 2);
    final rect =
        (messageRender != null &&
            messageRender.attached &&
            messageRender.hasSize)
        ? (() {
            final topLeft = messageRender.localToGlobal(
              Offset.zero,
              ancestor: overlayBox,
            );
            return topLeft & messageRender.size;
          })()
        : Rect.fromLTWH(
            localTouch.dx - 110,
            localTouch.dy - 24,
            220,
            48,
          ).intersect(Offset.zero & overlayBox.size);
    return ChatMessageActionSheetAnchor(
      messageRect: rect,
      touchPosition: localTouch,
      alignment: isMine
          ? ChatMessageActionSheetAlignment.right
          : ChatMessageActionSheetAlignment.left,
      safePadding: media.padding,
    );
  }
}
