---
name: pet-socket-calibration
description: Calibrate pet equipment sockets, validate Godot exports, or sync socket tracks into Flutter.
---

# Pet Socket Calibration

Use a human-in-the-loop workflow: scripts verify geometry and timing; visual review decides semantic attachment points.

## Required context

Use [the authoring workflow](../../../docs/godot-png-sequence-socket-workflow.md)
for the operation at hand: “Socket Positions” for socket/frame exports,
“Equipment Settings” for anchor/size overrides, and “Common Failure Modes” for
Godot/Flutter mismatches. The Godot project lives at `/Users/fatboy/pet-tomo`;
preserve existing user edits there and in this repo.

## Workflow

Run helper commands from the repository root.

1. Inspect source frames before authoring:
   `python3 .codex/skills/pet-socket-calibration/scripts/inspect_pet_frames.py <pet-sequence-directory>`.
2. In Godot, calibrate frame 0 with representative equipment. Treat AI-only coordinates as review level 1, never production-final.
3. Propagate one frame at a time using the previous marker position, onion-skin comparison when available, and local pose movement—not eye position alone.
4. Capture all head/body/back markers and export before switching scenes.
5. Validate every export:
   `python3 .codex/skills/pet-socket-calibration/scripts/validate_socket_export.py <file...>`.
6. Score movement and suspicious jumps:
   `python3 .codex/skills/pet-socket-calibration/scripts/score_socket_tracks.py --review-level 1 <file...>`.
7. After human equipment review reaches level 2, preserve every intentional
   non-zero per-frame capture by generating Flutter code with:
   `python3 .codex/skills/pet-socket-calibration/scripts/generate_flutter_tracks.py --track-threshold 0 --idle ... --walk ... --sleep ...`.
8. Apply generated code, check socket/frame integrity and equipment playback,
   and use the repository validation policy for the affected changes.

## Guardrails

- Do not infer semantic sockets from alpha bounds alone.
- Do not overwrite reviewed JSON without comparing the old and new per-frame coordinates.
- Keep canvas dimensions and frame durations aligned across PNG/GIF, Godot JSON, and `PetAnimationFrames`.
- The 10 px threshold on a 450 px canvas is for provisional automatic review
  only; it must not discard Level 2 human-reviewed movement.
- Review loop closure and isolated one-frame jumps before accepting generated tracks.
- Equipment anchors/sizes are independent from pet sockets; do not mix the two data sets.
- Do not sync level 0–1 captures to production Flutter unless the user explicitly requests a provisional implementation.
- Level-1 seeding: hand-place frame 0, then template-track each socket patch through
  the later frames (turtle `design/pet_sketches/turtle_pond_buddy/sockets/estimate_sockets.py`).
  A seeding script rewrites the scene JSON; never re-run it over reviewed captures.
- Before syncing a reported review, confirm it reached disk: the JSON's modification
  time is newer than the last scripted write, and the expected `equipmentSettings` are
  present. Captures and settings that were never exported exist only in the open editor.
- Fallbacks differ: Godot falls back to `equipment_overrides.json` `default`, while
  Flutter falls back to the `EquipmentDefinition` base (the ghost fit). When a pet was
  reviewed on Godot defaults, mirror those values as that pet's Flutter overrides.
- Faces drawn at an angle: set the dock's **Rotation °**, which exports
  `rotationDegrees` and maps to Flutter `EquipmentFitOverride.rotationDegrees`. Derive
  it from the measured eye tilt per state (turtle `design/pet_sketches/turtle_pond_buddy/sockets/fit_glasses.py`).

## Review scale

Use the 0–3 rubric in [references/calibration-rubric.md](references/calibration-rubric.md). Report the level per animation and slot, not only one score for the pet.

## Expected output

Report affected animations/slots, review levels, validation failures, suspicious
frames or loop transitions, generated changes, and remaining human checks.
