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
