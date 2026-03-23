part of '../store_view.dart';

extension _StoreItemCards on _StoreViewState {
  Future<void> _openThemePreview(StoreItem item) async {
    await showStoreThemePreviewDialog(context: context, item: item);
  }

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
    final package = productId == null
        ? null
        : _findPackageByProductId(productId);
    final storeProduct = productId == null
        ? null
        : _findStoreProductByProductId(productId);
    final priceString = item.localizedIapPrice(package, storeProduct, l10n);
    final isLetter = item.isRecoveryLetter;
    final canAffordCoins = _canAfford(item, _StoreCurrency.candy);
    final canAffordDiamonds = _canAfford(item, _StoreCurrency.diamonds);
    final canBuyCoins =
        !isOwned &&
        canAffordCoins &&
        item.priceCoins != null &&
        (!isLetter || _hasDepartedPets);
    final canBuyDiamonds =
        !isOwned &&
        canAffordDiamonds &&
        item.priceDiamonds != null &&
        (!isLetter || _hasDepartedPets);
    final canBuyIap =
        _iapConfigured &&
        !_purchasing &&
        (package != null || storeProduct != null);

    final itemEmoji =
        item.emoji ?? (item.isBackground ? '🖼️' : (isLetter ? '💌' : '🎁'));

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
              decoration: item.isBackground
                  ? RoomBackgrounds.resolve(item.backgroundKey).previewDecoration.copyWith(
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
                    child: _StoreStrokeText(
                      item.localizedName(l10n),
                      fontSize: 20,
                      color: Colors.white,
                      strokeColor: const Color(0xFF1A237E),
                      strokeWidth: 3.5,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (!item.isBackground)
                          Center(
                            child: Text(
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
                              onPressed: () => _openThemePreview(item),
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
                        'assets/icon/store/candy.png',
                        width: 24,
                        height: 24,
                      ),
                      fillColor: const Color(0xFFFFB1C6), // Custom Soft Pink
                      strokeColor: Colors.black,
                    ),
                  if (item.priceCoins != null && item.priceDiamonds != null)
                    const SizedBox(width: 4),
                  if (item.priceDiamonds != null)
                    _GridCurrencyPrice(
                      label: '${item.priceDiamonds}',
                      icon: Image.asset(
                        'assets/icon/store/diamond.png',
                        width: 24,
                        height: 24,
                      ),
                      fillColor: const Color(0xFF91DBF9), // Custom Light Blue
                      strokeColor: Colors.black,
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

Future<void> showStoreThemePreviewDialog({
  required BuildContext context,
  required StoreItem item,
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
        _StoreStrokeText(
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

class _GridBuyAction extends StatelessWidget {
  const _GridBuyAction({this.onPressed, required this.isOwned});

  final VoidCallback? onPressed;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          // Bottom Shadow (3D effect)
          Positioned.fill(
            top: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isOwned ? Colors.grey.shade400 : const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 3.0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: isOwned
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFD180),
                        Color(0xFFFB8C00),
                      ],
                    ),
              color: isOwned ? Colors.grey.shade200 : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _StoreStrokeText(
              isOwned ? l10n.commonOwned : l10n.commonBuy,
              fontSize: 16,
              color: Colors.white,
              strokeColor: isOwned ? Colors.grey.shade500 : const Color(0xFFD54900),
              strokeWidth: 3.5,
            ),
          ),
        ],
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
