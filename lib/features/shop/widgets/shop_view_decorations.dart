part of '../shop_view.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: _ShopStrokeText(
        title,
        fontSize: 16,
        color: Colors.white,
        strokeColor: Colors.black.withValues(alpha: 0.7),
        strokeWidth: 4.5,
      ),
    );
  }
}

class _ShopStrokeText extends StatelessWidget {
  const _ShopStrokeText(
    this.text, {
    required this.fontSize,
    required this.color,
    this.strokeColor = Colors.white,
    this.strokeWidth = 4.5,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: GoogleFonts.mPlusRounded1c(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: GoogleFonts.mPlusRounded1c(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ShopAdaptiveStrokeTitle extends StatelessWidget {
  const _ShopAdaptiveStrokeTitle({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.strokeColor,
    this.strokeWidth = 4.5,
    this.height = 32,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: _ShopStrokeText(
            text,
            fontSize: fontSize,
            color: color,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class ShopFeaturedBanner extends StatefulWidget {
  const ShopFeaturedBanner({
    super.key,
    required this.items,
    required this.onPurchase,
    required this.findPackage,
    required this.findStoreProduct,
    required this.isProUser,
    required this.activeEntitlements,
    required this.iapConfigured,
    required this.isPurchasing,
    required this.scrollController,
  });

  final List<ShopItem> items;
  final void Function(ShopItem) onPurchase;
  final Package? Function(String) findPackage;
  final StoreProduct? Function(String) findStoreProduct;
  final bool isProUser;
  final Set<String> activeEntitlements;
  final bool iapConfigured;
  final bool isPurchasing;
  final ScrollController scrollController;

  @override
  State<ShopFeaturedBanner> createState() => _ShopFeaturedBannerState();
}

class _ShopFeaturedBannerState extends State<ShopFeaturedBanner>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _floatController;
  int _currentPage = 0;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    ); // Controller kept but not repeating for static display

    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = widget.scrollController.offset;
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final productId = item.iapProductId;
              final package = productId != null
                  ? widget.findPackage(productId)
                  : null;
              final storeProduct = productId != null
                  ? widget.findStoreProduct(productId)
                  : null;
              final priceString = item.localizedIapPrice(
                package,
                storeProduct,
                l10n,
              );
              final entitlementId = item.rcEntitlementId;
              final isSubscribed =
                  item.iapType == 'subscription' &&
                  (widget.isProUser ||
                      (entitlementId != null &&
                          widget.activeEntitlements.contains(entitlementId)));
              final canBuy =
                  widget.iapConfigured &&
                  !widget.isPurchasing &&
                  !isSubscribed &&
                  (package != null || storeProduct != null);
              final actionLabel = isSubscribed
                  ? l10n.commonOwned
                  : l10n.storeSubscribe;

              // Parallax logic
              final parallaxOffset = _scrollOffset * 0.15;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFA5F2FF), // Light Dream Blue
                          Color(0xFFD1C4E9), // Light Lavender
                          Color(0xFFF3E5F5), // Soft Purple
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF303F9F).withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          // Soft bubbles background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _StarryBackgroundPainter(
                                scrollOffset: _scrollOffset * 0.08,
                              ),
                            ),
                          ),

                          // Cat Illustration (Moved back inside, balanced position)
                          Positioned(
                            left: -10,
                            bottom: -10 - parallaxOffset,
                            top: 10 - parallaxOffset,
                            width: 160,
                            child: Image.asset(
                              'assets/shop/shop_cat.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Main Content Area
                          Positioned(
                            right: 16,
                            top: 6, // Reduced top padding
                            bottom: 8,
                            left: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD180),
                                          Color(0xFFFB8C00),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                  child: _ShopAdaptiveStrokeTitle(
                                    text: item.localizedName(l10n),
                                    fontSize: 26,
                                    color: Colors.white,
                                    strokeColor: Colors.black, // Black outline
                                    strokeWidth: 4, // Thick black stroke
                                  ),
                                ),
                                const SizedBox(height: 8), // Reduced spacing
                                // Visual Benefits List
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _BenefitItem(
                                        icon: Icons.meeting_room_rounded,
                                        text: l10n
                                            .storePremiumBenefitUnlimitedRooms,
                                      ),
                                      _BenefitItem(
                                        icon: Icons.block_rounded,
                                        text: l10n.storePremiumBenefitNoAds,
                                      ),
                                      _BenefitItem(
                                        icon: Icons.star_rounded,
                                        text: l10n
                                            .storePremiumBenefitExclusiveItems,
                                      ),
                                    ],
                                  ),
                                ),

                                // CTA Area
                                Opacity(
                                  opacity: canBuy || isSubscribed ? 1 : 0.65,
                                  child: _ShopRaisedButtonShell(
                                    onPressed: canBuy
                                        ? () => widget.onPurchase(item)
                                        : null,
                                    depth: !isSubscribed && canBuy ? 4 : 0,
                                    borderRadius: BorderRadius.circular(20),
                                    shadowColor: const Color(0xFFE65100),
                                    faceBuilder: (context, isPressed) =>
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: isSubscribed || !canBuy
                                                ? null
                                                : const LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Color(0xFFFFD180),
                                                      Color(0xFFFB8C00),
                                                    ],
                                                  ),
                                            color: isSubscribed || !canBuy
                                                ? Colors.white.withValues(
                                                    alpha: 0.95,
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Center(
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                if (!isSubscribed) ...[
                                                  _ShopStrokeText(
                                                    priceString,
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    strokeColor: const Color(
                                                      0xFFD54900,
                                                    ),
                                                    strokeWidth: 3,
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                _ShopStrokeText(
                                                  actionLabel,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  strokeColor: const Color(
                                                    0xFFD54900,
                                                  ),
                                                  strokeWidth: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Center(
                                  child: Text(
                                    '${l10n.storeSubscriptionDurationMonthly} • ${l10n.storeSubscriptionRenewalNote}',
                                    style: GoogleFonts.mPlusRounded1c(
                                      color: const Color(
                                        0xFF303F9F,
                                      ).withValues(alpha: 0.7),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Active Badge (Design Choice 1: 3D Sticker style)
                  if (isSubscribed)
                    Positioned(
                      top: 4, // Overlap the top margin
                      right: 12,
                      child: Transform.rotate(
                        angle: 0.08, // Subtle tilt for sticker feel
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.storeSubscriptionActive.toUpperCase(),
                                style: GoogleFonts.mPlusRounded1c(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (widget.items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? const Color(0xFF90CAF9)
                      : Colors.black12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6), // Reduced bottom padding
      child: Row(
        children: [
          // Icon with white circular background for maximum clarity
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: const Color(0xFF303F9F), // Deep Indigo icon
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.mPlusRounded1c(
                color: const Color(0xFF303F9F).withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarryBackgroundPainter extends CustomPainter {
  _StarryBackgroundPainter({required this.scrollOffset});
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Draw soft bubbles/circles
    for (var i = 0; i < 15; i++) {
      final bubblePaint = Paint()
        ..color = Colors.white.withValues(
          alpha: random.nextDouble() * 0.15 + 0.05,
        );

      final radius = 10.0 + random.nextDouble() * 30.0;
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height + scrollOffset * 0.5) %
          size.height;

      canvas.drawCircle(Offset(x, y), radius, bubblePaint);
    }

    // Add some tiny sparkles
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (var i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height + scrollOffset) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_StarryBackgroundPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

class _ShopBackgroundStars extends StatelessWidget {
  const _ShopBackgroundStars();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Background Glows (Multi-directional colors)
          Positioned(
            top: -100,
            left: -100,
            child: _Glow(
              color: const Color(
                0xFFB3E5FC,
              ).withValues(alpha: 0.5), // Light Blue
              size: 400,
            ),
          ),
          Positioned(
            top: -50,
            right: -100,
            child: _Glow(
              color: const Color(
                0xFFE1BEE7,
              ).withValues(alpha: 0.5), // Light Purple
              size: 350,
            ),
          ),
          Positioned(
            top: 300,
            left: -50,
            child: _Glow(
              color: const Color(0xFFFFF9C4).withValues(alpha: 0.4), // Yellow
              size: 300,
            ),
          ),
          Positioned(
            bottom: 200,
            right: -100,
            child: _Glow(
              color: const Color(
                0xFFFFCDD2,
              ).withValues(alpha: 0.4), // Soft Red/Pink
              size: 450,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _Glow(
              color: const Color(0xFFFFF3E0).withValues(alpha: 0.5), // Peach
              size: 400,
            ),
          ),

          // Large Stars
          _Star(top: 80, left: 20, size: 32, opacity: 0.2),
          _Star(top: 220, right: 30, size: 40, opacity: 0.15),
          _Star(bottom: 150, left: 40, size: 28, opacity: 0.2),
          _Star(top: 400, right: 100, size: 36, opacity: 0.1),

          // Small Stars
          _Star(top: 150, left: 80, size: 14, opacity: 0.2),
          _Star(bottom: 250, right: 50, size: 16, opacity: 0.2),

          // Colorful Dots
          _Dot(
            top: 120,
            right: 80,
            size: 12,
            color: const Color(0xFFFFCDD2),
          ), // Pink
          _Dot(
            top: 300,
            left: 100,
            size: 10,
            color: const Color(0xFFE1BEE7),
          ), // Purple
          _Dot(
            bottom: 200,
            left: 150,
            size: 14,
            color: const Color(0xFFB3E5FC),
          ), // Blue
          _Dot(
            top: 500,
            right: 40,
            size: 8,
            color: const Color(0xFFF9FBE7),
          ), // Yellow
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Opacity(
        opacity: opacity,
        child: Icon(Icons.star_rounded, size: size, color: Colors.white),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ShopNoticeBackgroundVisual extends StatelessWidget {
  const _ShopNoticeBackgroundVisual({required this.backgroundKey});

  final String? backgroundKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: RoomBackgrounds.resolve(backgroundKey).previewDecoration,
      child: const SizedBox.expand(),
    );
  }
}

class _ShopCategoryRow extends StatelessWidget {
  const _ShopCategoryRow({
    this.onEquipmentTap,
    this.onFurnitureTap,
    this.onThemeTap,
  });

  final VoidCallback? onEquipmentTap;
  final VoidCallback? onFurnitureTap;
  final VoidCallback? onThemeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CategoryItem(
            icon: const Text('👒', style: TextStyle(fontSize: 36)),
            label: l10n.shopSectionEquipment,
            color: const Color(0xFFFFE0B2),
            onTap: onEquipmentTap,
          ),
          _CategoryItem(
            icon: Image.asset(
              'assets/shop/icon/sofa.png',
              width: 50,
              height: 50,
            ),
            label: l10n.storeTabFurniture,
            color: const Color(0xFFFFCDD2),
            onTap: onFurnitureTap,
          ),
          _CategoryItem(
            icon: Image.asset(
              'assets/shop/icon/house.png',
              width: 50,
              height: 50,
            ),
            label: l10n.storeTabThemes,
            color: const Color(0xFFE1BEE7),
            onTap: onThemeTap,
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(width: 60, height: 55, child: Center(child: icon)),
          const SizedBox(height: 0),
          _ShopStrokeText(
            label,
            fontSize: 16,
            color: Colors.white,
            strokeColor: const Color(0xFF1A237E),
            strokeWidth: 4,
          ),
        ],
      ),
    );
  }
}

class ShopCurrencyChip extends StatefulWidget {
  const ShopCurrencyChip({
    super.key,
    required this.amount,
    required this.icon,
    this.coinReward,
    this.coinRewardEventId = 0,
  });

  final int amount;
  final Widget icon;
  final int? coinReward;
  final int coinRewardEventId;

  @override
  State<ShopCurrencyChip> createState() => _ShopCurrencyChipState();
}

class _ShopCurrencyChipState extends State<ShopCurrencyChip>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _rewardController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _rewardOffset;
  late final Animation<double> _rewardOpacity;
  int? _displayReward;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _rewardController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _displayReward = null;
            });
          }
        });
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.14), weight: 42),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1), weight: 58),
    ]).animate(_bounceController);
    _rewardOffset =
        Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: const Offset(0, -0.85),
        ).animate(
          CurvedAnimation(
            parent: _rewardController,
            curve: Curves.easeOutCubic,
          ),
        );
    _rewardOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
      TweenSequenceItem(tween: ConstantTween(1), weight: 46),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 36),
    ]).animate(_rewardController);
  }

  @override
  void didUpdateWidget(covariant ShopCurrencyChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coinRewardEventId == oldWidget.coinRewardEventId) {
      return;
    }
    final reward = widget.coinReward ?? 0;
    if (reward <= 0) {
      return;
    }
    _displayReward = reward;
    _bounceController.forward(from: 0);
    _rewardController.forward(from: 0);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.icon,
                const SizedBox(width: 6),
                Text(
                  '${widget.amount}',
                  style: GoogleFonts.mPlusRounded1c(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_displayReward != null)
          Positioned(
            top: -18,
            child: SlideTransition(
              position: _rewardOffset,
              child: FadeTransition(
                opacity: _rewardOpacity,
                child: IgnorePointer(
                  child: Text(
                    '+$_displayReward',
                    key: const ValueKey('shop-currency-reward-label'),
                    style: GoogleFonts.mPlusRounded1c(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: const Color(0xFFFF7A3D),
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.95),
                          blurRadius: 4,
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
