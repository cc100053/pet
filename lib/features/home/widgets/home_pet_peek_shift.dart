import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Moves a room pet by [shift] while [hidden] (furniture mode), so it walks off
/// to peek over the room's bottom edge and walks back afterwards. [builder]
/// gets `walking` during the trip and the facing to use for it (null when the
/// pet's own facing applies). Bumping [cheerTick] while hidden makes it hop.
class HomePetPeekShift extends StatefulWidget {
  const HomePetPeekShift({
    super.key,
    required this.hidden,
    required this.shift,
    required this.cheerTick,
    required this.builder,
  });

  final bool hidden;
  final Offset shift;
  final int cheerTick;
  final Widget Function(bool walking, bool? facingRight) builder;

  static const tripDuration = Duration(milliseconds: 700);
  static const hopHeight = 14.0;

  @override
  State<HomePetPeekShift> createState() => _HomePetPeekShiftState();
}

class _HomePetPeekShiftState extends State<HomePetPeekShift>
    with TickerProviderStateMixin {
  late final AnimationController _trip = AnimationController(
    vsync: this,
    duration: HomePetPeekShift.tripDuration,
    value: widget.hidden ? 1 : 0,
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(HomePetPeekShift oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hidden != oldWidget.hidden) {
      widget.hidden ? _trip.forward() : _trip.reverse();
    }
    if (widget.cheerTick != oldWidget.cheerTick && widget.hidden) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _trip.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_trip, _hop]),
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_trip.value);
        final walking = _trip.isAnimating;
        final towardDx = widget.hidden ? widget.shift.dx : -widget.shift.dx;
        final hop = math.sin(math.pi * _hop.value) * HomePetPeekShift.hopHeight;
        return Transform.translate(
          offset: widget.shift * t - Offset(0, hop),
          child: widget.builder(
            walking,
            walking && towardDx.abs() > 1 ? towardDx > 0 : null,
          ),
        );
      },
    );
  }
}
