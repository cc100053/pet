import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_sockets.dart';

void main() {
  test('validates supported equipment slots', () {
    expect(PetEquipmentSlot.isValid(PetEquipmentSlot.head), isTrue);
    expect(PetEquipmentSlot.isValid(PetEquipmentSlot.body), isTrue);
    expect(PetEquipmentSlot.isValid(PetEquipmentSlot.back), isTrue);
    expect(PetEquipmentSlot.isValid('tail'), isFalse);
  });

  test('resolves base and overridden ghost head sockets', () {
    final ghost = PetSocketCatalog.forPet('ghost');

    expect(ghost, isNotNull);
    expect(
      ghost!.resolve(PetEquipmentSlot.head),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.50)
          .having((socket) => socket.y, 'y', 0.23),
    );
    expect(
      ghost.resolve(PetEquipmentSlot.head, isWalking: true),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.50)
          .having((socket) => socket.y, 'y', 0.24),
    );
    expect(
      ghost.resolve(PetEquipmentSlot.head, isSleeping: true),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.50)
          .having((socket) => socket.y, 'y', 0.28),
    );
    expect(ghost.resolve('missing_slot'), isNull);
  });
}
