class PetAnimationTimelineSample {
  const PetAnimationTimelineSample({
    required this.index,
    required this.nextIndex,
    required this.t,
  });

  final int index;
  final int nextIndex;
  final double t;
}

class PetAnimationTimeline {
  const PetAnimationTimeline({
    required this.frameCount,
    this.frameHold = 1,
    this.frameDurationsMs = const <int>[],
  });

  final int frameCount;
  final int frameHold;
  final List<int> frameDurationsMs;

  int get logicalFrameCount => frameCount * frameHold;

  int get totalDurationMs {
    if (!hasFrameDurations) {
      return logicalFrameCount;
    }
    return frameDurationsMs.fold<int>(
      0,
      (total, duration) => total + safeDurationMs(duration),
    );
  }

  bool get hasFrameDurations => frameDurationsMs.length == frameCount;

  double progressForElapsedMs(int elapsedMs) {
    final total = totalDurationMs;
    if (total <= 0) {
      return 0;
    }
    final loopMs = elapsedMs % total;
    return loopMs / total;
  }

  int frameIndexForProgress(double progress) {
    if (frameCount <= 0) {
      return 0;
    }
    if (hasFrameDurations) {
      return timedSampleForProgress(progress).index;
    }
    if (frameHold <= 1) {
      return logicalIndex(progress, frameCount);
    }
    final index = logicalIndex(progress, logicalFrameCount);
    return (index ~/ frameHold).clamp(0, frameCount - 1);
  }

  PetAnimationTimelineSample timedSampleForProgress(double progress) {
    if (frameCount <= 0) {
      return const PetAnimationTimelineSample(index: 0, nextIndex: 0, t: 0);
    }
    if (!hasFrameDurations) {
      return loopingSampleForProgress(progress);
    }

    final total = totalDurationMs;
    if (total <= 0) {
      return const PetAnimationTimelineSample(index: 0, nextIndex: 0, t: 0);
    }

    final currentMs = progress.clamp(0.0, 1.0) * total;
    var elapsedMs = 0;
    for (var index = 0; index < frameDurationsMs.length; index += 1) {
      final durationMs = safeDurationMs(frameDurationsMs[index]);
      final frameEndMs = elapsedMs + durationMs;
      if (currentMs < frameEndMs) {
        return PetAnimationTimelineSample(
          index: index,
          nextIndex: (index + 1) % frameCount,
          t: (currentMs - elapsedMs) / durationMs,
        );
      }
      elapsedMs = frameEndMs;
    }
    return PetAnimationTimelineSample(
      index: frameCount - 1,
      nextIndex: frameCount - 1,
      t: 0,
    );
  }

  PetAnimationTimelineSample loopingSampleForProgress(double progress) {
    if (frameCount <= 0) {
      return const PetAnimationTimelineSample(index: 0, nextIndex: 0, t: 0);
    }
    final clamped = progress.clamp(0.0, 1.0);
    final scaled = clamped * frameCount;
    final index = scaled.floor() % frameCount;
    return PetAnimationTimelineSample(
      index: index,
      nextIndex: (index + 1) % frameCount,
      t: scaled - scaled.floorToDouble(),
    );
  }

  static int logicalIndex(double progress, int frameCount) {
    if (frameCount <= 1) {
      return 0;
    }
    final clamped = progress.clamp(0.0, 1.0);
    return (clamped * frameCount).floor().clamp(0, frameCount - 1);
  }

  static int safeDurationMs(int durationMs) => durationMs < 1 ? 1 : durationMs;
}
