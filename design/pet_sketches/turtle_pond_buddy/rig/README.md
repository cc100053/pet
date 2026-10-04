# Turtle cut-out rig

Chosen on 2026-10-05 instead of generating walk sheets with AI (walk trials v1–v3
lacked crossing legs, kept changing detail between frames and drifted in colour).
The parts are cut from the [selected master](../selected_master.png), so every
frame keeps the master's painted pixels and colours.

Run from `design/pet_sketches/turtle_pond_buddy` (needs OpenCV, NumPy, Pillow):

```sh
python3 rig/split_layers.py   # master_rgba.png -> layers/*.png + layers/pivots.json
python3 rig/walk_test.py      # rough 8-frame walk -> walk_test/ + walk_test.gif
```

- `master_rgba.png`: master with the white background removed (flood fill
  from the corners plus a softened, un-premultiplied edge). Checked on a dark
  background: no white fringe.
- `layers/`: `body` (head, torso, belly, shell), `underside`, `leg_a`
  (image-left), `leg_b` (image-right), `arm_a`, `arm_b` and `tail`. All are
  1254 × 1254 in master coordinates; `pivots.json` holds the rotation pivots
  and the ground line.
- Hidden areas are filled in automatically: the leg tops extend behind the body,
  the tail base sits under the shell, and the torso and belly behind the arms use
  inpainted colour plus brush grain from the forehead. A shaded underside sits
  behind the legs, so a moving leg never shows the background.
- [`compose.py`](compose.py) draws, back to front: tail, underside, leg_a,
  leg_b, body, arm_a, arm_b. With no pose, the composite matches the master
  except for the soft edges (1.7% of pixels differ by more than 20 levels).
- [`layer_review.png`](layer_review.png) shows each layer next to the master.

## Walk test (draft)

[`walk_test.gif`](walk_test.gif): 8 frames at 200 ms each, heading image-left
to match the in-app convention (moving left uses the art unflipped). Each step
goes contact, down, passing, up: the stepping leg lifts and swings forward,
the planted foot slides back, and the legs overlap during the passing pose. The
body is highest at passing, the arms swing opposite the legs and the tail trails
one frame behind. The parameters at the top of `walk_test.py` are starting
values that have not been reviewed yet.

## Open items

- [USER ACTION REQUIRED] Review the layer cuts and the motion in the draft walk.
- Add a blink: eyelid overlays on the body layer for half-closed and closed eyes.
- Small seams remain where the tail meets the shell and along the leg-A thigh
  edge in some poses. Check them at app size before touching them up by hand.
- Decide the final timing, export scale and baseline against the idle export,
  then generate the runtime PNGs and calibrate equipment sockets.
