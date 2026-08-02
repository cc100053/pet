import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/chat/chat_message.dart';

typedef ChatReactionDetailsRowsLoader =
    Future<List<Map<String, dynamic>>> Function({
      required String roomId,
      required String messageId,
    });

class ChatMessageRepository {
  ChatMessageRepository({
    SupabaseClient? client,
    Box<dynamic>? box,
    ChatReactionDetailsRowsLoader? reactionDetailsRowsLoader,
  }) : _client = client,
       _box = box,
       _reactionDetailsRowsLoader = reactionDetailsRowsLoader;

  static final ChatMessageRepository instance = ChatMessageRepository(
    client: Supabase.instance.client,
  );

  static const String _boxName = 'chat_messages';
  static const int _maxMessagesPerRoom = 20;

  /// Reserved key inside the message box. Room ids are UUIDs, so this cannot
  /// collide with a cached room entry.
  static const String _blockedUserIdsKey = '__blocked_user_ids__';

  final SupabaseClient? _client;
  Box<dynamic>? _box;
  final ChatReactionDetailsRowsLoader? _reactionDetailsRowsLoader;

  bool get isReady => _box != null;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<List<ChatMessage>> loadCachedMessages(
    String roomId, {
    int limit = _maxMessagesPerRoom,
  }) async {
    final box = _box;
    if (box == null) {
      return const [];
    }
    final raw = box.get(roomId);
    if (raw is! List) {
      return const [];
    }

    final messages = raw
        .whereType<Map>()
        .map((entry) => ChatMessage.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
    if (limit >= messages.length) {
      return messages;
    }
    return messages.sublist(0, limit);
  }

  Future<void> cacheMessages(String roomId, List<ChatMessage> messages) async {
    final box = _box;
    if (box == null) {
      return;
    }

    final sorted = [...messages]
      ..sort((a, b) {
        final createdCompare = b.createdAt.compareTo(a.createdAt);
        if (createdCompare != 0) {
          return createdCompare;
        }
        return b.id.compareTo(a.id);
      });

    final payload = sorted
        .take(_maxMessagesPerRoom)
        .map((message) => message.toCacheJson())
        .toList();

    await box.put(roomId, payload);
  }

  /// Blocked-sender ids persisted for [userId].
  ///
  /// The block list decides which cached messages are allowed to paint, so it
  /// has to be available synchronously-fast at room entry — otherwise showing
  /// the Hive message cache first would flash a blocked sender's message.
  /// Scoped to the blocker so a different account on the same device cannot
  /// inherit a stale list.
  Future<Set<String>> loadCachedBlockedUserIds(String userId) async {
    final box = _box;
    if (box == null || userId.isEmpty) {
      return const <String>{};
    }
    final raw = box.get(_blockedUserIdsKey);
    if (raw is! Map || raw['user_id'] != userId) {
      return const <String>{};
    }
    final ids = raw['ids'];
    if (ids is! List) {
      return const <String>{};
    }
    return ids
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> cacheBlockedUserIds(
    String userId,
    Set<String> blockedUserIds,
  ) async {
    final box = _box;
    if (box == null || userId.isEmpty) {
      return;
    }
    await box.put(_blockedUserIdsKey, <String, dynamic>{
      'user_id': userId,
      'ids': blockedUserIds.toList(growable: false),
    });
  }

  Future<List<ChatMessage>> fetchMessages({
    required String roomId,
    String? beforeCreatedAt,
    String? beforeId,
    int limit = 20,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('ChatMessageRepository client is not configured.');
    }

    var query = client
        .from('messages')
        .select(
          'id,room_id,sender_id,type,body,image_url,caption,coins_awarded,'
          'created_at,client_created_at,labels,reply_to_message_id,'
          'edited_at,deleted_at,deleted_by',
        )
        .eq('room_id', roomId);

    if (beforeCreatedAt != null && beforeId != null) {
      query = query.or(
        'created_at.lt.$beforeCreatedAt,'
        'and(created_at.eq.$beforeCreatedAt,id.lt.$beforeId)',
      );
    }

    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    final rows = response as List<dynamic>;
    return rows
        .map((row) => ChatMessage.fromJson(row))
        .where((message) => message.type.isNotEmpty)
        .toList();
  }

  Future<Map<String, List<ChatMessageReactionSummary>>> fetchReactionSummaries({
    required String roomId,
    required List<String> messageIds,
    required String currentUserId,
  }) async {
    if (messageIds.isEmpty) {
      return const <String, List<ChatMessageReactionSummary>>{};
    }

    final client = _client;
    if (client == null) {
      throw StateError('ChatMessageRepository client is not configured.');
    }

    final response = await client
        .from('message_reactions')
        .select('message_id,emoji,user_id')
        .eq('room_id', roomId)
        .inFilter('message_id', messageIds);
    final rows = response as List<dynamic>;
    final grouped = <String, Map<String, _ReactionAccumulator>>{};

    for (final row in rows) {
      final record = Map<String, dynamic>.from(row as Map);
      final messageId = (record['message_id'] as String? ?? '').trim();
      final emoji = (record['emoji'] as String? ?? '').trim();
      final userId = (record['user_id'] as String? ?? '').trim();
      if (messageId.isEmpty || emoji.isEmpty || userId.isEmpty) {
        continue;
      }

      final byEmoji = grouped.putIfAbsent(
        messageId,
        () => <String, _ReactionAccumulator>{},
      );
      final accumulator = byEmoji.putIfAbsent(
        emoji,
        () => _ReactionAccumulator(emoji: emoji),
      );
      accumulator.count += 1;
      if (userId == currentUserId) {
        accumulator.reactedByMe = true;
      }
    }

    return grouped.map((messageId, byEmoji) {
      final summaries =
          byEmoji.values
              .map(
                (accumulator) => ChatMessageReactionSummary(
                  emoji: accumulator.emoji,
                  count: accumulator.count,
                  reactedByMe: accumulator.reactedByMe,
                ),
              )
              .toList()
            ..sort((a, b) {
              final countCompare = b.count.compareTo(a.count);
              if (countCompare != 0) {
                return countCompare;
              }
              return a.emoji.compareTo(b.emoji);
            });
      return MapEntry(messageId, summaries);
    });
  }

  Future<List<ChatMessageReactionDetail>> fetchReactionDetails({
    required String roomId,
    required String messageId,
  }) async {
    if (messageId.trim().isEmpty) {
      return const <ChatMessageReactionDetail>[];
    }

    final reactionDetailsRowsLoader = _reactionDetailsRowsLoader;
    final rows = reactionDetailsRowsLoader != null
        ? await reactionDetailsRowsLoader(roomId: roomId, messageId: messageId)
        : await _defaultFetchReactionDetailRows(
            roomId: roomId,
            messageId: messageId,
          );

    final details =
        rows
            .map(ChatMessageReactionDetail.fromJson)
            .where(
              (detail) =>
                  detail.messageId.isNotEmpty &&
                  detail.userId.isNotEmpty &&
                  detail.emoji.isNotEmpty,
            )
            .toList()
          ..sort((a, b) {
            final createdCompare = b.createdAt.compareTo(a.createdAt);
            if (createdCompare != 0) {
              return createdCompare;
            }
            final emojiCompare = a.emoji.compareTo(b.emoji);
            if (emojiCompare != 0) {
              return emojiCompare;
            }
            return a.userId.compareTo(b.userId);
          });
    return details;
  }

  Future<List<Map<String, dynamic>>> _defaultFetchReactionDetailRows({
    required String roomId,
    required String messageId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('ChatMessageRepository client is not configured.');
    }

    final response = await client
        .from('message_reactions')
        .select('message_id,user_id,emoji,created_at')
        .eq('room_id', roomId)
        .eq('message_id', messageId)
        .order('created_at', ascending: false)
        .order('emoji', ascending: true)
        .order('user_id', ascending: true);
    return (response as List<dynamic>)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}

class _ReactionAccumulator {
  _ReactionAccumulator({required this.emoji});

  final String emoji;
  int count = 0;
  bool reactedByMe = false;
}
