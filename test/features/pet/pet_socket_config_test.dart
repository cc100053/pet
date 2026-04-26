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

  test('resolves Godot-authored head sockets for every current pet state', () {
    final cat = PetSocketCatalog.forPet('cat')!;
    final fish = PetSocketCatalog.forPet('fish')!;
    final tiger = PetSocketCatalog.forPet('tiger')!;

    expect(
      cat.resolve(PetEquipmentSlot.head),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.448888889)
          .having((socket) => socket.y, 'y', 0.155555556),
    );
    expect(
      fish.resolve(PetEquipmentSlot.head, isWalking: true),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.477777778)
          .having((socket) => socket.y, 'y', 0.135555556),
    );
    expect(
      tiger.resolve(PetEquipmentSlot.head, isSleeping: true),
      isA<PetSocket>()
          .having((socket) => socket.x, 'x', 0.315555556)
          .having((socket) => socket.y, 'y', 0.38),
    );
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

  test('samples walk and sleep motion tracks from exported socket JSON', () {
    final cat = PetSocketCatalog.forPet('cat')!;
    final tiger = PetSocketCatalog.forPet('tiger')!;

    expect(
      cat.resolveMotion(
        slot: PetEquipmentSlot.head,
        animationProgress: 300 / 1200,
        isWalking: true,
      ),
      const Offset(-0.046666667, -0.004444444),
    );
    expect(
      tiger.resolveMotion(
        slot: PetEquipmentSlot.head,
        animationProgress: 300 / 1100,
        isSleeping: true,
      ),
      const Offset(-0.028888889, 0),
    );
  });

  test('timed motion tracks follow frame durations', () {
    final track = PetMotionTrack.timed(
      frames: const [Offset.zero, Offset(1, 0), Offset(2, 0)],
      frameDurationsMs: const [500, 200, 100],
    );

    expect(track.sample(499 / 800), Offset.zero);
    expect(track.sample(500 / 800), const Offset(1, 0));
    expect(track.sample(700 / 800), const Offset(2, 0));
    expect(track.sample(1), const Offset(2, 0));
  });
}
