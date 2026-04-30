part of '../shop_view.dart';

extension _ShopPurchaseHandler on _ShopViewState {
  bool get _hasDepartedPets => _departedPets.isNotEmpty;

  DepartedPetInfo? _currentRoomDepartedPet() {
    final roomId = widget.roomId;
    if (roomId != null) {
      for (final pet in _departedPets) {
        if (pet.roomId == roomId) {
          return pet;
        }
      }
    }
    if (_departedPets.length == 1) {
      return _departedPets.first;
    }
    return null;
  }

  Future<void> _handleLetterPurchase(ShopItem item) async {
    final l10n = AppLocalizations.of(context)!;
    if (_purchasing) {
      return;
    }
    if (widget.onReturnPet == null) {
      showJuiceToast(
        context: context,
        message: l10n.storeProductUnavailable,
        tone: AppDialogTone.warning,
      );
      return;
    }
    if (!_hasDepartedPets) {
      await _showNoDepartedPetsDialog(l10n);
      return;
    }

    final target = _currentRoomDepartedPet();
    if (target == null) {
      await _showNoDepartedPetsDialog(l10n);
      return;
    }

    final confirmed = await _confirmLetterPurchase(l10n, target);
    if (!confirmed) {
      return;
    }

    bool success;
    if (item.priceCoins != null) {
      success = await _purchaseItem(item);
    } else if (item.priceDiamonds != null) {
      success = await _purchaseDiamondItem(item);
    } else {
      return;
    }

    if (!success) {
      return;
    }

    final DepartedPetInfo selectedPet = target;
    final didReturn = await widget.onReturnPet!(selectedPet);
    if (!didReturn) {
      return;
    }
    await _consumePurchasedItem(item.id);

    if (!mounted) {
      return;
    }
    _setStoreState(() {
      _departedPets.removeWhere((pet) => pet.petId == selectedPet.petId);
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(
        context,
      ).pop(ShopRouteResult.returnedRoom(selectedPet.roomId));
    }
  }

  Future<void> _consumePurchasedItem(String itemId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    final currentQty = _inventory[itemId] ?? 0;
    if (currentQty <= 0) {
      return;
    }
    final nextQty = currentQty - 1;
    if (nextQty > 0) {
      await Supabase.instance.client
          .from('inventories')
          .update({'quantity': nextQty})
          .eq('user_id', user.id)
          .eq('item_id', itemId);
    } else {
      await Supabase.instance.client
          .from('inventories')
          .delete()
          .eq('user_id', user.id)
          .eq('item_id', itemId);
    }
    if (!mounted) {
      return;
    }
    _setStoreState(() {
      if (nextQty > 0) {
        _inventory[itemId] = nextQty;
      } else {
        _inventory.remove(itemId);
      }
    });
  }

  bool _canAfford(ShopItem item, ShopCurrency currency) {
    final price = currency == ShopCurrency.candy
        ? item.priceCoins
        : item.priceDiamonds;
    if (price == null) {
      return false;
    }
    return currency == ShopCurrency.candy
        ? _coins >= price
        : _diamonds >= price;
  }

  bool _ensureCurrencyPurchasable(ShopItem item, ShopCurrency currency) {
    final l10n = AppLocalizations.of(context)!;
    final price = currency == ShopCurrency.candy
        ? item.priceCoins
        : item.priceDiamonds;
    if (price == null) {
      showJuiceToast(
        context: context,
        message: l10n.storeProductUnavailable,
        tone: AppDialogTone.warning,
      );
      return false;
    }
    final canAfford = _canAfford(item, currency);
    if (canAfford) {
      return true;
    }
    _showShortageStoreNotice(
      title: currency == ShopCurrency.candy
          ? l10n.storeNotEnoughCoins
          : l10n.storeNotEnoughDiamonds,
      currency: currency,
      requiredAmount: price,
    );
    return false;
  }

  ShopEconomyStatePurchaseChange _applyPurchaseResult(
    ShopItem item,
    EconomyPurchaseResult result,
  ) {
    final change =
        ShopEconomyState(
          coins: _coins,
          diamonds: _diamonds,
          inventory: _inventory,
          ownedBackgroundIds: _roomBackgroundOwned,
          coinReward: _coinReward,
          coinRewardEventId: _coinRewardEventId,
        ).applyPurchaseResult(
          itemId: item.id,
          isBackground: item.isBackground,
          result: result,
        );
    _setStoreState(() {
      final state = change.state;
      _coins = state.coins;
      _diamonds = state.diamonds;
      _inventory
        ..clear()
        ..addAll(state.inventory);
      _roomBackgroundOwned
        ..clear()
        ..addAll(state.ownedBackgroundIds);
      _coinReward = state.coinReward;
      _coinRewardEventId = state.coinRewardEventId;
    });
    return change;
  }

  void _notifyPurchaseIfNeeded({
    required String roomId,
    required EconomyPurchaseResult result,
  }) {
    final messageId = result.purchaseNotificationMessageId;
    if (messageId == null || messageId.isEmpty) {
      return;
    }
    unawaited(
      _purchaseNotifier.notifyStorePurchase(
        roomId: roomId,
        messageId: messageId,
      ),
    );
  }

  Future<bool> _purchaseItem(ShopItem item) async {
    if (_purchasing) {
      return false;
    }
    if (!_ensureCurrencyPurchasable(item, ShopCurrency.candy)) {
      return false;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }

    _setStoreState(() {
      _purchasing = true;
    });

    try {
      if (item.isBackground) {
        final success = await _purchaseBackgroundWithCoins(item);
        if (!success) {
          return false;
        }
      } else if (item.isFurniture) {
        final roomId = widget.roomId;
        if (roomId == null) {
          showJuiceToast(
            context: context,
            message: AppLocalizations.of(context)!.storeBackgroundRoomRequired,
            tone: AppDialogTone.warning,
          );
          return false;
        }
        final result = await _economyPurchaseAdapter
            .purchaseRoomFurnitureWithCoins(roomId: roomId, itemId: item.id);
        _applyPurchaseResult(item, result);
        _notifyPurchaseIfNeeded(roomId: roomId, result: result);
      } else if (item.isEquipment) {
        final roomId = widget.roomId;
        if (roomId == null) {
          showJuiceToast(
            context: context,
            message: AppLocalizations.of(context)!.storeBackgroundRoomRequired,
            tone: AppDialogTone.warning,
          );
          return false;
        }
        final result = await _economyPurchaseAdapter
            .purchaseRoomEquipmentWithCoins(roomId: roomId, itemId: item.id);
        _applyPurchaseResult(item, result);
      } else {
        final result = await _economyPurchaseAdapter.purchaseItemWithCoins(
          itemId: item.id,
        );
        _applyPurchaseResult(item, result);
      }

      if (!mounted) {
        return false;
      }
      _showPurchaseSuccessNotice(
        item: item,
        showReturnToRoomAction:
            item.isFurniture || item.isBackground || item.isEquipment,
      );
      AnalyticsService.instance.logEvent(
        'purchase_coins',
        parameters: {'result': 'success', 'sku': item.sku},
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
      AnalyticsService.instance.logEvent(
        'purchase_coins',
        parameters: {'result': 'failure', 'sku': item.sku},
      );
      return false;
    } finally {
      if (mounted) {
        _setStoreState(() {
          _purchasing = false;
        });
      }
    }
  }

  Future<bool> _purchaseDiamondItem(ShopItem item) async {
    if (_purchasing) {
      return false;
    }
    if (!_ensureCurrencyPurchasable(item, ShopCurrency.diamonds)) {
      return false;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }

    _setStoreState(() {
      _purchasing = true;
    });

    try {
      if (item.isBackground) {
        final success = await _purchaseBackgroundWithDiamonds(item);
        if (!success) {
          return false;
        }
      } else if (item.isFurniture) {
        final roomId = widget.roomId;
        if (roomId == null) {
          showJuiceToast(
            context: context,
            message: AppLocalizations.of(context)!.storeBackgroundRoomRequired,
            tone: AppDialogTone.warning,
          );
          return false;
        }
        final result = await _economyPurchaseAdapter
            .purchaseRoomFurnitureWithDiamonds(roomId: roomId, itemId: item.id);
        _applyPurchaseResult(item, result);
        _notifyPurchaseIfNeeded(roomId: roomId, result: result);
      } else if (item.isEquipment) {
        final roomId = widget.roomId;
        if (roomId == null) {
          showJuiceToast(
            context: context,
            message: AppLocalizations.of(context)!.storeBackgroundRoomRequired,
            tone: AppDialogTone.warning,
          );
          return false;
        }
        final result = await _economyPurchaseAdapter
            .purchaseRoomEquipmentWithDiamonds(roomId: roomId, itemId: item.id);
        _applyPurchaseResult(item, result);
      } else {
        final result = await _economyPurchaseAdapter.purchaseItemWithDiamonds(
          itemId: item.id,
          previousCoinBalance: _coins,
        );
        final change = _applyPurchaseResult(item, result);
        if (change.shouldPlayCoinGainSfx) {
          unawaited(AppSfx.playCandyGain());
        }
      }

      if (!mounted) {
        return false;
      }
      _showPurchaseSuccessNotice(
        item: item,
        showReturnToRoomAction:
            item.isFurniture || item.isBackground || item.isEquipment,
      );
      AnalyticsService.instance.logEvent(
        'purchase_diamonds',
        parameters: {'result': 'success', 'sku': item.sku},
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
      AnalyticsService.instance.logEvent(
        'purchase_diamonds',
        parameters: {'result': 'failure', 'sku': item.sku},
      );
      return false;
    } finally {
      if (mounted) {
        _setStoreState(() {
          _purchasing = false;
        });
      }
    }
  }

  Future<bool> _purchaseBackgroundWithCoins(ShopItem item) async {
    final roomId = widget.roomId;
    if (roomId == null) {
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(context)!.storeBackgroundRoomRequired,
        tone: AppDialogTone.warning,
      );
      return false;
    }

    final result = await _economyPurchaseAdapter
        .purchaseRoomBackgroundWithCoins(roomId: roomId, itemId: item.id);
    _applyPurchaseResult(item, result);
    _notifyPurchaseIfNeeded(roomId: roomId, result: result);
    return true;
  }

  Future<bool> _purchaseBackgroundWithDiamonds(ShopItem item) async {
    final roomId = widget.roomId;
    if (roomId == null) {
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(context)!.storeBackgroundRoomRequired,
        tone: AppDialogTone.warning,
      );
      return false;
    }

    final result = await _economyPurchaseAdapter
        .purchaseRoomBackgroundWithDiamonds(roomId: roomId, itemId: item.id);
    _applyPurchaseResult(item, result);
    _notifyPurchaseIfNeeded(roomId: roomId, result: result);
    return true;
  }
}
