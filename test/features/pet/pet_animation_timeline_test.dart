import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_animation_timeline.dart';

void main() {
  group('PetAnimationTimeline', () {
    test('samples held logical frames without durations', () {
      const timeline = PetAnimationTimeline(frameCount: 3, frameHold: 2);

      expect(timeline.logicalFrameCount, 6);
      expect(timeline.totalDurationMs, 6);
      expect(timeline.frameIndexForProgress(0), 0);
      expect(timeline.frameIndexForProgress(1 / 6), 0);
      expect(timeline.frameIndexForProgress(2 / 6), 1);
      expect(timeline.frameIndexForProgress(4 / 6), 2);
      expect(timeline.frameIndexForProgress(1), 2);
    });

    test('samples timed frames by cumulative duration', () {
      const timeline = PetAnimationTimeline(
        frameCount: 3,
        frameDurationsMs: [500, 200, 100],
      );

      expect(timeline.totalDurationMs, 800);
      expect(timeline.frameIndexForProgress(499 / 800), 0);
      expect(timeline.frameIndexForProgress(500 / 800), 1);
      expect(timeline.frameIndexForProgress(700 / 800), 2);
      expect(timeline.frameIndexForProgress(1), 2);
    });

    test('clamps non-positive frame durations to one millisecond', () {
      const timeline = PetAnimationTimeline(
        frameCount: 3,
        frameDurationsMs: [0, -10, 8],
      );

      expect(timeline.totalDurationMs, 10);
      expect(timeline.frameIndexForProgress(0), 0);
      expect(timeline.frameIndexForProgress(1 / 10), 1);
      expect(timeline.frameIndexForProgress(2 / 10), 2);
    });

    test('converts elapsed milliseconds to looping progress', () {
      const timeline = PetAnimationTimeline(
        frameCount: 3,
        frameDurationsMs: [500, 200, 100],
      );

      expect(timeline.progressForElapsedMs(0), 0);
      expect(timeline.progressForElapsedMs(799), 799 / 800);
      expect(timeline.progressForElapsedMs(800), 0);
      expect(timeline.progressForElapsedMs(900), 100 / 800);
    });

    test('returns timed interpolation samples', () {
      const timeline = PetAnimationTimeline(
        frameCount: 3,
        frameDurationsMs: [500, 200, 100],
      );

      final first = timeline.timedSampleForProgress(250 / 800);
      expect(first.index, 0);
      expect(first.nextIndex, 1);
      expect(first.t, 0.5);

      final terminal = timeline.timedSampleForProgress(1);
      expect(terminal.index, 2);
      expect(terminal.nextIndex, 2);
      expect(terminal.t, 0);
    });

    test('returns looping interpolation samples', () {
      const timeline = PetAnimationTimeline(frameCount: 3);

      final middle = timeline.loopingSampleForProgress(1.5 / 3);
      expect(middle.index, 1);
      expect(middle.nextIndex, 2);
      expect(middle.t, 0.5);

      final terminal = timeline.loopingSampleForProgress(1);
      expect(terminal.index, 0);
      expect(terminal.nextIndex, 1);
      expect(terminal.t, 0);
    });
  });
}
