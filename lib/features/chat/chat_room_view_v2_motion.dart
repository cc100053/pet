part of 'chat_room_view_v2.dart';

// Telegram-style timeline motion. Every animation here is driven by a start
// time kept in the room state rather than in the widget, because list items
// are rebuilt under a new key (temp -> confirmed id swap, scroll recycling)
// and a time-based start lets the new element resume instead of restarting.

/// 0..1 progress of a motion that began at [startedAt].
double _motionProgress(DateTime startedAt, Duration duration) {
  final elapsed = DateTime.now().difference(startedAt).inMicroseconds;
  return (elapsed / duration.inMicroseconds).clamp(0.0, 1.0);
}

/// Launch point and landing geometry of a just-sent bubble.
class _SendFlyInSpec {
  _SendFlyInSpec({this.source});

  static const Duration duration = Duration(milliseconds: 340);

  /// Global rect of the composer input the bubble launches from. Null while a
  /// photo send waits for the camera route to finish closing; the bubble stays
  /// hidden until it is set (or the spec is dropped and it lands in place).
  Rect? source;
  DateTime? startedAt;
  double? itemBottom;
  double? bubbleLeft;

  bool get isDone =>
      startedAt != null && _motionProgress(startedAt!, duration) >= 1;
}

/// Telegram-style send: the bubble rises out of the composer input and glides
/// to its slot while the item grows from zero height, so older messages slide
/// up in step instead of jumping.
class _SendFlyIn extends StatefulWidget {
  const _SendFlyIn({
    required this.spec,
    required this.messageId,
    required this.surfaceRegistry,
    required this.child,
  });

  final _SendFlyInSpec spec;
  final String messageId;
  final Map<String, BuildContext> surfaceRegistry;
  final Widget child;

  @override
  State<_SendFlyIn> createState() => _SendFlyInState();
}

class _SendFlyInState extends State<_SendFlyIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _SendFlyInSpec.duration,
  );
  bool _measureScheduled = false;

  @override
  void initState() {
    super.initState();
    final startedAt = widget.spec.startedAt;
    if (startedAt != null) {
      _controller.forward(
        from: _motionProgress(startedAt, _SendFlyInSpec.duration),
      );
    } else {
      _maybeScheduleMeasure();
    }
  }

  @override
  void didUpdateWidget(covariant _SendFlyIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeScheduleMeasure();
  }

  void _maybeScheduleMeasure() {
    final spec = widget.spec;
    if (_measureScheduled || spec.source == null || spec.startedAt != null) {
      return;
    }
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measureAndStart();
    });
  }

  void _measureAndStart() {
    final spec = widget.spec;
    if (!mounted || spec.startedAt != null) {
      return;
    }
    final item = context.findRenderObject();
    final surface = widget.surfaceRegistry[widget.messageId]
        ?.findRenderObject();
    if (item is! RenderBox ||
        !item.hasSize ||
        surface is! RenderBox ||
        !surface.hasSize) {
      // Can't place the launch point; land in place rather than guess.
      spec.startedAt = DateTime.now().subtract(_SendFlyInSpec.duration);
      _controller.value = 1;
      return;
    }
    // Measured at heightFactor 0, where the item's top == bottom. In the
    // reversed list that bottom edge stays put while the item grows.
    spec
      ..itemBottom = item.localToGlobal(Offset.zero).dy
      ..bubbleLeft = surface.localToGlobal(Offset.zero).dx
      ..startedAt = DateTime.now();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_controller.isCompleted) {
          return child!;
        }
        final spec = widget.spec;
        final source = spec.source;
        final itemBottom = spec.itemBottom;
        final bubbleLeft = spec.bubbleLeft;
        if (source == null || itemBottom == null || bubbleLeft == null) {
          // Waiting to launch: laid out for measuring, not yet visible.
          return Align(
            alignment: Alignment.topCenter,
            heightFactor: 0,
            child: Opacity(opacity: 0, child: child),
          );
        }
        final t = Curves.easeOutCubic.transform(_controller.value);
        // Align alone moves the bubble up by its own height; the translate
        // adds the rest of the path from the input, shrinking to zero at t=1.
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: t,
          child: Transform.translate(
            offset: Offset(
              (source.left - bubbleLeft) * (1 - t),
              (source.top - itemBottom) * (1 - t),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Incoming message entrance: the item grows from zero height (older messages
/// slide up) while the bubble rises from below, fades in and settles from a
/// slightly smaller scale toward its sender side.
class _ChatEntrance extends StatefulWidget {
  const _ChatEntrance({
    required this.startedAt,
    required this.isSentByMe,
    required this.child,
  });

  static const Duration duration = Duration(milliseconds: 300);

  final DateTime startedAt;
  final bool isSentByMe;
  final Widget child;

  @override
  State<_ChatEntrance> createState() => _ChatEntranceState();
}

class _ChatEntranceState extends State<_ChatEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _ChatEntrance.duration,
  )..forward(from: _motionProgress(widget.startedAt, _ChatEntrance.duration));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_controller.isCompleted) {
          return child!;
        }
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Align(
          alignment: Alignment.topCenter,
          heightFactor: t,
          child: Opacity(
            opacity: (_controller.value * 1.6).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.9 + 0.1 * t,
              alignment: widget.isSentByMe
                  ? Alignment.bottomRight
                  : Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Own-message send status next to the bubble time: a clock while the row is
/// optimistic, then a check that pops in when the server confirms it.
class _SendStatusIcon extends StatefulWidget {
  const _SendStatusIcon({
    required this.isSending,
    required this.confirmedAt,
    required this.color,
  });

  static const Duration duration = Duration(milliseconds: 280);

  final bool isSending;

  /// When this message was confirmed in this session; the check pops only if
  /// that was just now, not for history scrolled back into view.
  final DateTime? confirmedAt;
  final Color? color;

  @override
  State<_SendStatusIcon> createState() => _SendStatusIconState();
}

class _SendStatusIconState extends State<_SendStatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _SendStatusIcon.duration,
  );

  @override
  void initState() {
    super.initState();
    final confirmedAt = widget.confirmedAt;
    if (!widget.isSending && confirmedAt != null) {
      _controller.forward(
        from: _motionProgress(confirmedAt, _SendStatusIcon.duration),
      );
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _SendStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSending != widget.isSending) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isSending
        ? Icon(Icons.schedule_rounded, size: 11, color: widget.color)
        : Icon(Icons.done_rounded, size: 13, color: widget.color);
    return SizedBox(
      width: 14,
      height: 13,
      child: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutBack,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
