import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A widget that adds "Juicy" physics to touch interactions (Squish & Pop).
class JuicyScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double lowerBound;
  final double upperBound;

  const JuicyScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 300),
    this.lowerBound = 0.90, // Squeeze effect
    this.upperBound = 1.05, // Overshoot effect
  });

  @override
  State<JuicyScaleButton> createState() => _JuicyScaleButtonState();
}

class _JuicyScaleButtonState extends State<JuicyScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact(); // Tactile feedback is MUST
    _controller.animateTo(0.0, duration: const Duration(milliseconds: 100));
    setState(() {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.lowerBound,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
      );
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    HapticFeedback.mediumImpact(); // Stronger pop on release
    // The "Pop" sequence: Retract -> Overshoot -> Settle
    setState(() {
      _scaleAnimation = TweenSequence<double>([
        // 1. Spring back to overshoot (fast)
        TweenSequenceItem(
          tween: Tween<double>(
            begin: widget.lowerBound,
            end: widget.upperBound,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 40,
        ),
        // 2. Settle to natural size
        TweenSequenceItem(
          tween: Tween<double>(
            begin: widget.upperBound,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60,
        ),
      ]).animate(_controller);
    });
    _controller.forward(from: 0.0).then((_) {
      widget.onTap?.call();
    });
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() {
      _scaleAnimation = Tween<double>(
        begin: _scaleAnimation.value,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// A widget that floats organically (Bobbing + Breathing).
class JuicyFloat extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final double yOffset;

  const JuicyFloat({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.yOffset = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(
          begin: -yOffset,
          end: yOffset,
          curve: Curves.easeInOutSine,
          duration: 3.seconds,
          delay: delay,
        )
        .scaleXY(
          begin: 1.0,
          end: 1.02,
          duration: 4.seconds,
          curve: Curves.easeInOutQuad,
        ); // Subtle breathing
  }
}
