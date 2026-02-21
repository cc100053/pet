part of '../store_view.dart';

extension _StoreItemCards on _StoreViewState {
  Widget _buildIapCard(StoreItem item, AppLocalizations l10n) {
    final productId = item.iapProductId;
    final package = productId == null
        ? null
        : _findPackageByProductId(productId);
    final storeProduct = productId == null
        ? null
        : _findStoreProductByProductId(productId);
    final priceString = item.localizedIapPrice(package, storeProduct, l10n);
    final isSubscription = item.iapType == 'subscription';
    final isDiamondPack = item.isDiamondIap;
    final entitlementId = item.rcEntitlementId;
    final isSubscribed =
        isSubscription &&
        entitlementId != null &&
        _activeEntitlements.contains(entitlementId);
    final canBuy =
        _iapConfigured &&
        !_purchasing &&
        (package != null || storeProduct != null);
    final packColor = isDiamondPack ? _diamondColor : Colors.amber;
    final activeStatusText = isSubscription && isSubscribed
        ? l10n.storeSubscriptionActive
        : null;
    final actionLabel = isSubscription
        ? (isSubscribed ? l10n.commonOwned : l10n.storeSubscribe)
        : l10n.commonBuy;
    final description = item.localizedDescription(l10n);

    if (isSubscription) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppTheme.secondaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.storeTabPremium,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        item.localizedName(l10n),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (description != null)
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      if (activeStatusText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          activeStatusText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.storeSubscriptionDurationMonthly} • ${l10n.storeSubscriptionRenewalNote}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildIapActionButton(
              item: item,
              isSubscribed: isSubscribed,
              canBuy: canBuy,
              isSubscription: isSubscription,
              priceString: priceString,
              actionLabel: actionLabel,
              stretch: true,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isSubscription
            ? Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSubscription
                  ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                  : packColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              isSubscription
                  ? Icons.stars_rounded
                  : (isDiamondPack
                        ? Icons.diamond_rounded
                        : Icons.monetization_on_rounded),
              color: isSubscription ? AppTheme.secondaryColor : packColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSubscription)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.storeTabPremium,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isDiamondPack && item.diamondAmount != null)
                  _CurrencyDeltaLabel(
                    amount: item.diamondAmount!,
                    icon: Icons.diamond_rounded,
                    color: packColor,
                  )
                else if (item.coinAmount != null)
                  _CurrencyDeltaLabel(
                    amount: item.coinAmount!,
                    icon: Icons.monetization_on_rounded,
                    color: Colors.amber.shade700,
                  ),

                Text(
                  item.localizedName(l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (description != null)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                if (activeStatusText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activeStatusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (isSubscription) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.storeSubscriptionRenewalNote,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIapActionButton(
                item: item,
                isSubscribed: isSubscribed,
                canBuy: canBuy,
                isSubscription: isSubscription,
                priceString: priceString,
                actionLabel: actionLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIapActionButton({
    required StoreItem item,
    required bool isSubscribed,
    required bool canBuy,
    required bool isSubscription,
    required String priceString,
    required String actionLabel,
    bool stretch = false,
  }) {
    return GestureDetector(
      onTap: isSubscribed || !canBuy ? null : () => _purchaseIapItem(item),
      child: Opacity(
        opacity: isSubscribed || !canBuy ? 0.6 : 1.0,
        child: Container(
          width: stretch ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSubscribed
                ? null
                : (isSubscription
                      ? AppTheme.accentGradient
                      : AppTheme.primaryGradient),
            color: isSubscribed ? Colors.grey[200] : null,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSubscribed
                ? []
                : [
                    BoxShadow(
                      color:
                          (isSubscription
                                  ? AppTheme.secondaryColor
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: _buildIapButtonLabel(
            priceString: priceString,
            actionLabel: actionLabel,
            isSubscribed: isSubscribed,
          ),
        ),
      ),
    );
  }

  Widget _buildIapButtonLabel({
    required String priceString,
    required String actionLabel,
    required bool isSubscribed,
  }) {
    final textColor = isSubscribed ? Colors.grey : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          priceString,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          actionLabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            height: 1.0,
          ),
        ),
      ],
    );
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

  int _ownedQuantity(StoreItem item) => _inventory[item.id] ?? 0;

  Widget _buildStoreItemCard(StoreItem item, AppLocalizations l10n) {
    if (item.isBackground) {
      return _buildThemeItemCard(item, l10n);
    }
    final ownedQty = _ownedQuantity(item);
    final isCosmetic = item.type == 'cosmetic';
    final isOwned = isCosmetic && _isItemOwned(item);
    final isLetter = item.isRecoveryLetter;
    final canAffordCoins = _canAfford(item, _StoreCurrency.candy);
    final canAffordDiamonds = _canAfford(item, _StoreCurrency.diamonds);
    final showQuantity = !isCosmetic && !isLetter && ownedQty > 0;
    final baseCanBuyCoins =
        !_purchasing && !isOwned && canAffordCoins && item.priceCoins != null;
    final baseCanBuyDiamonds =
        !_purchasing &&
        !isOwned &&
        canAffordDiamonds &&
        item.priceDiamonds != null;
    final canBuyCoins = isLetter
        ? baseCanBuyCoins && _hasDepartedPets
        : baseCanBuyCoins;
    final canBuyDiamonds = isLetter
        ? baseCanBuyDiamonds && _hasDepartedPets
        : baseCanBuyDiamonds;
    final itemEmoji =
        item.emoji ?? (item.isBackground ? '🖼️' : (isLetter ? '💌' : '🎁'));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isOwned
                  ? Colors.grey.withValues(alpha: 0.15)
                  : AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(itemEmoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.localizedName(l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  item.localizedDescription(l10n) ??
                      _displayTypeLabel(item, l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (showQuantity) ...[
                  Text(
                    l10n.storeOwnedCount(ownedQty),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (isOwned)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.commonOwned,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              if (item.priceCoins != null)
                _CurrencyBuyButton(
                  amount: item.priceCoins!,
                  icon: SvgPicture.asset(
                    'assets/icon/icon-park--candy.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      canBuyCoins ? Colors.white : Colors.black54,
                      BlendMode.srcIn,
                    ),
                  ),
                  color: Colors.amber,
                  enabled: canBuyCoins,
                  onPressed: () {
                    if (!canBuyCoins) {
                      return;
                    }
                    if (isLetter) {
                      _handleLetterPurchase(item);
                    } else {
                      _purchaseItem(item);
                    }
                  },
                ),
              if (item.priceCoins != null && item.priceDiamonds != null)
                const SizedBox(height: 6),
              if (item.priceDiamonds != null)
                _CurrencyBuyButton(
                  amount: item.priceDiamonds!,
                  icon: const Icon(Icons.diamond_rounded, size: 16),
                  color: _diamondColor,
                  enabled: canBuyDiamonds,
                  onPressed: () {
                    if (!canBuyDiamonds) {
                      return;
                    }
                    if (isLetter) {
                      _handleLetterPurchase(item);
                    } else {
                      _purchaseDiamondItem(item);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeItemCard(StoreItem item, AppLocalizations l10n) {
    final isOwned = _isItemOwned(item);
    final canAffordCoins = _canAfford(item, _StoreCurrency.candy);
    final canAffordDiamonds = _canAfford(item, _StoreCurrency.diamonds);
    final canBuyCoins =
        !_purchasing && !isOwned && canAffordCoins && item.priceCoins != null;
    final canBuyDiamonds =
        !_purchasing &&
        !isOwned &&
        canAffordDiamonds &&
        item.priceDiamonds != null;
    final bg = RoomBackgrounds.resolve(item.backgroundKey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 60,
              height: 60,
              child: DecoratedBox(decoration: bg.previewDecoration),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.localizedName(l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  item.localizedDescription(l10n) ??
                      _displayTypeLabel(item, l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openThemePreview(item),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: Text(l10n.storeThemePreviewAction),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ),
                if (isOwned)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.commonOwned,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              if (item.priceCoins != null)
                _CurrencyBuyButton(
                  amount: item.priceCoins!,
                  icon: SvgPicture.asset(
                    'assets/icon/icon-park--candy.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      canBuyCoins ? Colors.white : Colors.black54,
                      BlendMode.srcIn,
                    ),
                  ),
                  color: Colors.amber,
                  enabled: canBuyCoins,
                  onPressed: () => _purchaseItem(item),
                ),
              if (item.priceCoins != null && item.priceDiamonds != null)
                const SizedBox(height: 6),
              if (item.priceDiamonds != null)
                _CurrencyBuyButton(
                  amount: item.priceDiamonds!,
                  icon: const Icon(Icons.diamond_rounded, size: 16),
                  color: _diamondColor,
                  enabled: canBuyDiamonds,
                  onPressed: () => _purchaseDiamondItem(item),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openThemePreview(StoreItem item) async {
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

  String _displayTypeLabel(StoreItem item, AppLocalizations l10n) {
    if (item.iapType == 'subscription') {
      return l10n.storeTypeSubscription;
    }
    switch (item.type) {
      case 'cosmetic':
        return l10n.storeTypeCosmetic;
      case 'consumable':
        return l10n.storeTypeConsumable;
      case 'subscription':
        return l10n.storeTypeSubscription;
      default:
        return item.type;
    }
  }
}
