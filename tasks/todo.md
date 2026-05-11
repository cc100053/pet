# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

Historical snapshot before this compaction:
`tasks/archive/todo_20260509_pre_compaction.md`.

## Active Follow-ups
- [ ] Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs from the SPM
  path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.

## Plan (2026-05-09 AGENTS.md & Memory-Bank Optimization)
- [x] Read automation memory, `AGENTS.md`, active `memory-bank/*.md`,
  `tasks/todo.md`, and `tasks/lessons.md`.
- [x] Measure active memory-bank line counts and archive current snapshots.
- [x] Inspect repo-local workflow sources before documenting changes:
  `.codex/skills/`, referenced `docs/`, `scripts/`, and `supabase/functions/`.
- [x] Apply minimal AGENTS/docs updates and compact active notes.
- [x] Run verification and record the review here.

## Review (2026-05-09 AGENTS.md & Memory-Bank Optimization)
- Updated `AGENTS.md` with the supported Apple raw JWT command and the current
  Firebase Hosting/GEO marketing boundary.
- Fixed stale Crashlytics workflow docs that referenced removed local
  `firebase.json` / `.firebaserc` files.
- Compacted active memory-bank summaries and archived pre-compaction snapshots:
  `memory-bank/archive/architecture_20260509_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260509_pre_compaction.md`, and
  `memory-bank/archive/progress_20260509_pre_compaction.md`.
- Archived the long task log to
  `tasks/archive/todo_20260509_pre_compaction.md` and kept this file focused on
  active follow-ups plus the current run.
- Active memory-bank line counts:
  before `75/78/67/34/35 = 289` total for
  `architecture/database-schema/progress/tech-stack/ui-ux-guidelines`;
  after `65/71/59/34/35 = 264` total.
- Verification:
  `wc -l memory-bank/*.md` captured before/after counts,
  `git diff --check` passed,
  scoped `git diff --stat` stayed within AGENTS/docs/memory/tasks,
  `flutter analyze` passed,
  `flutter test` passed with `test/feed_flow_integration_test.dart` skipped:
  `Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.`
- Note: the working tree still includes pre-existing deletions of `.firebase/`,
  `.firebaserc`, `firebase.json`, and `html/` files from the GEO workspace
  split; this run did not revert or recreate them.
