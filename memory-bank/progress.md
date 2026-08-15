# Progress

Compact current state only. Full snapshots live in `memory-bank/archive/`;
latest: `memory-bank/archive/progress_20260811_pre_compaction.md`.

## Current State
- Repo release baseline is iOS `2.4.0+19`; exact ASC/build/localization and
  backend deployment state lives in `docs/release_status.md`. Build 19 is
  `VALID`, attached, and intentionally not submitted for App Review. Adds four
  new furniture pieces (Balloons/Cactus/Rug/Vinyl Records) to the shop,
  version-gated to `2.4.0` and active.
- Flutter is pinned to `3.44.0` / Dart `3.12.0`.
- Room invite creation/regeneration uses reusable 24-hour codes.
- Internal hunger-schedule and abandoned-room review tables use RLS as
  defense-in-depth while remaining service-only.
- Pet rendering prefers PNG sequences while preserving GIF ids. Chicken is
  visible from `2.3.0`; reviewed Level 2 tracks preserve intentional movement.
- Handled UI/media errors report classified non-fatals. `UncleanExitService`
  detects likely OOM/process kills on the next launch.
- The foreground OOM root cause was undisposed `ImageInfo` listener clones.
  All known aspect-ratio listeners now dispose them; iOS memory warnings also
  release cache/live images and trim thresholds track configured caps.
- iOS release exports preserve the archive and upload every archive dSYM to
  Crashlytics; the archive path is authoritative for symbolication.
- No public function scans `pg_timezone_names`; timezone-aware RPCs use
  `public.normalize_timezone(text)`.
- Failed pet-state refreshes keep the last successful visible snapshot.
- Room-photo cleanup remains human-reviewed/fail-closed; GEOFlow/hosting lives
  in `/Users/fatboy/geo-marketing`.
- ASC subscription metadata must retain the direct Apple Standard EULA footer.
- 房間選擇 room cards are equippable frame casings (`RoomFrameStyle` ×5) picked
  in the 換相框 sheet via long-press. `original` is the pre-redesign card and the
  default, so untouched rooms look unchanged. Equipped casing persists per
  device in Hive.
- The room-frame unlock ladder is calibrated, not flat: `original` and
  `polaroidClassic` Lv1, `corkboard` Lv3, `goldLeaf` Lv5, `nightGlow` Lv8. Exp
  comes only from rewarded feeds (`+10`, behind the 10-minute cooldown) against
  a `50 * level` curve, so level N costs `2.5*N*(N-1)` feeds ≈ 7 / 25 / 70 days
  at the live median of ~2 rewarded feeds per active day. Unlock levels may be
  lowered but never raised — raising one retracts a casing a room already wears.
  The picker grandfathers the equipped casing, and an unknown room level reads
  as Lv1 so a failed summary load cannot hand out a gated casing. Derivation and
  refresh queries live in `RoomFrameSkins`' doc comment.
- The room card is laid out around its photo: `photoAspectRatio` 1.25 gives the
  photo 63–66% of the card. The mat is a two-row text block beside a 30pt hunger
  ring centred against both rows; its horizontal inset derives from
  `skin.photoInset` so the name aligns to the photo's left edge in every skin.
  The caption line is never blank — it falls back to a status line (hungry / new
  photo / no photo yet) styled distinctly from a human caption.
- Pet names cap at 12 characters via `kPetNameMaxLength`, enforced at every
  entry point and on the server by `validate_pet_name`; first-time naming goes
  through `set_initial_pet_name` instead of a direct column write. Names are
  fitted to the space that shows them (15→11pt on the room card), so no layout
  depends on the cap.
- `lib/` and `test/` are canonical for the pinned formatter, and CI gates
  `dart format` / `flutter analyze` / `flutter test`.

## Open Items
- Room frames: the equipped casing is per device; sharing one across a room's
  members needs a server-backed state table following the `room_backgrounds`
  precedent, which requires approval. Whether any casing belongs in the shop
  instead of on the level ladder is also still open (needs an `items` row and a
  price off `docs/shop_pricing.md`, so it is a product call plus a migration).
- The room card is simulator-verified at all three `homeUiScale` tiers × all
  five casings (see `tasks/todo.md`).
- The `Lv` chip takes its fill from `levelColor` but its text from
  `levelInk` (`levelTextColor ?? levelColor`). The two are split because one
  accent could not do both jobs: reused as text it measured 1.59:1 on
  `original`. Light casings ink at `#8A4C0C`; `nightGlow` keeps its accent.
  `room_frame_test.dart` holds every casing to WCAG 4.5:1 against its own chip
  fill, so a new casing cannot ship an unreadable chip.
- Locked casings in 換相框 are drained (15% saturation) and dimmed (0.55), with
  the `Lv n` label outside the filter. Opacity alone did not read as a state.
- Convert source-text test assertions to behavioural ones. ~11 test files do
  `readAsStringSync()` + `contains('…')`, which checks how code looks, not what
  it does; `home_loading_performance_test.dart` is only whitespace-insensitive,
  not fixed. Migration tests asserting on `.sql` text are legitimate. Prove any
  replacement still has teeth by breaking the guarded structure first.
- Monitor ASC/store outcome for iOS `2.4.0+19`; App Review submission requires
  an explicit request.
- Live-verify feed satiety, visible hunger movement, and presigned-upload logs.
- Confirm Supabase secrets/config for `delete_account` and `avatar_upload`.
- Implement Sign in with Apple token revocation on account deletion.
- Confirm organic post-deploy timing for the timezone-normalized pet RPCs.
- Add a leak regression test for the high-volume
  `CachedNetworkImageView` path if its cache-manager harness can be stabilized.
- Instrument remaining best-effort bare catches opportunistically with
  `reportSwallowedError(...)`.
- Smoke-test iOS ads after the `google_mobile_ads` 8.0.0 upgrade.

## Read More
- Release/backend ledger: `docs/release_status.md`
- Architecture/schema: `memory-bank/architecture.md`,
  `memory-bank/database-schema.md`
- History: `memory-bank/archive/`
