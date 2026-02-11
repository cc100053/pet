import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/env.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/status_bar_style.dart';
import '../home/room_backgrounds.dart';
import '../pet/pet_catalog.dart';
import '../pet/pet_departure.dart';
import 'widgets/store_legal_links_row.dart';

const Color _diamondColor = Color(0xFF4C7DFF);

enum _StoreCurrency { candy, diamonds }

class StoreView extends StatefulWidget {
  const StoreView({
    super.key,
    this.roomId,
    this.departedPets = const [],
    this.onReturnPet,
  });

  final String? roomId;
  final List<DepartedPetInfo> departedPets;
  final Future<bool> Function(DepartedPetInfo pet)? onReturnPet;

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
  final Map<String, StoreProduct> _storeProductsByProductId = {};
  Set<String> _activeEntitlements = {};
  final ScrollController _storeScrollController = ScrollController();
  final GlobalKey _furnitureSectionKey = GlobalKey();
  final GlobalKey _themeSectionKey = GlobalKey();
  late List<DepartedPetInfo> _departedPets;
  Uri? _privacyPolicyUri;
  late final Uri _termsOfUseUri;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logEvent('store_open');
    _departedPets = List.of(widget.departedPets);
    _initializeLegalUris();
    _loadStore();
  }

  @override
  void dispose() {
    _storeScrollController.dispose();
    super.dispose();
  }

  void _initializeLegalUris() {
    try {
      final policyUrl = Env.privacyPolicyUrl;
      _privacyPolicyUri = Uri.tryParse(policyUrl);
    } catch (_) {
      _privacyPolicyUri = null;
    }
    _termsOfUseUri = Uri.parse(Env.appleStandardEulaUrl);
  }

  void _handleLegalLinkOpenFailed() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.storeLegalOpenFailed),
      ),
    );
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
        )!.storeLoadFailed(userFacingError(context, error));
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

      setState(() {
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
      setState(() {
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
    setState(() {
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
    setState(() {
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
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pet = _departedPets[index];
              final petDefinition = PetCatalog.byId(pet.petType);
              return Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: petDefinition.accent.withValues(alpha: 0.28),
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.38),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(pet),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: petDefinition.accent.withValues(
                                alpha: 0.14,
                              ),
                              alignment: Alignment.center,
                              child: Image.asset(
                                petDefinition.stayAsset,
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pet.petName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
    if (!_ensureCurrencyPurchasable(item, _StoreCurrency.candy)) {
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
    if (!_ensureCurrencyPurchasable(item, _StoreCurrency.diamonds)) {
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

    setState(() {
      _purchasing = true;
    });

    try {
      final result = package != null
          ? await _revenueCatService.purchasePackage(package)
          : await _revenueCatService.purchaseStoreProduct(storeProduct!);
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
            AppLocalizations.of(context)!.storePurchaseSuccess(
              item.localizedName(AppLocalizations.of(context)!),
            ),
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
        )!.storeRestoreFailed(userFacingError(context, error));
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
    final items = _iapConsumableItems
        .where((item) => item.isDiamondIap)
        .toList();
    items.sort(
      (a, b) => (a.diamondAmount ?? 0).compareTo(b.diamondAmount ?? 0),
    );
    return items;
  }

  List<StoreItem> get _storeItems {
    final items = _items.where((item) => !item.isIap).toList();
    items.sort((a, b) => _itemSortPrice(a).compareTo(_itemSortPrice(b)));
    return items;
  }

  List<StoreItem> get _themeItems =>
      _storeItems.where((item) => item.isBackground).toList(growable: false);

  List<StoreItem> get _furnitureItems =>
      _storeItems.where((item) => item.isFurniture).toList(growable: false);

  List<StoreItem> get _premiumUtilityItems => _storeItems
      .where((item) => !item.isBackground && !item.isFurniture)
      .toList(growable: false);

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
                    _CurrencyBalanceChip(
                      amount: _diamonds,
                      icon: Icon(
                        Icons.diamond_rounded,
                        size: 16,
                        color: _diamondColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CurrencyBalanceChip(
                      amount: _coins,
                      icon: SvgPicture.asset(
                        'assets/icon/icon-park--candy.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          Colors.amber.shade700,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
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
      controller: _storeScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (_furnitureItems.isNotEmpty || _themeItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _furnitureItems.isEmpty
                        ? null
                        : () => _jumpToSection(
                            _furnitureSectionKey,
                            fallbackFraction: 0.55,
                          ),
                    icon: const Icon(Icons.chair_rounded, size: 18),
                    label: Text(l10n.storeTabFurniture),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _themeItems.isEmpty
                        ? null
                        : () => _jumpToSection(
                            _themeSectionKey,
                            fallbackFraction: 1,
                          ),
                    icon: const Icon(Icons.palette_rounded, size: 18),
                    label: Text(l10n.storeTabThemes),
                  ),
                ),
              ],
            ),
          ),
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
        ],
        if (_iapDiamondPackItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionDiamondPacks),
          for (final item in _iapDiamondPackItems) _buildIapCard(item, l10n),
        ],
        if (_premiumUtilityItems.isNotEmpty) ...[
          _SectionHeader(title: l10n.storeSectionItems),
          for (final item in _premiumUtilityItems)
            _buildStoreItemCard(item, l10n),
        ],
        if (_furnitureItems.isNotEmpty) ...[
          KeyedSubtree(
            key: _furnitureSectionKey,
            child: _SectionHeader(title: l10n.storeTabFurniture),
          ),
          for (final item in _furnitureItems) _buildStoreItemCard(item, l10n),
        ],
        if (_themeItems.isNotEmpty) ...[
          KeyedSubtree(
            key: _themeSectionKey,
            child: _SectionHeader(title: l10n.storeTabThemes),
          ),
          for (final item in _themeItems) _buildStoreItemCard(item, l10n),
        ],
        if (_subscriptionItems.isNotEmpty && _privacyPolicyUri != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: StoreLegalLinksRow(
              privacyPolicyUri: _privacyPolicyUri!,
              termsOfUseUri: _termsOfUseUri,
              privacyPolicyLabel: l10n.storePrivacyPolicy,
              termsOfUseLabel: l10n.storeTermsOfUse,
              separatorLabel: l10n.storeLegalSeparator,
              onLaunchFailed: _handleLegalLinkOpenFailed,
            ),
          ),
      ],
    );
  }

  Future<void> _jumpToSection(
    GlobalKey key, {
    required double fallbackFraction,
  }) async {
    if (!_storeScrollController.hasClients) {
      return;
    }
    final position = _storeScrollController.position;
    final targetContext = key.currentContext;
    if (targetContext == null) {
      final fallbackOffset = (position.maxScrollExtent * fallbackFraction)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      await _storeScrollController.animateTo(
        fallbackOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    final targetRenderObject = targetContext.findRenderObject();
    if (targetRenderObject == null) {
      final fallbackOffset = (position.maxScrollExtent * fallbackFraction)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      await _storeScrollController.animateTo(
        fallbackOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final viewport = RenderAbstractViewport.of(targetRenderObject);
    final revealOffset = viewport
        .getOffsetToReveal(targetRenderObject, 0.05)
        .offset;
    final targetOffset = revealOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await _storeScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

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
                      Text(
                        l10n.storeSubscriptionRenewalNote,
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
    required this.catalogCurrencyCode,
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
  final String? catalogCurrencyCode;
  final String? category;
  final String? emoji;
  final String? backgroundKey;

  bool get isIap => iapProductId != null && iapProductId!.isNotEmpty;
  bool get isBackground => category == 'background';
  bool get isDiamondIap =>
      iapType != 'subscription' &&
      (iapCurrency == 'diamond' || diamondAmount != null);
  bool get isFurniture => category == 'furniture';
  bool get isUtility => category == 'utility';
  bool get isDefaultBackground => sku == 'background_default';
  bool get isRecoveryLetter {
    final skuLower = sku.toLowerCase();
    final categoryLower = (category ?? '').toLowerCase();
    return skuLower == 'letter' ||
        skuLower == 'return_letter' ||
        skuLower == 'recovery_letter' ||
        categoryLower == 'utility' ||
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

  String localizedIapPrice(
    Package? package,
    StoreProduct? storeProduct,
    AppLocalizations l10n,
  ) {
    final appStorePrice = package?.storeProduct.priceString;
    final appStoreCurrency = package?.storeProduct.currencyCode;
    if (appStorePrice != null && appStorePrice.isNotEmpty) {
      if (_shouldUseCatalogJpyFallback(appStoreCurrency)) {
        return l10n.currencyJpy(priceJpy!);
      }
      return appStorePrice;
    }
    final directStorePrice = storeProduct?.priceString;
    final directStoreCurrency = storeProduct?.currencyCode;
    if (directStorePrice != null && directStorePrice.isNotEmpty) {
      if (_shouldUseCatalogJpyFallback(directStoreCurrency)) {
        return l10n.currencyJpy(priceJpy!);
      }
      return directStorePrice;
    }
    if (priceJpy != null && _isCatalogJpy) {
      return l10n.currencyJpy(priceJpy!);
    }
    return l10n.storePriceUnavailable;
  }

  bool _shouldUseCatalogJpyFallback(String? storeCurrencyCode) {
    if (!_isCatalogJpy || priceJpy == null) {
      return false;
    }
    final code = storeCurrencyCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) {
      return false;
    }
    return code != 'JPY';
  }

  bool get _isCatalogJpy =>
      (catalogCurrencyCode ?? '').trim().toUpperCase() == 'JPY';

  String localizedName(AppLocalizations l10n) {
    switch (sku) {
      case 'subscription_premium_monthly':
        return l10n.storeItemNameProMonthly;
      case 'iap_diamond_pack_small':
        return l10n.storeItemNameDiamondPack300;
      case 'return_letter':
        return l10n.storeItemNameReturnLetter;
      case 'background_default':
        return l10n.storeItemNameBackgroundDefault;
      case 'background_test1':
        return l10n.storeItemNameBackgroundMoonlight;
      case 'furniture_emoji_sofa':
        return l10n.storeItemNameFurnitureSofa;
      case 'furniture_emoji_plant':
        return l10n.storeItemNameFurniturePlant;
      case 'furniture_emoji_frame':
        return l10n.storeItemNameFurnitureFrame;
      case 'furniture_emoji_teddy':
        return l10n.storeItemNameFurnitureTeddy;
      case 'furniture_emoji_brick':
        return l10n.storeItemNameFurnitureBricks;
      case 'furniture_emoji_tv':
        return l10n.storeItemNameFurnitureTv;
      case 'furniture_emoji_bath':
        return l10n.storeItemNameFurnitureBath;
      case 'furniture_emoji_ribbon':
        return l10n.storeItemNameFurnitureRibbon;
      default:
        return name;
    }
  }

  String? localizedDescription(AppLocalizations l10n) {
    switch (sku) {
      case 'subscription_premium_monthly':
        return l10n.storeItemDescProMonthly;
      case 'iap_diamond_pack_small':
        return null;
      case 'return_letter':
        return l10n.storeItemDescReturnLetter;
      case 'background_default':
        return l10n.storeItemDescBackgroundDefault;
      case 'background_test1':
        return l10n.storeItemDescBackgroundMoonlight;
      case 'furniture_emoji_sofa':
        return l10n.storeItemDescFurnitureSofa;
      case 'furniture_emoji_plant':
        return l10n.storeItemDescFurniturePlant;
      case 'furniture_emoji_frame':
        return l10n.storeItemDescFurnitureFrame;
      case 'furniture_emoji_teddy':
        return l10n.storeItemDescFurnitureTeddy;
      case 'furniture_emoji_brick':
        return l10n.storeItemDescFurnitureBricks;
      case 'furniture_emoji_tv':
        return l10n.storeItemDescFurnitureTv;
      case 'furniture_emoji_bath':
        return l10n.storeItemDescFurnitureBath;
      case 'furniture_emoji_ribbon':
        return l10n.storeItemDescFurnitureRibbon;
      default:
        return description;
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
    final catalogCurrencyCode = metadata['currency'] as String?;
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
      catalogCurrencyCode: catalogCurrencyCode,
      category: category,
      emoji: emoji,
      backgroundKey: backgroundKey,
    );
  }
}

typedef ShopItem = StoreItem;

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
    required this.amount,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final int amount;
  final Widget icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: icon,
        label: Text(
          '$amount',
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

class _CurrencyBalanceChip extends StatelessWidget {
  const _CurrencyBalanceChip({required this.amount, required this.icon});

  final int amount;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: const EdgeInsets.only(left: 2, right: 2),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 4), Text('$amount')],
      ),
    );
  }
}

class _CurrencyDeltaLabel extends StatelessWidget {
  const _CurrencyDeltaLabel({
    required this.amount,
    required this.icon,
    required this.color,
  });

  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '+$amount',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
