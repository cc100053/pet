import 'package:flutter/material.dart';

import '../../../shared/ui/user_avatar.dart';
import '../chat_message.dart';
import 'chat_reaction_bar.dart';

class ChatMessageEnvelope extends StatelessWidget {
  const ChatMessageEnvelope({
    super.key,
    required this.child,
    required this.isSentByMe,
    required this.isDarkBackground,
    required this.reactions,
    this.onReactionTap,
    this.avatar,
    this.fallbackText,
    this.showReceivedAvatar = false,
    this.avatarSlotKey,
    this.avatarKey,
    this.bubbleColumnKey,
    this.reactionBarKey,
  });

  static const double receivedAvatarSize = 32;
  static const double receivedAvatarGap = 8;
  static const double receivedAvatarSlotWidth =
      receivedAvatarSize + receivedAvatarGap;
  static const double receivedAvatarVerticalOffset =
      -(receivedAvatarSize * 0.1);

  final Widget child;
  final bool isSentByMe;
  final bool isDarkBackground;
  final List<ChatMessageReactionSummary> reactions;
  final ValueChanged<ChatMessageReactionSummary>? onReactionTap;
  final String? avatar;
  final String? fallbackText;
  final bool showReceivedAvatar;
  final Key? avatarSlotKey;
  final Key? avatarKey;
  final Key? bubbleColumnKey;
  final Key? reactionBarKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, 4, 2, reactions.isNotEmpty ? 1 : 4),
      child: isSentByMe ? _buildSentLayout() : _buildReceivedLayout(),
    );
  }

  Widget _buildSentLayout() {
    return _buildBubbleColumn(
      crossAxisAlignment: CrossAxisAlignment.end,
      childAlignment: Alignment.centerRight,
    );
  }

  Widget _buildReceivedLayout() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          key: avatarSlotKey,
          width: receivedAvatarSlotWidth,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: showReceivedAvatar
                ? Transform.translate(
                    offset: const Offset(0, receivedAvatarVerticalOffset),
                    child: UserAvatar(
                      key: avatarKey,
                      avatar: avatar,
                      fallbackText: fallbackText,
                      size: receivedAvatarSize,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        _buildBubbleColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          childAlignment: Alignment.centerLeft,
        ),
      ],
    );
  }

  Widget _buildBubbleColumn({
    required CrossAxisAlignment crossAxisAlignment,
    required AlignmentGeometry childAlignment,
  }) {
    const reactionHorizontalInset = 10.0;
    return Container(
      key: bubbleColumnKey,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(alignment: childAlignment, child: child),
          if (reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 2,
                left: isSentByMe ? 2 : reactionHorizontalInset,
                right: isSentByMe ? reactionHorizontalInset : 2,
              ),
              child: Transform.translate(
                offset: const Offset(0, -2),
                child: Container(
                  key: reactionBarKey,
                  child: ChatReactionBar(
                    reactions: reactions,
                    onReactionTap: onReactionTap,
                    alignEnd: isSentByMe,
                    isDarkBackground: isDarkBackground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
