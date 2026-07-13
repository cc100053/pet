---
name: pet-socket-calibration
description: Calibrate PicPet Godot per-frame pet equipment sockets, validate PNG/GIF sequences and exported socket JSON, score temporal track quality, and generate Flutter PetSocketConfig motion tracks. Use when adding or reviewing a pet animation, authoring HeadSocket/BodySocket/BackSocket markers, exporting `_sockets.json`, diagnosing drifting equipment, or syncing Godot socket data into Flutter.
---

# Pet Socket Calibration

Use a human-in-the-loop workflow: scripts verify geometry and timing; visual review decides semantic attachment points.

## Required context

Read `/Users/fatboy/pet/docs/godot-png-sequence-socket-workflow.md` before editing assets, scenes, socket JSON, or Flutter tracks. Preserve existing user edits in both `/Users/fatboy/pet` and `/Users/fatboy/pet-tomo`.

## Workflow

1. Inspect source frames before authoring:
   `python3 scripts/inspect_pet_frames.py <pet-sequence-directory>`.
2. In Godot, calibrate frame 0 with representative equipment. Treat AI-only coordinates as review level 1, never production-final.
3. Propagate one frame at a time using the previous marker position, onion-skin comparison when available, and local pose movement—not eye position alone.
4. Capture all head/body/back markers and export before switching scenes.
5. Validate every export:
   `python3 scripts/validate_socket_export.py <file...>`.
6. Score movement and suspicious jumps:
   `python3 scripts/score_socket_tracks.py --review-level 1 <file...>`.
7. After human equipment review reaches level 2, generate Flutter code:
   `python3 scripts/generate_flutter_tracks.py --idle ... --walk ... --sleep ...`.
8. Apply generated code, then run focused socket tests, `flutter analyze`, and `flutter test`.

## Guardrails

- Do not infer semantic sockets from alpha bounds alone.
- Do not overwrite reviewed JSON without comparing the old and new per-frame coordinates.
- Keep canvas dimensions and frame durations aligned across PNG/GIF, Godot JSON, and `PetAnimationFrames`.
- Generate motion tracks when any axis moves more than 10 px on a 450 px canvas; still review smaller head movement visually.
- Review loop closure and isolated one-frame jumps before accepting generated tracks.
- Equipment anchors/sizes are independent from pet sockets; do not mix the two data sets.
- Do not sync level 0–1 captures to production Flutter unless the user explicitly requests a provisional implementation.

## Review scale

Use the 0–3 rubric in [references/calibration-rubric.md](references/calibration-rubric.md). Report the level per animation and slot, not only one score for the pet.

## Expected output

Report asset integrity, validation errors, suspicious frames, max per-slot movement, loop delta, review level, generated Flutter changes, and remaining human checks.
