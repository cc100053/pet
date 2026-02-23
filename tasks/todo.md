# Findings #3-#5

## Feed Reward Pending UX (Done)
### Plan
- [x] Add immediate Home HUD feedback when feed reward is pending.
- [x] Keep backend reward/cooldown as source of truth (no optimistic coin mutation).
- [x] Clear pending UI on both success and failure paths.
- [x] Localize pending label for supported languages.
- [x] Verify with `flutter analyze` and `flutter test`.

### Review
- Added a small pending pill near the candy HUD that appears right after feed send and clears when reward resolution completes.
- Pending state is count-based to handle overlapping feed sends and is consumed after reward refresh or failure.
- No changes to reward correctness: coins still update only from server-side `feed_validate` + profile refresh.
- Verification: `flutter analyze` (clean) and `flutter test` (pass; env-gated integration test skipped).

## Feed Reward Latency (Done)
### Plan
- [x] Reduce post-send latency by starting compression immediately after image selection.
- [x] Reduce compression passes with early-exit profile selection while preserving visual quality.
- [x] Keep reward correctness and notification/message flow unchanged.
- [x] Verify with `flutter analyze` and `flutter test`.
- [x] Document the latency-focused update in memory docs.

### Review
- Feed capture now starts compression as soon as an image is picked, then reuses that prepared result at send time when possible.
- Compression profiles now early-exit once they hit the target-size bucket or upload-cap-safe size, reducing sequential encode passes and send latency.
- Reward/notification correctness is unchanged: candies still come from server `feed_validate` response and cooldown logic remains authoritative.
- Verification: `flutter analyze` (clean) and `flutter test` (pass; env-gated integration test skipped).

## Feed Compression Hardening (Done)
### Plan
- [x] Implement true client-side feed compression with quality-preserving multi-pass encoding.
- [x] Keep upload/notification/message behavior unchanged (only mutate upload bytes/content-type).
- [x] Verify analyzer/tests: `flutter analyze`, `flutter test`.
- [x] Update memory docs with compression behavior + review notes.

### Review
- Replaced feed upload passthrough with multi-pass WebP compression profiles (dimension/quality ladder) and emergency fallback profiles for oversized sources.
- Kept send/message/notification flow intact: only upload bytes + MIME are changed before invoking `feed_validate`; no DB or notification logic changed.
- Removed premature 10MB client rejection for feed photos and now allow compression first, while preserving a 30MB hard input guard to avoid extreme-memory uploads.
- Verification: `flutter analyze` (clean) and `flutter test` (pass; existing env-gated integration test skipped).

## Finding #3 (Done)
### Plan
- [x] Confirm root cause and impacted request paths for `notify_friend`.
- [x] Harden webhook/auth gating so unsigned webhook mode is impossible.
- [x] Ensure webhook path always validates message data from DB (no payload spoof bypass).
- [x] Verify feed/chat/hunger notification paths still work logically.
- [x] Run required checks: `flutter analyze` and `flutter test`.
- [x] Update memory docs and add a short review summary.

### Review
- Updated `notify_friend` to fail closed on webhook auth by removing unsigned webhook fallback.
- Webhook requests now always canonicalize content from `messages` and reject missing/non-owned records.
- Webhook recipients are constrained to active `room_members` (and sender excluded for non-hunger sends).
- Verification: `flutter analyze` (clean) and `flutter test` (pass, with existing env-gated integration test skipped).

## Finding #4 (Done)
### Plan
- [x] Confirm root cause in `supabase/functions/delete_account/index.ts`.
- [x] Add missing `serve` import and keep function behavior unchanged.
- [x] Run required checks: `flutter analyze` and `flutter test`.
- [x] Deploy updated `delete_account` via Supabase MCP and verify active version.
- [x] Update memory docs with final review notes.

### Review
- Added missing `serve` import from Deno std HTTP in `delete_account` so runtime can start the handler.
- Kept deletion/auth behavior unchanged (`auth.getUser` + `auth.admin.deleteUser`).
- Verification: `flutter analyze` (clean), `flutter test` (pass; env-gated integration test skipped).
- Deployed via MCP: `delete_account` version `2`, status `ACTIVE`, `verify_jwt=true`.

## Finding #5 (Done)
### Plan
- [x] Define and apply consistent upload limits + MIME allow-list for feed/avatar paths.
- [x] Add server-side payload size guards to `feed_validate` before decode/upload.
- [x] Add server-side payload size guards to `avatar_upload` before decode/upload.
- [x] Add client preflight checks for feed and avatar uploads with clear localized errors.
- [x] Ensure oversized uploads fail before message insert/notification dispatch.
- [x] Run required checks: `flutter analyze` and `flutter test`.
- [x] Deploy updated `feed_validate` and `avatar_upload` via Supabase MCP.
- [x] Update memory docs with review notes.

### Review
- Added shared Flutter upload limits in `lib/shared/upload_limits.dart` (`10MB`, allowed MIME set) and wired preflight checks in feed/profile upload flows.
- Added localized oversized-image message (`errorImageTooLarge`) across EN/JA/KO/zh/zh-TW and mapped backend `413/image_too_large` to that message in `user_facing_error`.
- Hardened `feed_validate` and `avatar_upload` with MIME allow-list, base64-size estimation, decoded-byte checks, and `413 image_too_large` responses before upload/DB side effects.
- Notification/message safety: oversized feed payloads now fail before `process_feed_event` and before `notify_friend`, preventing ghost messages/notifications.
- Verification: `flutter analyze` (clean), `flutter test` (pass; env-gated integration test skipped).
- Deployed via MCP: `feed_validate` version `14` and `avatar_upload` version `3`, both `ACTIVE`, `verify_jwt=true`.
