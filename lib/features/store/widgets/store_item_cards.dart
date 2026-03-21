part of '../store_view.dart';

extension _StoreItemCards on _StoreViewState {
  bool _isItemOwned(StoreItem item) {
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

  Widget _buildGridItemCard(StoreItem item, AppLocalizations l10n) {
    final isOwned = _isItemOwned(item);
    final isIap = item.isIap;
    final productId = item.iapProductId;
    final package = productId == null ? null : _findPackageByProductId(productId);
    final storeProduct = productId == null ? null : _findStoreProductByProductId(productId);
    final priceString = item.localizedIapPrice(package, storeProduct, l10n);
    final isLetter = item.isRecoveryLetter;
    final canAffordCoins = _canAfford(item, _StoreCurrency.candy);
    final canAffordDiamonds = _canAfford(item, _StoreCurrency.diamonds);
    final canBuyCoins = !isOwned && canAffordCoins && item.priceCoins != null && (!isLetter || _hasDepartedPets);
    final canBuyDiamonds = !isOwned && canAffordDiamonds && item.priceDiamonds != null && (!isLetter || _hasDepartedPets);
    final canBuyIap = _iapConfigured && !_purchasing && (package != null || storeProduct != null);

    final itemEmoji = item.emoji ?? (item.isBackground ? '🖼️' : (isLetter ? '💌' : '🎁'));

    final int colorIndex = item.id.hashCode.abs() % 3;
    final List<List<Color>> gradientPairs = [
      [const Color(0xFFFFEBF0), const Color(0xFFFFF9C4)],
      [const Color(0xFFE1F5FE), const Color(0xFFE8F5E9)],
      [const Color(0xFFF3E5F5), const Color(0xFFFFE0B2)],
    ];
    final List<Color> bgGradient = gradientPairs[colorIndex];

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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _StoreStrokeText(
                      item.localizedName(l10n),
                      fontSize: 12,
                      color: Colors.white,
                      strokeColor: const Color(0xFF3F51B5).withValues(alpha: 0.6),
                      strokeWidth: 2.0,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: item.isBackground
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: DecoratedBox(decoration: RoomBackgrounds.resolve(item.backgroundKey).previewDecoration),
                              ),
                            )
                          : Text(itemEmoji, style: const TextStyle(fontSize: 36)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
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
                        'assets/icon/store/candy.png',
                        width: 18,
                        height: 18,
                      ),
                      fillColor: _candyColor,
                      strokeColor: const Color(0xFFBF360C),
                    ),
                  if (item.priceCoins != null && item.priceDiamonds != null)
                    const SizedBox(width: 4),
                  if (item.priceDiamonds != null)
                    _GridCurrencyPrice(
                      label: '${item.priceDiamonds}',
                      icon: Image.asset(
                        'assets/icon/store/diamond.png',
                        width: 18,
                        height: 18,
                      ),
                      fillColor: _diamondColor,
                      strokeColor: const Color(0xFF1A237E),
                    ),
                ],
                const Spacer(),
                _GridBuyAction(
                  onPressed: isOwned
                      ? null
                      : (isIap
                          ? (canBuyIap ? () => _purchaseIapItem(item) : null)
                          : (canBuyCoins
                              ? () {
                                  if (isLetter) {
                                    _handleLetterPurchase(item);
                                  } else {
                                    _purchaseItem(item);
                                  }
                                }
                              : (canBuyDiamonds
                                  ? () {
                                      if (isLetter) {
                                        _handleLetterPurchase(item);
                                      } else {
                                        _purchaseDiamondItem(item);
                                      }
                                    }
                                  : null))),
                  isOwned: isOwned,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 3),
        ],
        _StoreStrokeText(
          label,
          fontSize: 13,
          color: fillColor,
          strokeColor: strokeColor.withValues(alpha: 0.8),
          strokeWidth: 2.0,
        ),
      ],
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
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isOwned
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFD180),
                    Color(0xFFFFB74D),
                    Color(0xFFFB8C00),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
          color: isOwned ? Colors.grey[200] : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOwned ? Colors.black12 : Colors.white.withValues(alpha: 0.9),
            width: 2.0,
          ),
          boxShadow: isOwned
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFE65100).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: isOwned
            ? Text(
                l10n.commonOwned,
                style: GoogleFonts.mPlusRounded1c(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              )
            : _StoreStrokeText(
                l10n.commonBuy,
                fontSize: 12,
                color: Colors.white,
                strokeColor: const Color(0xFFBF360C).withValues(alpha: 0.3),
                strokeWidth: 2.0,
              ),
      ),
    );
  }
}
