part of 'home_view.dart';

/// Room-decoration domain for [_HomeViewState]: furniture inventory,
/// placement, drag/scale/flip gestures, persistence, and room backgrounds.
/// Extracted from home_view.dart verbatim (behavior-preserving).
extension _HomeRoomDecor on _HomeViewState {
  int _placedCountForItem(String itemId) {
    final placed = _activeFurnitureForRoom();
    return placed.where((item) => item.itemId == itemId).length;
  }

  int _availableFurnitureCount(String itemId) {
    final owned = _furnitureInventory[itemId] ?? 0;
    final placed = _placedCountForItem(itemId);
    return availableRoomFurnitureCount(totalOwned: owned, placedCount: placed);
  }

  Future<void> _loadFurnitureInventory() async {
    if (_furnitureLoading) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      _setStateForRoomDecor(() {
        _furnitureCatalog.clear();
        _furnitureInventory.clear();
      });
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      _setStateForRoomDecor(() {
        _furnitureError = AppLocalizations.of(context)!.shopSignInPrompt;
      });
      return;
    }

    _setStateForRoomDecor(() {
      _furnitureLoading = true;
      _furnitureError = null;
    });

    try {
      final appVersion = await _ensureCurrentAppVersion();
      final itemsResponse = appVersion == null || appVersion.isEmpty
          ? await Supabase.instance.client
                .from('items')
                .select(
                  'id,sku,type,name,price_coins,price_diamonds,metadata,is_active',
                )
                .eq('is_active', true)
          : await Supabase.instance.client.rpc(
              'get_visible_shop_items',
              params: {'p_app_version': appVersion},
            );
      final inventoryResponse = await Supabase.instance.client.rpc(
        'get_room_furniture_inventory',
        params: {'p_room_id': roomId},
      );

      final visibleItems = (itemsResponse as List<dynamic>)
          .map((row) => ShopItem.fromJson(row as Map<String, dynamic>))
          .where((item) => item.isFurniture)
          .toList(growable: false);

      final inventory = <String, int>{};
      for (final row in inventoryResponse as List<dynamic>) {
        final itemId = row['item_id'] as String?;
        final quantity = row['total_quantity'] as int?;
        if (itemId != null && quantity != null) {
          inventory[itemId] = quantity;
        }
      }

      final visibleItemIds = visibleItems.map((item) => item.id).toSet();
      final missingInventoryIds = inventory.keys
          .where((itemId) => !visibleItemIds.contains(itemId))
          .toList(growable: false);
      final inventoryItemDetails = <ShopItem>[];
      if (missingInventoryIds.isNotEmpty) {
        final ownedItemsResponse = await Supabase.instance.client
            .from('items')
            .select(
              'id,sku,type,name,price_coins,price_diamonds,metadata,is_active',
            )
            .inFilter('id', missingInventoryIds);
        inventoryItemDetails.addAll(
          (ownedItemsResponse as List<dynamic>)
              .map((row) => ShopItem.fromJson(row as Map<String, dynamic>))
              .where((item) => item.isFurniture),
        );
      }

      if (!mounted) {
        return;
      }

      final catalog = buildRoomFurnitureCatalog(
        visibleShopItems: visibleItems,
        inventoryItemDetails: inventoryItemDetails,
        inventory: inventory,
        appVersion: appVersion,
      );

      _setStateForRoomDecor(() {
        _furnitureCatalog
          ..clear()
          ..addAll(catalog);
        _furnitureInventory
          ..clear()
          ..addAll(inventory);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setStateForRoomDecor(() {
        _furnitureError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        _setStateForRoomDecor(() => _furnitureLoading = false);
      }
    }
  }

  void _markFurnitureWrite(String id) {
    _recentFurnitureWriteAt[id] = DateTime.now();
  }

  bool _isRecentFurnitureWrite(String? id) {
    if (id == null) {
      return false;
    }
    final at = _recentFurnitureWriteAt[id];
    if (at == null) {
      return false;
    }
    return DateTime.now().difference(at) <=
        _HomeViewState._furnitureSelfEchoWindow;
  }

  void _handleFurnitureRealtimeChange(
    String roomId,
    PostgresChangePayload payload,
  ) {
    // Fix 3: never reload while the user is actively dragging or scaling a
    // piece; defer any genuine remote change until the gesture ends.
    if (_activeFurnitureDragId != null ||
        _activeFurnitureScaleInteractionItemId != null) {
      _furnitureReloadPendingAfterGesture = true;
      return;
    }
    // Prune stale ids so the map cannot grow unbounded.
    final cutoff = DateTime.now().subtract(
      _HomeViewState._furnitureSelfEchoWindow,
    );
    _recentFurnitureWriteAt.removeWhere((_, at) => at.isBefore(cutoff));
    // Fix 1: ignore the echo of our own recent write; its authoritative value
    // is already applied from the RPC response.
    final changedId =
        (payload.newRecord['id'] ?? payload.oldRecord['id']) as String?;
    if (_isRecentFurnitureWrite(changedId)) {
      return;
    }
    unawaited(_loadRoomFurniture(roomId));
  }

  void _flushPendingFurnitureReload() {
    if (!_furnitureReloadPendingAfterGesture) {
      return;
    }
    _furnitureReloadPendingAfterGesture = false;
    final roomId = _roomId;
    if (roomId != null) {
      unawaited(_loadRoomFurniture(roomId));
    }
  }

  Future<void> _loadRoomFurniture(String roomId) async {
    try {
      await _ensureCurrentAppVersion();
      final response = await Supabase.instance.client
          .from('room_furniture')
          .select(
            'id,item_id,owner_user_id,position_x,position_y,canvas_position_x,canvas_position_y,scale,flip_x,items(id,sku,type,name,price_coins,price_diamonds,metadata)',
          )
          .eq('room_id', roomId);

      final placed = <_PlacedFurniture>[];
      var unsupportedCount = 0;
      for (final row in response as List<dynamic>) {
        final record = row as Map<String, dynamic>;
        final id = record['id'] as String?;
        final itemId = record['item_id'] as String?;
        if (id == null || itemId == null) {
          continue;
        }
        final itemData = record['items'] as Map<String, dynamic>?;
        if (!_supportsPlacedFurniture(itemData)) {
          unsupportedCount++;
          continue;
        }
        final ownerUserId = record['owner_user_id'] as String?;
        final posX = (record['position_x'] as num?)?.toDouble() ?? 0;
        final posY = (record['position_y'] as num?)?.toDouble() ?? 0;
        final canvasX = (record['canvas_position_x'] as num?)?.toDouble();
        final canvasY = (record['canvas_position_y'] as num?)?.toDouble();
        final canvasPosition = (canvasX != null && canvasY != null)
            ? Offset(canvasX, canvasY)
            : null;
        final scale = _parseFurnitureScale(record['scale']);
        final flipX = record['flip_x'] == true;
        final emoji = _resolveFurnitureEmoji(itemId, record);
        final assetPath = _resolveFurnitureAssetPath(itemId, record);
        placed.add(
          _PlacedFurniture(
            id: id,
            itemId: itemId,
            ownerUserId: ownerUserId,
            emoji: emoji,
            assetPath: assetPath,
            normalizedPosition: Offset(posX, posY),
            persistedNormalizedPosition: Offset(posX, posY),
            canvasPosition: canvasPosition,
            persistedCanvasPosition: canvasPosition,
            scale: scale,
            persistedScale: scale,
            flipX: flipX,
            persistedFlipX: flipX,
            isPending: false,
          ),
        );
      }

      if (!mounted || _roomId != roomId) {
        return;
      }
      _setStateForRoomDecor(() {
        _placedFurnitureByRoom[roomId] = placed;
        _unsupportedPlacedFurnitureCountByRoom[roomId] = unsupportedCount;
      });
      unawaited(_maybePromptForUnsupportedRoomDecor(roomId));
    } catch (error) {
      if (mounted) {
        _setStateForRoomDecor(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
        });
      }
    }
  }

  void _subscribeToFurniture(String roomId) {
    if (_furnitureSubscriptionRoomId == roomId) {
      return;
    }

    final previousChannel = _furnitureChannel;
    _furnitureChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _furnitureSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel('room_furniture_$roomId');
    _furnitureChannel = channel;

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_furniture',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => _handleFurnitureRealtimeChange(roomId, payload),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'room_furniture',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => _handleFurnitureRealtimeChange(roomId, payload),
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'room_furniture',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) => _handleFurnitureRealtimeChange(roomId, payload),
    );

    channel.subscribe();
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
      'room_item_inventory_revisions_$roomId',
    );
    _roomInventoryRevisionChannel = channel;

    void refreshInventory() {
      if (!_furnitureMode || _roomId != roomId) {
        return;
      }
      unawaited(_loadFurnitureInventory());
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
      callback: (_) => refreshInventory(),
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
      callback: (_) => refreshInventory(),
    );

    channel.subscribe();
  }

  bool _isPlacedFurnitureSelected(_PlacedFurniture item) {
    return _selectedPlacedFurnitureId == item.id;
  }

  void _selectPlacedFurniture(_PlacedFurniture item) {
    _setStateForRoomDecor(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
    });
  }

  void _openFurnitureInventory() {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _dismissRoomDecorHint();
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    final selectionValid =
        _selectedEquipPetId != null &&
        pets.any((p) => p.petId == _selectedEquipPetId);
    _setStateForRoomDecor(() {
      _furnitureMode = true;
      _selectedFurnitureItemId = null;
      _selectedPlacedFurnitureId = null;
      if (!selectionValid) {
        _selectedEquipPetId = _petId;
        _panelEquippedItemsBySlot.clear();
      }
      _clearFurnitureDragGesture();
      _clearFurnitureScaleInteraction();
    });
    _furnitureWiggleController.repeat(reverse: true);
    _subscribeToRoomInventoryRevisions(roomId);
    unawaited(_loadFurnitureInventory());
    unawaited(_loadRoomFurniture(roomId));
    unawaited(_loadRoomBackgrounds(roomId));
    unawaited(_loadRoomBackgroundState(roomId));
    unawaited(_loadOwnedEquipment());
    unawaited(_loadPetEquipment(roomId: roomId, silent: true));
    unawaited(_loadPanelEquipmentForSelectedPet());
  }

  void _closeFurnitureInventory() {
    _setStateForRoomDecor(() {
      _furnitureMode = false;
      _selectedFurnitureItemId = null;
      _selectedPlacedFurnitureId = null;
      _clearFurnitureDragGesture();
      _clearFurnitureScaleInteraction();
    });
    _furnitureWiggleController.stop();
    _furnitureWiggleController.value = 0;
  }

  Future<void> _loadRoomBackgrounds(String roomId) async {
    if (_backgroundLoading) {
      return;
    }
    _setStateForRoomDecor(() => _backgroundLoading = true);
    try {
      await _ensureCurrentAppVersion();
      final response = await Supabase.instance.client
          .from('room_backgrounds')
          .select('item_id,items(*)')
          .eq('room_id', roomId);

      final items = <ShopItem>[];
      final unsupportedIds = <String>{};
      for (final row in response as List<dynamic>) {
        final record = row as Map<String, dynamic>;
        final itemData = record['items'] as Map<String, dynamic>?;
        if (itemData == null) {
          continue;
        }
        final item = ShopItem.fromJson(itemData);
        if (item.isBackground && _supportsBackgroundItem(item)) {
          items.add(item);
        } else if (item.isBackground) {
          final itemId = record['item_id'] as String?;
          if (itemId != null) {
            unsupportedIds.add(itemId);
          }
        }
      }

      if (!mounted || _roomId != roomId) {
        return;
      }
      _setStateForRoomDecor(() {
        _ownedBackgroundsByRoom[roomId] = items;
        _unsupportedBackgroundItemIdsByRoom[roomId] = unsupportedIds;
      });
      unawaited(_maybePromptForUnsupportedRoomDecor(roomId));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setStateForRoomDecor(() {
        _backgroundError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        _setStateForRoomDecor(() => _backgroundLoading = false);
      } else {
        _backgroundLoading = false;
      }
    }
  }

  Future<void> _loadRoomBackgroundState(String roomId) async {
    try {
      final response = await Supabase.instance.client
          .from('room_background_state')
          .select('active_item_id')
          .eq('room_id', roomId)
          .maybeSingle();

      final activeItemId = response?['active_item_id'] as String?;
      if (!mounted || _roomId != roomId) {
        return;
      }
      _setStateForRoomDecor(() {
        _activeBackgroundByRoom[roomId] = activeItemId;
      });
      unawaited(_maybePromptForUnsupportedRoomDecor(roomId));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setStateForRoomDecor(() {
        _backgroundError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    }
  }

  void _subscribeToBackgrounds(String roomId) {
    if (_backgroundSubscriptionRoomId == roomId) {
      return;
    }

    final previousStateChannel = _backgroundStateChannel;
    final previousInventoryChannel = _backgroundInventoryChannel;
    _backgroundStateChannel = null;
    _backgroundInventoryChannel = null;
    unawaited(_removeRealtimeChannel(previousStateChannel));
    unawaited(_removeRealtimeChannel(previousInventoryChannel));
    _backgroundSubscriptionRoomId = roomId;

    final stateChannel = Supabase.instance.client.channel(
      'room_background_state_$roomId',
    );
    _backgroundStateChannel = stateChannel;
    stateChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_background_state',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgroundState(roomId)),
    );
    stateChannel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'room_background_state',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgroundState(roomId)),
    );
    stateChannel.subscribe();

    final inventoryChannel = Supabase.instance.client.channel(
      'room_backgrounds_$roomId',
    );
    _backgroundInventoryChannel = inventoryChannel;
    inventoryChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'room_backgrounds',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgrounds(roomId)),
    );
    inventoryChannel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'room_backgrounds',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => unawaited(_loadRoomBackgrounds(roomId)),
    );
    inventoryChannel.subscribe();
  }

  List<ShopItem> _ownedBackgroundsForRoom(String roomId) {
    return _ownedBackgroundsByRoom[roomId] ?? const [];
  }

  Future<void> _applyRoomBackground(String itemId) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    final owned = _ownedBackgroundsForRoom(roomId);
    if (!owned.any((item) => item.id == itemId)) {
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    _setStateForRoomDecor(() => _backgroundApplyingItemId = itemId);
    try {
      await Supabase.instance.client.from('room_background_state').upsert({
        'room_id': roomId,
        'active_item_id': itemId,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _activeBackgroundByRoom[roomId] = itemId;
    } finally {
      if (mounted) {
        _setStateForRoomDecor(() => _backgroundApplyingItemId = null);
      } else {
        _backgroundApplyingItemId = null;
      }
    }
  }

  RoomBackgroundDefinition _currentBackgroundDefinition() {
    final roomId = _roomId;
    if (roomId == null) {
      return RoomBackgrounds.resolve(null);
    }
    final activeItemId = _activeBackgroundByRoom[roomId];
    if (activeItemId == null) {
      return RoomBackgrounds.resolve(null);
    }
    final items = _ownedBackgroundsByRoom[roomId];
    if (items == null) {
      return RoomBackgrounds.resolve(null);
    }
    ShopItem? activeItem;
    for (final item in items) {
      if (item.id == activeItemId) {
        activeItem = item;
        break;
      }
    }
    return RoomBackgrounds.resolve(activeItem?.backgroundKey);
  }

  Future<void> _maybePromptForUnsupportedRoomDecor(String roomId) async {
    if (!mounted || _roomId != roomId || _decorCompatibilityPromptShowing) {
      return;
    }
    final promptState = SharedDecorCompatibility.promptState(
      unsupportedPetType: _unsupportedPetTypesByRoom[roomId],
      unsupportedBackgroundItemIds:
          _unsupportedBackgroundItemIdsByRoom[roomId] ?? const <String>{},
      activeBackgroundItemId: _activeBackgroundByRoom[roomId],
      unsupportedPlacedFurnitureCount:
          _unsupportedPlacedFurnitureCountByRoom[roomId] ?? 0,
    );
    if (!promptState.shouldPrompt) {
      return;
    }
    final promptKey = promptState.keyFor(
      roomId: roomId,
      appVersion: _currentAppVersion,
    );
    if (_shownDecorCompatibilityPromptKeys.contains(promptKey)) {
      return;
    }
    _shownDecorCompatibilityPromptKeys.add(promptKey);
    _decorCompatibilityPromptShowing = true;
    final config = await AppConfigService().fetchForceUpdateConfig();
    final storeUrl = config?.storeUrl ?? AppConfigService.iosAppStoreUrl;
    if (!mounted || _roomId != roomId) {
      _decorCompatibilityPromptShowing = false;
      return;
    }
    try {
      await showAppDialog<void>(
        context: context,
        builder: (dialogContext) => AppDialog(
          tone: AppDialogTone.info,
          title: AppLocalizations.of(
            dialogContext,
          )!.roomDecorCompatibilityTitle,
          message: AppLocalizations.of(
            dialogContext,
          )!.roomDecorCompatibilityMessage,
          actions: [
            AppDialogAction.secondary(
              label: AppLocalizations.of(dialogContext)!.commonClose,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppDialogAction.primary(
              label: AppLocalizations.of(dialogContext)!.forceUpdateAction,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_launchCompatibilityUpdate(storeUrl));
              },
            ),
          ],
        ),
      );
    } finally {
      _decorCompatibilityPromptShowing = false;
    }
  }

  Future<void> _launchCompatibilityUpdate(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showJuiceToast(
          context: context,
          message: AppLocalizations.of(context)!.forceUpdateLinkError,
          tone: AppDialogTone.danger,
        );
      }
    } catch (_) {}
  }

  SystemUiOverlayStyle _currentOverlayStyle() {
    // Room selection and loading screens use light background themes.
    if (_showRoomSelection || _loadingRoom || _roomEntryLoading) {
      return AppStatusBarStyles.light;
    }
    final isDark = _currentBackgroundDefinition().isDark;
    return AppStatusBarStyles.forBackground(isDark: isDark);
  }

  void _placeFurnitureAt(Offset localPosition, Size fieldSize) {
    final itemId = _selectedFurnitureItemId;
    if (itemId == null) {
      return;
    }
    final item = _furnitureCatalog[itemId];
    if (item == null) {
      return;
    }
    if (_availableFurnitureCount(itemId) <= 0) {
      return;
    }

    // Plan A: store a canvas center fraction (device-independent) plus a legacy
    // top-left fraction so old app versions still render the piece.
    final content = RoomCanvas.contentRect(fieldSize);
    final itemSize = RoomCanvas.furnitureSize(content, 1.0);
    final canvasPosition = RoomCanvas.clampCenterFraction(
      centerFraction: RoomCanvas.centerFractionFromCenter(
        center: localPosition,
        content: content,
      ),
      content: content,
      itemSize: itemSize,
    );
    final normalized = RoomCanvas.legacyPositionFromCenterFraction(
      canvasPosition,
    );

    final placed = _PlacedFurniture(
      id: 'f_${_furnitureInstanceSeed++}',
      itemId: itemId,
      ownerUserId: Supabase.instance.client.auth.currentUser?.id,
      emoji: item.emoji ?? '🪑',
      assetPath: item.furnitureAssetPath,
      normalizedPosition: normalized,
      persistedNormalizedPosition: normalized,
      canvasPosition: canvasPosition,
      persistedCanvasPosition: canvasPosition,
      scale: 1.0,
      persistedScale: 1.0,
      flipX: false,
      persistedFlipX: false,
      isPending: true,
    );

    _setStateForRoomDecor(() {
      _activeFurnitureForRoom().add(placed);
      _selectedPlacedFurnitureId = placed.id;
    });
    unawaited(_persistFurniturePlacement(placed));
  }

  void _autoPlaceFurnitureFromInventory(String itemId) {
    final fieldSize = _petFieldSize();
    if (fieldSize == null) {
      return;
    }
    final jitterX = (_random.nextDouble() - 0.5) * 40;
    final jitterY = (_random.nextDouble() - 0.5) * 40;
    final center = Offset(
      fieldSize.width / 2 + jitterX,
      fieldSize.height / 2 + jitterY,
    );
    _placeFurnitureAt(center, fieldSize);
  }

  _PlacedFurniture? _selectedPlacedFurniture() {
    final selectedId = _selectedPlacedFurnitureId;
    if (selectedId == null) {
      return null;
    }
    for (final item in _activeFurnitureForRoom()) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  void _clearFurnitureDragGesture() {
    _activeFurnitureDragId = null;
    _activeFurnitureDragStartCanvasPosition = null;
    _flushPendingFurnitureReload();
  }

  void _handleFurnitureDragStart(_PlacedFurniture item) {
    final startCanvas = _canvasCenterFraction(item);
    _setStateForRoomDecor(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      _activeFurnitureDragId = item.id;
      item.canvasPosition = startCanvas;
      _activeFurnitureDragStartCanvasPosition = startCanvas;
    });
  }

  void _handleFurnitureDragUpdate(
    _PlacedFurniture item,
    DragUpdateDetails details,
    Rect content,
  ) {
    if (_activeFurnitureDragId != item.id) {
      return;
    }
    final itemSize = RoomCanvas.furnitureSize(content, item.scale);
    final current = _canvasCenterFraction(item);
    final currentCenter = Offset(
      content.left + current.dx * content.width,
      content.top + current.dy * content.height,
    );
    final nextCanvas = RoomCanvas.clampCenterFraction(
      centerFraction: RoomCanvas.centerFractionFromCenter(
        center: currentCenter + details.delta,
        content: content,
      ),
      content: content,
      itemSize: itemSize,
    );

    _setStateForRoomDecor(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      item.canvasPosition = nextCanvas;
      item.normalizedPosition = RoomCanvas.legacyPositionFromCenterFraction(
        nextCanvas,
      );
    });
  }

  void _handleFurnitureDragEnd(_PlacedFurniture item) {
    if (_activeFurnitureDragId != item.id) {
      return;
    }

    final startPosition = _activeFurnitureDragStartCanvasPosition;
    _clearFurnitureDragGesture();
    if (item.isPending || startPosition == null) {
      return;
    }
    final positionChanged =
        (_canvasCenterFraction(item) - startPosition).distance > 0.001;
    if (!positionChanged) {
      return;
    }
    unawaited(_persistFurnitureTransform(item));
  }

  void _handleFurnitureDragCancel() {
    _clearFurnitureDragGesture();
  }

  void _beginFurnitureScaleInteraction(_PlacedFurniture item) {
    _activeFurnitureScaleInteractionItemId = item.id;
    _activeFurnitureScaleInteractionStartScale = item.scale;
    _activeFurnitureScaleInteractionStartCanvasPosition = _canvasCenterFraction(
      item,
    );
  }

  void _clearFurnitureScaleInteraction() {
    _activeFurnitureScaleInteractionItemId = null;
    _activeFurnitureScaleInteractionStartScale = null;
    _activeFurnitureScaleInteractionStartCanvasPosition = null;
    _flushPendingFurnitureReload();
  }

  void _applyFurnitureScale(
    _PlacedFurniture item,
    double nextScale, {
    bool persist = false,
  }) {
    final fieldSize = _petFieldSize();
    if (fieldSize == null) {
      return;
    }
    final content = RoomCanvas.contentRect(fieldSize);
    final roundedScale = roundRoomFurnitureScaleToStep(nextScale);
    final nextSize = RoomCanvas.furnitureSize(content, roundedScale);
    // Anchored at the item center, so scaling keeps the center fixed; only
    // re-clamp so a larger piece stays fully inside the canvas.
    final nextCanvas = RoomCanvas.clampCenterFraction(
      centerFraction: _canvasCenterFraction(item),
      content: content,
      itemSize: nextSize,
    );
    _setStateForRoomDecor(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      item.scale = roundedScale;
      item.canvasPosition = nextCanvas;
      item.normalizedPosition = RoomCanvas.legacyPositionFromCenterFraction(
        nextCanvas,
      );
    });
    if (persist) {
      unawaited(_persistFurnitureTransform(item));
    }
  }

  void _stepSelectedFurnitureScale(int stepDelta) {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    final nextScale = nudgeRoomFurnitureScale(item.scale, stepDelta: stepDelta);
    if ((nextScale - item.scale).abs() <= 0.001) {
      return;
    }
    _applyFurnitureScale(item, nextScale, persist: true);
  }

  void _handleFurnitureScaleChangeStart(double _) {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    _beginFurnitureScaleInteraction(item);
  }

  void _handleFurnitureScaleChanged(double value) {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    if (_activeFurnitureScaleInteractionItemId != item.id) {
      _beginFurnitureScaleInteraction(item);
    }
    _applyFurnitureScale(item, value);
  }

  void _handleFurnitureScaleChangeEnd(double _) {
    final item = _selectedPlacedFurniture();
    final startItemId = _activeFurnitureScaleInteractionItemId;
    final startScale = _activeFurnitureScaleInteractionStartScale;
    final startPosition = _activeFurnitureScaleInteractionStartCanvasPosition;
    _clearFurnitureScaleInteraction();
    if (item == null ||
        item.isPending ||
        startItemId != item.id ||
        startScale == null ||
        startPosition == null) {
      return;
    }
    final scaleChanged = (item.scale - startScale).abs() > 0.001;
    final positionChanged =
        (_canvasCenterFraction(item) - startPosition).distance > 0.001;
    if (!scaleChanged && !positionChanged) {
      return;
    }
    unawaited(_persistFurnitureTransform(item));
  }

  void _toggleSelectedFurnitureFlip() {
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return;
    }
    final nextFlipX = !item.flipX;
    _setStateForRoomDecor(() {
      _selectedPlacedFurnitureId = item.id;
      _selectedFurnitureItemId = null;
      item.flipX = nextFlipX;
    });
    if (!item.isPending) {
      unawaited(_persistFurnitureFlip(item));
    }
  }

  Future<void> _persistFurniturePlacement(_PlacedFurniture item) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    final canvas = item.canvasPosition;
    try {
      Map<String, dynamic> response;
      try {
        response = await Supabase.instance.client
            .rpc(
              'place_room_furniture',
              params: {
                'p_room_id': roomId,
                'p_item_id': item.itemId,
                'p_position_x': item.normalizedPosition.dx,
                'p_position_y': item.normalizedPosition.dy,
                if (canvas != null) 'p_canvas_position_x': canvas.dx,
                if (canvas != null) 'p_canvas_position_y': canvas.dy,
              },
            )
            .single();
      } catch (error) {
        // Pre-migration safety: if the canvas-aware overload isn't deployed yet,
        // fall back to the legacy 4-arg placement.
        if (canvas != null &&
            _shouldFallbackToLegacyFurniturePlacement(error)) {
          response = await Supabase.instance.client
              .rpc(
                'place_room_furniture',
                params: {
                  'p_room_id': roomId,
                  'p_item_id': item.itemId,
                  'p_position_x': item.normalizedPosition.dx,
                  'p_position_y': item.normalizedPosition.dy,
                },
              )
              .single();
        } else {
          rethrow;
        }
      }

      final newId = response['id'] as String?;
      if (newId != null) {
        _markFurnitureWrite(newId);
      }
      final responseCanvas = _canvasOffsetFromRow(response);
      if (!mounted) {
        return;
      }
      _setStateForRoomDecor(() {
        final list = _activeFurnitureForRoom();
        final index = list.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          final previousId = list[index].id;
          final localScale = list[index].scale;
          final localPosition = list[index].normalizedPosition;
          final persistedPosition = list[index].persistedNormalizedPosition;
          final persistedScale = _parseFurnitureScale(response['scale']);
          final needsFollowUpPersist =
              (localScale - persistedScale).abs() > 0.001 ||
              (localPosition - persistedPosition).distance > 0.001;
          list[index]
            ..id = newId ?? list[index].id
            ..ownerUserId = response['owner_user_id'] as String?
            ..persistedScale = persistedScale
            ..persistedNormalizedPosition = persistedPosition
            ..persistedCanvasPosition =
                responseCanvas ?? list[index].canvasPosition
            ..isPending = false;
          list[index].scale = needsFollowUpPersist
              ? localScale
              : persistedScale;
          if (_selectedPlacedFurnitureId == previousId) {
            _selectedPlacedFurnitureId = list[index].id;
          }
          if (needsFollowUpPersist) {
            unawaited(_persistFurnitureTransform(list[index]));
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setStateForRoomDecor(() {
        _activeFurnitureForRoom().removeWhere((entry) => entry.id == item.id);
        _furnitureError = AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error));
      });
    }
  }

  Future<void> _persistFurnitureTransform(_PlacedFurniture item) async {
    if (item.isPending) {
      return;
    }
    _markFurnitureWrite(item.id);
    try {
      final canvas = item.canvasPosition;
      final response = await Supabase.instance.client.rpc(
        'update_room_furniture_transform',
        params: {
          'p_id': item.id,
          'p_scale': item.scale,
          'p_position_x': item.normalizedPosition.dx,
          'p_position_y': item.normalizedPosition.dy,
          if (canvas != null) 'p_canvas_position_x': canvas.dx,
          if (canvas != null) 'p_canvas_position_y': canvas.dy,
        },
      );
      _applyPersistedFurnitureTransformResponse(item, response);
    } catch (error) {
      if (_shouldFallbackToLegacyFurnitureTransform(error)) {
        await _persistFurnitureTransformLegacy(item);
        return;
      }
      if (mounted) {
        _setStateForRoomDecor(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
        });
      }
      final roomId = _roomId;
      if (roomId != null) {
        unawaited(_loadRoomFurniture(roomId));
      }
    }
  }

  Future<void> _persistFurnitureFlip(_PlacedFurniture item) async {
    if (item.isPending) {
      return;
    }
    _markFurnitureWrite(item.id);
    final requestedFlipX = item.flipX;
    try {
      final response = await Supabase.instance.client.rpc(
        'update_room_furniture_flip',
        params: {'p_id': item.id, 'p_flip_x': requestedFlipX},
      );
      final row = _coerceFurnitureTransformResponse(response);
      final persistedFlipX = row == null
          ? requestedFlipX
          : row['flip_x'] == true;
      if (!mounted) {
        item
          ..flipX = persistedFlipX
          ..persistedFlipX = persistedFlipX;
        return;
      }
      _setStateForRoomDecor(() {
        item
          ..flipX = persistedFlipX
          ..persistedFlipX = persistedFlipX;
      });
    } catch (error) {
      if (mounted) {
        _setStateForRoomDecor(() {
          item.flipX = item.persistedFlipX;
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
        });
      }
      final roomId = _roomId;
      if (roomId != null) {
        unawaited(_loadRoomFurniture(roomId));
      }
    }
  }

  Future<void> _persistFurnitureTransformLegacy(_PlacedFurniture item) async {
    _markFurnitureWrite(item.id);
    try {
      final scaleResponse = await Supabase.instance.client.rpc(
        'update_room_furniture_scale',
        params: {'p_id': item.id, 'p_scale': item.scale},
      );
      final positionResponse = await Supabase.instance.client.rpc(
        'update_room_furniture_position',
        params: {
          'p_id': item.id,
          'p_position_x': item.normalizedPosition.dx,
          'p_position_y': item.normalizedPosition.dy,
        },
      );
      _applyPersistedFurnitureTransformResponse(
        item,
        positionResponse,
        fallbackResponse: scaleResponse,
      );
    } catch (error) {
      if (mounted) {
        _setStateForRoomDecor(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
        });
      }
      final roomId = _roomId;
      if (roomId != null) {
        unawaited(_loadRoomFurniture(roomId));
      }
    }
  }

  void _applyPersistedFurnitureTransformResponse(
    _PlacedFurniture item,
    dynamic response, {
    dynamic fallbackResponse,
  }) {
    final row =
        _coerceFurnitureTransformResponse(response) ??
        _coerceFurnitureTransformResponse(fallbackResponse);
    final nextScale = _parseFurnitureScale(row?['scale'] ?? item.scale);
    final nextPosition = row == null
        ? item.normalizedPosition
        : Offset(
            (row['position_x'] as num?)?.toDouble() ??
                item.normalizedPosition.dx,
            (row['position_y'] as num?)?.toDouble() ??
                item.normalizedPosition.dy,
          );
    final nextCanvas = _canvasOffsetFromRow(row);

    if (!mounted) {
      item
        ..scale = nextScale
        ..normalizedPosition = nextPosition
        ..persistedScale = nextScale
        ..persistedNormalizedPosition = nextPosition;
      if (nextCanvas != null) {
        item
          ..canvasPosition = nextCanvas
          ..persistedCanvasPosition = nextCanvas;
      } else {
        item.persistedCanvasPosition = item.canvasPosition;
      }
      return;
    }

    _setStateForRoomDecor(() {
      item
        ..scale = nextScale
        ..normalizedPosition = nextPosition
        ..persistedScale = nextScale
        ..persistedNormalizedPosition = nextPosition;
      if (nextCanvas != null) {
        item
          ..canvasPosition = nextCanvas
          ..persistedCanvasPosition = nextCanvas;
      } else {
        item.persistedCanvasPosition = item.canvasPosition;
      }
    });
  }

  Future<void> _removeFurniture(_PlacedFurniture item) async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _setStateForRoomDecor(() {
      _activeFurnitureForRoom().removeWhere((entry) => entry.id == item.id);
      if (_selectedPlacedFurnitureId == item.id) {
        _selectedPlacedFurnitureId = null;
      }
    });

    if (item.isPending) {
      return;
    }

    _markFurnitureWrite(item.id);
    try {
      await Supabase.instance.client.rpc(
        'remove_room_furniture',
        params: {'p_id': item.id},
      );
    } catch (error) {
      if (mounted) {
        _setStateForRoomDecor(() {
          _furnitureError = AppLocalizations.of(
            context,
          )!.shopLoadFailed(userFacingError(context, error));
        });
      }
      unawaited(_loadRoomFurniture(roomId));
    }
  }
}
