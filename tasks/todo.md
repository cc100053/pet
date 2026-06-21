# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshots before compaction:
- `tasks/archive/todo_20260606_pre_compaction.md`
- `tasks/archive/todo_20260621_pre_compaction.md`

## Active Follow-ups
- [ ] Run ASC submission preflight for repo-current iOS `2.2.2+8`, then submit
      ASC version `1761de51-ec73-46e4-8b6f-134d9c650e1d` with attached build
      `702c2f8d-770f-40ec-a013-19cab3c1d098` for review if approved.
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

## Plan (2026-06-21 AGENTS + Memory-bank Optimization)
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

## Review (2026-06-21 AGENTS + Memory-bank Optimization)
- Updated `AGENTS.md` with the verified direct App Store Connect API fallback
  for ASC wrapper `-50` failures: use `scripts/asc_version_localization_sync.py`
  with bundled Codex Python.
- Compacted active memory-bank summaries from 364 to 341 lines:
  `architecture.md` 101 -> 97, `database-schema.md` 90 -> 88,
  `progress.md` 101 -> 84, `tech-stack.md` 41 -> 41,
  `ui-ux-guidelines.md` 31 -> 31.
- Archived exact pre-compaction snapshots:
  `memory-bank/archive/architecture_20260621_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260621_pre_compaction.md`,
  `memory-bank/archive/progress_20260621_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260621_pre_compaction.md`,
  `memory-bank/archive/ui_ux_guidelines_20260621_pre_compaction.md`.
- Archived the long task log at
  `tasks/archive/todo_20260621_pre_compaction.md`; active `tasks/todo.md` now
  keeps only current follow-ups, this plan, and this review.
- Verification passed: `wc -l memory-bank/*.md`, `git diff --check`,
  `git diff --stat`, `flutter analyze`, and `flutter test` (493 passed,
  1 skipped). The skipped test was `test/feed_flow_integration_test.dart`
  because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN` were unset.
- Working tree also contains a small `lib/features/home/home_view.dart` mounted
  guard that this documentation run did not edit; it was left untouched.
