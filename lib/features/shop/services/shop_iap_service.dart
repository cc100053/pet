part of '../shop_view.dart';

extension _ShopIapService on _ShopViewState {
  Future<void> _loadIap(String appUserId) async {
    _setStoreState(() {
      _iapLoading = true;
      _iapError = null;
    });

    try {
      final configured = await _revenueCatService.configure(
        appUserId: appUserId,
      );
      if (!configured) {
        _setStoreState(() {
          _iapConfigured = false;
          _packagesByProductId.clear();
          _storeProductsByProductId.clear();
          _activeEntitlements = {};
        });
        return;
      }

      final offerings = await _revenueCatService.getOfferings();
      final customerInfo = await _revenueCatService.getCustomerInfo();
      final packagesByProductId = _extractPackagesByProductId(offerings);
      final iapItems = _iapItems;
      final subscriptionProductIds = iapItems
          .where((item) => item.iapType == 'subscription')
          .map((item) => item.iapProductId)
          .whereType<String>()
          .toSet()
          .toList(growable: false);
      final nonSubscriptionProductIds = iapItems
          .where((item) => item.iapType != 'subscription')
          .map((item) => item.iapProductId)
          .whereType<String>()
          .toSet()
          .toList(growable: false);
      final subscriptionProducts = await _revenueCatService.getProducts(
        subscriptionProductIds,
        productCategory: ProductCategory.subscription,
      );
      final nonSubscriptionProducts = await _revenueCatService.getProducts(
        nonSubscriptionProductIds,
        productCategory: ProductCategory.nonSubscription,
      );
      final storeProductsByProductId = <String, StoreProduct>{};
      for (final product in subscriptionProducts) {
        storeProductsByProductId[product.identifier] = product;
      }
      for (final product in nonSubscriptionProducts) {
        storeProductsByProductId[product.identifier] = product;
      }
      final activeEntitlements = <String>{};
      if (customerInfo != null) {
        activeEntitlements.addAll(
          customerInfo.entitlements.active.keys.toList(),
        );
      }

      if (!mounted) {
        return;
      }

      _setStoreState(() {
        _iapConfigured = true;
        _packagesByProductId
          ..clear()
          ..addAll(packagesByProductId);
        _storeProductsByProductId
          ..clear()
          ..addAll(storeProductsByProductId);
        _activeEntitlements = activeEntitlements;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setStoreState(() {
        _iapConfigured = false;
        _iapError = AppLocalizations.of(
          context,
        )!.storeIapUnavailable(userFacingError(context, error));
        _packagesByProductId.clear();
        _storeProductsByProductId.clear();
        _activeEntitlements = {};
      });
    } finally {
      if (mounted) {
        _setStoreState(() {
          _iapLoading = false;
        });
      }
    }
  }

  Map<String, Package> _extractPackagesByProductId(Offerings? offerings) {
    final packagesByProductId = <String, Package>{};
    if (offerings == null) {
      return packagesByProductId;
    }

    for (final offering in offerings.all.values) {
      for (final package in offering.availablePackages) {
        packagesByProductId[package.storeProduct.identifier] = package;
      }
    }

    final current = offerings.current;
    if (current != null) {
      for (final package in current.availablePackages) {
        packagesByProductId[package.storeProduct.identifier] = package;
      }
    }

    return packagesByProductId;
  }

  Package? _findPackageByProductId(String productId) {
    final direct = _packagesByProductId[productId];
    if (direct != null) {
      return direct;
    }
    for (final entry in _packagesByProductId.entries) {
      if (entry.key.toLowerCase() == productId.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  StoreProduct? _findStoreProductByProductId(String productId) {
    final direct = _storeProductsByProductId[productId];
    if (direct != null) {
      return direct;
    }
    for (final entry in _storeProductsByProductId.entries) {
      if (entry.key.toLowerCase() == productId.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  Future<void> _purchaseIapItem(ShopItem item) async {
    if (_purchasing) {
      return;
    }

    final productId = item.iapProductId;
    if (productId == null) {
      return;
    }

    final package = _findPackageByProductId(productId);
    final storeProduct = _findStoreProductByProductId(productId);
    if (package == null && storeProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.storeProductUnavailable),
        ),
      );
      return;
    }

    _setStoreState(() {
      _purchasing = true;
    });

    try {
      final result = package != null
          ? await _revenueCatService.purchasePackage(package)
          : await _revenueCatService.purchaseStoreProduct(storeProduct!);
      if (result != null) {
        if (item.iapType == 'subscription') {
          _setStoreState(() {
            _activeEntitlements = result.customerInfo.entitlements.active.keys
                .toSet();
          });
        } else {
          if (item.isDiamondIap) {
            await _grantIapDiamonds(item, result);
          } else {
            await _grantIapCoins(item, result);
          }
        }
      }
      if (!mounted) {
        return;
      }
      _showPurchaseSuccessNotice(
        item: item,
        showReturnToRoomAction: item.isFurniture || item.isBackground,
      );
      AnalyticsService.instance.logEvent(
        'purchase_iap',
        parameters: {
          'result': 'success',
          'sku': item.sku,
          'type': item.iapType ?? 'unknown',
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
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
        'purchase_iap',
        parameters: {
          'result': 'failure',
          'sku': item.sku,
          'type': item.iapType ?? 'unknown',
        },
      );
    } finally {
      if (mounted) {
        _setStoreState(() {
          _purchasing = false;
        });
      }
    }
  }

  Future<void> _grantIapCoins(ShopItem item, PurchaseResult result) async {
    final coinAmount = item.coinAmount;
    if (coinAmount == null || coinAmount <= 0) {
      throw StateError('Missing coin amount for IAP item.');
    }

    final transaction = result.storeTransaction;
    final transactionId = transaction.transactionIdentifier;
    final productId = transaction.productIdentifier;
    if (transactionId.isEmpty) {
      throw StateError('Missing transaction id.');
    }

    final response = await Supabase.instance.client.rpc(
      'grant_iap_coins',
      params: {
        'p_product_id': productId,
        'p_amount': coinAmount,
        'p_transaction_id': transactionId,
      },
    );

    Map<String, dynamic>? row;
    if (response is List && response.isNotEmpty) {
      row = response.first as Map<String, dynamic>;
    } else if (response is Map) {
      row = response.cast<String, dynamic>();
    }

    if (row != null) {
      final newBalance = row['new_balance'] as int?;
      if (newBalance != null) {
        _setStoreState(() {
          _coins = newBalance;
        });
      }
    }
  }

  Future<void> _grantIapDiamonds(ShopItem item, PurchaseResult result) async {
    final diamondAmount = item.diamondAmount;
    if (diamondAmount == null || diamondAmount <= 0) {
      throw StateError('Missing diamond amount for IAP item.');
    }

    final transaction = result.storeTransaction;
    final transactionId = transaction.transactionIdentifier;
    final productId = transaction.productIdentifier;
    if (transactionId.isEmpty) {
      throw StateError('Missing transaction id.');
    }

    final response = await Supabase.instance.client.rpc(
      'grant_iap_diamonds',
      params: {
        'p_product_id': productId,
        'p_amount': diamondAmount,
        'p_transaction_id': transactionId,
      },
    );

    Map<String, dynamic>? row;
    if (response is List && response.isNotEmpty) {
      row = response.first as Map<String, dynamic>;
    } else if (response is Map) {
      row = response.cast<String, dynamic>();
    }

    if (row != null) {
      final newBalance = row['new_balance'] as int?;
      if (newBalance != null) {
        _setStoreState(() {
          _diamonds = newBalance;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_iapLoading) {
      return;
    }

    AnalyticsService.instance.logEvent('restore_purchases');
    _setStoreState(() {
      _iapLoading = true;
      _iapError = null;
    });

    try {
      final info = await _revenueCatService.restorePurchases();
      if (info != null && mounted) {
        _setStoreState(() {
          _activeEntitlements = info.entitlements.active.keys.toSet();
        });
        AnalyticsService.instance.logEvent(
          'restore_purchases_result',
          parameters: {'result': 'success'},
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setStoreState(() {
        _iapError = AppLocalizations.of(
          context,
        )!.storeRestoreFailed(userFacingError(context, error));
      });
      AnalyticsService.instance.logEvent(
        'restore_purchases_result',
        parameters: {'result': 'failure'},
      );
    } finally {
      if (mounted) {
        _setStoreState(() {
          _iapLoading = false;
        });
      }
    }
  }
}
