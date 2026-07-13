# Calibration Rubric

## Review levels

| Level | Evidence | Allowed next step |
|---|---|---|
| 0 — Placeholder | One coordinate copied across states/frames without pose review | Godot setup only |
| 1 — Estimated | Every frame has a visually estimated semantic position; schema and timing pass | Human Godot review |
| 2 — Equipment-reviewed | Representative head/face/body/back equipment plays cleanly through the full loop | Generate and test Flutter tracks |
| 3 — Production-verified | Multiple equipment shapes, loop boundary, both facings, Flutter preview, analyzer, and tests pass | Release candidate |

Score each animation × slot separately. The pet's overall level is the minimum required-slot level.

## Representative equipment

- Head: one small hat and one wide hat.
- Face: glasses or another eye-aligned item; face currently resolves through the head socket.
- Body: one narrow and one wide body item.
- Back: one close-fitting and one large back item.

## Quantitative warnings

- Axis range over 10 px: generate a motion track.
- Single-frame step over 12 px: inspect with onion skin; it may be valid locomotion.
- Loop delta over 10 px: inspect the last-to-first transition.
- Normalized coordinate mismatch over 0.001: reject export.
- Alpha coverage outside 75–125% of the sequence median: inspect for partial or corrupt frames.

Warnings do not automatically mean failure. They identify frames requiring semantic review.

## Godot overlay recommendation

Use a 450×450 grid with 10 px minor and 50 px major lines, marker pixel and normalized labels, previous-frame ghost markers, per-frame delta labels, and optional previous/next onion skins. This overlay improves manual precision but does not replace equipment playback.
