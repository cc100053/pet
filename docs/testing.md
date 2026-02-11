## Testing Helpers (Phase 1)

### In-app tools (temporary)
- Create Test Room: calls `create_room` RPC and displays `room_id` + invite code.
- Run Feed Test: calls `functions.invoke('feed_validate')` with a sample payload.

Remove these UI controls once Phase 1 testing is complete.

### Debug logs
- `main.dart` logs `JWT` + `UID` on `AuthChangeEvent.signedIn`.
- Keep only if needed for auth debugging; remove before release.

### Edge Function auth
- `feed_validate` currently has `verify_jwt = false` due to Edge gateway JWT rejection.
- Function still validates requests with `auth.getUser()` using the Authorization header.
- Re-enable `verify_jwt` after resolving Edge JWT verification.

### Integration test: feed -> Edge -> DB -> chat
- Required env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_TEST_REFRESH_TOKEN`.
- Obtain `SUPABASE_TEST_REFRESH_TOKEN` by logging in and printing
  `Supabase.instance.client.auth.currentSession?.refreshToken`.
- Run: `flutter test test/feed_flow_integration_test.dart`.
- Test creates a room via `create_room`, calls `feed_validate`, asserts the
  message record, then deletes the room to clean up.

### Notify Friend webhook test
- Script: `scripts/test_notify_friend.sh`
- Required env vars:
  - `NOTIFY_WEBHOOK_URL`, `NOTIFY_WEBHOOK_SECRET`
  - `RECIPIENT_ID` (user id with a row in `device_tokens`)
  - `ROOM_ID`, `SENDER_ID`, `MESSAGE_ID`
- Run: `NOTIFY_WEBHOOK_URL=... NOTIFY_WEBHOOK_SECRET=... RECIPIENT_ID=... ROOM_ID=... SENDER_ID=... MESSAGE_ID=... scripts/test_notify_friend.sh`

### Push notification acceptance checks (custom payload/UI)
- Verify payload fields in `notify_friend` send path include:
  - `message_type`, `pet_name`, `pet_avatar_url`, `image_url`, `caption`, `text_body`, `title_app_name`, `title_full`.
- Locale title rule:
  - Device locale `ja-*` => title begins with `ペットモ`.
  - Any non-`ja-*` locale => title begins with `PetTomo`.
- Body rule:
  - `message_type=image_feed` => body starts with `🖼️` and includes caption when present.
  - `message_type=text` => body equals raw text message.
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
