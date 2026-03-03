# TODO

## Plan
- [x] Reproduce and trace chatroom focus-loss path where tapping composer opens keyboard then immediately closes.
- [x] Stabilize chat composer/message-list widget identity across keyboard visibility transitions so TextField focus is preserved.
- [x] Keep keyboard-dismiss affordance without allowing composer tap-to-focus to trigger unintended dismiss.
- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with root cause + fix details.
- [x] Update `tasks/todo.md` review section with verification outcomes.
- [x] Update `tasks/lessons.md` with this regression pattern (user-follow-up correction).

## Review
- [x] Implemented and verified.
- Root cause: `ChatRoomView` inserted/removes `Stack` children based on keyboard visibility; without stable keys, composer subtree could be rematched/rebuilt on inset changes and drop `TextField` focus immediately after tap.
- Fixes in `lib/features/chat/chat_room_view.dart`:
  - Added stable keys for keyboard underlay, message list container, dismiss strip, and composer container so keyboard visibility transitions preserve composer element identity/focus.
  - Kept dismiss strip in tree and gated it with `IgnorePointer(ignoring: !isKeyboardVisible)` instead of conditionally adding/removing it during focus transitions.
  - Added a small downward drag threshold (`dy >= 6`) before dismissing keyboard to reduce accidental dismiss triggers.
- Verification:
  - `dart format lib/features/chat/chat_room_view.dart`
  - `flutter analyze`
  - `flutter test`
  - All passed.
