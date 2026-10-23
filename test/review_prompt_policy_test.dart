import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/review/review_prompt_policy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 24);

  ReviewPromptDecision evaluate({
    int feeds = 5,
    int days = 2,
    int index = 0,
    DateTime? last,
  }) => ReviewPromptPolicy.evaluate(
    updatedFeedCount: feeds,
    activeFeedDays: days,
    nextMilestoneIndex: index,
    lastPromptAtUtc: last,
    nowUtc: now,
  );

  test('first request needs five feeds and two observed feed days', () {
    expect(evaluate(feeds: 4).shouldPrompt, isFalse);
    expect(evaluate(days: 1).shouldPrompt, isFalse);
    expect(evaluate().shouldPrompt, isTrue);
    expect(evaluate().nextMilestoneIndex, 1);
  });

  test('later milestones still require their feed counts', () {
    for (
      var index = 1;
      index < ReviewPromptPolicy.feedMilestones.length;
      index++
    ) {
      final threshold = ReviewPromptPolicy.feedMilestones[index];
      expect(
        evaluate(feeds: threshold - 1, index: index).shouldPrompt,
        isFalse,
      );
      final decision = evaluate(feeds: threshold, index: index);
      expect(decision.shouldPrompt, isTrue);
      expect(decision.nextMilestoneIndex, index + 1);
    }
  });

  test(
    '90-day cooldown includes the exact boundary and rejects future dates',
    () {
      final boundary = now.subtract(const Duration(days: 90));
      expect(evaluate(last: boundary).shouldPrompt, isTrue);
      expect(
        evaluate(
          last: boundary.add(const Duration(microseconds: 1)),
        ).shouldPrompt,
        isFalse,
      );
      expect(
        evaluate(last: now.add(const Duration(days: 1))).shouldPrompt,
        isFalse,
      );
    },
  );

  test(
    'exhausted legacy milestones allow recurring requests after cooldown',
    () {
      for (final index in [5, 6]) {
        final decision = evaluate(
          feeds: 500,
          index: index,
          last: now.subtract(const Duration(days: 90)),
        );
        expect(decision.shouldPrompt, isTrue);
        expect(decision.nextMilestoneIndex, 5);
        expect(
          evaluate(feeds: 500, index: index, last: now).shouldPrompt,
          isFalse,
        );
      }
    },
  );
}
