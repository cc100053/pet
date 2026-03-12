import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ads/admob_banner_slot.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/auth/session_utils.dart';
import '../../services/env.dart';
import '../../services/ads/admob_ids.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/status_bar_style.dart';
import '../home/room_backgrounds.dart';
import '../pet/pet_departure.dart';
import 'models/store_item.dart';
import 'widgets/store_legal_links_row.dart';

part 'services/store_iap_service.dart';
part 'services/store_purchase_handler.dart';
part 'widgets/store_departed_pet_selector.dart';
part 'widgets/store_item_cards.dart';

const Color _diamondColor = Color(0xFF4C7DFF);

enum _StoreCurrency { candy, diamonds }

class StoreView extends StatefulWidget {
  const StoreView({
    super.key,
    this.roomId,
    this.isProUser = false,
    this.departedPets = const [],
    this.onReturnPet,
  });

  final String? roomId;
  final bool isProUser;
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

  bool get _hasProAdFreeAccess =>
      widget.isProUser || _activeEntitlements.isNotEmpty;

  void _setStoreState(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

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
    try {
      _termsOfUseUri = Uri.parse(Env.termsOfUseUrl);
    } catch (_) {
      _termsOfUseUri = Uri.parse(Env.appleStandardEulaUrl);
    }
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
      List<dynamic> roomFurnitureInventoryRows = const [];
      if (roomId != null) {
        roomFurnitureInventoryRows = await Supabase.instance.client
            .from('room_item_inventories')
            .select('item_id,quantity')
            .eq('room_id', roomId)
            .eq('user_id', user.id);
      }

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

      final roomFurnitureInventory = <String, int>{};
      for (final row in roomFurnitureInventoryRows) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final itemId = row['item_id'] as String?;
        final quantity = row['quantity'] as int?;
        if (itemId != null && quantity != null) {
          roomFurnitureInventory[itemId] = quantity;
        }
      }

      for (final item in items) {
        if (!item.isFurniture) {
          continue;
        }
        inventory[item.id] = roomFurnitureInventory[item.id] ?? 0;
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
        bottomNavigationBar: AdMobIds.isSupported && !_hasProAdFreeAccess
            ? const AdMobBannerSlot()
            : null,
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
