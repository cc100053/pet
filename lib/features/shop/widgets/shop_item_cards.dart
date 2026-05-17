part of '../shop_view.dart';

class ShopGridItemCard extends StatelessWidget {
  const ShopGridItemCard({
    super.key,
    required this.item,
    required this.isOwned,
    required this.ownedQuantity,
    required this.maxOwnedQuantity,
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
    required this.onUsePetTicket,
  });

  final ShopItem item;
  final bool isOwned;
  final int ownedQuantity;
  final int maxOwnedQuantity;
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
  final VoidCallback onUsePetTicket;

  VoidCallback? _resolveBuyAction() {
    if (item.isPetTicket && ownedQuantity > 0) {
      return onUsePetTicket;
    }

    final canBuyAdditionalEquipment =
        item.isEquipment && ownedQuantity < maxOwnedQuantity;
    if (isOwned && !item.isFurniture && !canBuyAdditionalEquipment) {
      return null;
    }
    if (isIap) {
      return canBuyIap ? onBuyIap : null;
    }

    final isLetter = item.isRecoveryLetter;
    if (isLetter && !hasDepartedPets) {
      return onHandleLetter;
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
        (item.isBackground
            ? '🖼️'
            : (item.isRecoveryLetter
                  ? '💌'
                  : (item.isPetTicket ? '🎟️' : '🎁')));

    final int colorIndex = item.id.hashCode.abs() % 3;
    final List<List<Color>> gradientPairs = [
      [const Color(0xFFFFEBF0), const Color(0xFFFFF9C4)],
      [const Color(0xFFE1F5FE), const Color(0xFFE8F5E9)],
      [const Color(0xFFF3E5F5), const Color(0xFFFFE0B2)],
    ];
    final List<Color> bgGradient = gradientPairs[colorIndex];
    final onBuy = _resolveBuyAction();
    final canBuyMore =
        (item.isFurniture || item.isEquipment) &&
        ownedQuantity > 0 &&
        ownedQuantity < maxOwnedQuantity;
    final canUsePetTicket = item.isPetTicket && ownedQuantity > 0;
    final isOwnedLocked =
        isOwned && !item.isFurniture && !canBuyMore && !canUsePetTicket;
    final buyActionLabel = canUsePetTicket
        ? l10n.petTicketUseCta
        : canBuyMore
        ? l10n.commonBuyMore
        : (isOwnedLocked ? l10n.commonOwned : l10n.commonBuy);

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
                                : item.isEquipment
                                ? ShopCatalogItemVisual(
                                    item: item,
                                    size: 86,
                                    fallbackEmoji: itemEmoji,
                                  )
                                : item.isFurniture
                                ? ShopFurnitureVisual(item: item, size: 86)
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
                        if ((item.isFurniture ||
                                item.isEquipment ||
                                item.isPetTicket) &&
                            ownedQuantity > 0)
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: _GridOwnedCountBadge(
                              label: l10n.storeOwnedCount(ownedQuantity),
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
                _GridBuyAction(
                  onPressed: onBuy,
                  isOwnedLocked: isOwnedLocked,
                  label: buyActionLabel,
                ),
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
    if (item.isPetTicket) {
      return (_inventory[item.id] ?? 0) > 0;
    }
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

  int _ownedQuantityForItem(ShopItem item) {
    if (!item.isFurniture && !item.isEquipment && !item.isPetTicket) {
      return 0;
    }
    return _inventory[item.id] ?? 0;
  }

  Widget _buildGridItemCard(ShopItem item, AppLocalizations l10n) {
    final isOwned = _isItemOwned(item);
    final ownedQuantity = _ownedQuantityForItem(item);
    final maxOwnedQuantity = item.isEquipment ? _roomPetCount : 999999;
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
      ownedQuantity: ownedQuantity,
      maxOwnedQuantity: maxOwnedQuantity,
      isIap: isIap,
      priceString: priceString,
      canAffordCoins: canAffordCoins,
      canAffordDiamonds: canAffordDiamonds,
      canBuyIap: canBuyIap,
      hasDepartedPets: _hasDepartedPets,
      onOpenThemePreview: () => _openThemePreview(item),
      onBuyIap: () => _purchaseIapItem(item),
      onBuyCoins: () => _purchaseItem(item),
      onBuyDiamonds: item.isPetTicket
          ? () => _handlePetTicketPurchase(item)
          : () => _purchaseDiamondItem(item),
      onHandleLetter: () => _handleLetterPurchase(item),
      onUsePetTicket: () => _handlePetTicketUse(item),
    );
  }
}

Future<void> showStoreThemePreviewDialog({
  required BuildContext context,
  required ShopItem item,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final bg = RoomBackgrounds.resolve(item.backgroundKey);
  await showJuiceToast<void>(
    context: context,
    message: l10n.storeThemePreviewTitle(item.localizedName(l10n)),
    position: JuicePosition.center,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: bg.previewDecoration,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.localizedName(l10n),
                  style: GoogleFonts.mPlusRounded1c(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Gap(24),
        JuicyScaleButton(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Text(
                l10n.commonClose,
                style: GoogleFonts.mPlusRounded1c(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
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

class _GridOwnedCountBadge extends StatelessWidget {
  const _GridOwnedCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _ShopRaisedButtonShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    if (!isEnabled) {
      return faceBuilder(context, false);
    }

    return JuicyScaleButton(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: Offset(0, depth),
              blurRadius: 4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: faceBuilder(context, false),
      ),
    );
  }
}

class _GridBuyAction extends StatelessWidget {
  const _GridBuyAction({
    this.onPressed,
    required this.isOwnedLocked,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool isOwnedLocked;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _ShopRaisedButtonShell(
      onPressed: onPressed,
      depth: 3,
      borderRadius: BorderRadius.circular(20),
      shadowColor: isOwnedLocked
          ? Colors.grey.shade400
          : const Color(0xFFE65100),
      faceBuilder: (context, isPressed) => Container(
        constraints: const BoxConstraints(minWidth: 68, maxWidth: 104),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isOwnedLocked
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD180), Color(0xFFFB8C00)],
                ),
          color: isOwnedLocked ? Colors.grey.shade200 : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _ShopStrokeText(
            label,
            fontSize: 16,
            color: Colors.white,
            strokeColor: isOwnedLocked
                ? Colors.grey.shade500
                : const Color(0xFFD54900),
            strokeWidth: 3.5,
          ),
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
