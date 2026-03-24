import 'package:flutter/material.dart';

const ScrollViewKeyboardDismissBehavior chatTimelineKeyboardDismissBehavior =
    ScrollViewKeyboardDismissBehavior.manual;

double resolveChatKeyboardBottomInset({
  required double keyboardInset,
  required double safeAreaInset,
}) => keyboardInset > safeAreaInset ? keyboardInset : safeAreaInset;

class ChatKeyboardSweepDismissLayer extends StatefulWidget {
  const ChatKeyboardSweepDismissLayer({
    super.key,
    required this.focusNode,
    required this.keyboardInset,
    required this.composerKey,
    required this.protectedRegionKey,
    required this.child,
    this.dismissThreshold = 28,
    this.sweepDistanceLimit = 120,
  });

  final FocusNode focusNode;
  final double keyboardInset;
  final GlobalKey composerKey;
  final GlobalKey protectedRegionKey;
  final Widget child;
  final double dismissThreshold;
  final double sweepDistanceLimit;

  @override
  State<ChatKeyboardSweepDismissLayer> createState() =>
      _ChatKeyboardSweepDismissLayerState();
}

class ChatBackSwipePopLayer extends StatefulWidget {
  const ChatBackSwipePopLayer({
    super.key,
    required this.child,
    required this.onPop,
    required this.excludedRegionKey,
    this.triggerDistance = 72,
    this.minFlingVelocity = 700,
  });

  final Widget child;
  final VoidCallback onPop;
  final GlobalKey excludedRegionKey;
  final double triggerDistance;
  final double minFlingVelocity;

  @override
  State<ChatBackSwipePopLayer> createState() => _ChatBackSwipePopLayerState();
}

class _ChatBackSwipePopLayerState extends State<ChatBackSwipePopLayer> {
  int? _activePointer;
  Offset? _startPosition;
  DateTime? _startTime;
  bool _tracking = false;
  bool _popped = false;

  Rect? _globalRectForKey(GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  void _reset() {
    _activePointer = null;
    _startPosition = null;
    _startTime = null;
    _tracking = false;
    _popped = false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    final media = MediaQuery.of(context);
    final excludedRect = _globalRectForKey(widget.excludedRegionKey);
    final isInLeftHalf = event.position.dx <= media.size.width / 2;
    final isExcluded = excludedRect?.contains(event.position) ?? false;
    if (!isInLeftHalf || isExcluded) {
      _reset();
      return;
    }
    _activePointer = event.pointer;
    _startPosition = event.position;
    _startTime = DateTime.now();
    _tracking = true;
    _popped = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_tracking || _popped || _activePointer != event.pointer) {
      return;
    }
    final start = _startPosition;
    if (start == null) {
      return;
    }
    final delta = event.position - start;
    if (delta.dx <= 0) {
      return;
    }
    if (delta.dy.abs() > delta.dx) {
      _tracking = false;
      return;
    }
    if (delta.dx >= widget.triggerDistance) {
      _popped = true;
      widget.onPop();
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_tracking && !_popped && _activePointer == event.pointer) {
      final start = _startPosition;
      final startedAt = _startTime;
      if (start != null && startedAt != null) {
        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        final deltaX = event.position.dx - start.dx;
        final deltaY = (event.position.dy - start.dy).abs();
        final velocity = elapsedMs <= 0 ? 0.0 : (deltaX / elapsedMs) * 1000;
        if (deltaX > 24 &&
            deltaX > deltaY &&
            velocity >= widget.minFlingVelocity) {
          widget.onPop();
        }
      }
    }
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: widget.child,
    );
  }
}

class _ChatKeyboardSweepDismissLayerState
    extends State<ChatKeyboardSweepDismissLayer> {
  int? _activePointer;
  Offset? _dragStartGlobalPosition;
  Offset? _composerEntryGlobalPosition;
  bool _startedInsideComposer = false;
  bool _startedInsideProtectedRegion = false;
  bool _enteredComposer = false;
  bool _dismissedDuringGesture = false;
  bool _startedWithinSweepRange = false;

  bool get _canDismiss => widget.keyboardInset > 0 && widget.focusNode.hasFocus;

  Rect? _globalRectForKey(GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  void _resetGesture() {
    _activePointer = null;
    _dragStartGlobalPosition = null;
    _composerEntryGlobalPosition = null;
    _startedInsideComposer = false;
    _startedInsideProtectedRegion = false;
    _enteredComposer = false;
    _dismissedDuringGesture = false;
    _startedWithinSweepRange = false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_canDismiss) {
      _resetGesture();
      return;
    }
    final composerRect = _globalRectForKey(widget.composerKey);
    if (composerRect == null) {
      _resetGesture();
      return;
    }
    final protectedRect = _globalRectForKey(widget.protectedRegionKey);

    _activePointer = event.pointer;
    _dragStartGlobalPosition = event.position;
    _startedInsideComposer = composerRect.contains(event.position);
    _startedInsideProtectedRegion =
        protectedRect?.contains(event.position) ?? false;

    final distAbove = composerRect.top - event.position.dy;
    _startedWithinSweepRange =
        distAbove >= 0 && distAbove <= widget.sweepDistanceLimit;

    _enteredComposer = _startedInsideComposer && !_startedInsideProtectedRegion;
    _composerEntryGlobalPosition = _enteredComposer ? event.position : null;
    _dismissedDuringGesture = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_canDismiss ||
        _dismissedDuringGesture ||
        _activePointer != event.pointer) {
      return;
    }

    final start = _dragStartGlobalPosition;
    if (start == null) {
      return;
    }

    final composerRect = _globalRectForKey(widget.composerKey);
    if (composerRect == null) {
      return;
    }

    final currentInsideComposer = composerRect.contains(event.position);
    final protectedRect = _globalRectForKey(widget.protectedRegionKey);
    final currentInsideProtected =
        protectedRect?.contains(event.position) ?? false;

    if (!_enteredComposer && currentInsideComposer) {
      if (currentInsideProtected) {
        return;
      }
      if (_startedWithinSweepRange) {
        _enteredComposer = true;
        _composerEntryGlobalPosition = event.position;
      } else if (_startedInsideComposer && !_startedInsideProtectedRegion) {
        _enteredComposer = true;
        _composerEntryGlobalPosition = start;
      }
    }

    if (!_enteredComposer) {
      return;
    }

    final entry = _composerEntryGlobalPosition;
    if (entry == null) {
      return;
    }

    final dragSinceEntry = event.position.dy - entry.dy;
    if (dragSinceEntry < widget.dismissThreshold) {
      return;
    }

    _dismissedDuringGesture = true;
    widget.focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _resetGesture(),
      onPointerCancel: (_) => _resetGesture(),
      child: widget.child,
    );
  }
}

class ChatComposerDismissShell extends StatefulWidget {
  const ChatComposerDismissShell({
    super.key,
    required this.focusNode,
    required this.keyboardInset,
    required this.child,
    this.contentKey,
    this.handleKey,
    this.dismissThreshold = 28,
    this.handleHeight = 12,
  });

  final FocusNode focusNode;
  final double keyboardInset;
  final Widget child;
  final Key? contentKey;
  final Key? handleKey;
  final double dismissThreshold;
  final double handleHeight;

  @override
  State<ChatComposerDismissShell> createState() =>
      _ChatComposerDismissShellState();
}

class _ChatComposerDismissShellState extends State<ChatComposerDismissShell> {
  double _dragDistance = 0;
  bool _dismissedDuringGesture = false;

  bool get _canDismiss => widget.keyboardInset > 0 && widget.focusNode.hasFocus;

  void _handleDragStart(DragStartDetails details) {
    if (!_canDismiss) {
      return;
    }
    _dragDistance = 0;
    _dismissedDuringGesture = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_canDismiss || _dismissedDuringGesture) {
      return;
    }
    final deltaY = details.delta.dy;
    if (deltaY <= 0) {
      return;
    }
    _dragDistance += deltaY;
    if (_dragDistance < widget.dismissThreshold) {
      return;
    }
    _dismissedDuringGesture = true;
    widget.focusNode.unfocus();
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragDistance = 0;
    _dismissedDuringGesture = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        KeyedSubtree(key: widget.contentKey, child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.handleHeight,
          child: GestureDetector(
            key: widget.handleKey,
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: _handleDragStart,
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            onVerticalDragCancel: () {
              _dragDistance = 0;
              _dismissedDuringGesture = false;
            },
          ),
        ),
      ],
    );
  }
}
