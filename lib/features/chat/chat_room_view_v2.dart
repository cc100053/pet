import 'dart:async';
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatMessage;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/app_dialog.dart';
import 'package:pet/shared/utils/render_geometry.dart';
import 'package:pet/shared/utils/supabase_realtime.dart';
import 'package:pet/shared/ui/juice_wrappers.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/auth/session_utils.dart';
import '../../services/chat/chat_message_action_service.dart';
import '../../services/chat/chat_message_repository.dart';
import '../../services/crash/crash_reporting_service.dart';
import '../../services/performance/memory_diagnostics_service.dart';
import '../../services/profile/profile_cache_service.dart';
import '../../services/review/review_prompt_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/status_bar_style.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_ui_scale.dart';
import '../../shared/ui/chat_emoji_picker_sheet.dart';
import '../feed/feed_capture_view.dart';
import '../feed/feed_reconciliation.dart';
import '../feed/feed_upload_queue.dart';
import '../pet/pet_animated_image.dart';
import '../../shared/ui/cached_network_image_view.dart';
import '../../shared/ui/keyboard_dismiss_utils.dart';
import '../../shared/ui/user_avatar.dart';
import 'adapters/pet_chat_message_adapter.dart';
import 'blocked_users_sheet.dart';
import 'chat_message.dart';
import 'chat_mentions.dart';
import 'chat_room_view_runtime.dart';
import 'chat_reaction_options.dart';
import 'chat_reaction_utils.dart';
import 'chat_window_state.dart';
import 'room_members_sheet.dart';
import 'widgets/deterministic_chat_list.dart';
import 'widgets/chat_message_action_sheet.dart';
import 'widgets/chat_message_envelope.dart';
import 'widgets/chat_reaction_details_sheet.dart';
import 'widgets/chat_reply_preview_panel.dart';
import 'widgets/chat_keyboard_dismiss_shell.dart';

part 'chat_room_view_v2_overlays.dart';
part 'chat_room_view_v2_composer.dart';
part 'chat_room_view_v2_messages.dart';
part 'chat_room_view_v2_chrome.dart';
part 'chat_room_view_v2_data_helpers.dart';
part 'chat_room_view_v2_scroll.dart';
part 'chat_room_view_v2_actions.dart';
part 'chat_room_view_v2_build.dart';

bool canSwipeReplyToMessage(ChatMessage message) =>
    !message.isSystem && !message.isDeleted;

enum _MessageAction { reply, copy, edit, delete, report, block, moreReactions }

class _MessageActionSelection {
  const _MessageActionSelection._({this.action, this.emoji});

  const _MessageActionSelection.action(_MessageAction action)
    : this._(action: action);

  const _MessageActionSelection.reaction(String emoji) : this._(emoji: emoji);

  final _MessageAction? action;
  final String? emoji;
}

class _MessagePreviewPresentation {
  const _MessagePreviewPresentation({
    required this.isSentByMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.showSenderName,
  });

  final bool isSentByMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool showSenderName;
}

class ChatRoomViewV2 extends ConsumerStatefulWidget {
  const ChatRoomViewV2({
    super.key,
    required this.roomId,
    this.backgroundDecoration,
    this.petName,
    this.memberCount,
    this.petAssetPath,
    this.isDarkBackground = false,
    this.isPetDeparted = false,
    this.isRoomLocked = false,
    this.onFeedSendStarted,
    this.repository,
    this.runtime,
    this.messageActionService,
  });

  final String roomId;
  final BoxDecoration? backgroundDecoration;
  final String? petName;
  final int? memberCount;
  final String? petAssetPath;
  final bool isDarkBackground;
  final bool isPetDeparted;
  final bool isRoomLocked;
  final ValueChanged<FeedOptimisticMessage>? onFeedSendStarted;
  final ChatMessageRepository? repository;
  final ChatRoomViewRuntime? runtime;
  final ChatMessageActionService? messageActionService;

  @override
  ConsumerState<ChatRoomViewV2> createState() => _ChatRoomViewV2State();
}

class _ChatRoomViewV2State extends ConsumerState<ChatRoomViewV2>
    with WidgetsBindingObserver {
  static const int _pageSize = 20;
  static const int _maxVisibleMessages = 80;
  static const Duration _replyJumpDuration = Duration(milliseconds: 360);
  static const Curve _replyJumpCurve = Curves.easeInOutCubic;

  late final ChatMessageActionService _messageActionService;
  final fc.InMemoryChatController _chatController = fc.InMemoryChatController();
  final ScrollController _chatScrollController = ScrollController();
  late final ListObserverController _observerController;
  late final ChatScrollObserver _chatObserver;
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final GlobalKey _composerSurfaceKey = GlobalKey();
  final GlobalKey _composerInputRegionKey = GlobalKey();
  final GlobalKey _composerInteractionRegionKey = GlobalKey();
  final GlobalKey _jumpToLatestPillKey = GlobalKey();
  final ChatWindowState _window = ChatWindowState(
    pageSize: _pageSize,
    maxVisibleMessages: _maxVisibleMessages,
  );
  final Map<String, ChatMessage> _messagesById = <String, ChatMessage>{};
  final Map<String, GlobalKey> _messageAnchorKeys = <String, GlobalKey>{};
  final Map<String, ProfileSummary> _profilesById = <String, ProfileSummary>{};
  final Map<String, String> _optimisticFeedImageByTempId = <String, String>{};
  final List<ChatMentionCandidate> _mentionCandidates =
      <ChatMentionCandidate>[];
  final List<ChatMentionCandidate> _mentionSuggestions =
      <ChatMentionCandidate>[];
  final Set<String> _blockedUserIds = <String>{};
  final Set<String> _optimisticIds = <String>{};
  final Set<String> _loadingReplyPreviewIds = <String>{};

  RealtimeChannel? _channel;
  StreamSubscription<ChatMessage>? _runtimeIncomingSubscription;
  StreamSubscription<ChatMessage>? _runtimeUpdatedSubscription;
  StreamSubscription<String>? _runtimeReactionSubscription;
  int _realtimeGeneration = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _sending = false;
  bool _shouldExitAfterFeedSend = false;
  bool _showScrollToLatestButton = false;
  String? _error;
  String? _replyTargetMessageId;
  String? _highlightedMessageId;
  String? _historyGroupingBoundaryMessageId;
  ChatMentionToken? _activeMentionToken;
  int? _memberCount;
  double _composerHeight = 0;
  double _lastKnownViewInsetBottom = 0;
  int _viewportSyncRequestId = 0;
  bool _isAnimatingExplicitLatest = false;
  bool _needsLatestCorrectionAfterAnimation = false;
  bool _returningToLatest = false;

  ChatMessageRepository get _repository =>
      widget.repository ?? ChatMessageRepository.instance;
  ChatRoomViewRuntime? get _runtime => widget.runtime;
  List<ChatMessage> get _messages => _window.visibleMessages;
  bool get _hasMore => _window.hasMoreOlder;
  bool get _isHistoryMode => _window.isHistoryMode;
  int get _pendingLiveMessageCount => _window.pendingLiveMessageCount;
  bool get _shouldShowJumpToLatestButton =>
      _showScrollToLatestButton ||
      _isHistoryMode ||
      _pendingLiveMessageCount > 0;

  String get _currentUserId =>
      _runtime?.currentUserId ??
      Supabase.instance.client.auth.currentUser?.id ??
      '__anonymous__';

  double _resolvedTopBarHeight(MediaQueryData media) {
    final uiScale = appUiScale(media.size.width);
    return (64.0 * uiScale).clamp(56.0, 64.0);
  }

  double _resolvedListTopPadding(MediaQueryData media) {
    return media.padding.top + _resolvedTopBarHeight(media) + 12;
  }

  double _resolvedComposerBottomInset(MediaQueryData media) {
    // Use max() to ensure a smooth transition and prevent the 'sink and bounce' effect.
    // The inset should never be less than the safe area padding + default gap.
    // When the keyboard is up, it will stay at least 10px above the keyboard.
    return (media.viewInsets.bottom + 10).clamp(
      media.padding.bottom + 8,
      double.infinity,
    );
  }

  double _resolvedListBottomPadding(MediaQueryData media) {
    // The list needs to end where the composer starts
    return _resolvedComposerBottomInset(media) + _composerHeight + 8;
  }

  @override
  void initState() {
    super.initState();
    _messageActionService =
        widget.messageActionService ?? ChatMessageActionService.instance;
    _observerController = ListObserverController(
      controller: _chatScrollController,
    );
    _chatObserver = ChatScrollObserver(_observerController);
    WidgetsBinding.instance.addObserver(this);
    _memberCount = widget.memberCount;
    _chatScrollController.addListener(_handleChatScroll);
    _composerController.addListener(_handleComposerEditingChanged);
    unawaited(_setChatCrashContext(lastAction: 'chat_init'));
    unawaited(_captureMemorySnapshot(source: 'chat_init_state'));
    if (_memberCount == null) {
      unawaited(_fetchMemberCount());
    }
    unawaited(_initialize());
    _subscribeToMessages();
  }

  @override
  void deactivate() {
    // If the chat list is still gliding from a fling when this route is popped
    // (returning to Home), the in-flight ballistic scroll activity can dispatch
    // a ScrollNotification after the subtree is deactivated. That notification
    // bubbles into an ancestor Material's ink handler, which calls
    // findRenderObject() on an inactive element ("Cannot get renderObject of
    // inactive element") and corrupts the deactivation pass — surfacing as the
    // framework `_dependents.isEmpty` assertion and "wrong build scope" errors.
    // Settle the scroll to current offset to cancel the ballistic activity (and
    // its ticker) before the subtree goes inactive. A same-offset jump emits no
    // scroll notifications.
    if (_chatScrollController.hasClients) {
      final position = _chatScrollController.position;
      position.jumpTo(position.pixels);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _realtimeGeneration += 1;
    unawaited(_setChatCrashContext(lastAction: 'chat_dispose'));
    unawaited(_captureMemorySnapshot(source: 'chat_dispose'));
    WidgetsBinding.instance.removeObserver(this);
    final channel = _channel;
    _channel = null;
    unawaited(_removeRealtimeChannel(channel));
    _runtimeIncomingSubscription?.cancel();
    _runtimeIncomingSubscription = null;
    _runtimeUpdatedSubscription?.cancel();
    _runtimeUpdatedSubscription = null;
    _runtimeReactionSubscription?.cancel();
    _runtimeReactionSubscription = null;
    _chatScrollController.removeListener(_handleChatScroll);
    _composerController.removeListener(_handleComposerEditingChanged);
    _chatController.dispose();
    _chatScrollController.dispose();
    _composerController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        _loading ||
        _loadingMore ||
        !mounted) {
      return;
    }
    // Reconcile the latest server page after backgrounded periods where the
    // realtime channel may not have delivered foreground updates yet.
    unawaited(ref.read(feedUploadQueueProvider.notifier).resumePendingJobs());
    unawaited(_refreshLatest());
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) {
      return;
    }
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) {
      return;
    }
    final nextInsetBottom = view.viewInsets.bottom / view.devicePixelRatio;
    if ((nextInsetBottom - _lastKnownViewInsetBottom).abs() <= 0.5) {
      return;
    }
    _lastKnownViewInsetBottom = nextInsetBottom;

    // With reverse: true, we generally don't need manual viewport sync on
    // keyboard metrics changes. We only ensure the latest message is
    // visible if we were already at the bottom.
    if (_shouldKeepLatestVisible()) {
      _scheduleViewportSync(
        stickToLatest: true,
        animated: false,
        followUpFrames: 2,
      );
    }
  }

  bool _globalPointInsideKey(GlobalKey key, Offset globalPosition) {
    final rect = _globalRectForKey(key);
    return rect?.contains(globalPosition) ?? false;
  }

  /// setState wrapper usable from `part`-file extensions on this State
  /// (extensions cannot call the protected `setState` directly).
  void _setStateChat(VoidCallback mutation) {
    setState(mutation);
  }

  void _handleBackdropTapUp(TapUpDetails details) {
    if (_globalPointInsideKey(_jumpToLatestPillKey, details.globalPosition)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _restoreComposerFocusAfterLatestJump() {
    if (!mounted || _composerFocusNode.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _composerFocusNode.hasFocus) {
        return;
      }
      _composerFocusNode.requestFocus();
    });
  }

  int get _imageMessageCount =>
      _messages.where((message) => message.isImageFeed).length;

  Future<void> _captureMemorySnapshot({
    required String source,
    String? note,
    String? fullscreenProviderType,
    int? fullscreenItemCount,
  }) {
    return MemoryDiagnosticsService.instance.captureSnapshot(
      source: source,
      route: 'chat_room_view_v2',
      roomId: widget.roomId,
      messageCount: _messages.length,
      imageMessageCount: _imageMessageCount,
      optimisticMessageCount: _optimisticIds.length,
      note: note,
      fullscreenProviderType: fullscreenProviderType,
      fullscreenItemCount: fullscreenItemCount,
    );
  }

  Future<void> _setChatCrashContext({String? lastAction}) {
    return CrashReportingService.instance.setContext(
      feature: 'chat_room_view_v2',
      roomId: widget.roomId,
      lastAction: lastAction,
    );
  }

  Future<void> _chatBreadcrumb(
    String message, {
    String? messageId,
    Object? error,
  }) {
    final imageCache = PaintingBinding.instance.imageCache;
    int activeChannels;
    try {
      activeChannels = Supabase.instance.client.getChannels().length;
    } catch (_) {
      activeChannels = -1;
    }
    return CrashReportingService.instance.breadcrumb(
      message,
      data: <String, Object?>{
        'room_id': widget.roomId,
        'message_id': messageId,
        'messages': _messages.length,
        'image_messages': _imageMessageCount,
        'optimistic_messages': _optimisticIds.length,
        'cache_bytes': imageCache.currentSizeBytes,
        'cache_live': imageCache.liveImageCount,
        'cache_pending': imageCache.pendingImageCount,
        'channels': activeChannels,
        'error_type': error?.runtimeType.toString(),
      },
    );
  }

  Future<void> _removeRealtimeChannel(RealtimeChannel? channel) =>
      removeRealtimeChannelSafely(channel);

  Future<void> _initialize() async {
    await _loadBlockedUsers();
    await _loadMentionCandidates();
    await _loadCachedMessages();
    await _loadInitial();
  }

  Future<void> _fetchMemberCount() async {
    try {
      final runtimeCountLoader = _runtime?.fetchMemberCount;
      final count = runtimeCountLoader != null
          ? await runtimeCountLoader(widget.roomId)
          : await Supabase.instance.client
                .from('room_members')
                .count(CountOption.exact)
                .eq('room_id', widget.roomId)
                .eq('is_active', true);
      if (!mounted) {
        return;
      }
      setState(() => _memberCount = count);
    } catch (_) {
      // Ignore member count failures in the spike view.
    }
  }

  Future<void> _loadBlockedUsers() async {
    _blockedUserIds.clear();

    try {
      final runtimeLoader = _runtime?.loadBlockedUserIds;
      if (runtimeLoader != null) {
        _blockedUserIds.addAll(await runtimeLoader(widget.roomId));
      } else if (_runtime != null) {
        return;
      } else {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          return;
        }
        final response = await Supabase.instance.client
            .from('blocks')
            .select('blocked_user_id')
            .eq('blocker_id', userId);
        final rows = response as List<dynamic>;
        for (final row in rows) {
          final blockedId = row['blocked_user_id'] as String?;
          if (blockedId != null && blockedId.isNotEmpty) {
            _blockedUserIds.add(blockedId);
          }
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.chatLoadBlockedUsersFailed(userFacingError(context, error));
      });
    }
  }

  Future<void> _loadMentionCandidates() async {
    try {
      final runtimeLoader = _runtime?.fetchMentionCandidates;
      final candidates = runtimeLoader != null
          ? await runtimeLoader(widget.roomId)
          : await _fetchMentionCandidates();
      if (!mounted) {
        return;
      }
      _mentionCandidates
        ..clear()
        ..addAll(candidates.where(_isMentionCandidateVisible));
      // Candidate list changed: drop cached mention segmentation so bubbles
      // re-resolve mentions against the new members.
      invalidateChatMentionCache();
      _updateMentionSuggestions(setStateIfChanged: true);
    } catch (_) {
      // Mention autocomplete is best-effort; the composer remains usable.
    }
  }

  Future<List<ChatMentionCandidate>> _fetchMentionCandidates() async {
    final response = await Supabase.instance.client
        .from('room_members')
        .select('user_id')
        .eq('room_id', widget.roomId)
        .eq('is_active', true)
        .order('joined_at', ascending: true);
    final memberIds = (response as List<dynamic>)
        .whereType<Map>()
        .map((row) => (row['user_id'] as String? ?? '').trim())
        .where((userId) => userId.isNotEmpty && userId != _currentUserId)
        .toList(growable: false);
    if (memberIds.isEmpty) {
      return const <ChatMentionCandidate>[];
    }

    final profiles = await ProfileCacheService.instance.getProfiles(memberIds);
    return memberIds
        .map((userId) {
          final profile = profiles[userId];
          final nickname = profile?.nickname?.trim();
          return ChatMentionCandidate(
            userId: userId,
            displayName: nickname != null && nickname.isNotEmpty
                ? nickname
                : 'User',
            avatarUrl: profile?.avatarUrl,
          );
        })
        .toList(growable: false);
  }

  bool _isMentionCandidateVisible(ChatMentionCandidate candidate) {
    return candidate.userId != _currentUserId &&
        candidate.displayName.trim().isNotEmpty &&
        !_blockedUserIds.contains(candidate.userId);
  }

  Future<void> _refreshAfterBlockChange() async {
    await _loadBlockedUsers();
    await _loadMentionCandidates();
    await _refreshLatest(resetWindow: true);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadCachedMessages() async {
    if (!_repository.isReady) {
      return;
    }

    try {
      final cached = _repository.loadCachedMessages(
        widget.roomId,
        limit: _pageSize,
      );
      final messages = _toAscendingMessages(await cached);
      if (!mounted || messages.isEmpty) {
        return;
      }
      _historyGroupingBoundaryMessageId = null;
      _window.hydrateCache(messages);
      await _applyWindowToChat(animated: false);
      _scheduleViewportSync(
        stickToLatest: true,
        animated: false,
        // followUpFrames is intentionally 0 here: _loadInitial fires
        // immediately after and will schedule its own viewport sync with
        // followUpFrames: 1. Keeping this at 0 prevents the two syncs from
        // competing across frame boundaries, which causes the visible
        // up/down jump when entering a room with cached data.
        followUpFrames: 0,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = null;
      });
      unawaited(_captureMemorySnapshot(source: 'chat_cached_messages_loaded'));
      unawaited(_ensureProfilesForMessages(_messages));
      unawaited(_ensureReplyPreviewsForMessages(_messages));
      unawaited(_ensureReactionSummariesForMessages(_messages));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.chatLoadCacheFailed(userFacingError(context, error));
      });
    }
  }

  Future<void> _loadInitial() async {
    if (mounted) {
      setState(() {
        _loading = _messages.isEmpty;
        _error = null;
      });
    }

    try {
      final page = await _fetchMessagePage();
      if (!mounted) {
        return;
      }
      _historyGroupingBoundaryMessageId = null;
      _window.replaceWithLatest(page.messages, hasMoreOlder: page.hasMoreOlder);
      await _applyWindowToChat(animated: false);
      _scheduleViewportSync(
        stickToLatest: true,
        animated: false,
        followUpFrames: 1,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = null;
      });
      unawaited(_captureMemorySnapshot(source: 'chat_initial_messages_loaded'));
      unawaited(_ensureProfilesForMessages(_messages));
      unawaited(_ensureReplyPreviewsForMessages(_messages));
      unawaited(_ensureReactionSummariesForMessages(_messages));
      unawaited(_persistCache());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(
          context,
        )!.chatLoadMessagesFailed(userFacingError(context, error));
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final oldest = _window.oldestMessage;
      if (oldest == null) {
        return;
      }
      final page = await _fetchMessagePage(
        beforeCreatedAt: oldest.createdAt.toUtc().toIso8601String(),
        beforeId: oldest.id,
      );
      if (!mounted) {
        return;
      }
      _historyGroupingBoundaryMessageId = oldest.id;
      _window.prependOlderPage(page.messages, hasMoreOlder: page.hasMoreOlder);
      await _applyWindowToChat(animated: false);
      unawaited(_ensureProfilesForMessages(_messages));
      unawaited(_ensureReplyPreviewsForMessages(_messages));
      unawaited(_ensureReactionSummariesForMessages(_messages));
      unawaited(_captureMemorySnapshot(source: 'chat_load_more_window_shift'));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.chatLoadMoreFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refreshLatest({bool resetWindow = false}) async {
    try {
      final page = await _fetchMessagePage();
      if (!mounted) {
        return;
      }
      if (resetWindow || _isHistoryMode || _pendingLiveMessageCount > 0) {
        _historyGroupingBoundaryMessageId = null;
        _window.replaceWithLatest(
          page.messages,
          hasMoreOlder: page.hasMoreOlder,
        );
      } else {
        _historyGroupingBoundaryMessageId = null;
        _window.mergeLatestPage(page.messages, hasMoreOlder: page.hasMoreOlder);
      }
      await _applyWindowToChat(animated: false);
      unawaited(_ensureProfilesForMessages(_messages));
      unawaited(_ensureReplyPreviewsForMessages(_messages));
      unawaited(_ensureReactionSummariesForMessages(_messages));
      unawaited(_persistCache());
      unawaited(
        _captureMemorySnapshot(
          source: resetWindow
              ? 'chat_latest_window_reset'
              : 'chat_refresh_latest_merged',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.chatRefreshFailed(userFacingError(context, error));
      });
    }
  }

  Future<void> _applyWindowToChat({required bool animated}) async {
    if (!mounted) {
      return;
    }
    _rebuildMessageIndex();
    _chatObserver.standby();
    await _chatController.setMessages(
      _toUiMessages(_messages),
      animated: animated,
    );
  }

  void _rebuildMessageIndex() {
    _messagesById
      ..clear()
      ..addEntries(_messages.map((message) => MapEntry(message.id, message)));
    _messageAnchorKeys.removeWhere(
      (messageId, _) => !_messagesById.containsKey(messageId),
    );
  }

  GlobalKey _messageAnchorKey(String messageId) {
    return _messageAnchorKeys.putIfAbsent(
      messageId,
      () => GlobalKey(debugLabel: 'chat-message-$messageId'),
    );
  }

  Future<void> _ensureProfilesForMessages(List<ChatMessage> messages) async {
    final userIds = <String>{};
    for (final message in messages) {
      final senderId = message.senderId;
      if (senderId != null &&
          senderId.isNotEmpty &&
          !_profilesById.containsKey(senderId)) {
        userIds.add(senderId);
      }
      final replySenderId = _resolvedReplyPreview(message)?.senderId;
      if (replySenderId != null &&
          replySenderId.isNotEmpty &&
          !_profilesById.containsKey(replySenderId)) {
        userIds.add(replySenderId);
      }
    }

    if (userIds.isEmpty) {
      return;
    }

    try {
      final profiles = await ProfileCacheService.instance.getProfiles(userIds);
      if (!mounted) {
        return;
      }
      final shouldKeepLatestVisible = _shouldKeepLatestVisible();
      bool hasNewProfiles = false;
      for (final entry in profiles.entries) {
        if (!_profilesById.containsKey(entry.key)) {
          _profilesById[entry.key] = entry.value;
          hasNewProfiles = true;
        }
      }
      if (hasNewProfiles) {
        setState(() {});
        if (shouldKeepLatestVisible) {
          _scheduleViewportSync(
            stickToLatest: true,
            animated: false,
            followUpFrames: 2,
          );
        }
      }
    } catch (_) {
      // Best-effort profile loading in the spike view.
    }
  }

  Future<void> _ensureReplyPreviewsForMessages(
    List<ChatMessage> messages,
  ) async {
    final replyIds = <String>{};
    for (final message in messages) {
      final replyId = message.replyToMessageId;
      if (replyId == null ||
          replyId.isEmpty ||
          message.replyPreview != null ||
          _messagesById.containsKey(replyId) ||
          _loadingReplyPreviewIds.contains(replyId)) {
        continue;
      }
      replyIds.add(replyId);
    }

    if (replyIds.isEmpty) {
      return;
    }

    _loadingReplyPreviewIds.addAll(replyIds);
    try {
      final runtimePreviewLoader = _runtime?.fetchReplyPreviews;
      final previewById = runtimePreviewLoader != null
          ? await runtimePreviewLoader(replyIds)
          : await _fetchReplyPreviewMap(replyIds);
      if (!mounted || previewById.isEmpty) {
        return;
      }
      final shouldKeepLatestVisible = _shouldKeepLatestVisible();
      var changed = false;
      for (var index = 0; index < _messages.length; index += 1) {
        final message = _messages[index];
        final replyId = message.replyToMessageId;
        if (replyId == null ||
            replyId.isEmpty ||
            message.replyPreview != null ||
            !previewById.containsKey(replyId)) {
          continue;
        }
        _window.replaceVisibleMessage(
          message.copyWith(replyPreview: previewById[replyId]),
        );
        changed = true;
      }
      if (!changed) {
        return;
      }
      _rebuildMessageIndex();
      unawaited(_persistCache());
      setState(() {});
      if (shouldKeepLatestVisible) {
        _scheduleViewportSync(
          stickToLatest: true,
          animated: false,
          followUpFrames: 2,
        );
      }
    } catch (_) {
      // Best-effort reply preview loading.
    } finally {
      _loadingReplyPreviewIds.removeAll(replyIds);
    }
  }

  Future<void> _ensureReactionSummariesForMessages(
    List<ChatMessage> messages,
  ) async {
    final currentUserId =
        _runtime?.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      return;
    }

    final messageIds = messages
        .where((message) => !message.isSystem && !message.isDeleted)
        .map((message) => message.id)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (messageIds.isEmpty) {
      return;
    }

    try {
      final summaries = await _repository.fetchReactionSummaries(
        roomId: widget.roomId,
        messageIds: messageIds,
        currentUserId: currentUserId,
      );
      if (!mounted) {
        return;
      }
      _applyReactionSummaries(messageIds, summaries);
    } catch (_) {
      // Best-effort reaction loading in the spike view.
    }
  }

  void _applyReactionSummaries(
    List<String> messageIds,
    Map<String, List<ChatMessageReactionSummary>> summariesByMessageId,
  ) {
    final shouldKeepLatestVisible = _shouldKeepLatestVisible();
    var changed = false;
    for (var index = 0; index < _messages.length; index += 1) {
      final message = _messages[index];
      if (!messageIds.contains(message.id)) {
        continue;
      }
      final nextReactions =
          summariesByMessageId[message.id] ??
          const <ChatMessageReactionSummary>[];
      if (_sameReactions(message.reactions, nextReactions)) {
        continue;
      }
      _window.replaceVisibleMessage(message.copyWith(reactions: nextReactions));
      changed = true;
    }

    if (!changed) {
      return;
    }

    _rebuildMessageIndex();
    unawaited(_persistCache());
    if (mounted) {
      setState(() {});
      if (shouldKeepLatestVisible) {
        _scheduleViewportSync(
          stickToLatest: true,
          animated: false,
          followUpFrames: 2,
        );
      }
    }
  }

  void _subscribeToMessages() {
    final generation = ++_realtimeGeneration;
    if (_runtime?.incomingMessages != null ||
        _runtime?.updatedMessages != null ||
        _runtime?.disableRealtime == true) {
      _runtimeIncomingSubscription = _runtime?.incomingMessages?.listen((
        message,
      ) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleIncomingMessage(message);
        }
      });
      _runtimeUpdatedSubscription = _runtime?.updatedMessages?.listen((
        message,
      ) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleUpdatedMessage(message);
        }
      });
      _runtimeReactionSubscription = _runtime?.reactionMessageIds?.listen((
        messageId,
      ) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleReactionRefreshMessageId(messageId);
        }
      });
      return;
    }

    final channel = Supabase.instance.client.channel(
      'room_messages_v2_${widget.roomId}',
    );
    _channel = channel;
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.roomId,
      ),
      callback: (payload) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleIncomingMessage(ChatMessage.fromJson(payload.newRecord));
        }
      },
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.roomId,
      ),
      callback: (payload) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleUpdatedMessage(ChatMessage.fromJson(payload.newRecord));
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'message_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.roomId,
      ),
      callback: (payload) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleReactionRefreshMessageId(
            (payload.newRecord['message_id'] as String? ?? '').trim(),
          );
        }
      },
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'message_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.roomId,
      ),
      callback: (payload) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleReactionRefreshMessageId(
            (payload.newRecord['message_id'] as String? ?? '').trim(),
          );
        }
      },
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'message_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.roomId,
      ),
      callback: (payload) {
        if (_isRealtimeGenerationActive(generation)) {
          _handleReactionRefreshMessageId(
            (payload.oldRecord['message_id'] as String? ?? '').trim(),
          );
        }
      },
    );
    channel.subscribe();
  }

  void _handleReactionRefreshMessageId(String messageId) {
    if (!mounted ||
        messageId.isEmpty ||
        !_messagesById.containsKey(messageId)) {
      return;
    }
    unawaited(_ensureReactionSummariesForMessages([_messagesById[messageId]!]));
  }

  void _handleIncomingMessage(ChatMessage message) {
    if (!mounted || message.type.isEmpty || !_isVisibleMessage(message)) {
      return;
    }
    final duplicateOptimisticId = _findMatchingOptimisticMessageId(message);
    if (duplicateOptimisticId != null) {
      unawaited(
        _replaceOptimisticMessage(
          tempId: duplicateOptimisticId,
          confirmedMessage: message,
          animated: true,
          scrollToLatest: true,
        ),
      );
      return;
    }
    if (_messagesById.containsKey(message.id)) {
      return;
    }
    if (_isHistoryMode) {
      _window.bufferLiveMessage(message);
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final shouldAutoScroll =
        !_chatScrollController.hasClients ||
        !shouldShowChatScrollToLatestButton(
          pixels: _chatScrollController.position.pixels,
          maxScrollExtent: _chatScrollController.position.maxScrollExtent,
        );
    unawaited(
      _insertMessage(
        message,
        animated: true,
        isOptimistic: false,
        scrollToLatest: shouldAutoScroll,
      ),
    );
  }

  void _handleUpdatedMessage(ChatMessage message) {
    if (!mounted ||
        message.type.isEmpty ||
        !_isVisibleMessage(message) ||
        !_messagesById.containsKey(message.id)) {
      return;
    }
    unawaited(_replaceMessageFromRealtime(message));
  }

  Future<void> _replaceMessageFromRealtime(ChatMessage message) async {
    if (!mounted || !_messagesById.containsKey(message.id)) {
      return;
    }
    final previous = _messagesById[message.id];
    final mergedMessage = message.copyWith(
      reactions: message.isDeleted
          ? const <ChatMessageReactionSummary>[]
          : previous?.reactions,
      replyPreview: previous?.replyPreview,
    );
    _window.replaceVisibleMessage(mergedMessage);
    _rebuildMessageIndex();
    await _updateVisibleChatMessage(mergedMessage);
    unawaited(_ensureProfilesForMessages([message]));
    unawaited(_ensureReplyPreviewsForMessages([message]));
    unawaited(_ensureReactionSummariesForMessages([message]));
    unawaited(_persistCache());
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _insertMessage(
    ChatMessage message, {
    required bool animated,
    required bool isOptimistic,
    required bool scrollToLatest,
  }) async {
    if (!mounted) {
      return;
    }

    if (isOptimistic) {
      _optimisticIds.add(message.id);
    } else {
      _optimisticIds.remove(message.id);
    }

    _window.upsertVisibleMessage(message, keepLatestWindow: _window.isLiveMode);
    await _applyWindowToChat(animated: animated);
    unawaited(_ensureProfilesForMessages([message]));
    unawaited(_ensureReplyPreviewsForMessages([message]));
    unawaited(_ensureReactionSummariesForMessages([message]));
    unawaited(_persistCache());
    if (scrollToLatest) {
      _scheduleViewportSync(
        stickToLatest: true,
        animated: animated,
        followUpFrames: animated ? 1 : 0,
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _removeMessageById(
    String messageId, {
    required bool animated,
  }) async {
    if (!mounted) {
      return;
    }
    if (!_window.containsVisibleMessage(messageId)) {
      _optimisticIds.remove(messageId);
      _window.removeVisibleMessage(messageId);
      return;
    }
    _optimisticIds.remove(messageId);
    _window.removeVisibleMessage(messageId);
    _messageAnchorKeys.remove(messageId);
    await _applyWindowToChat(animated: animated);
    unawaited(_persistCache());
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _replaceOptimisticMessage({
    required String tempId,
    required ChatMessage confirmedMessage,
    required bool animated,
    required bool scrollToLatest,
  }) async {
    if (!mounted) {
      return;
    }

    final hasTemp = _window.containsVisibleMessage(tempId);
    final hasConfirmed = _window.containsVisibleMessage(confirmedMessage.id);
    _optimisticIds.remove(tempId);
    _optimisticIds.remove(confirmedMessage.id);
    _messageAnchorKeys.remove(tempId);
    if (hasTemp) {
      _window.removeVisibleMessage(tempId);
    }
    if (hasConfirmed) {
      _window.replaceVisibleMessage(confirmedMessage);
    } else {
      _window.upsertVisibleMessage(
        confirmedMessage,
        keepLatestWindow: _window.isLiveMode,
      );
    }

    await _applyWindowToChat(animated: animated);
    unawaited(_ensureProfilesForMessages([confirmedMessage]));
    unawaited(_ensureReplyPreviewsForMessages([confirmedMessage]));
    unawaited(_ensureReactionSummariesForMessages([confirmedMessage]));
    unawaited(_persistCache());
    if (scrollToLatest) {
      _scheduleViewportSync(
        stickToLatest: true,
        animated: animated,
        followUpFrames: animated ? 1 : 0,
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateVisibleChatMessage(ChatMessage message) async {
    final controllerIndex = _chatController.messages.indexWhere(
      (entry) => entry.id == message.id,
    );
    if (controllerIndex == -1) {
      await _applyWindowToChat(animated: false);
      return;
    }
    await _chatController.updateMessage(
      _chatController.messages[controllerIndex],
      _toUiMessage(message),
    );
  }

  Future<void> _handleSendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final userId =
        _runtime?.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.authReauthRequired),
        ),
      );
      return;
    }

    final replyTargetId = _replyTargetMessageId;
    final replyTarget = replyTargetId == null
        ? null
        : _messagesById[replyTargetId];

    setState(() {
      _sending = true;
      _replyTargetMessageId = null;
    });

    String? tempId;
    try {
      unawaited(_setChatCrashContext(lastAction: 'chat_send_start'));
      unawaited(_chatBreadcrumb('chat_send_start'));
      await _ensureLatestWindowForCompose();
      if (!mounted) {
        return;
      }

      tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toUtc();
      final optimisticMessage = ChatMessage(
        id: tempId,
        roomId: widget.roomId,
        senderId: userId,
        type: 'text',
        body: text,
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: now,
        clientCreatedAt: now,
        labels: const <Map<String, dynamic>>[],
        localImagePath: null,
        replyToMessageId: replyTarget?.id,
        replyPreview: replyTarget == null
            ? null
            : ChatReplyPreview.fromMessage(replyTarget),
      );

      await _insertMessage(
        optimisticMessage,
        animated: true,
        isOptimistic: true,
        scrollToLatest: true,
      );
      unawaited(
        _chatBreadcrumb(
          'chat_send_optimistic_inserted',
          messageId: optimisticMessage.id,
        ),
      );

      final ChatMessage confirmedMessage;
      if (replyTarget != null) {
        confirmedMessage = ChatMessage.fromJson(
          await _messageActionService.sendTextReplyRow(
            roomId: widget.roomId,
            replyToMessageId: replyTarget.id,
            text: text,
            userId: userId,
          ),
        );
      } else {
        confirmedMessage = ChatMessage.fromJson(
          await _messageActionService.sendTextMessageRow(
            roomId: widget.roomId,
            text: text,
            userId: userId,
          ),
        );
      }
      unawaited(
        _chatBreadcrumb('chat_send_db_success', messageId: confirmedMessage.id),
      );
      if (replyTarget == null) {
        unawaited(_notifyTextMessage(confirmedMessage.id));
      }
      if (!mounted) {
        return;
      }
      await _replaceOptimisticMessage(
        tempId: tempId,
        confirmedMessage: confirmedMessage.copyWith(
          replyPreview: replyTarget == null
              ? null
              : ChatReplyPreview.fromMessage(replyTarget),
        ),
        animated: false,
        scrollToLatest: true,
      );
      tempId = null;
      unawaited(_refreshLatest());
      unawaited(
        _chatBreadcrumb(
          'chat_send_refresh_requested',
          messageId: confirmedMessage.id,
        ),
      );
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'success', 'ui': 'flutter_chat_ui_spike'},
      );
    } catch (error) {
      unawaited(_setChatCrashContext(lastAction: 'chat_send_failed'));
      unawaited(_chatBreadcrumb('chat_send_failed', error: error));
      if (tempId != null) {
        await _removeMessageById(tempId, animated: false);
      }
      if (!mounted) {
        return;
      }
      _composerController.text = text;
      _composerController.selection = TextSelection.collapsed(
        offset: _composerController.text.length,
      );
      setState(() {
        _replyTargetMessageId = replyTarget?.id;
      });
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'failure', 'ui': 'flutter_chat_ui_spike'},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.chatSendFailed(userFacingError(context, error)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _handleComposerEditingChanged() {
    _updateMentionSuggestions(setStateIfChanged: true);
  }

  void _updateMentionSuggestions({required bool setStateIfChanged}) {
    final token = activeChatMentionToken(
      _composerController.text,
      _composerController.selection,
    );
    final nextSuggestions = token == null
        ? const <ChatMentionCandidate>[]
        : filterChatMentionCandidates(
            candidates: _mentionCandidates.where(_isMentionCandidateVisible),
            query: token.query,
          );
    if (_sameMentionState(token, nextSuggestions)) {
      return;
    }

    void apply() {
      _activeMentionToken = token;
      _mentionSuggestions
        ..clear()
        ..addAll(nextSuggestions);
    }

    if (!setStateIfChanged || !mounted) {
      apply();
      return;
    }
    setState(apply);
  }

  void _selectMentionCandidate(ChatMentionCandidate candidate) {
    final token = _activeMentionToken;
    if (token == null) {
      return;
    }
    final replacement = replaceChatMentionToken(
      text: _composerController.text,
      token: token,
      candidate: candidate,
    );
    _composerController.value = TextEditingValue(
      text: replacement.text,
      selection: TextSelection.collapsed(offset: replacement.selectionOffset),
    );
    _composerFocusNode.requestFocus();
    _updateMentionSuggestions(setStateIfChanged: true);
  }

  void _setMessageReactionsLocally(
    String messageId,
    List<ChatMessageReactionSummary> reactions,
  ) {
    final message = _messagesById[messageId];
    if (message == null) {
      return;
    }
    if (_sameReactions(message.reactions, reactions)) {
      return;
    }
    _window.replaceVisibleMessage(message.copyWith(reactions: reactions));
    _rebuildMessageIndex();
    unawaited(_persistCache());
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _replaceMessageLocally(
    ChatMessage message, {
    required bool animated,
  }) async {
    if (!mounted || !_messagesById.containsKey(message.id)) {
      return;
    }
    final shouldKeepLatestVisible = _shouldKeepLatestVisible();
    _window.replaceVisibleMessage(message);
    _rebuildMessageIndex();
    await _updateVisibleChatMessage(message);
    unawaited(_persistCache());
    if (!mounted) {
      return;
    }
    setState(() {});
    if (shouldKeepLatestVisible) {
      _scheduleViewportSync(
        stickToLatest: true,
        animated: false,
        followUpFrames: 2,
      );
    }
  }

  Future<void> _toggleReaction(ChatMessage message, String emoji) async {
    final userId =
        _runtime?.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || message.isSystem || message.isDeleted) {
      return;
    }

    final previousReactions = message.reactions;
    final nextReactions = toggleReactionSummaries(previousReactions, emoji);
    _setMessageReactionsLocally(message.id, nextReactions);

    try {
      ChatMessageReactionSummary? currentReaction;
      for (final reaction in previousReactions) {
        if (reaction.reactedByMe) {
          currentReaction = reaction;
          break;
        }
      }
      await _messageActionService.toggleReaction(
        roomId: widget.roomId,
        messageId: message.id,
        emoji: emoji,
        currentReactionEmoji: currentReaction?.emoji,
        userId: userId,
      );
    } catch (error) {
      _setMessageReactionsLocally(message.id, previousReactions);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.chatSendFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  Future<void> _notifyTextMessage(String messageId) async {
    try {
      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        return;
      }
      final response = await Supabase.instance.client.functions.invoke(
        'notify_friend',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'type': 'chat_message',
          'room_id': widget.roomId,
          'message_id': messageId,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        return;
      }
    } catch (_) {
      // Notification delivery should not block chat send success.
    }
  }

  Future<void> _openFeedCamera() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isRoomLocked) {
      await showJuiceToast<void>(
        context: context,
        position: JuicePosition.center,
        message: l10n.roomLockedTitle,
        body: Column(
          children: [
            Text(
              l10n.roomLockedMessage,
              style: GoogleFonts.mPlusRounded1c(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
      return;
    }
    if (widget.isPetDeparted) {
      await showJuiceToast<void>(
        context: context,
        position: JuicePosition.center,
        message: l10n.petDepartureFeedDisabledTitle,
        body: Column(
          children: [
            Text(
              l10n.petDepartureFeedDisabledMessage,
              style: GoogleFonts.mPlusRounded1c(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
      return;
    }

    AnalyticsService.instance.logEvent('feed_camera_open');
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCaptureView(
          roomId: widget.roomId,
          onOptimisticMessage: _handleOptimisticFeed,
          onSendStarted: _handleFeedSendStarted,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _refreshLatest();
    if (!mounted) {
      return;
    }
    if (_shouldExitAfterFeedSend) {
      _shouldExitAfterFeedSend = false;
      unawaited(Navigator.of(context).maybePop());
    }
  }

  void _handleFeedSendStarted(FeedOptimisticMessage entry) {
    _shouldExitAfterFeedSend = true;
    widget.onFeedSendStarted?.call(entry);
  }

  Future<void> _ensureLatestWindowForCompose() async {
    if (!_isHistoryMode && _pendingLiveMessageCount == 0) {
      return;
    }
    await _refreshLatest(resetWindow: true);
    if (!mounted) {
      return;
    }
    _scheduleViewportSync(stickToLatest: true, animated: false);
  }

  Future<void> _handleJumpToLatestPressed() async {
    // If the composer is focused (keyboard is open), we want to keep it
    // focused through the jump so the keyboard does not close mid-animation.
    final composerWasFocused = _composerFocusNode.hasFocus;
    _isAnimatingExplicitLatest = true;
    _needsLatestCorrectionAfterAnimation = false;
    try {
      final page = await _fetchMessagePage();
      if (!mounted) {
        _isAnimatingExplicitLatest = false;
        return;
      }
      _historyGroupingBoundaryMessageId = null;
      _window.transitionToLatest(
        page.messages,
        hasMoreOlder: page.hasMoreOlder,
      );
      await _applyWindowToChat(animated: false);
      unawaited(_ensureProfilesForMessages(_messages));
      unawaited(_ensureReplyPreviewsForMessages(_messages));
      unawaited(_ensureReactionSummariesForMessages(_messages));
      if (!mounted) {
        _isAnimatingExplicitLatest = false;
        return;
      }
      // Re-request focus if the composer was focused before tapping the
      // button. Some gesture paths (translucent GestureDetector unfocus)
      // can dismiss the keyboard as a side-effect of the pill tap.
      if (composerWasFocused && !_composerFocusNode.hasFocus) {
        _restoreComposerFocusAfterLatestJump();
      }
      setState(() => _error = null);
      _scheduleExplicitLatestAnimation(
        reuseExistingLock: true,
        onSettled: () async {
          _historyGroupingBoundaryMessageId = null;
          _window.replaceWithLatest(
            page.messages,
            hasMoreOlder: page.hasMoreOlder,
          );
          await _applyWindowToChat(animated: false);
          unawaited(_persistCache());
          unawaited(_captureMemorySnapshot(source: 'chat_latest_window_reset'));
          if (!mounted) {
            return;
          }
          if (composerWasFocused) {
            _restoreComposerFocusAfterLatestJump();
          }
          _scheduleViewportSync(
            stickToLatest: true,
            animated: false,
            followUpFrames: 1,
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        _isAnimatingExplicitLatest = false;
        return;
      }
      _isAnimatingExplicitLatest = false;
      _needsLatestCorrectionAfterAnimation = false;
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.chatRefreshFailed(userFacingError(context, error));
      });
    }
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
    if (_optimisticIds.contains(entry.tempId)) {
      return;
    }
    _optimisticFeedImageByTempId[entry.tempId] = entry.localImagePath;
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
    unawaited(() async {
      await _ensureLatestWindowForCompose();
      if (!mounted) {
        return;
      }
      await _insertMessage(
        optimisticMessage,
        animated: true,
        isOptimistic: true,
        scrollToLatest: true,
      );
    }());
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    _optimisticFeedImageByTempId.remove(result.tempId);
    unawaited(ReviewPromptService.instance.onFeedCompletedSuccessfully());
    if (!mounted) {
      return;
    }
    unawaited(_removeMessageById(result.tempId, animated: false));
    unawaited(_refreshLatest(resetWindow: true));
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    _optimisticFeedImageByTempId.remove(tempId);
    if (!mounted) {
      return;
    }
    unawaited(_removeMessageById(tempId, animated: false));
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

  void _handleFeedUploadQueueTransition(
    FeedUploadQueueState? previous,
    FeedUploadQueueState next,
  ) {
    for (final event in FeedUploadQueueEvents.between(previous, next)) {
      if (event.job.roomId != widget.roomId) {
        continue;
      }
      switch (event) {
        case FeedUploadOptimisticReady():
          _handleOptimisticFeed(event.job.toOptimisticMessage());
        case FeedUploadCompleted():
          _handleFeedUploadCompleted(event.result);
        case FeedUploadFailed():
          _handleFeedUploadFailed(event.job.tempId, event.error);
      }
    }
  }

  Future<void> _jumpToReplySource(ChatMessage message) async {
    final targetId = message.replyToMessageId;
    if (targetId == null || targetId.isEmpty) {
      return;
    }

    var attempts = 0;
    while (!_messagesById.containsKey(targetId) && _hasMore && attempts < 5) {
      attempts += 1;
      await _loadMore();
    }

    if (!_messagesById.containsKey(targetId) && _isHistoryMode) {
      await _refreshLatest(resetWindow: true);
    }

    if (!_messagesById.containsKey(targetId)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatNoOlderMessages),
        ),
      );
      return;
    }

    final targetKey = _messageAnchorKey(targetId);
    if (!await _animateReplyTargetToCenter(
      targetKey,
      duration: _replyJumpDuration,
      curve: _replyJumpCurve,
    )) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _highlightedMessageId = targetId);
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || _highlightedMessageId != targetId) {
        return;
      }
      setState(() => _highlightedMessageId = null);
    });
  }

  Future<bool> _animateReplyTargetToCenter(
    GlobalKey targetKey, {
    required Duration duration,
    required Curve curve,
  }) async {
    for (
      var i = 0;
      (!_chatScrollController.hasClients || targetKey.currentContext == null) &&
          i < 4;
      i += 1
    ) {
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!_chatScrollController.hasClients) {
      return false;
    }
    final position = _chatScrollController.position;
    final targetOffset = _replyTargetCenterOffset(targetKey);
    if (targetOffset == null) {
      return false;
    }
    if ((position.pixels - targetOffset).abs() <= 1) {
      return true;
    }
    await _chatScrollController.animateTo(
      targetOffset,
      duration: duration,
      curve: curve,
    );
    return true;
  }

  Widget _buildMessageActionPreview(ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    final presentation = _previewPresentationForMessage(message);
    final resolvedReplyPreview = _resolvedReplyPreview(message);
    final replyTap = message.replyToMessageId == null
        ? null
        : () => _jumpToReplySource(message);
    final previewMessage = PetChatMessageAdapter.toUiMessage(message, l10n);

    if (previewMessage is fc.CustomMessage) {
      return _FeedCard(
        surfaceKey: GlobalKey(
          debugLabel: 'message-action-preview-${message.id}',
        ),
        message: previewMessage,
        isMe: presentation.isSentByMe,
        isGroupedWithPrevious: presentation.isGroupedWithPrevious,
        isGroupedWithNext: presentation.isGroupedWithNext,
        isDarkBackground: widget.isDarkBackground,
        isHighlighted: false,
        senderName: _displayNameForSenderId(message.senderId),
        showSenderName: presentation.showSenderName,
        replyPreview: resolvedReplyPreview,
        replySenderName: _displayNameForSenderId(
          resolvedReplyPreview?.senderId,
        ),
        onReplyTap: replyTap,
        onTapImage: () {},
      );
    }

    return _MessageActionTextPreviewBubble(
      message: message,
      isSentByMe: presentation.isSentByMe,
      isGroupedWithPrevious: presentation.isGroupedWithPrevious,
      isGroupedWithNext: presentation.isGroupedWithNext,
      isDarkBackground: widget.isDarkBackground,
      senderName: _displayNameForSenderId(message.senderId),
      showSenderName: presentation.showSenderName,
      replyPreview: resolvedReplyPreview,
      replySenderName: _displayNameForSenderId(resolvedReplyPreview?.senderId),
      onReplyTap: replyTap,
    );
  }

  void _handleDeterministicMessageLongPress(
    fc.Message message,
    LongPressStartDetails details,
  ) {
    final domainMessage = _messagesById[message.id];
    if (domainMessage == null ||
        domainMessage.isSystem ||
        domainMessage.isDeleted ||
        domainMessage.senderId == null) {
      return;
    }
    unawaited(_showMessageActions(domainMessage, details: details));
  }

  fc.ChatTheme _chatTheme(BuildContext context) {
    final base = fc.ChatTheme.fromThemeData(Theme.of(context));
    return base.copyWith(
      colors: base.colors.copyWith(
        primary: AppTheme.primaryColor,
        onPrimary: Colors.white,
        surface: widget.backgroundDecoration == null
            ? (widget.isDarkBackground
                  ? const Color(0xFF111111)
                  : AppTheme.backgroundColor)
            : Colors.transparent,
        onSurface: widget.isDarkBackground
            ? Colors.white
            : AppTheme.textPrimary,
        surfaceContainer: widget.isDarkBackground
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.88),
        surfaceContainerLow: widget.isDarkBackground
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.72),
        surfaceContainerHigh: widget.isDarkBackground
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF1ECE4),
      ),
      shape: BorderRadius.circular(18),
    );
  }

  Future<fc.User?> _resolveUser(String id) async {
    if (id == PetChatMessageAdapter.systemAuthorId) {
      return fc.User(id: id, name: widget.petName ?? 'System');
    }
    if (id == _currentUserId) {
      return fc.User(
        id: id,
        name: AppLocalizations.of(context)!.chatRoomMemberYou,
      );
    }
    final cached = _profilesById[id];
    if (cached != null) {
      return fc.User(
        id: id,
        name: cached.nickname,
        imageSource: cached.avatarUrl,
      );
    }
    final profile = await ProfileCacheService.instance.getProfile(id);
    if (profile != null && mounted) {
      _profilesById[id] = profile;
      setState(() {});
    }
    return fc.User(
      id: id,
      name: profile?.nickname,
      imageSource: profile?.avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FeedUploadQueueState>(
      feedUploadQueueProvider,
      _handleFeedUploadQueueTransition,
    );
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    _lastKnownViewInsetBottom = media.viewInsets.bottom;
    final uiScale = appUiScale(media.size.width);
    final topBarHeight = _resolvedTopBarHeight(media);
    final listTopPadding = _resolvedListTopPadding(media);
    final composerBottomInset = _resolvedComposerBottomInset(media);
    final listBottomPadding = _resolvedListBottomPadding(media);
    final scaffoldBackground =
        widget.backgroundDecoration?.color ??
        (widget.isDarkBackground
            ? const Color(0xFF111111)
            : AppTheme.backgroundColor);
    final replyTarget = _replyTargetMessageId == null
        ? null
        : _messagesById[_replyTargetMessageId!];

    final overlayStyle = AppStatusBarStyles.forBackground(
      isDark: widget.isDarkBackground,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: scaffoldBackground,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: _buildChatAppBar(
          context,
          l10n,
          uiScale,
          topBarHeight,
          overlayStyle,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration:
                    widget.backgroundDecoration ??
                    BoxDecoration(color: scaffoldBackground),
              ),
            ),
            Positioned.fill(
              child: ChatBackSwipePopLayer(
                excludedRegionKey: _composerInteractionRegionKey,
                onPop: () => Navigator.of(context).maybePop(),
                child: ChatKeyboardSweepDismissLayer(
                  focusNode: _composerFocusNode,
                  keyboardInset: media.viewInsets.bottom,
                  composerKey: _composerSurfaceKey,
                  protectedRegionKey: _composerInputRegionKey,
                  child: Chat(
                    currentUserId: _currentUserId,
                    resolveUser: _resolveUser,
                    chatController: _chatController,
                    decoration: null,
                    backgroundColor: Colors.transparent,
                    theme: _chatTheme(context),
                    onMessageSend: _sending ? null : _handleSendMessage,
                    onAttachmentTap: (_sending || widget.isRoomLocked)
                        ? null
                        : _openFeedCamera,
                    builders: _chatMessageBuilders(
                      l10n,
                      media,
                      composerBottomInset,
                      listTopPadding,
                      listBottomPadding,
                      replyTarget,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: media.padding.top + topBarHeight + 6,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _loadingMore
                        ? _ChatHistoryLoadingOverlay(
                            key: const ValueKey('chatHistoryLoadOverlay'),
                            label: l10n.chatLoadOlderMessages,
                            isDarkBackground: widget.isDarkBackground,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            if (_shouldShowJumpToLatestButton)
              Positioned(
                right: 16,
                bottom: composerBottomInset + _composerHeight + 16,
                child: _JumpToLatestPill(
                  key: _jumpToLatestPillKey,
                  label: l10n.chatJumpToLatest,
                  pendingCount: _pendingLiveMessageCount,
                  isDarkBackground: widget.isDarkBackground,
                  onTap: () => unawaited(_handleJumpToLatestPressed()),
                ),
              ),
            if (_mentionSuggestions.isNotEmpty)
              Positioned(
                left: 68,
                right: 68,
                bottom: composerBottomInset + _composerHeight + 8,
                child: _MentionSuggestionsPanel(
                  candidates: List<ChatMentionCandidate>.unmodifiable(
                    _mentionSuggestions,
                  ),
                  isDarkBackground: widget.isDarkBackground,
                  onSelected: _selectMentionCandidate,
                ),
              ),
            if (_loading)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (_error != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: media.padding.bottom + 16,
                child: IgnorePointer(
                  ignoring: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFeedViewer(ChatMessage? message) {
    if (message == null) {
      return;
    }
    final localPath = message.localImagePath?.trim();
    final remoteUrl = (message.imageUrl ?? '').trim();
    if (remoteUrl.isEmpty && (localPath == null || localPath.isEmpty)) {
      return;
    }

    FullScreenPhotoViewer.open(
      context,
      items: [
        PhotoViewerItem(
          imageUrl: remoteUrl,
          localImagePath: localPath,
          caption: (message.caption ?? '').trim().isEmpty
              ? null
              : message.caption,
          senderName: _displayNameForSenderId(message.senderId),
          sentAt: message.createdAt,
          roomId: widget.roomId,
          messageId: message.id,
          selectedReactionEmoji: _selectedReactionEmoji(message),
        ),
      ],
      showIndicator: false,
      onSendReply: (item, text) => _messageActionService.sendTextReply(
        roomId: item.roomId!,
        replyToMessageId: item.messageId!,
        text: text,
      ),
      onToggleReaction: (item, emoji, currentReactionEmoji) =>
          _messageActionService.toggleReaction(
            roomId: item.roomId!,
            messageId: item.messageId!,
            emoji: emoji,
            currentReactionEmoji: currentReactionEmoji,
          ),
    );
    unawaited(
      _captureMemorySnapshot(
        source: 'chat_fullscreen_viewer_open',
        fullscreenProviderType: localPath != null && localPath.isNotEmpty
            ? 'FileImage'
            : 'CachedNetworkImageProvider',
        fullscreenItemCount: 1,
      ),
    );
  }
}
