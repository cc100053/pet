# Little Pond Buddy

The owner selected the [generated master illustration](selected_master.png) on
2026-10-05. Preserve this character's painted texture, proportions, compact shell
and leaf-shaped tail through production. The original is saved unchanged:
1254 × 1254 RGB PNG with an opaque white background. A nine-frame
[idle trial](idle_trial/README.md) has been split and aligned; its continuous-loop
motion and timing were accepted on 2026-10-05.
Transparency, layered animation art and runtime exports are not prepared yet.

## Character brief

- Upright turtle in a slight three-quarter pose; large round head with a slight
  tilt, short neck, broad feet and small hands resting beside the belly.
- Sage body, olive shell, cream belly, peach cheeks, warm brown eyes.
- Shell remains visible beside the torso, with sparse broad markings.
- The master was generated with all five existing pets as style references,
  without the draft sketch. Its character design is now the visual source of truth.
- Signature behaviour: a delayed reaction followed by an enthusiastic wave.
- Planned states: idle (accepted blink, breathing and tail sway), walk (small determined steps and blink), sleep
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

1. Prepare walk, then sleep sprite-sheet trials using the selected master for
   character identity. Walk should be a small, determined in-place cycle at the
   same camera angle. The [walk prompt](walk_prompt.txt) is ready: eight gait
   phases plus a duplicate first frame for closure comparison in a 3 × 3 sheet.
   Preview frames 1–8 without doubling the endpoint hold. Split, align and review
   each loop as with idle. The [sleep prompt](sleep_prompt.txt) proposes a seated,
   slightly tucked pose with the face visible, eight breathing phases and a
   closure-comparison frame. Sleep pose and generated artwork await review.
2. Prepare transparent frames for the selected idle, walk and sleep sequences.
   Check light and dark backgrounds for white fringes and lost painted edges;
   keep the cream belly and eye whites intact.
3. If needed, prepare editable layers: shell, leaf tail, torso/belly, head, each arm,
   each leg, and facial-expression layers. Reconstruct the torso behind the
   hands and other hidden joints so movement does not expose gaps. AI-separated
   parts require review for shape and texture consistency.
4. Establish a shared 450 × 450 export canvas, consistent scale and foot baseline.
   Use the accepted idle timing (1650 ms) and reviewed walk/sleep timing.
   Do not crop and centre each frame
   independently with the furniture normalizer.
5. Review looping motion and small-size readability before Godot equipment
   socket calibration, runtime PNG exports and pet-catalog integration.

The [generation prompt](gemini_prompt.txt) and [existing-pet reference](pet_style_reference.png)
record the exploration setup; future edits should use the selected master.

## Existing idle references inspected

All current PNG frames and their catalog timing were inspected on 2026-10-05.
Cat: 7 frames / 1300 ms, tail movement and blink. Tiger: 9 / 1600 ms, tail sway.
Chicken: 5 / 1200 ms, slight feather/body movement and blink. Fish: 14 / 3400 ms,
body bob, fin movement and bubbles. Ghost: 13 / 2600 ms, subtle body/silhouette
movement. The proposed turtle trial combines a fixed stance, brief blink,
gentle leaf-tail sway and tiny breathing motion. The continuous preview's
1650 ms timing is accepted; verify parity when exporting runtime frames.
The image prompt cannot encode actual frame durations.

## Existing walk references inspected

Cat: 8 frames / 1200 ms; alternating steps, subtle body movement, blink and tail
motion. Tiger: 7 / 1200 ms; clear foot lifts, body bob, blink and tail movement.
Chicken: 8 / 1600 ms; alternating leg movement and feather/tail changes. These
PNG sequences and their catalog timing were inspected on 2026-10-05 for the
walk prompt. The owner requested a walk blink on 2026-10-05. The turtle prompt
now adds half-closed eyes on frame 3, closed eyes on frame 4 and open eyes from
frame 5, while gait and arm/tail motion continue. Proposed playback is eight
gait frames at approximately 200 ms each, preserving cadence through the blink.

## Existing sleep references inspected

All five sleep PNG sequences were inspected on 2026-10-05. Cat is seated with
closed eyes and rising z marks; chicken and ghost retain a closed-eye resting
pose with z marks. Tiger reclines with snore bubbles, and fish has closed eyes,
fin movement and bubbles. The turtle prompt borrows the closed-eye resting
pose and z effect, using a slower breathing cycle. It does not generate an
awake-to-sleep transition. Foot contact, facial visibility and loop continuity
must be checked on the generated result.

Follow the [art process](../../../.codex/skills/new-furniture-art/SKILL.md)
for visual review, and the [pet authoring workflow](../../../docs/godot-png-sequence-socket-workflow.md)
for equipment sockets when animations exist. Catalog integration, version gates,
pricing, release timing, and backend changes have not been decided.

To render the composition again from the repository root:

```sh
rsvg-convert -w 450 -h 450 design/pet_sketches/turtle_pond_buddy/turtle_pond_buddy.svg -o design/pet_sketches/turtle_pond_buddy/turtle_pond_buddy.png
```
