## Testing Helpers

### CI
- `.github/workflows/ci.yml` runs on pushes to `main`, on pull requests, and on
  demand: `dart format --set-exit-if-changed lib test`, then `flutter analyze`,
  then `flutter test`.
- It pins the same Flutter as `.fvmrc` (`3.44.0`). A different SDK ships a
  different formatter, which is what let the tree drift out of canonical form
  before the gate existed.
- Format runs first on purpose. Several tests assert on source text, so an
  unformatted tree surfaces as unrelated test failures rather than as a
  formatting complaint.

### Edge Function auth
- `feed_validate` and `avatar_upload` validate callers inside the function with
  `auth.getUser()` using the Authorization header.
- `notify_friend` uses function-level auth checks because it also supports
  server/webhook-style notification dispatch.

### Integration test: feed -> Edge -> DB -> chat
- Required env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_TEST_REFRESH_TOKEN`.
- Obtain `SUPABASE_TEST_REFRESH_TOKEN` by logging in and printing
  `Supabase.instance.client.auth.currentSession?.refreshToken`.
- Run: `flutter test test/feed_flow_integration_test.dart`.
- Test creates a room via `create_room`, calls `feed_validate`, asserts the
  message record, then deletes the room to clean up.
- Feed upload pipeline behavior, response compatibility, latency diagnosis, and
  existing-user queue reconciliation are documented in
  `docs/feed_upload_pipeline.md`.

### Feed upload focused tests
- Edge Function response-path guard:
  `flutter test test/feed_validate_function_test.dart`.
- Durable queue retry/reconciliation guard:
  `flutter test test/features/feed/feed_upload_queue_test.dart`.

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
