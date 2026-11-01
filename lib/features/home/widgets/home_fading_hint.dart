import 'dart:async';

import 'package:flutter/material.dart';

/// Shows [child] briefly, then fades it out after [visibleFor] or as soon as
/// [dismissed] turns true (e.g. the user starts the gesture it teaches). Once
/// faded it stays hidden; give it a new key to show it again.
class HomeFadingHint extends StatefulWidget {
  const HomeFadingHint({
    super.key,
    required this.dismissed,
    required this.child,
    this.visibleFor = const Duration(seconds: 3),
  });

  final bool dismissed;
  final Widget child;
  final Duration visibleFor;

  @override
  State<HomeFadingHint> createState() => _HomeFadingHintState();
}

class _HomeFadingHintState extends State<HomeFadingHint> {
  late final Timer _timer;
  late bool _visible = !widget.dismissed;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.visibleFor, _hide);
  }

  @override
  void didUpdateWidget(HomeFadingHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dismissed) _visible = false;
  }

  void _hide() {
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: widget.child,
      ),
    );
  }
}
