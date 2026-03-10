import 'package:flutter/material.dart';

const ScrollViewKeyboardDismissBehavior chatTimelineKeyboardDismissBehavior =
    ScrollViewKeyboardDismissBehavior.manual;

class ChatKeyboardSweepDismissLayer extends StatefulWidget {
  const ChatKeyboardSweepDismissLayer({
    super.key,
    required this.focusNode,
    required this.keyboardInset,
    required this.composerKey,
    required this.protectedRegionKey,
    required this.child,
    this.dismissThreshold = 28,
  });

  final FocusNode focusNode;
  final double keyboardInset;
  final GlobalKey composerKey;
  final GlobalKey protectedRegionKey;
  final Widget child;
  final double dismissThreshold;

  @override
  State<ChatKeyboardSweepDismissLayer> createState() =>
      _ChatKeyboardSweepDismissLayerState();
}

class _ChatKeyboardSweepDismissLayerState
    extends State<ChatKeyboardSweepDismissLayer> {
  int? _activePointer;
  Offset? _dragStartGlobalPosition;
  bool _startedInsideComposer = false;
  bool _startedInsideProtectedRegion = false;
  bool _dismissedDuringGesture = false;

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
    _startedInsideComposer = false;
    _startedInsideProtectedRegion = false;
    _dismissedDuringGesture = false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_canDismiss) {
      _resetGesture();
      return;
    }
    final composerRect = _globalRectForKey(widget.composerKey);
    final protectedRect = _globalRectForKey(widget.protectedRegionKey);
    if (composerRect == null) {
      _resetGesture();
      return;
    }
    _activePointer = event.pointer;
    _dragStartGlobalPosition = event.position;
    _startedInsideComposer = composerRect.contains(event.position);
    _startedInsideProtectedRegion =
        protectedRect?.contains(event.position) ?? false;
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

    final protectedRect = _globalRectForKey(widget.protectedRegionKey);
    final totalDeltaY = event.position.dy - start.dy;
    if (totalDeltaY < widget.dismissThreshold) {
      return;
    }

    final currentInsideComposer = composerRect.contains(event.position);
    final currentInsideProtected =
        protectedRect?.contains(event.position) ?? false;
    final startedAboveComposer = start.dy < composerRect.top;
    final startedInComposerChrome =
        _startedInsideComposer && !_startedInsideProtectedRegion;
    final crossedIntoComposer = startedAboveComposer && currentInsideComposer;
    final draggedWithinComposerChrome =
        startedInComposerChrome && !currentInsideProtected;

    if (!crossedIntoComposer && !draggedWithinComposerChrome) {
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
