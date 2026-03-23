import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../services/audio/app_sfx.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/pet_name_text_style.dart';
import 'home_responsive.dart';

class HomeGameStatusBar extends StatelessWidget {
  const HomeGameStatusBar({
    super.key,
    required this.petAvatar,
    required this.expProgress,
    required this.level,
    required this.petName,
    required this.healthValue,
    this.healthDebugValue,
    required this.coins,
    required this.diamonds,
    required this.onPetTap,
    required this.onStoreTap,
    this.coinReward,
    this.coinRewardEventId = 0,
    this.showRewardPending = false,
    this.rewardPendingLabel,
    this.onPetNameTap,
    this.onInviteTap,
    this.inviteLabel,
    this.inviteLoading = false,
    this.onInventoryTap,
    this.inventoryLabel,
    this.showInventoryGuidance = false,
    this.inventoryGuidanceTitle,
    this.onInventoryGuidanceDismiss,
  });

  final Widget petAvatar;
  final double expProgress;
  final int? level;
  final String petName;
  final double healthValue;
  final int? healthDebugValue;
  final int coins;
  final int diamonds;
  final VoidCallback onPetTap;
  final VoidCallback onStoreTap;
  final VoidCallback? onPetNameTap;
  final VoidCallback? onInviteTap;
  final String? inviteLabel;
  final bool inviteLoading;
  final VoidCallback? onInventoryTap;
  final String? inventoryLabel;
  final bool showInventoryGuidance;
  final String? inventoryGuidanceTitle;
  final VoidCallback? onInventoryGuidanceDismiss;

  /// When set, triggers the coin reward animation showing "+X" and bounce.
  /// Treated as a one-shot trigger; it can be cleared on the next frame.
  final int? coinReward;

  /// Monotonic event id that guarantees re-triggering even when reward amount
  /// repeats (e.g., +10 multiple times).
  final int coinRewardEventId;
  final bool showRewardPending;
  final String? rewardPendingLabel;

  @override
  Widget build(BuildContext context) {
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scale, 8 * scale, 16 * scale, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _LeftCluster(
              petAvatar: petAvatar,
              expProgress: expProgress,
              level: level,
              petName: petName,
              onPetTap: onPetTap,
              onPetNameTap: onPetNameTap,
              onInviteTap: onInviteTap,
              inviteLabel: inviteLabel,
              inviteLoading: inviteLoading,
              onInventoryTap: onInventoryTap,
              inventoryLabel: inventoryLabel,
              showInventoryGuidance: showInventoryGuidance,
              inventoryGuidanceTitle: inventoryGuidanceTitle,
              onInventoryGuidanceDismiss: onInventoryGuidanceDismiss,
            ),
          ),
          Gap(8 * scale),
          _RightCluster(
            healthValue: healthValue,
            healthDebugValue: healthDebugValue,
            coins: coins,
            diamonds: diamonds,
            coinReward: coinReward,
            coinRewardEventId: coinRewardEventId,
            showRewardPending: showRewardPending,
            rewardPendingLabel: rewardPendingLabel,
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
    this.onInviteTap,
    this.inviteLabel,
    required this.inviteLoading,
    this.onInventoryTap,
    this.inventoryLabel,
    required this.showInventoryGuidance,
    this.inventoryGuidanceTitle,
    this.onInventoryGuidanceDismiss,
  });

  final Widget petAvatar;
  final double expProgress;
  final int? level;
  final String petName;
  final VoidCallback onPetTap;
  final VoidCallback? onPetNameTap;
  final VoidCallback? onInviteTap;
  final String? inviteLabel;
  final bool inviteLoading;
  final VoidCallback? onInventoryTap;
  final String? inventoryLabel;
  final bool showInventoryGuidance;
  final String? inventoryGuidanceTitle;
  final VoidCallback? onInventoryGuidanceDismiss;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = homeUiScale(MediaQuery.sizeOf(context).width);
        final maxNameWidth = max(120.0, constraints.maxWidth * 0.72);
        final levelFontSize = 11.0 * scale;
        final nameFontSize = 14.0 * scale;
        final chipGap = 6.0 * scale;

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onPetTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ExpRingAvatar(progress: expProgress, child: petAvatar),
                    ],
                  ),
                ),
                const Gap(0),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 4 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    level == null ? 'Lv --' : 'Lv $level',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.secondaryColor,
                      height: 1,
                    ).copyWith(fontSize: levelFontSize),
                  ),
                ),
              ],
            ),
            Gap(10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onPetNameTap,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxNameWidth),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * scale,
                          vertical: 8 * scale,
                        ),
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
                        child: Text(
                          petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: petNameTextStyle(
                            fontSize: nameFontSize,
                            color: Colors.black,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if ((inviteLabel != null && onInviteTap != null) ||
                      (inventoryLabel != null && onInventoryTap != null)) ...[
                    Gap(chipGap),
                    Wrap(
                      spacing: 8 * scale,
                      runSpacing: 6 * scale,
                      children: [
                        if (inviteLabel != null && onInviteTap != null)
                          _ActionChip(
                            label: inviteLabel!,
                            onTap: onInviteTap!,
                            loading: inviteLoading,
                            icon: Icons.mail_outline_rounded,
                            minWidth: 60,
                          ),
                        if (inventoryLabel != null && onInventoryTap != null)
                          _InventoryActionChip(
                            label: inventoryLabel!,
                            onTap: onInventoryTap!,
                            showGuidance: showInventoryGuidance,
                            guidanceTitle: inventoryGuidanceTitle,
                            onGuidanceDismiss: onInventoryGuidanceDismiss,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InventoryActionChip extends StatelessWidget {
  const _InventoryActionChip({
    required this.label,
    required this.onTap,
    required this.showGuidance,
    this.guidanceTitle,
    this.onGuidanceDismiss,
  });

  final String label;
  final VoidCallback onTap;
  final bool showGuidance;
  final String? guidanceTitle;
  final VoidCallback? onGuidanceDismiss;

  @override
  Widget build(BuildContext context) {
    return _InventoryGuidanceHighlight(
      enabled: showGuidance,
      onDismiss: onGuidanceDismiss,
      child: _ActionChip(
        label: label,
        onTap: onTap,
        icon: Icons.inventory_2_outlined,
        iconOnly: true,
        minWidth: 36,
      ),
    );
  }
}

class _InventoryGuidanceHighlight extends StatefulWidget {
  const _InventoryGuidanceHighlight({
    required this.enabled,
    required this.child,
    this.onDismiss,
  });

  final bool enabled;
  final Widget child;
  final VoidCallback? onDismiss;

  @override
  State<_InventoryGuidanceHighlight> createState() =>
      _InventoryGuidanceHighlightState();
}

class _InventoryGuidanceHighlightState
    extends State<_InventoryGuidanceHighlight>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  // Controller for global entry/exit fade
  late final AnimationController _visibilityController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _InventoryGuidanceHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.enabled) {
      _controller.repeat();
      _visibilityController.forward();
      // Auto-dismiss after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && widget.enabled) {
          widget.onDismiss?.call();
        }
      });
    } else {
      // Fade out first, then stop the loop
      _visibilityController.reverse().then((_) {
        if (mounted && !widget.enabled) {
          _controller.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _visibilityController]),
      child: widget.child,
      builder: (context, child) {
        final visibility = _visibilityController.value;
        if (visibility <= 0 && !widget.enabled) {
          return child!;
        }

        // Button Pulse Effect (intensity scales with visibility)
        final pulse = 1.0 + (sin(_controller.value * 2 * pi) * 0.08 * visibility);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Magic Trail / Sparkles
            Positioned(
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 250,
                  height: 150,
                  child: CustomPaint(
                    painter: _InventoryMagicTrailPainter(
                      progress: _controller.value,
                      visibility: visibility,
                    ),
                  ),
                ),
              ),
            ),
            // The Button itself with Pulse
            Transform.scale(scale: pulse, child: child!),
            // Ripple/Glow effect around the button
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _InventorySweepPainter(
                    progress: _controller.value,
                    visibility: visibility,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InventoryMagicTrailPainter extends CustomPainter {
  _InventoryMagicTrailPainter({required this.progress, required this.visibility});
  final double progress;
  final double visibility;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    const target = Offset(230, 75);
    const start = Offset(20, 100);

    for (int i = 0; i < 8; i++) {
      final particleDelay = i * 0.12;
      double t = (progress - particleDelay) % 1.0;
      if (t < 0) continue;

      final cp1 = Offset(start.dx + 60, start.dy - 120);
      final cp2 = Offset(target.dx - 40, target.dy - 100);

      final pos = _calculateBezier(t, start, cp1, cp2, target);
      final opacity = (1.0 - t).clamp(0.0, 1.0) * visibility;
      final sizeMult = (1.0 - t * 0.4);

      // Core Golden Glow
      paint.color = const Color(0xFFFFD86C).withValues(alpha: opacity * 0.9);
      canvas.drawCircle(pos, 4.5 * sizeMult, paint);

      // Bright White Center
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(pos, 2.0 * sizeMult, paint);

      if (t > 0.2 && t < 0.8) {
        final rand = Random((i + t * 10).toInt());
        paint.color = Colors.white.withValues(alpha: opacity * 0.5);
        canvas.drawCircle(
          pos + Offset(rand.nextDouble() * 10 - 5, rand.nextDouble() * 10 - 5),
          1.0,
          paint,
        );
      }
    }
  }

  Offset _calculateBezier(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
    final u = 1 - t;
    return p0 * (u * u * u) +
        p1 * (3 * u * u * t) +
        p2 * (3 * u * t * t) +
        p3 * (t * t * t);
  }

  @override
  bool shouldRepaint(covariant _InventoryMagicTrailPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.visibility != visibility;
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.loading = false,
    required this.icon,
    this.iconOnly = false,
    this.minWidth,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final IconData icon;
  final bool iconOnly;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black87, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: minWidth == null ? null : minWidth! * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (iconOnly ? 9 : 10) * scale,
                  vertical: 6 * scale,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (loading)
                        const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(icon, size: 14 * scale),
                      if (!iconOnly) ...[
                        Gap(6 * scale),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 90 * scale),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ).copyWith(fontSize: 10.5 * scale),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventorySweepPainter extends CustomPainter {
  const _InventorySweepPainter({required this.progress, required this.visibility});

  final double progress;
  final double visibility;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.8),
      const Radius.circular(999),
    );
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFF6C557).withValues(alpha: 0.34);
    canvas.drawRRect(rrect, basePaint);

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..shader = SweepGradient(
        transform: GradientRotation(progress * 2 * pi),
        colors: [
          Colors.transparent,
          const Color(0xFFFFD86C).withValues(alpha: 0.15),
          const Color(0xFFFFD86C),
          Colors.white,
          const Color(0xFFFFD86C),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.0, 0.08, 0.14, 0.18, 0.22, 0.32, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    canvas.drawRRect(rrect, sweepPaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFFFFD86C).withValues(alpha: 0.09);
    canvas.drawRRect(rrect.inflate(1.8), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _InventorySweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ExpRingAvatar extends StatelessWidget {
  const _ExpRingAvatar({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);

    // Outer size includes the progress ring
    final double outerSize = 58 * scale;
    final double ringStrokeWidth = 4 * scale;
    final double innerSize = outerSize - ringStrokeWidth * 2;

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom progress ring - starts from 12 o'clock, goes clockwise
          CustomPaint(
            size: Size(outerSize, outerSize),
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
    this.healthDebugValue,
    required this.coins,
    required this.diamonds,
    this.coinReward,
    this.coinRewardEventId = 0,
    this.showRewardPending = false,
    this.rewardPendingLabel,
    required this.onStoreTap,
  });

  final double healthValue;
  final int? healthDebugValue;
  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
  final bool showRewardPending;
  final String? rewardPendingLabel;
  final VoidCallback onStoreTap;

  @override
  Widget build(BuildContext context) {
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final rowLeftInset = 10 * scale;
    final rowTopInset = 14 * scale;
    final rowGap = 10 * scale;
    final statusWidth = 176 * scale;
    final heartSize = 34 * scale;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: rowLeftInset, top: rowTopInset),
              child: SizedBox(
                width: statusWidth,
                child: _HealthBar(
                  value: healthValue,
                  debugValue: healthDebugValue,
                ),
              ),
            ),
            SizedBox(height: rowGap),
            Padding(
              padding: EdgeInsets.only(left: rowLeftInset),
              child: SizedBox(
                width: statusWidth,
                child: _CombinedCurrencyPill(
                  coins: coins,
                  diamonds: diamonds,
                  coinReward: coinReward,
                  coinRewardEventId: coinRewardEventId,
                  showRewardPending: showRewardPending,
                  rewardPendingLabel: rewardPendingLabel,
                  onStoreTap: onStoreTap,
                  expandToWidth: true,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 4 * scale,
          left: -2 * scale,
          child: Icon(
            Icons.favorite_rounded,
            color: const Color(0xFFEE6D85),
            size: heartSize,
          ),
        ),
      ],
    );
  }
}

class _HealthBar extends StatefulWidget {
  const _HealthBar({required this.value, this.debugValue});

  final double value;
  final int? debugValue;

  @override
  State<_HealthBar> createState() => _HealthBarState();
}

class _HealthBarState extends State<_HealthBar> {
  static const _riseThreshold = 0.002;
  static const _riseTint = Color(0xFFEE6D85);
  static const _restTint = Color(0xFFed8787);

  double _lastValue = 0.0;
  bool _isRising = false;
  Timer? _riseTimer;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value.isFinite ? widget.value : 0.0;
  }

  @override
  void didUpdateWidget(_HealthBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value.isFinite ? widget.value : 0.0;
    if (nextValue > _lastValue + _riseThreshold) {
      _riseTimer?.cancel();
      setState(() {
        _isRising = true;
      });
      _riseTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isRising = false;
        });
      });
    } else if (nextValue < _lastValue - _riseThreshold) {
      _isRising = false;
    }
    _lastValue = nextValue;
  }

  @override
  void dispose() {
    _riseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeValue = widget.value.isFinite ? widget.value : 0.0;
    final clamped = safeValue.clamp(0.0, 1.0);
    final fillColor = _isRising ? _riseTint : _restTint;
    final debugText =
        widget.debugValue?.toString() ?? (clamped * 100).round().toString();
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackWidth = MediaQuery.of(context).size.width * 0.28;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackWidth;
        final innerWidth = (width - 4).clamp(0.0, double.infinity);
        final fillWidth = (innerWidth * clamped).clamp(0.0, innerWidth);
        return SizedBox(
          width: width,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black87, width: 2),
                ),
              ),
              Positioned(
                left: 2,
                top: 2,
                bottom: 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOut,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                debugText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardPendingPill extends StatelessWidget {
  const _RewardPendingPill({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 148 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black87, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10 * scale,
              height: 10 * scale,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            Gap(6 * scale),
            Flexible(
              child: Text(
                label ?? 'Reward pending',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
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
    this.showRewardPending = false,
    this.rewardPendingLabel,
    this.expandToWidth = false,
  });

  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
  final bool showRewardPending;
  final String? rewardPendingLabel;
  final VoidCallback onStoreTap;
  final bool expandToWidth;

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
    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: Curves.easeOutCubic,
          ),
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
    _floatOffset =
        Tween<Offset>(
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
    unawaited(AppSfx.playCandyGain());
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
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final addButtonSize = 16 * scale;
    final iconSize = 16 * scale;
    final dividerHeight = 12 * scale;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        if (widget.showRewardPending)
          Positioned(
            right: 0,
            bottom: -22 * scale,
            child: _RewardPendingPill(label: widget.rewardPendingLabel),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onStoreTap,
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: widget.expandToWidth ? double.infinity : null,
              child: Row(
                mainAxisSize: widget.expandToWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 5 * scale,
                      ),
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
                        children: [
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/shop/icon/diamond.png',
                                    width: iconSize,
                                    height: iconSize,
                                  ),
                                  Gap(4 * scale),
                                  Text(
                                    '${widget.diamonds}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13 * scale,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: dividerHeight,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _bounceAnimation,
                                builder: (context, child) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.scale(
                                            scale: _bounceAnimation.value,
                                            child: Image.asset(
                                              'assets/shop/icon/candy.png',
                                              width: iconSize,
                                              height: iconSize,
                                            ),
                                          ),
                                          Gap(4 * scale),
                                          Text(
                                            '${widget.coins}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13 * scale,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_displayReward != null)
                                        Positioned(
                                          right: -10 * scale,
                                          top: -20 * scale,
                                          child: SlideTransition(
                                            position: _floatOffset,
                                            child: FadeTransition(
                                              opacity: _floatOpacity,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8 * scale,
                                                  vertical: 4 * scale,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppTheme.secondaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppTheme
                                                          .secondaryColor
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  '+$_displayReward',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14 * scale,
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
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: dividerHeight,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                width: addButtonSize,
                                height: addButtonSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEE6D85),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black87,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 10 * scale,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
