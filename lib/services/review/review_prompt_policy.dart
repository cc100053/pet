class ReviewPromptDecision {
  const ReviewPromptDecision({
    required this.shouldPrompt,
    required this.nextMilestoneIndex,
  });

  final bool shouldPrompt;
  final int nextMilestoneIndex;
}

class ReviewPromptPolicy {
  static const List<int> feedMilestones = <int>[5, 25, 50, 100, 150];
  static const Duration minimumPromptGap = Duration(days: 90);

  static ReviewPromptDecision evaluate({
    required int updatedFeedCount,
    required int activeFeedDays,
    required int nextMilestoneIndex,
    required DateTime? lastPromptAtUtc,
    required DateTime nowUtc,
  }) {
    if (activeFeedDays < 2) {
      return ReviewPromptDecision(
        shouldPrompt: false,
        nextMilestoneIndex: nextMilestoneIndex,
      );
    }

    final requiredCount =
        feedMilestones[nextMilestoneIndex.clamp(0, feedMilestones.length - 1)];
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
      nextMilestoneIndex: (nextMilestoneIndex + 1).clamp(
        0,
        feedMilestones.length,
      ),
    );
  }
}
