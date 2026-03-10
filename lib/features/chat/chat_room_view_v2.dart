import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as fc;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatMessage;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pet/shared/ui/app_dialog.dart';
import 'package:pet/shared/ui/full_screen_photo_viewer.dart';
import 'package:pet/shared/ui/photo_viewer_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/auth/session_utils.dart';
import '../../services/chat/chat_message_repository.dart';
import '../../services/profile/profile_cache_service.dart';
import '../../services/review/review_prompt_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/status_bar_style.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_ui_scale.dart';
import '../feed/feed_capture_view.dart';
import '../../shared/ui/cached_network_image_view.dart';
import 'adapters/pet_chat_message_adapter.dart';
import 'blocked_users_sheet.dart';
import 'chat_message.dart';
import 'room_members_sheet.dart';

class ChatRoomViewV2 extends StatefulWidget {
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
    this.onFeedUploaded,
    this.onFeedUploadFailed,
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
  final void Function(FeedUploadResult result, String? imageSource)?
  onFeedUploaded;
  final void Function(String tempId, Object error)? onFeedUploadFailed;

  @override
  State<ChatRoomViewV2> createState() => _ChatRoomViewV2State();
}

enum _MessageAction { reply, copy, report, block }

class _ChatRoomViewV2State extends State<ChatRoomViewV2> {
  static const int _pageSize = 20;

  final ChatMessageRepository _repository = ChatMessageRepository.instance;
  final fc.InMemoryChatController _chatController = fc.InMemoryChatController();
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final Map<String, ChatMessage> _messagesById = <String, ChatMessage>{};
  final Map<String, ProfileSummary> _profilesById = <String, ProfileSummary>{};
  final Map<String, String> _optimisticFeedImageByTempId = <String, String>{};
  final Set<String> _blockedUserIds = <String>{};
  final Set<String> _optimisticIds = <String>{};
  final Set<String> _loadingReplyPreviewIds = <String>{};

  RealtimeChannel? _channel;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _sending = false;
  bool _shouldExitAfterFeedSend = false;
  String? _error;
  String? _replyTargetMessageId;
  String? _highlightedMessageId;
  int? _memberCount;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '__anonymous__';

  @override
  void initState() {
    super.initState();
    _memberCount = widget.memberCount;
    if (_memberCount == null) {
      unawaited(_fetchMemberCount());
    }
    unawaited(_initialize());
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _chatController.dispose();
    _composerController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadBlockedUsers();
    await _loadCachedMessages();
    await _loadInitial();
  }

  Future<void> _fetchMemberCount() async {
    try {
      final count = await Supabase.instance.client
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
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

  Future<void> _refreshAfterBlockChange() async {
    await _loadBlockedUsers();
    await _refreshLatest();
    final visibleMessages = _messages.where(_isVisibleMessage).toList();
    await _setMessages(visibleMessages, animated: false);
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
      final cached = _repository.loadCachedMessages(widget.roomId);
      final messages = _toAscendingMessages(await cached);
      if (!mounted || messages.isEmpty) {
        return;
      }
      await _setMessages(messages, animated: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = null;
      });
      unawaited(_ensureProfilesForMessages(messages));
      unawaited(_ensureReplyPreviewsForMessages(messages));
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
      final page = await _fetchMessages();
      final mergedById = <String, ChatMessage>{
        for (final message in _messages)
          if (!_optimisticIds.contains(message.id)) message.id: message,
      };
      for (final message in page) {
        mergedById[message.id] = message;
      }
      final merged = mergedById.values.toList()..sort(_sortByCreatedAtAsc);
      _hasMore = page.length == _pageSize;
      await _setMessages(merged, animated: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = null;
      });
      unawaited(_ensureProfilesForMessages(merged));
      unawaited(_ensureReplyPreviewsForMessages(merged));
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
      final oldest = _messages.first;
      final page = await _fetchMessages(
        beforeCreatedAt: oldest.createdAt.toUtc().toIso8601String(),
        beforeId: oldest.id,
      );
      final olderMessages =
          page
              .where((message) => !_messagesById.containsKey(message.id))
              .toList()
            ..sort(_sortByCreatedAtAsc);

      _hasMore = page.length == _pageSize;
      if (olderMessages.isNotEmpty) {
        _messages.insertAll(0, olderMessages);
        _rebuildMessageIndex();
        await _chatController.insertAllMessages(
          _toUiMessages(olderMessages),
          index: 0,
          animated: false,
        );
        unawaited(_ensureProfilesForMessages(olderMessages));
        unawaited(_ensureReplyPreviewsForMessages(olderMessages));
        unawaited(_persistCache());
      }
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

  Future<void> _refreshLatest() async {
    try {
      final page = await _fetchMessages();
      final merged = <String, ChatMessage>{
        for (final message in _messages)
          if (!_optimisticIds.contains(message.id)) message.id: message,
      };
      for (final message in page) {
        merged[message.id] = message;
      }
      final allMessages = merged.values.toList()..sort(_sortByCreatedAtAsc);
      _hasMore = page.length == _pageSize;
      await _setMessages(allMessages, animated: false);
      unawaited(_ensureProfilesForMessages(allMessages));
      unawaited(_ensureReplyPreviewsForMessages(allMessages));
      unawaited(_persistCache());
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

  Future<void> _setMessages(
    List<ChatMessage> messages, {
    required bool animated,
  }) async {
    _messages
      ..clear()
      ..addAll(messages.where(_isVisibleMessage));
    _messages.sort(_sortByCreatedAtAsc);
    _rebuildMessageIndex();
    await _chatController.setMessages(
      _toUiMessages(_messages),
      animated: animated,
    );
  }

  void _rebuildMessageIndex() {
    _messagesById
      ..clear()
      ..addEntries(_messages.map((message) => MapEntry(message.id, message)));
  }

  Future<void> _persistCache() async {
    if (!_repository.isReady) {
      return;
    }
    final cacheable = _messages
        .where((message) => !_optimisticIds.contains(message.id))
        .toList();
    await _repository.cacheMessages(widget.roomId, cacheable.reversed.toList());
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
    return page.where(_isVisibleMessage).toList();
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
      bool hasNewProfiles = false;
      for (final entry in profiles.entries) {
        if (!_profilesById.containsKey(entry.key)) {
          _profilesById[entry.key] = entry.value;
          hasNewProfiles = true;
        }
      }
      if (hasNewProfiles) {
        setState(() {});
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
      for (var index = 0; index < _messages.length; index += 1) {
        final message = _messages[index];
        final replyId = message.replyToMessageId;
        if (replyId == null ||
            replyId.isEmpty ||
            message.replyPreview != null ||
            !previewById.containsKey(replyId)) {
          continue;
        }
        _messages[index] = message.copyWith(replyPreview: previewById[replyId]);
      }
      _rebuildMessageIndex();
      setState(() {});
    } catch (_) {
      // Best-effort reply preview loading.
    } finally {
      _loadingReplyPreviewIds.removeAll(replyIds);
    }
  }

  void _subscribeToMessages() {
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
        final message = ChatMessage.fromJson(payload.newRecord);
        if (!mounted || message.type.isEmpty || !_isVisibleMessage(message)) {
          return;
        }
        final duplicateOptimisticId = _findMatchingOptimisticMessageId(message);
        if (duplicateOptimisticId != null) {
          unawaited(_removeMessageById(duplicateOptimisticId, animated: false));
        }
        if (_messagesById.containsKey(message.id)) {
          return;
        }
        unawaited(
          _insertMessage(
            message,
            animated: true,
            isOptimistic: false,
            scrollToLatest: true,
          ),
        );
      },
    );
    channel.subscribe();
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
        final optimisticClient = message.clientCreatedAt?.toIso8601String();
        final incomingClient = incoming.clientCreatedAt?.toIso8601String();
        if (optimisticClient != null &&
            incomingClient != null &&
            optimisticClient == incomingClient) {
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
    final existingIndex = _messages.indexWhere(
      (entry) => entry.id == message.id,
    );
    if (existingIndex != -1) {
      final oldDomain = _messages[existingIndex];
      _messages[existingIndex] = message;
      _rebuildMessageIndex();
      await _chatController.updateMessage(
        _toUiMessage(oldDomain),
        _toUiMessage(message, isOptimistic: isOptimistic),
      );
    } else {
      _messages.add(message);
      _messages.sort(_sortByCreatedAtAsc);
      _rebuildMessageIndex();
      final index = _messages.indexWhere((entry) => entry.id == message.id);
      await _chatController.insertMessage(
        _toUiMessage(message, isOptimistic: isOptimistic),
        index: index == -1 ? null : index,
        animated: animated,
      );
    }

    if (isOptimistic) {
      _optimisticIds.add(message.id);
    } else {
      _optimisticIds.remove(message.id);
    }

    unawaited(_ensureProfilesForMessages([message]));
    unawaited(_ensureReplyPreviewsForMessages([message]));
    unawaited(_persistCache());
    if (scrollToLatest) {
      unawaited(_chatController.scrollToMessage(message.id, alignment: 1));
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _removeMessageById(
    String messageId, {
    required bool animated,
  }) async {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) {
      return;
    }
    final message = _messages.removeAt(index);
    _optimisticIds.remove(messageId);
    _rebuildMessageIndex();
    await _chatController.removeMessage(
      _toUiMessage(message),
      animated: animated,
    );
    unawaited(_persistCache());
    if (mounted) {
      setState(() {});
    }
  }

  fc.Message _toUiMessage(ChatMessage message, {bool? isOptimistic}) {
    return PetChatMessageAdapter.toUiMessage(
      message,
      AppLocalizations.of(context)!,
      isOptimistic: isOptimistic ?? _optimisticIds.contains(message.id),
    );
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

  Future<void> _handleSendMessage(String rawText) async {
    final text = rawText.trim();
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

    final replyTargetId = _replyTargetMessageId;
    final replyTarget = replyTargetId == null
        ? null
        : _messagesById[replyTargetId];

    if (mounted) {
      setState(() {
        _sending = true;
        _replyTargetMessageId = null;
      });
    }

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

    try {
      final insertedMessage = await Supabase.instance.client
          .from('messages')
          .insert({
            'room_id': widget.roomId,
            'sender_id': userId,
            'type': 'text',
            'body': text,
            'reply_to_message_id': replyTarget?.id,
            'client_created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();
      final insertedMessageId = insertedMessage['id'] as String?;
      await _removeMessageById(tempId, animated: false);
      unawaited(_refreshLatest());
      if (insertedMessageId != null) {
        unawaited(_notifyTextMessage(insertedMessageId));
      }
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'success', 'ui': 'flutter_chat_ui_spike'},
      );
    } catch (error) {
      await _removeMessageById(tempId, animated: false);
      _composerController.text = text;
      _composerController.selection = TextSelection.collapsed(
        offset: _composerController.text.length,
      );
      if (mounted) {
        setState(() {
          _replyTargetMessageId = replyTarget?.id;
        });
      }
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'failure', 'ui': 'flutter_chat_ui_spike'},
      );
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
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
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
          onSendStarted: _handleFeedSendStarted,
          onUploadCompleted: _handleFeedUploadCompleted,
          onUploadFailed: _handleFeedUploadFailed,
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

  void _handleOptimisticFeed(FeedOptimisticMessage entry) {
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
    unawaited(
      _insertMessage(
        optimisticMessage,
        animated: true,
        isOptimistic: true,
        scrollToLatest: true,
      ),
    );
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    final optimisticImage = _optimisticFeedImageByTempId.remove(result.tempId);
    unawaited(_removeMessageById(result.tempId, animated: false));
    unawaited(_refreshLatest());
    widget.onFeedUploaded?.call(result, optimisticImage ?? result.imageUrl);
    unawaited(ReviewPromptService.instance.onFeedCompletedSuccessfully());
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    _optimisticFeedImageByTempId.remove(tempId);
    unawaited(_removeMessageById(tempId, animated: false));
    widget.onFeedUploadFailed?.call(tempId, error);
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

  void _requestReply(ChatMessage message) {
    setState(() => _replyTargetMessageId = message.id);
    _composerFocusNode.requestFocus();
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final senderId = message.senderId;
    if (currentUserId == null || senderId == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final isBlocked = _blockedUserIds.contains(senderId);
    final copyText = (message.body ?? '').trim().isNotEmpty
        ? message.body!.trim()
        : ((message.caption ?? '').trim().isNotEmpty
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

    await _chatController.scrollToMessage(
      targetId,
      alignment: 0.25,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final uiScale = appUiScale(media.size.width);
    final topBarHeight = (64.0 * uiScale).clamp(56.0, 64.0);
    final listTopPadding = media.padding.top + topBarHeight + 12;
    final listBottomInset = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 8
        : media.padding.bottom + 8;
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
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Chat(
                  currentUserId: _currentUserId,
                  resolveUser: _resolveUser,
                  chatController: _chatController,
                  decoration: widget.backgroundDecoration,
                  backgroundColor: scaffoldBackground,
                  theme: _chatTheme(context),
                  onMessageSend: _sending ? null : _handleSendMessage,
                  onAttachmentTap: (_sending || widget.isRoomLocked)
                      ? null
                      : _openFeedCamera,
                  onMessageLongPress:
                      (context, message, {required index, required details}) {
                        final domainMessage = _messagesById[message.id];
                        final isMine =
                            domainMessage?.senderId == _currentUserId;
                        if (domainMessage == null ||
                            domainMessage.isSystem ||
                            isMine ||
                            domainMessage.senderId == null) {
                          return;
                        }
                        unawaited(_showMessageActions(domainMessage));
                      },
                  builders: fc.Builders(
                    textMessageBuilder:
                        (
                          context,
                          message,
                          index, {
                          required isSentByMe,
                          groupStatus,
                        }) {
                          return _TelegramTextMessageBubble(
                            message: message,
                            index: index,
                            isSentByMe: isSentByMe,
                            isDarkBackground: widget.isDarkBackground,
                            senderName: _displayNameForSenderId(
                              _messagesById[message.id]?.senderId,
                            ),
                          );
                        },
                    composerBuilder: (context) => _TelegramComposer(
                      controller: _composerController,
                      focusNode: _composerFocusNode,
                      hintText: l10n.chatMessageHint,
                      isDarkBackground: widget.isDarkBackground,
                      onAttachmentTap: (_sending || widget.isRoomLocked)
                          ? null
                          : _openFeedCamera,
                      onSend: _sending ? null : _handleSendMessage,
                      topWidget: replyTarget == null
                          ? null
                          : _ReplyComposerBar(
                              message: replyTarget,
                              senderName: _displayNameForSenderId(
                                replyTarget.senderId,
                              ),
                              isDarkBackground: widget.isDarkBackground,
                              onCancel: () {
                                setState(() => _replyTargetMessageId = null);
                              },
                            ),
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
                          return _FeedCard(
                            message: message,
                            isMe: isSentByMe,
                            senderName: _displayNameForSenderId(
                              _messagesById[message.id]?.senderId,
                            ),
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
                          Widget content = _MessageEnvelope(
                            replyPreview: _resolvedReplyPreview(domainMessage),
                            replySenderName: _displayNameForSenderId(
                              _resolvedReplyPreview(domainMessage)?.senderId,
                            ),
                            isSentByMe: isSentByMe,
                            isDarkBackground: widget.isDarkBackground,
                            isHighlighted:
                                _highlightedMessageId == domainMessage.id,
                            onReplyTap: domainMessage.replyToMessageId == null
                                ? null
                                : () => _jumpToReplySource(domainMessage),
                            child: child,
                          );
                          final canReply =
                              !domainMessage.isSystem &&
                              !isSentByMe &&
                              domainMessage.senderId != null;
                          if (canReply) {
                            content = _ReplySwipeWrapper(
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
                      return ChatAnimatedList(
                        itemBuilder: itemBuilder,
                        reversed: true,
                        onEndReached: _hasMore ? _loadMore : null,
                        topPadding: listTopPadding,
                        bottomPadding: listBottomInset,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                      );
                    },
                    emptyChatListBuilder: (context) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.chatEmptyState,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: widget.isDarkBackground
                                    ? Colors.white.withValues(alpha: 0.84)
                                    : AppTheme.textSecondary,
                              ),
                        ),
                      ),
                    ),
                    loadMoreBuilder: (context) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
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
        ),
      ],
      showIndicator: false,
    );
  }

  int _sortByCreatedAtAsc(ChatMessage a, ChatMessage b) {
    final createdCompare = a.createdAt.compareTo(b.createdAt);
    if (createdCompare != 0) {
      return createdCompare;
    }
    return a.id.compareTo(b.id);
  }
}

class _ReplyComposerBar extends StatelessWidget {
  const _ReplyComposerBar({
    required this.message,
    required this.senderName,
    required this.isDarkBackground,
    required this.onCancel,
  });

  final ChatMessage message;
  final String? senderName;
  final bool isDarkBackground;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : l10n.chatPartnerLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: isDarkBackground
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkBackground
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.chatReplyingTo(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDarkBackground
                        ? Colors.white
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PetChatMessageAdapter.previewTextForMessage(message, l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkBackground
                        ? Colors.white.withValues(alpha: 0.66)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.74)
                  : AppTheme.textSecondary,
            ),
            splashRadius: 16,
            tooltip: l10n.commonCancel,
          ),
        ],
      ),
    );
  }
}

class _TelegramComposer extends StatefulWidget {
  const _TelegramComposer({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.isDarkBackground,
    required this.onSend,
    this.onAttachmentTap,
    this.topWidget,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isDarkBackground;
  final Future<void> Function(String text)? onSend;
  final VoidCallback? onAttachmentTap;
  final Widget? topWidget;

  @override
  State<_TelegramComposer> createState() => _TelegramComposerState();
}

class _TelegramComposerState extends State<_TelegramComposer> {
  final GlobalKey _measureKey = GlobalKey();

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant _TelegramComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureComposer());
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
    context.read<ComposerHeightNotifier>().setHeight(renderBox.size.height);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureComposer());
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final composerBottomInset = keyboardInset > 0
        ? keyboardInset + 8
        : media.padding.bottom + 10;

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

    return Positioned(
      left: 12,
      right: 12,
      bottom: composerBottomInset,
      child: Padding(
        key: _measureKey,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.topWidget != null) widget.topWidget!,
            Row(
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
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
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
                        hintStyle: TextStyle(color: hintColor, fontSize: 15),
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
                const SizedBox(width: 8),
                _ComposerSendButton(
                  enabled: canSend,
                  onTap: canSend ? _handleSend : null,
                  isDarkBackground: isDark,
                ),
              ],
            ),
          ],
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
              boxShadow: isDarkBackground
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
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
    return Center(
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
    );
  }
}

class _TelegramTextMessageBubble extends StatelessWidget {
  const _TelegramTextMessageBubble({
    required this.message,
    required this.index,
    required this.isSentByMe,
    required this.isDarkBackground,
    required this.senderName,
  });

  final fc.TextMessage message;
  final int index;
  final bool isSentByMe;
  final bool isDarkBackground;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final sentBackgroundColor = isDarkBackground
        ? const Color(0xFF3D6E67)
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

    return SimpleTextMessage(
      message: message,
      index: index,
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
      constraints: const BoxConstraints(maxWidth: 296),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isSentByMe ? 20 : 8),
        bottomRight: Radius.circular(isSentByMe ? 8 : 20),
      ),
      sentBackgroundColor: sentBackgroundColor,
      receivedBackgroundColor: receivedBackgroundColor,
      sentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: sentTextColor,
        fontSize: 16,
        height: 1.36,
        fontWeight: FontWeight.w400,
      ),
      receivedTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      topWidget: !isSentByMe && senderName?.trim().isNotEmpty == true
          ? Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                senderName!.trim(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            )
          : null,
      timeAndStatusPosition: fc.TimeAndStatusPosition.inline,
      timeAndStatusPositionInlineInsets: const EdgeInsets.only(bottom: 1),
      showStatus: false,
    );
  }
}

class _MessageEnvelope extends StatelessWidget {
  const _MessageEnvelope({
    required this.child,
    required this.replyPreview,
    required this.replySenderName,
    required this.isSentByMe,
    required this.isDarkBackground,
    required this.isHighlighted,
    required this.onReplyTap,
  });

  final Widget child;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final bool isSentByMe;
  final bool isDarkBackground;
  final bool isHighlighted;
  final VoidCallback? onReplyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final previewSurface = isDarkBackground
        ? const Color(0xFF242B36).withValues(alpha: 0.86)
        : const Color(0xFFF4F7FA);
    final previewTextColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.68)
        : AppTheme.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.primaryColor.withValues(
                alpha: isDarkBackground ? 0.16 : 0.08,
              )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? AppTheme.primaryColor.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Column(
        crossAxisAlignment: isSentByMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyPreview != null)
            Align(
              alignment: isSentByMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 296),
                  child: InkWell(
                    onTap: onReplyTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: previewSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkBackground
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  replySenderName?.trim().isNotEmpty == true
                                      ? replySenderName!.trim()
                                      : l10n.chatPartnerLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: isSentByMe
                                            ? (isDarkBackground
                                                  ? const Color(0xFFA2E0CF)
                                                  : const Color(0xFF4B8F7B))
                                            : AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  PetChatMessageAdapter.previewTextForReply(
                                    replyPreview!,
                                    l10n,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: previewTextColor,
                                        height: 1.25,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: previewTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: isSentByMe
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.onTapImage,
  });

  final fc.CustomMessage message;
  final bool isMe;
  final String? senderName;
  final VoidCallback onTapImage;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? const <String, dynamic>{};
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
    final cardBackground = isMe
        ? (theme.brightness == Brightness.dark
              ? const Color(0xFF365D57)
              : const Color(0xFFDDF3EA))
        : (theme.brightness == Brightness.dark
              ? const Color(0xFF2A313D)
              : Colors.white);
    final cardBorderColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final bubbleTime = _formatBubbleTime(context, message.resolvedTime);
    final senderLabel = !isMe && senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : null;
    final overlaySurface = Colors.black.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.42 : 0.34,
    );
    final overlayBorder = Colors.white.withValues(alpha: 0.16);
    final overlayShadow = Colors.black.withValues(alpha: 0.18);
    final overlayPrimaryText = Colors.white;
    final overlaySecondaryText = Colors.white.withValues(alpha: 0.76);

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
      image = Image.file(File(localPath), fit: BoxFit.cover);
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: overlaySurface,
              borderRadius: borderRadius,
              border: Border.all(color: overlayBorder),
              boxShadow: [
                BoxShadow(
                  color: overlayShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorderColor),
        ),
        child: InkWell(
          onTap: onTapImage,
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (senderLabel != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: buildGlassPill(
                      borderRadius: BorderRadius.circular(999),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        senderLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: overlayPrimaryText,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
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
                          SvgPicture.asset(
                            'assets/icon/icon-park--candy.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '+$coinsAwarded',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: overlayPrimaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (caption.isNotEmpty || bubbleTime != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: buildGlassPill(
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (caption.isNotEmpty)
                            Expanded(
                              child: Text(
                                caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.28,
                                  color: overlayPrimaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (caption.isNotEmpty && bubbleTime != null)
                            const SizedBox(width: 10),
                          if (bubbleTime != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
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
                  ),
              ],
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

class _ReplySwipeWrapper extends StatefulWidget {
  const _ReplySwipeWrapper({required this.child, required this.onTriggered});

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<_ReplySwipeWrapper> createState() => _ReplySwipeWrapperState();
}

class _ReplySwipeWrapperState extends State<_ReplySwipeWrapper>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 64;

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
        if (details.delta.dx >= 0) {
          return;
        }
        _controller.stop();
        setState(() {
          _dragOffset = (_dragOffset + (-details.delta.dx)).clamp(0.0, 84.0);
        });
      },
      onHorizontalDragEnd: (_) {
        final shouldTrigger = _dragOffset >= _triggerDistance && !_triggered;
        if (shouldTrigger) {
          _triggered = true;
          widget.onTriggered();
        }
        _animateBack();
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
              : Image.asset(
                  petAssetPath!,
                  width: petAssetSize,
                  height: petAssetSize,
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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: useDarkSurface
                ? Colors.black.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.72),
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
