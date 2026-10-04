# Little Pond Buddy

Concept selected with the owner on 2026-10-04. On 2026-10-05 the owner requested
a smaller shell and a more distinctive tail. Composition sketch v2 reduces shell
width by 16% and height by 10%. The owner selected A (leaf-shaped tail) and
requested a text-only AI exploration without uploading the sketch or references.
These are composition studies, not production pet art.

## Character brief

- Upright turtle in a slight three-quarter pose; round head, short neck,
  broad feet, small paddle-shaped hands, one raised in a gentle wave.
- Sage body, olive shell, cream belly, peach cheeks, warm brown eyes.
- Shell remains visible beside the torso, with sparse broad markings.
- Existing cat informed the painted-texture direction. The first AI exploration
  uses text only, with no reference upload; proportions, expression and pose can
  vary while preserving the smaller shell and leaf-shaped tail.
- Signature behaviour: a delayed reaction followed by an enthusiastic wave.
- Planned states: idle (blink/wave), walk (small determined steps), sleep
  (head partly tucked into shell with face still readable).

## Review files

- [Editable composition](turtle_pond_buddy.svg)
- [Transparent 450 × 450 render](turtle_pond_buddy.png)
- [Comparison and small-size review](review.png)
- [Tail alternatives on the smaller-shell composition](tail_options.png)

Tail alternatives are A: leaf-shaped (selected), B: curved droplet, C: soft curl.
These explore silhouette only. Each tail originates behind the
lower torso. Leaf-shaped means the tail's own shape, not an attached plant.
Editable studies: [A](tail_leaf.svg), [B](tail_droplet.svg), [C](tail_curl.svg).

The review compares the sketch with the shipped cat and shows both on the
existing free room background. The 64 px and 96 px views are readability probes,
not a claim about the app's exact pet scale.

## Next stage

Use the [text-only exploration prompt](gemini_prompt.txt) in a new Gemini chat
with a square image setting. Upload no sketch or style reference for this pass,
as requested by the owner. Select and review the generated interpretation next.
Review the resulting master illustration before separating animation layers.
All frames must retain one shared canvas and alignment; do not normalize each
frame with the furniture crop-and-centre process.

Follow the [art process](../../../.codex/skills/new-furniture-art/SKILL.md)
for visual review, and the [pet authoring workflow](../../../docs/godot-png-sequence-socket-workflow.md)
for equipment sockets when animations exist. Catalog integration, version gates,
pricing, release timing, and backend changes have not been decided.

To render the composition again from the repository root:

```sh
rsvg-convert -w 450 -h 450 design/pet_sketches/turtle_pond_buddy/turtle_pond_buddy.svg -o design/pet_sketches/turtle_pond_buddy/turtle_pond_buddy.png
```
