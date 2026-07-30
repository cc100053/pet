# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260728_pre_compaction.md`.

## Plan (2026-07-30 Room Invite Expiry)
- [x] Inventory current and legacy invite RPC contracts and verify live
      definitions on project `ilxzpszgirhwxpeocygs`.
- [x] Standardize first-party invite creation and regeneration on 24 hours.
- [x] Cap existing active invites with a 24-hour transition window.
- [x] Verify live definitions/data, Supabase advisors, Flutter analysis/tests,
      and current-state documentation.

## Active Follow-ups
- [ ] Run ASC submission preflight for iOS `2.3.0+13`, then submit ASC version
      `5a4313f5-29c6-4fc6-9ecf-0a5f9806670c` with attached build
      `cab2d2f1-e325-4c66-bab5-ea974a6f5ab6` if approved.
- [ ] Live-verify a real feed: confirm `pet_state`, visible satiety movement,
      and clean presigned-upload logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] TODO: Decide whether to track Supabase Edge Function deployment config;
      current `verify_jwt` behavior is documented but no `supabase/config.toml`
      exists.

## Recent Context
- Detailed release/build/backend status: `docs/release_status.md`.
- Full task state before this compaction:
  `tasks/archive/todo_20260728_pre_compaction.md`.

## Review (2026-07-30 Room Invite Expiry)
- Applied local migration
  `20260730120037_standardize_room_invite_codes_to_24_hours.sql` as live
  migration `20260730120412` on `ilxzpszgirhwxpeocygs`.
- Preserved all RPC signatures and unlimited reusable joins while standardizing
  first-party creation/regeneration defaults to 24 hours.
- Live verification: 8 active codes, 0 over 24 hours, 0 primary room/code
  expiry mismatches, and all four creation paths expose the expected defaults.
- Supabase advisors were reviewed. Their invite-function warnings reflect the
  existing authenticated `SECURITY DEFINER` contract; every function still
  performs its original `auth.uid()` and membership/owner checks. The general
  table scan also flagged two pre-existing internal tables without RLS, but
  direct ACL verification confirmed neither `anon` nor `authenticated` has
  read/write privileges.
- `git diff --check` passed. `flutter analyze` passed with no issues.
  `flutter test` passed 541 tests; the feed integration test skipped because
  its three Supabase test environment variables are unset.
