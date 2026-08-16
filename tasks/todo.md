# TODO

Current follow-ups and the active session only. Historical task logs live in
`tasks/archive/`; latest:
`tasks/archive/todo_20260811_pre_compaction.md`.

## Plan (2026-08-16 v3.0.0 Release Notes Sync)
- [x] Approve localized bundled What's New and ASC release-note drafts.
- [x] Resolve the next iOS build number as `20` from ASC build history.
- [x] Update `pubspec.yaml`, bundled What's New, and ASC localization assets.
- [x] Run localization generation, formatting, analyzer, tests, and metadata
      terms validation.
- [x] Sync v3.0.0 metadata to ASC, archive/upload build 20, wait for processing,
      and attach the valid build without submitting for review.
- [x] Update release ledgers, create the release tag, commit, push, and leave
      the worktree clean.

## Review (2026-08-16 v3.0.0 Release Notes Sync)
- Local `3.0.0+20` metadata, generated localization code, bundled What's New,
  and four ASC `.strings` files are synchronized for the room-frame feature.
- `flutter analyze` passed; `flutter test` passed 642 tests with 1 skipped
  integration test; the direct-EULA metadata test passed.
- ASC version `9c8da611-140f-42aa-be58-e3b019978793` is
  `PREPARE_FOR_SUBMISSION`; build `2fec6cc5-c143-42a4-97b6-aed587726311`
  is `VALID` and attached. App Review submission was intentionally not made.

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
      with 使用中/擁有/locked states, 完成 confirm.
- [x] Keep the pre-redesign card as `RoomFrameStyle.original`, make it the
      default so no existing room changes look, and list it first in 換相框.
- [x] Gate casings by room level via `RoomFrameSkin.unlockLevel` (all `1` for
      now); locked swatches show a lock plus the required `Lv n`.
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

## Plan (2026-08-15 Room Frame Unlock Ladder)
Client-only; no schema or shop changes.
- [x] Calibrate against the real curve and live data: exp is `+10` per
      *rewarded* feed only, `50 * level` per level, so level N costs
      `2.5*N*(N-1)` feeds; ~2 rewarded feeds per active day; 58 active rooms
      median Lv2 / p75 ~5.75 / p90 12, 70% of all 293 rooms still Lv1.
- [x] Set the ladder: Lv1 `original` + `polaroidClassic` (換相框 must never open
      as a menu of locks), Lv3 `corkboard` (~7 days), Lv5 `goldLeaf` (~25 days),
      Lv8 `nightGlow` (~70 days, the long-tail anchor).
- [x] Record the derivation and the two refresh queries in `RoomFrameSkins`'
      doc comment so the next recalibration is not a re-derivation.
- [x] Grandfather the equipped casing in 換相框, and keep an unknown room level
      reading as Lv1 so a failed pet-summary load cannot hand out a gated
      casing.
- [x] Tests: exact ladder values, monotonic opening, Lv1 lock counts + hint
      copy, unknown-level behaviour, grandfathering (proved to have teeth by
      removing the grandfather clause first).
- [x] `dart format`, `flutter analyze`, `flutter test` (628 passed / 1 skipped).

## Review (2026-08-15 Simulator Verification)
Verified on iOS 26.5 simulators (iPhone 17 Pro / 17 Pro Max / 17e) with a
throwaway `--dart-define`-driven harness, since the simulator has no tap API.
The harness has been deleted; the recipe is `RoomSelectionView` inside a fixed
-width `SizedBox` (both `homeUiScale` and `HomeResponsiveSpec` read
`LayoutBuilder` constraints, so a constrained width exercises the real tier),
plus a `PrimaryScrollController` jump to `maxScrollExtent` and a first-frame
`showRoomFramePickerSheet` call.
- All five casings render correctly at all three tiers — compact 360/0.76,
  regular 393/0.90, expanded 440/1.00 — with no clipping or overflow.
- `gridBottomInset` is right at every tier: scrolled to the end, the last card
  row clears the floating CTA, and the CTA clears the home indicator.
- The 30pt hunger ring does not overpower `goldLeaf`.
- `Lv` chip contrast: `nightGlow` is fine (amber on the dark card).
  **`goldLeaf` is the weakest pair in the set** — gold `0xFFC08A2E` on an 18%
  gold fill over a cream card. Legible at preview size, marginal on the room
  card. Left as-is; see the follow-up.
- 換相框 uses **no** `homeUiScale` — fixed 16pt paddings, a fixed 190pt preview
  and a 4-up grid that flexes with the device width — so it has no breakpoints
  to sweep. Verified on the narrowest device available: the `🔒 Lv 3/5/8`
  labels do not truncate and 完成 clears the home indicator.
- Caveats: no simulator ≤360pt exists in this install, so the compact tier was
  driven by constraining the view rather than by a narrow device; and every
  shot shows the empty-photo placeholder, since the harness has no network
  photo.

## Plan (2026-08-15 Lv Chip Contrast And Locked Swatches)
- [x] Measure instead of eyeballing. **The simulator read was wrong**: the
      worst chip was not `goldLeaf` (2.48:1) but `original` /
      `polaroidClassic` at **1.59:1** — `#FFB36B` on white. A small orange chip
      on a white card looks acceptable at a glance and is not.
- [x] Split `levelTextColor` out of `levelColor`, so the fill keeps each
      casing's accent while the text takes a readable ink. All four light
      casings use `_levelInk` `#8A4C0C` (6.09 / 6.09 / 4.60 / 5.49);
      `nightGlow` keeps its accent, which already measures 6.18.
- [x] Dim locked swatches: 15% saturation + 0.55 opacity, with the `Lv n`
      label left outside the filter. The previous 0.75 opacity alone was
      invisible as a state.
- [x] Tests: a WCAG contrast helper holds every casing to 4.5:1 against its own
      chip fill (proved to have teeth — reverting `levelInk` fails on
      `original` first), plus a per-swatch assertion that exactly the gated
      casings are drained.
- [x] Re-verified both on the simulator, `dart format`, `flutter analyze`,
      `flutter test` (630 passed / 1 skipped).

## Active Follow-ups
- [ ] Decide whether any casing belongs in the shop instead of on the level
      ladder. Needs an `items` row + a price off `docs/shop_pricing.md`, so it
      is a product call plus a migration, not a client change.
- [ ] Room frames are per-device only. To share a casing across a room's
      members, add a `room_frame_state`-style table following the
      `room_backgrounds` / `room_background_state` precedent and version-gate
      visibility per `.codex/skills/shared-item-rollout/SKILL.md`. Needs
      approval first (migration + old-client compatibility).
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
