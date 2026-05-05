part of 'chat_room_view_v2.dart';

class _ChatHistoryLoadingOverlay extends StatelessWidget {
  const _ChatHistoryLoadingOverlay({
    super.key,
    required this.label,
    required this.isDarkBackground,
  });

  final String label;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkBackground
        ? Colors.black.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;
    final spinnerColor = isDarkBackground
        ? Colors.white
        : AppTheme.primaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.1,
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpToLatestPill extends StatelessWidget {
  const _JumpToLatestPill({
    super.key,
    required this.label,
    required this.pendingCount,
    required this.isDarkBackground,
    required this.onTap,
  });

  final String label;
  final int pendingCount;
  final bool isDarkBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkBackground
        ? const Color(0xFF222B35).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textSecondary;
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: TextFieldTapRegion(
        child: InkWell(
          key: const ValueKey('chatJumpToLatestButton'),
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward_rounded, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  key: const ValueKey('chatJumpToLatestLabel'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const ValueKey('chatScrollToLatestPendingCount'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _TelegramComposer extends StatefulWidget {
  const _TelegramComposer({
    required this.controller,
    required this.focusNode,
    required this.surfaceKey,
    required this.inputRegionKey,
    required this.interactionRegionKey,
    required this.keyboardInset,
    required this.bottomInset,
    required this.hintText,
    required this.isDarkBackground,
    required this.onHeightChanged,
    required this.onSend,
    this.onAttachmentTap,
    this.replyPreview,
    this.replySenderName,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey surfaceKey;
  final GlobalKey inputRegionKey;
  final GlobalKey interactionRegionKey;
  final double keyboardInset;
  final double bottomInset;
  final String hintText;
  final bool isDarkBackground;
  final ValueChanged<double> onHeightChanged;
  final Future<void> Function(String text)? onSend;
  final VoidCallback? onAttachmentTap;
  final ChatMessage? replyPreview;
  final String? replySenderName;
  final VoidCallback? onCancelReply;

  @override
  State<_TelegramComposer> createState() => _TelegramComposerState();
}

class _TelegramComposerState extends State<_TelegramComposer> {
  final GlobalKey _measureKey = GlobalKey();
  bool _measureScheduled = false;

  bool get _hasText => widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _scheduleComposerMeasure();
  }

  @override
  void didUpdateWidget(covariant _TelegramComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    if (oldWidget.replyPreview != widget.replyPreview ||
        oldWidget.replySenderName != widget.replySenderName ||
        oldWidget.isDarkBackground != widget.isDarkBackground) {
      _scheduleComposerMeasure();
    }
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
    _scheduleComposerMeasure();
  }

  void _scheduleComposerMeasure() {
    if (!mounted || _measureScheduled) {
      return;
    }
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measureComposer();
    });
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
    widget.onHeightChanged(renderBox.size.height);
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
    final replySenderLabel = widget.replySenderName?.trim().isNotEmpty == true
        ? widget.replySenderName!.trim()
        : AppLocalizations.of(context)!.chatPartnerLabel;

    return Positioned(
      left: 12,
      right: 12,
      bottom: widget.bottomInset,
      child: ChatComposerDismissShell(
        focusNode: widget.focusNode,
        keyboardInset: widget.keyboardInset,
        contentKey: widget.interactionRegionKey,
        handleKey: const ValueKey('chatComposerDismissHandle'),
        child: Padding(
          key: _measureKey,
          padding: EdgeInsets.zero,
          child: Row(
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
                  key: widget.surfaceKey,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.replyPreview != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ChatReplyPreviewPanel(
                                  key: const ValueKey(
                                    'chatComposerReplyPreview',
                                  ),
                                  senderName: replySenderLabel,
                                  previewText:
                                      PetChatMessageAdapter.previewTextForMessage(
                                        widget.replyPreview!,
                                        AppLocalizations.of(context)!,
                                      ),
                                  accentColor: AppTheme.primaryColor,
                                  senderColor: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  previewTextColor: isDark
                                      ? Colors.white.withValues(alpha: 0.66)
                                      : AppTheme.textSecondary,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppTheme.primaryColor.withValues(
                                          alpha: 0.07,
                                        ),
                                  iconColor: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : AppTheme.textSecondary,
                                  isImage: widget.replyPreview!.isImageFeed,
                                  compact: true,
                                  maxLines: 1,
                                  padding: const EdgeInsets.fromLTRB(
                                    9,
                                    6,
                                    9,
                                    6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              IconButton(
                                onPressed: widget.onCancelReply,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.74)
                                      : AppTheme.textSecondary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                splashRadius: 14,
                                tooltip: AppLocalizations.of(
                                  context,
                                )!.commonCancel,
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              key: widget.inputRegionKey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: TextField(
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                key: const ValueKey('chatComposerTextField'),
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
                                  hintStyle: TextStyle(
                                    color: hintColor,
                                    fontSize: 15,
                                  ),
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
                        ],
                      ),
                    ],
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
            key: const ValueKey('chatComposerSendButton'),
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

class ReplySwipeWrapper extends StatefulWidget {
  const ReplySwipeWrapper({
    super.key,
    required this.child,
    required this.onTriggered,
  });

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<ReplySwipeWrapper> createState() => _ReplySwipeWrapperState();
}

class _ReplySwipeWrapperState extends State<ReplySwipeWrapper>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 32;

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
        if (details.delta.dx >= 0 || _triggered) {
          return;
        }
        _controller.stop();
        setState(() {
          _dragOffset = (_dragOffset + (-details.delta.dx)).clamp(0.0, 84.0);
        });
        if (_dragOffset >= _triggerDistance) {
          _triggered = true;
          widget.onTriggered();
          _animateBack();
        }
      },
      onHorizontalDragEnd: (_) {
        if (!_triggered) {
          _animateBack();
        }
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
              : PetAnimatedImage(
                  sourceAsset: petAssetPath!,
                  width: petAssetSize,
                  height: petAssetSize,
                  fit: BoxFit.contain,
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
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: useDarkSurface
              ? Colors.black.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: useDarkSurface
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: useDarkSurface ? 0.10 : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
