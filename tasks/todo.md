# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260818_pre_compaction.md`.

## Plan (2026-08-18 Agent Docs And Memory Optimization)
- [x] Audit `AGENTS.md`, active memory, task notes, repo-local workflows,
      recent commits, and the full worktree.
- [x] Archive exact pre-compaction snapshots and compact active memory/task
      notes to current decisions, contracts, and follow-ups.
- [x] Add only verified, non-duplicative workflow guidance to `AGENTS.md`.
- [x] Inspect the complete diff and run required format/analyzer/tests.
- [x] Commit all legitimate changes in logical groups, push `main`, verify the
      remote SHA, and leave a clean worktree.

## Active Follow-ups
- [ ] Decide whether any room-frame casing belongs in the shop. This needs an
      `items` row, a price from `docs/shop_pricing.md`, and migration /
      old-client compatibility approval.
- [ ] To share a room-frame casing across members, add server-backed state
      following the room-background precedent and version-gate it through
      `.codex/skills/shared-item-rollout/SKILL.md`.
- [ ] Monitor ASC/store outcome for iOS `3.0.1+21`; submit for App Review only
      after an explicit request.
- [ ] Confirm build 21's recorded UUIDs are absent from Crashlytics Missing
      dSYMs `[USER ACTION REQUIRED]`.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and
      `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm organic post-deploy timing for timezone-normalized pet RPCs.
- [ ] Add a leak regression test for `CachedNetworkImageView` if its cache
      manager harness can be stabilized without hanging `flutter test`.
- [ ] Convert source-text app tests to behavioral coverage where practical.
- [ ] Instrument remaining best-effort bare catches opportunistically with
      `reportSwallowedError(...)`.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.

## Current References
- Release/build/backend truth: `docs/release_status.md`.
- Full pre-compaction task state:
  `tasks/archive/todo_20260818_pre_compaction.md`.

## Review (2026-08-18 Agent Docs And Memory Optimization)
- Added a narrow `AGENTS.md` TODO for the pet-socket skill's broken bare helper
  paths and clarified touched-file formatting versus the non-writing final
  whole-tree check. No runtime or generated files changed.
- Active memory fell from 382 to 299 lines: architecture 73→73, database schema
  78→74, progress 109→65, tech stack 38→38, and UI/UX 84→49.
  `tasks/todo.md` fell from 168 baseline lines to this compact active file.
- Preserved exact pre-compaction memory snapshots in
  `memory-bank/archive/*_20260818_pre_compaction.md`; preserved the post-plan
  178-line task snapshot in `tasks/archive/todo_20260818_pre_compaction.md`.
- `git diff --check` passed. The final format check reported 328 files and 0
  changes. `flutter analyze` passed with no issues. `flutter test` passed 642
  tests with 1 skip: `feed_flow_integration_test.dart` requires unset
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN`.
