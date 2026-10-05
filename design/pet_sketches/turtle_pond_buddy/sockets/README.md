# Turtle equipment sockets

Started on 2026-10-05. On 2026-10-05 the owner reported hats and the back socket
as calibrated (level 2), and the sockets were **synced to Flutter**:
`PetSocketConfig('turtle')` in `pet_sockets.dart` comes from
`generate_flutter_tracks.py --track-threshold 0`, with motion tracks for all
three states. At sync time the Godot JSON still matched the level-1 estimates,
with no hat or back equipment settings exported. Hats therefore use the Godot
global default fit, mirrored as turtle overrides in `equipment_catalog.dart`
(straw hat anchor (0.5, 0.75) at 0.8; crown (0.5, 0.7) at 0.32), because the
Flutter fallback is the ghost fit. No back-slot equipment exists yet. If any
hat was tuned without **Export Sockets**, export it and sync again.

[`estimate_sockets.py`](estimate_sockets.py), run from the repository root:

- Copies the runtime frames into the Godot project
  (`/Users/fatboy/pet-tomo/pet/turtle/turtle_{stay,moving,sleep}/`) and writes
  the authoring scenes `turtle_<anim>.tscn` with the exported frame durations.
- Hand-places frame 0 to match the shipped pets: head at the top-centre of the
  head where hats sit, body on the upper chest just under the chin, back on
  the shell at shoulder height.
- Tracks each socket through the later frames by matching the image patch
  around it (36 px half-patch, at most 18 px movement per frame). This follows
  the walk sway and the sleep nod.
- Writes `turtle_<anim>_sockets.json`, which the Godot dock loads as per-frame
  captures, and the review sheets `review_{stay,moving,sleep}.png` (each frame's
  sockets, with frame 0 as a grey cross).

Checks on 2026-10-05:
- `validate_socket_export.py`: all three files PASS.
- `score_socket_tracks.py --review-level 1`: no suspicious frames. Maximum
  step 9 px (stay head); largest loop delta 5.4 px (stay head).
- `inspect_pet_frames.py` was not run: it fails with the installed Pillow
  (`Image.get_flattened_data` is missing).

| Animation | Head range x, y (px) | Body | Back |
| --- | --- | --- | --- |
| stay | 7, 9 | 4, 8 | 4, 3 |
| moving | 6, 5 | 3, 6 | 4, 7 |
| sleep | 10, 5 | 2, 6 | 0, 1 |

## Sunglasses (2026-10-05)

The turtle's eyes are not level: the image-right eye sits lower. Measured
across every frame, the tilt is about 6.4° in idle, 6.2° in walk and 10.2° in
sleep (7-11° as the head nods). The eyes are about 89 px apart. The new
`EquipmentFitOverride.rotationDegrees` tilts the item clockwise about its
centre, and the flip for moving right mirrors it with the pet.
[`fit_glasses.py`](fit_glasses.py) measures the eyes against the current head
sockets and solves the lens-on-eye fit: width 0.52, and per-state anchors with
rotations, now in `equipment_catalog.dart`.

The owner then tuned stay in Godot to a smaller size: anchor (0.55, 0.15) and
size 0.45, slightly left of and below lens-on-eye. `OWNER_TUNE` in the script
keeps that size and that offset from the eyes for every state. The results
are idle (0.55, 0.15) at 6.4°, walk (0.562, 0.134) at 6.2° and sleep
(0.587, 0.026) at 10.2°, written to the Godot scene JSON and
`equipment_catalog.dart`. Its mock of the Flutter placement
is [`review_glasses.png`](review_glasses.png).

Godot now previews the tilt. The dock has a **Rotation °** field, and
`fit_glasses.py` writes each state's sunglasses anchor, size and rotation into
that scene's `equipmentSettings` and `equipmentPreview`, so opening the scene
shows the tilted glasses. After editing the add-on, reload it (Project →
Project Settings → Plugins: toggle socket_authoring off and on) or restart
Godot. Running `estimate_sockets.py` again would reset the scene JSON,
including any reviewed captures, so after the Godot review only re-run
`fit_glasses.py`.

The fit depends on the head sockets, so re-run the script after the Godot
review moves them. The sleep tilt is one median value; the per-frame head
tilt varies by about ±2°.

## Status

Owner-reviewed (level 2), synced to Flutter and checked on a device on
2026-10-05. If the turtle frames change, re-run `fit_glasses.py` only after a
new Godot socket review. Never re-run `estimate_sockets.py` over reviewed JSON.
