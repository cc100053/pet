/// Waits while [isCovered] (another route, e.g. the launch What's New dialog,
/// sits on top of the room) for up to [timeout], polling every [step].
///
/// Returns true once uncovered while [isStillWanted] holds; false as soon as
/// [isStillWanted] turns false or [timeout] passes while still covered.
Future<bool> waitUntilUncovered({
  required bool Function() isCovered,
  required bool Function() isStillWanted,
  Duration step = const Duration(seconds: 1),
  Duration timeout = const Duration(minutes: 2),
}) async {
  var waited = Duration.zero;
  while (isStillWanted() && isCovered()) {
    if (waited >= timeout) {
      return false;
    }
    await Future<void>.delayed(step);
    waited += step;
  }
  return isStillWanted();
}
