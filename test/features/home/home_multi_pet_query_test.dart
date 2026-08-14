import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home resolves room pet id through main_pet_id for multi-pet rooms', () {
    final source = File('lib/features/home/home_view.dart').readAsStringSync();
    final loadPetIdBody =
        RegExp(
          r'Future<String\?> _loadPetId\(String roomId\) async \{([\s\S]*?)\n  \}',
          multiLine: true,
        ).firstMatch(source)?.group(1) ??
        '';

    expect(loadPetIdBody, contains(".from('rooms')"));
    expect(loadPetIdBody, contains("select('main_pet_id')"));
    expect(loadPetIdBody, contains(".from('pets')"));
    expect(loadPetIdBody, contains(".limit(1)"));
    expect(
      loadPetIdBody,
      isNot(contains(".eq('room_id', roomId)\n        .maybeSingle()")),
    );
  });

  test('Home loads and renders additional room pets', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final sceneSource = File(
      'lib/features/home/home_view_pet_scene_builders.dart',
    ).readAsStringSync();

    expect(homeSource, contains("'get_room_pets'"));
    expect(homeSource, contains('_roomPetsByRoom'));
    expect(sceneSource, contains('_buildAdditionalRoomPets(fieldSize)'));
    expect(sceneSource, contains('!pet.isMain && pet.petId != _petId'));
    expect(sceneSource, contains('_buildRoomPetAvatar'));
  });

  test('Equip targets the persistently selected pet, not a per-tap picker', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    // The equipment domain lives in a `part` file of the home_view library.
    final equipmentSource = File(
      'lib/features/home/home_view_equipment.dart',
    ).readAsStringSync();
    final homeLibrarySource = homeSource + equipmentSource;
    final panelSource = File(
      'lib/features/home/widgets/home_room_inventory_panel.dart',
    ).readAsStringSync();
    // The old per-tap picker is gone; selection is persistent state instead.
    expect(homeLibrarySource, isNot(contains('_resolveEquipTargetPetId')));
    expect(homeLibrarySource, contains('_selectedEquipPetId'));
    expect(homeLibrarySource, contains('_onSelectEquipPet'));
    // The equip RPC must use the selected pet, not always _petId.
    expect(homeLibrarySource, contains("'p_pet_id': targetPetId,"));
    expect(
      homeLibrarySource,
      contains('final targetPetId = _selectedEquipPetId ?? _petId;'),
    );
    // The panel renders a persistent selector when the room has 2+ pets.
    expect(panelSource, contains('_EquipPetSelector'));
    expect(panelSource, contains('equipPets.length >= 2'));
  });

  test('Every room pet renders its own gear on screen and in the selector', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final sceneSource = File(
      'lib/features/home/home_view_pet_scene_builders.dart',
    ).readAsStringSync();
    // Per-pet equipment is loaded for the whole room.
    expect(homeSource, contains('_equippedSkusByPetId'));
    expect(homeSource, contains('_loadAllPetEquipment'));
    // Extras render their own gear instead of an empty map.
    expect(
      sceneSource,
      contains('_equippedSkusByPetId[pet.petId] ?? const {}'),
    );
    expect(sceneSource, isNot(contains('equippedSkusBySlot: const {},')));
  });

  test('Extra pets can be renamed directly via long-press', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final sceneSource = File(
      'lib/features/home/home_view_pet_scene_builders.dart',
    ).readAsStringSync();
    expect(homeSource, contains('_openPetNameEditor({_RoomPet? targetPet})'));
    expect(homeSource, contains("'update_pet_name'"));
    expect(sceneSource, contains('_openPetNameEditor(targetPet: pet)'));
  });

  test('Shop counts pets across both tables for equipment capacity', () {
    final shopSource = File(
      'lib/features/shop/shop_view.dart',
    ).readAsStringSync();
    // Pet count for equipment capacity must use get_room_pets (UNIONs pets +
    // room_extra_pets), not a raw count of the pets table (always 1).
    expect(shopSource, contains("'get_room_pets'"));
    expect(
      shopSource,
      isNot(
        contains(
          ".from('pets')\n            .select('id')\n            .eq('room_id', roomId)",
        ),
      ),
    );
  });

  test('Feed action summons all extra pets to the food location', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final feedSource = File(
      'lib/features/home/controllers/home_feed_orchestrator.dart',
    ).readAsStringSync();
    expect(homeSource, contains('_summonExtraPetsToFood'));
    expect(
      feedSource,
      contains('_summonExtraPetsToFood(foodTarget, fieldSize)'),
    );
    // Pet repulsion/collision avoidance was removed; pets may overlap freely.
    expect(homeSource, isNot(contains('_pickWanderTargetAvoiding')));
  });

  test('Background feed pet-info refreshes swallow transient failures', () {
    final feedSource = File(
      'lib/features/home/controllers/home_feed_orchestrator.dart',
    ).readAsStringSync();
    final unreadSource = File(
      'lib/features/home/controllers/home_unread_manager.dart',
    ).readAsStringSync();

    expect(
      feedSource,
      contains(
        'try {\n'
        '          final petId = await _loadPetId(refreshRoomId);',
      ),
    );
    expect(feedSource, contains('} catch (_) {'));
    expect(
      unreadSource,
      contains(
        'try {\n'
        '          final petId = _petId ?? await _loadPetId(roomId);',
      ),
    );
    expect(unreadSource, contains('} catch (_) {'));
  });

  test('Extra room pets are interactive (drag + tap name tag + wander)', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final sceneSource = File(
      'lib/features/home/home_view_pet_scene_builders.dart',
    ).readAsStringSync();

    expect(homeSource, contains('_ExtraPetRuntime'));
    expect(homeSource, contains('_handleExtraPetDragStart'));
    expect(homeSource, contains('_handleExtraPetDragUpdate'));
    expect(homeSource, contains('_handleExtraPetDragEnd'));
    expect(homeSource, contains('_showPetNameTag'));
    expect(homeSource, contains('_wanderExtraPetsIfIdle'));
    expect(sceneSource, contains('AnimatedPositioned'));
    expect(sceneSource, contains('onPanStart: (details) =>'));
    expect(sceneSource, contains('_buildPetNameTag'));
  });

  test('Extra pets animate walk/sleep/stay at full size like the main pet', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final sceneSource = File(
      'lib/features/home/home_view_pet_scene_builders.dart',
    ).readAsStringSync();
    // Avatar builder selects walk/sleep/stay assets from runtime state.
    expect(sceneSource, contains('petDefinition.walkAsset'));
    expect(sceneSource, contains('petDefinition.sleepAsset'));
    expect(sceneSource, contains('_buildRoomPetAvatar(pet, runtime'));
    // Full size (no 0.86 shrink factor).
    expect(
      sceneSource,
      contains('final size = _HomeViewState._petAvatarSize;'),
    );
    expect(sceneSource, isNot(contains('_petAvatarSize.width * 0.86')));
    // Walk state machine wired through arrival timer.
    expect(homeSource, contains('_beginExtraPetWalk'));
    expect(homeSource, contains('_pickStationaryStateForNow'));
  });

  test('Top-left avatar opens main-pet switcher when room has 2+ pets', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final sceneSource = File(
      'lib/features/home/home_view_pet_scene_builders.dart',
    ).readAsStringSync();
    expect(homeSource, contains('_showMainPetSwitcher'));
    expect(homeSource, contains("'set_room_main_pet'"));
    expect(sceneSource, contains('canSwitch ? () => _showMainPetSwitcher()'));
    // After switching, active pet must repoint to the promoted pet (not keep
    // the stale old-main _petId) and recover gracefully if the list was stale.
    expect(homeSource, contains('_petId = selectedId'));
    expect(homeSource, contains("error.toString().contains('pet_not_found')"));
  });

  test(
    'Room name follows the main pet (model B): no separate rename dialog',
    () {
      final homeSource = File(
        'lib/features/home/home_view.dart',
      ).readAsStringSync();
      // The two-name rename dialog is gone; room name mirrors the main pet
      // server-side via trigger + set_room_main_pet.
      expect(homeSource, isNot(contains('_maybeShowMultiPetNamingPrompt')));
      expect(homeSource, isNot(contains('_showMultiPetNamingDialog')));
      expect(homeSource, isNot(contains("'apply_multi_pet_room_naming'")));
    },
  );

  test('Room entry evicts a cross-room/stale warm pet cache', () {
    // Regression: a pet id persisted for a *different* room leaked into this
    // room's warm cache, so entering the room painted the wrong pet's name and
    // loaded equipment for a pet not in the room (get_pet_equipment ->
    // pet_not_found). _switchRoom must reconcile the cached id against the room
    // snapshot's authoritative main pet id and drop the cache when they differ.
    final roomManagerSource = File(
      'lib/features/home/controllers/home_room_manager.dart',
    ).readAsStringSync();

    final switchRoomBody =
        RegExp(
          r'void _switchRoom\([\s\S]*?\n  \}\n',
          multiLine: true,
        ).firstMatch(roomManagerSource)?.group(0) ??
        '';

    // The conflict check compares the cached id to the snapshot's main pet id.
    expect(switchRoomBody, contains('cachedPetId != snapshotPetId'));
    // ...and evicts both per-room caches so the poison cannot persist.
    expect(switchRoomBody, contains('_petIdByRoom.remove(roomId)'));
    expect(switchRoomBody, contains('_petStateByRoom.remove(roomId)'));
  });

  test('Equipment load self-heals a stale active pet id (pet_not_found)', () {
    // Defense-in-depth: if a cross-room/stale `_petId` slips through, the
    // active-pet equipment load gets `pet_not_found` from get_pet_equipment.
    // It must re-resolve the room's main pet (via _loadPetId), evict the
    // poisoned warm cache, repoint `_petId`, and retry once — not just show an
    // error. Mirrors the _showMainPetSwitcher recovery.
    final equipmentSource = File(
      'lib/features/home/home_view_equipment.dart',
    ).readAsStringSync();

    expect(equipmentSource, contains('_isPetNotFound(error)'));
    expect(equipmentSource, contains('_recoverActivePetId('));
    expect(equipmentSource, contains('isRecoveryAttempt: true'));
    // Recovery re-resolves the authoritative main pet and clears the poison.
    expect(equipmentSource, contains('await _loadPetId(roomId)'));
    expect(equipmentSource, contains('_petIdByRoom.remove(roomId)'));
    expect(equipmentSource, contains('_petStateByRoom.remove(roomId)'));
    // It must not retry forever, and only on a true main-pet change.
    expect(equipmentSource, contains('mainPetId == stalePetId'));
  });

  test('Home subscribes to pets/rooms realtime for the active room', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    final roomManagerSource = File(
      'lib/features/home/controllers/home_room_manager.dart',
    ).readAsStringSync();

    expect(homeSource, contains('_subscribeToRoomPets'));
    expect(homeSource, contains("channel('room_pets_"));
    expect(homeSource, contains("['pets', 'room_extra_pets']"));
    expect(homeSource, contains("table: 'rooms'"));
    // Room manager must not double-call _loadRoomPets; _refreshPetState
    // already triggers it.
    expect(
      roomManagerSource,
      isNot(contains('unawaited(_loadRoomPets(roomId));')),
    );
  });
}
