# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260724_pre_compaction.md`.

## Plan (2026-07-25 Crashlytics Background Timeout Fix)
- [x] Apply the existing retryable-network classifier to Flutter framework
      error reporting so socket timeouts are recorded as non-fatal.
- [x] Prevent retryable network errors from activating the app-wide crash
      recovery screen while preserving genuine fatal handling.
- [x] Add regression coverage for the exact `tick_pet_state` timeout signature
      and the recovery-screen decision.
- [x] Run formatting, focused tests, `flutter analyze`, and `flutter test`.
- [x] Update current-state notes, commit, push, and leave a clean worktree.

## Plan (2026-07-24 AGENTS/Memory Optimization)
- [x] Audit AGENTS, active memory, task notes, local skills, referenced docs,
      scripts, Edge Functions, and relevant migrations for verified changes.
- [x] Archive full pre-compaction snapshots and keep active memory/task notes
      focused on current state and next actions.
- [x] Add only accurate, non-duplicative AGENTS workflow guidance.
- [x] Record before/after counts, inspect all worktree changes, and run required
      Flutter verification.
- [x] Group and commit all legitimate changes, push, verify, and leave a clean
      worktree.

## Active Follow-ups
- [ ] Run ASC submission preflight for iOS `2.2.6+12`, then submit ASC version
      `b7b48f69-f839-41da-ba4f-60cc0bc9647b` with attached build
      `a489f171-7dc2-416c-b332-8ec3e8fe6477` if approved.
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
  `tasks/archive/todo_20260724_pre_compaction.md`.

## Review (2026-07-25 Crashlytics Background Timeout Fix)
- Fixed iOS Crashlytics issue `5347dc92ac7a507fa084a7558fa4f4a0`:
  Flutter-reported socket/auth timeouts now reuse the central retryable-network
  classifier and are recorded as non-fatal.
- `AppCrashSignal` now applies the same classifier before showing
  `CrashUpdateGuard`, so expected background network loss cannot replace the
  app while genuine fatal errors retain the recovery flow.
- Added exact `tick_pet_state` timeout regression coverage. Focused tests
  passed, `flutter analyze` found no issues, and the final full `flutter test`
  run passed 533 tests with one environment-dependent integration test skipped.
- One pre-existing feed retry-budget timing test failed in the first full run;
  its focused rerun and the final full-suite rerun both passed.

## Review (2026-07-24 AGENTS/Memory Optimization)
- Added verified ASC release commands for explicit IPA versioning and attaching
  a `VALID` build while keeping App Review submission separately authorized.
- Compacted active memory from 314 to 257 lines: architecture 93→70, database
  schema 88→76, progress 66→44, tech stack 38→38, UI/UX 29→29.
- Archived full snapshots at
  `memory-bank/archive/architecture_20260724_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260724_pre_compaction.md`, and
  `memory-bank/archive/progress_20260724_pre_compaction.md`; archived the task
  log at `tasks/archive/todo_20260724_pre_compaction.md`.
- `git diff --check` passed. `flutter analyze` passed with no issues.
  `flutter test` passed 532 tests with one integration test skipped because
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` are
  unset.
- The first sandboxed Flutter invocation could not write the external FVM SDK
  cache; the approved rerun passed, confirming an environment-only issue.
