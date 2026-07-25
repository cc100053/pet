import 'dart:ui';

import 'pet_animation_frames.dart';
import 'pet_animation_timeline.dart';

enum PetMotionSampling { linear, stepped }

class PetEquipmentSlot {
  static const String head = 'head';
  static const String face = 'face';
  static const String body = 'body';
  static const String back = 'back';

  static const List<String> values = [head, face, body, back];

  static bool isValid(String slot) => values.contains(slot);

  static String socketAnchorFor(String slot) {
    return switch (slot) {
      face => head,
      _ => slot,
    };
  }
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
    this.frameDurationsMs = const <int>[],
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

  factory PetMotionTrack.timed({
    required List<Offset> frames,
    required List<int> frameDurationsMs,
    PetMotionSampling sampling = PetMotionSampling.stepped,
  }) {
    if (frameDurationsMs.length != frames.length) {
      throw ArgumentError.value(
        frameDurationsMs,
        'frameDurationsMs',
        'Must have one duration per frame.',
      );
    }
    return PetMotionTrack(
      frames: frames,
      sampling: sampling,
      frameDurationsMs: frameDurationsMs,
    );
  }

  final List<Offset> frames;
  final PetMotionSampling sampling;
  final List<int> frameDurationsMs;

  Offset sample(double progress) {
    if (frames.isEmpty) {
      return Offset.zero;
    }
    if (frames.length == 1) {
      return frames.first;
    }

    final clamped = progress.clamp(0.0, 1.0);
    if (_hasFrameDurations) {
      return _sampleFromTimeline(
        PetAnimationTimeline(
          frameCount: frames.length,
          frameDurationsMs: frameDurationsMs,
        ).timedSampleForProgress(clamped),
      );
    }
    if (sampling == PetMotionSampling.stepped) {
      final index = PetAnimationTimeline.logicalIndex(clamped, frames.length);
      return frames[index];
    }
    return _sampleFromTimeline(
      PetAnimationTimeline(
        frameCount: frames.length,
      ).loopingSampleForProgress(clamped),
    );
  }

  bool get _hasFrameDurations => frameDurationsMs.length == frames.length;

  Offset _sampleFromTimeline(PetAnimationTimelineSample sample) {
    if (sampling == PetMotionSampling.stepped) {
      return frames[sample.index];
    }
    final start = frames[sample.index];
    final end = frames[sample.nextIndex];
    return Offset.lerp(start, end, sample.t) ?? start;
  }
}

class PetSocketConfig {
  const PetSocketConfig({
    required this.petId,
    required this.sockets,
    this.walkOverrides = const <String, PetSocket>{},
    this.sleepOverrides = const <String, PetSocket>{},
    this.sleepHiddenSlots = const <String>{},
    this.idleMotionTrack,
    this.idleMotionTracksBySlot = const <String, PetMotionTrack>{},
    this.walkMotionTracksBySlot = const <String, PetMotionTrack>{},
    this.sleepMotionTracksBySlot = const <String, PetMotionTrack>{},
  });

  final String petId;
  final Map<String, PetSocket> sockets;
  final Map<String, PetSocket> walkOverrides;
  final Map<String, PetSocket> sleepOverrides;
  final Set<String> sleepHiddenSlots;
  final PetMotionTrack? idleMotionTrack;
  final Map<String, PetMotionTrack> idleMotionTracksBySlot;
  final Map<String, PetMotionTrack> walkMotionTracksBySlot;
  final Map<String, PetMotionTrack> sleepMotionTracksBySlot;

  PetSocket? resolve(
    String slot, {
    bool isWalking = false,
    bool isSleeping = false,
  }) {
    final socketSlot = PetEquipmentSlot.socketAnchorFor(slot);
    if (isSleeping && sleepHiddenSlots.contains(socketSlot)) {
      return null;
    }
    if (isWalking && walkOverrides.containsKey(socketSlot)) {
      return walkOverrides[socketSlot];
    }
    if (isSleeping && sleepOverrides.containsKey(socketSlot)) {
      return sleepOverrides[socketSlot];
    }
    return sockets[socketSlot];
  }

  Offset resolveMotion({
    String? slot,
    required double animationProgress,
    bool isWalking = false,
    bool isSleeping = false,
  }) {
    final socketSlot = slot == null
        ? null
        : PetEquipmentSlot.socketAnchorFor(slot);
    if (isWalking) {
      final slotTrack = socketSlot == null
          ? null
          : walkMotionTracksBySlot[socketSlot];
      return slotTrack?.sample(animationProgress) ?? Offset.zero;
    }
    if (isSleeping) {
      final slotTrack = socketSlot == null
          ? null
          : sleepMotionTracksBySlot[socketSlot];
      return slotTrack?.sample(animationProgress) ?? Offset.zero;
    }
    final slotTrack = socketSlot == null
        ? null
        : idleMotionTracksBySlot[socketSlot];
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
        PetEquipmentSlot.body: PetSocket(x: 0.442222222, y: 0.486666667),
        PetEquipmentSlot.back: PetSocket(x: 0.762222222, y: 0.466666667),
      },
      walkOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.484444444, y: 0.131111111),
      },
      sleepOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.484444444, y: 0.131111111),
        PetEquipmentSlot.body: PetSocket(x: 0.442222222, y: 0.495555556),
      },
      idleMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.ghostIdle.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, -0.002222222),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.004444444),
            Offset(0, -0.002222222),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.004444444),
          ],
        ),
      },
      walkMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.ghostWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, 0),
            Offset(0, 0),
            Offset(0, 0),
            Offset(-0.002222222, 0),
            Offset(-0.002222222, 0),
            Offset(0, 0),
            Offset(0, 0),
            Offset(-0.002222222, -0.002222222),
            Offset(0, 0),
            Offset(-0.002222222, 0),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.004444444),
            Offset(0, 0),
            Offset(-0.002222222, -0.004444444),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, 0),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.004444444),
            Offset(0, 0),
            Offset(-0.002222222, -0.004444444),
            Offset(0, 0),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, 0),
            Offset(0, 0),
            Offset(0, 0),
            Offset(-0.002222222, -0.002222222),
            Offset(0, 0),
            Offset(0, 0),
            Offset(0, 0),
            Offset(0, 0),
            Offset(-0.002222222, 0),
          ],
        ),
      },
      sleepMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.ghostSleep.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, -0.008888889),
            Offset(-0.002222222, -0.008888889),
            Offset(-0.004444444, -0.004444444),
            Offset(-0.002222222, -0.002222222),
            Offset(-0.002222222, -0.008888889),
          ],
        ),
      },
    ),
    PetSocketConfig(
      petId: 'cat',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.448888889, y: 0.155555556),
        PetEquipmentSlot.body: PetSocket(x: 0.444444444, y: 0.462222222),
        PetEquipmentSlot.back: PetSocket(x: 0.68, y: 0.41),
      },
      walkOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.446666667, y: 0.16),
      },
      sleepOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.448888889, y: 0.157777778),
      },
      walkMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.catWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.011111111, -0.002222222),
            Offset(-0.046666667, -0.004444444),
            Offset(-0.055555556, -0.006666667),
            Offset(-0.06, -0.006666667),
            Offset(-0.004444444, -0.004444444),
            Offset(0.006666667, -0.004444444),
            Offset(-0.006666667, -0.004444444),
          ],
        ),
        PetEquipmentSlot.body: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.catWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, 0),
            Offset(-0.017777778, 0),
            Offset(-0.028888889, 0),
            Offset(-0.040000000, 0),
            Offset(-0.013333333, 0),
            Offset(0.006666667, 0),
            Offset(-0.008888889, 0),
          ],
        ),
      },
      sleepMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.catSleep.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.026666667, 0),
            Offset(-0.035555556, 0),
            Offset(-0.051111111, 0.002222222),
            Offset(-0.04, 0.002222222),
            Offset(-0.028888889, 0.002222222),
          ],
        ),
      },
    ),
    PetSocketConfig(
      petId: 'fish',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.48, y: 0.153333333),
        PetEquipmentSlot.body: PetSocket(x: 0.457777778, y: 0.433333333),
        PetEquipmentSlot.back: PetSocket(x: 0.69, y: 0.44),
      },
      walkOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.477777778, y: 0.135555556),
        PetEquipmentSlot.body: PetSocket(x: 0.451111111, y: 0.431111111),
      },
      sleepOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.477777778, y: 0.135555556),
        PetEquipmentSlot.body: PetSocket(x: 0.455555556, y: 0.431111111),
      },
      idleMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.fishIdle.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, -0.02),
            Offset(0, -0.053333333),
            Offset(0, -0.044444444),
            Offset(0, -0.053333333),
            Offset(0, -0.031111111),
            Offset(0, -0.013333333),
            Offset(0, -0.033333333),
            Offset(0, -0.006666667),
            Offset(0, 0),
            Offset(0, -0.037777778),
            Offset(0, -0.035555556),
            Offset(0, -0.004444444),
            Offset(0, -0.017777778),
          ],
        ),
        PetEquipmentSlot.body: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.fishIdle.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, -0.020000000),
            Offset(0, -0.053333333),
            Offset(0, -0.046666667),
            Offset(0, -0.053333333),
            Offset(0, -0.031111111),
            Offset(0, -0.015555556),
            Offset(0, -0.033333333),
            Offset(0, -0.008888889),
            Offset(0, -0.002222222),
            Offset(0, -0.037777778),
            Offset(0, -0.037777778),
            Offset(0, -0.006666667),
            Offset(0, -0.020000000),
          ],
        ),
      },
      walkMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.fishWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, 0),
            Offset(0, -0.022222222),
            Offset(0.002222222, -0.006666667),
            Offset(-0.006666667, -0.006666667),
            Offset(-0.006666667, -0.017777778),
            Offset(0.013333333, -0.033333333),
            Offset(-0.06, -0.024444444),
            Offset(-0.053333333, -0.015555556),
            Offset(-0.06, 0.004444444),
            Offset(-0.031111111, -0.004444444),
            Offset(-0.002222222, -0.004444444),
          ],
        ),
        PetEquipmentSlot.body: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.fishWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, 0),
            Offset(0, -0.022222222),
            Offset(0.004444444, -0.008888889),
            Offset(-0.008888889, -0.008888889),
            Offset(-0.008888889, -0.020000000),
            Offset(0.002222222, -0.035555556),
            Offset(-0.044444444, -0.020000000),
            Offset(-0.040000000, -0.015555556),
            Offset(-0.048888889, 0.004444444),
            Offset(-0.026666667, -0.006666667),
            Offset(-0.026666667, -0.006666667),
          ],
        ),
      },
    ),
    PetSocketConfig(
      petId: 'tiger',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.386666667, y: 0.233333333),
        PetEquipmentSlot.body: PetSocket(x: 0.382222222, y: 0.566666667),
        PetEquipmentSlot.back: PetSocket(x: 0.69, y: 0.39),
      },
      walkOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.386666667, y: 0.235555556),
        PetEquipmentSlot.body: PetSocket(x: 0.384444444, y: 0.566666667),
      },
      sleepOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.315555556, y: 0.38),
      },
      sleepHiddenSlots: {PetEquipmentSlot.body},
      walkMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.tigerWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0.002222222, 0),
            Offset(-0.024444444, -0.031111111),
            Offset(-0.022222222, -0.004444444),
            Offset(0.024444444, 0),
            Offset(0.024444444, -0.017777778),
            Offset(0.024444444, 0),
          ],
        ),
        PetEquipmentSlot.body: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.tigerWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0, 0),
            Offset(-0.022222222, -0.035555556),
            Offset(-0.020000000, -0.004444444),
            Offset(-0.002222222, 0),
            Offset(0, -0.020000000),
            Offset(0, 0),
          ],
        ),
      },
      sleepMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.tigerSleep.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.028888889, 0),
            Offset(-0.028888889, 0),
            Offset(-0.028888889, 0),
            Offset(-0.028888889, 0),
            Offset(-0.028888889, 0),
            Offset(-0.028888889, 0),
            Offset(-0.028888889, 0),
          ],
        ),
      },
    ),
    PetSocketConfig(
      petId: 'chicken',
      sockets: {
        PetEquipmentSlot.head: PetSocket(x: 0.368888889, y: 0.16),
        PetEquipmentSlot.body: PetSocket(x: 0.448888889, y: 0.52),
        PetEquipmentSlot.back: PetSocket(x: 0.688888889, y: 0.451111111),
      },
      walkOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.368888889, y: 0.16),
        PetEquipmentSlot.body: PetSocket(x: 0.448888889, y: 0.52),
        PetEquipmentSlot.back: PetSocket(x: 0.688888889, y: 0.451111111),
      },
      sleepOverrides: {
        PetEquipmentSlot.head: PetSocket(x: 0.368888889, y: 0.166666667),
        PetEquipmentSlot.body: PetSocket(x: 0.444444444, y: 0.5),
        PetEquipmentSlot.back: PetSocket(x: 0.688888889, y: 0.455555556),
      },
      idleMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenIdle.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.006666667, 0.008888889),
            Offset(-0.017777778, 0.013333333),
            Offset(-0.017777778, 0.017777778),
            Offset(-0.017777778, 0.008888889),
          ],
        ),
        PetEquipmentSlot.body: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenIdle.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.002222222, 0),
            Offset(-0.006666667, 0),
            Offset(-0.006666667, 0),
            Offset(-0.006666667, 0),
          ],
        ),
        PetEquipmentSlot.back: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenIdle.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0.004444444, -0.004444444),
            Offset(0.008888889, -0.008888889),
            Offset(0.006666667, -0.004444444),
            Offset(0.004444444, -0.004444444),
          ],
        ),
      },
      walkMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.008888889, -0.011111111),
            Offset(-0.017777778, -0.017777778),
            Offset(-0.015555556, 0.002222222),
            Offset(-0.042222222, 0.006666667),
            Offset(-0.077777778, 0.02),
            Offset(-0.12, 0.035555556),
            Offset(-0.033333333, 0.002222222),
          ],
        ),
        PetEquipmentSlot.body: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.004444445, -0.004444444),
            Offset(-0.006666667, -0.013333333),
            Offset(-0.008888889, 0.002222222),
            Offset(-0.026666667, 0.002222222),
            Offset(-0.048888889, 0.004444444),
            Offset(-0.088888889, 0.008888889),
            Offset(-0.015555556, 0),
          ],
        ),
        PetEquipmentSlot.back: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenWalk.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(0.011111111, -0.006666667),
            Offset(0.022222222, -0.028888889),
            Offset(0.011111111, 0.004444445),
            Offset(-0.011111111, -0.006666667),
            Offset(-0.022222222, -0.017777778),
            Offset(-0.055555556, -0.04),
            Offset(-0.004444445, -0.006666667),
          ],
        ),
      },
      sleepMotionTracksBySlot: {
        PetEquipmentSlot.head: PetMotionTrack.timed(
          frameDurationsMs: PetAnimationFrames.chickenSleep.frameDurationsMs,
          frames: [
            Offset(0, 0),
            Offset(-0.004444445, 0.002222222),
            Offset(-0.026666667, -0.002222223),
            Offset(-0.046666667, 0),
            Offset(-0.046666667, 0),
            Offset(-0.004444445, 0),
          ],
        ),
      },
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
