# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260811_pre_compaction.md`.

## Plan (2026-08-14 Room Frame Casings)
Design source: `design_handoff_room_frames/` (turn 4 = skins, turn 3 = screen +
sheet). Client-only; no schema or shop changes.
- [x] `room_frame_skins.dart`: `RoomFrameStyle` enum with stable storage keys
      plus one `const RoomFrameSkin` per style, values taken from the handoff.
- [x] `room_frame_card.dart`: one card for all four casings, with
      `RoomFrameGeometry` shared by build and the grid's height estimate.
- [x] Rebuild `room_selection_view.dart` on the card: gradient backdrop, 42px
      avatar, 邀請碼 hard-shadow pill, 2-column grid, dashed 空位, 56px CTA.
- [x] `room_frame_picker_sheet.dart` (換相框): live preview, 4-up swatch grid
      with 使用中/擁有/price states, 完成 confirm.
- [x] Extract the currency pill to `home_currency_pill.dart` and reuse it in the
      sheet rather than re-drawing it.
- [x] Persist the equipped casing per room via `AppSettingsRepository` (Hive)
      behind `roomFrameProvider`.
- [x] `flutter analyze`, `flutter test`, and visual verification of all four
      casings, the screen, and the sheet.

## Plan (2026-08-11 Agent Docs And Memory Optimization)
- [x] Audit `AGENTS.md`, active memory, task notes, local workflows, recent
      commits, and the complete worktree without discarding shared-session work.
- [x] Archive exact pre-compaction snapshots and reduce active memory/task notes
      to current decisions, contracts, and follow-ups.
- [x] Add only verified, non-duplicative workflow guidance to `AGENTS.md`.
- [x] Inspect all diffs and run required Flutter verification.
- [x] Commit the logical documentation set, push `main`, verify the remote SHA,
      and leave a clean worktree.

## Active Follow-ups
- [ ] Room frames are per-device only. To make them shared/purchasable, add a
      `room_frame_state`-style table plus `items` rows following the
      `room_backgrounds` / `room_background_state` precedent, price 夜光 off
      `docs/shop_pricing.md`, and version-gate visibility per
      `.codex/skills/shared-item-rollout/SKILL.md`. Needs approval first
      (migration + old-client compatibility).
- [ ] Monitor ASC/store outcome for iOS `2.4.0+19`; submit for App Review only
      after an explicit request.
- [ ] Live-verify feed satiety, visible hunger movement, and presigned-upload
      logs.
- [ ] Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- [ ] Implement Sign in with Apple token revocation on account deletion.
- [ ] Confirm organic post-deploy timing for the timezone-normalized pet RPCs.
- [ ] Add a leak regression test for `CachedNetworkImageView` if the cache
      manager harness can be stabilized without hanging `flutter test`.
- [ ] Instrument remaining best-effort bare catches opportunistically with
      `reportSwallowedError(...)`.
- [ ] Smoke-test iOS banner/rewarded ads after `google_mobile_ads` 8.0.0.
- [ ] Decide whether to track Supabase Edge Function deployment config; no
      checked-in `supabase/config.toml` currently exists.

## Current References
- Release/build/backend truth: `docs/release_status.md`.
- Full pre-compaction task state:
  `tasks/archive/todo_20260811_pre_compaction.md`.

## Review (2026-08-11 Agent Docs And Memory Optimization)
- Added three repo-grounded `AGENTS.md` guardrails: archive-based Crashlytics
  dSYM upload/re-upload, timezone validation without `pg_timezone_names`
  scans, and disposal of listener-owned `ImageInfo` clones.
- Active memory fell from 287 to 252 lines: architecture 93→71, database schema
  66→67 (one new current timezone contract), progress 61→47, tech stack 38→38,
  and UI/UX 29→29. `tasks/todo.md` fell from 221 archived lines to 54 active
  lines after this review.
- Preserved exact pre-compaction snapshots in
  `memory-bank/archive/{architecture,database_schema,progress}_20260811_pre_compaction.md`
  and `tasks/archive/todo_20260811_pre_compaction.md`.
- The worktree started clean; the final diff is one documentation-only group
  with no runtime, generated, release, or unrelated file changes.
- `git diff --check` passed. `flutter analyze` passed with no issues.
  `flutter test` passed 613 tests with 1 skip: the live feed integration test
  requires unset `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_TEST_REFRESH_TOKEN`.
