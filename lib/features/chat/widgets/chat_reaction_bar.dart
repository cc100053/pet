import 'package:flutter/material.dart';

import '../chat_message.dart';

class ChatReactionBar extends StatelessWidget {
  const ChatReactionBar({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.alignEnd = false,
    this.isDarkBackground = false,
  });

  final List<ChatMessageReactionSummary> reactions;
  final ValueChanged<ChatMessageReactionSummary>? onReactionTap;
  final bool alignEnd;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final surfaceColor = isDarkBackground
        ? const Color(0xFF222B35).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.96);
    final activeSurfaceColor = isDarkBackground
        ? const Color(0xFF305D57)
        : const Color(0xFFE1F3ED);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final activeBorderColor = isDarkBackground
        ? const Color(0xFF7FD4BC).withValues(alpha: 0.5)
        : const Color(0xFF9FD8C7);
    final textColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.84)
        : const Color(0xFF425264);

    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: 6,
      runSpacing: 6,
      children: reactions.map((reaction) {
        final isActive = reaction.reactedByMe;
        final chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? activeSurfaceColor : surfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? activeBorderColor : borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${reaction.count}',
                style: TextStyle(
                  fontSize: 12,
                  height: 1,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        );

        if (onReactionTap == null) {
          return chip;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onReactionTap!(reaction),
            child: chip,
          ),
        );
      }).toList(),
    );
  }
}
