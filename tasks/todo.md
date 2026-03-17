# TODO

# Plan (2026-03-17 Chat Memory Diagnostics)
- [x] Add a shared memory diagnostics service that snapshots image-cache, realtime-channel, and chat-message counts.
- [x] Wire diagnostics capture into Home room switching, chat-room lifecycle checkpoints, and fullscreen viewer open events.
- [x] Expose diagnostics through the existing debug drawer and add lightweight release breadcrumbs.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Chat Memory Diagnostics)
- [x] Implemented and verified.
- Root change:
  - Added `MemoryDiagnosticsService` to capture normalized image-cache, message-count, optimistic-message, and active-channel snapshots, with rolling in-memory history plus Crashlytics breadcrumb/custom-key emission.
  - Hooked snapshot capture into Home room switching, chat route enter/exit/load checkpoints, and fullscreen viewer open events so multi-room repros now produce comparable traces without changing runtime image policy yet.
  - Added a debug-admin diagnostics flow in the Home drawer: manual snapshot capture, image-cache clear plus snapshot, and a bottom sheet that shows recent snapshot summaries.
- Verification:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `flutter test`
  - All passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.
