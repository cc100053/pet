class ReviewPromptDecision {
  const ReviewPromptDecision({
    required this.shouldPrompt,
    required this.nextMilestoneIndex,
  });

  final bool shouldPrompt;
  final int nextMilestoneIndex;
}

class ReviewPromptPolicy {
  static const List<int> feedMilestones = <int>[10, 25, 50, 100, 150];
  static const Duration minimumPromptGap = Duration(days: 10);

  static ReviewPromptDecision evaluate({
    required int updatedFeedCount,
    required int nextMilestoneIndex,
    required DateTime? lastPromptAtUtc,
    required DateTime nowUtc,
  }) {
    if (nextMilestoneIndex >= feedMilestones.length) {
      return ReviewPromptDecision(
        shouldPrompt: false,
        nextMilestoneIndex: nextMilestoneIndex,
      );
    }

    final requiredCount = feedMilestones[nextMilestoneIndex];
    if (updatedFeedCount < requiredCount) {
      return ReviewPromptDecision(
        shouldPrompt: false,
        nextMilestoneIndex: nextMilestoneIndex,
      );
    }

    final gapTooShort =
        lastPromptAtUtc != null &&
        nowUtc.difference(lastPromptAtUtc.toUtc()) < minimumPromptGap;
    if (gapTooShort) {
      return ReviewPromptDecision(
        shouldPrompt: false,
        nextMilestoneIndex: nextMilestoneIndex,
      );
    }

    return ReviewPromptDecision(
      shouldPrompt: true,
      nextMilestoneIndex: nextMilestoneIndex + 1,
    );
  }
}
