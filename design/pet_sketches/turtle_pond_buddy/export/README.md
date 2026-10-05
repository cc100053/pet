# Turtle runtime-style exports

Generated on 2026-10-05 from the two accepted loops by
[`export_frames.py`](export_frames.py), run from `design/pet_sketches/turtle_pond_buddy`:

```sh
python3 export/export_frames.py
```

| State | Source | Frames | Timing |
| --- | --- | --- | --- |
| `stay/turtle_stay-01..09.png` | [idle trial](../idle_trial/README.md), accepted continuous loop | 9 | 200, 200, 250, 200, 120, 160, 120, 200, 200 ms (1650 ms) |
| `walk/turtle_walk-01..08.png` | [walk v4 fix](../walk_trial/v4/README.md), accepted | 8 | 200 ms each (1600 ms) |

The format matches the shipped PNG sequences: 450 × 450 RGBA, named
`<pet>_<state>-NN.png`, with idle stored as `stay`. Timings are in [`timing.json`](timing.json).

Processing:

1. Colour match. Each sequence gets one per-channel curve mapping its measured
   skin, shell and belly to the [master](../selected_master.png) (the
   `split_sheet.py` curve). This lightens the accepted idle slightly
   (about +10 on skin) so that idle and walk share the master's colours.
2. Background removal. A flood fill from the corners removes the near-white
   background; components smaller than 2% of the turtle are dropped (this
   removes the specks in the walk sheet). The edges are softened and
   un-premultiplied from white. Checked on dark: no white fringe.
3. Size. The idle is scaled to 390 px tall, about the tiger's size. The walk
   sheet was drawn about 10% larger, so it is scaled to the idle's head width
   (scales are in `timing.json`). Resizing is premultiplied.
4. Placement. Each sequence's lowest foot sits on y=432, the tiger's baseline.
   The idle's bounding box is centred, and the walk's mean head position matches
   the idle's, so switching states does not jump. The walk heads image-left,
   which is the app's unflipped direction.

Review files are in [`review/`](review/): loops on light and dark backgrounds,
and a [contact sheet](review/contact_sheet.png) with 96 px and 128 px size probes.

## Not done (needs decisions)

- The frames are not in `assets/pet_sequences/` or `pubspec.yaml`, and there is
  no `PetAnimationFrames` or `pet_catalog.dart` entry. The catalog entry, pet
  id, price, version-gated visibility, old-client GIF fallback and release
  timing are undecided (see AGENTS.md "New shared items" and the
  shared-item-rollout skill).
- The sleep sequence has not been generated.
- Godot equipment socket calibration is not done (pet-socket-calibration skill).
- [USER ACTION REQUIRED] Check the export at actual room size on a device.
