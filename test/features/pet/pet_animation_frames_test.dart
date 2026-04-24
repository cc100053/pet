import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_animation_frames.dart';

void main() {
  test('ghost idle sequence follows exported frame durations', () {
    final sequence = PetAnimationFrames.ghostIdle;

    expect(sequence.logicalFrameCount, 13);
    expect(sequence.totalDurationMs, 2600);
    expect(
      sequence.assetForProgress(0),
      'assets/pet_sequences/ghost/stay/ghost_stay-01.png',
    );
    expect(
      sequence.assetForProgress(199 / 2600),
      'assets/pet_sequences/ghost/stay/ghost_stay-01.png',
    );
    expect(
      sequence.assetForProgress(200 / 2600),
      'assets/pet_sequences/ghost/stay/ghost_stay-02.png',
    );
    expect(
      sequence.assetForProgress(1),
      'assets/pet_sequences/ghost/stay/ghost_stay-13.png',
    );
  });

  test('sequence supports variable per-frame durations', () {
    const sequence = PetFrameSequence(
      petId: 'fish',
      sourceAsset: 'assets/pet/fish/fish_stay.gif',
      frameAssets: [
        'assets/pet/fish/fish_stay/fish_stay-01.png',
        'assets/pet/fish/fish_stay/fish_stay-02.png',
        'assets/pet/fish/fish_stay/fish_stay-03.png',
      ],
      frameDurationsMs: [500, 200, 100],
    );

    expect(sequence.totalDurationMs, 800);
    expect(
      sequence.assetForProgress(499 / 800),
      'assets/pet/fish/fish_stay/fish_stay-01.png',
    );
    expect(
      sequence.assetForProgress(500 / 800),
      'assets/pet/fish/fish_stay/fish_stay-02.png',
    );
    expect(
      sequence.assetForProgress(700 / 800),
      'assets/pet/fish/fish_stay/fish_stay-03.png',
    );
    expect(
      sequence.assetForProgress(1),
      'assets/pet/fish/fish_stay/fish_stay-03.png',
    );
  });

  test('sequence catalog resolves every pet animation asset', () {
    expect(
      PetAnimationFrames.sequenceFor(
        petId: 'ghost',
        sourceAsset: 'assets/pet/ghost/ghost_stay.gif',
      ),
      PetAnimationFrames.ghostIdle,
    );
    expect(PetAnimationFrames.all, hasLength(12));
    for (final sequence in PetAnimationFrames.all) {
      expect(sequence.frameAssets, isNotEmpty);
      expect(sequence.frameDurationsMs, hasLength(sequence.frameAssets.length));
      expect(sequence.totalDurationMs, greaterThan(0));
      expect(
        PetAnimationFrames.sequenceForAsset(sequence.sourceAsset),
        same(sequence),
      );
    }
  });

  test('sequence lookup rejects mismatched pet ids', () {
    expect(
      PetAnimationFrames.sequenceFor(
        petId: 'ghost',
        sourceAsset: 'assets/pet/cat/cat_stay.gif',
      ),
      isNull,
    );
    expect(
      PetAnimationFrames.sequenceFor(
        petId: 'cat',
        sourceAsset: 'assets/pet/ghost/ghost_stay.gif',
      ),
      isNull,
    );
  });
}
