# Turtle equipment sockets

Started on 2026-10-05. **Review level 1 (estimated): not synced to Flutter.**

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

## Next

1. [USER ACTION REQUIRED] In Godot, use Scene Browser → turtle → each action,
   with representative equipment (small and wide hat, glasses, narrow and wide
   body item, close-fitting and large back item). Fix any frame, then Capture
   and **Export Sockets** before switching scenes. Record any per-pet equipment
   settings, then mark each animation × slot as level 2.
2. Generate the Flutter tracks with `generate_flutter_tracks.py --track-threshold 0`,
   add the `PetSocketConfig` and any `equipment_catalog.dart` fit overrides, and
   run the full validation.
