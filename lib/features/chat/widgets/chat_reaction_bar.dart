import 'package:flutter/material.dart';

import '../chat_message.dart';

class ChatReactionBar extends StatelessWidget {
  const ChatReactionBar({
    super.key,
    required this.reactions,
    this.pulses,
    this.onReactionTap,
    this.alignEnd = false,
    this.isDarkBackground = false,
  });

  final List<ChatMessageReactionSummary> reactions;

  /// emoji -> when its count changed live. A chip pops in (new) or bounces
  /// (count changed) when its entry is recent; history loads pass nothing.
  final Map<String, DateTime>? pulses;
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
      spacing: 4,
      runSpacing: 4,
      children: reactions.map((reaction) {
        final isActive = reaction.reactedByMe;
        final chip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              // The count-bearing key sits on a leaf so a count change does
              // not recreate the chip and cut its count roll short.
              Text(
                reaction.emoji,
                key: ValueKey<String>(
                  'chatReactionChip_${reaction.emoji}_${reaction.count}',
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              _RollingCount(
                count: reaction.count,
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

        return _ReactionChipPop(
          key: ValueKey<String>('chatReactionChipPop_${reaction.emoji}'),
          changedAt: pulses?[reaction.emoji],
          child: onReactionTap == null
              ? chip
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onReactionTap!(reaction),
                    child: chip,
                  ),
                ),
        );
      }).toList(),
    );
  }
}

/// Pops a chip in when it first appears from a live change, and bounces it
/// when its count changes while on screen.
class _ReactionChipPop extends StatefulWidget {
  const _ReactionChipPop({
    super.key,
    required this.changedAt,
    required this.child,
  });

  static const Duration duration = Duration(milliseconds: 360);

  final DateTime? changedAt;
  final Widget child;

  @override
  State<_ReactionChipPop> createState() => _ReactionChipPopState();
}

class _ReactionChipPopState extends State<_ReactionChipPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _ReactionChipPop.duration,
    value: 1,
  );
  // New chips grow from small; existing ones bounce past full size.
  late Animation<double> _scale = _appear;

  Animation<double> get _appear => Tween<double>(
    begin: 0.3,
    end: 1,
  ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_controller);

  Animation<double> get _bounce => TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.22,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.22,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _playIfRecent(widget.changedAt);
  }

  @override
  void didUpdateWidget(covariant _ReactionChipPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.changedAt != oldWidget.changedAt) {
      _scale = _bounce;
      _playIfRecent(widget.changedAt);
    }
  }

  void _playIfRecent(DateTime? changedAt) {
    if (changedAt == null) {
      return;
    }
    final progress =
        DateTime.now().difference(changedAt).inMicroseconds /
        _ReactionChipPop.duration.inMicroseconds;
    if (progress < 1) {
      _controller.forward(from: progress.clamp(0.0, 1.0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Count that rolls up (or down) to its new value like Telegram's.
class _RollingCount extends StatelessWidget {
  const _RollingCount({required this.count, required this.style});

  final int count;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey<int>(count);
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, isIncoming ? 0.8 : -0.8),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Text('$count', key: ValueKey<int>(count), style: style),
    );
  }
}
