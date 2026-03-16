# TODO

# Plan (2026-03-17 Thumbnail Stretch Fix)
- [x] Identify the shared thumbnail-path change that altered Pet Home gallery and chat image thumbnail rendering.
- [x] Restore the previous thumbnail presentation while keeping cache-focused protections non-visual.
- [x] Run `flutter analyze` and `flutter test`, then record the correction.

# Review (2026-03-17 Thumbnail Stretch Fix)
- [x] Implemented and verified.
- Root change:
  - Removed the extra exact-size provider resize inside `lib/shared/ui/cached_network_image_view.dart` that had changed the displayed aspect/presentation for both Pet Home gallery and chat image thumbnails.
  - Kept the outer `CachedNetworkImage` cache-bound settings in place, so the protection remains focused on cache/decode behavior instead of altering the rendered thumbnail path.
  - Updated repo notes and lessons to reflect that shared thumbnail rendering must stay separate from cache sizing logic.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Clean Up tasks/todo.md)
- [x] Move completed tasks from `tasks/todo.md` to `memory-bank/progress.md`.
- [x] Clear `tasks/todo.md` to keep it focused on pending items.
