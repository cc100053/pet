import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ads/admob_banner_slot.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/app_sfx.dart';
import '../../services/env.dart';
import '../../services/ads/admob_ids.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../services/settings/app_settings_repository.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/status_bar_style.dart';
import '../home/room_backgrounds.dart';
import '../pet/pet_departure.dart';
import '../pet/pet_selection_page.dart';
import 'models/shop_item.dart';
import 'services/economy_purchase_adapter.dart';
import 'services/shop_economy_state.dart';
import 'services/shop_purchase_notifier.dart';
import 'widgets/shop_legal_links_row.dart';
import 'widgets/shop_item_visual.dart';

part 'services/shop_iap_service.dart';
part 'services/shop_purchase_handler.dart';
part 'widgets/shop_departed_pet_selector.dart';
part 'widgets/shop_item_cards.dart';
part 'widgets/shop_view_decorations.dart';

const List<Color> _storeBackgroundGradient = [
  Color(0xFFE0F7FF), // Light Blue
  Color(0xFFF3E5F5), // Soft Lavender
  Color(0xFFFFF3E0), // Soft Peach/Pink
];

enum ShopCurrency { candy, diamonds }

enum ShopNoticeKind { shortage, success }

class ShopRouteResult {
  const ShopRouteResult({required this.roomId, this.showRoomDecorHint = false});

  final String roomId;
  final bool showRoomDecorHint;

  factory ShopRouteResult.returnedRoom(String roomId) {
    return ShopRouteResult(roomId: roomId);
  }

  factory ShopRouteResult.roomDecor(String roomId) {
    return ShopRouteResult(roomId: roomId, showRoomDecorHint: true);
  }
}

class ShopNoticeAction {
  const ShopNoticeAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

class ShopNoticeData {
  ShopNoticeData.shortage({
    required this.key,
    required this.title,
    required this.currency,
    required this.currentAmount,
    required this.requiredAmount,
    this.onDismiss,
  }) : kind = ShopNoticeKind.shortage,
       message = null,
       primaryAction = null,
       visual = null;

  ShopNoticeData.success({
    required this.key,
    required this.title,
    this.message,
    this.primaryAction,
    this.visual,
    this.onDismiss,
  }) : kind = ShopNoticeKind.success,
       currency = null,
       currentAmount = null,
       requiredAmount = null;

  final Key key;
  final ShopNoticeKind kind;
  final String title;
  final String? message;
  final ShopCurrency? currency;
  final int? currentAmount;
  final int? requiredAmount;
  final ShopNoticeAction? primaryAction;
  final Widget? visual;
  final VoidCallback? onDismiss;
}

class ShopView extends StatefulWidget {
  const ShopView({
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
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  final RevenueCatService _revenueCatService = RevenueCatService();
  final EconomyPurchaseAdapter _economyPurchaseAdapter =
      SupabaseEconomyPurchaseAdapter();
  final ShopPurchaseNotifier _purchaseNotifier = SupabaseShopPurchaseNotifier();
  static const Duration _storeShortageNoticeDuration = Duration(
    milliseconds: 2200,
  );
  static const Duration _storeSuccessNoticeDuration = Duration(
    milliseconds: 2200,
  );
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  int _coins = 0;
  int _diamonds = 0;
  int? _coinReward;
  int _coinRewardEventId = 0;
  List<ShopItem> _items = [];
  final Map<String, int> _inventory = {};
  final Set<String> _roomBackgroundOwned = {};
  int _roomPetCount = 1;
  bool _iapConfigured = false;
  bool _iapLoading = false;
  String? _iapError;
  final Map<String, Package> _packagesByProductId = {};
  final Map<String, StoreProduct> _storeProductsByProductId = {};
  Set<String> _activeEntitlements = {};
  final ScrollController _storeScrollController = ScrollController();
  final GlobalKey _equipmentSectionKey = GlobalKey();
  final GlobalKey _furnitureSectionKey = GlobalKey();
  final GlobalKey _themeSectionKey = GlobalKey();
  final GlobalKey _specialPacksSectionKey = GlobalKey();
  final GlobalKey _consumablesSectionKey = GlobalKey();
  late List<DepartedPetInfo> _departedPets;
  Uri? _privacyPolicyUri;
  late final Uri _termsOfUseUri;
  Timer? _storeNoticeTimer;
  ShopNoticeData? _storeNotice;
  String? _currentAppVersion =
      AppSettingsRepository.instance.lastLaunchedAppVersion;
  RealtimeChannel? _roomInventoryRevisionChannel;
  String? _roomInventoryRevisionSubscriptionRoomId;

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
    _storeNoticeTimer?.cancel();
    final roomInventoryRevisionChannel = _roomInventoryRevisionChannel;
    _roomInventoryRevisionChannel = null;
    unawaited(_removeRealtimeChannel(roomInventoryRevisionChannel));
    _storeScrollController.dispose();
    super.dispose();
  }

  Future<void> _removeRealtimeChannel(RealtimeChannel? channel) async {
    if (channel == null) {
      return;
    }
    try {
      await Supabase.instance.client.removeChannel(channel);
    } catch (_) {
      // Best effort cleanup.
    }
  }

  void _subscribeToRoomInventoryRevisions(String roomId) {
    if (_roomInventoryRevisionSubscriptionRoomId == roomId) {
      return;
    }

    final previousChannel = _roomInventoryRevisionChannel;
    _roomInventoryRevisionChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _roomInventoryRevisionSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel(
      'shop_room_item_inventory_revisions_$roomId',
    );
    _roomInventoryRevisionChannel = channel;

    void refreshStore() {
      if (!mounted || widget.roomId != roomId) {
        return;
      }
      unawaited(_loadStore(silent: true));
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_item_inventory_revisions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => refreshStore(),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'room_item_inventory_revisions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => refreshStore(),
    );

    channel.subscribe();
  }

  void _showStoreNotice(ShopNoticeData notice, {Duration? duration}) {
    _storeNoticeTimer?.cancel();
    _setStoreState(() {
      _storeNotice = notice;
    });
    if (duration == null) {
      return;
    }
    _storeNoticeTimer = Timer(duration, () {
      if (!mounted) {
        return;
      }
      _setStoreState(() {
        _storeNotice = null;
      });
    });
  }

  void _showShortageStoreNotice({
    required String title,
    required ShopCurrency currency,
    required int requiredAmount,
  }) {
    final currentAmount = currency == ShopCurrency.candy ? _coins : _diamonds;
    _showStoreNotice(
      ShopNoticeData.shortage(
        key: UniqueKey(),
        title: title,
        currency: currency,
        currentAmount: currentAmount,
        requiredAmount: requiredAmount,
        onDismiss: _dismissStoreNotice,
      ),
      duration: _storeShortageNoticeDuration,
    );
  }

  void _showPurchaseSuccessNotice({
    required ShopItem item,
    required bool showReturnToRoomAction,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final roomId = widget.roomId;
    final canReturnToRoom = showReturnToRoomAction && roomId != null;
    _showStoreNotice(
      ShopNoticeData.success(
        key: UniqueKey(),
        title: l10n.storePurchaseSuccess(item.localizedName(l10n)),
        message: canReturnToRoom ? l10n.shopReturnToRoomHint : null,
        visual: _buildPurchaseSuccessVisual(item),
        primaryAction: canReturnToRoom
            ? ShopNoticeAction(
                label: l10n.shopReturnToRoomCta,
                onPressed: () {
                  Navigator.of(context).pop(ShopRouteResult.roomDecor(roomId));
                },
              )
            : null,
        onDismiss: _dismissStoreNotice,
      ),
      duration: canReturnToRoom ? null : _storeSuccessNoticeDuration,
    );
  }

  Widget _buildPurchaseSuccessVisual(ShopItem item) {
    if (item.isBackground) {
      return _ShopNoticeBackgroundVisual(backgroundKey: item.backgroundKey);
    }
    if (item.isFurniture) {
      return ShopFurnitureVisual(item: item, size: 34);
    }
    if (item.isEquipment) {
      return ShopCatalogItemVisual(item: item, size: 34);
    }
    final emoji = item.emoji?.trim();
    if (emoji != null && emoji.isNotEmpty) {
      return Text(
        emoji,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, height: 1),
      );
    }
    if (item.isDiamondIap || item.diamondAmount != null) {
      return Image.asset(
        'assets/shop/icon/diamond_300.png',
        fit: BoxFit.contain,
      );
    }
    if (item.coinAmount != null) {
      return Image.asset('assets/shop/icon/candy.png', fit: BoxFit.contain);
    }
    return const Icon(Icons.shopping_bag_rounded, size: 28);
  }

  void _dismissStoreNotice() {
    _storeNoticeTimer?.cancel();
    _setStoreState(() {
      _storeNotice = null;
    });
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

  Future<String?> _ensureCurrentAppVersion() async {
    final cached = _currentAppVersion?.trim();
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final resolved = version.isEmpty ? null : version;
      if (!mounted) {
        _currentAppVersion = resolved;
        return resolved;
      }
      if (resolved != cached) {
        setState(() {
          _currentAppVersion = resolved;
        });
      }
      return resolved;
    } catch (_) {
      return cached != null && cached.isNotEmpty ? cached : _currentAppVersion;
    }
  }

  Future<void> _loadStore({bool silent = false}) async {
    final showFullLoading = !silent && (_items.isEmpty || _error != null);
    if (showFullLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.shopSignInPrompt;
      });
      return;
    }

    try {
      final appVersion = await _ensureCurrentAppVersion();
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins,diamonds')
          .eq('user_id', user.id)
          .maybeSingle();

      final itemsResponse = appVersion == null || appVersion.isEmpty
          ? await Supabase.instance.client
                .from('items')
                .select('id,sku,type,name,price_coins,price_diamonds,metadata')
                .eq('is_active', true)
                .order('price_coins', ascending: true)
          : await Supabase.instance.client.rpc(
              'get_visible_shop_items',
              params: {'p_app_version': appVersion},
            );

      final inventoryResponse = await Supabase.instance.client
          .from('inventories')
          .select('item_id,quantity')
          .eq('user_id', user.id);

      final roomId = widget.roomId;
      List<dynamic> roomFurnitureInventoryRows = const [];
      List<dynamic> roomEquipmentInventoryRows = const [];
      var roomPetCount = 1;
      if (roomId != null) {
        roomFurnitureInventoryRows = await Supabase.instance.client.rpc(
          'get_room_furniture_inventory',
          params: {'p_room_id': roomId},
        );
        roomEquipmentInventoryRows = await Supabase.instance.client.rpc(
          'get_room_equipment_inventory',
          params: {'p_room_id': roomId},
        );
        // Count both the canonical main pet and room_extra_pets (multi-pet
        // v2.0.0). get_room_pets UNIONs both tables.
        final petRows = await Supabase.instance.client.rpc(
          'get_room_pets',
          params: {'p_room_id': roomId},
        );
        roomPetCount = petRows is List ? math.max(1, petRows.length) : 1;
      }

      List<dynamic> roomBackgroundRows = const [];
      if (roomId != null) {
        roomBackgroundRows = await Supabase.instance.client
            .from('room_backgrounds')
            .select('item_id')
            .eq('room_id', roomId);
      }

      final items = (itemsResponse as List<dynamic>)
          .map((row) => ShopItem.fromJson(row as Map<String, dynamic>))
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
        final quantity = row['total_quantity'] as int?;
        if (itemId != null && quantity != null) {
          roomFurnitureInventory[itemId] = quantity;
        }
      }

      final roomEquipmentInventory = <String, int>{};
      for (final row in roomEquipmentInventoryRows) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final itemId = row['id'] as String?;
        final quantity = row['total_quantity'] as int?;
        if (itemId != null && quantity != null) {
          roomEquipmentInventory[itemId] = quantity;
        }
      }

      for (final item in items) {
        if (!item.isFurniture && !item.isEquipment) {
          continue;
        }
        inventory[item.id] = item.isFurniture
            ? roomFurnitureInventory[item.id] ?? 0
            : roomEquipmentInventory[item.id] ?? 0;
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

      if (roomId != null) {
        _subscribeToRoomInventoryRevisions(roomId);
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
        _roomPetCount = roomPetCount;
      });

      await _loadIap(user.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (silent && _items.isNotEmpty) {
        // Ignore background refresh errors if we already have items
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<ShopItem> get _iapItems => _items
      .where((item) => item.isIap)
      .where((item) => item.iapType == 'subscription' || item.isDiamondIap)
      .toList(growable: false);

  List<ShopItem> get _subscriptionItems => _iapItems
      .where((item) => item.iapType == 'subscription')
      .toList(growable: false);

  List<ShopItem> get _iapConsumableItems => _iapItems
      .where((item) => item.iapType != 'subscription')
      .toList(growable: false);

  List<ShopItem> get _iapDiamondPackItems {
    final items = _iapConsumableItems
        .where((item) => item.isDiamondIap)
        .toList();
    items.sort(
      (a, b) => (a.diamondAmount ?? 0).compareTo(b.diamondAmount ?? 0),
    );
    return items;
  }

  List<ShopItem> get _storeItems {
    final items = _items
        .where((item) => !item.isIap && !item.isHiddenFromShop)
        .toList();
    items.sort((a, b) => _itemSortPrice(a).compareTo(_itemSortPrice(b)));
    return items;
  }

  List<ShopItem> get _themeItems => _storeItems
      .where((item) => item.isBackground && !item.isDefaultBackground)
      .toList(growable: false);

  List<ShopItem> get _equipmentItems =>
      _storeItems.where((item) => item.isEquipment).toList(growable: false);

  List<ShopItem> get _furnitureItems =>
      _storeItems.where((item) => item.isFurniture).toList(growable: false);

  List<ShopItem> get _premiumUtilityItems => _storeItems
      .where(
        (item) => !item.isBackground && !item.isFurniture && !item.isEquipment,
      )
      .toList(growable: false);

  int _itemSortPrice(ShopItem item) {
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _storeBackgroundGradient,
            ),
          ),
          child: Stack(
            children: [
              const _ShopBackgroundStars(),
              RefreshIndicator(
                displacement: 100,
                onRefresh: _loadStore,
                child: _buildBody(context, l10n),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 16,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  ignoring: _storeNotice == null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, -0.18),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: _storeNotice == null
                        ? const SizedBox.shrink()
                        : ShopFloatingNoticeCard(
                            key: _storeNotice!.key,
                            notice: _storeNotice!,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            AdMobIds.isBannerViewSupported && !_hasProAdFreeAccess
            ? const AdMobBannerSlot()
            : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(l10n),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(l10n),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadStore,
                    child: Text(l10n.commonTryAgain),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return CustomScrollView(
        slivers: [
          _buildSliverAppBar(l10n),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.shopEmpty, textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _storeScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildSliverAppBar(l10n),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (_iapError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _iapError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (_subscriptionItems.isNotEmpty)
          SliverToBoxAdapter(
            child: ShopFeaturedBanner(
              items: _subscriptionItems,
              onPurchase: _purchaseIapItem,
              findPackage: _findPackageByProductId,
              findStoreProduct: _findStoreProductByProductId,
              isProUser: widget.isProUser,
              activeEntitlements: _activeEntitlements,
              iapConfigured: _iapConfigured,
              isPurchasing: _purchasing,
              scrollController: _storeScrollController,
            ),
          ),

        SliverToBoxAdapter(
          child: _ShopCategoryRow(
            onEquipmentTap: _equipmentItems.isEmpty
                ? null
                : () => _jumpToSection(
                    _equipmentSectionKey,
                    fallbackFraction: 0.35,
                  ),
            onFurnitureTap: _furnitureItems.isEmpty
                ? null
                : () => _jumpToSection(
                    _furnitureSectionKey,
                    fallbackFraction: 0.55,
                  ),
            onThemeTap: _themeItems.isEmpty
                ? null
                : () => _jumpToSection(_themeSectionKey, fallbackFraction: 1),
          ),
        ),

        if (_iapDiamondPackItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _specialPacksSectionKey,
              child: _SectionHeader(title: l10n.shopSectionDiamondPacks),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildGridItemCard(_iapDiamondPackItems[index], l10n),
                childCount: _iapDiamondPackItems.length,
              ),
            ),
          ),
        ],
        if (_premiumUtilityItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _consumablesSectionKey,
              child: _SectionHeader(title: l10n.shopSectionItems),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildGridItemCard(_premiumUtilityItems[index], l10n),
                childCount: _premiumUtilityItems.length,
              ),
            ),
          ),
        ],
        if (_equipmentItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _equipmentSectionKey,
              child: _SectionHeader(title: l10n.shopSectionEquipment),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildGridItemCard(_equipmentItems[index], l10n),
                childCount: _equipmentItems.length,
              ),
            ),
          ),
        ],
        if (_furnitureItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _furnitureSectionKey,
              child: _SectionHeader(title: l10n.storeTabFurniture),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildGridItemCard(_furnitureItems[index], l10n),
                childCount: _furnitureItems.length,
              ),
            ),
          ),
        ],
        if (_themeItems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _themeSectionKey,
              child: _SectionHeader(title: l10n.storeTabThemes),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildGridItemCard(_themeItems[index], l10n),
                childCount: _themeItems.length,
              ),
            ),
          ),
        ],
        if (_subscriptionItems.isNotEmpty && _privacyPolicyUri != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: ShopLegalLinksRow(
                privacyPolicyUri: _privacyPolicyUri!,
                termsOfUseUri: _termsOfUseUri,
                privacyPolicyLabel: l10n.storePrivacyPolicy,
                termsOfUseLabel: l10n.storeTermsOfUse,
                separatorLabel: l10n.storeLegalSeparator,
                onLaunchFailed: _handleLegalLinkOpenFailed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.chevron_left_rounded,
          size: 40,
          color: Color(0xFF5C6BC0),
        ),
      ),
      title: _ShopStrokeText(
        l10n.shopTitle,
        fontSize: 24,
        color: Colors.white,
        strokeColor: const Color(0xFF1A237E),
        strokeWidth: 4.5,
      ),
      actions: [
        if (_subscriptionItems.isNotEmpty)
          IconButton(
            onPressed: _iapLoading ? null : _restorePurchases,
            icon: const Icon(
              Icons.history_rounded,
              size: 28,
              color: Color(0xFF5C6BC0),
            ),
            tooltip: l10n.storeRestoreTooltip,
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShopCurrencyChip(
                amount: _diamonds,
                icon: Image.asset(
                  'assets/shop/icon/diamond.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 6),
              ShopCurrencyChip(
                amount: _coins,
                coinReward: _coinReward,
                coinRewardEventId: _coinRewardEventId,
                icon: Image.asset(
                  'assets/shop/icon/candy.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
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

class ShopFloatingNoticeCard extends StatelessWidget {
  const ShopFloatingNoticeCard({super.key, required this.notice});

  final ShopNoticeData notice;

  @override
  Widget build(BuildContext context) {
    final isShortage = notice.kind == ShopNoticeKind.shortage;
    final isCandy = notice.currency == ShopCurrency.candy;
    final accent = switch (notice.kind) {
      ShopNoticeKind.shortage =>
        isCandy ? const Color(0xFFFF8A65) : const Color(0xFF4C7DFF),
      ShopNoticeKind.success => const Color(0xFF3DA66B),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 5,
                left: 0,
                right: 0,
                bottom: -5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.98),
                      const Color(0xFFFFF7EA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withValues(alpha: 0.22),
                            accent.withValues(alpha: 0.38),
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: EdgeInsets.all(isShortage ? 11 : 8),
                          child: isShortage
                              ? Image.asset(
                                  isCandy
                                      ? 'assets/shop/icon/candy.png'
                                      : 'assets/shop/icon/diamond.png',
                                )
                              : DefaultTextStyle(
                                  style: TextStyle(color: accent),
                                  child:
                                      notice.visual ??
                                      Icon(
                                        Icons.check_rounded,
                                        size: 30,
                                        color: accent,
                                      ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShopStrokeText(
                            notice.title,
                            fontSize: 16,
                            color: accent,
                            strokeColor: Colors.white,
                            strokeWidth: 3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (notice.message != null &&
                              notice.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              notice.message!,
                              style: GoogleFonts.mPlusRounded1c(
                                color: const Color(0xFF5A4A42),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ],
                          if (isShortage &&
                              notice.currentAmount != null &&
                              notice.requiredAmount != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${notice.currentAmount}',
                                    style: GoogleFonts.mPlusRounded1c(
                                      color: const Color(0xFF5A4A42),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '/',
                                      style: GoogleFonts.mPlusRounded1c(
                                        color: const Color(0xFF9E8B80),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${notice.requiredAmount}',
                                    style: GoogleFonts.mPlusRounded1c(
                                      color: accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (notice.primaryAction != null) ...[
                            const SizedBox(height: 10),
                            FilledButton.tonal(
                              onPressed: notice.primaryAction!.onPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: accent.withValues(alpha: 0.14),
                                foregroundColor: accent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                textStyle: GoogleFonts.mPlusRounded1c(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: Text(notice.primaryAction!.label),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (notice.onDismiss != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: notice.onDismiss,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: -8,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    isShortage ? '!' : 'OK',
                    style: GoogleFonts.mPlusRounded1c(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
