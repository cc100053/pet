import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

/// The coach bubble that teaches 長按換相框 on 房間選擇.
///
/// A long press has no visual form, so nothing on the grid can hint at it —
/// this bubble is the only thing that ever says it out loud. It is owed once
/// per device (`AppSettingsRepository.roomFrameHintSeen`) and points down at
/// the first room card.
///
/// Times itself out with an [AnimationController] rather than a `Timer`: the
/// controller is a scheduled animation, so a widget test's `pumpAndSettle`
/// runs it to completion instead of failing on a pending timer at teardown.
class RoomFrameLongPressHint extends StatefulWidget {
  const RoomFrameLongPressHint({
    super.key,
    required this.onDismissed,
    this.scale = 1,
  });

  /// Fired once, when the bubble has either been tapped or finished its stay.
  /// The caller persists the flag; the bubble never shows itself again.
  final VoidCallback onDismissed;
  final double scale;

  /// Long enough to be noticed on a screen the player is already reading, short
  /// enough that it is gone before it becomes furniture.
  static const Duration visibleFor = Duration(milliseconds: 5200);
  static const Duration _fade = Duration(milliseconds: 320);

  @override
  State<RoomFrameLongPressHint> createState() => _RoomFrameLongPressHintState();
}

class _RoomFrameLongPressHintState extends State<RoomFrameLongPressHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RoomFrameLongPressHint.visibleFor,
  )..forward();

  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _report();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Idempotent: the stay can end and the bubble be tapped in the same frame.
  void _report() {
    if (_reported) {
      return;
    }
    _reported = true;
    widget.onDismissed();
  }

  /// 1 while the bubble stays, easing to 0 across its last [_fade].
  double _opacityAt(double t) {
    final total = RoomFrameLongPressHint.visibleFor.inMilliseconds;
    final fade = RoomFrameLongPressHint._fade.inMilliseconds;
    final fadeStart = (total - fade) / total;
    if (t <= fadeStart) {
      return 1;
    }
    return Curves.easeOut.transform(1 - ((t - fadeStart) / (1 - fadeStart)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = widget.scale;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _opacityAt(_controller.value);
        return IgnorePointer(
          ignoring: opacity <= 0,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: GestureDetector(
          onTap: _report,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBubble(l10n, scale),
              // The tail sits under the bubble's left third, so it lands on the
              // first card rather than between the two columns.
              Padding(
                padding: EdgeInsetsDirectional.only(start: 34 * scale),
                child: CustomPaint(
                  size: Size(16 * scale, 9 * scale),
                  painter: _TailPainter(
                    color: const Color(0xFFFFF4DB),
                    border: AppTheme.secondaryColor.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(AppLocalizations l10n, double scale) {
    // Same cream/gold coach language as the onboarding card, at hint size.
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * scale),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF4), Color(0xFFFFF4DB)],
        ),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.92),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE7B754).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 15 * scale,
            color: AppTheme.primaryColor,
          ),
          Gap(6 * scale),
          Flexible(
            child: Text(
              l10n.roomFrameLongPressHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bubble's downward tail, drawn with the bubble's own fill and border so
/// the two read as one shape.
class _TailPainter extends CustomPainter {
  const _TailPainter({required this.color, required this.border});

  final Color color;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // Only the two slanted edges are drawn: the top edge is the bubble's own
    // bottom border, and stroking it again would double its weight.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.border != border;
}
