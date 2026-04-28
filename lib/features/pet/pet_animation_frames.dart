import 'pet_animation_timeline.dart';

class PetFrameSequence {
  const PetFrameSequence({
    required this.petId,
    required this.sourceAsset,
    required this.frameAssets,
    this.frameHold = 1,
    this.frameDurationsMs = const <int>[],
  });

  final String petId;
  final String sourceAsset;
  final List<String> frameAssets;
  final int frameHold;
  final List<int> frameDurationsMs;

  PetAnimationTimeline get _timeline => PetAnimationTimeline(
    frameCount: frameAssets.length,
    frameHold: frameHold,
    frameDurationsMs: frameDurationsMs,
  );

  int get logicalFrameCount => _timeline.logicalFrameCount;

  int get totalDurationMs => _timeline.totalDurationMs;

  String assetForProgress(double progress) {
    if (frameAssets.isEmpty) {
      return sourceAsset;
    }
    final index = frameIndexForProgress(progress);
    return frameAssets[index];
  }

  String assetForElapsedMs(int elapsedMs) =>
      assetForProgress(progressForElapsedMs(elapsedMs));

  double progressForElapsedMs(int elapsedMs) {
    return _timeline.progressForElapsedMs(elapsedMs);
  }

  int frameIndexForProgress(double progress) {
    if (frameAssets.isEmpty) {
      return 0;
    }
    return _timeline.frameIndexForProgress(progress);
  }
}

class PetAnimationFrames {
  static const int ghostIdleTotalDurationMs = 2600;

  static const List<PetFrameSequence> all = [
    ghostIdle,
    ghostSleep,
    ghostWalk,
    catIdle,
    catSleep,
    catWalk,
    fishIdle,
    fishSleep,
    fishWalk,
    tigerIdle,
    tigerSleep,
    tigerWalk,
  ];

  static const PetFrameSequence ghostIdle = PetFrameSequence(
    petId: 'ghost',
    sourceAsset: 'assets/pet/ghost/ghost_stay.gif',
    frameDurationsMs: _ghostIdleDurationsMs,
    frameAssets: _ghostIdleFrames,
  );

  static const PetFrameSequence ghostSleep = PetFrameSequence(
    petId: 'ghost',
    sourceAsset: 'assets/pet/ghost/ghost_sleep.gif',
    frameDurationsMs: [201, 201, 201, 201, 201, 201],
    frameAssets: [
      'assets/pet_sequences/ghost/sleep/ghost_sleep-01.png',
      'assets/pet_sequences/ghost/sleep/ghost_sleep-02.png',
      'assets/pet_sequences/ghost/sleep/ghost_sleep-03.png',
      'assets/pet_sequences/ghost/sleep/ghost_sleep-04.png',
      'assets/pet_sequences/ghost/sleep/ghost_sleep-05.png',
      'assets/pet_sequences/ghost/sleep/ghost_sleep-06.png',
    ],
  );

  static const PetFrameSequence ghostWalk = PetFrameSequence(
    petId: 'ghost',
    sourceAsset: 'assets/pet/ghost/ghost_walking.gif',
    frameDurationsMs: [
      300,
      200,
      200,
      250,
      200,
      250,
      200,
      100,
      200,
      200,
      200,
      200,
      100,
      200,
      100,
      200,
      200,
      200,
      100,
      200,
      100,
      200,
      200,
      250,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
    ],
    frameAssets: [
      'assets/pet_sequences/ghost/walk/ghost_walk-01.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-02.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-03.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-04.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-05.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-06.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-07.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-08.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-09.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-10.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-11.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-12.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-13.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-14.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-15.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-16.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-17.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-18.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-19.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-20.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-21.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-22.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-23.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-24.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-25.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-26.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-27.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-28.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-29.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-30.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-31.png',
      'assets/pet_sequences/ghost/walk/ghost_walk-32.png',
    ],
  );

  static const PetFrameSequence catIdle = PetFrameSequence(
    petId: 'cat',
    sourceAsset: 'assets/pet/cat/cat_stay.gif',
    frameDurationsMs: [200, 200, 100, 200, 200, 200, 200],
    frameAssets: [
      'assets/pet_sequences/cat/stay/cat_stay-01.png',
      'assets/pet_sequences/cat/stay/cat_stay-02.png',
      'assets/pet_sequences/cat/stay/cat_stay-03.png',
      'assets/pet_sequences/cat/stay/cat_stay-04.png',
      'assets/pet_sequences/cat/stay/cat_stay-05.png',
      'assets/pet_sequences/cat/stay/cat_stay-06.png',
      'assets/pet_sequences/cat/stay/cat_stay-07.png',
    ],
  );

  static const PetFrameSequence catSleep = PetFrameSequence(
    petId: 'cat',
    sourceAsset: 'assets/pet/cat/cat_sleep.gif',
    frameDurationsMs: [200, 300, 200, 300, 200, 200],
    frameAssets: [
      'assets/pet_sequences/cat/sleep/cat_sleep-01.png',
      'assets/pet_sequences/cat/sleep/cat_sleep-02.png',
      'assets/pet_sequences/cat/sleep/cat_sleep-03.png',
      'assets/pet_sequences/cat/sleep/cat_sleep-04.png',
      'assets/pet_sequences/cat/sleep/cat_sleep-05.png',
      'assets/pet_sequences/cat/sleep/cat_sleep-06.png',
    ],
  );

  static const PetFrameSequence catWalk = PetFrameSequence(
    petId: 'cat',
    sourceAsset: 'assets/pet/cat/cat_moving.gif',
    frameDurationsMs: [200, 100, 200, 100, 200, 100, 200, 100],
    frameAssets: [
      'assets/pet_sequences/cat/walk/cat_walk-01.png',
      'assets/pet_sequences/cat/walk/cat_walk-02.png',
      'assets/pet_sequences/cat/walk/cat_walk-03.png',
      'assets/pet_sequences/cat/walk/cat_walk-04.png',
      'assets/pet_sequences/cat/walk/cat_walk-05.png',
      'assets/pet_sequences/cat/walk/cat_walk-06.png',
      'assets/pet_sequences/cat/walk/cat_walk-07.png',
      'assets/pet_sequences/cat/walk/cat_walk-08.png',
    ],
  );

  static const PetFrameSequence fishIdle = PetFrameSequence(
    petId: 'fish',
    sourceAsset: 'assets/pet/fish/fish_stay.gif',
    frameDurationsMs: [
      500,
      200,
      100,
      200,
      100,
      200,
      300,
      200,
      400,
      200,
      300,
      200,
      200,
      300,
    ],
    frameAssets: [
      'assets/pet_sequences/fish/stay/fish_stay-01.png',
      'assets/pet_sequences/fish/stay/fish_stay-02.png',
      'assets/pet_sequences/fish/stay/fish_stay-03.png',
      'assets/pet_sequences/fish/stay/fish_stay-04.png',
      'assets/pet_sequences/fish/stay/fish_stay-05.png',
      'assets/pet_sequences/fish/stay/fish_stay-06.png',
      'assets/pet_sequences/fish/stay/fish_stay-07.png',
      'assets/pet_sequences/fish/stay/fish_stay-08.png',
      'assets/pet_sequences/fish/stay/fish_stay-09.png',
      'assets/pet_sequences/fish/stay/fish_stay-10.png',
      'assets/pet_sequences/fish/stay/fish_stay-11.png',
      'assets/pet_sequences/fish/stay/fish_stay-12.png',
      'assets/pet_sequences/fish/stay/fish_stay-13.png',
      'assets/pet_sequences/fish/stay/fish_stay-14.png',
    ],
  );

  static const PetFrameSequence fishSleep = PetFrameSequence(
    petId: 'fish',
    sourceAsset: 'assets/pet/fish/fish_sleep.gif',
    frameDurationsMs: [200, 200, 200, 200, 100, 200, 100],
    frameAssets: [
      'assets/pet_sequences/fish/sleep/fish_sleep-01.png',
      'assets/pet_sequences/fish/sleep/fish_sleep-02.png',
      'assets/pet_sequences/fish/sleep/fish_sleep-03.png',
      'assets/pet_sequences/fish/sleep/fish_sleep-04.png',
      'assets/pet_sequences/fish/sleep/fish_sleep-05.png',
      'assets/pet_sequences/fish/sleep/fish_sleep-06.png',
      'assets/pet_sequences/fish/sleep/fish_sleep-07.png',
    ],
  );

  static const PetFrameSequence fishWalk = PetFrameSequence(
    petId: 'fish',
    sourceAsset: 'assets/pet/fish/fish_moving.gif',
    frameDurationsMs: [
      100,
      200,
      200,
      200,
      200,
      200,
      200,
      200,
      100,
      200,
      200,
      200,
    ],
    frameAssets: [
      'assets/pet_sequences/fish/walk/fish_walk-01.png',
      'assets/pet_sequences/fish/walk/fish_walk-02.png',
      'assets/pet_sequences/fish/walk/fish_walk-03.png',
      'assets/pet_sequences/fish/walk/fish_walk-04.png',
      'assets/pet_sequences/fish/walk/fish_walk-05.png',
      'assets/pet_sequences/fish/walk/fish_walk-06.png',
      'assets/pet_sequences/fish/walk/fish_walk-07.png',
      'assets/pet_sequences/fish/walk/fish_walk-08.png',
      'assets/pet_sequences/fish/walk/fish_walk-09.png',
      'assets/pet_sequences/fish/walk/fish_walk-10.png',
      'assets/pet_sequences/fish/walk/fish_walk-11.png',
      'assets/pet_sequences/fish/walk/fish_walk-12.png',
    ],
  );

  static const PetFrameSequence tigerIdle = PetFrameSequence(
    petId: 'tiger',
    sourceAsset: 'assets/pet/tiger/tiger_stay.gif',
    frameDurationsMs: [200, 200, 100, 200, 200, 200, 100, 200, 200],
    frameAssets: [
      'assets/pet_sequences/tiger/stay/tiger_stay-01.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-02.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-03.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-04.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-05.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-06.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-07.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-08.png',
      'assets/pet_sequences/tiger/stay/tiger_stay-09.png',
    ],
  );

  static const PetFrameSequence tigerSleep = PetFrameSequence(
    petId: 'tiger',
    sourceAsset: 'assets/pet/tiger/tiger_sleep.gif',
    frameDurationsMs: [300, 200, 100, 100, 100, 100, 100, 100],
    frameAssets: [
      'assets/pet_sequences/tiger/sleep/tiger_sleep-01.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-02.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-03.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-04.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-05.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-06.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-07.png',
      'assets/pet_sequences/tiger/sleep/tiger_sleep-08.png',
    ],
  );

  static const PetFrameSequence tigerWalk = PetFrameSequence(
    petId: 'tiger',
    sourceAsset: 'assets/pet/tiger/tiger_moving.gif',
    frameDurationsMs: [200, 200, 100, 200, 200, 100, 200],
    frameAssets: [
      'assets/pet_sequences/tiger/walk/tiger_walk-01.png',
      'assets/pet_sequences/tiger/walk/tiger_walk-02.png',
      'assets/pet_sequences/tiger/walk/tiger_walk-03.png',
      'assets/pet_sequences/tiger/walk/tiger_walk-04.png',
      'assets/pet_sequences/tiger/walk/tiger_walk-05.png',
      'assets/pet_sequences/tiger/walk/tiger_walk-06.png',
      'assets/pet_sequences/tiger/walk/tiger_walk-07.png',
    ],
  );

  static const List<int> _ghostIdleDurationsMs = [
    200,
    200,
    200,
    200,
    200,
    200,
    200,
    200,
    200,
    200,
    200,
    200,
    200,
  ];

  static const List<String> _ghostIdleFrames = [
    'assets/pet_sequences/ghost/stay/ghost_stay-01.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-02.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-03.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-04.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-05.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-06.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-07.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-08.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-09.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-10.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-11.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-12.png',
    'assets/pet_sequences/ghost/stay/ghost_stay-13.png',
  ];

  static PetFrameSequence? sequenceForAsset(String sourceAsset) {
    for (final sequence in all) {
      if (sequence.sourceAsset == sourceAsset) {
        return sequence;
      }
    }
    return null;
  }

  static PetFrameSequence? sequenceFor({
    required String petId,
    required String sourceAsset,
  }) {
    final sequence = sequenceForAsset(sourceAsset);
    if (sequence != null && sequence.petId == petId) {
      return sequence;
    }
    return null;
  }

  static List<String> frameAssetsForSourceAsset(String sourceAsset) =>
      sequenceForAsset(sourceAsset)?.frameAssets ?? const <String>[];

  static List<String> frameAssetsForPetSources(Iterable<String> sourceAssets) {
    final assets = <String>[];
    for (final sourceAsset in sourceAssets) {
      assets.addAll(frameAssetsForSourceAsset(sourceAsset));
    }
    return assets;
  }
}
