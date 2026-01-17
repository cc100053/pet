import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/iap/revenuecat_service.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final RevenueCatService _revenueCatService = RevenueCatService();
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  int _coins = 0;
  List<StoreItem> _items = [];
  final Map<String, int> _inventory = {};
  bool _iapConfigured = false;
  bool _iapLoading = false;
  String? _iapError;
  final Map<String, Package> _packagesByProductId = {};
  Set<String> _activeEntitlements = {};

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('store_open');
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
        _error = 'Please sign in to access the store.';
      });
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins')
          .eq('user_id', user.id)
          .maybeSingle();

      final itemsResponse = await Supabase.instance.client
          .from('items')
          .select('id,sku,type,name,price_coins,metadata')
          .eq('is_active', true)
          .order('price_coins', ascending: true);

      final inventoryResponse = await Supabase.instance.client
          .from('inventories')
          .select('item_id,quantity')
          .eq('user_id', user.id);

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

      if (!mounted) {
        return;
      }

      setState(() {
        _coins = (profile?['coins'] as int?) ?? 0;
        _items = items;
        _inventory
          ..clear()
          ..addAll(inventory);
      });

      await _loadIap(user.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load store: $error';
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
      final configured =
          await _revenueCatService.configure(appUserId: appUserId);
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
        activeEntitlements
            .addAll(customerInfo.entitlements.active.keys.toList());
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
        _iapError = 'IAP unavailable: $error';
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

  Future<void> _purchaseItem(StoreItem item) async {
    if (_purchasing) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _purchasing = true;
    });

    try {
      final response = await Supabase.instance.client.rpc(
        'purchase_item_with_coins',
        params: {
          'p_item_id': item.id,
          'p_quantity': 1,
        },
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

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${item.name}.')),
      );
      AnalyticsService.instance.logEvent('purchase_coins', parameters: {
        'result': 'success',
        'sku': item.sku,
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $error')),
      );
      AnalyticsService.instance.logEvent('purchase_coins', parameters: {
        'result': 'failure',
        'sku': item.sku,
      });
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
        });
      }
    }
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
        const SnackBar(content: Text('Product unavailable.')),
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
            _activeEntitlements =
                result.customerInfo.entitlements.active.keys.toSet();
          });
        } else {
          await _grantIapCoins(item, result);
        }
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchased ${item.name}.')),
      );
      AnalyticsService.instance.logEvent('purchase_iap', parameters: {
        'result': 'success',
        'sku': item.sku,
        'type': item.iapType ?? 'unknown',
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $error')),
      );
      AnalyticsService.instance.logEvent('purchase_iap', parameters: {
        'result': 'failure',
        'sku': item.sku,
        'type': item.iapType ?? 'unknown',
      });
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
          _activeEntitlements =
              info.entitlements.active.keys.toSet();
        });
        AnalyticsService.instance.logEvent('restore_purchases_result', parameters: {
          'result': 'success',
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _iapError = 'Restore failed: $error';
      });
      AnalyticsService.instance.logEvent('restore_purchases_result', parameters: {
        'result': 'failure',
      });
    } finally {
      if (mounted) {
        setState(() {
          _iapLoading = false;
        });
      }
    }
  }

  List<StoreItem> get _iapItems =>
      _items.where((item) => item.isIap).toList(growable: false);

  List<StoreItem> get _subscriptionItems => _iapItems
      .where((item) => item.iapType == 'subscription')
      .toList(growable: false);

  List<StoreItem> get _iapConsumableItems => _iapItems
      .where((item) => item.iapType != 'subscription')
      .toList(growable: false);

  List<StoreItem> get _coinItems =>
      _items.where((item) => !item.isIap).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          if (_subscriptionItems.isNotEmpty)
            IconButton(
              onPressed: _iapLoading ? null : _restorePurchases,
              icon: const Icon(Icons.restore),
              tooltip: 'Restore purchases',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(
                label: Text('Coins: $_coins'),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStore,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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
            child: const Text('Try again'),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Store is empty for now.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (_subscriptionItems.isNotEmpty) ...[
          const _SectionHeader(title: 'Subscription'),
          if (_iapError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _iapError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (final item in _subscriptionItems)
            _buildIapCard(item),
          const SizedBox(height: 8),
        ],
        if (_iapConsumableItems.isNotEmpty) ...[
          const _SectionHeader(title: 'Coin Packs'),
          for (final item in _iapConsumableItems)
            _buildIapCard(item),
          const SizedBox(height: 8),
        ],
        if (_coinItems.isNotEmpty) ...[
          const _SectionHeader(title: 'Coin Store'),
          for (final item in _coinItems)
            _buildCoinCard(item),
        ],
      ],
    );
  }

  Widget _buildIapCard(StoreItem item) {
    final productId = item.iapProductId;
    final package =
        productId == null ? null : _packagesByProductId[productId];
    final priceString = package?.storeProduct.priceString ??
        (item.priceJpy != null ? 'JPY ${item.priceJpy}' : null);
    final isSubscription = item.iapType == 'subscription';
    final entitlementId = item.rcEntitlementId;
    final isSubscribed =
        isSubscription &&
        entitlementId != null &&
        _activeEntitlements.contains(entitlementId);
    final canBuy = _iapConfigured && !_purchasing && package != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.displayType,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: isSubscribed || !canBuy
                      ? null
                      : () => _purchaseIapItem(item),
                  child: Text(isSubscription
                      ? (isSubscribed ? 'Active' : 'Subscribe')
                      : 'Buy'),
                ),
              ],
            ),
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(item.description!),
            ],
            if (!isSubscription && item.coinAmount != null) ...[
              const SizedBox(height: 6),
              Text('Coins +${item.coinAmount}'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(priceString ?? 'Price unavailable'),
                if (item.priceJpy != null) ...[
                  const SizedBox(width: 12),
                  Text('JPY ${item.priceJpy}'),
                ],
              ],
            ),
            if (!_iapConfigured) ...[
              const SizedBox(height: 6),
              Text(
                'IAP not configured.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else if (package == null) ...[
              const SizedBox(height: 6),
              Text(
                'Product not found in RevenueCat.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoinCard(StoreItem item) {
    final ownedQty = _inventory[item.id] ?? 0;
    final isCosmetic = item.type == 'cosmetic';
    final isOwned = isCosmetic && ownedQty > 0;
    final canAfford = item.priceCoins != null && _coins >= item.priceCoins!;
    final showQuantity = !isCosmetic && ownedQty > 0;
    final canBuy =
        !_purchasing && !isOwned && canAfford && item.priceCoins != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.displayType,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: canBuy ? () => _purchaseItem(item) : null,
                  child: Text(isOwned ? 'Owned' : 'Buy'),
                ),
              ],
            ),
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(item.description!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Coins: ${item.priceCoins ?? '-'}'),
                if (item.priceJpy != null) ...[
                  const SizedBox(width: 12),
                  Text('JPY ${item.priceJpy}'),
                ],
              ],
            ),
            if (showQuantity) ...[
              const SizedBox(height: 6),
              Text('Owned: $ownedQty'),
            ] else if (isOwned) ...[
              const SizedBox(height: 6),
              const Text('Owned'),
            ],
            if (!canAfford && !isOwned && item.priceCoins != null) ...[
              const SizedBox(height: 6),
              Text(
                'Not enough coins.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StoreItem {
  StoreItem({
    required this.id,
    required this.sku,
    required this.type,
    required this.name,
    required this.priceCoins,
    required this.priceJpy,
    required this.description,
    required this.iapProductId,
    required this.iapType,
    required this.rcEntitlementId,
    required this.coinAmount,
  });

  final String id;
  final String sku;
  final String type;
  final String name;
  final int? priceCoins;
  final int? priceJpy;
  final String? description;
  final String? iapProductId;
  final String? iapType;
  final String? rcEntitlementId;
  final int? coinAmount;

  bool get isIap => iapProductId != null && iapProductId!.isNotEmpty;

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

    return StoreItem(
      id: json['id'] as String,
      sku: json['sku'] as String,
      type: json['type'] as String? ?? 'consumable',
      name: json['name'] as String? ?? 'Item',
      priceCoins: json['price_coins'] as int?,
      priceJpy: priceJpy,
      description: description,
      iapProductId: iapProductId,
      iapType: iapType,
      rcEntitlementId: rcEntitlementId,
      coinAmount: coinAmount,
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
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
