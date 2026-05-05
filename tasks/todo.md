# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if they are still useful.

## Active Follow-ups
- [ ] Before shipping the Firebase Apple SPM / v1.4.0 changes, create a
  TestFlight/archive build and confirm Crashlytics receives dSYMs from the SPM
  path.
- [ ] Smoke-test iOS banner and rewarded ads after the `google_mobile_ads`
  8.0.0 upgrade.

## Plan (2026-05-02 AGENTS.md & Memory-Bank Optimization)
- [x] Read `AGENTS.md`, active `memory-bank/*.md`, `tasks/todo.md`, and
  `tasks/lessons.md`.
- [x] Inspect repo-local workflow sources in `.codex/skills/`, `docs/`,
  `scripts/`, and `supabase/functions/` before documenting anything.
- [x] Archive pre-compaction snapshots for active memory-bank files that will be
  shortened.
- [x] Apply minimal repo-grounded updates to `AGENTS.md` and compact active
  `memory-bank/*.md` files.
- [x] Run `wc -l memory-bank/*.md`, `git diff --stat`, `flutter analyze`, and
  `flutter test`.
- [x] Record review notes with before/after counts, archive paths, and
  verification results.

## Plan (2026-05-02 Compress Task Log)
- [x] Identify whether `tasks/todo.md` still contains current actionable items.
- [x] Preserve only active follow-ups and compact current-session context.
- [x] Remove long historical plan/review logs from the active task file.
- [x] Run required verification.

## Review (2026-05-02 Repo Documentation Cleanup)
- Removed stale docs that were completed, superseded, or misleading compared
  with current code/memory-bank state.
- Kept current operational docs only: Crashlytics MCP, Godot PNG/socket
  workflow, hunger tick schedule report, label mapping, and testing helpers.
- Replaced duplicated `CLAUDE.md` guidance with a short pointer to canonical
  `AGENTS.md`.
- Updated `README.md` into a current doc index and added
  `.firebase-mcp.env.example` for Crashlytics MCP setup.
- Verification already run for that cleanup: `flutter analyze` passed and
  `flutter test` passed, with `test/feed_flow_integration_test.dart` skipped
  due missing Supabase test env vars.

## Review (2026-05-02 Compress Task Log)
- Compressed `tasks/todo.md` from a long historical task log into a compact
  current task file.
- Preserved only active release follow-ups and the latest repo documentation
  cleanup summary.
- Verification: `flutter analyze` passed; `flutter test` passed with
  `test/feed_flow_integration_test.dart` skipped due missing Supabase test env
  vars.

## Review (2026-05-02 AGENTS.md & Memory-Bank Optimization)
- Updated `AGENTS.md` only with repo-grounded Crashlytics workflow details:
  prefer ADC via `.firebase-mcp.env` and inspect
  `ios/scripts/upload_crashlytics_symbols.sh` when stacks are unsymbolicated.
- Compacted active memory-bank files into current-state summaries and archived
  full pre-compaction snapshots:
  `memory-bank/archive/architecture_20260502_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260502_pre_compaction.md`,
  `memory-bank/archive/progress_20260502_pre_compaction.md`,
  `memory-bank/archive/tech_stack_20260502_pre_compaction.md`,
  `memory-bank/archive/ui_ux_guidelines_20260502_pre_compaction.md`.
- Active memory-bank line counts:
  before `121/114/92/57/81 = 465` total for
  `architecture/database-schema/progress/tech-stack/ui-ux-guidelines`;
  after `71/78/55/34/35 = 273` total.
- `git diff --stat` inspection stayed within `AGENTS.md`, active
  `memory-bank/*.md`, and the already-dirty `tasks/todo.md`.
- Verification:
  `wc -l memory-bank/*.md` captured before/after counts,
  `flutter analyze` passed,
  `flutter test` passed, and
  `test/feed_flow_integration_test.dart` was skipped with:
  `Set SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_TEST_REFRESH_TOKEN.`
