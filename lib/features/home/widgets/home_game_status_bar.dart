import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';

class HomeGameStatusBar extends StatelessWidget {
  const HomeGameStatusBar({
    super.key,
    required this.petAvatar,
    required this.expProgress,
    required this.level,
    required this.petName,
    required this.healthValue,
    required this.coins,
    required this.onPetTap,
  });

  final Widget petAvatar;
  final double expProgress;
  final int level;
  final String petName;
  final double healthValue;
  final int coins;
  final VoidCallback onPetTap;

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
          ),
          _RightCluster(healthValue: healthValue, coins: coins),
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
  });

  final Widget petAvatar;
  final double expProgress;
  final int level;
  final String petName;
  final VoidCallback onPetTap;

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
        Container(
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
  const _RightCluster({required this.healthValue, required this.coins});

  final double healthValue;
  final int coins;

  @override
  Widget build(BuildContext context) {
    const barWidth = 150.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFEE6D85)),
            const Gap(8),
            SizedBox(
              width: barWidth,
              child: _HealthBar(value: healthValue),
            ),
          ],
        ),
        const Gap(10),
        SizedBox(
          width: barWidth,
          child: _CoinsPill(coins: coins),
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
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      width: 150,
      height: 14,
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
    );
  }
}

class _CoinsPill extends StatelessWidget {
  const _CoinsPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cake_rounded,
                size: 18,
                color: AppTheme.secondaryColor,
              ),
              const Gap(8),
              Text(
                '$coins',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1,
                ),
              ),
            ],
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFEE6D85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: const Icon(Icons.add, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
