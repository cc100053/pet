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
          .having((socket) => socket.x, 'x', 0.484444444)
          .having((socket) => socket.y, 'y', 0.131111111),
    );
    expect(
      ghost.resolve(PetEquipmentSlot.head, isWalking: true),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.484444444)
          .having((socket) => socket.y, 'y', 0.131111111),
    );
    expect(
      ghost.resolve(PetEquipmentSlot.head, isSleeping: true),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.484444444)
          .having((socket) => socket.y, 'y', 0.131111111),
    );
    expect(
      ghost.resolve(PetEquipmentSlot.body),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.444444444)
          .having((socket) => socket.y, 'y', 0.462222222),
    );
    expect(
      ghost.resolve(PetEquipmentSlot.back),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.762222222)
          .having((socket) => socket.y, 'y', 0.466666667),
    );
    expect(ghost.resolve('missing_slot'), isNull);
  });

  test('samples ghost idle motion from PNG-derived track', () {
    final ghost = PetSocketCatalog.forPet('ghost');

    expect(ghost, isNotNull);
    expect(
      ghost!.resolveMotion(slot: PetEquipmentSlot.head, animationProgress: 0),
      Offset.zero,
    );
    expect(
      ghost.resolveMotion(
        slot: PetEquipmentSlot.head,
        animationProgress: 1 / 26,
      ),
      Offset.zero,
    );
    expect(
      ghost.resolveMotion(
        slot: PetEquipmentSlot.head,
        animationProgress: 2 / 26,
      ),
      const Offset(0, -0.002222222),
    );
    expect(
      ghost.resolveMotion(
        slot: PetEquipmentSlot.head,
        animationProgress: 2 / 26,
        isWalking: true,
      ),
      Offset.zero,
    );
  });
}
