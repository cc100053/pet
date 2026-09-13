## Testing Helpers

### Verification is local, not CI

There is no CI gate. Before pushing code or runtime-asset changes, run on the
final tree, in this order:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Use the SDK pinned in `.fvmrc` (Flutter 3.44.0). Format only touched Dart files;
the whole-tree command above is non-writing. Several tests inspect source text,
so formatting comes before tests. Run Flutter test processes sequentially:
concurrent processes share `build/unit_test_assets` shader outputs.

For documentation-only changes, validate affected instructions, links, and
commands instead. Do not use this exception for executable scripts or runtime
assets. If CI is restored, materialize gitignored `lib/firebase_options.dart`
and `.env` from appropriate templates before analyzer/tests.

### Live-test boundary

The feed integration test reads credentials from process variables **and `.env`**.
When all required values are present, even a full `flutter test` can invoke live
services. Verify the target, dedicated test account, and authorization before
enabling it. Missing credentials produce a documented skip; do not inject
production credentials merely to turn that skip green. Cleanup is best-effort,
not proof that the test has no lasting effects.

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
- Run: `flutter test test/feed_flow_integration_test.dart`.
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

For authorized secret rotation, `tool/generate_secret.sh` reads `APPLE_*` values
from `.env`, generates the client secret, and updates the reminder date.
`scripts/generate_apple_client_secret.mjs` is the raw JWT helper. Keep `.p8`
files and generated secrets out of Git and logs. The monthly
`.github/workflows/apple_key_reminder.yml` checks
`LAST_UPDATED_APPLE_SECRET.txt` for expiry within 60 days.
