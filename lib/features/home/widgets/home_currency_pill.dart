import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../services/audio/app_sfx.dart';
import '../../../shared/theme/app_theme.dart';
import 'home_responsive.dart';

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

/// The combined diamond + candy pill used by the Home status bar and by any
/// surface that spends currency (e.g. the 換相框 sheet). Keep this the single
/// drawing of the pill so those surfaces cannot drift apart.
class HomeCurrencyPill extends StatefulWidget {
  const HomeCurrencyPill({
    super.key,
    required this.coins,
    required this.diamonds,
    required this.coinRewardEventId,
    required this.onStoreTap,
    this.coinReward,
    this.showRewardPending = false,
    this.rewardPendingLabel,
    this.coinRewardLabel,
    this.expandToWidth = false,
  });

  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
  final String? coinRewardLabel;
  final bool showRewardPending;
  final String? rewardPendingLabel;
  final VoidCallback onStoreTap;
  final bool expandToWidth;

  @override
  State<HomeCurrencyPill> createState() => _HomeCurrencyPillState();
}

class _HomeCurrencyPillState extends State<HomeCurrencyPill>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _floatOpacity;
  late Animation<Offset> _floatOffset;

  int? _displayReward;
  String? _displayRewardLabel;
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
        _displayRewardLabel = null;
      });
    };
    _floatController.addStatusListener(_floatStatusListener);
  }

  @override
  void didUpdateWidget(HomeCurrencyPill oldWidget) {
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
      _displayRewardLabel = widget.coinRewardLabel;
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
                              // A six-figure balance is wider than the column
                              // it is given on narrow headers. Shrink the pair
                              // to fit rather than overflow it — the icon and
                              // the number must scale together or they stop
                              // reading as one unit.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
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
                                      // Shrinks to fit for the same reason as
                                      // the diamond column above.
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
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
                                                  _displayRewardLabel ??
                                                      '+$_displayReward',
                                                  key: const ValueKey(
                                                    'home-currency-reward-label',
                                                  ),
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
