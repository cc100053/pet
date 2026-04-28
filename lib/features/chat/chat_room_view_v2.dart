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

  Future<void> _removeRealtimeChannel(RealtimeChannel? channel) async {
    if (channel == null) {
      return;
    }
    try {
      await Supabase.instance.client.removeChannel(channel);
    } catch (_) {
      try {
        await channel.unsubscribe();
      } catch (_) {
        // Best-effort cleanup; route disposal must not fail user flows.
      }
    }
  }

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

  Future<void> _persistCache() async {
    if (!_repository.isReady || !_window.isLiveMode) {
      return;
    }
    final cacheable = _window.latestVisibleCanonicalSlice(
      includeMessage: (message) => !_optimisticIds.contains(message.id),
    );
    await _repository.cacheMessages(widget.roomId, cacheable);
  }

  List<ChatMessage> _toAscendingMessages(List<ChatMessage> messages) {
    final filtered = messages.where(_isVisibleMessage).toList();
    filtered.sort(_sortByCreatedAtAsc);
    return filtered;
  }

  bool _isVisibleMessage(ChatMessage message) {
    final senderId = message.senderId;
    return senderId == null || !_blockedUserIds.contains(senderId);
  }

  Future<_FetchedMessagePage> _fetchMessagePage({
    String? beforeCreatedAt,
    String? beforeId,
  }) async {
    final page = await _repository.fetchMessages(
      roomId: widget.roomId,
      beforeCreatedAt: beforeCreatedAt,
      beforeId: beforeId,
      limit: _pageSize,
    );
    return _FetchedMessagePage(
      messages: page.where(_isVisibleMessage).toList()
        ..sort(_sortByCreatedAtAsc),
      hasMoreOlder: page.length == _pageSize,
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

  ChatReplyPreview? _resolvedReplyPreview(ChatMessage message) {
    final preview = message.replyPreview;
    if (preview != null && preview.id.isNotEmpty) {
      return preview;
    }

    final replyId = message.replyToMessageId;
    if (replyId == null || replyId.isEmpty) {
      return null;
    }
    final target = _messagesById[replyId];
    if (target != null) {
      return ChatReplyPreview.fromMessage(target);
    }
    return null;
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

  bool _sameReactions(
    List<ChatMessageReactionSummary> a,
    List<ChatMessageReactionSummary> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index += 1) {
      final left = a[index];
      final right = b[index];
      if (left.emoji != right.emoji ||
          left.count != right.count ||
          left.reactedByMe != right.reactedByMe) {
        return false;
      }
    }
    return true;
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

  bool _isRealtimeGenerationActive(int generation) {
    return mounted && generation == _realtimeGeneration;
  }

  Future<Map<String, ChatReplyPreview>> _fetchReplyPreviewMap(
    Set<String> replyIds,
  ) async {
    final response = await Supabase.instance.client
        .from('messages')
        .select(
          'id,sender_id,type,body,image_url,caption,deleted_at,deleted_by',
        )
        .filter('id', 'in', '(${replyIds.join(',')})');
    final rows = response as List<dynamic>;
    final previewById = <String, ChatReplyPreview>{};
    for (final row in rows) {
      final preview = ChatReplyPreview.fromJson(Map<String, dynamic>.from(row));
      if (preview.id.isNotEmpty) {
        previewById[preview.id] = preview;
      }
    }
    return previewById;
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

  String? _findMatchingOptimisticMessageId(ChatMessage incoming) {
    for (final message in _messages) {
      if (!_optimisticIds.contains(message.id)) {
        continue;
      }
      if (message.senderId != incoming.senderId) {
        continue;
      }
      if (message.type == 'image_feed' && incoming.type == 'image_feed') {
        final optimisticClient = message.clientCreatedAt;
        if (optimisticClient != null &&
            matchesFeedIdentity(
              expectedRoomId: message.roomId,
              expectedSenderId: message.senderId,
              expectedCaption: message.caption,
              expectedClientCreatedAt: optimisticClient,
              roomId: incoming.roomId,
              senderId: incoming.senderId,
              caption: incoming.caption,
              messageId: incoming.id,
              clientCreatedAt: incoming.clientCreatedAt,
              createdAt: incoming.createdAt,
            )) {
          return message.id;
        }
      }
      final sameText = message.body == incoming.body;
      final sameReply = message.replyToMessageId == incoming.replyToMessageId;
      if (sameText && sameReply) {
        return message.id;
      }
    }
    return null;
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

  List<fc.Message> _toUiMessages(List<ChatMessage> messages) {
    final l10n = AppLocalizations.of(context)!;
    return messages
        .map(
          (message) => PetChatMessageAdapter.toUiMessage(
            message,
            l10n,
            isOptimistic: _optimisticIds.contains(message.id),
          ),
        )
        .toList();
  }

  fc.Message _toUiMessage(ChatMessage message) {
    return PetChatMessageAdapter.toUiMessage(
      message,
      AppLocalizations.of(context)!,
      isOptimistic: _optimisticIds.contains(message.id),
    );
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

  bool _sameMentionState(
    ChatMentionToken? token,
    List<ChatMentionCandidate> suggestions,
  ) {
    final currentToken = _activeMentionToken;
    if ((currentToken == null) != (token == null)) {
      return false;
    }
    if (currentToken != null && token != null) {
      if (currentToken.start != token.start ||
          currentToken.end != token.end ||
          currentToken.query != token.query) {
        return false;
      }
    }
    if (_mentionSuggestions.length != suggestions.length) {
      return false;
    }
    for (var index = 0; index < suggestions.length; index += 1) {
      if (_mentionSuggestions[index].userId != suggestions[index].userId ||
          _mentionSuggestions[index].displayName !=
              suggestions[index].displayName) {
        return false;
      }
    }
    return true;
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

  void _requestReply(ChatMessage message) {
    setState(() => _replyTargetMessageId = message.id);
    _composerFocusNode.requestFocus();
  }

  String? _copyTextForMessage(ChatMessage message) {
    if (message.isDeleted) {
      return null;
    }
    if ((message.body ?? '').trim().isNotEmpty) {
      return message.body!.trim();
    }
    if ((message.caption ?? '').trim().isNotEmpty) {
      return message.caption!.trim();
    }
    return null;
  }

  Future<String?> _promptEditMessageText(ChatMessage message) async {
    final controller = TextEditingController(text: (message.body ?? '').trim());
    final l10n = AppLocalizations.of(context)!;
    final originalText = controller.text.trim();
    String? errorText;
    final result = await showJuiceToast<String>(
      context: context,
      position: JuicePosition.center,
      tone: AppDialogTone.info,
      message: l10n.chatEditMessageTitle,
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final text = controller.text.trim();
            if (text.isEmpty) {
              setDialogState(() {
                errorText = l10n.chatMessageHint;
              });
              return;
            }
            if (text == originalText) {
              setDialogState(() {
                errorText = l10n.chatEditNoChanges;
              });
              return;
            }
            final navigator = Navigator.of(context);
            Future<void>.microtask(() => navigator.pop(text));
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('chatEditMessageTextField'),
                controller: controller,
                autofocus: true,
                onTapOutside: dismissKeyboardOnTapOutside,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 4,
                style: GoogleFonts.mPlusRounded1c(),
                decoration: InputDecoration(
                  hintText: l10n.chatMessageHint,
                  errorText: errorText,
                  hintStyle: GoogleFonts.mPlusRounded1c(color: Colors.black26),
                ),
                onSubmitted: (_) => submit(),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: () {
                        final navigator = Navigator.of(context);
                        Future<void>.microtask(navigator.pop);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonCancel,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: submit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonSave,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 350)).then((_) {
        controller.dispose();
      }),
    );
    return result;
  }

  Future<bool> _confirmDeleteMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showJuiceToast<bool>(
      context: context,
      position: JuicePosition.center,
      tone: AppDialogTone.danger,
      message: l10n.chatDeleteMessageTitle,
      body: Builder(
        builder: (dialogContext) {
          void close(bool value) {
            final navigator = Navigator.of(dialogContext);
            Future<void>.microtask(() => navigator.pop(value));
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chatDeleteMessageConfirm,
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: JuicyScaleButton(
                      onTap: () => close(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            l10n.commonCancel,
                            style: GoogleFonts.mPlusRounded1c(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: JuicyScaleButton(
                      key: const ValueKey('chatDeleteMessageConfirmButton'),
                      onTap: () => close(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            l10n.chatDeleteAction,
                            style: GoogleFonts.mPlusRounded1c(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return result == true;
  }

  Future<void> _editMessage(ChatMessage message) async {
    if (message.isDeleted || message.type != 'text') {
      return;
    }
    final text = await _promptEditMessageText(message);
    if (!mounted || text == null || text.trim().isEmpty) {
      return;
    }

    final previous = _messagesById[message.id] ?? message;
    final optimistic = previous.copyWith(
      body: text.trim(),
      editedAt: DateTime.now().toUtc(),
    );
    await _replaceMessageLocally(optimistic, animated: false);

    try {
      final updated =
          ChatMessage.fromJson(
            await _messageActionService.editTextMessageRow(
              roomId: widget.roomId,
              messageId: message.id,
              text: text,
            ),
          ).copyWith(
            reactions: previous.reactions,
            replyPreview: previous.replyPreview,
          );
      await _replaceMessageLocally(updated, animated: false);
    } catch (error) {
      await _replaceMessageLocally(previous, animated: false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.chatEditFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    if (message.isDeleted || message.type != 'text') {
      return;
    }
    if (!await _confirmDeleteMessage() || !mounted) {
      return;
    }

    final userId =
        _runtime?.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    final previous = _messagesById[message.id] ?? message;
    final optimistic = previous.copyWith(
      clearBody: true,
      deletedAt: DateTime.now().toUtc(),
      deletedBy: userId,
      reactions: const <ChatMessageReactionSummary>[],
    );
    await _replaceMessageLocally(optimistic, animated: false);

    try {
      final updated =
          ChatMessage.fromJson(
            await _messageActionService.deleteTextMessageRow(
              roomId: widget.roomId,
              messageId: message.id,
            ),
          ).copyWith(
            reactions: const <ChatMessageReactionSummary>[],
            replyPreview: previous.replyPreview,
          );
      await _replaceMessageLocally(updated, animated: false);
    } catch (error) {
      await _replaceMessageLocally(previous, animated: false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.chatDeleteFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  String? _defaultReactionSheetFilterEmoji(
    ChatMessage message, {
    String? preferredEmoji,
  }) {
    final preferred = preferredEmoji?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    final currentReaction = _selectedReactionEmoji(
      _messagesById[message.id] ?? message,
    );
    if (currentReaction != null && currentReaction.isNotEmpty) {
      return currentReaction;
    }
    final reactions = (_messagesById[message.id] ?? message).reactions;
    if (reactions.isNotEmpty) {
      return reactions.first.emoji;
    }
    return null;
  }

  Future<void> _primeProfilesForReactionUserIds(
    Iterable<String> userIds,
  ) async {
    final idsToLoad = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && !_profilesById.containsKey(id))
        .toSet();
    if (idsToLoad.isEmpty) {
      return;
    }
    try {
      final profiles = await ProfileCacheService.instance.getProfiles(
        idsToLoad,
      );
      for (final entry in profiles.entries) {
        _profilesById[entry.key] = entry.value;
      }
    } catch (_) {
      // Best-effort reaction profile loading.
    }
  }

  Future<List<ChatReactionDetailsSheetEntry>> _loadReactionSheetEntries(
    String messageId,
  ) async {
    final details = await _repository.fetchReactionDetails(
      roomId: widget.roomId,
      messageId: messageId,
    );
    await _primeProfilesForReactionUserIds(
      details.map((detail) => detail.userId),
    );
    if (!mounted) {
      return const <ChatReactionDetailsSheetEntry>[];
    }
    final l10n = AppLocalizations.of(context)!;
    return details
        .map((detail) {
          final isCurrentUser = detail.userId == _currentUserId;
          final profile = _profilesById[detail.userId];
          final nickname = profile?.nickname?.trim();
          final displayName = isCurrentUser
              ? l10n.chatRoomMemberYou
              : ((nickname != null && nickname.isNotEmpty)
                    ? nickname
                    : l10n.chatPartnerLabel);
          return ChatReactionDetailsSheetEntry(
            userId: detail.userId,
            displayName: displayName,
            emoji: detail.emoji,
            createdAt: detail.createdAt,
            avatarUrl: profile?.avatarUrl,
            isCurrentUser: isCurrentUser,
          );
        })
        .toList(growable: false);
  }

  Future<ChatReactionDetailsSheetUpdate?> _toggleReactionFromSheet(
    ChatMessage message,
    String emoji,
  ) async {
    final currentMessage = _messagesById[message.id] ?? message;
    await _toggleReaction(currentMessage, emoji);
    if (!mounted) {
      return null;
    }

    try {
      final entries = await _loadReactionSheetEntries(message.id);
      if (!mounted) {
        return null;
      }
      return ChatReactionDetailsSheetUpdate(
        entries: entries,
        selectedReactionEmoji: _selectedReactionEmoji(
          _messagesById[message.id] ?? currentMessage,
        ),
      );
    } catch (_) {
      return ChatReactionDetailsSheetUpdate(
        entries: const <ChatReactionDetailsSheetEntry>[],
        selectedReactionEmoji: _selectedReactionEmoji(
          _messagesById[message.id] ?? currentMessage,
        ),
      );
    }
  }

  Future<void> _showMessageActions(
    ChatMessage message, {
    LongPressStartDetails? details,
  }) async {
    final senderId = message.senderId;
    if (_currentUserId == '__anonymous__' ||
        senderId == null ||
        message.isDeleted) {
      return;
    }

    final isMine = senderId == _currentUserId;
    final canEditDelete = isMine && message.type == 'text';
    final isBlocked = _blockedUserIds.contains(senderId);
    final copyText = _copyTextForMessage(message);
    ChatMessageReactionSummary? myReaction;
    for (final reaction in message.reactions) {
      if (reaction.reactedByMe) {
        myReaction = reaction;
        break;
      }
    }
    final anchor = _buildMessageActionSheetAnchor(
      message,
      details: details,
      isMine: isMine,
    );
    final preview = _buildMessageActionPreview(message);
    unawaited(_setChatCrashContext(lastAction: 'chat_action_sheet_open'));
    unawaited(
      _captureMemorySnapshot(
        source: 'chat_action_sheet_open',
        note: message.isImageFeed ? 'image_message' : 'text_message',
      ),
    );
    final action = await showGeneralDialog<_MessageActionSelection>(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (dialogContext, _, _) => ChatMessageActionSheet(
        anchor: anchor,
        preview: preview,
        reactionOptions: kChatQuickReactionOptions,
        selectedReaction: myReaction?.emoji,
        copyEnabled: copyText != null,
        editEnabled: canEditDelete,
        deleteEnabled: canEditDelete,
        isMine: isMine,
        isBlocked: isBlocked,
        onReactionSelected: (emoji) => Navigator.pop(
          dialogContext,
          _MessageActionSelection.reaction(emoji),
        ),
        onReply: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.reply),
        ),
        onCopy: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.copy),
        ),
        onEdit: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.edit),
        ),
        onDelete: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.delete),
        ),
        onReport: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.report),
        ),
        onBlock: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.block),
        ),
        onMoreReactions: () => Navigator.pop(
          dialogContext,
          const _MessageActionSelection.action(_MessageAction.moreReactions),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
    unawaited(_setChatCrashContext(lastAction: 'chat_action_sheet_closed'));
    unawaited(
      _captureMemorySnapshot(
        source: 'chat_action_sheet_closed',
        note: action == null ? 'dismissed' : 'selected',
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    final emoji = action.emoji;
    if (emoji != null && emoji.isNotEmpty) {
      await _toggleReaction(message, emoji);
      return;
    }

    switch (action.action) {
      case _MessageAction.reply:
        _requestReply(message);
        break;
      case _MessageAction.copy:
        if (copyText != null) {
          await Clipboard.setData(ClipboardData(text: copyText));
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.chatMessageCopied),
            ),
          );
        }
        break;
      case _MessageAction.edit:
        await _editMessage(message);
        break;
      case _MessageAction.delete:
        await _deleteMessage(message);
        break;
      case _MessageAction.report:
        await _reportMessage(message);
        break;
      case _MessageAction.block:
        await _blockUser(senderId);
        break;
      case _MessageAction.moreReactions:
        final selectedEmoji = await showChatEmojiPickerSheet(
          context,
          selectedEmoji: myReaction?.emoji,
        );
        if (!mounted || selectedEmoji == null || selectedEmoji.isEmpty) {
          return;
        }
        await _toggleReaction(message, selectedEmoji);
        break;
      case null:
        break;
    }
  }

  Future<void> _showReactionDetailsSheet(
    ChatMessage message, {
    String? initialFilterEmoji,
  }) async {
    final senderId = message.senderId;
    if (_currentUserId == '__anonymous__' || senderId == null) {
      return;
    }

    List<ChatReactionDetailsSheetEntry> entries;
    try {
      entries = await _loadReactionSheetEntries(message.id);
    } catch (_) {
      entries = const <ChatReactionDetailsSheetEntry>[];
    }

    if (!mounted) {
      return;
    }

    unawaited(_setChatCrashContext(lastAction: 'chat_reaction_sheet_open'));
    unawaited(
      _captureMemorySnapshot(
        source: 'chat_reaction_sheet_open',
        note: message.isImageFeed ? 'image_message' : 'text_message',
      ),
    );
    final action = await showModalBottomSheet<ChatReactionDetailsSheetAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatReactionDetailsSheet(
        reactionOptions: kChatQuickReactionOptions,
        entries: entries,
        selectedReactionEmoji: _selectedReactionEmoji(
          _messagesById[message.id] ?? message,
        ),
        initialFilterEmoji: _defaultReactionSheetFilterEmoji(
          message,
          preferredEmoji: initialFilterEmoji,
        ),
        copyEnabled: false,
        isMine: false,
        isBlocked: false,
        showMessageActions: false,
        onReactionSelected: (emoji) => _toggleReactionFromSheet(message, emoji),
        onMoreReactions: () async {
          final selectedEmoji = await showChatEmojiPickerSheet(
            context,
            selectedEmoji: _selectedReactionEmoji(
              _messagesById[message.id] ?? message,
            ),
          );
          if (!mounted || selectedEmoji == null || selectedEmoji.isEmpty) {
            return null;
          }
          return _toggleReactionFromSheet(message, selectedEmoji);
        },
      ),
    );
    unawaited(_setChatCrashContext(lastAction: 'chat_reaction_sheet_closed'));
    unawaited(
      _captureMemorySnapshot(
        source: 'chat_reaction_sheet_closed',
        note: action == null ? 'dismissed' : 'selected',
      ),
    );
    if (!mounted || action == null) {
      return;
    }
  }

  Future<void> _reportMessage(ChatMessage message) async {
    final reporterId = Supabase.instance.client.auth.currentUser?.id;
    if (reporterId == null) {
      return;
    }

    final reason = await _promptReportReason(context);
    if (reason == null) {
      return;
    }

    try {
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': reporterId,
        'message_id': message.id,
        'reason': reason,
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatReportSent)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.chatReportFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  Future<void> _blockUser(String blockedUserId) async {
    final blockerId = Supabase.instance.client.auth.currentUser?.id;
    if (blockerId == null) {
      return;
    }

    if (_blockedUserIds.contains(blockedUserId)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatUserAlreadyBlocked),
        ),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('blocks').upsert({
        'blocker_id': blockerId,
        'blocked_user_id': blockedUserId,
      });

      _blockedUserIds.add(blockedUserId);
      final toRemove = _messages
          .where((message) => message.senderId == blockedUserId)
          .map((message) => message.id)
          .toList();
      for (final messageId in toRemove) {
        await _removeMessageById(messageId, animated: false);
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chatUserBlocked)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.chatBlockFailed(userFacingError(context, error)),
          ),
        ),
      );
    }
  }

  Future<void> _openBlockedUsers() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
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

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BlockedUsersSheet(
        currentUserId: currentUserId,
        onBlockListChanged: () => unawaited(_refreshAfterBlockChange()),
      ),
    );

    if (changed == true) {
      await _refreshAfterBlockChange();
    }
  }

  Future<void> _openRoomMembers() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          RoomMembersSheet(roomId: widget.roomId, currentUserId: currentUserId),
    );

    if (!mounted) {
      return;
    }
    unawaited(_fetchMemberCount());
  }

  Future<String?> _promptReportReason(BuildContext context) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final result = await showJuiceToast<String>(
      context: context,
      position: JuicePosition.center,
      tone: AppDialogTone.warning,
      message: l10n.chatReportMessageTitle,
      body: Column(
        children: [
          TextField(
            controller: controller,
            onTapOutside: dismissKeyboardOnTapOutside,
            style: GoogleFonts.mPlusRounded1c(),
            decoration: InputDecoration(
              hintText: l10n.chatReportHint,
              hintStyle: GoogleFonts.mPlusRounded1c(color: Colors.black26),
            ),
            maxLines: 3,
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonCancel,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: JuicyScaleButton(
                  onTap: () {
                    final text = controller.text.trim();
                    Navigator.pop(
                      context,
                      text.isEmpty ? l10n.chatReportNoReason : text,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonSubmit,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
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
      setState(() => _showScrollToLatestButton = showJumpButton);
    }

    if (_loadingMore || _loading || !_hasMore) {
      return;
    }
    // In a reversed list, older messages are at the maxScrollExtent.
    if (position.pixels >= position.maxScrollExtent - 120) {
      unawaited(_loadMore());
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
    setState(() => _composerHeight = height);
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

  bool _canGroupPreviewMessages(ChatMessage a, ChatMessage b) {
    if (a.isSystem || b.isSystem) {
      return false;
    }
    final aSender = a.senderId?.trim();
    final bSender = b.senderId?.trim();
    if (aSender == null ||
        aSender.isEmpty ||
        bSender == null ||
        bSender.isEmpty) {
      return false;
    }
    return aSender == bSender && isSameLocalChatDay(a.createdAt, b.createdAt);
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

  double? _replyTargetCenterOffset(GlobalKey targetKey) {
    final targetContext = targetKey.currentContext;
    if (targetContext == null) {
      return null;
    }
    final renderObject = targetContext.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      return null;
    }
    final viewport = RenderAbstractViewport.of(renderObject);
    final position = _chatScrollController.position;
    return viewport
        .getOffsetToReveal(renderObject, 0.5)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
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

  String? _displayNameForSenderId(String? senderId) {
    if (senderId == null || senderId.isEmpty) {
      return null;
    }
    if (senderId == _currentUserId) {
      return AppLocalizations.of(context)!.chatRoomMemberYou;
    }
    final nickname = _profilesById[senderId]?.nickname?.trim();
    if (nickname == null || nickname.isEmpty) {
      return null;
    }
    return nickname;
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: overlayStyle,
          toolbarHeight: topBarHeight,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: _ChatTopBar(
            petName: widget.petName ?? l10n.chatTitle,
            memberCount: _memberCount == null
                ? null
                : l10n.chatMemberCount(_memberCount!),
            uiScale: uiScale,
            useLightForeground: widget.isDarkBackground,
            onBack: () => Navigator.of(context).maybePop(),
            onMembersTap: _openRoomMembers,
            menuButton: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 8),
                position: PopupMenuPosition.under,
                onSelected: (value) {
                  if (value == 'block') {
                    unawaited(_openBlockedUsers());
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.blockedUsersTitle),
                      ],
                    ),
                  ),
                ],
                child: _ChatMenuAvatar(
                  petAssetPath: widget.petAssetPath,
                  uiScale: uiScale,
                ),
              ),
            ),
          ),
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
                    builders: fc.Builders(
                      textMessageBuilder:
                          (
                            context,
                            message,
                            index, {
                            required isSentByMe,
                            groupStatus,
                          }) {
                            final domainMessage = _messagesById[message.id];
                            final resolvedReplyPreview = domainMessage == null
                                ? null
                                : _resolvedReplyPreview(domainMessage);
                            final replyTap =
                                domainMessage == null ||
                                    domainMessage.replyToMessageId == null
                                ? null
                                : () => _jumpToReplySource(domainMessage);
                            return _TelegramTextMessageBubble(
                              surfaceKey: _messageAnchorKey(message.id),
                              message: message,
                              index: index,
                              isSentByMe: isSentByMe,
                              isGroupedWithPrevious:
                                  groupStatus != null && !groupStatus.isFirst,
                              isGroupedWithNext:
                                  groupStatus != null && !groupStatus.isLast,
                              isDarkBackground: widget.isDarkBackground,
                              isHighlighted:
                                  _highlightedMessageId == message.id,
                              senderName: _displayNameForSenderId(
                                _messagesById[message.id]?.senderId,
                              ),
                              showSenderName:
                                  isSentByMe ||
                                  message.id ==
                                      _historyGroupingBoundaryMessageId ||
                                  groupStatus == null ||
                                  groupStatus.isFirst,
                              replyPreview: resolvedReplyPreview,
                              replySenderName: _displayNameForSenderId(
                                resolvedReplyPreview?.senderId,
                              ),
                              mentionCandidates: _mentionCandidates,
                              onReplyTap: replyTap,
                            );
                          },
                      composerBuilder: (context) => _TelegramComposer(
                        controller: _composerController,
                        focusNode: _composerFocusNode,
                        surfaceKey: _composerSurfaceKey,
                        inputRegionKey: _composerInputRegionKey,
                        interactionRegionKey: _composerInteractionRegionKey,
                        keyboardInset: media.viewInsets.bottom,
                        bottomInset: composerBottomInset,
                        hintText: l10n.chatMessageHint,
                        isDarkBackground: widget.isDarkBackground,
                        onHeightChanged: _handleComposerHeightChanged,
                        onAttachmentTap: (_sending || widget.isRoomLocked)
                            ? null
                            : _openFeedCamera,
                        onSend: _sending ? null : _handleSendMessage,
                        replyPreview: replyTarget,
                        replySenderName: replyTarget == null
                            ? null
                            : _displayNameForSenderId(replyTarget.senderId),
                        onCancelReply: replyTarget == null
                            ? null
                            : () {
                                setState(() => _replyTargetMessageId = null);
                              },
                      ),
                      systemMessageBuilder:
                          (
                            context,
                            message,
                            index, {
                            required isSentByMe,
                            groupStatus,
                          }) {
                            return _SystemPill(message: message.text);
                          },
                      customMessageBuilder:
                          (
                            context,
                            message,
                            index, {
                            required isSentByMe,
                            groupStatus,
                          }) {
                            final domainMessage = _messagesById[message.id];
                            final resolvedReplyPreview = domainMessage == null
                                ? null
                                : _resolvedReplyPreview(domainMessage);
                            final replyTap =
                                domainMessage == null ||
                                    domainMessage.replyToMessageId == null
                                ? null
                                : () => _jumpToReplySource(domainMessage);
                            return _FeedCard(
                              surfaceKey: _messageAnchorKey(message.id),
                              message: message,
                              isMe: isSentByMe,
                              isGroupedWithPrevious:
                                  groupStatus != null && !groupStatus.isFirst,
                              isGroupedWithNext:
                                  groupStatus != null && !groupStatus.isLast,
                              isDarkBackground: widget.isDarkBackground,
                              isHighlighted:
                                  _highlightedMessageId == message.id,
                              senderName: _displayNameForSenderId(
                                _messagesById[message.id]?.senderId,
                              ),
                              showSenderName:
                                  isSentByMe ||
                                  message.id ==
                                      _historyGroupingBoundaryMessageId ||
                                  groupStatus == null ||
                                  groupStatus.isFirst,
                              replyPreview: resolvedReplyPreview,
                              replySenderName: _displayNameForSenderId(
                                resolvedReplyPreview?.senderId,
                              ),
                              onReplyTap: replyTap,
                              onTapImage: () =>
                                  _openFeedViewer(_messagesById[message.id]),
                            );
                          },
                      chatMessageBuilder:
                          (
                            context,
                            message,
                            index,
                            animation,
                            child, {
                            isRemoved,
                            required isSentByMe,
                            groupStatus,
                          }) {
                            final domainMessage = _messagesById[message.id];
                            if (domainMessage == null) {
                              return child;
                            }
                            if (domainMessage.isSystem) {
                              return child;
                            }
                            final senderId = domainMessage.senderId;
                            final showReceivedAvatar =
                                !isSentByMe &&
                                senderId != null &&
                                (groupStatus == null || groupStatus.isLast);
                            Widget content = ChatMessageEnvelope(
                              isSentByMe: isSentByMe,
                              isDarkBackground: widget.isDarkBackground,
                              reactions: domainMessage.reactions,
                              isGroupedWithPrevious:
                                  groupStatus != null && !groupStatus.isFirst,
                              isGroupedWithNext:
                                  groupStatus != null && !groupStatus.isLast,
                              avatar: senderId == null
                                  ? null
                                  : _profilesById[senderId]?.avatarUrl,
                              fallbackText: _displayNameForSenderId(senderId),
                              showReceivedAvatar: showReceivedAvatar,
                              onReactionTap: (reaction) {
                                unawaited(
                                  _showReactionDetailsSheet(
                                    domainMessage,
                                    initialFilterEmoji: reaction.emoji,
                                  ),
                                );
                              },
                              child: child,
                            );
                            final canReply = canSwipeReplyToMessage(
                              domainMessage,
                            );
                            if (canReply) {
                              content = ReplySwipeWrapper(
                                onTriggered: () {
                                  HapticFeedback.lightImpact();
                                  _requestReply(domainMessage);
                                },
                                child: content,
                              );
                            }
                            return content;
                          },
                      chatAnimatedListBuilder: (context, itemBuilder) {
                        final uiMessages = _toUiMessages(
                          _messages,
                        ).reversed.toList();
                        if (uiMessages.isEmpty) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleBackdropTapUp(
                              TapUpDetails(kind: PointerDeviceKind.touch),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  l10n.chatEmptyState,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: widget.isDarkBackground
                                            ? Colors.white.withValues(
                                                alpha: 0.84,
                                              )
                                            : AppTheme.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                          );
                        }
                        return DeterministicChatList(
                          itemBuilder: itemBuilder,
                          messages: uiMessages,
                          scrollController: _chatScrollController,
                          observerController: _observerController,
                          topPadding: listTopPadding,
                          bottomPadding: listBottomPadding,
                          onMessageLongPress:
                              _handleDeterministicMessageLongPress,
                          onBackgroundTap: () => _handleBackdropTapUp(
                            TapUpDetails(kind: PointerDeviceKind.touch),
                          ),
                        );
                      },
                      emptyChatListBuilder: (context) =>
                          const SizedBox.shrink(),
                      loadMoreBuilder: (context) => const SizedBox.shrink(),
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

  String? _selectedReactionEmoji(ChatMessage message) {
    for (final reaction in message.reactions) {
      if (reaction.reactedByMe && reaction.emoji.isNotEmpty) {
        return reaction.emoji;
      }
    }
    return null;
  }

  int _sortByCreatedAtAsc(ChatMessage a, ChatMessage b) {
    final createdCompare = a.createdAt.compareTo(b.createdAt);
    if (createdCompare != 0) {
      return createdCompare;
    }
    return a.id.compareTo(b.id);
  }
}

class _FetchedMessagePage {
  const _FetchedMessagePage({
    required this.messages,
    required this.hasMoreOlder,
  });

  final List<ChatMessage> messages;
  final bool hasMoreOlder;
}

class _ChatHistoryLoadingOverlay extends StatelessWidget {
  const _ChatHistoryLoadingOverlay({
    super.key,
    required this.label,
    required this.isDarkBackground,
  });

  final String label;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkBackground
        ? Colors.black.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;
    final spinnerColor = isDarkBackground
        ? Colors.white
        : AppTheme.primaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.1,
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpToLatestPill extends StatelessWidget {
  const _JumpToLatestPill({
    super.key,
    required this.label,
    required this.pendingCount,
    required this.isDarkBackground,
    required this.onTap,
  });

  final String label;
  final int pendingCount;
  final bool isDarkBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkBackground
        ? const Color(0xFF222B35).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textSecondary;
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: TextFieldTapRegion(
        child: InkWell(
          key: const ValueKey('chatJumpToLatestButton'),
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward_rounded, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  key: const ValueKey('chatJumpToLatestLabel'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const ValueKey('chatScrollToLatestPendingCount'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MentionTextMessageBubble extends StatelessWidget {
  const _MentionTextMessageBubble({
    required this.message,
    required this.constraints,
    required this.borderRadius,
    required this.backgroundColor,
    required this.padding,
    required this.textSpans,
    required this.timeStyle,
    required this.isEdited,
    this.topWidget,
  });

  final fc.TextMessage message;
  final BoxConstraints constraints;
  final BorderRadiusGeometry borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final List<InlineSpan> textSpans;
  final TextStyle? timeStyle;
  final bool isEdited;
  final Widget? topWidget;

  @override
  Widget build(BuildContext context) {
    final bubbleTime = _formatBubbleTime(context, message.resolvedTime);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        constraints: constraints,
        decoration: BoxDecoration(color: backgroundColor),
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?topWidget,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: RichText(
                    key: ValueKey<String>('chatMentionRichText_${message.id}'),
                    text: TextSpan(children: textSpans),
                  ),
                ),
                if (bubbleTime != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEdited) ...[
                          Text(
                            AppLocalizations.of(context)!.chatMessageEdited,
                            style: timeStyle,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(bubbleTime, style: timeStyle),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MentionSuggestionsPanel extends StatelessWidget {
  const _MentionSuggestionsPanel({
    required this.candidates,
    required this.isDarkBackground,
    required this.onSelected,
  });

  final List<ChatMentionCandidate> candidates;
  final bool isDarkBackground;
  final ValueChanged<ChatMentionCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkBackground
        ? const Color(0xFF202833).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.98);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;
    final subTextColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.58)
        : AppTheme.textSecondary;

    return TextFieldTapRegion(
      child: Material(
        key: const ValueKey('chatMentionSuggestionsPanel'),
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 184),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: candidates.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              return InkWell(
                key: ValueKey<String>(
                  'chatMentionSuggestion_${candidate.userId}',
                ),
                onTap: () => onSelected(candidate),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        avatar: candidate.avatarUrl,
                        fallbackText: candidate.displayName,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              candidate.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              candidate.mentionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: subTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TelegramComposer extends StatefulWidget {
  const _TelegramComposer({
    required this.controller,
    required this.focusNode,
    required this.surfaceKey,
    required this.inputRegionKey,
    required this.interactionRegionKey,
    required this.keyboardInset,
    required this.bottomInset,
    required this.hintText,
    required this.isDarkBackground,
    required this.onHeightChanged,
    required this.onSend,
    this.onAttachmentTap,
    this.replyPreview,
    this.replySenderName,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey surfaceKey;
  final GlobalKey inputRegionKey;
  final GlobalKey interactionRegionKey;
  final double keyboardInset;
  final double bottomInset;
  final String hintText;
  final bool isDarkBackground;
  final ValueChanged<double> onHeightChanged;
  final Future<void> Function(String text)? onSend;
  final VoidCallback? onAttachmentTap;
  final ChatMessage? replyPreview;
  final String? replySenderName;
  final VoidCallback? onCancelReply;

  @override
  State<_TelegramComposer> createState() => _TelegramComposerState();
}

class _TelegramComposerState extends State<_TelegramComposer> {
  final GlobalKey _measureKey = GlobalKey();
  bool _measureScheduled = false;

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _scheduleComposerMeasure();
  }

  @override
  void didUpdateWidget(covariant _TelegramComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    if (oldWidget.replyPreview != widget.replyPreview ||
        oldWidget.replySenderName != widget.replySenderName ||
        oldWidget.isDarkBackground != widget.isDarkBackground) {
      _scheduleComposerMeasure();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _scheduleComposerMeasure();
  }

  void _scheduleComposerMeasure() {
    if (!mounted || _measureScheduled) {
      return;
    }
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measureComposer();
    });
  }

  void _measureComposer() {
    if (!mounted) {
      return;
    }
    final renderBox =
        _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    widget.onHeightChanged(renderBox.size.height);
  }

  Future<void> _handleSend() async {
    if (widget.onSend == null) {
      return;
    }
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.controller.clear();
    await widget.onSend!(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkBackground;
    final canSend = _hasText && widget.onSend != null;
    final inputColor = isDark
        ? const Color(0xFF2C3440).withValues(alpha: 0.86)
        : const Color(0xFFF1F5F9);
    final attachmentSurface = isDark
        ? const Color(0xFF252D38).withValues(alpha: 0.84)
        : const Color(0xFFF5F7FB);
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : AppTheme.textSecondary.withValues(alpha: 0.9);
    final attachmentIconColor = isDark
        ? Colors.white.withValues(alpha: 0.86)
        : AppTheme.textSecondary;
    final darkPillBorder = Colors.white.withValues(alpha: 0.08);
    final darkPillShadow = Colors.black.withValues(alpha: 0.28);
    final replySenderLabel = widget.replySenderName?.trim().isNotEmpty == true
        ? widget.replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;

    return Positioned(
      left: 12,
      right: 12,
      bottom: widget.bottomInset,
      child: ChatComposerDismissShell(
        focusNode: widget.focusNode,
        keyboardInset: widget.keyboardInset,
        contentKey: widget.interactionRegionKey,
        handleKey: const ValueKey('chatComposerDismissHandle'),
        child: Padding(
          key: _measureKey,
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ComposerActionButton(
                backgroundColor: attachmentSurface,
                iconColor: attachmentIconColor,
                tooltip: AppLocalizations.of(context)!.feedTitle,
                onTap: widget.onAttachmentTap,
                isDarkBackground: isDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  key: widget.surfaceKey,
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: inputColor,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark ? Border.all(color: darkPillBorder) : null,
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: darkPillShadow,
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.replyPreview != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ChatReplyPreviewPanel(
                                  key: const ValueKey(
                                    'chatComposerReplyPreview',
                                  ),
                                  senderName: replySenderLabel,
                                  previewText:
                                      PetChatMessageAdapter.previewTextForMessage(
                                        widget.replyPreview!,
                                        AppLocalizations.of(context)!,
                                      ),
                                  accentColor: AppTheme.primaryColor,
                                  senderColor: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  previewTextColor: isDark
                                      ? Colors.white.withValues(alpha: 0.66)
                                      : AppTheme.textSecondary,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppTheme.primaryColor.withValues(
                                          alpha: 0.07,
                                        ),
                                  iconColor: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppTheme.textSecondary,
                                  isImage: widget.replyPreview!.isImageFeed,
                                  compact: true,
                                  maxLines: 1,
                                  padding: const EdgeInsets.fromLTRB(
                                    9,
                                    6,
                                    9,
                                    6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                onPressed: widget.onCancelReply,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.74)
                                      : AppTheme.textSecondary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                splashRadius: 14,
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.commonCancel,
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              key: widget.inputRegionKey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: TextField(
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                key: const ValueKey('chatComposerTextField'),
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 4,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: textColor,
                                ),
                                cursorColor: AppTheme.primaryColor,
                                decoration: InputDecoration(
                                  hintText: widget.hintText,
                                  hintStyle: TextStyle(
                                    color: hintColor,
                                    fontSize: 15,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  filled: true,
                                  counterText: '',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ComposerSendButton(
                enabled: canSend,
                onTap: canSend ? _handleSend : null,
                isDarkBackground: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  const _ComposerActionButton({
    required this.backgroundColor,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
    this.isDarkBackground = false,
  });

  final Color backgroundColor;
  final Color iconColor;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: isDarkBackground
                  ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                  : null,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icon/solar--camera-linear.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerSendButton extends StatelessWidget {
  const _ComposerSendButton({
    required this.enabled,
    required this.onTap,
    this.isDarkBackground = false,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = enabled
        ? AppTheme.primaryColor
        : (isDarkBackground
              ? const Color(0xFF252D38).withValues(alpha: 0.84)
              : AppTheme.textSecondary.withValues(alpha: 0.18));
    final iconColor = enabled
        ? Colors.white
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.56)
              : AppTheme.textSecondary.withValues(alpha: 0.55));

    return Tooltip(
      message: AppLocalizations.of(context)!.commonSend,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        scale: enabled ? 1 : 0.96,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('chatComposerSendButton'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: isDarkBackground
                    ? Border.all(
                        color: enabled
                            ? AppTheme.primaryColor.withValues(alpha: 0.32)
                            : Colors.white.withValues(alpha: 0.08),
                      )
                    : null,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : isDarkBackground
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icon/mingcute--send-plane-line.svg',
                  width: enabled ? 20 : 18,
                  height: enabled ? 20 : 18,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemPill extends StatelessWidget {
  const _SystemPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).colorScheme.surface.computeLuminance() < 0.2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF232A34).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

BorderRadius _buildGroupedBubbleRadius({
  required bool isSentByMe,
  required bool isGroupedWithPrevious,
  required bool isGroupedWithNext,
  double expandedRadius = 20,
  double groupedRadius = 8,
}) {
  if (isSentByMe) {
    return BorderRadius.only(
      topLeft: Radius.circular(expandedRadius),
      topRight: Radius.circular(
        isGroupedWithPrevious ? groupedRadius : expandedRadius,
      ),
      bottomLeft: Radius.circular(expandedRadius),
      bottomRight: Radius.circular(
        isGroupedWithNext ? groupedRadius : expandedRadius,
      ),
    );
  }

  return BorderRadius.only(
    topLeft: Radius.circular(
      isGroupedWithPrevious ? groupedRadius : expandedRadius,
    ),
    topRight: Radius.circular(expandedRadius),
    bottomLeft: Radius.circular(
      isGroupedWithNext ? groupedRadius : expandedRadius,
    ),
    bottomRight: Radius.circular(expandedRadius),
  );
}

class _TelegramTextMessageBubble extends StatelessWidget {
  const _TelegramTextMessageBubble({
    required this.surfaceKey,
    required this.message,
    required this.index,
    required this.isSentByMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.isDarkBackground,
    required this.isHighlighted,
    required this.senderName,
    required this.showSenderName,
    required this.replyPreview,
    required this.replySenderName,
    required this.mentionCandidates,
    required this.onReplyTap,
  });

  final GlobalKey surfaceKey;
  final fc.TextMessage message;
  final int index;
  final bool isSentByMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool isDarkBackground;
  final bool isHighlighted;
  final String? senderName;
  final bool showSenderName;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final List<ChatMentionCandidate> mentionCandidates;
  final VoidCallback? onReplyTap;

  @override
  Widget build(BuildContext context) {
    final sentBackgroundColor = isDarkBackground
        ? const Color(0xFF4E7E76)
        : const Color(0xFFDDF3EA);
    final receivedBackgroundColor = isDarkBackground
        ? const Color(0xFF2A313D)
        : Colors.white;
    final sentTextColor = isDarkBackground
        ? Colors.white
        : const Color(0xFF1E3B34);
    final receivedTextColor = isDarkBackground
        ? Colors.white
        : AppTheme.textPrimary;
    final timeColor = isSentByMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.72)
              : const Color(0xFF4B7B6D))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.5)
              : AppTheme.textSecondary.withValues(alpha: 0.82));

    final bubbleRadius = _buildGroupedBubbleRadius(
      isSentByMe: isSentByMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
    );
    final replyLabel = replySenderName?.trim().isNotEmpty == true
        ? replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;
    final replyPreviewBackground = isSentByMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F8));

    final metadata = message.metadata ?? const <String, dynamic>{};
    final isEdited =
        metadata[PetChatMessageAdapter.isEditedKey] as bool? ?? false;
    final isDeleted =
        metadata[PetChatMessageAdapter.isDeletedKey] as bool? ?? false;
    final deletedTextStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDarkBackground
              ? Colors.white.withValues(alpha: 0.58)
              : AppTheme.textSecondary.withValues(alpha: 0.78),
          fontSize: 13,
          height: 1.28,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          color: isDarkBackground
              ? Colors.white.withValues(alpha: 0.58)
              : AppTheme.textSecondary.withValues(alpha: 0.78),
          fontSize: 13,
          height: 1.28,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        );

    final mentionSpans = isDeleted
        ? <InlineSpan>[TextSpan(text: message.text, style: deletedTextStyle)]
        : buildChatMentionSpans(
            text: message.text,
            baseStyle:
                (isSentByMe
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: sentTextColor,
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w400,
                      )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: receivedTextColor,
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w400,
                      )) ??
                TextStyle(
                  color: isSentByMe ? sentTextColor : receivedTextColor,
                  fontSize: 16,
                  height: 1.36,
                ),
            mentionStyle:
                (isSentByMe
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkBackground
                            ? const Color(0xFFA2E0CF)
                            : const Color(0xFF276D5A),
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w700,
                      )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w700,
                      )) ??
                TextStyle(
                  color: isSentByMe
                      ? const Color(0xFF276D5A)
                      : AppTheme.primaryColor,
                  fontSize: 16,
                  height: 1.36,
                  fontWeight: FontWeight.w700,
                ),
            candidates: mentionCandidates,
          );
    final hasHighlightedMention = mentionSpans.any(
      (span) => span.style?.fontWeight == FontWeight.w700,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: _MessageHighlightFrame(
        isHighlighted: isHighlighted,
        isDarkBackground: isDarkBackground,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          key: ValueKey<String>('chatMessageSurface_${message.id}'),
          child: KeyedSubtree(
            key: surfaceKey,
            child: (hasHighlightedMention || isEdited || isDeleted)
                ? _MentionTextMessageBubble(
                    message: message,
                    constraints: const BoxConstraints(maxWidth: 296),
                    borderRadius: bubbleRadius,
                    backgroundColor: isSentByMe
                        ? sentBackgroundColor
                        : receivedBackgroundColor,
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
                    textSpans: mentionSpans,
                    timeStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: timeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    isEdited: isEdited,
                    topWidget: _buildTextMessageTopWidget(
                      context: context,
                      isSentByMe: isSentByMe,
                      isDarkBackground: isDarkBackground,
                      showSenderName: showSenderName,
                      senderName: senderName,
                      replyPreview: replyPreview,
                      replyLabel: replyLabel,
                      replyPreviewBackground: replyPreviewBackground,
                      onReplyTap: onReplyTap,
                    ),
                  )
                : SimpleTextMessage(
                    message: message,
                    index: index,
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
                    constraints: const BoxConstraints(maxWidth: 296),
                    borderRadius: bubbleRadius,
                    sentBackgroundColor: sentBackgroundColor,
                    receivedBackgroundColor: receivedBackgroundColor,
                    sentTextStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: sentTextColor,
                          fontSize: 16,
                          height: 1.36,
                          fontWeight: FontWeight.w400,
                        ),
                    receivedTextStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: receivedTextColor,
                          fontSize: 16,
                          height: 1.36,
                          fontWeight: FontWeight.w400,
                        ),
                    timeStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: timeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    topWidget: _buildTextMessageTopWidget(
                      context: context,
                      isSentByMe: isSentByMe,
                      isDarkBackground: isDarkBackground,
                      showSenderName: showSenderName,
                      senderName: senderName,
                      replyPreview: replyPreview,
                      replyLabel: replyLabel,
                      replyPreviewBackground: replyPreviewBackground,
                      onReplyTap: onReplyTap,
                    ),
                    timeAndStatusPosition: fc.TimeAndStatusPosition.inline,
                    timeAndStatusPositionInlineInsets: const EdgeInsets.only(
                      bottom: 1,
                    ),
                    showStatus: false,
                  ),
          ),
        ),
      ),
    );
  }

  Widget? _buildTextMessageTopWidget({
    required BuildContext context,
    required bool isSentByMe,
    required bool isDarkBackground,
    required bool showSenderName,
    required String? senderName,
    required ChatReplyPreview? replyPreview,
    required String replyLabel,
    required Color replyPreviewBackground,
    required VoidCallback? onReplyTap,
  }) {
    if (!isSentByMe &&
        (!showSenderName || senderName?.trim().isNotEmpty != true) &&
        replyPreview == null) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isSentByMe &&
            showSenderName &&
            senderName?.trim().isNotEmpty == true)
          Padding(
            padding: EdgeInsets.only(bottom: replyPreview == null ? 4 : 6),
            child: Text(
              senderName!.trim(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        if (replyPreview != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChatReplyPreviewPanel(
              key: const ValueKey('chatTextBubbleReplyPreview'),
              senderName: replyLabel,
              previewText: PetChatMessageAdapter.previewTextForReply(
                replyPreview,
                AppLocalizations.of(context)!,
              ),
              accentColor: AppTheme.primaryColor,
              senderColor: isSentByMe
                  ? (isDarkBackground
                        ? const Color(0xFFA2E0CF)
                        : const Color(0xFF4B8F7B))
                  : AppTheme.primaryColor,
              previewTextColor: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.68)
                  : AppTheme.textSecondary,
              backgroundColor: replyPreviewBackground,
              iconColor: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.58)
                  : AppTheme.textSecondary.withValues(alpha: 0.8),
              isImage: replyPreview.isImageFeed,
              showJumpIcon: true,
              compact: true,
              maxLines: 1,
              onTap: onReplyTap,
            ),
          ),
      ],
    );
  }
}

class _MessageActionTextPreviewBubble extends StatelessWidget {
  const _MessageActionTextPreviewBubble({
    required this.message,
    required this.isSentByMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.isDarkBackground,
    required this.senderName,
    required this.showSenderName,
    required this.replyPreview,
    required this.replySenderName,
    required this.onReplyTap,
  });

  final ChatMessage message;
  final bool isSentByMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool isDarkBackground;
  final String? senderName;
  final bool showSenderName;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final VoidCallback? onReplyTap;

  @override
  Widget build(BuildContext context) {
    final sentBackgroundColor = isDarkBackground
        ? const Color(0xFF4E7E76)
        : const Color(0xFFDDF3EA);
    final receivedBackgroundColor = isDarkBackground
        ? const Color(0xFF2A313D)
        : Colors.white;
    final sentTextColor = isDarkBackground
        ? Colors.white
        : const Color(0xFF1E3B34);
    final receivedTextColor = isDarkBackground
        ? Colors.white
        : AppTheme.textPrimary;
    final timeColor = isSentByMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.72)
              : const Color(0xFF4B7B6D))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.5)
              : AppTheme.textSecondary.withValues(alpha: 0.82));
    final bubbleRadius = _buildGroupedBubbleRadius(
      isSentByMe: isSentByMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
    );
    final replyLabel = replySenderName?.trim().isNotEmpty == true
        ? replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;
    final replyPreviewBackground = isSentByMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F8));
    final bodyText = (message.body ?? '').trim();
    final bubbleTime = _formatBubbleTime(context, message.createdAt);

    return _MessageHighlightFrame(
      isHighlighted: false,
      isDarkBackground: isDarkBackground,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: isSentByMe ? sentBackgroundColor : receivedBackgroundColor,
          borderRadius: bubbleRadius,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSentByMe &&
                showSenderName &&
                senderName?.trim().isNotEmpty == true)
              Padding(
                padding: EdgeInsets.only(bottom: replyPreview == null ? 4 : 6),
                child: Text(
                  senderName!.trim(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            if (replyPreview != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChatReplyPreviewPanel(
                  senderName: replyLabel,
                  previewText: PetChatMessageAdapter.previewTextForReply(
                    replyPreview!,
                    AppLocalizations.of(context)!,
                  ),
                  accentColor: AppTheme.primaryColor,
                  senderColor: isSentByMe
                      ? (isDarkBackground
                            ? const Color(0xFFA2E0CF)
                            : const Color(0xFF4B8F7B))
                      : AppTheme.primaryColor,
                  previewTextColor: isDarkBackground
                      ? Colors.white.withValues(alpha: 0.68)
                      : AppTheme.textSecondary,
                  backgroundColor: replyPreviewBackground,
                  iconColor: isDarkBackground
                      ? Colors.white.withValues(alpha: 0.58)
                      : AppTheme.textSecondary.withValues(alpha: 0.8),
                  isImage: replyPreview!.isImageFeed,
                  showJumpIcon: true,
                  compact: true,
                  maxLines: 1,
                  onTap: onReplyTap,
                ),
              ),
            Text(
              bodyText.isNotEmpty
                  ? bodyText
                  : AppLocalizations.of(context)!.chatMessageHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSentByMe ? sentTextColor : receivedTextColor,
                fontSize: 16,
                height: 1.36,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (bubbleTime != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    bubbleTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: timeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageHighlightFrame extends StatelessWidget {
  const _MessageHighlightFrame({
    required this.child,
    required this.isHighlighted,
    required this.isDarkBackground,
    required this.borderRadius,
  });

  final Widget child;
  final bool isHighlighted;
  final bool isDarkBackground;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final highlightBorder = AppTheme.primaryColor.withValues(
      alpha: isDarkBackground ? 0.42 : 0.34,
    );
    final highlightFill = AppTheme.primaryColor.withValues(
      alpha: isDarkBackground ? 0.10 : 0.06,
    );
    final highlightShadow = AppTheme.primaryColor.withValues(
      alpha: isDarkBackground ? 0.26 : 0.18,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isHighlighted ? highlightFill : Colors.transparent,
        borderRadius: borderRadius,
        border: Border.all(
          color: isHighlighted ? highlightBorder : Colors.transparent,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: highlightShadow,
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.surfaceKey,
    required this.message,
    required this.isMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.isDarkBackground,
    required this.isHighlighted,
    required this.senderName,
    required this.showSenderName,
    required this.replyPreview,
    required this.replySenderName,
    required this.onReplyTap,
    required this.onTapImage,
  });

  final GlobalKey surfaceKey;
  final fc.CustomMessage message;
  final bool isMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool isDarkBackground;
  final bool isHighlighted;
  final String? senderName;
  final bool showSenderName;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final VoidCallback? onReplyTap;
  final VoidCallback onTapImage;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? const <String, dynamic>{};
    final media = MediaQuery.of(context);
    final remoteUrl =
        (metadata[PetChatMessageAdapter.imageUrlKey] as String? ?? '').trim();
    final localPath =
        (metadata[PetChatMessageAdapter.localImagePathKey] as String? ?? '')
            .trim();
    final caption =
        (metadata[PetChatMessageAdapter.captionKey] as String? ?? '').trim();
    final coinsAwarded =
        (metadata[PetChatMessageAdapter.coinsAwardedKey] as int?) ?? 0;
    final theme = Theme.of(context);
    final canShowRemote = remoteUrl.isNotEmpty;
    final canShowLocal = localPath.isNotEmpty;
    final localImageCacheWidth = (280 * media.devicePixelRatio).round();
    final localImageCacheHeight = ((280 * 5 / 4) * media.devicePixelRatio)
        .round();
    final cardBackground = isMe
        ? (isDarkBackground ? const Color(0xFF4E7E76) : const Color(0xFFDDF3EA))
        : (isDarkBackground ? const Color(0xFF2A313D) : Colors.white);
    final cardTextColor = isMe && !isDarkBackground
        ? const Color(0xFF1E3B34)
        : (isDarkBackground ? Colors.white : AppTheme.textPrimary);
    final cardBorderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final bubbleTime = _formatBubbleTime(context, message.resolvedTime);
    final senderLabel =
        !isMe && showSenderName && senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : null;
    final replyLabel = replySenderName?.trim().isNotEmpty == true
        ? replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;
    final metadataTimeColor = isMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.72)
              : const Color(0xFF4B7B6D))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.5)
              : AppTheme.textSecondary.withValues(alpha: 0.82));
    final overlaySurface = Colors.black.withValues(
      alpha: isDarkBackground ? 0.42 : 0.34,
    );
    final overlayBorder = Colors.white.withValues(alpha: 0.16);
    final overlayShadow = Colors.black.withValues(alpha: 0.18);
    final overlayPrimaryText = Colors.white;
    final overlaySecondaryText = Colors.white.withValues(alpha: 0.76);
    final cardRadius = _buildGroupedBubbleRadius(
      isSentByMe: isMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
      expandedRadius: 18,
      groupedRadius: 9,
    );

    Widget image = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 28,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (canShowLocal) {
      image = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        cacheWidth: localImageCacheWidth,
        cacheHeight: localImageCacheHeight,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else if (canShowRemote) {
      image = CachedNetworkImageView(imageUrl: remoteUrl, fit: BoxFit.cover);
    }

    Widget buildGlassPill({
      required Widget child,
      required BorderRadius borderRadius,
      required EdgeInsetsGeometry padding,
    }) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: overlaySurface,
            borderRadius: borderRadius,
            border: Border.all(color: overlayBorder),
            boxShadow: [
              BoxShadow(
                color: overlayShadow.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: _MessageHighlightFrame(
        isHighlighted: isHighlighted,
        isDarkBackground: isDarkBackground,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          key: ValueKey<String>('chatMessageSurface_${message.id}'),
          child: KeyedSubtree(
            key: surfaceKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: cardRadius,
                  border: Border.all(color: cardBorderColor),
                ),
                child: InkWell(
                  onTap: onTapImage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (replyPreview != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: ChatReplyPreviewPanel(
                            key: const ValueKey('chatFeedCardReplyPreview'),
                            senderName: replyLabel,
                            previewText:
                                PetChatMessageAdapter.previewTextForReply(
                                  replyPreview!,
                                  AppLocalizations.of(context)!,
                                ),
                            accentColor: AppTheme.primaryColor,
                            senderColor: isMe
                                ? (isDarkBackground
                                      ? const Color(0xFFA2E0CF)
                                      : const Color(0xFF4B8F7B))
                                : AppTheme.primaryColor,
                            previewTextColor: isDarkBackground
                                ? Colors.white.withValues(alpha: 0.68)
                                : AppTheme.textSecondary,
                            backgroundColor: isDarkBackground
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF1F5F8),
                            iconColor: isDarkBackground
                                ? Colors.white.withValues(alpha: 0.58)
                                : AppTheme.textSecondary.withValues(alpha: 0.8),
                            isImage: replyPreview!.isImageFeed,
                            showJumpIcon: true,
                            compact: true,
                            maxLines: 1,
                            onTap: onReplyTap,
                          ),
                        ),
                      if (replyPreview != null) const SizedBox(height: 10),
                      if (senderLabel != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Text(
                            senderLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(child: image),
                            if (coinsAwarded > 0)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: buildGlassPill(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/shop/icon/candy.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        PetChatMessageAdapter.feedRewardLabel(
                                          coinsAwarded,
                                          AppLocalizations.of(context)!,
                                        ),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: overlayPrimaryText,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (bubbleTime != null && caption.isEmpty)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: buildGlassPill(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    bubbleTime,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: overlaySecondaryText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.35,
                                    color: cardTextColor,
                                  ),
                                ),
                              ),
                              if (bubbleTime != null) ...[
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: Text(
                                    bubbleTime,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: metadataTimeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _formatBubbleTime(BuildContext context, DateTime? time) {
  if (time == null) {
    return null;
  }
  final local = time.toLocal();
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
}

class ReplySwipeWrapper extends StatefulWidget {
  const ReplySwipeWrapper({
    super.key,
    required this.child,
    required this.onTriggered,
  });

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<ReplySwipeWrapper> createState() => _ReplySwipeWrapperState();
}

class _ReplySwipeWrapperState extends State<ReplySwipeWrapper>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 32;

  late final AnimationController _controller;
  Animation<double>? _animation;
  double _dragOffset = 0;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _animation?.removeListener(_handleAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationTick() {
    final animation = _animation;
    if (!mounted || animation == null) {
      return;
    }
    setState(() => _dragOffset = animation.value);
  }

  void _animateBack() {
    if (_dragOffset <= 0) {
      return;
    }
    _animation?.removeListener(_handleAnimationTick);
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(_handleAnimationTick);
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / _triggerDistance).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx >= 0 || _triggered) {
          return;
        }
        _controller.stop();
        setState(() {
          _dragOffset = (_dragOffset + (-details.delta.dx)).clamp(0.0, 84.0);
        });
        if (_dragOffset >= _triggerDistance) {
          _triggered = true;
          widget.onTriggered();
          _animateBack();
        }
      },
      onHorizontalDragEnd: (_) {
        if (!_triggered) {
          _animateBack();
        }
        _triggered = false;
      },
      onHorizontalDragCancel: _animateBack,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 8,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.9 + (progress * 0.1),
                child: Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: AppTheme.primaryColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.petName,
    required this.memberCount,
    required this.uiScale,
    required this.useLightForeground,
    required this.onBack,
    required this.onMembersTap,
    required this.menuButton,
  });

  final String petName;
  final String? memberCount;
  final double uiScale;
  final bool useLightForeground;
  final VoidCallback onBack;
  final VoidCallback onMembersTap;
  final Widget menuButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12 * uiScale,
          8 * uiScale,
          12 * uiScale,
          8 * uiScale,
        ),
        child: Row(
          children: [
            _GlassPill(
              useDarkSurface: useLightForeground,
              padding: EdgeInsets.all(4 * uiScale),
              child: IconButton(
                iconSize: (20 * uiScale).clamp(18.0, 20.0),
                constraints: BoxConstraints.tightFor(
                  width: (36.0 * uiScale).clamp(32.0, 36.0),
                  height: (36.0 * uiScale).clamp(32.0, 36.0),
                ),
                padding: EdgeInsets.all((8.0 * uiScale).clamp(6.0, 8.0)),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: useLightForeground ? Colors.white : AppTheme.textPrimary,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            SizedBox(width: 10 * uiScale),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 220 * uiScale),
                  child: GestureDetector(
                    onTap: onMembersTap,
                    child: _GlassPill(
                      useDarkSurface: useLightForeground,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * uiScale,
                        vertical: 8 * uiScale,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: (15 * uiScale).clamp(13.0, 15.0),
                              fontWeight: FontWeight.w600,
                              color: useLightForeground
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          if (memberCount != null)
                            Text(
                              memberCount!,
                              style: TextStyle(
                                fontSize: (11 * uiScale).clamp(10.0, 11.0),
                                color: useLightForeground
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Colors.black.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * uiScale),
            _GlassPill(
              useDarkSurface: useLightForeground,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: menuButton,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMenuAvatar extends StatelessWidget {
  const _ChatMenuAvatar({required this.petAssetPath, required this.uiScale});

  final String? petAssetPath;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final avatarSize = (48.0 * uiScale).clamp(40.0, 48.0);
    final petIconSize = (24.0 * uiScale).clamp(20.0, 24.0);
    final petAssetSize = (40.0 * uiScale).clamp(32.0, 40.0);
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Center(
        child: CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: petAssetPath == null
              ? Icon(Icons.pets, size: petIconSize, color: AppTheme.textPrimary)
              : PetAnimatedImage(
                  sourceAsset: petAssetPath!,
                  width: petAssetSize,
                  height: petAssetSize,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.padding,
    this.useDarkSurface = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool useDarkSurface;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: useDarkSurface
              ? Colors.black.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: useDarkSurface
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: useDarkSurface ? 0.10 : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
