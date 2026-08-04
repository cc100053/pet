# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260728_pre_compaction.md`.

## Plan (2026-08-04 Agent Docs And Memory Optimization)
- [ ] Audit `AGENTS.md`, active memory, task notes, repo-local workflows, and
      every outstanding worktree change without discarding shared-session work.
- [ ] Archive full active-memory snapshots, then compact current-state notes
      and add only verified, non-duplicative agent workflow guidance.
- [ ] Run diff, analyzer, and test verification; document results and line-count
      changes; commit logical groups, push, and verify a clean worktree.

## Plan (2026-07-30 Internal Table RLS Hardening)
- [x] Verify both internal tables' grants, owners, service callers, and current
      advisor findings on project `ilxzpszgirhwxpeocygs`.
- [x] Enable RLS without client policies and preserve explicit client-role
      revocations.
- [x] Verify live service/client access contracts, advisors, Flutter checks,
      and current-state documentation.

## Plan (2026-08-02 iOS 2.3.1 Release Notes Sync)
- [x] Bump the app to `2.3.1+14` and add localized bundled What's New copy.
- [x] Sync localized ASC metadata while preserving descriptions and EULA
      footers.
- [x] Archive, validate, upload, process, and attach the iOS build.
- [x] Run localization, metadata terms, analyzer, and full Flutter checks.

## Plan (2026-08-03 iOS 2.3.2 Release Notes Sync)
- [x] Bump the app to `2.3.2+15` and add localized bundled What's New copy
      (generic bug-fix/stability wording; the underlying commits were
      internal-only Crashlytics/OOM-detection work with no user-visible
      change).
- [x] Sync localized ASC metadata while preserving descriptions and EULA
      footers.
- [x] Archive, validate, upload, process, and attach the iOS build.
- [x] Run localization, metadata terms, analyzer, and full Flutter checks.

## Active Follow-ups
- [ ] Monitor ASC/store outcome for iOS `2.3.2+15`; submit for App Review only
      after an explicit request.
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
- Completed iOS `2.3.2+15` release-notes-sync; ASC version/build IDs and exact
  processing state are recorded in `docs/release_status.md`.
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

## Review (2026-08-02 iOS 2.3.1 Release Notes Sync)
- ASC version `91382e2c-a755-42cc-96e6-5e3628b426cf` is
  `PREPARE_FOR_SUBMISSION`; build `1b2dbb59-b9a9-49b9-a3e0-68f2b1fac618` is
  `VALID`, encryption exempt, and attached.
- Localized ASC metadata was verified for en-US, ja, ko, and zh-Hant with
  direct EULA footers preserved. App Review submission was intentionally not
  performed.
- `flutter gen-l10n`, the App Store metadata terms test, `flutter analyze`,
  and `flutter test` completed successfully; the feed integration test remains
  skipped because its required Supabase test environment variables are unset.

## Review (2026-08-03 iOS 2.3.2 Release Notes Sync)
- ASC version `2120a1f4-f8cf-4f2a-9527-b177b20e9210` is `PREPARE_FOR_SUBMISSION`;
  build `36348531-630d-47a7-b0b8-be9ea7fc89b6` is `VALID` and attached.
- Localized ASC metadata was verified for en-US, ja, ko, and zh-Hant with
  direct EULA footers preserved. App Review submission was intentionally not
  performed.
- `flutter gen-l10n`, the App Store metadata terms test, `flutter analyze`,
  and `flutter test` (579 passed) completed successfully.
