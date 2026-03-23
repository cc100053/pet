part of '../shop_view.dart';

class ShopGridItemCard extends StatelessWidget {
  const ShopGridItemCard({
    super.key,
    required this.item,
    required this.isOwned,
    required this.isIap,
    required this.priceString,
    required this.canAffordCoins,
    required this.canAffordDiamonds,
    required this.canBuyIap,
    required this.hasDepartedPets,
    required this.onOpenThemePreview,
    required this.onBuyIap,
    required this.onBuyCoins,
    required this.onBuyDiamonds,
    required this.onHandleLetter,
  });

  final ShopItem item;
  final bool isOwned;
  final bool isIap;
  final String priceString;
  final bool canAffordCoins;
  final bool canAffordDiamonds;
  final bool canBuyIap;
  final bool hasDepartedPets;
  final VoidCallback onOpenThemePreview;
  final VoidCallback onBuyIap;
  final VoidCallback onBuyCoins;
  final VoidCallback onBuyDiamonds;
  final VoidCallback onHandleLetter;

  VoidCallback? _resolveBuyAction() {
    if (isOwned) {
      return null;
    }
    if (isIap) {
      return canBuyIap ? onBuyIap : null;
    }

    final isLetter = item.isRecoveryLetter;
    if (isLetter && !hasDepartedPets) {
      return null;
    }

    if (item.priceCoins != null) {
      if (isLetter && canAffordCoins) {
        return onHandleLetter;
      }
      return onBuyCoins;
    }

    if (item.priceDiamonds != null) {
      if (isLetter && canAffordDiamonds) {
        return onHandleLetter;
      }
      return onBuyDiamonds;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemEmoji =
        item.emoji ??
        (item.isBackground ? '🖼️' : (item.isRecoveryLetter ? '💌' : '🎁'));

    final int colorIndex = item.id.hashCode.abs() % 3;
    final List<List<Color>> gradientPairs = [
      [const Color(0xFFFFEBF0), const Color(0xFFFFF9C4)],
      [const Color(0xFFE1F5FE), const Color(0xFFE8F5E9)],
      [const Color(0xFFF3E5F5), const Color(0xFFFFE0B2)],
    ];
    final List<Color> bgGradient = gradientPairs[colorIndex];
    final onBuy = _resolveBuyAction();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              width: double.infinity,
              decoration: item.isBackground
                  ? RoomBackgrounds.resolve(
                      item.backgroundKey,
                    ).previewDecoration.copyWith(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    )
                  : BoxDecoration(
                      gradient: LinearGradient(
                        colors: bgGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _ShopAdaptiveStrokeTitle(
                      text: item.localizedName(l10n),
                      fontSize: 20,
                      color: Colors.white,
                      strokeColor: const Color(0xFF1A237E),
                      strokeWidth: 3.5,
                      height: 24,
                      alignment: Alignment.center,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (!item.isBackground)
                          Center(
                            child: item.isDiamondIap
                                ? Image.asset(
                                    'assets/shop/icon/diamond_300.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                  )
                                : Text(
                                    itemEmoji,
                                    style: const TextStyle(fontSize: 56),
                                  ),
                          ),
                        if (item.isBackground)
                          Positioned(
                            top: 0,
                            right: 4,
                            child: _GridPreviewAction(
                              tooltip: l10n.storeThemePreviewAction,
                              onPressed: onOpenThemePreview,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 8, 6),
            child: Row(
              children: [
                if (isIap)
                  _GridCurrencyPrice(
                    label: priceString,
                    fillColor: const Color(0xFFFFD700),
                    strokeColor: const Color(0xFF795548),
                  )
                else ...[
                  if (item.priceCoins != null)
                    _GridCurrencyPrice(
                      label: '${item.priceCoins}',
                      icon: Image.asset(
                        'assets/shop/icon/candy.png',
                        width: 24,
                        height: 24,
                      ),
                      fillColor: const Color(0xFFFFB1C6),
                      strokeColor: Colors.black,
                    ),
                  if (item.priceCoins != null && item.priceDiamonds != null)
                    const SizedBox(width: 4),
                  if (item.priceDiamonds != null)
                    _GridCurrencyPrice(
                      label: '${item.priceDiamonds}',
                      icon: Image.asset(
                        'assets/shop/icon/diamond.png',
                        width: 24,
                        height: 24,
                      ),
                      fillColor: const Color(0xFF91DBF9),
                      strokeColor: Colors.black,
                    ),
                ],
                const Spacer(),
                _GridBuyAction(onPressed: onBuy, isOwned: isOwned),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _ShopItemCards on _ShopViewState {
  Future<void> _openThemePreview(ShopItem item) async {
    await showStoreThemePreviewDialog(context: context, item: item);
  }

  bool _isItemOwned(ShopItem item) {
    if (item.type != 'cosmetic') {
      return false;
    }
    if (item.isDefaultBackground) {
      return true;
    }
    if (item.isBackground) {
      return _roomBackgroundOwned.contains(item.id);
    }
    return (_inventory[item.id] ?? 0) > 0;
  }

  Widget _buildGridItemCard(ShopItem item, AppLocalizations l10n) {
    final isOwned = _isItemOwned(item);
    final isIap = item.isIap;
    final productId = item.iapProductId;
    final package = productId == null
        ? null
        : _findPackageByProductId(productId);
    final storeProduct = productId == null
        ? null
        : _findStoreProductByProductId(productId);
    final priceString = item.localizedIapPrice(package, storeProduct, l10n);
    final canAffordCoins = _canAfford(item, ShopCurrency.candy);
    final canAffordDiamonds = _canAfford(item, ShopCurrency.diamonds);
    final canBuyIap =
        _iapConfigured &&
        !_purchasing &&
        (package != null || storeProduct != null);
    return ShopGridItemCard(
      item: item,
      isOwned: isOwned,
      isIap: isIap,
      priceString: priceString,
      canAffordCoins: canAffordCoins,
      canAffordDiamonds: canAffordDiamonds,
      canBuyIap: canBuyIap,
      hasDepartedPets: _hasDepartedPets,
      onOpenThemePreview: () => _openThemePreview(item),
      onBuyIap: () => _purchaseIapItem(item),
      onBuyCoins: () => _purchaseItem(item),
      onBuyDiamonds: () => _purchaseDiamondItem(item),
      onHandleLetter: () => _handleLetterPurchase(item),
    );
  }
}

Future<void> showStoreThemePreviewDialog({
  required BuildContext context,
  required ShopItem item,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final bg = RoomBackgrounds.resolve(item.backgroundKey);
  await showAppDialog<void>(
    context: context,
    builder: (context) => AppDialog(
      tone: AppDialogTone.info,
      title: l10n.storeThemePreviewTitle(item.localizedName(l10n)),
      body: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: bg.previewDecoration,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.localizedName(l10n),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        AppDialogAction.primary(
          label: l10n.commonClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

class _GridCurrencyPrice extends StatelessWidget {
  const _GridCurrencyPrice({
    required this.label,
    this.icon,
    required this.fillColor,
    required this.strokeColor,
  });

  final String label;
  final Widget? icon;
  final Color fillColor;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 3)],
        _ShopStrokeText(
          label,
          fontSize: 16,
          color: fillColor,
          strokeColor: strokeColor.withValues(alpha: 0.8),
          strokeWidth: 3.5,
        ),
      ],
    );
  }
}

class _ShopRaisedButtonShell extends StatefulWidget {
  const _ShopRaisedButtonShell({
    required this.onPressed,
    required this.borderRadius,
    required this.shadowColor,
    required this.faceBuilder,
    required this.depth,
  });

  final VoidCallback? onPressed;
  final BorderRadius borderRadius;
  final Color shadowColor;
  final Widget Function(BuildContext context, bool isPressed) faceBuilder;
  final double depth;

  @override
  State<_ShopRaisedButtonShell> createState() => _ShopRaisedButtonShellState();
}

class _ShopRaisedButtonShellState extends State<_ShopRaisedButtonShell> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || widget.onPressed == null) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: isEnabled ? (_) => _setPressed(true) : null,
      onTapUp: isEnabled ? (_) => _setPressed(false) : null,
      onTapCancel: isEnabled ? () => _setPressed(false) : null,
      child: Stack(
        children: [
          Positioned.fill(
            top: widget.depth,
            child: Container(
              decoration: BoxDecoration(
                color: widget.shadowColor,
                borderRadius: widget.borderRadius,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(bottom: _isPressed ? 0 : widget.depth),
            child: AnimatedScale(
              scale: _isPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOutCubic,
              child: widget.faceBuilder(context, _isPressed),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBuyAction extends StatelessWidget {
  const _GridBuyAction({this.onPressed, required this.isOwned});

  final VoidCallback? onPressed;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ShopRaisedButtonShell(
      onPressed: onPressed,
      depth: 3,
      borderRadius: BorderRadius.circular(20),
      shadowColor: isOwned ? Colors.grey.shade400 : const Color(0xFFE65100),
      faceBuilder: (context, isPressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: isOwned
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD180), Color(0xFFFB8C00)],
                ),
          color: isOwned ? Colors.grey.shade200 : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _ShopStrokeText(
          isOwned ? l10n.commonOwned : l10n.commonBuy,
          fontSize: 16,
          color: Colors.white,
          strokeColor: isOwned ? Colors.grey.shade500 : const Color(0xFFD54900),
          strokeWidth: 3.5,
        ),
      ),
    );
  }
}

class _GridPreviewAction extends StatelessWidget {
  const _GridPreviewAction({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: const Icon(
            Icons.visibility_rounded,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
