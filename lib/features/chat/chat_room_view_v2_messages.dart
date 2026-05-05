part of 'chat_room_view_v2.dart';

class _MentionTextMessageBubble extends StatelessWidget {
  const _MentionTextMessageBubble({
    required this.message,
    required this.constraints,
    required this.borderRadius,
    required this.backgroundColor,
    required this.padding,
    required this.textSpans,
    required this.timeStyle,
    required this.isEdited,
    this.topWidget,
  });

  final fc.TextMessage message;
  final BoxConstraints constraints;
  final BorderRadiusGeometry borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final List<InlineSpan> textSpans;
  final TextStyle? timeStyle;
  final bool isEdited;
  final Widget? topWidget;

  @override
  Widget build(BuildContext context) {
    final bubbleTime = _formatBubbleTime(context, message.resolvedTime);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        constraints: constraints,
        decoration: BoxDecoration(color: backgroundColor),
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?topWidget,
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: RichText(
                    key: ValueKey<String>('chatMentionRichText_${message.id}'),
                    text: TextSpan(children: textSpans),
                  ),
                ),
                if (bubbleTime != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEdited) ...[
                          Text(
                            AppLocalizations.of(context)!.chatMessageEdited,
                            style: timeStyle,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(bubbleTime, style: timeStyle),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MentionSuggestionsPanel extends StatelessWidget {
  const _MentionSuggestionsPanel({
    required this.candidates,
    required this.isDarkBackground,
    required this.onSelected,
  });

  final List<ChatMentionCandidate> candidates;
  final bool isDarkBackground;
  final ValueChanged<ChatMentionCandidate> onSelected;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkBackground
        ? const Color(0xFF202833).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.98);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;
    final subTextColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.58)
        : AppTheme.textSecondary;

    return TextFieldTapRegion(
      child: Material(
        key: const ValueKey('chatMentionSuggestionsPanel'),
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 184),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: candidates.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              return InkWell(
                key: ValueKey<String>(
                  'chatMentionSuggestion_${candidate.userId}',
                ),
                onTap: () => onSelected(candidate),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        avatar: candidate.avatarUrl,
                        fallbackText: candidate.displayName,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              candidate.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              candidate.mentionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: subTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Center(
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
      ),
    );
  }
}

BorderRadius _buildGroupedBubbleRadius({
  required bool isSentByMe,
  required bool isGroupedWithPrevious,
  required bool isGroupedWithNext,
  double expandedRadius = 20,
  double groupedRadius = 8,
}) {
  if (isSentByMe) {
    return BorderRadius.only(
      topLeft: Radius.circular(expandedRadius),
      topRight: Radius.circular(
        isGroupedWithPrevious ? groupedRadius : expandedRadius,
      ),
      bottomLeft: Radius.circular(expandedRadius),
      bottomRight: Radius.circular(
        isGroupedWithNext ? groupedRadius : expandedRadius,
      ),
    );
  }

  return BorderRadius.only(
    topLeft: Radius.circular(
      isGroupedWithPrevious ? groupedRadius : expandedRadius,
    ),
    topRight: Radius.circular(expandedRadius),
    bottomLeft: Radius.circular(
      isGroupedWithNext ? groupedRadius : expandedRadius,
    ),
    bottomRight: Radius.circular(expandedRadius),
  );
}

class _TelegramTextMessageBubble extends StatelessWidget {
  const _TelegramTextMessageBubble({
    required this.surfaceKey,
    required this.message,
    required this.index,
    required this.isSentByMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.isDarkBackground,
    required this.isHighlighted,
    required this.senderName,
    required this.showSenderName,
    required this.replyPreview,
    required this.replySenderName,
    required this.mentionCandidates,
    required this.onReplyTap,
  });

  final GlobalKey surfaceKey;
  final fc.TextMessage message;
  final int index;
  final bool isSentByMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool isDarkBackground;
  final bool isHighlighted;
  final String? senderName;
  final bool showSenderName;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final List<ChatMentionCandidate> mentionCandidates;
  final VoidCallback? onReplyTap;

  @override
  Widget build(BuildContext context) {
    final sentBackgroundColor = isDarkBackground
        ? const Color(0xFF4E7E76)
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

    final bubbleRadius = _buildGroupedBubbleRadius(
      isSentByMe: isSentByMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
    );
    final replyLabel = replySenderName?.trim().isNotEmpty == true
        ? replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;
    final replyPreviewBackground = isSentByMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F8));

    final metadata = message.metadata ?? const <String, dynamic>{};
    final isEdited =
        metadata[PetChatMessageAdapter.isEditedKey] as bool? ?? false;
    final isDeleted =
        metadata[PetChatMessageAdapter.isDeletedKey] as bool? ?? false;
    final deletedTextStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDarkBackground
              ? Colors.white.withValues(alpha: 0.58)
              : AppTheme.textSecondary.withValues(alpha: 0.78),
          fontSize: 13,
          height: 1.28,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          color: isDarkBackground
              ? Colors.white.withValues(alpha: 0.58)
              : AppTheme.textSecondary.withValues(alpha: 0.78),
          fontSize: 13,
          height: 1.28,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        );

    final mentionSpans = isDeleted
        ? <InlineSpan>[TextSpan(text: message.text, style: deletedTextStyle)]
        : buildChatMentionSpans(
            text: message.text,
            baseStyle:
                (isSentByMe
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: sentTextColor,
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w400,
                      )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: receivedTextColor,
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w400,
                      )) ??
                TextStyle(
                  color: isSentByMe ? sentTextColor : receivedTextColor,
                  fontSize: 16,
                  height: 1.36,
                ),
            mentionStyle:
                (isSentByMe
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkBackground
                            ? const Color(0xFFA2E0CF)
                            : const Color(0xFF276D5A),
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w700,
                      )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        height: 1.36,
                        fontWeight: FontWeight.w700,
                      )) ??
                TextStyle(
                  color: isSentByMe
                      ? const Color(0xFF276D5A)
                      : AppTheme.primaryColor,
                  fontSize: 16,
                  height: 1.36,
                  fontWeight: FontWeight.w700,
                ),
            candidates: mentionCandidates,
          );
    final hasHighlightedMention = mentionSpans.any(
      (span) => span.style?.fontWeight == FontWeight.w700,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: _MessageHighlightFrame(
        isHighlighted: isHighlighted,
        isDarkBackground: isDarkBackground,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          key: ValueKey<String>('chatMessageSurface_${message.id}'),
          child: KeyedSubtree(
            key: surfaceKey,
            child: (hasHighlightedMention || isEdited || isDeleted)
                ? _MentionTextMessageBubble(
                    message: message,
                    constraints: const BoxConstraints(maxWidth: 296),
                    borderRadius: bubbleRadius,
                    backgroundColor: isSentByMe
                        ? sentBackgroundColor
                        : receivedBackgroundColor,
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
                    textSpans: mentionSpans,
                    timeStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: timeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    isEdited: isEdited,
                    topWidget: _buildTextMessageTopWidget(
                      context: context,
                      isSentByMe: isSentByMe,
                      isDarkBackground: isDarkBackground,
                      showSenderName: showSenderName,
                      senderName: senderName,
                      replyPreview: replyPreview,
                      replyLabel: replyLabel,
                      replyPreviewBackground: replyPreviewBackground,
                      onReplyTap: onReplyTap,
                    ),
                  )
                : SimpleTextMessage(
                    message: message,
                    index: index,
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
                    constraints: const BoxConstraints(maxWidth: 296),
                    borderRadius: bubbleRadius,
                    sentBackgroundColor: sentBackgroundColor,
                    receivedBackgroundColor: receivedBackgroundColor,
                    sentTextStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: sentTextColor,
                          fontSize: 16,
                          height: 1.36,
                          fontWeight: FontWeight.w400,
                        ),
                    receivedTextStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
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
                    topWidget: _buildTextMessageTopWidget(
                      context: context,
                      isSentByMe: isSentByMe,
                      isDarkBackground: isDarkBackground,
                      showSenderName: showSenderName,
                      senderName: senderName,
                      replyPreview: replyPreview,
                      replyLabel: replyLabel,
                      replyPreviewBackground: replyPreviewBackground,
                      onReplyTap: onReplyTap,
                    ),
                    timeAndStatusPosition: fc.TimeAndStatusPosition.inline,
                    timeAndStatusPositionInlineInsets: const EdgeInsets.only(
                      bottom: 1,
                    ),
                    showStatus: false,
                  ),
          ),
        ),
      ),
    );
  }

  Widget? _buildTextMessageTopWidget({
    required BuildContext context,
    required bool isSentByMe,
    required bool isDarkBackground,
    required bool showSenderName,
    required String? senderName,
    required ChatReplyPreview? replyPreview,
    required String replyLabel,
    required Color replyPreviewBackground,
    required VoidCallback? onReplyTap,
  }) {
    if (!isSentByMe &&
        (!showSenderName || senderName?.trim().isNotEmpty != true) &&
        replyPreview == null) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isSentByMe &&
            showSenderName &&
            senderName?.trim().isNotEmpty == true)
          Padding(
            padding: EdgeInsets.only(bottom: replyPreview == null ? 4 : 6),
            child: Text(
              senderName!.trim(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        if (replyPreview != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChatReplyPreviewPanel(
              key: const ValueKey('chatTextBubbleReplyPreview'),
              senderName: replyLabel,
              previewText: PetChatMessageAdapter.previewTextForReply(
                replyPreview,
                AppLocalizations.of(context)!,
              ),
              accentColor: AppTheme.primaryColor,
              senderColor: isSentByMe
                  ? (isDarkBackground
                        ? const Color(0xFFA2E0CF)
                        : const Color(0xFF4B8F7B))
                  : AppTheme.primaryColor,
              previewTextColor: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.68)
                  : AppTheme.textSecondary,
              backgroundColor: replyPreviewBackground,
              iconColor: isDarkBackground
                  ? Colors.white.withValues(alpha: 0.58)
                  : AppTheme.textSecondary.withValues(alpha: 0.8),
              isImage: replyPreview.isImageFeed,
              showJumpIcon: true,
              compact: true,
              maxLines: 1,
              onTap: onReplyTap,
            ),
          ),
      ],
    );
  }
}

class _MessageActionTextPreviewBubble extends StatelessWidget {
  const _MessageActionTextPreviewBubble({
    required this.message,
    required this.isSentByMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.isDarkBackground,
    required this.senderName,
    required this.showSenderName,
    required this.replyPreview,
    required this.replySenderName,
    required this.onReplyTap,
  });

  final ChatMessage message;
  final bool isSentByMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool isDarkBackground;
  final String? senderName;
  final bool showSenderName;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final VoidCallback? onReplyTap;

  @override
  Widget build(BuildContext context) {
    final sentBackgroundColor = isDarkBackground
        ? const Color(0xFF4E7E76)
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
    final bubbleRadius = _buildGroupedBubbleRadius(
      isSentByMe: isSentByMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
    );
    final replyLabel = replySenderName?.trim().isNotEmpty == true
        ? replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;
    final replyPreviewBackground = isSentByMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F8));
    final bodyText = (message.body ?? '').trim();
    final bubbleTime = _formatBubbleTime(context, message.createdAt);

    return _MessageHighlightFrame(
      isHighlighted: false,
      isDarkBackground: isDarkBackground,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: isSentByMe ? sentBackgroundColor : receivedBackgroundColor,
          borderRadius: bubbleRadius,
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSentByMe &&
                showSenderName &&
                senderName?.trim().isNotEmpty == true)
              Padding(
                padding: EdgeInsets.only(bottom: replyPreview == null ? 4 : 6),
                child: Text(
                  senderName!.trim(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            if (replyPreview != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChatReplyPreviewPanel(
                  senderName: replyLabel,
                  previewText: PetChatMessageAdapter.previewTextForReply(
                    replyPreview!,
                    AppLocalizations.of(context)!,
                  ),
                  accentColor: AppTheme.primaryColor,
                  senderColor: isSentByMe
                      ? (isDarkBackground
                            ? const Color(0xFFA2E0CF)
                            : const Color(0xFF4B8F7B))
                      : AppTheme.primaryColor,
                  previewTextColor: isDarkBackground
                      ? Colors.white.withValues(alpha: 0.68)
                      : AppTheme.textSecondary,
                  backgroundColor: replyPreviewBackground,
                  iconColor: isDarkBackground
                      ? Colors.white.withValues(alpha: 0.58)
                      : AppTheme.textSecondary.withValues(alpha: 0.8),
                  isImage: replyPreview!.isImageFeed,
                  showJumpIcon: true,
                  compact: true,
                  maxLines: 1,
                  onTap: onReplyTap,
                ),
              ),
            Text(
              bodyText.isNotEmpty
                  ? bodyText
                  : AppLocalizations.of(context)!.chatMessageHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSentByMe ? sentTextColor : receivedTextColor,
                fontSize: 16,
                height: 1.36,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (bubbleTime != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    bubbleTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: timeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageHighlightFrame extends StatelessWidget {
  const _MessageHighlightFrame({
    required this.child,
    required this.isHighlighted,
    required this.isDarkBackground,
    required this.borderRadius,
  });

  final Widget child;
  final bool isHighlighted;
  final bool isDarkBackground;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final highlightBorder = AppTheme.primaryColor.withValues(
      alpha: isDarkBackground ? 0.42 : 0.34,
    );
    final highlightFill = AppTheme.primaryColor.withValues(
      alpha: isDarkBackground ? 0.10 : 0.06,
    );
    final highlightShadow = AppTheme.primaryColor.withValues(
      alpha: isDarkBackground ? 0.26 : 0.18,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isHighlighted ? highlightFill : Colors.transparent,
        borderRadius: borderRadius,
        border: Border.all(
          color: isHighlighted ? highlightBorder : Colors.transparent,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: highlightShadow,
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.surfaceKey,
    required this.message,
    required this.isMe,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
    required this.isDarkBackground,
    required this.isHighlighted,
    required this.senderName,
    required this.showSenderName,
    required this.replyPreview,
    required this.replySenderName,
    required this.onReplyTap,
    required this.onTapImage,
  });

  final GlobalKey surfaceKey;
  final fc.CustomMessage message;
  final bool isMe;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final bool isDarkBackground;
  final bool isHighlighted;
  final String? senderName;
  final bool showSenderName;
  final ChatReplyPreview? replyPreview;
  final String? replySenderName;
  final VoidCallback? onReplyTap;
  final VoidCallback onTapImage;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? const <String, dynamic>{};
    final media = MediaQuery.of(context);
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
    final localImageCacheWidth = (280 * media.devicePixelRatio).round();
    final localImageCacheHeight = ((280 * 5 / 4) * media.devicePixelRatio)
        .round();
    final cardBackground = isMe
        ? (isDarkBackground ? const Color(0xFF4E7E76) : const Color(0xFFDDF3EA))
        : (isDarkBackground ? const Color(0xFF2A313D) : Colors.white);
    final cardTextColor = isMe && !isDarkBackground
        ? const Color(0xFF1E3B34)
        : (isDarkBackground ? Colors.white : AppTheme.textPrimary);
    final cardBorderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final bubbleTime = _formatBubbleTime(context, message.resolvedTime);
    final senderLabel =
        !isMe && showSenderName && senderName?.trim().isNotEmpty == true
        ? senderName!.trim()
        : null;
    final replyLabel = replySenderName?.trim().isNotEmpty == true
        ? replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;
    final metadataTimeColor = isMe
        ? (isDarkBackground
              ? Colors.white.withValues(alpha: 0.72)
              : const Color(0xFF4B7B6D))
        : (isDarkBackground
              ? Colors.white.withValues(alpha: 0.5)
              : AppTheme.textSecondary.withValues(alpha: 0.82));
    final overlaySurface = Colors.black.withValues(
      alpha: isDarkBackground ? 0.42 : 0.34,
    );
    final overlayBorder = Colors.white.withValues(alpha: 0.16);
    final overlayShadow = Colors.black.withValues(alpha: 0.18);
    final overlayPrimaryText = Colors.white;
    final overlaySecondaryText = Colors.white.withValues(alpha: 0.76);
    final cardRadius = _buildGroupedBubbleRadius(
      isSentByMe: isMe,
      isGroupedWithPrevious: isGroupedWithPrevious,
      isGroupedWithNext: isGroupedWithNext,
      expandedRadius: 18,
      groupedRadius: 9,
    );

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
      image = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        cacheWidth: localImageCacheWidth,
        cacheHeight: localImageCacheHeight,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
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
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: overlaySurface,
            borderRadius: borderRadius,
            border: Border.all(color: overlayBorder),
            boxShadow: [
              BoxShadow(
                color: overlayShadow.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: _MessageHighlightFrame(
        isHighlighted: isHighlighted,
        isDarkBackground: isDarkBackground,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          key: ValueKey<String>('chatMessageSurface_${message.id}'),
          child: KeyedSubtree(
            key: surfaceKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: cardRadius,
                  border: Border.all(color: cardBorderColor),
                ),
                child: InkWell(
                  onTap: onTapImage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (replyPreview != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: ChatReplyPreviewPanel(
                            key: const ValueKey('chatFeedCardReplyPreview'),
                            senderName: replyLabel,
                            previewText:
                                PetChatMessageAdapter.previewTextForReply(
                                  replyPreview!,
                                  AppLocalizations.of(context)!,
                                ),
                            accentColor: AppTheme.primaryColor,
                            senderColor: isMe
                                ? (isDarkBackground
                                      ? const Color(0xFFA2E0CF)
                                      : const Color(0xFF4B8F7B))
                                : AppTheme.primaryColor,
                            previewTextColor: isDarkBackground
                                ? Colors.white.withValues(alpha: 0.68)
                                : AppTheme.textSecondary,
                            backgroundColor: isDarkBackground
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF1F5F8),
                            iconColor: isDarkBackground
                                ? Colors.white.withValues(alpha: 0.58)
                                : AppTheme.textSecondary.withValues(alpha: 0.8),
                            isImage: replyPreview!.isImageFeed,
                            showJumpIcon: true,
                            compact: true,
                            maxLines: 1,
                            onTap: onReplyTap,
                          ),
                        ),
                      if (replyPreview != null) const SizedBox(height: 10),
                      if (senderLabel != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Text(
                            senderLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(child: image),
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
                                      Image.asset(
                                        'assets/shop/icon/candy.png',
                                        width: 14,
                                        height: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        PetChatMessageAdapter.feedRewardLabel(
                                          coinsAwarded,
                                          AppLocalizations.of(context)!,
                                        ),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: overlayPrimaryText,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (bubbleTime != null && caption.isEmpty)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: buildGlassPill(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
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
                      if (caption.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.35,
                                    color: cardTextColor,
                                  ),
                                ),
                              ),
                              if (bubbleTime != null) ...[
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: Text(
                                    bubbleTime,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: metadataTimeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
