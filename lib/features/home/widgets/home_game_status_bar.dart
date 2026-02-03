import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';

const Color _diamondColor = Color(0xFF4C7DFF);

class HomeGameStatusBar extends StatelessWidget {
  const HomeGameStatusBar({
    super.key,
    required this.petAvatar,
    required this.expProgress,
    required this.level,
    required this.petName,
    required this.healthValue,
    required this.coins,
    required this.diamonds,
    required this.onPetTap,
    required this.onStoreTap,
    this.coinReward,
    this.coinRewardEventId = 0,
    this.onPetNameTap,
  });

  final Widget petAvatar;
  final double expProgress;
  final int level;
  final String petName;
  final double healthValue;
  final int coins;
  final int diamonds;
  final VoidCallback onPetTap;
  final VoidCallback onStoreTap;
  final VoidCallback? onPetNameTap;

  /// When set, triggers the coin reward animation showing "+X" and bounce.
  /// Treated as a one-shot trigger; it can be cleared on the next frame.
  final int? coinReward;

  /// Monotonic event id that guarantees re-triggering even when reward amount
  /// repeats (e.g., +10 multiple times).
  final int coinRewardEventId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeftCluster(
            petAvatar: petAvatar,
            expProgress: expProgress,
            level: level,
            petName: petName,
            onPetTap: onPetTap,
            onPetNameTap: onPetNameTap,
          ),
          _RightCluster(
            healthValue: healthValue,
            coins: coins,
            diamonds: diamonds,
            coinReward: coinReward,
            coinRewardEventId: coinRewardEventId,
            onStoreTap: onStoreTap,
          ),
        ],
      ),
    );
  }
}

class _LeftCluster extends StatelessWidget {
  const _LeftCluster({
    required this.petAvatar,
    required this.expProgress,
    required this.level,
    required this.petName,
    required this.onPetTap,
    this.onPetNameTap,
  });

  final Widget petAvatar;
  final double expProgress;
  final int level;
  final String petName;
  final VoidCallback onPetTap;
  final VoidCallback? onPetNameTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPetTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [_ExpRingAvatar(progress: expProgress, child: petAvatar)],
          ),
        ),
        const Gap(10),
        GestureDetector(
          onTap: onPetNameTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black87, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lv $level',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppTheme.secondaryColor,
                    height: 1,
                  ),
                ),
                const Gap(8),
                Text(
                  petName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpRingAvatar extends StatelessWidget {
  const _ExpRingAvatar({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    // Outer size includes the progress ring
    const double outerSize = 58;
    const double ringStrokeWidth = 4;
    const double innerSize = outerSize - ringStrokeWidth * 2;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom progress ring - starts from 12 o'clock, goes clockwise
          CustomPaint(
            size: const Size(outerSize, outerSize),
            painter: _CircularProgressPainter(
              progress: clamped,
              strokeWidth: ringStrokeWidth,
              backgroundColor: Colors.black.withValues(alpha: 0.12),
              progressColor: AppTheme.secondaryColor,
            ),
          ),
          // Inner container with pet avatar
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc - starts from top (12 o'clock = -pi/2) and goes clockwise
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2; // 12 o'clock position
    final sweepAngle = 2 * pi * progress; // Clockwise sweep

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _RightCluster extends StatelessWidget {
  const _RightCluster({
    required this.healthValue,
    required this.coins,
    required this.diamonds,
    this.coinReward,
    this.coinRewardEventId = 0,
    required this.onStoreTap,
  });

  final double healthValue;
  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
  final VoidCallback onStoreTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _HealthBar(value: healthValue),
            ),
            const SizedBox(height: 8),
            _CombinedCurrencyPill(
              coins: coins,
              diamonds: diamonds,
              coinReward: coinReward,
              coinRewardEventId: coinRewardEventId,
              onStoreTap: onStoreTap,
            ),
          ],
        ),
        const Positioned(
          top: -11,
          left: -5,
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFEE6D85),
            size: 40,
          ),
        ),
      ],
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.isFinite ? value : 0.0;
    final clamped = safeValue.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = MediaQuery.of(context).size.width * 0.35;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackWidth;
        return SizedBox(
          width: width,
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: clamped,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEE6D85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CombinedCurrencyPill extends StatefulWidget {
  const _CombinedCurrencyPill({
    required this.coins,
    required this.diamonds,
    required this.coinRewardEventId,
    required this.onStoreTap,
    this.coinReward,
  });

  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
  final VoidCallback onStoreTap;

  @override
  State<_CombinedCurrencyPill> createState() => _CombinedCurrencyPillState();
}

class _CombinedCurrencyPillState extends State<_CombinedCurrencyPill>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _floatOpacity;
  late Animation<Offset> _floatOffset;

  int? _displayReward;
  late final AnimationStatusListener _floatStatusListener;

  @override
  void initState() {
    super.initState();

    // Bounce animation (scale 1.0 -> 1.25 -> 1.0)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );

    // Float animation (move up + fade out)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_floatController);
    _floatOffset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeOutCubic),
    );

    _floatStatusListener = (status) {
      if (status != AnimationStatus.completed) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _displayReward = null;
      });
    };
    _floatController.addStatusListener(_floatStatusListener);
  }

  @override
  void didUpdateWidget(_CombinedCurrencyPill oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation only on reward event id changes.
    if (widget.coinRewardEventId == oldWidget.coinRewardEventId) {
      return;
    }
    final reward = widget.coinReward;
    if (reward == null || reward <= 0) {
      return;
    }

    setState(() {
      _displayReward = reward;
    });
    _triggerAnimation();
  }

  void _triggerAnimation() {
    _bounceController.forward(from: 0);
    _floatController.forward(from: 0);
  }

  @override
  void dispose() {
    _floatController.removeStatusListener(_floatStatusListener);
    _bounceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 20, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.black87, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Diamonds Part
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.diamond_rounded,
                    size: 18,
                    color: _diamondColor,
                  ),
                  const Gap(6),
                  Text(
                    '${widget.diamonds}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Container(
                width: 1,
                height: 14,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              const Gap(12),
              // Coins Part
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _bounceAnimation.value,
                        child: SvgPicture.asset(
                          'assets/icon/icon-park--candy.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            AppTheme.secondaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '${widget.coins}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Gap(8),
              Transform.translate(
                offset: const Offset(10, 0),
                child: GestureDetector(
                  onTap: widget.onStoreTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEE6D85),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating "+X" text
        if (_displayReward != null)
          Positioned(
            right: 0,
            top: -20,
            child: SlideTransition(
              position: _floatOffset,
              child: FadeTransition(
                opacity: _floatOpacity,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '+$_displayReward',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
