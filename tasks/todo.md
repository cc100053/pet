# TODO

# Plan (2026-03-17 Crashlytics Skill Workflow Update)
- [x] Update the repo-local Crashlytics triage skill so its final report explicitly states whether action is needed in detail.
- [x] Require the skill to end by asking whether the user wants the recommended action executed.
- [x] Run `flutter analyze` and `flutter test` after the skill update.

# Review (2026-03-17 Crashlytics Skill Workflow Update)
- [x] Implemented and verified.
- Root change:
  - Updated `.codex/skills/firebase-crashlytics-triage/SKILL.md` so the required output now includes a dedicated action section that explicitly answers whether action is needed right now, explains that decision in detail, and summarizes concrete next steps when action is recommended.
  - The skill now must end by asking the user whether they want the recommended action executed.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

# Plan (2026-03-17 Crashlytics Triage)
- [x] Pull the current iOS Crashlytics fatal issues, affected versions, and sample events from Firebase MCP.
- [x] Map the top crash paths back to the current repo to determine whether each issue is still present, already fixed, or likely external/tooling noise.
- [x] Record the triage outcome and next actions in this file.

# Review (2026-03-17 Crashlytics Triage)
- [x] Investigated and summarized.
- Scope:
  - Firebase MCP target confirmed as `pet-app-702be`, using iOS app `1:69520994244:ios:d6fc14579fda1a1ca33e91`.
  - Current repo/app version is `1.0.5+1`, but the fatal Crashlytics events in the last 7 days are from `1.0.0 (15)`, `1.0.1 (3)`, and `1.0.2 (1)`. No sampled fatal event in this pull came from `1.0.5`.
- Findings:
  - `1d17d2cef8aaab07652ca69c9b7ef756` (`google_fonts` host lookup failure, 1 event / 1 user, `2026-03-10T11:44:08Z`):
    - Most likely still present in current code. `lib/shared/theme/app_theme.dart` still builds the global text theme from `GoogleFonts.poppinsTextTheme()` with no bundled-font fallback, so an offline DNS failure at bootstrap can still throw before the app settles.
    - This is not a native iOS crash; it is a runtime font fetch exception recorded as fatal by the global zone/error hooks in `lib/main.dart`.
  - `51d63e291417d0f7cfcb5c37d165c1f6` (legacy `chat_message_list.dart` null check, 3 events / 2 users across sampled history, `2026-03-08T00:50:50Z`, `2026-03-10T04:58:12Z`):
    - Already fixed in the repo. The blamed file no longer exists, and `git log --diff-filter=D` shows `lib/features/chat/chat_message_list.dart` was deleted in commit `89f61ce` on `2026-03-10`.
    - Current chat code uses `lib/features/chat/chat_room_view_v2.dart` plus `lib/features/chat/widgets/deterministic_chat_list.dart`, so this issue is old-build noise until users leave `1.0.0 (15)`.
  - `6cd7b77a79bd9f95739614da34231c2c` (Flutter Impeller `shadow_path_geometry.cc`, 1 event / 1 user, `2026-03-11T04:00:27Z`):
    - Evidence points to a Flutter engine / Impeller raster crash, not an app-owned Dart exception. The blamed frame is fully inside Flutter raster code with no Dart frames.
    - Context is thin: the breadcrumbs show room switching, camera open, feed send success, then another route push right before the crash. The event memory footprint was high (`~6.0 GB used, ~307 MB free`), so memory pressure may be a contributing factor, but the stack alone is not enough to identify a precise app-level root cause.
  - `faba429c9f9c47073b49d24eb91366af` (`AuthRetryableFetchException` refresh-token path, 1 event / 1 user, `2026-03-12T15:31:35Z`):
    - Most likely a reporting-classification problem, not a true crash. The thrown exception is a retryable auth/network error, but `lib/main.dart` reports all uncaught zoned errors as `fatal: true`.
    - The related high-volume non-fatal issue (`5f2e809db34b69a598977233280e18a1`) shows the same Supabase/app-config network family during `force_update_check`, which supports the conclusion that transient network/auth failures are being over-promoted into crash signals.
- Recommended next actions:
  - Fix first: stop treating transient `google_fonts` network fetch failures as fatal by bundling the font locally or replacing the runtime-fetched theme path.
  - Fix second: narrow fatal reporting in `lib/main.dart` so known retryable network/auth exceptions are recorded non-fatally instead of tripping the crash screen and polluting fatal issue counts.
  - Monitor separately: the Impeller crash needs more samples or a Flutter-engine upgrade correlation before making an app-level code change.

# Plan (2026-03-17 Crashlytics Cleanup)
- [x] Inspect the current Google Fonts loading path and global crash-reporting hooks to choose the minimal safe fixes.
- [x] Patch the app to avoid runtime font fetch crashes and downgrade retryable network/auth exceptions from fatal.
- [x] Update task tracking and memory-bank notes for the new behavior.
- [x] Run `flutter analyze` and `flutter test` to verify the changes.

# Review (2026-03-17 Crashlytics Cleanup)
- [x] Implemented and verified.
- Root change:
  - Replaced the global light-theme dependency on `GoogleFonts.poppinsTextTheme()` with a local Material typography base, so app startup no longer relies on a runtime fetch to `fonts.gstatic.com`.
  - Added fatality classification inside `CrashReportingService.reportError`, so requested-fatal reports are downgraded to non-fatal for retryable network/auth transport failures such as `AuthRetryableFetchException`, DNS/socket failures, and timeouts.
  - Added unit coverage for the new crash fatality classifier in `test/services/crash/crash_reporting_service_test.dart`.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`, as expected.

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

# Plan (2026-03-17 Chat Bright Status Bar)
- [x] Inspect the chat route and compare bright/dark status-bar handling with other screens.
- [x] Apply the minimal fix so bright chat backgrounds use dark iPhone status-bar content while dark themes keep light content.
- [x] Update memory-bank notes if behavior changed, then run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Chat Bright Status Bar)
- [x] Implemented and verified.
- Root change:
  - Kept the existing bright/dark room-background decision path in `ChatRoomViewV2`, but now pass the same resolved `overlayStyle` directly into the chat `AppBar`.
  - This keeps iPhone status-bar content aligned with the active chat theme: bright chat backgrounds use dark time/battery text, while dark chat themes still use light content.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without the required Supabase env vars, as expected.

# Plan (2026-03-17 Global AppBar Status Bar)
- [x] Audit all AppBar/status-bar handling and identify the correct shared default.
- [x] Enforce dark status-bar content for non-Home/non-Chat AppBars while preserving explicit dark-theme overrides.
- [x] Update memory-bank notes, then run `flutter analyze` and `flutter test`.

# Review (2026-03-17 Global AppBar Status Bar)
- [x] Implemented and verified.
- Root change:
  - Added `AppStatusBarStyles.light` to the shared `AppBarTheme` inside `AppTheme.lightTheme`, so every standard light-surface `AppBar` now defaults to dark iPhone status-bar content.
  - Home and chat keep their explicit route-level overlay handling, so they remain the only places where dark-theme status-bar content can appear.
- Verification:
  - `flutter analyze`
  - `flutter test`
  - Both passed; `test/feed_flow_integration_test.dart` remained skipped without the required Supabase env vars, as expected.
