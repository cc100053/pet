part of '../store_view.dart';

extension _StorePurchaseHandler on _StoreViewState {
  bool get _hasDepartedPets => _departedPets.isNotEmpty;

  Future<void> _handleLetterPurchase(StoreItem item) async {
    final l10n = AppLocalizations.of(context)!;
    if (_purchasing) {
      return;
    }
    if (widget.onReturnPet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storeProductUnavailable)));
      return;
    }
    if (!_hasDepartedPets) {
      await _showNoDepartedPetsDialog(l10n);
      return;
    }

    DepartedPetInfo? target;
    if (_departedPets.length == 1) {
      target = _departedPets.first;
    } else {
      target = await _selectDepartedPet(l10n);
      if (target == null) {
        return;
      }
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

  bool _canAfford(StoreItem item, _StoreCurrency currency) {
    final price = currency == _StoreCurrency.candy
        ? item.priceCoins
        : item.priceDiamonds;
    if (price == null) {
      return false;
    }
    return currency == _StoreCurrency.candy
        ? _coins >= price
        : _diamonds >= price;
  }

  bool _ensureCurrencyPurchasable(StoreItem item, _StoreCurrency currency) {
    final l10n = AppLocalizations.of(context)!;
    final price = currency == _StoreCurrency.candy
        ? item.priceCoins
        : item.priceDiamonds;
    if (price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storeProductUnavailable)));
      return false;
    }
    final canAfford = _canAfford(item, currency);
    if (canAfford) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currency == _StoreCurrency.candy
              ? l10n.storeNotEnoughCoins
              : l10n.storeNotEnoughDiamonds,
        ),
      ),
    );
    return false;
  }

  Future<bool> _purchaseItem(StoreItem item) async {
    if (_purchasing) {
      return false;
    }
    if (!_ensureCurrencyPurchasable(item, _StoreCurrency.candy)) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.storeBackgroundRoomRequired,
              ),
            ),
          );
          return false;
        }
        final response = await Supabase.instance.client.rpc(
          'purchase_room_furniture_with_coins',
          params: {'p_room_id': roomId, 'p_item_id': item.id},
        );

        Map<String, dynamic>? row;
        if (response is List && response.isNotEmpty) {
          row = response.first as Map<String, dynamic>;
        } else if (response is Map) {
          row = response.cast<String, dynamic>();
        }

        if (row != null) {
          final remaining = row['remaining_coins'] as int?;
          final newQuantity = row['new_quantity'] as int?;
          _setStoreState(() {
            if (remaining != null) {
              _coins = remaining;
            }
            if (newQuantity != null) {
              _inventory[item.id] = newQuantity;
            }
          });
        }
      } else {
        final response = await Supabase.instance.client.rpc(
          'purchase_item_with_coins',
          params: {'p_item_id': item.id, 'p_quantity': 1},
        );

        Map<String, dynamic>? row;
        if (response is List && response.isNotEmpty) {
          row = response.first as Map<String, dynamic>;
        } else if (response is Map) {
          row = response.cast<String, dynamic>();
        }

        if (row != null) {
          final remaining = row['remaining_coins'] as int?;
          final newQuantity = row['new_quantity'] as int?;
          _setStoreState(() {
            if (remaining != null) {
              _coins = remaining;
            }
            if (newQuantity != null) {
              _inventory[item.id] = newQuantity;
            }
          });
        }
      }

      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.storePurchaseSuccess(
              item.localizedName(AppLocalizations.of(context)!),
            ),
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.storePurchaseFailed(userFacingError(context, error)),
          ),
        ),
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

  Future<bool> _purchaseDiamondItem(StoreItem item) async {
    if (_purchasing) {
      return false;
    }
    if (!_ensureCurrencyPurchasable(item, _StoreCurrency.diamonds)) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.storeBackgroundRoomRequired,
              ),
            ),
          );
          return false;
        }
        final response = await Supabase.instance.client.rpc(
          'purchase_room_furniture_with_diamonds',
          params: {'p_room_id': roomId, 'p_item_id': item.id},
        );

        Map<String, dynamic>? row;
        if (response is List && response.isNotEmpty) {
          row = response.first as Map<String, dynamic>;
        } else if (response is Map) {
          row = response.cast<String, dynamic>();
        }

        if (row != null) {
          final remaining = row['remaining_diamonds'] as int?;
          final newQuantity = row['new_quantity'] as int?;
          _setStoreState(() {
            if (remaining != null) {
              _diamonds = remaining;
            }
            if (newQuantity != null) {
              _inventory[item.id] = newQuantity;
            }
          });
        }
      } else {
        final response = await Supabase.instance.client.rpc(
          'purchase_item_with_diamonds',
          params: {'p_item_id': item.id, 'p_quantity': 1},
        );

        Map<String, dynamic>? row;
        if (response is List && response.isNotEmpty) {
          row = response.first as Map<String, dynamic>;
        } else if (response is Map) {
          row = response.cast<String, dynamic>();
        }

        if (row != null) {
          final remaining = row['remaining_diamonds'] as int?;
          final newQuantity = row['new_quantity'] as int?;
          final newCoinBalance = row['new_coin_balance'] as int?;
          _setStoreState(() {
            if (remaining != null) {
              _diamonds = remaining;
            }
            if (newQuantity != null) {
              _inventory[item.id] = newQuantity;
            }
            if (newCoinBalance != null) {
              _coins = newCoinBalance;
            }
          });
        }
      }

      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.storePurchaseSuccess(
              item.localizedName(AppLocalizations.of(context)!),
            ),
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.storePurchaseFailed(userFacingError(context, error)),
          ),
        ),
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

  Future<bool> _purchaseBackgroundWithCoins(StoreItem item) async {
    final roomId = widget.roomId;
    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.storeBackgroundRoomRequired,
          ),
        ),
      );
      return false;
    }

    final response = await Supabase.instance.client.rpc(
      'purchase_room_background_with_coins',
      params: {'p_room_id': roomId, 'p_item_id': item.id},
    );

    Map<String, dynamic>? row;
    if (response is List && response.isNotEmpty) {
      row = response.first as Map<String, dynamic>;
    } else if (response is Map) {
      row = response.cast<String, dynamic>();
    }

    if (row != null) {
      final remaining = row['remaining_coins'] as int?;
      final alreadyOwned = row['already_owned'] as bool? ?? false;
      _setStoreState(() {
        if (remaining != null) {
          _coins = remaining;
        }
        if (!alreadyOwned) {
          _roomBackgroundOwned.add(item.id);
        }
      });
    }
    return true;
  }

  Future<bool> _purchaseBackgroundWithDiamonds(StoreItem item) async {
    final roomId = widget.roomId;
    if (roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.storeBackgroundRoomRequired,
          ),
        ),
      );
      return false;
    }

    final response = await Supabase.instance.client.rpc(
      'purchase_room_background_with_diamonds',
      params: {'p_room_id': roomId, 'p_item_id': item.id},
    );

    Map<String, dynamic>? row;
    if (response is List && response.isNotEmpty) {
      row = response.first as Map<String, dynamic>;
    } else if (response is Map) {
      row = response.cast<String, dynamic>();
    }

    if (row != null) {
      final remaining = row['remaining_diamonds'] as int?;
      final alreadyOwned = row['already_owned'] as bool? ?? false;
      _setStoreState(() {
        if (remaining != null) {
          _diamonds = remaining;
        }
        if (!alreadyOwned) {
          _roomBackgroundOwned.add(item.id);
        }
      });
    }
    return true;
  }
}
