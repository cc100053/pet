import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/status_bar_style.dart';
import '../pet/pet_departure.dart';

const Color _diamondColor = Color(0xFF4C7DFF);

class StoreView extends StatefulWidget {
  const StoreView({
    super.key,
    this.roomId,
    this.departedPets = const [],
    this.onReturnPet,
  });

  final String? roomId;
  final List<DepartedPetInfo> departedPets;
  final Future<void> Function(DepartedPetInfo pet)? onReturnPet;

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final RevenueCatService _revenueCatService = RevenueCatService();
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  int _coins = 0;
  int _diamonds = 0;
  List<StoreItem> _items = [];
  final Map<String, int> _inventory = {};
  final Set<String> _roomBackgroundOwned = {};
  bool _iapConfigured = false;
  bool _iapLoading = false;
  String? _iapError;
  final Map<String, Package> _packagesByProductId = {};
  Set<String> _activeEntitlements = {};
  late List<DepartedPetInfo> _departedPets;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('store_open');
    _departedPets = List.of(widget.departedPets);
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.storeSignInPrompt;
      });
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins,diamonds')
          .eq('user_id', user.id)
          .maybeSingle();

      final itemsResponse = await Supabase.instance.client
          .from('items')
          .select('id,sku,type,name,price_coins,price_diamonds,metadata')
          .eq('is_active', true)
          .order('price_coins', ascending: true);

      final inventoryResponse = await Supabase.instance.client
          .from('inventories')
          .select('item_id,quantity')
          .eq('user_id', user.id);

      final roomId = widget.roomId;
      List<dynamic> roomBackgroundRows = const [];
      if (roomId != null) {
        roomBackgroundRows = await Supabase.instance.client
            .from('room_backgrounds')
            .select('item_id')
            .eq('room_id', roomId);
      }

      final items = (itemsResponse as List<dynamic>)
          .map((row) => StoreItem.fromJson(row as Map<String, dynamic>))
          .toList();

      final inventory = <String, int>{};
      for (final row in inventoryResponse as List<dynamic>) {
        final itemId = row['item_id'] as String?;
        final quantity = row['quantity'] as int?;
        if (itemId != null && quantity != null) {
          inventory[itemId] = quantity;
        }
      }

      final ownedBackgrounds = <String>{};
      for (final row in roomBackgroundRows) {
        if (row is Map<String, dynamic>) {
          final itemId = row['item_id'] as String?;
          if (itemId != null) {
            ownedBackgrounds.add(itemId);
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _coins = (profile?['coins'] as int?) ?? 0;
        _diamonds = (profile?['diamonds'] as int?) ?? 0;
        _items = items;
        _inventory
          ..clear()
          ..addAll(inventory);
        _roomBackgroundOwned
          ..clear()
          ..addAll(ownedBackgrounds);
      });

      await _loadIap(user.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.storeLoadFailed(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadIap(String appUserId) async {
    setState(() {
      _iapLoading = true;
      _iapError = null;
    });

    try {
      final configured = await _revenueCatService.configure(
        appUserId: appUserId,
      );
      if (!configured) {
        setState(() {
          _iapConfigured = false;
          _packagesByProductId.clear();
          _activeEntitlements = {};
        });
        return;
      }

      final offerings = await _revenueCatService.getOfferings();
      final customerInfo = await _revenueCatService.getCustomerInfo();
      final packagesByProductId = _extractPackagesByProductId(offerings);
      final activeEntitlements = <String>{};
      if (customerInfo != null) {
        activeEntitlements.addAll(
          customerInfo.entitlements.active.keys.toList(),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _iapConfigured = true;
        _packagesByProductId
          ..clear()
          ..addAll(packagesByProductId);
        _activeEntitlements = activeEntitlements;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _iapConfigured = false;
        _iapError = AppLocalizations.of(
          context,
        )!.storeIapUnavailable(error.toString());
        _packagesByProductId.clear();
        _activeEntitlements = {};
      });
    } finally {
      if (mounted) {
        setState(() {
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

    final current = offerings.current;
    if (current != null) {
      for (final package in current.availablePackages) {
        packagesByProductId[package.storeProduct.identifier] = package;
      }
    } else {
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          packagesByProductId[package.storeProduct.identifier] = package;
        }
      }
    }

    return packagesByProductId;
  }

  bool get _hasDepartedPets => _departedPets.isNotEmpty;

  Future<void> _handleLetterPurchase(StoreItem item) async {
    final l10n = AppLocalizations.of(context)!;
    if (_purchasing) {
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
    if (widget.onReturnPet != null) {
      await widget.onReturnPet!(selectedPet);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _departedPets.removeWhere((pet) => pet.petId == selectedPet.petId);
    });
  }

  Future<void> _showNoDepartedPetsDialog(AppLocalizations l10n) async {
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.petDepartureLetterUnavailableTitle,
        message: l10n.petDepartureLetterUnavailableMessage,
        actions: [
          AppDialogAction.primary(
            label: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<DepartedPetInfo?> _selectDepartedPet(AppLocalizations l10n) {
    return showAppDialog<DepartedPetInfo>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.petDepartureLetterSelectTitle,
        message: l10n.petDepartureLetterSelectMessage,
        body: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _departedPets.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pet = _departedPets[index];
              final subtitle = pet.roomName.trim().isEmpty
                  ? null
                  : pet.roomName;
              return ListTile(
                title: Text(pet.petName),
                subtitle: subtitle == null ? null : Text(subtitle),
                onTap: () => Navigator.of(context).pop(pet),
              );
            },
          ),
        ),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmLetterPurchase(
    AppLocalizations l10n,
    DepartedPetInfo pet,
  ) async {
    final result = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.petDepartureLetterConfirmTitle(pet.petName),
        message: l10n.petDepartureLetterConfirmMessage(pet.petName),
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppDialogAction.primary(
            label: l10n.petDepartureLetterConfirmAction,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _purchaseItem(StoreItem item) async {
    if (_purchasing) {
      return false;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }

    setState(() {
      _purchasing = true;
    });

    try {
      if (item.isBackground) {
        final success = await _purchaseBackgroundWithCoins(item);
        if (!success) {
          return false;
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
          setState(() {
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
            AppLocalizations.of(context)!.storePurchaseSuccess(item.name),
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
            AppLocalizations.of(context)!.storePurchaseFailed(error.toString()),
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
        setState(() {
          _purchasing = false;
        });
      }
    }
  }

  Future<bool> _purchaseDiamondItem(StoreItem item) async {
    if (_purchasing) {
      return false;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return false;
    }

    setState(() {
      _purchasing = true;
    });

    try {
      if (item.isBackground) {
        final success = await _purchaseBackgroundWithDiamonds(item);
        if (!success) {
          return false;
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
          setState(() {
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
            AppLocalizations.of(context)!.storePurchaseSuccess(item.name),
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
            AppLocalizations.of(context)!.storePurchaseFailed(error.toString()),
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
        setState(() {
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
      setState(() {
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
      setState(() {
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

  Future<void> _purchaseIapItem(StoreItem item) async {
    if (_purchasing) {
      return;
    }

    final productId = item.iapProductId;
    if (productId == null) {
      return;
    }

    final package = _packagesByProductId[productId];
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.storeProductUnavailable),
        ),
      );
      return;
    }

    setState(() {
      _purchasing = true;
    });

    try {
      final result = await _revenueCatService.purchasePackage(package);
      if (result != null) {
        if (item.iapType == 'subscription') {
          setState(() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.storePurchaseSuccess(item.name),
          ),
        ),
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
            AppLocalizations.of(context)!.storePurchaseFailed(error.toString()),
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
        setState(() {
          _purchasing = false;
        });
      }
    }
  }

  Future<void> _grantIapCoins(StoreItem item, PurchaseResult result) async {
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
        setState(() {
          _coins = newBalance;
        });
      }
    }
  }

  Future<void> _grantIapDiamonds(StoreItem item, PurchaseResult result) async {
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
        setState(() {
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
    setState(() {
      _iapLoading = true;
      _iapError = null;
    });

    try {
      final info = await _revenueCatService.restorePurchases();
      if (info != null && mounted) {
        setState(() {
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
      setState(() {
        _iapError = AppLocalizations.of(
          context,
        )!.storeRestoreFailed(error.toString());
      });
      AnalyticsService.instance.logEvent(
        'restore_purchases_result',
        parameters: {'result': 'failure'},
      );
    } finally {
      if (mounted) {
        setState(() {
          _iapLoading = false;
        });
      }
    }
  }

  List<StoreItem> get _iapItems => _items
      .where((item) => item.isIap)
      .where((item) => item.iapType == 'subscription' || item.isDiamondIap)
      .toList(growable: false);

  List<StoreItem> get _subscriptionItems => _iapItems
      .where((item) => item.iapType == 'subscription')
      .toList(growable: false);

  List<StoreItem> get _iapConsumableItems => _iapItems
      .where((item) => item.iapType != 'subscription')
      .toList(growable: false);

  List<StoreItem> get _iapDiamondPackItems {
    final items =
        _iapConsumableItems.where((item) => item.isDiamondIap).toList();
    items.sort((a, b) => (a.diamondAmount ?? 0).compareTo(b.diamondAmount ?? 0));
    return items;
  }

  List<StoreItem> get _storeItems {
    final items = _items.where((item) => !item.isIap).toList();
    items.sort((a, b) => _itemSortPrice(a).compareTo(_itemSortPrice(b)));
    return items;
  }

  int _itemSortPrice(StoreItem item) {
    final coin = item.priceCoins;
    final diamond = item.priceDiamonds;
    if (coin == null && diamond == null) {
      return 999999;
    }
    if (coin == null) {
      return diamond ?? 999999;
    }
    if (diamond == null) {
      return coin;
    }
    return coin < diamond ? coin : diamond;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.light,
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: AppStatusBarStyles.light,
          title: Text(l10n.storeTitle),
          actions: [
            if (_subscriptionItems.isNotEmpty)
              IconButton(
                onPressed: _iapLoading ? null : _restorePurchases,
                icon: const Icon(Icons.restore),
                tooltip: l10n.storeRestoreTooltip,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(label: Text(l10n.storeDiamondsLabel(_diamonds))),
                    const SizedBox(width: 8),
                    Chip(label: Text(l10n.storeCoinsLabel(_coins))),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadStore,
          child: _buildBody(context, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadStore,
            child: Text(l10n.commonTryAgain),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [Text(l10n.storeEmpty, textAlign: TextAlign.center)],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (_subscriptionItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionSubscription),
          if (_iapError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _iapError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (final item in _subscriptionItems) _buildIapCard(item, l10n),
          const SizedBox(height: 8),
        ],
        if (_iapDiamondPackItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionDiamondPacks),
          for (final item in _iapDiamondPackItems) _buildIapCard(item, l10n),
          const SizedBox(height: 8),
        ],
        if (_storeItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionItems),
          for (final item in _storeItems) _buildStoreItemCard(item, l10n),
        ],
      ],
    );
  }

  Widget _buildIapCard(StoreItem item, AppLocalizations l10n) {
    final productId = item.iapProductId;
    final package = productId == null ? null : _packagesByProductId[productId];
    final priceString =
        package?.storeProduct.priceString ??
        (item.priceJpy != null ? l10n.currencyJpy(item.priceJpy!) : null);
    final isSubscription = item.iapType == 'subscription';
    final isDiamondPack = item.isDiamondIap;
    final entitlementId = item.rcEntitlementId;
    final isSubscribed =
        isSubscription &&
        entitlementId != null &&
        _activeEntitlements.contains(entitlementId);
    final canBuy = _iapConfigured && !_purchasing && package != null;
    final packColor = isDiamondPack ? _diamondColor : Colors.amber;

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
                      l10n.storeSubscriptionActive, // Reusing label for "Premium" tag contextually? No, wait.
                      // Actually "Subscription" label
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isDiamondPack && item.diamondAmount != null)
                  Text(
                    l10n.storeDiamondsReward(item.diamondAmount!),
                    style: TextStyle(
                      color: packColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                else if (item.coinAmount != null)
                  Text(
                    l10n.storeCoinsReward(item.coinAmount!),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  priceString ?? l10n.storePriceUnavailable,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSubscribed || !canBuy
                ? null
                : () => _purchaseIapItem(item),
            child: Opacity(
              opacity: isSubscribed || !canBuy ? 0.6 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                child: Text(
                  isSubscription
                      ? (isSubscribed
                            ? l10n
                                  .commonOwned // "Active"
                            : l10n.storeSubscribe)
                      : l10n.commonBuy,
                  style: TextStyle(
                    color: isSubscribed ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isItemOwned(StoreItem item) {
    if (item.type != 'cosmetic') {
      return false;
    }
    if (item.isBackground) {
      return _roomBackgroundOwned.contains(item.id);
    }
    return (_inventory[item.id] ?? 0) > 0;
  }

  int _ownedQuantity(StoreItem item) => _inventory[item.id] ?? 0;

  Widget _buildStoreItemCard(StoreItem item, AppLocalizations l10n) {
    final ownedQty = _ownedQuantity(item);
    final isCosmetic = item.type == 'cosmetic';
    final isOwned = isCosmetic && _isItemOwned(item);
    final isLetter = item.isRecoveryLetter;
    final canAffordCoins =
        item.priceCoins != null && _coins >= item.priceCoins!;
    final canAffordDiamonds =
        item.priceDiamonds != null && _diamonds >= item.priceDiamonds!;
    final showQuantity = !isCosmetic && ownedQty > 0;
    final baseCanBuyCoins =
        !_purchasing && !isOwned && canAffordCoins && item.priceCoins != null;
    final baseCanBuyDiamonds =
        !_purchasing &&
        !isOwned &&
        canAffordDiamonds &&
        item.priceDiamonds != null;
    final canBuyCoins =
        isLetter ? baseCanBuyCoins && _hasDepartedPets : baseCanBuyCoins;
    final canBuyDiamonds =
        isLetter ? baseCanBuyDiamonds && _hasDepartedPets : baseCanBuyDiamonds;

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
            child: Text(
              item.emoji ?? (item.isBackground ? '🖼️' : '🎁'),
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  item.description ?? _displayTypeLabel(item, l10n),
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
                  label: l10n.storeBuyWithCandies(item.priceCoins!),
                  icon: Icons.monetization_on_rounded,
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
                  label: l10n.storeBuyWithDiamonds(item.priceDiamonds!),
                  icon: Icons.diamond_rounded,
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

class StoreItem {
  StoreItem({
    required this.id,
    required this.sku,
    required this.type,
    required this.name,
    required this.priceCoins,
    required this.priceDiamonds,
    required this.priceJpy,
    required this.description,
    required this.iapProductId,
    required this.iapType,
    required this.rcEntitlementId,
    required this.coinAmount,
    required this.diamondAmount,
    required this.iapCurrency,
    required this.category,
    required this.emoji,
    this.backgroundKey,
  });

  final String id;
  final String sku;
  final String type;
  final String name;
  final int? priceCoins;
  final int? priceDiamonds;
  final int? priceJpy;
  final String? description;
  final String? iapProductId;
  final String? iapType;
  final String? rcEntitlementId;
  final int? coinAmount;
  final int? diamondAmount;
  final String? iapCurrency;
  final String? category;
  final String? emoji;
  final String? backgroundKey;

  bool get isIap => iapProductId != null && iapProductId!.isNotEmpty;
  bool get isBackground => category == 'background';
  bool get isDiamondIap =>
      iapType != 'subscription' &&
      (iapCurrency == 'diamond' || diamondAmount != null);
  bool get isFurniture => category == 'furniture';
  bool get isRecoveryLetter {
    final skuLower = sku.toLowerCase();
    final categoryLower = (category ?? '').toLowerCase();
    return skuLower == 'letter' ||
        skuLower == 'recovery_letter' ||
        categoryLower == 'letter' ||
        categoryLower == 'recovery_letter';
  }

  String get displayType {
    if (iapType == 'subscription') {
      return 'Subscription';
    }
    switch (type) {
      case 'cosmetic':
        return 'Cosmetic';
      case 'consumable':
        return 'Consumable';
      case 'subscription':
        return 'Subscription';
      default:
        return type;
    }
  }

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
    final priceJpyRaw = metadata['price_jpy'];
    final description = metadata['description'] as String?;
    final iapProductId = metadata['iap_product_id'] as String?;
    final iapType = metadata['iap_type'] as String?;
    final rcEntitlementId = metadata['rc_entitlement_id'] as String?;
    final coinAmountRaw = metadata['coin_amount'];
    final diamondAmountRaw = metadata['diamond_amount'];
    final iapCurrency = metadata['iap_currency'] as String?;
    final category = metadata['category'] as String?;
    final emoji = metadata['emoji'] as String?;
    final backgroundKey = metadata['background_key'] as String?;

    int? priceJpy;
    if (priceJpyRaw is int) {
      priceJpy = priceJpyRaw;
    } else if (priceJpyRaw is double) {
      priceJpy = priceJpyRaw.round();
    } else if (priceJpyRaw is String) {
      priceJpy = int.tryParse(priceJpyRaw);
    }

    int? coinAmount;
    if (coinAmountRaw is int) {
      coinAmount = coinAmountRaw;
    } else if (coinAmountRaw is double) {
      coinAmount = coinAmountRaw.round();
    } else if (coinAmountRaw is String) {
      coinAmount = int.tryParse(coinAmountRaw);
    }

    int? diamondAmount;
    if (diamondAmountRaw is int) {
      diamondAmount = diamondAmountRaw;
    } else if (diamondAmountRaw is double) {
      diamondAmount = diamondAmountRaw.round();
    } else if (diamondAmountRaw is String) {
      diamondAmount = int.tryParse(diamondAmountRaw);
    }

    return StoreItem(
      id: json['id'] as String,
      sku: json['sku'] as String,
      type: json['type'] as String? ?? 'consumable',
      name: json['name'] as String? ?? 'Item',
      priceCoins: json['price_coins'] as int?,
      priceDiamonds: json['price_diamonds'] as int?,
      priceJpy: priceJpy,
      description: description,
      iapProductId: iapProductId,
      iapType: iapType,
      rcEntitlementId: rcEntitlementId,
      coinAmount: coinAmount,
      diamondAmount: diamondAmount,
      iapCurrency: iapCurrency,
      category: category,
      emoji: emoji,
      backgroundKey: backgroundKey,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _CurrencyBuyButton extends StatelessWidget {
  const _CurrencyBuyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade300,
          foregroundColor: enabled ? Colors.white : Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
