part of 'home_view.dart';

/// "Just arrived in the shop" popup for catalog items whose
/// `metadata.new_until` is still open. Shown once per account per NEW item,
/// and only inside a room so the shop knows which room purchases go to.
extension _HomeNewShopItems on _HomeViewState {
  bool _canShowNewShopItemsFor(String roomId) {
    return mounted &&
        _roomId == roomId &&
        !_showRoomSelection &&
        !_roomEntryLoading &&
        !_isBasicOnboardingActive &&
        (ModalRoute.of(context)?.isCurrent ?? true);
  }

  /// A launch dialog (What's New, update prompt) can still cover the room
  /// here, most often on the first launch of the release that brings the
  /// items. Wait for it to close instead of dropping the popup until the next
  /// room entry.
  Future<bool> _waitForRoomOnTop(String roomId) {
    return waitUntilUncovered(
      isCovered: () => mounted && !(ModalRoute.of(context)?.isCurrent ?? true),
      isStillWanted: () => mounted && _roomId == roomId,
    );
  }

  Future<void> _maybeShowNewShopItems(String roomId) async {
    if (_newShopItemsCheckedThisSession) {
      return;
    }
    // Let the room entry settle so the popup never covers it.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!await _waitForRoomOnTop(roomId)) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    final appVersion = _currentAppVersion;
    if (_newShopItemsCheckedThisSession ||
        user == null ||
        appVersion == null ||
        appVersion.isEmpty ||
        !_canShowNewShopItemsFor(roomId)) {
      return;
    }
    _newShopItemsCheckedThisSession = true;

    final List<ShopItem> newItems;
    try {
      final now = DateTime.now();
      newItems = (await _fetchPopupShopItems(
        appVersion,
      )).where((item) => item.isNewAt(now)).toList();
    } catch (error, stackTrace) {
      _newShopItemsCheckedThisSession = false;
      reportSwallowedError(error, stackTrace, source: 'home_new_shop_items');
      return;
    }

    final settings = AppSettingsRepository.instance;
    final seen = settings.seenNewShopItemIds(user.id);
    final unseen = newItems.where((item) => !seen.contains(item.id)).toList();
    if (unseen.isEmpty ||
        !await _waitForRoomOnTop(roomId) ||
        !_canShowNewShopItemsFor(roomId)) {
      return;
    }
    // Keep only ids still inside their NEW window so the set stays small.
    await settings.setSeenNewShopItemIds(
      user.id,
      newItems.map((item) => item.id).toSet(),
    );
    if (!mounted) {
      return;
    }

    _sortForNewShopItemsPopup(unseen);

    AnalyticsService.instance.logEvent(
      'new_items_popup_shown',
      parameters: {'count': unseen.length},
    );
    final shopRoomId = await _showNewShopItemsPopup(unseen, roomId);
    if (shopRoomId == null || !mounted) {
      return;
    }
    AnalyticsService.instance.logEvent('new_items_popup_visit');
    await _openStoreWithDepartures(shopRoomId: shopRoomId);
  }

  /// Shop items the popup may feature: visible, non-IAP and supported on
  /// [appVersion]. Callers apply the NEW-window filter.
  Future<List<ShopItem>> _fetchPopupShopItems(String appVersion) async {
    final rows = await Supabase.instance.client.rpc(
      'get_visible_shop_items',
      params: {'p_app_version': appVersion},
    );
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ShopItem.fromJson)
        .where(
          (item) =>
              !item.isIap &&
              !item.isHiddenFromShop &&
              item.isSupportedOnAppVersion(appVersion),
        )
        .toList();
  }

  void _sortForNewShopItemsPopup(List<ShopItem> items) {
    int rank(ShopItem item) => item.isFurniture
        ? 0
        : item.isEquipment
        ? 1
        : item.isBackground
        ? 2
        : 3;
    items.sort((a, b) => rank(a).compareTo(rank(b)));
  }

  /// Debug drawer preview: shows the popup for the current NEW items,
  /// ignoring the seen set and session flag and recording nothing. Falls back
  /// to a few catalog items when no NEW window is open.
  Future<void> _debugShowNewShopItems() async {
    final roomId = _roomId;
    final appVersion = _currentAppVersion;
    if (roomId == null || appVersion == null || appVersion.isEmpty) {
      return;
    }
    final List<ShopItem> items;
    try {
      items = await _fetchPopupShopItems(appVersion);
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'debug_new_shop_items');
      return;
    }
    final now = DateTime.now();
    final newItems = items.where((item) => item.isNewAt(now)).toList();
    final preview = newItems.isNotEmpty ? newItems : items.take(3).toList();
    if (preview.isEmpty || !mounted) {
      return;
    }
    _sortForNewShopItemsPopup(preview);
    final shopRoomId = await _showNewShopItemsPopup(preview, roomId);
    if (shopRoomId == null || !mounted) {
      return;
    }
    await _openStoreWithDepartures(shopRoomId: shopRoomId);
  }

  /// Returns the room id to open the shop for, or null when dismissed.
  Future<String?> _showNewShopItemsPopup(List<ShopItem> items, String roomId) {
    final l10n = AppLocalizations.of(context)!;
    final hero = items.first;
    final rooms = _shopRoomTargets();
    var selectedRoomId = roomId;

    return showJuiceToast<String>(
      context: context,
      message: l10n.newItemsPopupTitle,
      position: JuicePosition.center,
      // The item art lives in the body: the leading slot would leave the
      // room tag too narrow on 320pt phones.
      fullWidthBody: true,
      body: StatefulBuilder(
        builder: (context, setDialogState) {
          ShopRoomTarget? selected;
          for (final room in rooms) {
            if (room.roomId == selectedRoomId) {
              selected = room;
            }
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.kinako,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.ink, width: 2),
                    ),
                    child: hero.isEquipment
                        ? ShopCatalogItemVisual(item: hero, size: 52)
                        : ShopFurnitureVisual(item: hero, size: 52),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hero.localizedName(l10n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mPlusRounded1c(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (items.length > 1)
                          Text(
                            l10n.newItemsPopupMore(items.length - 1),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.mPlusRounded1c(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Only multi-room users can mix up where purchases go.
              if (rooms.length > 1 && selected != null) ...[
                const Gap(12),
                ShopDeliveryTag(
                  target: selected,
                  compact: true,
                  onSwitch: () async {
                    final picked = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => ShopRoomPickerSheet(
                        title: l10n.shopSwitchRoomTitle,
                        rooms: rooms,
                        selectedRoomId: selectedRoomId,
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedRoomId = picked);
                    }
                  },
                ),
              ],
              const Gap(12),
              ShopRoomActionButton(
                label: l10n.newItemsVisitShop,
                filled: true,
                onTap: () => Navigator.of(context).pop(selectedRoomId),
              ),
              const Gap(8),
              ShopRoomActionButton(
                label: l10n.newItemsLater,
                filled: false,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }
}
