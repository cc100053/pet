# Progress

Current baseline and where live state is recorded. Full snapshots live in
`memory-bank/archive/`; latest: `memory-bank/archive/progress_20260818_pre_compaction.md`.

## Current State
- `5.0.1+32` is the repository baseline as of 2026-10-16: built, uploaded,
  VALID and attached in ASC; onboarding and photo feedback/caption improvements,
  with no newly visible pets/items. Not submitted or publicly released.
  Execution evidence, Apple warnings and human checks live in `docs/release_status.md`.
- Gingerbread Man is wired as `gingerbread_man` from owner-approved 5.1.0:
  stay 7/1650 ms, walk 8/1700 ms, sleep 6/800 ms, five locales and GIF fallbacks.
  Owner explicitly approved provisional Level-1 socket tracks and Godot-default
  equipment fits. Human art/device/equipment checks remain; details and source
  evidence live in [the pet README](../design/pet_sketches/gingerbread_man/README.md).
- Five supplied furniture pieces are wired for the next `5.1.0+` build:
  Candle 100, Candy Cane 150, Sunflowers 150, Gift Box 200, Christmas Tree
  250 coins. PNGs, five-language app copy and purchase push names are ready;
  catalog migration is applied and `notify_friend` v40 is deployed with approval.
  NEW ends `2026-11-01T00:00:00Z`. Release/deployment details live in
  `docs/release_status.md`; art review lives in
  `design/furniture_sketches/festive_2026/README.md`.
- `pubspec.yaml` version is the in-flight build; release, ASC, dSYM, and
  deployment state live only in `docs/release_status.md`.
- Halloween 2026 furniture (Pumpkin Lantern 100, Candy Cauldron 150, Bat-Wing
  Armchair 250) is live in the catalog, version-gated at `3.3.1` (first shown
  in 4.0.0), with `new_until` 2026-11-01.
- Pet rendering prefers PNG sequences; Chicken is visible from `2.3.0`.
- Turtle ([Little Pond Buddy](../design/pet_sketches/turtle_pond_buddy/README.md))
  is production-complete as pet id `turtle`, gated at `minAppVersion` 5.0.0:
  idle 9 frames/1650 ms, pose-guided walk 8/1600 ms, procedural nod sleep
  16/2560 ms. Sockets and fits (tilted sunglasses) are synced, and the owner
  checked it on a device on 2026-10-05. Version 5.0.0+31 is built, uploaded,
  processed, and attached in ASC; bundled and ASC What's New cover Turtle's two
  room paths and larger chat emoji. Release state and the required dSYM check
  live in `docs/release_status.md`. The `notify_friend` push avatar still falls
  back to the ghost for Turtle.
- Behaviour and contracts live in their canonical sources: architecture,
  schema, and UI in this folder; runbooks under `docs/`.

## Open Items
Tracked in `tasks/todo.md` ("Active follow-ups").

Maintenance priorities: [research snapshot](../docs/project_maintenance_research.md).
Automated checks, offline CI fixtures and explicit live-test opt-in are defined
in [testing](../docs/testing.md); delivery and verification are tracked in
`tasks/todo.md`.
