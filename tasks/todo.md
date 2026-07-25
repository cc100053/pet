# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260724_pre_compaction.md`.

## Plan (2026-07-26 Chicken Idle Socket Fix)
- [x] Validate the reviewed Chicken Stay export and calculate exact per-frame
      head/body/back offsets from frame 0.
- [x] Add all three Chicken idle motion tracks and regression coverage that
      proves Idle samples the authored Stay movement.
- [x] Run focused tests, `flutter analyze`, and the full `flutter test` suite.
- [x] Update current-state notes, commit, push the pending calibration commits,
      and leave `main` clean and synchronized.

## Plan (2026-07-26 Chicken Calibration Sync)
- [x] Sync the Level 2 Chicken Godot socket export, including the corrected
      sleep head motion frame, into Flutter.
- [x] Apply Chicken per-pet crown/straw-hat/ribbon fits plus the crown sleep
      state override from the resolved Godot equipment settings.
- [x] Model sunglasses as incompatible with Chicken, hide them from Chicken
      inventory/preview rendering, and guard the equip RPC path.
- [x] Add regression coverage, regenerate localization, run full verification,
      update current-state notes, commit, push, and leave the repo clean.

## Plan (2026-07-26 Godot Equipment Precedence Fix)
- [x] Make each higher-priority global equipment layer replace the resolved
      authoring value instead of leaving the first default value in controls.
- [x] Prove chicken per-pet values win over defaults with a headless Godot
      regression script, then validate editor/plugin startup.
- [x] Record the corrected diagnosis and unrecoverable last edit, run required
      Flutter verification, commit, push, and leave the repo clean.

## Plan (2026-07-26 Godot Equipment Reload Fix)
- [x] Reload saved per-pet equipment settings into the active Godot controls
      and preview without requiring a manual equipment reselect.
- [x] Initialize the authoring dock from an already-open pet scene after the
      Godot editor or plugin reloads.
- [x] Preserve the saved chicken equipment overrides and validate the add-on
      script in headless Godot.
- [x] Update workflow/current-state notes, run required Flutter verification,
      commit, push, and leave the repo worktree clean.

## Plan (2026-07-25 Crashlytics Background Timeout Fix)
- [x] Apply the existing retryable-network classifier to Flutter framework
      error reporting so socket timeouts are recorded as non-fatal.
- [x] Prevent retryable network errors from activating the app-wide crash
      recovery screen while preserving genuine fatal handling.
- [x] Add regression coverage for the exact `tick_pet_state` timeout signature
      and the recovery-screen decision.
- [x] Run formatting, focused tests, `flutter analyze`, and `flutter test`.
- [x] Update current-state notes, commit, push, and leave a clean worktree.

## Plan (2026-07-24 AGENTS/Memory Optimization)
- [x] Audit AGENTS, active memory, task notes, local skills, referenced docs,
      scripts, Edge Functions, and relevant migrations for verified changes.
- [x] Archive full pre-compaction snapshots and keep active memory/task notes
      focused on current state and next actions.
- [x] Add only accurate, non-duplicative AGENTS workflow guidance.
- [x] Record before/after counts, inspect all worktree changes, and run required
      Flutter verification.
- [x] Group and commit all legitimate changes, push, verify, and leave a clean
      worktree.

## Active Follow-ups
- [ ] Run ASC submission preflight for iOS `2.2.6+12`, then submit ASC version
      `b7b48f69-f839-41da-ba4f-60cc0bc9647b` with attached build
      `a489f171-7dc2-416c-b332-8ec3e8fe6477` if approved.
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
  `tasks/archive/todo_20260724_pre_compaction.md`.

## Review (2026-07-26 Chicken Idle Socket Fix)
- Confirmed `stay` → `idle` state mapping was already correct. The Chicken
  config was missing idle motion tracks because all Stay movement fell below
  the provisional 10 px generation threshold.
- Synced all five reviewed Stay frames for head, body, and back using the exact
  frame-0 deltas and `PetAnimationFrames.chickenIdle` timing.
- Added direct track-sampling coverage plus an overlay regression proving an
  Idle head item follows the authored Stay socket.
- Updated the calibration workflow to generate every intentional non-zero
  Level 2 track with `--track-threshold 0`. Focused tests passed 18 tests,
  `flutter analyze` passed, and `flutter test` passed 537 tests with one
  environment-dependent integration test skipped.

## Review (2026-07-26 Chicken Calibration Sync)
- Synced the reviewed Level 2 Chicken socket export, including the corrected
  sleep head frame, plus per-pet crown, straw-hat, and ribbon fits and the
  sleep-specific crown override.
- Added a catalog-level Chicken incompatibility for sunglasses. Chicken
  inventory lists now omit them, equip requests are rejected with localized
  feedback, and the shared overlay suppresses stale equipped data.
- Kept the existing Chicken `2.3.0` visibility gate and made no backend/RPC
  contract changes; other pets can continue buying and using sunglasses.
- Focused calibration/equipment tests passed 32 tests. `flutter analyze`
  passed with no issues, and `flutter test` passed 536 tests with one
  environment-dependent integration test skipped.

## Review (2026-07-26 Godot Equipment Precedence Fix)
- Found the remaining root cause: the resolver inserted default equipment
  settings into the authoring map first, then refused to replace an existing
  key when processing `per_pet.<pet>`.
- Changed the external Godot dock so each higher-priority global layer replaces
  the resolved authoring value; per-animation JSON continues to apply after the
  global layers.
- A headless regression resolved chicken crown to its per-pet anchor
  `(0.40, 0.80)` and size ratio `0.32`, rather than the default anchor
  `(0.50, 0.70)`. A complete Godot 4.6.2 editor/plugin startup also passed.
- The 00:36 Save did execute, but saved stale visible defaults over the latest
  straw-hat/ribbon edits. Those unsaved intended values are not recoverable
  from the current files and must be calibrated again after this fix.
- All three chicken socket exports passed validation. `flutter analyze` passed
  with no issues, and `flutter test` passed 533 tests with one
  environment-dependent integration test skipped.

## Review (2026-07-26 Godot Equipment Reload Fix)
- Fixed the external Godot authoring dock so socket JSON loads discard stale
  in-memory equipment data, resolve default/per-pet/per-animation settings
  again, and apply the active equipment values to the visible controls.
- Added current-scene initialization after editor/plugin reloads and deferred
  preview reconstruction by one editor tick to avoid mutating a scene tree
  while Godot is still building it.
- Godot 4.6.2 completed a full headless editor/plugin load without parser,
  initialization, or scene-tree errors. All three chicken socket exports pass
  the calibration validator, and the saved chicken overrides remain intact.
- `flutter analyze` passed with no issues. `flutter test` passed 533 tests with
  one environment-dependent integration test skipped.

## Review (2026-07-25 Crashlytics Background Timeout Fix)
- Fixed iOS Crashlytics issue `5347dc92ac7a507fa084a7558fa4f4a0`:
  Flutter-reported socket/auth timeouts now reuse the central retryable-network
  classifier and are recorded as non-fatal.
- `AppCrashSignal` now applies the same classifier before showing
  `CrashUpdateGuard`, so expected background network loss cannot replace the
  app while genuine fatal errors retain the recovery flow.
- Added exact `tick_pet_state` timeout regression coverage. Focused tests
  passed, `flutter analyze` found no issues, and the final full `flutter test`
  run passed 533 tests with one environment-dependent integration test skipped.
- One pre-existing feed retry-budget timing test failed in the first full run;
  its focused rerun and the final full-suite rerun both passed.

## Review (2026-07-24 AGENTS/Memory Optimization)
- Added verified ASC release commands for explicit IPA versioning and attaching
  a `VALID` build while keeping App Review submission separately authorized.
- Compacted active memory from 314 to 257 lines: architecture 93→70, database
  schema 88→76, progress 66→44, tech stack 38→38, UI/UX 29→29.
- Archived full snapshots at
  `memory-bank/archive/architecture_20260724_pre_compaction.md`,
  `memory-bank/archive/database_schema_20260724_pre_compaction.md`, and
  `memory-bank/archive/progress_20260724_pre_compaction.md`; archived the task
  log at `tasks/archive/todo_20260724_pre_compaction.md`.
- `git diff --check` passed. `flutter analyze` passed with no issues.
  `flutter test` passed 532 tests with one integration test skipped because
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_TEST_REFRESH_TOKEN` are
  unset.
- The first sandboxed Flutter invocation could not write the external FVM SDK
  cache; the approved rerun passed, confirming an environment-only issue.
