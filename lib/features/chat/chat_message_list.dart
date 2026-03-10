import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/app_dialog.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat/chat_message_repository.dart';
import '../../services/performance/performance_service.dart';
import '../../services/profile/profile_cache_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/app_ui_scale.dart';
import 'chat_message.dart';
import 'widgets/chat_keyboard_dismiss_shell.dart';
import 'widgets/chat_message_tile.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.useLightForeground = false,
    this.scrollController,
    this.contentPadding,
    this.onReplyRequested,
  });

  final String roomId;
  final String? currentUserId;
  final bool useLightForeground;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? contentPadding;
  final ValueChanged<ChatReplyTarget>? onReplyRequested;

  @override
  State<ChatMessageList> createState() => ChatMessageListState();
}

enum _MessageAction { reply, copy, report, block }

class ChatMessageListState extends State<ChatMessageList> {
  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 120;

  late final ScrollController _scrollController;
  final List<ChatMessage> _messages = [];
  final Set<String> _messageIds = {};
  final Set<String> _optimisticIds = {}; // Track temp message IDs
  final Set<String> _blockedUserIds = {};
  final Set<String> _loadingReplyPreviewIds = {};
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

  /// Force the list to show the latest message (bottom in chat semantics).
  void scrollToLatest({bool animated = true}) {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (animated) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0);
      }
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
      unawaited(_ensureReplyPreviewsForMessages(_messages));
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

  String? _displayNameForSenderId(String? senderId) {
    if (senderId == null || senderId.isEmpty) {
      return null;
    }
    if (senderId == widget.currentUserId) {
      return AppLocalizations.of(context)!.chatRoomMemberYou;
    }
    final nickname = _profileNicknames[senderId]?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    return null;
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
    for (final candidate in _messages) {
      if (candidate.id == replyId) {
        return ChatReplyPreview.fromMessage(candidate);
      }
    }
    return null;
  }

  Future<void> _ensureReplyPreviewsForMessages(
    List<ChatMessage> messages,
  ) async {
    final replyIds = <String>{};
    for (final message in messages) {
      final replyId = message.replyToMessageId;
      if (replyId == null || replyId.isEmpty || message.replyPreview != null) {
        continue;
      }
      final existsLocally = _messages.any((entry) => entry.id == replyId);
      if (!existsLocally && !_loadingReplyPreviewIds.contains(replyId)) {
        replyIds.add(replyId);
      }
    }

    if (replyIds.isEmpty) {
      return;
    }

    _loadingReplyPreviewIds.addAll(replyIds);
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('id,sender_id,type,body,image_url,caption')
          .filter('id', 'in', '(${replyIds.join(',')})');
      final rows = response as List<dynamic>;
      final previewById = <String, ChatReplyPreview>{};
      for (final row in rows) {
        final preview = ChatReplyPreview.fromJson(
          Map<String, dynamic>.from(row),
        );
        if (preview.id.isNotEmpty) {
          previewById[preview.id] = preview;
        }
      }
      if (!mounted || previewById.isEmpty) {
        return;
      }

      setState(() {
        for (var index = 0; index < _messages.length; index++) {
          final message = _messages[index];
          final replyId = message.replyToMessageId;
          if (replyId == null ||
              replyId.isEmpty ||
              message.replyPreview != null) {
            continue;
          }
          final preview = previewById[replyId];
          if (preview != null) {
            _messages[index] = message.copyWith(replyPreview: preview);
          }
        }
      });
      _persistCache();
      unawaited(_ensureProfilesForMessages(_messages));
    } catch (_) {
      // Best-effort reply preview loading.
    } finally {
      _loadingReplyPreviewIds.removeAll(replyIds);
    }
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
      unawaited(_ensureReplyPreviewsForMessages(_messages));
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
      unawaited(_ensureProfilesForMessages(page));
      unawaited(_ensureReplyPreviewsForMessages(page));
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
          !_profileNicknames.containsKey(senderId)) {
        userIds.add(senderId);
      }
      final replySenderId = _resolvedReplyPreview(message)?.senderId;
      if (replySenderId != null &&
          replySenderId.isNotEmpty &&
          !_profileNicknames.containsKey(replySenderId) &&
          replySenderId != widget.currentUserId) {
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
      bool hasNewProfiles = false;
      for (final userId in userIds) {
        final nickname = profiles[userId]?.nickname;
        if (nickname != null && nickname.isNotEmpty) {
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
        final shouldAutoFollowLatest = _isNearLatest();
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
              return m.body == message.body &&
                  m.replyToMessageId == message.replyToMessageId;
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
        if (shouldAutoFollowLatest) {
          scrollToLatest(animated: true);
        }
        // Fetch profile for new sender if not cached
        if (message.senderId != null &&
            message.senderId != widget.currentUserId &&
            !_profileNicknames.containsKey(message.senderId)) {
          unawaited(_ensureProfilesForMessages([message]));
        }
        if (message.replyToMessageId != null && message.replyPreview == null) {
          unawaited(_ensureReplyPreviewsForMessages([message]));
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

  bool _isNearLatest() {
    if (!_scrollController.hasClients) {
      return true;
    }
    return _scrollController.position.pixels <= 72;
  }

  @override
  Widget build(BuildContext context) {
    final defaultPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    );
    final resolvedPadding = (widget.contentPadding ?? defaultPadding).resolve(
      Directionality.of(context),
    );
    if (_loadingInitial && _messages.isEmpty) {
      return _ChatLoadingList(padding: resolvedPadding);
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final uiScale = appUiScale(MediaQuery.of(context).size.width);
    final imageIndexByMessageId = <String, int>{};
    final imageViewerItems = <PhotoViewerItem>[];
    for (final message in _messages) {
      if (!message.isImageFeed) {
        continue;
      }
      final localPath = message.localImagePath?.trim();
      final remoteUrl = (message.imageUrl ?? '').trim();
      if (remoteUrl.isEmpty && (localPath == null || localPath.isEmpty)) {
        continue;
      }
      final index = imageViewerItems.length;
      imageIndexByMessageId[message.id] = index;
      final captionRaw = (message.caption ?? message.body ?? '').trim();
      final senderId = message.senderId;
      final senderName = senderId == null ? null : _profileNicknames[senderId];
      imageViewerItems.add(
        PhotoViewerItem(
          imageUrl: remoteUrl,
          localImagePath: localPath,
          caption: captionRaw.isEmpty ? null : captionRaw,
          senderName: senderName == null || senderName.trim().isEmpty
              ? null
              : senderName.trim(),
          sentAt: message.createdAt,
        ),
      );
    }
    return Stack(
      children: [
        _messages.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
                reverse: true,
                padding: resolvedPadding,
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
                keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
                padding: resolvedPadding,
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
                        child: Center(child: Text(l10n.chatNoOlderMessages)),
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
                  final isOptimistic = _optimisticIds.contains(message.id);
                  final imageIndex = imageIndexByMessageId[message.id];
                  final senderName = isMe
                      ? null
                      : _profileNicknames[message.senderId];
                  final resolvedReplyPreview = _resolvedReplyPreview(message);
                  final replySenderName = _displayNameForSenderId(
                    resolvedReplyPreview?.senderId,
                  );
                  return ChatMessageTile(
                    key: ValueKey(message.id),
                    message: resolvedReplyPreview == null
                        ? message
                        : message.copyWith(replyPreview: resolvedReplyPreview),
                    isMe: isMe,
                    isOptimistic: isOptimistic,
                    useLightForeground: widget.useLightForeground,
                    senderName: senderName,
                    replySenderName: replySenderName,
                    onLongPress: _shouldShowActions(message, isMe)
                        ? () => _showMessageActions(message)
                        : null,
                    onSwipeReply: _shouldShowActions(message, isMe)
                        ? () => _requestReply(message)
                        : null,
                    onImageTap: imageIndex == null
                        ? null
                        : () => FullScreenPhotoViewer.open(
                            context,
                            items: imageViewerItems,
                            initialIndex: imageIndex,
                            showIndicator: false,
                          ),
                  );
                },
                separatorBuilder: (context, index) {
                  if (index == _messages.length - 1) {
                    return _DateSeparator(date: _messages[index].createdAt);
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
            right: resolvedPadding.right,
            bottom: resolvedPadding.bottom + (12 * uiScale).clamp(8.0, 12.0),
            child: FloatingActionButton.small(
              onPressed: _scrollToBottom,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        if (_error != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: resolvedPadding.bottom + 8,
            child: IgnorePointer(
              ignoring: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.96,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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

  void _requestReply(ChatMessage message) {
    final callback = widget.onReplyRequested;
    if (callback == null) {
      return;
    }
    callback(
      ChatReplyTarget(
        message: message.copyWith(replyPreview: _resolvedReplyPreview(message)),
        senderName: _displayNameForSenderId(message.senderId),
      ),
    );
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final currentUserId = widget.currentUserId;
    final senderId = message.senderId;
    if (currentUserId == null || senderId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final isBlocked = _blockedUserIds.contains(senderId);
    final copyText = message.body?.trim().isNotEmpty == true
        ? message.body!.trim()
        : (message.caption?.trim().isNotEmpty == true
              ? message.caption!.trim()
              : null);
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: Text(l10n.chatReplyAction),
                onTap: () => Navigator.pop(context, _MessageAction.reply),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_rounded),
                title: Text(l10n.chatCopyAction),
                enabled: copyText != null,
                onTap: copyText == null
                    ? null
                    : () => Navigator.pop(context, _MessageAction.copy),
              ),
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
      case _MessageAction.reply:
        _requestReply(message);
        break;
      case _MessageAction.copy:
        if (copyText != null) {
          await Clipboard.setData(ClipboardData(text: copyText));
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.chatMessageCopied)));
        }
        break;
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
      keyboardDismissBehavior: chatTimelineKeyboardDismissBehavior,
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
