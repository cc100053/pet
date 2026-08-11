# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260811_pre_compaction.md`.

## Plan (2026-08-11 Agent Docs And Memory Optimization)
- [x] Audit `AGENTS.md`, active memory, task notes, local workflows, recent
      commits, and the complete worktree without discarding shared-session work.
- [x] Archive exact pre-compaction snapshots and reduce active memory/task notes
      to current decisions, contracts, and follow-ups.
- [x] Add only verified, non-duplicative workflow guidance to `AGENTS.md`.
- [x] Inspect all diffs and run required Flutter verification.
- [x] Commit the logical documentation set, push `main`, verify the remote SHA,
      and leave a clean worktree.

## Active Follow-ups
- [ ] Monitor ASC/store outcome for iOS `2.3.4+18`; submit for App Review only
      after an explicit request.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm organic post-deploy timing for the timezone-normalized pet RPCs.
- [ ] Add a leak regression test for `CachedNetworkImageView` if the cache
      manager harness can be stabilized without hanging `flutter test`.
- [ ] Instrument remaining best-effort bare catches opportunistically with
      `reportSwallowedError(...)`.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.

## Current References
- Release/build/backend truth: `docs/release_status.md`.
- Full pre-compaction task state:
  `tasks/archive/todo_20260811_pre_compaction.md`.

## Review (2026-08-11 Agent Docs And Memory Optimization)
- Added three repo-grounded `AGENTS.md` guardrails: archive-based Crashlytics
  dSYM upload/re-upload, timezone validation without `pg_timezone_names`
  scans, and disposal of listener-owned `ImageInfo` clones.
- Active memory fell from 287 to 252 lines: architecture 93→71, database schema
  66→67 (one new current timezone contract), progress 61→47, tech stack 38→38,
  and UI/UX 29→29. `tasks/todo.md` fell from 221 archived lines to 54 active
  lines after this review.
- Preserved exact pre-compaction snapshots in
  `memory-bank/archive/{architecture,database_schema,progress}_20260811_pre_compaction.md`
  and `tasks/archive/todo_20260811_pre_compaction.md`.
- The worktree started clean; the final diff is one documentation-only group
  with no runtime, generated, release, or unrelated file changes.
- `git diff --check` passed. `flutter analyze` passed with no issues.
  `flutter test` passed 613 tests with 1 skip: the live feed integration test
  requires unset `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN`.
