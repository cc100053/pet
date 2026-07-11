# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshots before compaction:
- `tasks/archive/todo_20260606_pre_compaction.md`
- `tasks/archive/todo_20260621_pre_compaction.md`
- `tasks/archive/todo_20260627_pre_compaction.md`

## Active Follow-ups
- [ ] Run ASC submission preflight for repo-current iOS `2.2.4+10`, then submit
      ASC version `ca26e644-9448-4ee3-8640-bac50a810057` with attached build
      `cdd2fae2-1dd1-434b-bc25-d0bccaa402fd` for review if approved.
- [ ] Live-verify a real feed on the current build: confirm `feed_validate`
      returns `pet_state`, the satiety bar moves on slow upload, and presigned
      upload logs stay clean.
- [ ] Confirm Supabase secrets/config are set for `delete_account` and
      `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm Crashlytics receives dSYMs from the Firebase Apple SPM path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
      8.0.0 upgrade.
- [ ] TODO: Decide whether to add repo-tracked Supabase Edge Function
      deployment config; current `verify_jwt` behavior is documented but no
      `supabase/config.toml` exists.

## Plan (2026-07-04 AGENTS + Memory-bank Optimization)
- [x] Read automation memory, `AGENTS.md`, active `memory-bank/*.md`,
      `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Measure active memory-bank line counts before editing.
- [ ] Inspect repo-local skills, referenced docs, scripts, Edge Functions, and
      relevant migration references before documenting workflow claims.
- [ ] Archive current active memory-bank snapshots under `memory-bank/archive/`.
- [ ] Compact active memory-bank files into current-state summaries.
- [ ] Update `AGENTS.md` only for newly verified workflow notes or TODOs.
- [ ] Run diff/line-count checks plus `flutter analyze` and `flutter test`.
- [ ] Add review notes with before/after counts, archive paths, and
      verification results.

## Plan (2026-06-27 AGENTS + Memory-bank Optimization)
- [x] Read automation memory, `AGENTS.md`, active `memory-bank/*.md`,
      `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Measure active memory-bank line counts before editing.
- [x] Inspect repo-local skills, referenced docs, scripts, Edge Functions, and
      relevant migration references before documenting workflow claims.
- [x] Archive full active memory-bank snapshots under `memory-bank/archive/`.
- [x] Compact active memory-bank files into current-state summaries.
- [x] Update `AGENTS.md` only for newly verified workflow notes or TODOs.
- [x] Run diff/line-count checks plus `flutter analyze` and `flutter test`.
- [x] Add review notes with before/after counts, archive paths, and
      verification results.

## Recent Context
- Detailed release/build/backend status now lives in `docs/release_status.md`.
- Detailed task history before this run is archived at
  `tasks/archive/todo_20260627_pre_compaction.md`.

## Review (2026-06-27 AGENTS + Memory-bank Optimization)
- Added one repo-grounded `AGENTS.md` task-management rule: keep
  `tasks/todo.md` current-state focused and move long completed plans/reviews
  to `tasks/archive/`.
- Compacted active memory-bank summaries from 353 to 346 lines:
  `architecture.md` 109 -> 105, `database-schema.md` 88 -> 88,
  `progress.md` 84 -> 81, `tech-stack.md` 41 -> 41,
  `ui-ux-guidelines.md` 31 -> 31.
- Archived exact pre-compaction memory snapshots:
  `memory-bank/archive/architecture_20260627_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260627_pre_compaction.md`,
  `memory-bank/archive/progress_20260627_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260627_pre_compaction.md`,
  `memory-bank/archive/ui_ux_guidelines_20260627_pre_compaction.md`.
- Archived task history at `tasks/archive/todo_20260627_pre_compaction.md`;
  active `tasks/todo.md` is now current follow-ups plus this run's plan/review.
- Verification passed: `wc -l memory-bank/*.md`, `git diff --check`,
  `git diff --stat`, `flutter analyze`, and `flutter test` (518 passed,
  1 skipped). The skipped test was `test/feed_flow_integration_test.dart`
  because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN` were unset.
