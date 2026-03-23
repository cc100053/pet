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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storeProductUnavailable)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storeProductUnavailable)));
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
          final messageId = row['message_id'] as String?;
          _setStoreState(() {
            if (remaining != null) {
              _coins = remaining;
            }
            if (newQuantity != null) {
              _inventory[item.id] = newQuantity;
            }
          });
          if (messageId != null && messageId.isNotEmpty) {
            unawaited(
              _notifyStorePurchase(roomId: roomId, messageId: messageId),
            );
          }
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
      _showPurchaseSuccessNotice(
        item: item,
        showReturnToRoomAction: item.isFurniture || item.isBackground,
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
          final messageId = row['message_id'] as String?;
          _setStoreState(() {
            if (remaining != null) {
              _diamonds = remaining;
            }
            if (newQuantity != null) {
              _inventory[item.id] = newQuantity;
            }
          });
          if (messageId != null && messageId.isNotEmpty) {
            unawaited(
              _notifyStorePurchase(roomId: roomId, messageId: messageId),
            );
          }
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
      _showPurchaseSuccessNotice(
        item: item,
        showReturnToRoomAction: item.isFurniture || item.isBackground,
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

  Future<bool> _purchaseBackgroundWithCoins(ShopItem item) async {
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
      final messageId = row['message_id'] as String?;
      _setStoreState(() {
        if (remaining != null) {
          _coins = remaining;
        }
        if (!alreadyOwned) {
          _roomBackgroundOwned.add(item.id);
        }
      });
      if (!alreadyOwned && messageId != null && messageId.isNotEmpty) {
        unawaited(_notifyStorePurchase(roomId: roomId, messageId: messageId));
      }
    }
    return true;
  }

  Future<bool> _purchaseBackgroundWithDiamonds(ShopItem item) async {
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
      final messageId = row['message_id'] as String?;
      _setStoreState(() {
        if (remaining != null) {
          _diamonds = remaining;
        }
        if (!alreadyOwned) {
          _roomBackgroundOwned.add(item.id);
        }
      });
      if (!alreadyOwned && messageId != null && messageId.isNotEmpty) {
        unawaited(_notifyStorePurchase(roomId: roomId, messageId: messageId));
      }
    }
    return true;
  }

  Future<void> _notifyStorePurchase({
    required String roomId,
    required String messageId,
  }) async {
    try {
      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        return;
      }
      final response = await Supabase.instance.client.functions.invoke(
        'notify_friend',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'type': 'store_purchase',
          'room_id': roomId,
          'message_id': messageId,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        return;
      }
    } catch (_) {
      // Notification delivery should not block store purchase success.
    }
  }
}
