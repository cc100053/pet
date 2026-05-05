part of 'chat_room_view_v2.dart';

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
