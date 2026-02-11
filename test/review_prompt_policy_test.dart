import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/review/review_prompt_policy.dart';

void main() {
  test('does not prompt before first feed milestone', () {
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: 9,
      nextMilestoneIndex: 0,
      lastPromptAtUtc: null,
      nowUtc: DateTime.utc(2026, 2, 11),
    );

    expect(decision.shouldPrompt, isFalse);
    expect(decision.nextMilestoneIndex, 0);
  });

  test('prompts at first milestone and advances milestone index', () {
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: 10,
      nextMilestoneIndex: 0,
      lastPromptAtUtc: null,
      nowUtc: DateTime.utc(2026, 2, 11),
    );

    expect(decision.shouldPrompt, isTrue);
    expect(decision.nextMilestoneIndex, 1);
  });

  test('does not prompt again if last prompt was under 10 days ago', () {
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: 25,
      nextMilestoneIndex: 1,
      lastPromptAtUtc: DateTime.utc(2026, 2, 5),
      nowUtc: DateTime.utc(2026, 2, 11),
    );

    expect(decision.shouldPrompt, isFalse);
    expect(decision.nextMilestoneIndex, 1);
  });

  test('prompts when cooldown has elapsed and milestone is reached', () {
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: 25,
      nextMilestoneIndex: 1,
      lastPromptAtUtc: DateTime.utc(2026, 2, 1),
      nowUtc: DateTime.utc(2026, 2, 11),
    );

    expect(decision.shouldPrompt, isTrue);
    expect(decision.nextMilestoneIndex, 2);
  });

  test('stops prompting after all milestones are consumed', () {
    final decision = ReviewPromptPolicy.evaluate(
      updatedFeedCount: 500,
      nextMilestoneIndex: ReviewPromptPolicy.feedMilestones.length,
      lastPromptAtUtc: DateTime.utc(2026, 1, 1),
      nowUtc: DateTime.utc(2026, 2, 11),
    );

    expect(decision.shouldPrompt, isFalse);
    expect(
      decision.nextMilestoneIndex,
      ReviewPromptPolicy.feedMilestones.length,
    );
  });
}
