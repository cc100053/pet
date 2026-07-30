# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260728_pre_compaction.md`.

## Plan (2026-07-30 Internal Table RLS Hardening)
- [x] Verify both internal tables' grants, owners, service callers, and current
      advisor findings on project `ilxzpszgirhwxpeocygs`.
- [x] Enable RLS without client policies and preserve explicit client-role
      revocations.
- [x] Verify live service/client access contracts, advisors, Flutter checks,
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

## Review (2026-07-30 Internal Table RLS Hardening)
- Applied local migration
  `20260730143024_enable_rls_on_internal_scheduler_and_cleanup_tables.sql` as
  live migration `20260730143222` on `ilxzpszgirhwxpeocygs`.
- Both internal tables now have RLS enabled without policies or `FORCE RLS`.
  Client roles retain no DML privileges; `service_role` retains all required
  DML privileges and `BYPASSRLS`.
- Live runtime checks confirmed both hunger and cleanup cron groups active,
  with all 275 hunger schedule rows and 225 cleanup candidates preserved.
- The previous critical table advisory cleared. Remaining no-policy INFO
  findings are intentional for these service-only tables.
- `git diff --check` and `flutter analyze` passed. `flutter test` passed 543
  tests; the feed integration test skipped because its three Supabase test
  environment variables are unset.
