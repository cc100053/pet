part of 'chat_room_view_v2.dart';

/// Message-action & moderation domain for [_ChatRoomViewV2State]: reply,
/// edit/delete, reaction sheets, report/block, and member sheets.
/// Extracted from chat_room_view_v2.dart verbatim (behavior-preserving).
extension _ChatMessageActions on _ChatRoomViewV2State {
  void _requestReply(ChatMessage message) {
    _setStateChat(() => _replyTargetMessageId = message.id);
    _composerFocusNode.requestFocus();
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
                            textAlign: TextAlign.center,
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
                            textAlign: TextAlign.center,
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

  Future<bool> _confirmDeleteMessage({bool isPhoto = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showJuiceToast<bool>(
      context: context,
      position: JuicePosition.center,
      tone: AppDialogTone.danger,
      message: isPhoto
          ? l10n.feedRecallPhotoTitle
          : l10n.chatDeleteMessageTitle,
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
                isPhoto
                    ? l10n.feedRecallPhotoConfirm
                    : l10n.chatDeleteMessageConfirm,
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
                            textAlign: TextAlign.center,
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
                            isPhoto
                                ? l10n.feedRecallPhotoAction
                                : l10n.chatDeleteAction,
                            textAlign: TextAlign.center,
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
    final isImageFeed = message.type == 'image_feed';
    if (message.isDeleted || !(message.type == 'text' || isImageFeed)) {
      return;
    }
    if (!await _confirmDeleteMessage(isPhoto: isImageFeed) || !mounted) {
      return;
    }

    final userId =
        _runtime?.currentUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    final previous = _messagesById[message.id] ?? message;
    // Recalling a photo also drops its image + caption so the tombstone shows
    // nothing leaked; the server applies the same change.
    final optimistic = previous.copyWith(
      clearBody: true,
      clearImageUrl: isImageFeed,
      clearLocalImagePath: isImageFeed,
      clearCaption: isImageFeed,
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
    // Editing stays text-only; recall (delete) also covers the user's own
    // photos so a sent photo can be un-sent.
    final canEdit = isMine && message.type == 'text';
    final canDelete =
        isMine && (message.type == 'text' || message.type == 'image_feed');
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
        editEnabled: canEdit,
        deleteEnabled: canDelete,
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
                        textAlign: TextAlign.center,
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
                        textAlign: TextAlign.center,
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
}
