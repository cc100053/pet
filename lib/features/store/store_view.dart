import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../shared/theme/app_theme.dart';

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
        _error = AppLocalizations.of(context)!.storeSignInPrompt;
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
        'purchase_coins',
        parameters: {'result': 'success', 'sku': item.sku},
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
        'purchase_coins',
        parameters: {'result': 'failure', 'sku': item.sku},
      );
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
          await _grantIapCoins(item, result);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
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
              child: Chip(label: Text(l10n.storeCoinsLabel(_coins))),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStore,
        child: _buildBody(context, l10n),
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
        if (_iapConsumableItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionCoinPacks),
          for (final item in _iapConsumableItems) _buildIapCard(item, l10n),
          const SizedBox(height: 8),
        ],
        if (_coinItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionCoinStore),
          for (final item in _coinItems) _buildCoinCard(item, l10n),
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
    final entitlementId = item.rcEntitlementId;
    final isSubscribed =
        isSubscription &&
        entitlementId != null &&
        _activeEntitlements.contains(entitlementId);
    final canBuy = _iapConfigured && !_purchasing && package != null;

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
                  : Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              isSubscription ? Icons.stars_rounded : Icons.diamond_rounded,
              color: isSubscription ? AppTheme.secondaryColor : Colors.amber,
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

  Widget _buildCoinCard(StoreItem item, AppLocalizations l10n) {
    final ownedQty = _inventory[item.id] ?? 0;
    final isCosmetic = item.type == 'cosmetic';
    final isOwned = isCosmetic && ownedQty > 0;
    final canAfford = item.priceCoins != null && _coins >= item.priceCoins!;
    final showQuantity = !isCosmetic && ownedQty > 0;
    final canBuy =
        !_purchasing && !isOwned && canAfford && item.priceCoins != null;

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
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              item.emoji ?? '🎁',
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
                if (item.priceCoins != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.priceCoins}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canAfford ? Colors.amber[800] : Colors.red,
                        ),
                      ),
                    ],
                  ),
                if (showQuantity) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.storeOwnedCount(ownedQty),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: canBuy ? () => _purchaseItem(item) : null,
            child: Opacity(
              opacity: canBuy || isOwned ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isOwned ? null : AppTheme.primaryGradient,
                  color: isOwned ? Colors.grey[200] : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isOwned || !canBuy
                      ? []
                      : [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Text(
                  isOwned ? l10n.commonOwned : l10n.commonBuy,
                  style: TextStyle(
                    color: isOwned ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
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
    required this.priceJpy,
    required this.description,
    required this.iapProductId,
    required this.iapType,
    required this.rcEntitlementId,
    required this.coinAmount,
    required this.category,
    required this.emoji,
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
  final String? category;
  final String? emoji;

  bool get isIap => iapProductId != null && iapProductId!.isNotEmpty;
  bool get isFurniture => category == 'furniture';

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
    final category = metadata['category'] as String?;
    final emoji = metadata['emoji'] as String?;

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
      category: category,
      emoji: emoji,
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
