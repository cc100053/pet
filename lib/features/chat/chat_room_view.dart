import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/app_dialog.dart';
import 'package:pet/shared/ui/status_bar_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/app_ui_scale.dart';
import '../../services/review/review_prompt_service.dart';
import '../../services/auth/session_utils.dart';
import '../feed/feed_capture_view.dart';
import 'chat_message_list.dart';
import 'blocked_users_sheet.dart';
import 'chat_message.dart';

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({
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
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

/// GlobalKey to allow parent to notify child of new messages
final _chatMessageListKey = GlobalKey<ChatMessageListState>();

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _messageController = TextEditingController();
  final Map<String, String> _optimisticFeedImageByTempId = {};
  bool _shouldExitAfterFeedSend = false;
  bool _sending = false;
  int? _memberCount;

  @override
  void initState() {
    super.initState();
    _memberCount = widget.memberCount;
    if (_memberCount == null) {
      _fetchMemberCount();
    }
  }

  Future<void> _fetchMemberCount() async {
    try {
      final count = await Supabase.instance.client
          .from('room_members')
          .count(CountOption.exact)
          .eq('room_id', widget.roomId)
          .eq('is_active', true);
      if (mounted) {
        setState(() => _memberCount = count);
      }
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
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

    setState(() {
      _sending = true;
    });

    // Clear immediately for better UX
    _messageController.clear();

    // Create optimistic message
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
      labels: const [],
      localImagePath: null,
    );

    // Add optimistic message immediately
    _chatMessageListKey.currentState?.addOptimisticMessage(optimisticMessage);

    try {
      final insertedMessage = await Supabase.instance.client
          .from('messages')
          .insert({
            'room_id': widget.roomId,
            'sender_id': userId,
            'type': 'text',
            'body': text,
            'client_created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();
      final insertedMessageId = insertedMessage['id'] as String?;
      if (insertedMessageId != null) {
        unawaited(_notifyTextMessage(insertedMessageId));
      }
      _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
      _chatMessageListKey.currentState?.refreshLatest();
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'success'},
      );
      if (!mounted) {
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
      AnalyticsService.instance.logEvent(
        'message_send',
        parameters: {'result': 'failure'},
      );
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
        setState(() {
          _sending = false;
        });
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
      // Notification delivery issues should not block chat send success.
    }
  }

  Future<void> _openFeedCamera() async {
    if (widget.isRoomLocked) {
      final l10n = AppLocalizations.of(context)!;
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
      final l10n = AppLocalizations.of(context)!;
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
    _chatMessageListKey.currentState?.refreshLatest();
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
    _chatMessageListKey.currentState?.addOptimisticMessage(optimisticMessage);
  }

  void _handleFeedUploadCompleted(FeedUploadResult result) {
    final optimisticImage = _optimisticFeedImageByTempId.remove(result.tempId);
    _chatMessageListKey.currentState?.removeOptimisticMessage(result.tempId);
    _chatMessageListKey.currentState?.refreshLatest();
    widget.onFeedUploaded?.call(result, optimisticImage ?? result.imageUrl);
    unawaited(ReviewPromptService.instance.onFeedCompletedSuccessfully());
  }

  void _handleFeedUploadFailed(String tempId, Object error) {
    _optimisticFeedImageByTempId.remove(tempId);
    _chatMessageListKey.currentState?.removeOptimisticMessage(tempId);
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
        onBlockListChanged: () =>
            _chatMessageListKey.currentState?.refreshAfterBlockChange(),
      ),
    );

    if (changed == true) {
      _chatMessageListKey.currentState?.refreshAfterBlockChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context)!;
    final useLightForeground = widget.isDarkBackground;
    final media = MediaQuery.of(context);
    final uiScale = appUiScale(media.size.width);
    final topBarHeight = (64.0 * uiScale).clamp(56.0, 64.0);
    final composerHeight = (64.0 * uiScale).clamp(54.0, 64.0);
    final composerButtonSize = (42.0 * uiScale).clamp(36.0, 42.0);
    final composerIconSize = (26.0 * uiScale).clamp(20.0, 26.0);
    final composerOuterHorizontalPadding = (8.0 * uiScale).clamp(6.0, 8.0);
    final composerInnerHorizontalPadding = (10.0 * uiScale).clamp(8.0, 10.0);
    final composerVerticalPadding = (6.0 * uiScale).clamp(4.0, 6.0);
    final listTopPadding = media.padding.top + topBarHeight + 12;
    final composerBottomInset = media.padding.bottom;
    final listBottomPadding = composerHeight + composerBottomInset + 16;

    final overlayStyle = AppStatusBarStyles.forBackground(
      isDark: widget.isDarkBackground,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
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
            useLightForeground: useLightForeground,
            onBack: () => Navigator.of(context).maybePop(),
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
                  if (value == 'block' && currentUserId != null) {
                    _openBlockedUsers();
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
        body: Container(
          decoration: widget.backgroundDecoration,
          child: Stack(
            children: [
              Positioned.fill(
                child: ChatMessageList(
                  key: _chatMessageListKey,
                  roomId: widget.roomId,
                  currentUserId: currentUserId,
                  useLightForeground: useLightForeground,
                  contentPadding: EdgeInsets.fromLTRB(
                    16,
                    listTopPadding,
                    16,
                    listBottomPadding,
                  ),
                ),
              ),
              Positioned(
                left: 12 * uiScale,
                right: 12 * uiScale,
                bottom: 10 * uiScale,
                child: SafeArea(
                  top: false,
                  child: _GlassPill(
                    backgroundOpacity: useLightForeground ? 0.35 : 0.55,
                    useDarkSurface: useLightForeground,
                    padding: EdgeInsets.fromLTRB(
                      composerOuterHorizontalPadding,
                      composerVerticalPadding,
                      composerInnerHorizontalPadding,
                      composerVerticalPadding,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: (_sending || widget.isRoomLocked)
                              ? null
                              : _openFeedCamera,
                          icon: SvgPicture.asset(
                            'assets/icon/solar--camera-linear.svg',
                            width: composerIconSize,
                            height: composerIconSize,
                            colorFilter: ColorFilter.mode(
                              useLightForeground
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppTheme.textSecondary,
                              BlendMode.srcIn,
                            ),
                          ),
                          tooltip: l10n.feedTitle,
                          iconSize: composerIconSize,
                          constraints: BoxConstraints.tightFor(
                            width: composerButtonSize,
                            height: composerButtonSize,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) =>
                                _sending ? null : _sendMessage(),
                            decoration: InputDecoration(
                              hintText: l10n.chatMessageHint,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: (10.0 * uiScale).clamp(8.0, 10.0),
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.transparent,
                              hintStyle: TextStyle(
                                color: useLightForeground
                                    ? Colors.white.withValues(alpha: 0.72)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: (15.0 * uiScale).clamp(13.0, 15.0),
                              color: useLightForeground
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                            cursorColor: useLightForeground
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(width: (6.0 * uiScale).clamp(4.0, 6.0)),
                        Tooltip(
                          message: l10n.commonSend,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _sending ? null : _sendMessage,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: composerButtonSize,
                                height: composerButtonSize,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icon/mingcute--send-plane-line.svg',
                                    width: composerIconSize,
                                    height: composerIconSize,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    required this.menuButton,
  });

  final String petName;
  final String? memberCount;
  final double uiScale;
  final bool useLightForeground;
  final VoidCallback onBack;
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
    this.backgroundOpacity = 0.72,
    this.useDarkSurface = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double backgroundOpacity;
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
                ? Colors.black.withValues(alpha: backgroundOpacity)
                : Colors.white.withValues(alpha: backgroundOpacity),
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
