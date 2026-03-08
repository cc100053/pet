import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/chat/chat_message.dart';

class ChatMessageRepository {
  ChatMessageRepository._(this._client);

  static final ChatMessageRepository instance = ChatMessageRepository._(
    Supabase.instance.client,
  );

  static const String _boxName = 'chat_messages';
  static const int _maxMessagesPerRoom = 200;

  final SupabaseClient _client;
  Box<dynamic>? _box;

  bool get isReady => _box != null;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<List<ChatMessage>> loadCachedMessages(String roomId) async {
    final box = _box;
    if (box == null) {
      return const [];
    }
    final raw = box.get(roomId);
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((entry) => ChatMessage.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
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

  Future<List<ChatMessage>> fetchMessages({
    required String roomId,
    String? beforeCreatedAt,
    String? beforeId,
    int limit = 20,
  }) async {
    var query = _client
        .from('messages')
        .select(
          'id,room_id,sender_id,type,body,image_url,caption,coins_awarded,'
          'created_at,client_created_at,labels,reply_to_message_id',
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
}
