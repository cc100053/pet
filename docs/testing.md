## Testing Helpers

### Automated checks and local verification

`.github/workflows/ci.yml` runs formatting, analysis, the full test suite and
documentation links on pull requests, pushes to main and manual dispatch. It
reads the SDK pin from `.fvmrc`, installs locked dependencies, and copies fake
offline fixtures from `.github/fixtures/` into the gitignored Firebase/env
files before generating `.env.app`. It needs no production secrets and never
builds or deploys the app. Follow its bootstrap steps only in a clean test
checkout; never overwrite a developer's real config with the CI fixtures.

Main had no branch protection when checked on 2026-10-22, so workflow failures
report problems but do not block direct pushes. `[USER ACTION REQUIRED]` if a
mandatory merge gate is desired: require the `verify` check in branch protection
or a ruleset after confirming a successful run. Keep the local final checks
below before pushing executable/asset changes and before release.

`.githooks/pre-push` (enable per clone with
`git config core.hooksPath .githooks`) format-checks pushed Dart files, runs
`flutter analyze`, and link-checks pushed Markdown; it skips `flutter test`.
Before pushing code or runtime-asset changes, run on the final tree, in this
order:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Use the SDK pinned in `.fvmrc`. Format only touched Dart files;
the whole-tree command above is non-writing. Several tests inspect source text,
so formatting comes before tests. Run Flutter test processes sequentially:
concurrent processes share `build/unit_test_assets` shader outputs.

For documentation-only changes, run `scripts/check_doc_links.sh <files>` and
check affected instructions and commands instead. Do not use this exception for executable scripts or runtime
assets.

The app bundles `.env.app`, not `.env`. Run `scripts/write_app_env.sh` after
creating or changing `.env` and before any `flutter run`, `test` or `build`;
without it the build stops at "Error detected in pubspec.yaml". It copies
only the public client keys `lib/services/env.dart` reads, because every
bundled asset ships to users in plain text; server secrets (R2, webhook
secrets, Apple keys) must never reach it.

### Risk-based behavior checks

Before implementation, identify the behavior that could break and choose the
checks below. Record a short decision in commentary or `tasks/todo.md`:
**changed behavior → test level → concrete pass/fail signal**. Execute the
chosen checks after the change as part of the task; the user need not request
testing separately. An explicit simulator/device test request selects that
level even when automated tests already pass.

| Change / risk | Behavior verification |
| --- | --- |
| Documentation or agent instructions only | Validate instructions, links and affected commands; walk through the decision branches. |
| Formatting, trivial edits or behavior-preserving refactors | Use relevant existing tests; add a test only when a meaningful regression is otherwise uncovered. |
| Non-trivial logic, retries, persisted state, auth, purchases or backend contracts | Run focused automated checks for the changed behavior, failure paths and relevant old data/contracts. For bug fixes, demonstrate the regression against the prior implementation when feasible, then verify the fix. |
| Layout, navigation, keyboard, dialogs or animation timing | Use widget tests; add a simulator rendering/interaction check when those tests cannot establish the actual platform behavior. |
| Native integration, local file lifetime, background/resume or process restart | Run applicable automated regressions plus a simulator check of the platform boundary. Use actual process termination/relaunch when testing restart recovery. |
| Hardware, iCloud transfer, APNs delivery, native purchases/review dialogs or OS eviction/OOM behavior | Validate what the simulator supports, then perform a targeted real-device check for the remaining claim. Mark unavailable required checks `[USER ACTION REQUIRED]`. |

These behavior checks supplement the final-tree gate above; they do not waive
it for code or runtime-asset changes. Physical-device testing is selected for a
specific uncovered risk, rather than required after every edit. Before release,
include a short smoke check of the affected critical flow. Once the selected
checks pass, expand or repeat them only for new changes, failures or unresolved
risks.

Report the decision and actual results, including checks skipped and why.
Distinguish isolated harnesses, mocked services and copied private methods from
the full app flow; report the device/runtime and tested commit for platform
runs. A successful launch alone proves startup, not the changed feature.
Live service/account/notification tests retain the [live-test boundary](#live-test-boundary).

### iOS simulator builds on Xcode 27

`flutter build ios --simulator` / `flutter run` on a simulator fail in
`debug_unpack_ios` ("does not contain architectures arm64 x86_64"): Xcode 27's
`lipo -verify_arch` accepts only one architecture, and Flutter 3.44 passes two.
Device and archive builds (arm64 only) are unaffected. Build arm64-only instead:

```sh
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug \
  -sdk iphonesimulator -destination 'id=<SIMULATOR_UDID>' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -derivedDataPath build/ios_sim build
```

then install `build/ios_sim/Build/Products/Debug-iphonesimulator/Runner.app`.

### Simulator verification procedure

1. Record the source commit, working-tree state, pinned SDK, simulator UDID and
   OS. Prefer XcodeBuildMCP when available: inspect session defaults, select
   the correct Runner workspace/scheme/device, then build and launch with the
   arm64 settings above. Verify the normal app opens.
2. Exercise the changed path in the app using a verified test account when
   authorized. If account access or UI automation is unavailable, use an
   isolated temporary entry point under ignored `build/` with production
   components and separate Hive boxes/directories. Preserve the normal app
   bundle before building a custom `FLUTTER_TARGET`; keep the entry point out
   of release wiring. Use test-generated photos and mocked uploads for local
   checks, retaining the live-test boundary for real writes and notifications.
3. Assert the relevant happy path and failure/recovery cases. For feed photo
   lifetime, verify actual photo pixels through each bite after fast upload,
   retry after deleting the picker source, and persisted-job recovery after
   terminating/relaunching the simulator process. Seed orphan/staging files
   in the isolated directory and check that startup removes only those files
   while preserving the pending photo; verify cleanup after acknowledgement.
4. Capture visible output and inspect assertions/results, rather than treating
   a running app or a green status label as feature verification. Save enough
   evidence to identify the source, environment, scenarios and limitations.
5. Stop the temporary entry point, reinstall/launch the preserved normal app
   and verify its normal screen. Restore any temporary build configuration,
   preserve existing account/room data, and check the worktree for accidental
   changes. Keep required real-device or live-service checks explicitly pending.

### Live-test boundary

The feed integration test requires the process variable
`PET_RUN_LIVE_FEED_TEST=1` before it reads credentials or contacts a service.
Without that opt-in, even existing credentials in process variables or `.env`
cannot enable it. After opt-in, credentials are read from both places; missing
or blank credentials produce a documented skip. Verify the target, dedicated
test account, and authorization before enabling it. Do not inject production
credentials merely to turn that skip green. Cleanup is best-effort, not proof
that the test has no lasting effects. Routine CI does not set the opt-in.

The webhook helper sends to the configured recipient. Run it only for an
authorized notification test. Transactional SQL checks also require a verified
target and authorized scope, even when they roll back writes.

### Edge Function auth
- `feed_validate` and `avatar_upload` validate callers inside the function with
  `auth.getUser()` using the Authorization header.
- `notify_friend` uses function-level auth checks because it also supports
  server/webhook-style notification dispatch.

### Integration test: feed -> Edge -> DB -> chat
- Required env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_TEST_REFRESH_TOKEN`.
- Obtain `SUPABASE_TEST_REFRESH_TOKEN` through the dedicated test account
  authentication flow; keep it out of logs and committed files.
- Run only after verification/authorization:
  `PET_RUN_LIVE_FEED_TEST=1 flutter test test/feed_flow_integration_test.dart`.
- Test creates a room via `create_room`, calls `feed_validate`, asserts the
  message record, then attempts to delete the room to clean up.
- Feed upload pipeline behavior, response compatibility, latency diagnosis, and
  existing-user queue reconciliation are documented in
  `docs/feed_upload_pipeline.md`.

### Feed upload focused tests
- Edge Function response-path guard:
  `flutter test test/feed_validate_function_test.dart`.
- Durable queue retry/reconciliation guard:
  `flutter test test/features/feed/feed_upload_queue_test.dart`.

### Admin debug currency

- Client wiring/error reporting: `flutter test test/features/home/home_debug_currency_test.dart`.
- On verified project `ilxzpszgirhwxpeocygs`, run
  `test/supabase/debug_profile_balances_checks.sql` via Supabase MCP as postgres.
  It selects an existing admin profile, simulates claims transactionally and
  rolls back all balance/timestamp writes. Profiles have only the timestamp
  trigger; confirm that remains true before re-running against a changed schema.
  This validates DB authorization/arithmetic; device testing still needs a
  rebuilt app and a real admin session.

### Shared room frames
- Client requests/cache/stale response and picker retry coverage:
  `flutter test test/features/home/room_frame_provider_test.dart test/features/home/room_frame_test.dart`.
- Execute `test/supabase/room_frame_state_checks.sql` via Supabase MCP as
  postgres on the verified target. It tests level boundaries, partner
  read/write, nonmember/session denial, server timestamps, and grandfathered
  upserts, then rolls back every frame write without changing pet/membership
  state. It needs existing active rooms at levels 1/2/3/4/5/7/8.
- On two upgraded devices: confirm a frame, verify the partner card changes
  without refresh, then background the partner, change it again, and verify
  on resume. Old binaries retain local-only frame behavior. Unconfirmed Hive
  choices must never overwrite an existing shared casing.

### Notify Friend webhook test
- Script: `scripts/test_notify_friend.sh`
- Required env vars:
  - `NOTIFY_WEBHOOK_URL`, `NOTIFY_WEBHOOK_SECRET`
  - `RECIPIENT_ID` (user id with a row in `device_tokens`)
  - `ROOM_ID`, `SENDER_ID`, `MESSAGE_ID`
- Run: `NOTIFY_WEBHOOK_URL=... NOTIFY_WEBHOOK_SECRET=... RECIPIENT_ID=... ROOM_ID=... SENDER_ID=... MESSAGE_ID=... scripts/test_notify_friend.sh`

### Push notification acceptance checks (custom payload/UI)
- Verify payload fields in `notify_friend` send path include:
  - `message_kind` (`message_type` legacy fallback), `pet_name`, `sender_name`, `pet_avatar_url`, `image_url`, `caption`, `text_body`, `body_full`, `title_app_name`, `title_full`.
- Locale title rule:
  - `title_full` equals pet name only.
  - If pet name is longer than 7 characters, it is collapsed to `7 chars + ...`.
- Body rule:
  - `message_kind=text` => body is `<sender>: <text_body>`.
  - `message_kind=image_feed` => body uses localized `<sender> fed <petName>` phrasing.
  - If sender name is longer than 7 characters, sender display is collapsed to `7 chars + ...`.
- Android visual rule:
  - Notification uses `MessagingStyle` and groups by room (`room_id`).
  - Large icon shows pet avatar with app icon badge at bottom-right.
- iOS visual rule:
  - Notification Service Extension rewrites title/body and sets thread id (`room_<room_id>`).
  - Avatar attachment is composed with app badge overlay.
  - Feed notifications attach feed image preview when `image_url` is provided.

### iOS extension setup note
- The Xcode project includes `PetTomoNotificationServiceExtension`.
- If APNs rich media does not appear in non-foreground states, confirm:
  - payload contains `aps.mutable-content = 1`
  - extension target is signed and embedded in Runner app
  - extension bundle id matches provisioning profile.

### Sign in with Apple secret maintenance

For authorized secret rotation, `scripts/generate_apple_secret.sh` reads `APPLE_*` values
from `.env`, generates the client secret, and updates the reminder date.
`scripts/generate_apple_client_secret.mjs` is the raw JWT helper. Keep `.p8`
files and generated secrets out of Git and logs. The monthly
`.github/workflows/apple_key_reminder.yml` checks
`LAST_UPDATED_APPLE_SECRET.txt` for expiry within 60 days.
