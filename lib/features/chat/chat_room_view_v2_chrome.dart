part of 'chat_room_view_v2.dart';

class ReplySwipeWrapper extends StatefulWidget {
  const ReplySwipeWrapper({
    super.key,
    required this.child,
    required this.onTriggered,
  });

  final Widget child;
  final VoidCallback onTriggered;

  @override
  State<ReplySwipeWrapper> createState() => _ReplySwipeWrapperState();
}

class _ReplySwipeWrapperState extends State<ReplySwipeWrapper>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 32;

  late final AnimationController _controller;
  Animation<double>? _animation;
  double _dragOffset = 0;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _animation?.removeListener(_handleAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationTick() {
    final animation = _animation;
    if (!mounted || animation == null) {
      return;
    }
    setState(() => _dragOffset = animation.value);
  }

  void _animateBack() {
    if (_dragOffset <= 0) {
      return;
    }
    _animation?.removeListener(_handleAnimationTick);
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(_handleAnimationTick);
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / _triggerDistance).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx >= 0 || _triggered) {
          return;
        }
        _controller.stop();
        setState(() {
          _dragOffset = (_dragOffset + (-details.delta.dx)).clamp(0.0, 84.0);
        });
        if (_dragOffset >= _triggerDistance) {
          _triggered = true;
          widget.onTriggered();
          _animateBack();
        }
      },
      onHorizontalDragEnd: (_) {
        if (!_triggered) {
          _animateBack();
        }
        _triggered = false;
      },
      onHorizontalDragCancel: _animateBack,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 8,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.9 + (progress * 0.1),
                child: Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: AppTheme.primaryColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.petName,
    required this.memberCount,
    required this.uiScale,
    required this.useLightForeground,
    required this.onBack,
    required this.onMembersTap,
    required this.menuButton,
  });

  final String petName;
  final String? memberCount;
  final double uiScale;
  final bool useLightForeground;
  final VoidCallback onBack;
  final VoidCallback onMembersTap;
  final Widget menuButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12 * uiScale,
          8 * uiScale,
          12 * uiScale,
          8 * uiScale,
        ),
        child: Row(
          children: [
            _GlassPill(
              useDarkSurface: useLightForeground,
              padding: EdgeInsets.all(4 * uiScale),
              child: IconButton(
                iconSize: (20 * uiScale).clamp(18.0, 20.0),
                constraints: BoxConstraints.tightFor(
                  width: (36.0 * uiScale).clamp(32.0, 36.0),
                  height: (36.0 * uiScale).clamp(32.0, 36.0),
                ),
                padding: EdgeInsets.all((8.0 * uiScale).clamp(6.0, 8.0)),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: useLightForeground ? Colors.white : AppTheme.textPrimary,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
            SizedBox(width: 10 * uiScale),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 220 * uiScale),
                  child: GestureDetector(
                    onTap: onMembersTap,
                    child: _GlassPill(
                      useDarkSurface: useLightForeground,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * uiScale,
                        vertical: 8 * uiScale,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: (15 * uiScale).clamp(13.0, 15.0),
                              fontWeight: FontWeight.w600,
                              color: useLightForeground
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          if (memberCount != null)
                            Text(
                              memberCount!,
                              style: TextStyle(
                                fontSize: (11 * uiScale).clamp(10.0, 11.0),
                                color: useLightForeground
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Colors.black.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * uiScale),
            _GlassPill(
              useDarkSurface: useLightForeground,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: menuButton,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMenuAvatar extends StatelessWidget {
  const _ChatMenuAvatar({required this.petAssetPath, required this.uiScale});

  final String? petAssetPath;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final avatarSize = (48.0 * uiScale).clamp(40.0, 48.0);
    final petIconSize = (24.0 * uiScale).clamp(20.0, 24.0);
    final petAssetSize = (40.0 * uiScale).clamp(32.0, 40.0);
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Center(
        child: CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: petAssetPath == null
              ? Icon(Icons.pets, size: petIconSize, color: AppTheme.textPrimary)
              : PetAnimatedImage(
                  sourceAsset: petAssetPath!,
                  width: petAssetSize,
                  height: petAssetSize,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.padding,
    this.useDarkSurface = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool useDarkSurface;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: useDarkSurface
              ? Colors.black.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: useDarkSurface
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: useDarkSurface ? 0.10 : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
