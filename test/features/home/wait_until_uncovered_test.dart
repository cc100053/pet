import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/wait_until_uncovered.dart';

void main() {
  const step = Duration(milliseconds: 10);

  test('returns true immediately when nothing covers the room', () async {
    expect(
      await waitUntilUncovered(
        isCovered: () => false,
        isStillWanted: () => true,
        step: step,
      ),
      isTrue,
    );
  });

  test('waits for a covering dialog to close, then returns true', () async {
    var polls = 0;
    final result = await waitUntilUncovered(
      isCovered: () => ++polls < 5,
      isStillWanted: () => true,
      step: step,
    );
    expect(result, isTrue);
    expect(polls, 5);
  });

  test('gives up after the timeout while still covered', () async {
    expect(
      await waitUntilUncovered(
        isCovered: () => true,
        isStillWanted: () => true,
        step: step,
        timeout: const Duration(milliseconds: 50),
      ),
      isFalse,
    );
  });

  test('stops when the user leaves the room', () async {
    var polls = 0;
    expect(
      await waitUntilUncovered(
        isCovered: () => true,
        isStillWanted: () => ++polls < 3,
        step: step,
      ),
      isFalse,
    );
  });
}
