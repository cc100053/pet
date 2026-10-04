# Little Pond Buddy

The owner selected the [generated master illustration](selected_master.png) on
2026-10-05. Preserve this character's painted texture, proportions, compact shell
and leaf-shaped tail through production. The original is saved unchanged:
1254 × 1254 RGB PNG with an opaque white background. Transparency, layered
animation art and runtime exports are not prepared yet.

## Character brief

- Upright turtle in a slight three-quarter pose; large round head with a slight
  tilt, short neck, broad feet and small hands resting beside the belly.
- Sage body, olive shell, cream belly, peach cheeks, warm brown eyes.
- Shell remains visible beside the torso, with sparse broad markings.
- The master was generated with all five existing pets as style references,
  without the draft sketch. Its character design is now the visual source of truth.
- Signature behaviour: a delayed reaction followed by an enthusiastic wave.
- Planned states: idle (blink/wave), walk (small determined steps), sleep
  (head partly tucked into shell with face still readable).

## Review files

- [Selected master, original resolution](selected_master.png)
- [Editable composition](turtle_pond_buddy.svg)
- [Transparent 450 × 450 render](turtle_pond_buddy.png)
- [Comparison and small-size review](review.png)
- [Tail alternatives on the smaller-shell composition](tail_options.png)

Tail alternatives are A: leaf-shaped (selected), B: curved droplet, C: soft curl.
These explore silhouette only. Each tail originates behind the
lower torso. Leaf-shaped means the tail's own shape, not an attached plant.
Editable studies: [A](tail_leaf.svg), [B](tail_droplet.svg), [C](tail_curl.svg).

The earlier composition and tail files remain design studies. The review
compares the sketch with the shipped cat and shows both on the
existing free room background. The 64 px and 96 px views are readability probes,
not a claim about the app's exact pet scale.

## Next stage

1. Prepare a transparent cutout from the selected master at original resolution.
   Check light and dark backgrounds for white fringes and lost painted edges;
   keep the cream belly and eye whites intact.
2. Prepare editable layers: shell, leaf tail, torso/belly, head, each arm,
   each leg, and facial-expression layers. Reconstruct the torso behind the
   hands and other hidden joints so movement does not expose gaps. AI-separated
   parts require review for shape and texture consistency.
3. Establish a shared 450 × 450 export canvas, consistent scale and foot baseline.
   Make an idle loop first (gentle breathing, blink, slight tail sway; wave as a
   secondary gesture), then walk and sleep. Do not crop and centre each frame
   independently with the furniture normalizer.
4. Review looping motion and small-size readability before Godot equipment
   socket calibration, runtime PNG exports and pet-catalog integration.

The [generation prompt](gemini_prompt.txt) and [existing-pet reference](pet_style_reference.png)
record the exploration setup; future edits should use the selected master.

Follow the [art process](../../../.codex/skills/new-furniture-art/SKILL.md)
for visual review, and the [pet authoring workflow](../../../docs/godot-png-sequence-socket-workflow.md)
for equipment sockets when animations exist. Catalog integration, version gates,
pricing, release timing, and backend changes have not been decided.

To render the composition again from the repository root:

```sh
rsvg-convert -w 450 -h 450 design/pet_sketches/turtle_pond_buddy/turtle_pond_buddy.svg -o design/pet_sketches/turtle_pond_buddy/turtle_pond_buddy.png
```
