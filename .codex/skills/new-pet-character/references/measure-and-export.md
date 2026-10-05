# Measure and export

Review by measurement, not by eye alone. Every turtle defect that reached the
owner (darker colours, a 10% larger walk, a 20% larger sleep head) was
measurable before it was shown.

## In-app facts

- Runtime frames are 450 × 450 RGBA, named
  `assets/pet_sequences/<pet>/<state>/<pet>_<state>-NN.png`, with idle stored
  as `stay`. Each sequence also keeps a fallback GIF that serves as its stable
  `sourceAsset` (tiger and turtle: `assets/pet/<pet>/<pet>_{stay,moving,sleep}.gif`).
- Shipped pets stand roughly 360-436 px tall. The tiger stands about 390 px
  tall with its feet on y≈432, which the turtle copied.
- While walking, the pet travels sideways. The art is drawn heading image-left
  and is flipped when moving right (`facingRight` in `home_view.dart`).
- With no `PetSocketConfig`, the equipment overlay draws nothing on the pet.

## Review measurements

The split script reports or produces all of these for a sheet:

- **Grid:** split by `width // 3`. Expect each row to sit at a different height
  and scale (the turtle's bottom rows were about 20 px higher and about 3% larger).
- **Baseline:** move each frame's lowest foot to one line using integer
  translation only. Keep the generated horizontal placement, because centring
  each frame removes any lean, and aligning on a foot band makes the frames
  jump sideways once a foot lifts.
- **Colour:** take the median of the skin, shell and belly regions and compare
  them with the master. Map them back with one per-channel curve through
  black, the three anchors and white. Check the result again after matching.
- **Size:** compare the widest row of the head between states and sheets.
  Different sheets come out at different scales (the turtle walk was 10%
  larger than its idle). Measure the head in comparable regions. A
  fixed-fraction band failed on the seated sleep pose, so measure the isolated
  head layer and re-check on the final export.
- **Previews:** an aligned contact sheet with the ground line drawn, a GIF at
  the real timing, and, after the background is removed, light and dark loops
  plus 96 px and 128 px size checks.
- **Showing the owner:** the browser pane cannot load local files or the GIFs a
  page references. Serve a page with GIFs embedded as data URIs from
  `python3 -m http.server` (background, longest timeout) and open
  `http://localhost:<port>`.

## Export

1. Colour-match each sequence to the master.
2. Remove the background: flood-fill near-white from the corners, keep
   components larger than 2% of the character (this drops specks), soften the
   edge from whiteness and un-premultiply the white. Check on a dark
   background for fringe.
3. Scale each state to one character size: the idle height sets the size,
   and the other states match the idle's head width. Resize premultiplied
   (`RGBa`).
4. Place each sequence by its own lowest foot on the shared baseline. Centre
   the idle, and give the other states the idle's mean head x, so switching
   states does not jump.
5. Assert that nothing is clipped and the baseline is within 2 px. Write
   `timing.json` and the review GIFs.

## Scripts

These are the turtle implementations. Copy them into the new pet's folder and
adapt the constants named here; they are not generic tools.

| Script | Purpose | Adapt |
| --- | --- | --- |
| [walk_trial/split_sheet.py](../../../../design/pet_sketches/turtle_pond_buddy/walk_trial/split_sheet.py) | Split, baseline-align, colour-measure and colour-match a 3 × 3 sheet | `MASTER` colours and the region hue/value masks |
| [export/export_frames.py](../../../../design/pet_sketches/turtle_pond_buddy/export/export_frames.py) | Colour-match, cut out, size-match and place stay/walk | `SEQS` paths and timings; `TARGET_H`, `BASE_Y` |
| [sleep_trial/animate_sleep.py](../../../../design/pet_sketches/turtle_pond_buddy/sleep_trial/animate_sleep.py) | Procedural sleep: head/body cut, nod, breathing, z marks | `HEAD` ellipse, `NECK_PIVOT`, `NECK_BEHIND_Y`, the z source cell |
| [rig/split_layers.py](../../../../design/pet_sketches/turtle_pond_buddy/rig/split_layers.py), [rig/compose.py](../../../../design/pet_sketches/turtle_pond_buddy/rig/compose.py), [rig/walk_test.py](../../../../design/pet_sketches/turtle_pond_buddy/rig/walk_test.py) | Cut-out rig and a procedural walk | Every polygon and pivot (hand-placed on the master) |
| [rig/pose_guide.py](../../../../design/pet_sketches/turtle_pond_buddy/rig/pose_guide.py) | Flat-colour 3 × 3 pose guide from the rig poses | Colours, exaggerated lift |
| [export/install_assets.py](../../../../design/pet_sketches/turtle_pond_buddy/export/install_assets.py) | Copy frames into `assets/` and build the fallback GIFs | Pet id and GIF names |
| [sockets/estimate_sockets.py](../../../../design/pet_sketches/turtle_pond_buddy/sockets/estimate_sockets.py) | Godot scenes and level-1 sockets: hand-placed frame 0, template-tracked | `FRAME0` per state, `GODOT` path; run once before review |
| [sockets/fit_glasses.py](../../../../design/pet_sketches/turtle_pond_buddy/sockets/fit_glasses.py) | Face-item fit from measured eye tilt and spacing, written to Godot and printed for Dart | Lens centres, `OWNER_TUNE` |

Paths are relative to the turtle folder.
