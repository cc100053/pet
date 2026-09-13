# TODO

## Plan — Repository instruction cleanup (2026-09-13)

- [x] Audit actual instructions and agree the full cleanup scope.
- [x] Simplify root guidance and skill routing; preserve operational constraints.
- [x] Correct runbook conflicts and archive historical context.
- [x] Validate skills, links, commands, and the complete diff.
- [x] Prepare the validated documentation changes for commit and push.

## Active follow-ups
- [ ] Decide whether any room-frame casing belongs in the shop. This needs an
      `items` row, a price from `docs/shop_pricing.md`, and migration /
      old-client compatibility approval.
- [ ] Real-device verify shared frames in two upgraded clients once `3.2.0+24`
      is distributed; legacy-only choices are shared on Done.
- [ ] Monitor ASC/store outcome for iOS `3.2.0+24`; submit for App Review only
      after an explicit request.
- [ ] Confirm build 24's Runner UUID `899B069B-543E-33E9-B307-4C78FBEC276A`
      and App.framework UUID `0C7143A3-E8A1-4BD6-485E-50E684619EE5` are absent
      from Crashlytics → Settings → Missing dSYMs `[USER ACTION REQUIRED]`.
- [ ] Confirm build 23's Runner UUID
      `1074123E-B8C3-3470-9A05-F5D2ACAF3F78` and App.framework UUID
      `0C7143A3-F470-6FF3-485E-50E695C70643` are absent from Crashlytics →
      Settings → Missing dSYMs `[USER ACTION REQUIRED]`.
- [x] Confirm build 22's recorded UUIDs (Runner
      `3D5833E2-B9BC-3107-9C9C-15DEFC0C5886`, App.framework
      `0C7143A3-330B-1F8B-485E-50E6EF09C56E`) are absent from Crashlytics →
      Settings → Missing dSYMs — confirmed 2026-08-26.
- [x] Confirm build 21's recorded UUIDs are absent from Crashlytics Missing
      dSYMs — confirmed 2026-08-20.
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

## History

Previous task plans and verification evidence:
`tasks/archive/todo_20260913_pre_instruction_cleanup.md`.

## Review — Repository instruction cleanup

- Simplified root and seven skill entrypoints, corrected paths and execution
  scope, and consolidated validation into `docs/testing.md`. Operational
  compatibility, release-copy, dSYM, socket, and cleanup safeguards remain.
- Release baseline and recorded public availability are separate. Preserved
  exact previous lesson, task, and release-ledger contents in linked archives.
- Seven skill metadata validators, 18 local Markdown links, five helper CLI
  help checks, historical snapshot equality, and `git diff --check` passed.
- Independent scope scenarios covered draft-only release, bundled-only edits,
  migration review, and an authorized crash fix; clarified conditional release
  sections following that check.
- Documentation only: no runtime changes, Flutter tests, or production actions.
