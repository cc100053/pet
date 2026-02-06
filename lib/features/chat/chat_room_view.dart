import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/app_dialog.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/status_bar_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../services/chat/chat_message_repository.dart';
import '../../services/performance/performance_service.dart';
import '../feed/feed_capture_view.dart';
import 'blocked_users_sheet.dart';
import 'widgets/chat_message_tile.dart';
import 'chat_message.dart';

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({
    super.key,
    required this.roomId,
    this.backgroundDecoration,
    this.petName,
    this.memberCount,
    this.petAssetPath,
    this.isDarkBackground = false,
    this.isPetDeparted = false,
    this.isRoomLocked = false,
  });

  final String roomId;
  final BoxDecoration? backgroundDecoration;
  final String? petName;
  final int? memberCount;
  final String? petAssetPath;
  final bool isDarkBackground;
  final bool isPetDeparted;
  final bool isRoomLocked;

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

/// GlobalKey to allow parent to notify child of new messages
final _chatMessageListKey = GlobalKey<ChatMessageListState>();

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;
  int? _memberCount;
  static const double _topBarHeight = 64;

  @override
  void initState() {
    super.initState();
    _memberCount = widget.memberCount;
    if (_memberCount == null) {
      _fetchMemberCount();
    }
  }

  Future<void> _fetchMemberCount() async {
    try {
      final count = await Supabase.instance.client
          .from('room_members')
          .count(CountOption.exact)
          .eq('room_id', widget.roomId)
          .eq('is_active', true);
      if (mounted) {
        setState(() => _memberCount = count);
      }
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
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

    setState(() {
      _sending = true;
    });

    // Clear immediately for better UX
    _messageController.clear();

    // Create optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      roomId: widget.roomId,
      senderId: userId,
      type: 'text',
      body: text,
      imageUrl: null,
      caption: null,
      coinsAwarded: 0,
      createdAt: DateTime.now().toUtc(),
      clientCreatedAt: DateTime.now().toUtc(),
      labels: const [],
      localImagePath: null,
    );

    // Add optimistic message immediately
    _chatMessageListKey.currentState?.addOptimisticMessage(optimisticMessage);

    try {
      await Supabase.instance.client.from('messages').insert({
        'room_id': widget.roomId,
        'sender_id': userId,
        'type': 'text',
        'body': text,
        'client_created_at': DateTime.now().toUtc().toIso8601String(),
      });
      _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
      _chatMessageListKey.currentState?.refreshLatest();
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'success'},
      );
      if (!mounted) {
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'failure'},
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
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _openFeedCamera() async {
    if (widget.isRoomLocked) {
      final l10n = AppLocalizations.of(context)!;
      await showAppDialog<void>(
        context: context,
        builder: (context) => AppDialog(
          tone: AppDialogTone.info,
          title: l10n.roomLockedTitle,
          message: l10n.roomLockedMessage,
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
    if (widget.isPetDeparted) {
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
    AnalyticsService.instance.logEvent('feed_camera_open');
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCaptureView(
          roomId: widget.roomId,
          onOptimisticMessage: _handleOptimisticFeed,
          onUploadCompleted: _handleFeedUploadCompleted,
          onUploadFailed: _handleFeedUploadFailed,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    _chatMessageListKey.currentState?.refreshLatest();
  }

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
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
    _chatMessageListKey.currentState?.addOptimisticMessage(optimisticMessage);
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    _chatMessageListKey.currentState?.removeOptimisticMessage(result.tempId);
    _chatMessageListKey.currentState?.refreshLatest();
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
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
        onBlockListChanged: () =>
            _chatMessageListKey.currentState?.refreshAfterBlockChange(),
      ),
    );

    if (changed == true) {
      _chatMessageListKey.currentState?.refreshAfterBlockChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context)!;
    final useLightForeground = widget.isDarkBackground;
    final media = MediaQuery.of(context);
    final listTopPadding = media.padding.top + _topBarHeight + 12;
    final composerBottomInset = media.padding.bottom;
    const composerHeight = 64.0;
    final listBottomPadding = composerHeight + composerBottomInset + 16;

    final overlayStyle = AppStatusBarStyles.forBackground(
      isDark: widget.isDarkBackground,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          systemOverlayStyle: overlayStyle,
          toolbarHeight: _topBarHeight,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: _ChatTopBar(
            petName: widget.petName ?? l10n.chatTitle,
            memberCount: _memberCount == null
                ? null
                : l10n.chatMemberCount(_memberCount!),
            useLightForeground: useLightForeground,
            onBack: () => Navigator.of(context).maybePop(),
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
                  if (value == 'block' && currentUserId != null) {
                    _openBlockedUsers();
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
                child: _ChatMenuAvatar(petAssetPath: widget.petAssetPath),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: widget.backgroundDecoration,
          child: Stack(
            children: [
              Positioned.fill(
                child: ChatMessageList(
                  key: _chatMessageListKey,
                  roomId: widget.roomId,
                  currentUserId: currentUserId,
                  useLightForeground: useLightForeground,
                  contentPadding: EdgeInsets.fromLTRB(
                    16,
                    listTopPadding,
                    16,
                    listBottomPadding,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: SafeArea(
                  top: false,
                  child: _GlassPill(
                    backgroundOpacity: useLightForeground ? 0.35 : 0.55,
                    useDarkSurface: useLightForeground,
                    padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: (_sending || widget.isRoomLocked)
                              ? null
                              : _openFeedCamera,
                          icon: SvgPicture.asset(
                            'assets/icon/solar--camera-linear.svg',
                            width: 26,
                            height: 26,
                            colorFilter: ColorFilter.mode(
                              useLightForeground
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppTheme.textSecondary,
                              BlendMode.srcIn,
                            ),
                          ),
                          tooltip: l10n.feedTitle,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) =>
                                _sending ? null : _sendMessage(),
                            decoration: InputDecoration(
                              hintText: l10n.chatMessageHint,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.transparent,
                              hintStyle: TextStyle(
                                color: useLightForeground
                                    ? Colors.white.withValues(alpha: 0.72)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 15,
                              color: useLightForeground
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                            cursorColor: useLightForeground
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: l10n.commonSend,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _sending ? null : _sendMessage,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icon/mingcute--send-plane-line.svg',
                                    width: 26,
                                    height: 26,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.useLightForeground = false,
    this.scrollController,
    this.contentPadding,
  });

  final String roomId;
  final String? currentUserId;
  final bool useLightForeground;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<ChatMessageList> createState() => ChatMessageListState();
}

enum _MessageAction { report, block }

class ChatMessageListState extends State<ChatMessageList> {
  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 120;

  late final ScrollController _scrollController;
  final List<ChatMessage> _messages = [];
  final Set<String> _messageIds = {};
  final Set<String> _optimisticIds = {}; // Track temp message IDs
  final Set<String> _blockedUserIds = {};
  final Map<String, String> _profileNicknames = {}; // userId -> nickname
  final ChatMessageRepository _repository = ChatMessageRepository.instance;

  RealtimeChannel? _channel;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _showScrollToBottom = false;
  bool _usedCachedMessages = false;
  String? _error;

  /// Add an optimistic message immediately (called by parent)
  void addOptimisticMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _optimisticIds.add(message.id);
      _messages.insert(0, message);
      _sortMessages();
    });
  }

  void removeOptimisticMessage(String tempId) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((message) => message.id == tempId);
      _optimisticIds.remove(tempId);
    });
  }

  /// Refresh latest messages (useful after returning from feed capture)
  Future<void> refreshLatest() async {
    if (_loadingInitial) {
      return;
    }

    try {
      final page = await _fetchMessages();
      if (!mounted) {
        return;
      }
      setState(() {
        _mergePage(page);
        _error = null;
      });
      _persistCache();
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

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    unawaited(_initialize());
    _subscribeToMessages();
  }

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId == widget.roomId) {
      return;
    }

    _channel?.unsubscribe();
    setState(() {
      _messages.clear();
      _messageIds.clear();
      _optimisticIds.clear();
      _error = null;
      _hasMore = true;
      _loadingMore = false;
      _loadingInitial = true;
      _showScrollToBottom = false;
      _usedCachedMessages = false;
    });
    unawaited(_initialize());
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadBlockedUsers();
    await _loadCachedMessages();
    await _loadInitial();
  }

  Future<void> _loadCachedMessages() async {
    if (!_repository.isReady) {
      return;
    }
    try {
      final cached = await _repository.loadCachedMessages(widget.roomId);
      if (!mounted) {
        return;
      }
      if (cached.isEmpty) {
        return;
      }
      setState(() {
        _applyCachedMessages(_filterBlocked(cached));
        _loadingInitial = false;
        _error = null;
        _usedCachedMessages = true;
      });
      PerformanceService.instance.markChatColdLoaded(
        messageCount: cached.length,
        source: 'cache',
        success: true,
      );
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

  Future<void> _loadBlockedUsers() async {
    final userId = widget.currentUserId;
    _blockedUserIds.clear();
    if (userId == null) {
      return;
    }

    try {
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

  Future<void> refreshAfterBlockChange() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _messages.clear();
      _messageIds.clear();
      _optimisticIds.clear();
      _error = null;
      _hasMore = true;
      _loadingMore = false;
      _loadingInitial = true;
      _showScrollToBottom = false;
    });

    await _loadBlockedUsers();
    await _loadCachedMessages();
    await _loadInitial();
  }

  List<ChatMessage> _filterBlocked(List<ChatMessage> source) {
    return source
        .where(
          (message) =>
              message.senderId == null ||
              !_blockedUserIds.contains(message.senderId),
        )
        .toList();
  }

  void _applyCachedMessages(List<ChatMessage> cached) {
    _messages
      ..clear()
      ..addAll(cached);
    _messageIds
      ..clear()
      ..addAll(cached.map((message) => message.id));
    _sortMessages();
  }

  void _persistCache() {
    if (!_repository.isReady) {
      return;
    }
    final cacheable = _messages
        .where((message) => !_optimisticIds.contains(message.id))
        .toList();
    unawaited(_repository.cacheMessages(widget.roomId, cacheable));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final showScrollButton = position.pixels > 300;
    if (showScrollButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showScrollButton;
      });
    }

    if (!_hasMore || _loadingMore || _loadingInitial) {
      return;
    }

    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadInitial() async {
    final showSkeleton = _messages.isEmpty;
    setState(() {
      _loadingInitial = showSkeleton;
      _error = null;
    });

    try {
      final page = await _fetchMessages();
      if (!mounted) {
        return;
      }
      _mergePage(page);
      _persistCache();
      unawaited(_ensureProfilesForMessages(_messages));
      PerformanceService.instance.markChatColdLoaded(
        messageCount: _messages.length,
        source: _usedCachedMessages ? 'cache+network' : 'network',
        success: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.chatLoadMessagesFailed(userFacingError(context, error));
      });
      PerformanceService.instance.markChatColdLoaded(
        messageCount: _messages.length,
        source: 'network_error',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
        });
      }
    }
  }

  void _mergePage(List<ChatMessage> page) {
    final merged = <ChatMessage>[...page];
    final ids = <String>{...page.map((message) => message.id)};
    for (final message in _messages) {
      if (ids.add(message.id)) {
        merged.add(message);
      }
    }
    _messages
      ..clear()
      ..addAll(merged);
    _messageIds
      ..clear()
      ..addAll(ids);
    _hasMore = page.length == _pageSize;
    _sortMessages();
  }

  Future<void> _loadMore() async {
    if (_messages.isEmpty) {
      return;
    }

    setState(() {
      _loadingMore = true;
      _error = null;
    });

    final oldest = _messages.last;
    try {
      final page = await _fetchMessages(
        beforeCreatedAt: oldest.createdAt.toUtc().toIso8601String(),
        beforeId: oldest.id,
      );
      if (!mounted) {
        return;
      }
      for (final message in page) {
        if (_messageIds.add(message.id)) {
          _messages.add(message);
        }
      }
      _hasMore = page.length == _pageSize;
      _sortMessages();
      _persistCache();
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
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  Future<List<ChatMessage>> _fetchMessages({
    String? beforeCreatedAt,
    String? beforeId,
  }) async {
    final page = await _repository.fetchMessages(
      roomId: widget.roomId,
      beforeCreatedAt: beforeCreatedAt,
      beforeId: beforeId,
      limit: _pageSize,
    );
    return _filterBlocked(page);
  }

  /// Fetches and caches nicknames for all unique sender IDs in messages
  Future<void> _ensureProfilesForMessages(List<ChatMessage> messages) async {
    final userIds = <String>{};
    for (final message in messages) {
      final senderId = message.senderId;
      if (senderId != null &&
          senderId.isNotEmpty &&
          senderId != widget.currentUserId &&
          !_profileNicknames.containsKey(senderId)) {
        userIds.add(senderId);
      }
    }

    if (userIds.isEmpty) {
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('user_id, nickname')
          .inFilter('user_id', userIds.toList());

      if (!mounted) {
        return;
      }

      final rows = response as List<dynamic>;
      bool hasNewProfiles = false;
      for (final row in rows) {
        final userId = row['user_id'] as String?;
        final nickname = row['nickname'] as String?;
        if (userId != null && nickname != null && nickname.isNotEmpty) {
          _profileNicknames[userId] = nickname;
          hasNewProfiles = true;
        }
      }

      if (hasNewProfiles) {
        setState(() {});
      }
    } catch (_) {
      // Best-effort profile loading
    }
  }

  void _subscribeToMessages() {
    final channel = Supabase.instance.client.channel(
      'room_messages_${widget.roomId}',
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
        final record = payload.newRecord;
        final message = ChatMessage.fromJson(record);
        if (message.type.isEmpty) {
          return;
        }
        if (message.senderId != null &&
            _blockedUserIds.contains(message.senderId)) {
          return;
        }
        if (!mounted) {
          return;
        }
        setState(() {
          // Remove any optimistic messages with matching body/senderId
          if (message.senderId != null) {
            _messages.removeWhere((m) {
              if (!_optimisticIds.contains(m.id)) {
                return false;
              }
              if (m.senderId != message.senderId) {
                return false;
              }
              if (m.type == 'image_feed' && message.type == 'image_feed') {
                final optimisticClient = m.clientCreatedAt?.toIso8601String();
                final incomingClient = message.clientCreatedAt
                    ?.toIso8601String();
                return optimisticClient != null &&
                    incomingClient != null &&
                    optimisticClient == incomingClient;
              }
              return m.body == message.body;
            });
            _optimisticIds.removeWhere(
              (id) => _messages.every((m) => m.id != id),
            );
          }
          // Add the real message if not already present
          if (_messageIds.add(message.id)) {
            _messages.insert(0, message);
            _sortMessages();
          }
        });
        _persistCache();
        // Fetch profile for new sender if not cached
        if (message.senderId != null &&
            message.senderId != widget.currentUserId &&
            !_profileNicknames.containsKey(message.senderId)) {
          unawaited(_ensureProfilesForMessages([message]));
        }
      },
    );
    channel.subscribe();
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final createdCompare = b.createdAt.compareTo(a.createdAt);
      if (createdCompare != 0) {
        return createdCompare;
      }
      return b.id.compareTo(a.id);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial && _messages.isEmpty) {
      return _ChatLoadingList(
        padding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final imageIndexByMessageId = <String, int>{};
    final imageUrls = <String>[];
    final imageCaptions = <String?>[];
    final localImagePaths = <int, String>{};
    for (final message in _messages) {
      if (!message.isImageFeed) {
        continue;
      }
      final localPath = message.localImagePath;
      final remoteUrl = message.imageUrl ?? '';
      if (remoteUrl.isEmpty && (localPath == null || localPath.isEmpty)) {
        continue;
      }
      final index = imageUrls.length;
      imageIndexByMessageId[message.id] = index;
      imageUrls.add(remoteUrl);
      final captionRaw = (message.caption ?? message.body ?? '').trim();
      imageCaptions.add(captionRaw.isEmpty ? null : captionRaw);
      if (localPath != null && localPath.isNotEmpty) {
        localImagePaths[index] = localPath;
      }
    }
    final errorBanner = _error == null
        ? null
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );

    return Column(
      children: [
        if (errorBanner != null) errorBanner,
        Expanded(
          child: Stack(
            children: [
              _messages.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      reverse: true,
                      padding:
                          widget.contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            l10n.chatEmptyState,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.useLightForeground
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      reverse: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          widget.contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          if (_loadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (!_hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(l10n.chatNoOlderMessages),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                child: Text(l10n.chatLoadOlderMessages),
                              ),
                            ),
                          );
                        }

                        final message = _messages[index];
                        final isMe =
                            message.senderId != null &&
                            message.senderId == widget.currentUserId;
                        final isOptimistic = _optimisticIds.contains(
                          message.id,
                        );
                        final imageIndex = imageIndexByMessageId[message.id];
                        final senderName = isMe
                            ? null
                            : _profileNicknames[message.senderId];
                        return ChatMessageTile(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: isMe,
                          isOptimistic: isOptimistic,
                          useLightForeground: widget.useLightForeground,
                          senderName: senderName,
                          onLongPress: _shouldShowActions(message, isMe)
                              ? () => _showMessageActions(message)
                              : null,
                          onImageTap: imageIndex == null
                              ? null
                              : () => FullScreenPhotoViewer.open(
                                  context,
                                  imageUrls: imageUrls,
                                  initialIndex: imageIndex,
                                  localImagePaths: localImagePaths,
                                  showIndicator: false,
                                  captions: imageCaptions,
                                ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        if (index == _messages.length - 1) {
                          // Separator between oldest message and loader/footer
                          return _DateSeparator(
                            date: _messages[index].createdAt,
                          );
                        }
                        if (index < _messages.length - 1) {
                          final newer = _messages[index];
                          final older = _messages[index + 1];
                          if (!_isSameDay(newer.createdAt, older.createdAt)) {
                            return _DateSeparator(date: newer.createdAt);
                          }
                        }
                        return const SizedBox(height: 2);
                      },
                      itemCount: _messages.length + 1,
                    ),
              if (_showScrollToBottom)
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: FloatingActionButton.small(
                    onPressed: _scrollToBottom,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowActions(ChatMessage message, bool isMe) {
    if (message.isSystem) {
      return false;
    }
    if (isMe) {
      return false;
    }
    return message.senderId != null && message.id.isNotEmpty;
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final currentUserId = widget.currentUserId;
    final senderId = message.senderId;
    if (currentUserId == null || senderId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final isBlocked = _blockedUserIds.contains(senderId);
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report_gmailerrorred_outlined),
                title: Text(l10n.chatReportMessageTitle),
                onTap: () => Navigator.pop(context, _MessageAction.report),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(
                  isBlocked ? l10n.chatUserAlreadyBlocked : l10n.chatBlockUser,
                ),
                enabled: !isBlocked,
                onTap: isBlocked
                    ? null
                    : () => Navigator.pop(context, _MessageAction.block),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _MessageAction.report:
        await _reportMessage(message);
        break;
      case _MessageAction.block:
        await _blockUser(senderId);
        break;
    }
  }

  Future<void> _reportMessage(ChatMessage message) async {
    final reporterId = widget.currentUserId;
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
    final blockerId = widget.currentUserId;
    if (blockerId == null) {
      return;
    }

    if (_blockedUserIds.contains(blockedUserId)) {
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

      if (!mounted) {
        return;
      }

      setState(() {
        _blockedUserIds.add(blockedUserId);
        _messages.removeWhere((message) {
          if (message.senderId == blockedUserId) {
            _messageIds.remove(message.id);
            _optimisticIds.remove(message.id);
            return true;
          }
          return false;
        });
      });
      _persistCache();

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

  Future<String?> _promptReportReason(BuildContext context) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final result = await showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.warning,
        title: l10n.chatReportMessageTitle,
        body: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.chatReportHint),
          maxLines: 3,
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.pop(context),
          ),
          AppDialogAction.primary(
            label: l10n.commonSubmit,
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(
                context,
                text.isEmpty ? l10n.chatReportNoReason : text,
              );
            },
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }
}

class _ChatLoadingList extends StatelessWidget {
  const _ChatLoadingList({required this.padding});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = theme.colorScheme.surfaceContainerHighest;

    Widget bubble({required Alignment alignment, required double widthFactor}) {
      return Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      reverse: true,
      padding: padding,
      children: [
        bubble(alignment: Alignment.centerRight, widthFactor: 0.45),
        const SizedBox(height: 12),
        bubble(alignment: Alignment.centerLeft, widthFactor: 0.65),
        const SizedBox(height: 12),
        bubble(alignment: Alignment.centerRight, widthFactor: 0.35),
        const SizedBox(height: 12),
        bubble(alignment: Alignment.centerLeft, widthFactor: 0.55),
        const SizedBox(height: 12),
        bubble(alignment: Alignment.centerRight, widthFactor: 0.5),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.petName,
    required this.memberCount,
    required this.useLightForeground,
    required this.onBack,
    required this.menuButton,
  });

  final String petName;
  final String? memberCount;
  final bool useLightForeground;
  final VoidCallback onBack;
  final Widget menuButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            _GlassPill(
              useDarkSurface: useLightForeground,
              padding: const EdgeInsets.all(4),
              child: IconButton(
                iconSize: 20,
                constraints: const BoxConstraints(), // Remove 48px limit
                padding: const EdgeInsets.all(8), // Tighter tap area
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: useLightForeground ? Colors.white : AppTheme.textPrimary,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: _GlassPill(
                    useDarkSurface: useLightForeground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
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
                              fontSize: 11,
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
            const SizedBox(width: 10),
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
  const _ChatMenuAvatar({required this.petAssetPath});

  final String? petAssetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: petAssetPath == null
              ? const Icon(Icons.pets, size: 24, color: AppTheme.textPrimary)
              : Image.asset(petAssetPath!, width: 40, height: 40),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.padding,
    this.backgroundOpacity = 0.72,
    this.useDarkSurface = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double backgroundOpacity;
  final bool useDarkSurface;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: useDarkSurface
                ? Colors.black.withValues(alpha: backgroundOpacity)
                : Colors.white.withValues(alpha: backgroundOpacity),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: useDarkSurface
                  ? Colors.white.withValues(alpha: 0.24)
                  : Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: useDarkSurface ? 0.18 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(context, date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final l10n = AppLocalizations.of(context)!;
    // Check if Today
    if (localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day) {
      return l10n.calendarToday;
    }

    // Check if Yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (localDate.year == yesterday.year &&
        localDate.month == yesterday.month &&
        localDate.day == yesterday.day) {
      return l10n.calendarYesterday;
    }

    if (localDate.year == now.year) {
      return DateFormat.MMMd().format(localDate);
    }
    return DateFormat.yMMMd().format(localDate);
  }
}
