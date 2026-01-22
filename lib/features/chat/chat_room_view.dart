import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../services/chat/chat_message_repository.dart';
import '../../services/performance/performance_service.dart';
import '../../shared/ui/cached_network_image_view.dart';
import '../feed/feed_capture_view.dart';
import 'blocked_users_sheet.dart';
import 'widgets/chat_message_tile.dart';
import 'chat_message.dart';

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({super.key, required this.roomId});

  final String roomId;

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

/// GlobalKey to allow parent to notify child of new messages
final _chatMessageListKey = GlobalKey<ChatMessageListState>();

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

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
            AppLocalizations.of(context)!.chatSendFailed(error.toString()),
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

  void _handleFeedUploadCompleted(String tempId) {
    _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
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
          AppLocalizations.of(context)!.feedUploadFailed(error.toString()),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        actions: [
          IconButton(
            onPressed: currentUserId == null ? null : () => _openBlockedUsers(),
            icon: const Icon(Icons.block),
            tooltip: l10n.blockedUsersTitle,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(
              key: _chatMessageListKey,
              roomId: widget.roomId,
              currentUserId: currentUserId,
            ),
          ),
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _openFeedCamera,
                  icon: const Icon(Icons.camera_alt_rounded),
                  color: AppTheme.textSecondary,
                  tooltip: l10n.feedTitle,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sending ? null : _sendMessage(),
                      decoration: InputDecoration(
                        hintText: l10n.chatMessageHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        isDense: true,
                        filled: false,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  color: AppTheme.primaryColor,
                  tooltip: l10n.commonSend,
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.roomId,
    required this.currentUserId,
    this.scrollController,
    this.contentPadding,
  });

  final String roomId;
  final String? currentUserId;
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
        )!.chatRefreshFailed(error.toString());
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
        )!.chatLoadCacheFailed(error.toString());
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
        )!.chatLoadBlockedUsersFailed(error.toString());
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
        )!.chatLoadMessagesFailed(error.toString());
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
        )!.chatLoadMoreFailed(error.toString());
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

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial && _messages.isEmpty) {
      return const _ChatLoadingList();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                        return ChatMessageTile(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: isMe,
                          isOptimistic: isOptimistic,
                          onLongPress: _shouldShowActions(message, isMe)
                              ? () => _showMessageActions(message)
                              : null,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 2),
                      itemCount: _messages.length + 1,
                    ),
              if (_showScrollToBottom)
                Positioned(
                  right: 16,
                  bottom: 16,
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
            AppLocalizations.of(context)!.chatReportFailed(error.toString()),
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
            AppLocalizations.of(context)!.chatBlockFailed(error.toString()),
          ),
        ),
      );
    }
  }

  Future<String?> _promptReportReason(BuildContext context) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatReportMessageTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.chatReportHint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(
                context,
                text.isEmpty ? l10n.chatReportNoReason : text,
              );
            },
            child: Text(l10n.commonSubmit),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }
}

class _ChatLoadingList extends StatelessWidget {
  const _ChatLoadingList();

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
