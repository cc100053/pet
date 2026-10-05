# Little Pond Buddy

The owner selected the [generated master illustration](selected_master.png) on
2026-10-05. Preserve this character's painted texture, proportions, compact shell
and leaf-shaped tail through production. The original is saved unchanged:
1254 × 1254 RGB PNG with an opaque white background. A nine-frame
[idle trial](idle_trial/README.md) has been split and aligned; its continuous-loop
motion and timing were accepted on 2026-10-05.

## Status (2026-10-05)

Production complete and in the app, hidden behind `minAppVersion` 5.0.0. The
owner checked it on a device at room size on 2026-10-05.

| Stage | Result |
| --- | --- |
| Idle (`stay`) | AI sheet, prompt only: 9 frames, 1650 ms ([idle trial](idle_trial/README.md)) |
| Walk | Pose-guided AI sheet plus one targeted fix: 8 frames, 1600 ms, crossing legs ([walk v4](walk_trial/v4/README.md)) |
| Sleep | Generated pose with a procedural dozing nod, breathing and z marks: 16 frames, 2560 ms ([sleep loop](sleep_trial/README.md)) |
| Export | Colour-matched to the master, transparent 450 px, one head size and baseline across states ([export](export/README.md)) |
| App | Pet id `turtle`, catalog, frames, fallback GIFs, five-language copy and tests ([export § App integration](export/README.md#app-integration-2026-10-05)) |
| Sockets | Owner-reviewed and synced to `pet_sockets.dart`; hats on the Godot default fit; sunglasses tilted to the eyes ([sockets](sockets/README.md)) |

Still open: release timing for 5.0.0, and the push-notification avatar
(`notify_friend` shows the ghost until an avatar is published and the function
deployed under its own approval). Rejected attempts (walk v1-v3) and the unused
[cut-out rig](rig/README.md) are kept as history. The full process and its
lessons are in the `new-pet-character` skill
(`.codex/skills/new-pet-character/SKILL.md`).

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

## Production history

Walk took four AI versions. v1 lifted only one foot. v2 had alternating steps
but no weight shift. The v3 march-in-place waddle had sideways kicks and no
crossing. The rig-derived pose guide in v4, plus a targeted fix for frames 3
and 6-8, was accepted. Each trial README records its prompt, measurements and
review. The [walk prompt](walk_prompt.txt) and [sleep prompt](sleep_prompt.txt)
are the originals. The sleep prompt asked for too little motion, which is why
the sleep loop is procedural.

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
