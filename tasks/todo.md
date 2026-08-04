# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260804_pre_compaction.md`.

## Plan (2026-08-04 Agent Docs And Memory Optimization)
- [x] Audit `AGENTS.md`, active memory, task notes, repo-local workflows, and
      every outstanding worktree change without discarding shared-session work.
- [x] Archive full active-memory snapshots, compact current-state notes, and
      add only verified, non-duplicative agent workflow guidance.
- [x] Run diff, analyzer, and test verification; document results and line-count
      changes before committing logical groups.

## Active Follow-ups
- [ ] Monitor ASC/store outcome for iOS `2.3.3+16`; submit for App Review only
      after an explicit request.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm Crashlytics receives Firebase Apple SPM dSYMs and real
      `unclean_exit` events.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.

## Recent Context
- Release/build/backend truth: `docs/release_status.md`.
- iOS `2.3.3+16` release-notes sync completed: ASC version
  `717272d6-bcf3-4d3e-a6e4-48438305b196` is `PREPARE_FOR_SUBMISSION`;
  build `daa5e0e0-c9b1-4e4e-b8d6-277a82fd9a7d` is `VALID`, attached, and
  intentionally not submitted for App Review. Release note covers the chat fix
  where a sender's name could disappear after a system message
  (`chat_sender_name_visibility.dart`, commit `183efdc`).
- Localized ASC metadata was verified for en-US, ja, ko, and zh-Hant with EULA
  footers preserved. The release session recorded successful `flutter gen-l10n`,
  metadata terms, analyzer, and full test checks (588 passed).
- Full prior task state: `tasks/archive/todo_20260804_pre_compaction.md`.

## Review (2026-08-04 Agent Docs And Memory Optimization)
- Added repo-grounded handled-error and OOM/process-kill guidance to
  `AGENTS.md`; no runtime code or generated file was changed by this pass.
- Active memory fell from 318 to 242 lines: architecture 111→70, database
  schema 87→66, progress 53→39, tech stack 38→38, UI/UX 29→29.
- Preserved full snapshots in
  `memory-bank/archive/{architecture,database_schema,progress}_20260804_pre_compaction.md`
  and the prior task log in
  `tasks/archive/todo_20260804_pre_compaction.md`.
- Reviewed all outstanding files. The pre-existing 2.3.2 release/localization
  set is coherent and will be committed separately from this documentation set.
- `git diff --check`, `flutter gen-l10n`, and `flutter analyze` passed.
  `flutter gen-l10n` reported three pre-existing untranslated messages in each
  of ko and zh_TW; generated sources stayed consistent.
- `flutter test` passed 579 tests; the feed integration test skipped because
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN` are unset.
