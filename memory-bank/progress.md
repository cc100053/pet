# Progress

Current baseline and where live state is recorded. Full snapshots live in
`memory-bank/archive/`; latest: `memory-bank/archive/progress_20260818_pre_compaction.md`.

## Current State
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
