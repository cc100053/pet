import 'dart:ui';

enum PetMotionSampling { linear, stepped }

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

class PetMotionTrack {
  const PetMotionTrack({
    required this.frames,
    this.sampling = PetMotionSampling.linear,
  });

  factory PetMotionTrack.repeated({
    required List<Offset> frames,
    required int hold,
    PetMotionSampling sampling = PetMotionSampling.stepped,
  }) {
    if (hold <= 0) {
      throw ArgumentError.value(hold, 'hold', 'Must be greater than zero.');
    }
    final expanded = <Offset>[];
    for (final frame in frames) {
      for (var i = 0; i < hold; i++) {
        expanded.add(frame);
      }
    }
    return PetMotionTrack(frames: expanded, sampling: sampling);
  }

  final List<Offset> frames;
  final PetMotionSampling sampling;

  Offset sample(double progress) {
    if (frames.isEmpty) {
      return Offset.zero;
    }
    if (frames.length == 1) {
      return frames.first;
    }

    final clamped = progress.clamp(0.0, 1.0);
    if (sampling == PetMotionSampling.stepped) {
      final index = (clamped * frames.length).floor().clamp(
        0,
        frames.length - 1,
      );
      return frames[index];
    }
    final scaled = clamped * frames.length;
    final startIndex = scaled.floor() % frames.length;
    final endIndex = (startIndex + 1) % frames.length;
    final t = scaled - scaled.floorToDouble();
    final start = frames[startIndex];
    final end = frames[endIndex];
    return Offset.lerp(start, end, t) ?? start;
  }
}

class PetSocketConfig {
  const PetSocketConfig({
    required this.petId,
    required this.sockets,
    this.walkOverrides = const <String, PetSocket>{},
    this.sleepOverrides = const <String, PetSocket>{},
    this.idleMotionTrack,
    this.idleMotionTracksBySlot = const <String, PetMotionTrack>{},
  });

  final String petId;
  final Map<String, PetSocket> sockets;
  final Map<String, PetSocket> walkOverrides;
  final Map<String, PetSocket> sleepOverrides;
  final PetMotionTrack? idleMotionTrack;
  final Map<String, PetMotionTrack> idleMotionTracksBySlot;

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

  Offset resolveMotion({
    String? slot,
    required double animationProgress,
    bool isWalking = false,
    bool isSleeping = false,
  }) {
    if (isWalking || isSleeping) {
      return Offset.zero;
    }
    final slotTrack = slot == null ? null : idleMotionTracksBySlot[slot];
    if (slotTrack != null) {
      return slotTrack.sample(animationProgress);
    }
    return idleMotionTrack?.sample(animationProgress) ?? Offset.zero;
  }
}

class PetSocketCatalog {
  static final List<PetSocketConfig> configs = [
    PetSocketConfig(
      petId: 'ghost',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.484444444, y: 0.131111111),
        PetEquipmentSlot.body: PetSocket(x: 0.444444444, y: 0.462222222),
        PetEquipmentSlot.back: PetSocket(x: 0.762222222, y: 0.466666667),
      },
      walkOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.484444444, y: 0.131111111),
      },
      sleepOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.484444444, y: 0.131111111),
      },
      idleMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.repeated(
          hold: 2,
          frames: [
            Offset(0, 0),
            Offset(0, -0.002222222),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(0, 0),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
          ],
        ),
      },
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
