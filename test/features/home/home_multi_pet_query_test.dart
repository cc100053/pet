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

  test('Equip action prompts pet picker when room has 2+ pets', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    expect(homeSource, contains('_resolveEquipTargetPetId'));
    expect(homeSource, contains('equipTargetPickerTitle'));
    // The equip RPC must use the picker's chosen pet, not always _petId.
    expect(
      homeSource,
      contains("'p_pet_id': targetPetId,"),
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
    expect(homeSource, contains('_pickWanderTargetAvoiding'));
    expect(feedSource, contains('_summonExtraPetsToFood(foodTarget, fieldSize)'));
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
    expect(sceneSource, contains('final size = _HomeViewState._petAvatarSize;'));
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
  });

  test('First 1->2 pet transition prompts room rename + first-pet name', () {
    final homeSource = File(
      'lib/features/home/home_view.dart',
    ).readAsStringSync();
    expect(homeSource, contains('_maybeShowMultiPetNamingPrompt'));
    expect(homeSource, contains("'apply_multi_pet_room_naming'"));
    expect(homeSource, contains('multiPetNamingTitle'));
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
