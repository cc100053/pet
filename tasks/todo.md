# TODO

## Plan
- [x] Add tap-outside behavior on chat input to dismiss keyboard.
- [x] Add drag-dismiss behavior on chat message list so swipe/drag closes keyboard.
- [x] Run `dart format` for touched files.
- [x] Run `flutter analyze`.
- [x] Run `flutter test`.
- [x] Update `memory-bank/progress.md` with this UX change.

## Review
- [x] Implemented and verified.
- Added `onTapOutside` to chat composer `TextField` to dismiss keyboard when user taps anywhere outside input.
- Added `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` to chat message lists (loaded, empty, loading-skeleton) so drag/down-swipe on chat content dismisses keyboard.
- Verification passed: `flutter analyze` and `flutter test`.
