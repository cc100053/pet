import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'models/shop_item.dart';
import 'widgets/shop_legal_links_row.dart';

part 'services/shop_iap_service.dart';
part 'services/shop_purchase_handler.dart';
part 'widgets/shop_departed_pet_selector.dart';
part 'widgets/shop_item_cards.dart';

const List<Color> _storeBackgroundGradient = [
  Color(0xFFE0F7FF), // Light Blue
  Color(0xFFF3E5F5), // Soft Lavender
  Color(0xFFFFF3E0), // Soft Peach/Pink
];

enum _ShopCurrency { candy, diamonds }

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
  static const Duration _storeNoticeDuration = Duration(milliseconds: 2200);
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  int _coins = 0;
  int _diamonds = 0;
  List<ShopItem> _items = [];
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
  final GlobalKey _specialPacksSectionKey = GlobalKey();
  final GlobalKey _consumablesSectionKey = GlobalKey();
  late List<DepartedPetInfo> _departedPets;
  Uri? _privacyPolicyUri;
  late final Uri _termsOfUseUri;
  Timer? _storeNoticeTimer;
  _ShopNoticeData? _storeNotice;

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
    _storeScrollController.dispose();
    super.dispose();
  }

  void _showStoreNotice({
    required String message,
    required _ShopCurrency currency,
    required int requiredAmount,
  }) {
    final currentAmount = currency == _ShopCurrency.candy ? _coins : _diamonds;
    _storeNoticeTimer?.cancel();
    _setStoreState(() {
      _storeNotice = _ShopNoticeData(
        key: UniqueKey(),
        message: message,
        currency: currency,
        currentAmount: currentAmount,
        requiredAmount: requiredAmount,
      );
    });
    _storeNoticeTimer = Timer(_storeNoticeDuration, () {
      if (!mounted) {
        return;
      }
      _setStoreState(() {
        _storeNotice = null;
      });
    });
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

  Future<void> _loadStore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.shopSignInPrompt;
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
    final items = _items.where((item) => !item.isIap).toList();
    items.sort((a, b) => _itemSortPrice(a).compareTo(_itemSortPrice(b)));
    return items;
  }

  List<ShopItem> get _themeItems => _storeItems
      .where((item) => item.isBackground && !item.isDefaultBackground)
      .toList(growable: false);

  List<ShopItem> get _furnitureItems =>
      _storeItems.where((item) => item.isFurniture).toList(growable: false);

  List<ShopItem> get _premiumUtilityItems => _storeItems
      .where((item) => !item.isBackground && !item.isFurniture)
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
      value: AppStatusBarStyles.dark,
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
                        : _ShopFloatingNotice(
                            key: _storeNotice!.key,
                            notice: _storeNotice!,
                            onDismiss: _dismissStoreNotice,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AdMobIds.isSupported && !_hasProAdFreeAccess
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
              activeEntitlements: _activeEntitlements,
              iapConfigured: _iapConfigured,
              isPurchasing: _purchasing,
              scrollController: _storeScrollController,
            ),
          ),

        SliverToBoxAdapter(
          child: _ShopCategoryRow(
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
              _ShopCurrencyChip(
                amount: _diamonds,
                icon: Image.asset(
                  'assets/shop/icon/diamond.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 6),
              _ShopCurrencyChip(
                amount: _coins,
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

class _ShopNoticeData {
  const _ShopNoticeData({
    required this.key,
    required this.message,
    required this.currency,
    required this.currentAmount,
    required this.requiredAmount,
  });

  final Key key;
  final String message;
  final _ShopCurrency currency;
  final int currentAmount;
  final int requiredAmount;
}

class _ShopFloatingNotice extends StatelessWidget {
  const _ShopFloatingNotice({
    super.key,
    required this.notice,
    required this.onDismiss,
  });

  final _ShopNoticeData notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bool isCandy = notice.currency == _ShopCurrency.candy;
    final Color accent = isCandy
        ? const Color(0xFFFF8A65)
        : const Color(0xFF4C7DFF);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(26),
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
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Image.asset(
                            isCandy
                                ? 'assets/shop/icon/candy.png'
                                : 'assets/shop/icon/diamond.png',
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShopStrokeText(
                              notice.message,
                              fontSize: 16,
                              color: accent,
                              strokeColor: Colors.white,
                              strokeWidth: 3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        ),
                      ),
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
                      '!',
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: _ShopStrokeText(
        title,
        fontSize: 16,
        color: Colors.white,
        strokeColor: Colors.black.withValues(alpha: 0.7),
        strokeWidth: 4.5,
      ),
    );
  }
}

class _ShopStrokeText extends StatelessWidget {
  const _ShopStrokeText(
    this.text, {
    required this.fontSize,
    required this.color,
    this.strokeColor = Colors.white,
    this.strokeWidth = 4.5,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: GoogleFonts.mPlusRounded1c(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: GoogleFonts.mPlusRounded1c(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ShopAdaptiveStrokeTitle extends StatelessWidget {
  const _ShopAdaptiveStrokeTitle({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.strokeColor,
    this.strokeWidth = 4.5,
    this.height = 32,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: _ShopStrokeText(
            text,
            fontSize: fontSize,
            color: color,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          ),
        ),
      ),
    );
  }
}

class ShopFeaturedBanner extends StatefulWidget {
  const ShopFeaturedBanner({
    super.key,
    required this.items,
    required this.onPurchase,
    required this.findPackage,
    required this.findStoreProduct,
    required this.activeEntitlements,
    required this.iapConfigured,
    required this.isPurchasing,
    required this.scrollController,
  });

  final List<ShopItem> items;
  final void Function(ShopItem) onPurchase;
  final Package? Function(String) findPackage;
  final StoreProduct? Function(String) findStoreProduct;
  final Set<String> activeEntitlements;
  final bool iapConfigured;
  final bool isPurchasing;
  final ScrollController scrollController;

  @override
  State<ShopFeaturedBanner> createState() => _ShopFeaturedBannerState();
}

class _ShopFeaturedBannerState extends State<ShopFeaturedBanner>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _floatController;
  int _currentPage = 0;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    ); // Controller kept but not repeating for static display

    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = widget.scrollController.offset;
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final productId = item.iapProductId;
              final package = productId != null
                  ? widget.findPackage(productId)
                  : null;
              final storeProduct = productId != null
                  ? widget.findStoreProduct(productId)
                  : null;
              final priceString = item.localizedIapPrice(
                package,
                storeProduct,
                l10n,
              );
              final entitlementId = item.rcEntitlementId;
              final isSubscribed =
                  item.iapType == 'subscription' &&
                  entitlementId != null &&
                  widget.activeEntitlements.contains(entitlementId);
              final canBuy =
                  widget.iapConfigured &&
                  !widget.isPurchasing &&
                  !isSubscribed &&
                  (package != null || storeProduct != null);
              final actionLabel = isSubscribed
                  ? l10n.commonOwned
                  : l10n.storeSubscribe;

              // Parallax logic
              final parallaxOffset = _scrollOffset * 0.15;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFA5F2FF), // Light Dream Blue
                      Color(0xFFD1C4E9), // Light Lavender
                      Color(0xFFF3E5F5), // Soft Purple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF303F9F).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Soft bubbles background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _StarryBackgroundPainter(
                            scrollOffset: _scrollOffset * 0.08,
                          ),
                        ),
                      ),

                      // Cat Illustration (Moved back inside, balanced position)
                      Positioned(
                        left: -10,
                        bottom: -10 - parallaxOffset,
                        top: 10 - parallaxOffset,
                        width: 160,
                        child: Image.asset(
                          'assets/shop/shop_cat.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Main Content Area
                      Positioned(
                        right: 16,
                        top: 6, // Reduced top padding
                        bottom: 8,
                        left: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD180), Color(0xFFFB8C00)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: _ShopAdaptiveStrokeTitle(
                                text: item.localizedName(l10n),
                                fontSize: 26,
                                color: Colors.white,
                                strokeColor: Colors.black, // Black outline
                                strokeWidth: 4, // Thick black stroke
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced spacing
                            
                            // Visual Benefits List
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BenefitItem(
                                    icon: Icons.meeting_room_rounded,
                                    text: l10n.storePremiumBenefitUnlimitedRooms,
                                  ),
                                  _BenefitItem(
                                    icon: Icons.block_rounded,
                                    text: l10n.storePremiumBenefitNoAds,
                                  ),
                                  _BenefitItem(
                                    icon: Icons.star_rounded,
                                    text: l10n.storePremiumBenefitExclusiveItems,
                                  ),
                                ],
                              ),
                            ),

                            // CTA Area
                            Opacity(
                              opacity: canBuy || isSubscribed ? 1 : 0.65,
                              child: _ShopRaisedButtonShell(
                                onPressed: canBuy
                                    ? () => widget.onPurchase(item)
                                    : null,
                                depth: !isSubscribed && canBuy ? 4 : 0,
                                borderRadius: BorderRadius.circular(20),
                                shadowColor: const Color(0xFFE65100),
                                faceBuilder: (context, isPressed) => Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSubscribed || !canBuy
                                        ? null
                                        : const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFFFFD180),
                                              Color(0xFFFB8C00),
                                            ],
                                          ),
                                    color: isSubscribed || !canBuy
                                        ? Colors.white.withValues(alpha: 0.95)
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (!isSubscribed) ...[
                                          _ShopStrokeText(
                                            priceString,
                                            fontSize: 16,
                                            color: Colors.white,
                                            strokeColor: const Color(0xFFD54900),
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        _ShopStrokeText(
                                          actionLabel,
                                          fontSize: 16,
                                          color: Colors.white,
                                          strokeColor: const Color(0xFFD54900),
                                          strokeWidth: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                '${l10n.storeSubscriptionDurationMonthly} • ${l10n.storeSubscriptionRenewalNote}',
                                style: GoogleFonts.mPlusRounded1c(
                                  color: const Color(0xFF303F9F).withValues(alpha: 0.7),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? const Color(0xFF90CAF9)
                      : Colors.black12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6), // Reduced bottom padding
      child: Row(
        children: [
          // Icon with white circular background for maximum clarity
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: const Color(0xFF303F9F), // Deep Indigo icon
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.mPlusRounded1c(
                color: const Color(0xFF303F9F).withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarryBackgroundPainter extends CustomPainter {
  _StarryBackgroundPainter({required this.scrollOffset});
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    // Draw soft bubbles/circles
    for (var i = 0; i < 15; i++) {
      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: random.nextDouble() * 0.15 + 0.05);
      
      final radius = 10.0 + random.nextDouble() * 30.0;
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + scrollOffset * 0.5) % size.height;
      
      canvas.drawCircle(Offset(x, y), radius, bubblePaint);
    }
    
    // Add some tiny sparkles
    final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (var i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + scrollOffset) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_StarryBackgroundPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}

class _ShopBackgroundStars extends StatelessWidget {
  const _ShopBackgroundStars();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Background Glows (Multi-directional colors)
          Positioned(
            top: -100,
            left: -100,
            child: _Glow(
              color: const Color(
                0xFFB3E5FC,
              ).withValues(alpha: 0.5), // Light Blue
              size: 400,
            ),
          ),
          Positioned(
            top: -50,
            right: -100,
            child: _Glow(
              color: const Color(
                0xFFE1BEE7,
              ).withValues(alpha: 0.5), // Light Purple
              size: 350,
            ),
          ),
          Positioned(
            top: 300,
            left: -50,
            child: _Glow(
              color: const Color(0xFFFFF9C4).withValues(alpha: 0.4), // Yellow
              size: 300,
            ),
          ),
          Positioned(
            bottom: 200,
            right: -100,
            child: _Glow(
              color: const Color(
                0xFFFFCDD2,
              ).withValues(alpha: 0.4), // Soft Red/Pink
              size: 450,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _Glow(
              color: const Color(0xFFFFF3E0).withValues(alpha: 0.5), // Peach
              size: 400,
            ),
          ),

          // Large Stars
          _Star(top: 80, left: 20, size: 32, opacity: 0.2),
          _Star(top: 220, right: 30, size: 40, opacity: 0.15),
          _Star(bottom: 150, left: 40, size: 28, opacity: 0.2),
          _Star(top: 400, right: 100, size: 36, opacity: 0.1),

          // Small Stars
          _Star(top: 150, left: 80, size: 14, opacity: 0.2),
          _Star(bottom: 250, right: 50, size: 16, opacity: 0.2),

          // Colorful Dots
          _Dot(
            top: 120,
            right: 80,
            size: 12,
            color: const Color(0xFFFFCDD2),
          ), // Pink
          _Dot(
            top: 300,
            left: 100,
            size: 10,
            color: const Color(0xFFE1BEE7),
          ), // Purple
          _Dot(
            bottom: 200,
            left: 150,
            size: 14,
            color: const Color(0xFFB3E5FC),
          ), // Blue
          _Dot(
            top: 500,
            right: 40,
            size: 8,
            color: const Color(0xFFF9FBE7),
          ), // Yellow
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Opacity(
        opacity: opacity,
        child: Icon(Icons.star_rounded, size: size, color: Colors.white),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ShopCategoryRow extends StatelessWidget {
  const _ShopCategoryRow({this.onFurnitureTap, this.onThemeTap});

  final VoidCallback? onFurnitureTap;
  final VoidCallback? onThemeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CategoryItem(
            icon: Image.asset(
              'assets/shop/icon/sofa.png',
              width: 50,
              height: 50,
            ),
            label: l10n.storeTabFurniture,
            color: const Color(0xFFFFCDD2),
            onTap: onFurnitureTap,
          ),
          _CategoryItem(
            icon: Image.asset(
              'assets/shop/icon/house.png',
              width: 50,
              height: 50,
            ),
            label: l10n.storeTabThemes,
            color: const Color(0xFFE1BEE7),
            onTap: onThemeTap,
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(width: 60, height: 55, child: Center(child: icon)),
          const SizedBox(height: 0),
          _ShopStrokeText(
            label,
            fontSize: 16,
            color: Colors.white,
            strokeColor: const Color(0xFF1A237E),
            strokeWidth: 4,
          ),
        ],
      ),
    );
  }
}

class _ShopCurrencyChip extends StatelessWidget {
  const _ShopCurrencyChip({required this.amount, required this.icon});

  final int amount;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            '$amount',
            style: GoogleFonts.mPlusRounded1c(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
