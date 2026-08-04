part of 'chat_room_view_v2.dart';

extension _ChatRoomDataHelpers on _ChatRoomViewV2State {
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
      limit: _ChatRoomViewV2State._pageSize,
    );
    return _FetchedMessagePage(
      messages: page.where(_isVisibleMessage).toList()
        ..sort(_sortByCreatedAtAsc),
      hasMoreOlder: page.length == _ChatRoomViewV2State._pageSize,
    );
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

  bool _canGroupPreviewMessages(ChatMessage a, ChatMessage b) =>
      canGroupSenderNames(a, b);

  /// Ids of the messages whose bubble must render the sender name; see
  /// `chat_sender_name_visibility.dart` for why the chat package's own
  /// `groupStatus` cannot answer this.
  Set<String> _senderNameVisibleMessageIds() => senderNameVisibleMessageIds(
    _toAscendingMessages(_messages),
    historyGroupingBoundaryMessageId: _historyGroupingBoundaryMessageId,
  );

  double? _replyTargetCenterOffset(BuildContext targetContext) {
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
