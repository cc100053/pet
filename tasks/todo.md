# TODO

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshots before compaction:
- `tasks/archive/todo_20260606_pre_compaction.md`
- `tasks/archive/todo_20260621_pre_compaction.md`
- `tasks/archive/todo_20260627_pre_compaction.md`
- `tasks/archive/todo_20260704_pre_compaction.md`

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

## Plan (2026-07-11 Chicken Pet Wire-up)
- [x] Read active memory, shared-item rollout instructions, compatibility
      workflow, and Godot PNG sequence/socket authoring workflow.
- [x] Inventory chicken animation frames/timing and existing Flutter/Godot pet
      contracts.
- [x] Add version-gated chicken catalog/localization, PNG sequences, starter
      sockets, asset registration, and regression tests.
- [x] Add basic chicken authoring scenes in the Godot project
      for the user's detailed calibration pass.
- [x] Run localization generation, bundle verification, `flutter analyze`, and
      `flutter test`.
- [x] Record implementation and verification results below.

## Recent Context
- Detailed release/build/backend status now lives in `docs/release_status.md`.
- Detailed task history before this run is archived at
  `tasks/archive/todo_20260704_pre_compaction.md`.

## Review (2026-07-11 Chicken Pet Wire-up)
- Added the `chicken` pet with a `2.2.5` minimum-version gate, localized name
  and tagline for all five locales, catalog styling, and compatibility tests.
- Added the supplied 5-frame idle, 6-frame sleep, and 8-frame walk sequences
  with timing-sheet durations, explicit nested bundle registration, and debug
  equipment-preview access.
- Added starter head/body/back sockets at `(0.39, 0.18)`, `(0.45, 0.52)`, and
  `(0.69, 0.45)` in Flutter and matching 450x450 Marker2D positions in three
  Godot authoring scenes under `/Users/fatboy/pet-tomo/pet/chicken/`.
- Godot headless editor imported all chicken assets/scenes without errors.
- Verification passed: focused pet tests (16), `flutter build bundle` with all
  chicken assets present, `flutter analyze`, and full `flutter test` (521
  passed, 1 integration test skipped because its Supabase env vars are unset).
