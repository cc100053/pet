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
}
