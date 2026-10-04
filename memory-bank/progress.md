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
- Turtle concept selected: [Little Pond Buddy](../design/pet_sketches/turtle_pond_buddy/README.md),
  an upright pond turtle. Generated master with compact shell and leaf-shaped
  tail selected on 2026-10-05. Nine-frame idle continuous-loop motion/timing
  accepted; walk and sleep prompts are ready, with generated trials pending.
  Transparency, room-size review,
  equipment calibration and rollout remain pending.
- Behaviour and contracts live in their canonical sources: architecture,
  schema, and UI in this folder; runbooks under `docs/`.

## Open Items
Tracked in `tasks/todo.md` ("Active follow-ups").
