import 'dart:ui';

class PetEquipmentSlot {
  static const String head = 'head';
  static const String body = 'body';
  static const String back = 'back';

  static const List<String> values = [head, body, back];

  static bool isValid(String slot) => values.contains(slot);
}

class PetSocket {
  const PetSocket({required this.x, required this.y});

  final double x;
  final double y;

  Offset toOffset(Size size) => Offset(x * size.width, y * size.height);

  PetSocket flippedX() => PetSocket(x: 1 - x, y: y);
}

class PetSocketConfig {
  const PetSocketConfig({
    required this.petId,
    required this.sockets,
    this.walkOverrides = const <String, PetSocket>{},
    this.sleepOverrides = const <String, PetSocket>{},
  });

  final String petId;
  final Map<String, PetSocket> sockets;
  final Map<String, PetSocket> walkOverrides;
  final Map<String, PetSocket> sleepOverrides;

  PetSocket? resolve(
    String slot, {
    bool isWalking = false,
    bool isSleeping = false,
  }) {
    if (isWalking && walkOverrides.containsKey(slot)) {
      return walkOverrides[slot];
    }
    if (isSleeping && sleepOverrides.containsKey(slot)) {
      return sleepOverrides[slot];
    }
    return sockets[slot];
  }
}

class PetSocketCatalog {
  static const List<PetSocketConfig> configs = [
    PetSocketConfig(
      petId: 'ghost',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.23),
        PetEquipmentSlot.body: PetSocket(x: 0.50, y: 0.56),
        PetEquipmentSlot.back: PetSocket(x: 0.67, y: 0.43),
      },
      walkOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.24)},
      sleepOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.50, y: 0.28)},
    ),
    PetSocketConfig(
      petId: 'cat',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.52, y: 0.18),
        PetEquipmentSlot.body: PetSocket(x: 0.50, y: 0.52),
        PetEquipmentSlot.back: PetSocket(x: 0.68, y: 0.41),
      },
      walkOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.53, y: 0.19)},
      sleepOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.56, y: 0.32)},
    ),
    PetSocketConfig(
      petId: 'fish',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.48, y: 0.23),
        PetEquipmentSlot.body: PetSocket(x: 0.50, y: 0.52),
        PetEquipmentSlot.back: PetSocket(x: 0.69, y: 0.44),
      },
      walkOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.47, y: 0.24)},
      sleepOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.44, y: 0.31)},
    ),
    PetSocketConfig(
      petId: 'tiger',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.52, y: 0.17),
        PetEquipmentSlot.body: PetSocket(x: 0.52, y: 0.50),
        PetEquipmentSlot.back: PetSocket(x: 0.69, y: 0.39),
      },
      walkOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.53, y: 0.18)},
      sleepOverrides: {PetEquipmentSlot.head: PetSocket(x: 0.56, y: 0.31)},
    ),
  ];

  static PetSocketConfig? forPet(String petId) {
    for (final config in configs) {
      if (config.petId == petId) {
        return config;
      }
    }
    return null;
  }
}
