part of 'home_view.dart';

/// Pet-equipment domain for [_HomeViewState]: loading owned/equipped items,
/// equip/unequip RPCs, realtime subscription, and slot localization.
/// Extracted from home_view.dart verbatim (behavior-preserving).
extension _HomeEquipment on _HomeViewState {
  Future<void> _loadPetEquipment({
    String? petId,
    String? roomId,
    bool silent = false,
    bool isRecoveryAttempt = false,
  }) async {
    final resolvedPetId = petId ?? _petId;
    final expectedRoomId = roomId ?? _roomId;
    if (resolvedPetId == null || expectedRoomId == null) {
      if (!silent && mounted) {
        _setStateForEquipment(() {
          _equipmentLoading = false;
          _equipmentError = null;
          _equippedItemsBySlot.clear();
        });
      } else {
        _equippedItemsBySlot.clear();
      }
      return;
    }

    if (!silent && mounted) {
      _setStateForEquipment(() {
        _equipmentLoading = true;
        _equipmentError = null;
      });
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'get_pet_equipment',
        params: {'p_pet_id': resolvedPetId, 'p_room_id': expectedRoomId},
      );
      final equipped = <String, _EquippedPetItem>{};
      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final slot = row['slot'] as String?;
        final itemId = row['item_id'] as String?;
        final sku = row['item_sku'] as String?;
        if (slot == null || itemId == null || sku == null) {
          continue;
        }
        equipped[slot] = _EquippedPetItem(itemId: itemId, sku: sku);
      }
      _precacheEquippedAssets(equipped.values.map((item) => item.sku));
      if (!mounted) {
        _equippedItemsBySlot
          ..clear()
          ..addAll(equipped);
        _roomEquippedSkusBySlot[expectedRoomId] = _equippedSkusFromItemsBySlot(
          equipped,
        );
        _equipmentLoading = false;
        return;
      }
      if (_roomId != expectedRoomId ||
          (_petId != null && _petId != resolvedPetId)) {
        return;
      }
      _setStateForEquipment(() {
        _equippedItemsBySlot
          ..clear()
          ..addAll(equipped);
        _roomEquippedSkusBySlot[expectedRoomId] = _equippedSkusFromItemsBySlot(
          equipped,
        );
      });
    } catch (error) {
      // A stale / cross-room active `_petId` (e.g. a poisoned warm cache) makes
      // `get_pet_equipment` raise `pet_not_found`, because the pet isn't a
      // member of this room. Re-resolve the room's real main pet once and retry
      // instead of surfacing a scary error. Mirrors the `pet_not_found`
      // recovery in `_showMainPetSwitcher`.
      if (!isRecoveryAttempt &&
          mounted &&
          _roomId == expectedRoomId &&
          _petId == resolvedPetId &&
          _isPetNotFound(error)) {
        final recovered = await _recoverActivePetId(
          expectedRoomId,
          resolvedPetId,
        );
        if (recovered != null) {
          await _loadPetEquipment(
            petId: recovered,
            roomId: expectedRoomId,
            silent: silent,
            isRecoveryAttempt: true,
          );
          return;
        }
      }
      if (!mounted) {
        _equipmentError = error.toString();
        _equipmentLoading = false;
        return;
      }
      _setStateForEquipment(() {
        _equipmentError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (!silent) {
        if (mounted) {
          _setStateForEquipment(() => _equipmentLoading = false);
        } else {
          _equipmentLoading = false;
        }
      }
    }
  }

  bool _isPetNotFound(Object error) {
    if (error is PostgrestException) {
      return error.message.contains('pet_not_found');
    }
    return error.toString().contains('pet_not_found');
  }

  /// Recovers from an active-pet `pet_not_found`: the seeded/cached `_petId`
  /// belongs to another room, so evict the poisoned warm cache and repoint the
  /// active pet at the room's authoritative main pet (`rooms.main_pet_id` via
  /// [_loadPetId]). Also refreshes the (wrong) name/level/type and the realtime
  /// subscription so the whole pet identity is corrected, not just equipment.
  /// Returns the recovered pet id, or null when nothing better could be
  /// resolved (so the caller should not retry).
  Future<String?> _recoverActivePetId(String roomId, String stalePetId) async {
    // Drop the poisoned per-room warm cache so it can't re-seed the bad id on
    // the next entry (and so the persisted bootstrap snapshot is cleaned too).
    if (_petIdByRoom[roomId] == stalePetId) {
      _petIdByRoom.remove(roomId);
      _petStateByRoom.remove(roomId);
    }
    String? mainPetId;
    try {
      mainPetId = await _loadPetId(roomId);
    } catch (_) {
      return null;
    }
    if (mainPetId == null || mainPetId == stalePetId) {
      return null;
    }
    // Bail if the user moved on (or the active pet already changed) mid-flight.
    if (!mounted || _roomId != roomId || _petId != stalePetId) {
      return null;
    }
    final recoveredPetId = mainPetId;
    _petSubscriptionPetId = null;
    _setStateForEquipment(() {
      _petId = recoveredPetId;
      _petState = null;
      _petStateReady = false;
    });
    unawaited(_loadPetInfo(recoveredPetId, roomId: roomId));
    _subscribeToPetState(recoveredPetId);
    return recoveredPetId;
  }

  // Loads the equipment of the panel's selected pet into _panelEquippedItemsBySlot.
  // No-op when the selected target is the main pet (it reuses _equippedItemsBySlot).
  Future<void> _loadPanelEquipmentForSelectedPet() async {
    final petId = _selectedEquipPetId;
    final roomId = _roomId;
    if (petId == null || roomId == null || petId == _petId) {
      return;
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'get_pet_equipment',
        params: {'p_pet_id': petId, 'p_room_id': roomId},
      );
      final equipped = <String, _EquippedPetItem>{};
      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final slot = row['slot'] as String?;
        final itemId = row['item_id'] as String?;
        final sku = row['item_sku'] as String?;
        if (slot == null || itemId == null || sku == null) {
          continue;
        }
        equipped[slot] = _EquippedPetItem(itemId: itemId, sku: sku);
      }
      _precacheEquippedAssets(equipped.values.map((item) => item.sku));
      // Bail if the target moved while the request was in flight.
      if (!mounted || _roomId != roomId || _selectedEquipPetId != petId) {
        return;
      }
      _setStateForEquipment(() {
        _panelEquippedItemsBySlot
          ..clear()
          ..addAll(equipped);
      });
    } catch (_) {
      // Best-effort: the panel falls back to an empty equipped state.
    }
  }

  // Loads every room pet's equipment in one query so each pet (main + extras)
  // can render its own gear on screen and in the equipment selector.
  Future<void> _loadAllPetEquipment(String roomId) async {
    try {
      final rows = await Supabase.instance.client
          .from('pet_equipment')
          .select('pet_id, slot, items(sku)')
          .eq('room_id', roomId);
      final map = <String, Map<String, String>>{};
      for (final row in rows) {
        final petId = row['pet_id'] as String?;
        final slot = row['slot'] as String?;
        final items = row['items'];
        if (petId == null || slot == null || items is! Map) {
          continue;
        }
        final sku = items['sku'] as String?;
        if (sku == null) {
          continue;
        }
        (map[petId] ??= <String, String>{})[slot] = sku;
      }
      for (final skus in map.values) {
        _precacheEquippedAssets(skus.values);
      }
      if (!mounted || _roomId != roomId) {
        return;
      }
      _setStateForEquipment(() {
        _equippedSkusByPetId
          ..clear()
          ..addAll(map);
      });
    } catch (_) {
      // Best-effort: pets fall back to rendering without gear.
    }
  }

  List<RoomPetOption> _equipPetOptionsForRoom(String? roomId) {
    if (roomId == null) {
      return const <RoomPetOption>[];
    }
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    return pets
        .map(
          (pet) => RoomPetOption(
            petId: pet.petId,
            petType: pet.petType,
            isMain: pet.isMain,
            name: pet.name,
            equippedSkusBySlot:
                _equippedSkusByPetId[pet.petId] ?? const <String, String>{},
          ),
        )
        .toList(growable: false);
  }

  void _onSelectEquipPet(String petId) {
    if (_selectedEquipPetId == petId) {
      return;
    }
    _setStateForEquipment(() {
      _selectedEquipPetId = petId;
      if (petId != _petId) {
        _panelEquippedItemsBySlot.clear();
      }
    });
    unawaited(_loadPanelEquipmentForSelectedPet());
  }

  Future<void> _loadOwnedEquipment({bool silent = false}) async {
    final roomId = _roomId;
    if (Supabase.instance.client.auth.currentUser == null || roomId == null) {
      if (mounted) {
        _setStateForEquipment(() {
          _ownedEquipmentItems.clear();
          _equipmentLoading = false;
        });
      } else {
        _ownedEquipmentItems.clear();
      }
      return;
    }

    if (!silent && mounted) {
      _setStateForEquipment(() {
        _equipmentLoading = true;
        _equipmentError = null;
      });
    }

    try {
      final response = await Supabase.instance.client.rpc(
        'get_room_equipment_inventory',
        params: {'p_room_id': roomId},
      );
      final items = <ShopItem>[];
      final quantities = <String, int>{};
      for (final row in response as List<dynamic>) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final item = ShopItem.fromJson(row);
        if (!item.isEquipment) {
          continue;
        }
        if (!item.isSupportedOnAppVersion(_currentAppVersion)) {
          continue;
        }
        items.add(item);
        quantities[item.id] = (row['total_quantity'] as num?)?.toInt() ?? 0;
      }
      items.sort((a, b) => a.sku.compareTo(b.sku));
      if (!mounted) {
        _ownedEquipmentItems
          ..clear()
          ..addAll(items);
        _ownedEquipmentQtyById
          ..clear()
          ..addAll(quantities);
        _equipmentLoading = false;
        return;
      }
      _setStateForEquipment(() {
        _ownedEquipmentItems
          ..clear()
          ..addAll(items);
        _ownedEquipmentQtyById
          ..clear()
          ..addAll(quantities);
      });
    } catch (error) {
      if (!mounted) {
        _equipmentError = error.toString();
        _equipmentLoading = false;
        return;
      }
      _setStateForEquipment(() {
        _equipmentError = AppLocalizations.of(
          context,
        )!.shopLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (!silent) {
        if (mounted) {
          _setStateForEquipment(() => _equipmentLoading = false);
        } else {
          _equipmentLoading = false;
        }
      }
    }
  }

  void _subscribeToPetEquipment(String roomId) {
    if (_petEquipmentSubscriptionRoomId == roomId) {
      return;
    }

    final previousChannel = _petEquipmentChannel;
    _petEquipmentChannel = null;
    unawaited(_removeRealtimeChannel(previousChannel));
    _petEquipmentSubscriptionRoomId = roomId;

    final channel = Supabase.instance.client.channel('pet_equipment_$roomId');
    _petEquipmentChannel = channel;

    void refreshEquipment() {
      if (!mounted || _roomId != roomId) {
        return;
      }
      unawaited(_loadPetEquipment(roomId: roomId, silent: true));
      unawaited(_loadPanelEquipmentForSelectedPet());
      unawaited(_loadAllPetEquipment(roomId));
    }

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'pet_equipment',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (_) => refreshEquipment(),
    );

    channel.subscribe();
  }

  /// Free copies of [itemId] available to equip on another pet/slot: the
  /// room-owned quantity minus the copies already worn across all pets in the
  /// active room. Mirrors the capacity check inside the equip_pet_item RPC so
  /// the UI can dim fully-used items instead of failing with
  /// equipment_copy_unavailable.
  int _availableEquipmentCopies(String itemId) {
    final total = _ownedEquipmentQtyById[itemId] ?? 0;
    if (total <= 0) {
      return 0;
    }
    final sku = _ownedEquipmentItems
        .cast<ShopItem?>()
        .firstWhere((item) => item?.id == itemId, orElse: () => null)
        ?.sku;
    if (sku == null) {
      return total;
    }
    var equipped = 0;
    for (final skusBySlot in _equippedSkusByPetId.values) {
      if (skusBySlot.values.contains(sku)) {
        equipped++;
      }
    }
    return total - equipped;
  }

  Future<void> _equipItem(String itemId, String slot) async {
    final targetPetId = _selectedEquipPetId ?? _petId;
    final roomId = _roomId;
    if (targetPetId == null || roomId == null) {
      return;
    }
    final targetItem = _ownedEquipmentItems.cast<ShopItem?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
    String? targetPetType;
    for (final pet in _roomPetsByRoom[roomId] ?? const <_RoomPet>[]) {
      if (pet.petId == targetPetId) {
        targetPetType = pet.petType;
        break;
      }
    }
    if (targetPetType == null && targetPetId == _petId) {
      targetPetType = _petType;
    }
    if (targetItem != null &&
        targetPetType != null &&
        !EquipmentCatalog.isSkuCompatibleWithPet(
          targetItem.sku,
          targetPetType,
        )) {
      if (mounted) {
        showJuiceSnackbar(
          context: context,
          message: AppLocalizations.of(context)!.equipmentNotCompatible,
          tone: AppDialogTone.warning,
        );
      }
      return;
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'equip_pet_item',
        params: {
          'p_pet_id': targetPetId,
          'p_room_id': roomId,
          'p_item_id': itemId,
          'p_slot': slot,
        },
      );
      await _loadPetEquipment(roomId: roomId, silent: true);
      await _loadPanelEquipmentForSelectedPet();
      await _loadAllPetEquipment(roomId);
      if (!mounted) {
        return;
      }
      final itemName = targetItem?.localizedName(AppLocalizations.of(context)!);
      final responseMap = response is Map<String, dynamic>
          ? response
          : <String, dynamic>{};
      final fallbackSku = responseMap['item_sku'] as String?;
      showJuiceSnackbar(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.equipmentEquipSuccess(itemName ?? fallbackSku ?? ''),
        tone: AppDialogTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      // Refresh so the strip dims the now-unavailable copy if another member
      // grabbed the last one while this panel was open.
      unawaited(_loadAllPetEquipment(roomId));
      if (_isEquipmentCopyUnavailable(error)) {
        showJuiceSnackbar(
          context: context,
          message: AppLocalizations.of(context)!.equipmentCopyUnavailable,
          tone: AppDialogTone.warning,
        );
        return;
      }
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
  }

  bool _isEquipmentCopyUnavailable(Object error) {
    if (error is PostgrestException) {
      return error.message.contains('equipment_copy_unavailable');
    }
    return error.toString().contains('equipment_copy_unavailable');
  }

  Future<void> _unequipItem(String slot) async {
    final petId = _selectedEquipPetId ?? _petId;
    final roomId = _roomId;
    if (petId == null || roomId == null) {
      return;
    }
    try {
      await Supabase.instance.client.rpc(
        'unequip_pet_item',
        params: {'p_pet_id': petId, 'p_room_id': roomId, 'p_slot': slot},
      );
      await _loadPetEquipment(roomId: roomId, silent: true);
      await _loadPanelEquipmentForSelectedPet();
      await _loadAllPetEquipment(roomId);
      if (!mounted) {
        return;
      }
      showJuiceSnackbar(
        context: context,
        message: AppLocalizations.of(context)!.equipmentUnequipSuccess(
          _localizedEquipmentSlot(slot, AppLocalizations.of(context)!),
        ),
        tone: AppDialogTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.storePurchaseFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
  }

  String _localizedEquipmentSlot(String slot, AppLocalizations l10n) {
    switch (slot) {
      case PetEquipmentSlot.head:
        return l10n.equipmentSlotHead;
      case PetEquipmentSlot.face:
        return l10n.equipmentSlotFace;
      case PetEquipmentSlot.body:
        return l10n.equipmentSlotBody;
      case PetEquipmentSlot.back:
        return l10n.equipmentSlotBack;
    }
    return slot;
  }
}
