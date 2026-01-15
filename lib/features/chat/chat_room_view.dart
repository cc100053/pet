import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../feed/feed_capture_view.dart';

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({super.key, required this.roomId});

  final String roomId;

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

/// GlobalKey to allow parent to notify child of new messages
final _chatMessageListKey = GlobalKey<_ChatMessageListState>();

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
        const SnackBar(content: Text('Please sign in again.')),
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
      if (!mounted) {
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _openFeedCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCaptureView(roomId: widget.roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
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
            minimum: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _openFeedCamera,
                  icon: const Icon(Icons.photo_camera),
                  tooltip: 'Feed',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sending ? null : _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  tooltip: 'Send',
                ),
              ],
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
  });

  final String roomId;
  final String? currentUserId;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 120;

  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _messageIds = {};
  final Set<String> _optimisticIds = {}; // Track temp message IDs

  RealtimeChannel? _channel;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _showScrollToBottom = false;
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
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
    setState(() {
      _loadingInitial = true;
      _error = null;
    });

    try {
      final page = await _fetchMessages();
      if (!mounted) {
        return;
      }
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load messages: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
        });
      }
    }
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load more: $error';
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
    var query = Supabase.instance.client
        .from('messages')
        .select(
          'id,room_id,sender_id,type,body,image_url,caption,coins_awarded,'
          'created_at,client_created_at,labels',
        )
        .eq('room_id', widget.roomId);

    if (beforeCreatedAt != null && beforeId != null) {
      query = query.or(
        'created_at.lt.$beforeCreatedAt,'
        'and(created_at.eq.$beforeCreatedAt,id.lt.$beforeId)',
      );
    }

    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(_pageSize);
    final rows = response as List<dynamic>;
    return rows
        .map((row) => ChatMessage.fromJson(row))
        .where((message) => message.type.isNotEmpty)
        .toList();
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
        if (!mounted) {
          return;
        }
        setState(() {
          // Remove any optimistic messages with matching body/senderId
          if (message.senderId != null) {
            _messages.removeWhere((m) =>
                _optimisticIds.contains(m.id) &&
                m.senderId == message.senderId &&
                m.body == message.body);
            _optimisticIds.removeWhere((id) =>
                _messages.every((m) => m.id != id));
          }
          // Add the real message if not already present
          if (_messageIds.add(message.id)) {
            _messages.insert(0, message);
            _sortMessages();
          }
        });
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
    if (_loadingInitial) {
      return const _ChatLoadingList();
    }

    final theme = Theme.of(context);
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No messages yet. Start the chat below.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      reverse: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: Text('No older messages.')),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                child: const Text('Load older messages'),
                              ),
                            ),
                          );
                        }

                        final message = _messages[index];
                        final isMe =
                            message.senderId != null &&
                            message.senderId == widget.currentUserId;
                        return ChatMessageTile(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: isMe,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
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
}

class _ChatLoadingList extends StatelessWidget {
  const _ChatLoadingList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = theme.colorScheme.surfaceContainerHighest;

    Widget bubble({
      required Alignment alignment,
      required double widthFactor,
    }) {
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

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    super.key,
    required this.message,
    required this.isMe,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Center(
        child: Text(
          message.body ?? 'System update',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final crossAxisAlignment =
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final theme = Theme.of(context);
    final senderLabel = isMe ? 'You' : 'Partner';

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            senderLabel,
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          if (message.isImageFeed)
            _FeedMessageCard(
              message: message,
              isMe: isMe,
            )
          else
            _TextMessageBubble(
              message: message,
              isMe: isMe,
            ),
        ],
      ),
    );
  }
}

class _TextMessageBubble extends StatelessWidget {
  const _TextMessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.body ?? '',
        style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
      ),
    );
  }
}

class _FeedMessageCard extends StatelessWidget {
  const _FeedMessageCard({
    required this.message,
    required this.isMe,
  });

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.image_not_supported,
                color: theme.colorScheme.outline,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.stars, size: 16),
              const SizedBox(width: 6),
              Text(
                message.coinsAwarded > 0
                    ? '+${message.coinsAwarded} coins'
                    : 'Feed',
                style: theme.textTheme.labelMedium?.copyWith(color: textColor),
              ),
            ],
          ),
          if (message.caption != null && message.caption!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message.caption!,
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.body,
    required this.imageUrl,
    required this.caption,
    required this.coinsAwarded,
    required this.createdAt,
    required this.clientCreatedAt,
    required this.labels,
  });

  final String id;
  final String roomId;
  final String? senderId;
  final String type;
  final String? body;
  final String? imageUrl;
  final String? caption;
  final int coinsAwarded;
  final DateTime createdAt;
  final DateTime? clientCreatedAt;
  final List<Map<String, dynamic>> labels;

  bool get isSystem => type == 'system';
  bool get isImageFeed => type == 'image_feed';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as String?) ?? '',
      roomId: (json['room_id'] as String?) ?? '',
      senderId: json['sender_id'] as String?,
      type: (json['type'] as String?) ?? '',
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      coinsAwarded: (json['coins_awarded'] as int?) ?? 0,
      createdAt: _parseDate(json['created_at']),
      clientCreatedAt: _parseOptionalDate(json['client_created_at']),
      labels: _parseLabels(json['labels']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<Map<String, dynamic>> _parseLabels(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return const [];
  }
}
