# Gingerbread Man

Supplied artwork from `assets/todo-Gingerbread_Man`, integrated on 2026-10-11
as pet id `gingerbread_man`. The owner approved `minAppVersion = 5.1.0` and
explicitly requested provisional socket sync, retaining the calibration todo.
This is an implemented, provisional pet, not a production-reviewed character.

## Art and playback

The received files are preserved unchanged in [source](source/). Runtime PNGs
and GIFs are byte-identical copies, with stable lowercase filenames. No new
character art was generated. [inspection.json](inspection.json) records canvas,
alpha bounds and timing; [timing.json](timing.json) carries per-frame timings.

| State | Frames | Timing (ms) | Runtime folder |
| --- | --- | --- | --- |
| Stay | 7 | 200, 100, 250, 400, 200, 400, 100 = 1650 | `assets/pet_sequences/gingerbread_man/stay/` |
| Walk | 8 | 200, 200, 200, 200, 200, 200, 300, 200 = 1700 | `assets/pet_sequences/gingerbread_man/walk/` |
| Sleep | 6 | 200, 100, 200, 100, 100, 100 = 800 | `assets/pet_sequences/gingerbread_man/sleep/` |

All frames have transparent 450 × 450 canvases and unclipped alpha bounds.
The cookie has warm golden-brown dough, cream icing, green eyes and a waving
arm. Stay waves, walk alternates spread/together feet with a wink, and seated
sleep closes the eyes with drifting bubbles. Existing `PetAnimatedImage` /
`PetAnimationFrameBuilder` playback uses PNGs at the supplied timings; GIFs
remain stable source/fallback identifiers under `assets/pet/gingerbread_man/`.
Room locomotion travels sideways and flips the image when facing right.
The supplied walk is front-facing; its visual suitability for sideways travel
still needs owner review.

Reference timings were checked against the shipped cat (stay 7/1300 ms,
walk 8/1200 ms, sleep 6/1200 ms), tiger (9/1600, 7/1200, 8/1100) and chicken
(5/1200, 8/1600, 6/1200). Their existing runtime source and playback behavior
are unchanged. Gingerbread Man's first-frame head widths are approximately
179/180/182 px (stay/walk/sleep). Moving arms and bubbles prevent a reliable
whole-sequence head measurement from a fixed horizontal band.

Source foot bottoms are y=431–432 for stay, 424–440 for walk, and 392 for
sleep. Preserve the walking bounce; inspect the 40 px seated height change
at the state transition before release. Common-baseline/continuous-loop art
acceptance is pending, not inferred from the supplied files.

To review actual loops on light/dark backgrounds at 450, 128 and 96 px:

```sh
python3 -m http.server 8871 --bind 127.0.0.1 --directory design/pet_sketches/gingerbread_man
```

Open `http://127.0.0.1:8871/review.html`; GIFs are embedded in
[review.html](review.html), so the app browser does not need local file access.

## Provisional equipment calibration

All stay/walk/sleep × head/body/back captures are **Level 1**; face uses head.
The owner explicitly approved syncing these estimates into Flutter before
human equipment review. The Dart catalog has a `shortcut:` marker, all nine
tracks retain every non-zero movement (`--track-threshold 0`), and hats/glasses
mirror the Godot default anchors and sizes. Ribbon already shares the default
fit. This does not establish that any equipment shape fits correctly.

[estimate_sockets.py](sockets/estimate_sockets.py) adapts the turtle template
tracker, with bounded patches near the canvas edge and an overwrite guard.
Frame-0 semantic points were estimated from each source pose; later frames
were tracked from the previous frame. Scenes and seed exports are preserved
under [godot/pet/gingerbread_man](godot/pet/gingerbread_man/) and installed at
`/Users/fatboy/pet-tomo/pet/gingerbread_man/`. Do not rerun the seed script over
reviewed captures. Equipment overrides in the existing Godot project were
not modified.

Schema/timing/normalized-coordinate checks pass. [score.json](sockets/score.json)
records these warnings using 1-based frame numbers:

- Stay: head steps at frames 2 and 7 (up to 13.34 px); back step at frame 2
  (12.04 px).
- Walk: head last-to-first delta 10.05 px.
- Sleep: head step at frame 2 and last-to-first delta 14.56 px.

Review sheets: [stay](sockets/review_stay.png),
[walk](sockets/review_moving.png), [sleep](sockets/review_sleep.png).
These warnings identify provisional points to review; they are not rejected
or certified as intentional motion.

`[USER ACTION REQUIRED]` Play each scene in Godot with small/wide hats,
glasses and body equipment, review all three markers, and **Export Sockets**
before switching scenes. Confirm both facings in Flutter. Back has no shipped
equipment SKU, so inspect its marker and review with equipment when available.
After review, compare the exported files with these seeds, preserve the exports
here, validate them and regenerate tracks at `--track-threshold 0` following
the [socket skill](../../../.codex/skills/pet-socket-calibration/SKILL.md).

## Rollout and verification

The app catalog, five locales, equipment preview, PNG sequences, fallback GIFs
and explicit asset folders are wired. Existing compatibility helpers hide it
below 5.1.0 and render the ghost for unsupported shared-room pet ids.
The current repository version 5.0.0+31 therefore keeps this pet hidden.
No backend contract, migration, push function, release notes or release build
was changed. `notify_friend` continues to use the existing ghost push avatar.
Gate/release state lives in [release_status](../../../docs/release_status.md).

Verification completed 2026-10-12: final-tree Dart format unchanged; Flutter
analyze clean; full Flutter test suite 750 passed / 1 skipped (live feed test
credentials absent); `flutter build bundle` succeeded. All 21 PNG frames and
three GIFs occur in `AssetManifest.bin` and are byte-identical in the copied
bundle. Source/timing screenshots are excluded. Markdown link checks and
`git diff --check` pass. Socket regression coverage compares every exported
frame/slot with Flutter coordinates and checks Godot default equipment anchors.

Read-only backend inspection on 2026-10-12 confirmed current `add_room_pet`,
`use_pet_ticket` and `purchase_and_use_pet_ticket` definitions accept any
nonblank `p_pet_type` and store it in `color_dna.pet_type`. Latest relevant
applied migration: `20260527010845_add_purchase_system_messages_for_tickets_and_equipment`;
the prior extras-table migration is `20260519164401`. No new enum/catalog row
is required for this pet. No actual creation, ticket use, purchase or push was
performed during verification.

`[USER ACTION REQUIRED]` Review continuous loops, room-size placement and
state transitions on a device using a build at/above 5.1.0, complete Level-2
equipment review, and decide release timing. Publishing a pet push avatar and
deploying `notify_friend` require their own approval.
