import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/session_utils.dart';

typedef ChatReplyInsertFn =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> payload);
typedef ChatTextInsertFn =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> payload);
typedef ChatReactionDeleteFn =
    Future<void> Function({required String messageId, required String userId});
typedef ChatReactionUpsertFn =
    Future<void> Function(Map<String, dynamic> payload);
typedef ChatNotifyFn =
    Future<void> Function({required String roomId, required String messageId});
typedef ChatAccessTokenProvider = Future<String?> Function();

class ChatMessageActionService {
  ChatMessageActionService({
    SupabaseClient? client,
    ChatTextInsertFn? insertText,
    ChatReplyInsertFn? insertReply,
    ChatReactionDeleteFn? deleteReaction,
    ChatReactionUpsertFn? upsertReaction,
    ChatNotifyFn? notifyTextMessage,
    ChatAccessTokenProvider? accessTokenProvider,
  }) : _client = client,
       _insertText = insertText,
       _insertReply = insertReply,
       _deleteReaction = deleteReaction,
       _upsertReaction = upsertReaction,
       _notifyTextMessage = notifyTextMessage,
       _accessTokenProvider = accessTokenProvider;

  static final ChatMessageActionService instance = ChatMessageActionService();

  final SupabaseClient? _client;
  final ChatTextInsertFn? _insertText;
  final ChatReplyInsertFn? _insertReply;
  final ChatReactionDeleteFn? _deleteReaction;
  final ChatReactionUpsertFn? _upsertReaction;
  final ChatNotifyFn? _notifyTextMessage;
  final ChatAccessTokenProvider? _accessTokenProvider;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;
  static const String _messageSelectClause =
      'id,room_id,sender_id,type,body,image_url,caption,coins_awarded,'
      'created_at,client_created_at,labels,reply_to_message_id';

  Future<String> sendTextMessage({
    required String roomId,
    required String text,
    String? userId,
  }) async {
    final inserted = await sendTextMessageRow(
      roomId: roomId,
      text: text,
      userId: userId,
    );
    final messageId = (inserted['id'] as String? ?? '').trim();
    if (messageId.isEmpty) {
      throw StateError('message_insert_missing_id');
    }
    return messageId;
  }

  Future<Map<String, dynamic>> sendTextMessageRow({
    required String roomId,
    required String text,
    String? userId,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Message text cannot be empty.');
    }

    final resolvedUserId = userId ?? _resolvedClient.auth.currentUser?.id;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      throw StateError('auth_reauth_required');
    }

    final payload = <String, dynamic>{
      'room_id': roomId,
      'sender_id': resolvedUserId,
      'type': 'text',
      'body': trimmedText,
      'client_created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final inserted =
        await (_insertText?.call(payload) ?? _defaultInsertText(payload));
    if (((inserted['id'] as String?) ?? '').trim().isEmpty) {
      throw StateError('message_insert_missing_id');
    }
    return inserted;
  }

  Future<String> sendTextReply({
    required String roomId,
    required String replyToMessageId,
    required String text,
    String? userId,
  }) async {
    final inserted = await sendTextReplyRow(
      roomId: roomId,
      replyToMessageId: replyToMessageId,
      text: text,
      userId: userId,
    );
    final messageId = (inserted['id'] as String? ?? '').trim();
    if (messageId.isEmpty) {
      throw StateError('message_insert_missing_id');
    }
    return messageId;
  }

  Future<Map<String, dynamic>> sendTextReplyRow({
    required String roomId,
    required String replyToMessageId,
    required String text,
    String? userId,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Reply text cannot be empty.');
    }

    final resolvedUserId = userId ?? _resolvedClient.auth.currentUser?.id;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      throw StateError('auth_reauth_required');
    }

    final payload = <String, dynamic>{
      'room_id': roomId,
      'sender_id': resolvedUserId,
      'type': 'text',
      'body': trimmedText,
      'reply_to_message_id': replyToMessageId,
      'client_created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final inserted =
        await (_insertReply?.call(payload) ?? _defaultInsertReply(payload));
    final messageId = (inserted['id'] as String? ?? '').trim();
    if (messageId.isEmpty) {
      throw StateError('message_insert_missing_id');
    }

    await (_notifyTextMessage?.call(roomId: roomId, messageId: messageId) ??
        _defaultNotifyTextMessage(roomId: roomId, messageId: messageId));
    return inserted;
  }

  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String emoji,
    required String? currentReactionEmoji,
    String? userId,
  }) async {
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isEmpty) {
      throw ArgumentError.value(emoji, 'emoji', 'Emoji cannot be empty.');
    }

    final resolvedUserId = userId ?? _resolvedClient.auth.currentUser?.id;
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      throw StateError('auth_reauth_required');
    }

    if (currentReactionEmoji == trimmedEmoji) {
      await (_deleteReaction?.call(
            messageId: messageId,
            userId: resolvedUserId,
          ) ??
          _defaultDeleteReaction(messageId: messageId, userId: resolvedUserId));
      return;
    }

    await (_upsertReaction?.call(<String, dynamic>{
          'message_id': messageId,
          'room_id': roomId,
          'user_id': resolvedUserId,
          'emoji': trimmedEmoji,
        }) ??
        _defaultUpsertReaction(<String, dynamic>{
          'message_id': messageId,
          'room_id': roomId,
          'user_id': resolvedUserId,
          'emoji': trimmedEmoji,
        }));
  }

  Future<Map<String, dynamic>> _defaultInsertText(
    Map<String, dynamic> payload,
  ) async {
    final response = await _resolvedClient
        .from('messages')
        .insert(payload)
        .select(_messageSelectClause)
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> _defaultInsertReply(
    Map<String, dynamic> payload,
  ) async {
    final response = await _resolvedClient
        .from('messages')
        .insert(payload)
        .select(_messageSelectClause)
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> _defaultDeleteReaction({
    required String messageId,
    required String userId,
  }) async {
    await _resolvedClient
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId);
  }

  Future<void> _defaultUpsertReaction(Map<String, dynamic> payload) async {
    await _resolvedClient
        .from('message_reactions')
        .upsert(payload, onConflict: 'message_id,user_id');
  }

  Future<void> _defaultNotifyTextMessage({
    required String roomId,
    required String messageId,
  }) async {
    try {
      final accessToken =
          await (_accessTokenProvider?.call() ?? ensureValidAccessToken());
      if (accessToken == null || accessToken.isEmpty) {
        return;
      }
      final response = await _resolvedClient.functions.invoke(
        'notify_friend',
        headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        body: <String, dynamic>{
          'type': 'chat_message',
          'room_id': roomId,
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
}
