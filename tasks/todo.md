# Notify Friend Finding #3 Fix

## Plan
- [x] Confirm root cause and impacted request paths for `notify_friend`.
- [x] Harden webhook/auth gating so unsigned webhook mode is impossible.
- [x] Ensure webhook path always validates message data from DB (no payload spoof bypass).
- [x] Verify feed/chat/hunger notification paths still work logically.
- [x] Run required checks: `flutter analyze` and `flutter test`.
- [x] Update memory docs and add a short review summary.

## Review
- Updated `notify_friend` to fail closed on webhook auth by removing unsigned webhook fallback.
- Webhook requests now always canonicalize content from `messages` and reject missing/non-owned records.
- Webhook recipients are constrained to active `room_members` (and sender excluded for non-hunger sends).
- Verification: `flutter analyze` (clean) and `flutter test` (pass, with existing env-gated integration test skipped).
