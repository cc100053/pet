# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260728_pre_compaction.md`.

## Plan (2026-07-28 AGENTS/Memory Optimization)
- [x] Audit AGENTS, active memory/task notes, local skills, referenced docs,
      scripts, Edge Functions, and recent repository changes.
- [x] Archive pre-compaction memory/task snapshots and keep active files
      focused on current contracts, release state, and follow-ups.
- [x] Add only verified, non-duplicative workflow guidance to AGENTS.md.
- [x] Record line-count changes, inspect the full diff, and run required
      Flutter verification.
- [x] Commit and push all legitimate changes, verify the remote branch, and
      leave the worktree clean.

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

## Review (2026-07-28 AGENTS/Memory Optimization)
- Added the Level 2 socket-export guardrail to AGENTS.md, grounded in the local
  calibration skill and workflow; no other non-duplicative workflow addition
  was warranted.
- Compacted active memory from 270 to 236 lines: architecture 73→63, database
  schema 76→69, progress 54→37, tech stack 38→38, UI/UX 29→29.
- Archived full pre-compaction snapshots under
  `memory-bank/archive/*_20260728_pre_compaction.md` and archived the completed
  task history at `tasks/archive/todo_20260728_pre_compaction.md`.
- `git diff --check` passed. `flutter analyze` passed with no issues.
  `flutter test` passed 538 tests; the feed integration test skipped because
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` are
  unset.
- The worktree began clean; the complete diff is documentation/task history
  from this automation and belongs in one documentation commit.
