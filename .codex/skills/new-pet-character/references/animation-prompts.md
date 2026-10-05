# Animation and prompts

## Production routes

Pick per state; the lessons are from the turtle trials.

| Route | Use when | Strength | Cost |
| --- | --- | --- | --- |
| AI sheet, prompt only | Small, mostly-static motion: idle blink, tail sway, breathing | Fast | Painted detail changes slightly between frames and colours drift; complex gaits fail |
| AI sheet + **pose guide** | Limb motion the model cannot infer: walk cycles, crossing legs | Turtle walk v4 was the first sheet to cross the legs | The guide must be built (usually from a rig); targeted fixes are still likely |
| Procedural from one frame | Whole-part motion: nodding head, breathing, floating marks | Detail and colour never change; timing and amplitude are adjustable numbers | Needs a head/body cut with the hidden areas filled |
| Cut-out rig | Fallback when AI keeps failing; also the source of pose guides | Consistent and tweakable | Layer cutting and hidden-area fills take a session |

Turtle outcomes: idle used prompt only and was accepted; walk failed three
prompt-only versions, then succeeded with a pose guide plus one targeted fix;
sleep used the generated pose with a procedural nod.

## What each state must show

Each state must read clearly at about 100 px in the room. Ask for visible
amplitude in concrete units. "Extremely small" breathing produced a sleep
sheet in which only the z marks moved.

### Idle (`stay`)

- Fixed stance with a blink, a small breath and secondary motion (a tail sway).
- Blink: open, half-closed, closed, half-open, open. Hold the closed frames
  for 120-160 ms; at 80 ms the owner found the blink too fast.
- For a seamless loop, drop the extra rest holds at the loop boundary.
  The turtle's accepted timing is 1650 ms over 9 frames.

### Walk

- The app slides the pet sideways while the walk plays. Draw a 3/4 view
  heading image-left; moving right flips it. A front-facing march reads as
  stomping while gliding.
- Use 8 poses, two steps of contact, down, passing and up. In the passing pose
  the swinging leg crosses the planted leg (in front or behind), and the body
  is at its highest. At least one foot is always grounded, and each planted
  foot sits on one ground line.
- The two steps must mirror each other in lift height and timing. Frame 8
  must differ from frame 1, or the loop pauses.
- Arms swing opposite to the legs, the tail lags one frame, and the bob is
  small but visible.
- Blink mid-cycle (half-closed, then closed) while the legs keep moving at the
  same cadence. 200 ms per frame, 1600 ms per cycle.

### Sleep

- Already asleep in every frame (a loop, not a transition), with the face
  visible and the eyes as soft closed curves.
- The motion must read as sleeping. Use a dozing nod: a slow sink of about 9 px
  and 4° over roughly 60% of the cycle, then a quick catch with a small bounce.
  Add breathing (about 1.8% body stretch from the ground line) and z marks
  that rise toward image-right, growing and fading in turn.
- The turtle uses 16 frames at 160 ms (2560 ms).

## Writing the image prompt

Attach the master as image 1 and any pose guide as image 2. Then:

- **Identity:** list the traits to keep (head shape and tilt, face, markings,
  texture, camera). Add "Treat this as ONE drawing with only the X reposed";
  name exactly what may change.
- **Colour:** "Match image 1's colours exactly, without darkening or
  saturating them", plus the master's hex values. This reduced the drift a lot
  (v3 skin `#8EAF68`, v4 `#ADC789`, target `#B5CA95`), but post-process
  matching is still required.
- **Directions:** use IMAGE-LEFT and IMAGE-RIGHT, defined as the viewer's view,
  plus "never mirror the turtle". Use verbs that match the camera. Forward,
  behind and "passes beneath" are side-view words; on a front-facing character
  the model drew them as sideways kicks with pointed toes. In 3/4 view, name
  the near and far legs or use the guide's colours.
- **Frames:** exactly 9 frames in a 3 × 3 grid of equal square cells. Frames 1-8
  are the loop; frame 9 copies frame 1 for closure only and is not played.
  Number each frame with its single job: which foot is planted or lifted, the
  body height and the eye state. Unnumbered descriptions drift.
- **Amplitude:** use measurable phrases ("raised about half a foot-height",
  "lean about 4 degrees", "same height as frame 3").
- **Canvas:** pure flat white `#FFFFFF`; no floor, shadows, text, numbers,
  grid lines or borders; the same scale and ground line in every cell.
- **Timing:** state the intended ms per frame so the poses are spaced evenly.
  The image cannot carry durations; they are assigned after splitting.
- **Self-check:** end with a short list for the model to verify, for example
  "frames 2-4 lift the image-right foot; frames 6-8 lift the image-left foot".

Templates: [walk v4 prompt](../../../../design/pet_sketches/turtle_pond_buddy/walk_trial/v4/prompt.txt) (pose-guided walk),
[fix prompt](../../../../design/pet_sketches/turtle_pond_buddy/walk_trial/v4/fix_prompt.txt), [idle prompt](../../../../design/pet_sketches/turtle_pond_buddy/idle_prompt.txt)
and [sleep prompt](../../../../design/pet_sketches/turtle_pond_buddy/sleep_prompt.txt). The sleep prompt under-asked for motion;
raise its amplitude before reuse.

## Pose guide

Image models copy a drawn pose far more reliably than a written one. A shipped
pet's walk as a motion reference (turtle v3 used the tiger) improved the step
but never produced crossing legs.

- Render the guide from a rig ([rig/pose_guide.py](../../../../design/pet_sketches/turtle_pond_buddy/rig/pose_guide.py)) as flat colours: grey body,
  darker shell, light arms, and one distinct colour per leg. The near leg is
  drawn in front where they overlap. Add a faint ground line and keep the
  eyes as dark marks, so orientation is unambiguous.
- Exaggerate the foot lift beyond the final intent, so it reads at sheet size.
- In the prompt, map each colour to its part, say where the overlap means
  crossing, say "copy foot position, height and overlap exactly", and say
  "do NOT copy the flat colours or the ground line".

## Targeted fixes

Use the same chat, so the model keeps the master, the guide and its sheet.

- First line: keep everything identical; list the frames that must stay
  unchanged.
- One block per frame to redraw. Describe the pose, which foot stays planted
  and the frame it mirrors ("mirror of frame 3 on the other leg").
- Fix eye states explicitly. The model merged the half-closed and closed
  frames until told.
- End with the check list. Re-split and colour-match the result, because
  every edit darkens it.
