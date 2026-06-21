part of 'chat_room_view_v2.dart';

/// build() helpers for [_ChatRoomViewV2State], extracted verbatim to keep the
/// main build method readable (behavior-preserving).
extension _ChatBuildHelpers on _ChatRoomViewV2State {
  PreferredSizeWidget _buildChatAppBar(
    BuildContext context,
    AppLocalizations l10n,
    double uiScale,
    double topBarHeight,
    SystemUiOverlayStyle overlayStyle,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      systemOverlayStyle: overlayStyle,
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
    );
  }

  fc.Builders _chatMessageBuilders(
    AppLocalizations l10n,
    MediaQueryData media,
    double composerBottomInset,
    double listTopPadding,
    double listBottomPadding,
    ChatMessage? replyTarget,
  ) {
    return fc.Builders(
      textMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            final domainMessage = _messagesById[message.id];
            final resolvedReplyPreview = domainMessage == null
                ? null
                : _resolvedReplyPreview(domainMessage);
            final replyTap =
                domainMessage == null || domainMessage.replyToMessageId == null
                ? null
                : () => _jumpToReplySource(domainMessage);
            return _TelegramTextMessageBubble(
              surfaceRegistry: _messageSurfaceContexts,
              message: message,
              index: index,
              isSentByMe: isSentByMe,
              isGroupedWithPrevious:
                  groupStatus != null && !groupStatus.isFirst,
              isGroupedWithNext: groupStatus != null && !groupStatus.isLast,
              isDarkBackground: widget.isDarkBackground,
              isHighlighted: _highlightedMessageId == message.id,
              senderName: _displayNameForSenderId(
                _messagesById[message.id]?.senderId,
              ),
              showSenderName:
                  isSentByMe ||
                  message.id == _historyGroupingBoundaryMessageId ||
                  groupStatus == null ||
                  groupStatus.isFirst,
              replyPreview: resolvedReplyPreview,
              replySenderName: _displayNameForSenderId(
                resolvedReplyPreview?.senderId,
              ),
              mentionCandidates: _mentionCandidates,
              onReplyTap: replyTap,
            );
          },
      composerBuilder: (context) => _TelegramComposer(
        controller: _composerController,
        focusNode: _composerFocusNode,
        surfaceKey: _composerSurfaceKey,
        inputRegionKey: _composerInputRegionKey,
        interactionRegionKey: _composerInteractionRegionKey,
        keyboardInset: media.viewInsets.bottom,
        bottomInset: composerBottomInset,
        hintText: l10n.chatMessageHint,
        isDarkBackground: widget.isDarkBackground,
        onHeightChanged: _handleComposerHeightChanged,
        onAttachmentTap: (_sending || widget.isRoomLocked)
            ? null
            : _openFeedCamera,
        onSend: _sending ? null : _handleSendMessage,
        replyPreview: replyTarget,
        replySenderName: replyTarget == null
            ? null
            : _displayNameForSenderId(replyTarget.senderId),
        onCancelReply: replyTarget == null
            ? null
            : () {
                _setStateChat(() => _replyTargetMessageId = null);
              },
      ),
      systemMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            return _SystemPill(message: message.text);
          },
      customMessageBuilder:
          (context, message, index, {required isSentByMe, groupStatus}) {
            final domainMessage = _messagesById[message.id];
            final resolvedReplyPreview = domainMessage == null
                ? null
                : _resolvedReplyPreview(domainMessage);
            final replyTap =
                domainMessage == null || domainMessage.replyToMessageId == null
                ? null
                : () => _jumpToReplySource(domainMessage);
            return _FeedCard(
              surfaceRegistry: _messageSurfaceContexts,
              message: message,
              isMe: isSentByMe,
              isGroupedWithPrevious:
                  groupStatus != null && !groupStatus.isFirst,
              isGroupedWithNext: groupStatus != null && !groupStatus.isLast,
              isDarkBackground: widget.isDarkBackground,
              isHighlighted: _highlightedMessageId == message.id,
              senderName: _displayNameForSenderId(
                _messagesById[message.id]?.senderId,
              ),
              showSenderName:
                  isSentByMe ||
                  message.id == _historyGroupingBoundaryMessageId ||
                  groupStatus == null ||
                  groupStatus.isFirst,
              replyPreview: resolvedReplyPreview,
              replySenderName: _displayNameForSenderId(
                resolvedReplyPreview?.senderId,
              ),
              onReplyTap: replyTap,
              onTapImage: () => _openFeedViewer(_messagesById[message.id]),
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
            if (domainMessage.isSystem) {
              return child;
            }
            final senderId = domainMessage.senderId;
            final showReceivedAvatar =
                !isSentByMe &&
                senderId != null &&
                (groupStatus == null || groupStatus.isLast);
            Widget content = ChatMessageEnvelope(
              isSentByMe: isSentByMe,
              isDarkBackground: widget.isDarkBackground,
              reactions: domainMessage.reactions,
              isGroupedWithPrevious:
                  groupStatus != null && !groupStatus.isFirst,
              isGroupedWithNext: groupStatus != null && !groupStatus.isLast,
              avatar: senderId == null
                  ? null
                  : _profilesById[senderId]?.avatarUrl,
              fallbackText: _displayNameForSenderId(senderId),
              showReceivedAvatar: showReceivedAvatar,
              onReactionTap: (reaction) {
                unawaited(
                  _showReactionDetailsSheet(
                    domainMessage,
                    initialFilterEmoji: reaction.emoji,
                  ),
                );
              },
              child: child,
            );
            final canReply = canSwipeReplyToMessage(domainMessage);
            if (canReply) {
              content = ReplySwipeWrapper(
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
        final uiMessages = _toUiMessages(_messages).reversed.toList();
        if (uiMessages.isEmpty) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleBackdropTapUp(
              TapUpDetails(kind: PointerDeviceKind.touch),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  l10n.chatEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isDarkBackground
                        ? Colors.white.withValues(alpha: 0.84)
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }
        return DeterministicChatList(
          itemBuilder: itemBuilder,
          messages: uiMessages,
          scrollController: _chatScrollController,
          observerController: _observerController,
          topPadding: listTopPadding,
          bottomPadding: listBottomPadding,
          onMessageLongPress: _handleDeterministicMessageLongPress,
          onBackgroundTap: () =>
              _handleBackdropTapUp(TapUpDetails(kind: PointerDeviceKind.touch)),
        );
      },
      emptyChatListBuilder: (context) => const SizedBox.shrink(),
      loadMoreBuilder: (context) => const SizedBox.shrink(),
    );
  }
}
