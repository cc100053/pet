import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';

import '../../../services/audio/app_sfx.dart';
import '../../../shared/theme/app_theme.dart';
import 'home_responsive.dart';

const Color _diamondColor = Color(0xFF4C7DFF);

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
    this.onPetNameTap,
    this.onInviteTap,
    this.inviteLabel,
    this.inviteLoading = false,
    this.onInventoryTap,
    this.inventoryLabel,
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

  /// When set, triggers the coin reward animation showing "+X" and bounce.
  /// Treated as a one-shot trigger; it can be cleared on the next frame.
  final int? coinReward;

  /// Monotonic event id that guarantees re-triggering even when reward amount
  /// repeats (e.g., +10 multiple times).
  final int coinRewardEventId;

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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1,
                          ).copyWith(fontSize: nameFontSize),
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
                          ),
                        if (inventoryLabel != null && onInventoryTap != null)
                          _ActionChip(
                            label: inventoryLabel!,
                            onTap: onInventoryTap!,
                            icon: Icons.inventory_2_outlined,
                            iconOnly: true,
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.loading = false,
    required this.icon,
    this.iconOnly = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final IconData icon;
  final bool iconOnly;

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
              width: iconOnly ? (30 * scale) : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (iconOnly ? 9 : 10) * scale,
                  vertical: 6 * scale,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
    required this.onStoreTap,
  });

  final double healthValue;
  final int? healthDebugValue;
  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
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

class _CombinedCurrencyPill extends StatefulWidget {
  const _CombinedCurrencyPill({
    required this.coins,
    required this.diamonds,
    required this.coinRewardEventId,
    required this.onStoreTap,
    this.coinReward,
    this.expandToWidth = false,
  });

  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
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
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onStoreTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: widget.expandToWidth ? double.infinity : null,
              padding: EdgeInsets.fromLTRB(
                10,
                5,
                widget.expandToWidth ? 10 : 16,
                5,
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
                mainAxisSize: widget.expandToWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  // Diamonds Part
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.diamond_rounded,
                        size: 16,
                        color: _diamondColor,
                      ),
                      const Gap(4),
                      Text(
                        '${widget.diamonds}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Container(
                    width: 1,
                    height: 12,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  const Gap(8),
                  // Coins Part
                  AnimatedBuilder(
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
                                child: SvgPicture.asset(
                                  'assets/icon/icon-park--candy.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    AppTheme.secondaryColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '${widget.coins}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          if (_displayReward != null)
                            Positioned(
                              right: -10,
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
                                          color: AppTheme.secondaryColor
                                              .withValues(alpha: 0.4),
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
                    },
                  ),
                  if (widget.expandToWidth) const Spacer(),
                  const Gap(6),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE6D85),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 10,
                          color: Colors.white,
                        ),
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
