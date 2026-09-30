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

  Future<void> _maybeShowNewShopItems(String roomId) async {
    if (_newShopItemsCheckedThisSession) {
      return;
    }
    // Let the room entry settle so the popup never covers it.
    await Future<void>.delayed(const Duration(seconds: 2));
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
      final rows = await Supabase.instance.client.rpc(
        'get_visible_shop_items',
        params: {'p_app_version': appVersion},
      );
      final now = DateTime.now();
      newItems = (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ShopItem.fromJson)
          .where(
            (item) =>
                item.isNewAt(now) &&
                !item.isIap &&
                !item.isHiddenFromShop &&
                item.isSupportedOnAppVersion(appVersion),
          )
          .toList();
    } catch (error, stackTrace) {
      _newShopItemsCheckedThisSession = false;
      reportSwallowedError(error, stackTrace, source: 'home_new_shop_items');
      return;
    }

    final settings = AppSettingsRepository.instance;
    final seen = settings.seenNewShopItemIds(user.id);
    final unseen = newItems.where((item) => !seen.contains(item.id)).toList();
    if (unseen.isEmpty || !_canShowNewShopItemsFor(roomId)) {
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

    int rank(ShopItem item) => item.isFurniture
        ? 0
        : item.isEquipment
        ? 1
        : item.isBackground
        ? 2
        : 3;
    unseen.sort((a, b) => rank(a).compareTo(rank(b)));

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
      leading: const SizedBox.shrink(),
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
