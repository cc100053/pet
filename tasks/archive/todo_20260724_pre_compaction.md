# TODO

> Archived in full before the 2026-07-24 compaction.

Keep this file compact. It is for current follow-ups and the active session's
plan/review only; historical task logs should stay in git history or move to a
purpose-specific archive if still useful.

Latest historical snapshots before compaction:
- `tasks/archive/todo_20260606_pre_compaction.md`
- `tasks/archive/todo_20260621_pre_compaction.md`
- `tasks/archive/todo_20260627_pre_compaction.md`
- `tasks/archive/todo_20260704_pre_compaction.md`
- `tasks/archive/todo_20260711_pre_compaction.md`

## Plan (2026-07-24 AGENTS/Memory Optimization)
- [ ] Audit AGENTS, active memory, task notes, local skills, referenced docs,
      scripts, Edge Functions, and relevant migrations for verified changes.
- [ ] Archive full pre-compaction snapshots and keep active memory/task notes
      focused on current state and next actions.
- [ ] Add only accurate, non-duplicative AGENTS workflow guidance.
- [ ] Record before/after counts, inspect all worktree changes, and run required
      Flutter verification.
- [ ] Group and commit all legitimate changes, push, verify, and leave a clean
      worktree.

## Plan (2026-07-16 Chicken v2.3.0 Rollout Boundary)
- [x] Move chicken's app-version visibility gate from `2.2.7` to `2.3.0`.
- [x] Prove all `2.2.x` versions keep chicken hidden with default-pet fallback.
- [x] Run full Flutter verification, update current-state docs, commit, and push
      a clean working tree.

## Review (2026-07-16 Chicken v2.3.0 Rollout Boundary)
- Chicken remains bundled but is unavailable throughout `2.2.x`; selection and
  remote rendering continue to fall back to the default pet.
- Version `2.3.0` is now the first supported chicken release boundary.
- `flutter analyze` passed; `flutter test` passed 532 tests with the
  credentialed feed integration test skipped.

## Plan (2026-07-16 iOS 2.2.6 Pet Status Release)
- [x] Keep chicken unavailable in 2.2.6 by moving its rollout gate beyond 2.2.x
      and updating compatibility coverage.
- [x] Add the approved localized bundled and App Store release notes and bump
      the app to 2.2.6+12.
- [x] Regenerate localization output and run release validation.
- [x] Sync App Store Connect metadata, archive/upload, wait for processing, and
      attach the build without submitting for review.
- [x] Update release ledgers, commit, push, and leave a clean working tree.

## Review (2026-07-16 iOS 2.2.6 Pet Status Release)
- Added approved bundled and ASC copy for fresher, consistent pet status across
  room selection and Pet Home; no chicken release copy was included.
- Moved chicken's minimum app version beyond the `2.2.6` release. Regression
  coverage proves
  `2.2.6` keeps it hidden and resolves unsupported remote chicken state to the
  default pet.
- Created ASC version `b7b48f69-f839-41da-ba4f-60cc0bc9647b`, synced and read
  back all four localizations, built and verified the iPhone-only `2.2.6+12`
  IPA, uploaded it, waited for `VALID`, and attached build
  `a489f171-7dc2-416c-b332-8ec3e8fe6477`.
- The ASC CLI wrappers returned the repo's known Apple `-50` error, so metadata
  sync used the checked-in direct API fallback and upload/processing used
  Apple's native authenticated tooling. `flutter analyze` passed and
  `flutter test` passed 532 tests with the credentialed feed integration test
  skipped. App Review submission was intentionally not performed.

## Plan (2026-07-16 Pet Status Freshness)
- [x] Inventory the current cache/server contract and add regression tests for
      shared selection/Home status semantics.
- [x] Add and deploy an additive read-only effective room-pet status RPC.
- [x] Reuse one per-room snapshot across selection and Home, with background
      revalidation on entry/resume and debounced durable persistence.
- [x] Keep server reconciliation neutral while preserving action-driven hunger
      animations.
- [x] Run focused and full verification, update current-state docs/release
      status, then commit and push a clean worktree.

## Review (2026-07-16 Pet Status Freshness)
- Added and deployed the additive authenticated-only
  `get_effective_room_pet_statuses(uuid[])` RPC. It calculates every requested
  room from one server timestamp and the room timezone without mutating state;
  old clients and tick contracts remain unchanged.
- Room selection and Pet Home now reuse one normalized per-room status snapshot,
  persist updates with a debounce, and revalidate status independently from
  feeds, equipment, member counts, and unread data on entry/resume.
- Cache corrections use a short neutral transition; only genuine feed/action
  gains trigger the longer rise treatment, preventing guessed hunger from
  looking like a reward.
- Live migration/permission/result smoke checks passed and Supabase advisors
  report no lint for the new RPC. `flutter analyze` passed; `flutter test`
  passed 532 tests with the credentialed feed integration test skipped.

## Plan (2026-07-15 iOS 2.2.5 Bug-Fix Release)
- [x] Inventory the approved bug fix and confirm the chicken rollout boundary.
- [x] Gate chicken beyond 2.2.5 and add a regression test proving it is hidden.
- [x] Update bundled What's New, ASC metadata, and the app version to 2.2.5+11.
- [x] Regenerate localization output and run release validation.
- [x] Sync App Store Connect metadata, archive/upload, wait for processing, and
      attach the build without submitting for review.
- [x] Update release ledgers with the verified App Store Connect state.

## Review (2026-07-15 iOS 2.2.5 Bug-Fix Release)
- Published bug-fix-only bundled and ASC release notes for the iOS notification
  permission initialization crash; no new-pet copy was included.
- Moved chicken's app-version visibility gate to `2.2.6`. Regression coverage
  proves `2.2.5` excludes it from the visible catalog and resolves remote
  chicken state to the default pet.
- Created ASC version `38afa02d-dc0a-4dff-a91c-4cedfe3095a0`, synced and read
  back all four localizations, built and verified the iPhone-only `2.2.5+11`
  IPA, uploaded it, waited for `VALID`, and attached build
  `5e052823-70d6-4d95-9ae5-a7b51651da9d`.
- `flutter analyze` passed. `flutter test` passed 523 tests with the credentialed
  feed integration test skipped. App Review submission was intentionally not
  performed.

## Plan (2026-07-14 Crashlytics FCM Permission Fix)
- [x] Inventory the notification initialization contract and affected
      Crashlytics variant.
- [x] Contain notification-permission request failures without changing
      successful FCM registration behavior.
- [x] Add regression coverage for the permission-failure path.
- [x] Run formatting, focused tests, `flutter analyze`, and `flutter test`.
- [x] Record verification results and remaining release implications.

## Review (2026-07-14 Crashlytics FCM Permission Fix)
- Contained notification permission request exceptions inside `FCMService`
  so unsupported Apple environments no longer escape to the fatal global zone.
- Preserved successful permission, local notification, tap routing, token sync,
  payload, server, and durable-state behavior.
- Added an injectable permission boundary and regression coverage for the exact
  `Notifications are not allowed for this application` platform failure.
- Focused FCM tests passed. `flutter analyze` reported no issues and full
  `flutter test` passed 523 tests with the environment-dependent feed test
  skipped.
- Existing 2.2.4 installs are unchanged; the fix requires a subsequent app
  build and no server deployment or migration.

## Plan (2026-07-11 AGENTS/Memory Optimization)
- [x] Audit AGENTS, active memory, task notes, local skills, referenced docs,
      scripts, Edge Functions, and relevant migrations for verified changes.
- [x] Archive pre-compaction snapshots and keep active memory current-state
      focused.
- [x] Add only newly supported, non-duplicative AGENTS workflow guidance.
- [x] Record before/after counts and inspect the documentation-only diff.
- [x] Run `flutter analyze` and `flutter test`, then record results.

## Active Follow-ups
- [ ] Run ASC submission preflight for repo-current iOS `2.2.6+12`, then submit
      ASC version `b7b48f69-f839-41da-ba4f-60cc0bc9647b` with attached build
      `a489f171-7dc2-416c-b332-8ec3e8fe6477` for review if approved.
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

## Plan (2026-07-11 Pet Socket Calibration Skill)
- [x] Scaffold a repo-local skill with standard metadata.
- [x] Add deterministic frame inspection, socket validation, quality scoring,
      and Flutter motion-track generation scripts.
- [x] Document the 0–3 review scale and human-in-the-loop calibration workflow.
- [x] Run the tools against chicken and validate the complete skill package.
- [x] Record implementation and verification results.

## Plan (2026-07-11 Chicken Socket Sync)
- [x] Revalidate chicken assets and Godot exports with the calibration skill.
- [x] Apply exported base/state sockets and required provisional motion tracks.
- [x] Update regression coverage for track lengths, timing, and sampled motion.
- [x] Run formatting, focused tests, `flutter analyze`, and `flutter test`.
- [x] Record verification and remaining Level 2 equipment review.

## Review (2026-07-11 Chicken Socket Sync)
- Replaced starter chicken sockets with normalized frame-0 values from the
  validated stay/moving/sleep Godot exports.
- Added timing-aware Moving motion tracks for head/body/back and a Sleep head
  track; Stay remains static because every slot stays below the 10px threshold.
- Added regression coverage for exported bases, track frame/duration parity,
  and representative Moving/Sleep samples.
- Focused socket tests passed. `flutter analyze` reported no issues and full
  `flutter test` passed 522 tests with the environment-dependent feed test
  skipped.
- The implementation is intentionally provisional Level 1. Chicken-specific
  equipment anchors/sizes and Level 2 promotion still require representative
  equipment playback in Godot and Flutter.

## Review (2026-07-11 Pet Socket Calibration Skill)
- Added `.codex/skills/pet-socket-calibration/` with standard Codex metadata,
  a concise human-in-the-loop workflow, and a 0–3 per-animation/slot rubric.
- Added deterministic scripts for PNG/GIF integrity inspection, Godot export
  schema/normalization validation, movement/jump/loop scoring, and Flutter
  `PetSocketConfig` generation.
- Chicken benchmark passed frame integrity and all three JSON validators. The
  scorer correctly keeps the AI-authored export at level 1, recommends moving
  tracks for all moving slots plus the sleeping head, and flags moving frames
  5–8 for human equipment review.
- Python syntax parsing, generated Flutter snippet output, `git diff --check`,
  and the official skill validator passed. The validator required a temporary
  minimal YAML compatibility module because available Python runtimes do not
  include PyYAML; no repo dependency was added.
- Required repo verification passed: `flutter analyze` reported no issues and
  `flutter test` passed 521 tests with the network integration test skipped.

## Recent Context
- Detailed release/build/backend status now lives in `docs/release_status.md`.
- Detailed task history before this run is archived at
  `tasks/archive/todo_20260711_pre_compaction.md`.

## Review (2026-07-11 AGENTS/Memory Optimization)
- Audited repo-local workflows and found no accurate, non-duplicative AGENTS
  addition; the existing shared-item and PNG/socket rules cover the new chicken
  rollout.
- Compacted active memory from 314 to 295 lines: architecture 93→90,
  database schema 82→82, progress 72→56, tech stack 38→38, UI/UX 29→29.
- Archived full pre-compaction copies at
  `memory-bank/archive/architecture_20260711_pre_compaction.md` and
  `memory-bank/archive/progress_20260711_pre_compaction.md`; archived the prior
  task state at `tasks/archive/todo_20260711_pre_compaction.md`.
- Diff inspection and `git diff --check` passed. `flutter analyze` passed with
  no issues. `flutter test` passed: 521 tests, with the feed integration test
  skipped because `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN` are unset.
