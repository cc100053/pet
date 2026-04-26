# Godot PNG Sequence Socket Workflow

> Audience: future PicPet coding session or asset-authoring session
> Last updated: 2026-04-25
> Scope: pet PNG sequence playback, socket marker authoring in Godot, equipment preview, and applying exported JSON to the Flutter app

## Goal

PicPet now renders pet animations from PNG sequences instead of relying on Flutter GIF playback. Equipment placement is still widget-layer overlay rendering, but the rendered pet frame and the equipment socket motion can share the same animation progress. This avoids the old problem where a GIF internally moved inside a fixed canvas while equipment stayed on a static Flutter coordinate.

The intended workflow is:

1. Prepare a pet animation as a PNG sequence.
2. Build or open the matching Godot scene.
3. Use the Socket Authoring add-on to mark `head`, `body`, and `back` sockets per frame.
4. Optionally load an equipment PNG, tune its anchor/size, and preview playback in Godot.
5. Export the socket JSON.
6. Copy the PNG sequence and timing into Flutter.
7. Convert the JSON's normalized socket data into `PetSocketCatalog` and equipment catalog values.
8. Run Flutter verification.

GIF assets are still retained as stable source ids and migration fallback assets. Do not delete old GIF code/assets until the migration cleanup is explicitly requested.

## File Locations

| Purpose | Path |
| --- | --- |
| Flutter app repo | `/Users/fatboy/pet` |
| Godot authoring project | `/Users/fatboy/pet-tomo` |
| Godot socket add-on | `/Users/fatboy/pet-tomo/addons/socket_authoring/` |
| Godot pet scenes | `/Users/fatboy/pet-tomo/pet/<pet>/<animation>.tscn` |
| Godot exported socket JSON | beside the scene, e.g. `/Users/fatboy/pet-tomo/pet/ghost/ghost_stay_sockets.json` |
| Flutter runtime PNG sequences | `/Users/fatboy/pet/assets/pet_sequences/<pet>/<state>/` |
| Flutter source/fallback pet assets | `/Users/fatboy/pet/assets/pet/<pet>/` |
| Flutter frame sequence catalog | `/Users/fatboy/pet/lib/features/pet/pet_animation_frames.dart` |
| Flutter sequence renderer | `/Users/fatboy/pet/lib/features/pet/pet_animated_image.dart` |
| Flutter socket catalog | `/Users/fatboy/pet/lib/features/pet/pet_sockets.dart` |
| Flutter equipment catalog | `/Users/fatboy/pet/lib/features/pet/equipment_catalog.dart` |
| Flutter overlay placement math | `/Users/fatboy/pet/lib/features/home/widgets/pet_equipment_layout.dart` |
| Runtime overlay renderer | `/Users/fatboy/pet/lib/features/home/widgets/pet_equipment_overlay.dart` |
| Asset registration | `/Users/fatboy/pet/pubspec.yaml` |
| Focused tests | `/Users/fatboy/pet/test/features/pet/` and `/Users/fatboy/pet/test/features/home/widgets/` |

## Current Runtime Model

Flutter still uses the old GIF asset path as the stable source id. For example:

```dart
PetFrameSequence(
  petId: 'fish',
  sourceAsset: 'assets/pet/fish/fish_stay.gif',
  frameDurationsMs: [500, 200, 100, ...],
  frameAssets: [
    'assets/pet_sequences/fish/stay/fish_stay-01.png',
    'assets/pet_sequences/fish/stay/fish_stay-02.png',
  ],
)
```

Runtime views pass the source asset to `PetAnimationFrameBuilder` or `PetAnimatedImage`. If a sequence exists, Flutter renders the current PNG frame. If no sequence exists, it falls back to the source asset.

Important current coverage:

- `HomeView`: main pet and equipment overlay use the sequence renderer.
- Room selection avatars use `PetAnimatedImage`.
- Chat menu avatar uses `PetAnimatedImage`.
- Room inventory equipment preview uses `PetAnimationFrameBuilder`.
- Pet selection cards use `PetAnimatedImage`.
- The old Flutter Dress-up Fit Tool remains legacy/debug-only. Future fitting should happen in Godot.

## Asset Naming

Use consistent runtime names in Flutter:

```text
assets/pet_sequences/<pet>/<state>/<pet>_<state>-NN.png
```

Examples:

```text
assets/pet_sequences/ghost/stay/ghost_stay-01.png
assets/pet_sequences/cat/walk/cat_walk-08.png
assets/pet_sequences/fish/sleep/fish_sleep-07.png
assets/pet_sequences/tiger/stay/tiger_stay-09.png
```

Godot source files may use different names, such as `fish-stay-01.png` under `/Users/fatboy/pet-tomo/pet/fish/fish_stay/`. That is acceptable. Treat Godot as the authoring project and Flutter `assets/pet_sequences/` as the runtime bundle.

## Frame Duration Rule

Do not assume that a GIF timeline is simply `0.1 = one frame`, `0.5 = five frames`, or that every frame has the same delay. Some current animations have mixed frame durations, for example fish stay uses `500, 200, 100, ...` ms.

Use one of these sources of truth:

1. Godot Socket Authoring JSON: `frameDurationsMs` and each `frames[].durationMs`.
2. Existing Flutter catalog: `PetAnimationFrames.<petState>.frameDurationsMs`.
3. The original GIF metadata, if you are extracting a new sequence from GIF.

The app samples by cumulative time, not by equal frame index spacing.

## Godot Scene Requirements

Each authoring scene should contain:

- `AnimatedSprite2D`
- `HeadSocket` as `Marker2D`
- `BodySocket` as `Marker2D`
- `BackSocket` as `Marker2D`

Recommended scene setup:

- Keep the animation canvas size equal to the source PNG canvas, usually `450x450`.
- Set `AnimatedSprite2D.centered = false` so marker positions use top-left PNG coordinates.
- Put frame PNGs in the matching Godot folder:
  - `/Users/fatboy/pet-tomo/pet/ghost/ghost_stay/`
  - `/Users/fatboy/pet-tomo/pet/cat/cat_stay/`
  - etc.
- Keep sockets visually small and clearly colored in the editor. The add-on reads node positions, not visual style.

## Enabling The Godot Add-On

Add-on files:

```text
/Users/fatboy/pet-tomo/addons/socket_authoring/plugin.cfg
/Users/fatboy/pet-tomo/addons/socket_authoring/socket_authoring_plugin.gd
/Users/fatboy/pet-tomo/addons/socket_authoring/socket_authoring_dock.gd
```

In Godot:

1. Open `/Users/fatboy/pet-tomo`.
2. Open `Project > Project Settings > Plugins`.
3. Enable `Socket Authoring`.
4. Open a pet animation scene, for example `pet/ghost/ghost_stay.tscn`.
5. The `Socket Authoring` dock should appear on the right.

The add-on version at the time of writing is `0.5.0`.

## Socket Authoring Dock Controls

Core controls:

| Control | Meaning |
| --- | --- |
| `Pet` picker | Scans `res://pet/<pet>/` and selects the pet authoring scene group |
| `Action` picker | Selects an action scene such as `stay`, `sleep`, or `moving` |
| `Open Selected` | Opens the selected pet/action scene and auto-loads the matching socket JSON when present |
| `Refresh Lists` | Re-scans pet scenes and equipment PNGs |
| `Pet` | Pet id written to JSON, e.g. `ghost`, `cat`, `fish`, `tiger` |
| `Animation` | Animation/state label written to JSON, e.g. `idle`, `sleep`, `walk` |
| `Canvas W` / `Canvas H` | Source canvas size used for normalized coordinates |
| `Frame Hold` | Compatibility field for old repeated-frame workflows |
| `Duration ms` | Current frame duration |
| `All Duration` + `Apply to All Frames` | Bulk set all frame durations |
| `Prev` / `Next` | Move the `AnimatedSprite2D` frame |
| `Capture & Next` | Save all marker positions and current duration, then advance |
| `Capture, Copy and Next` | Save current frame and copy the selected preview slot to the next frame |
| `Load JSON` | Restore a previous socket JSON into the dock |
| `Export JSON` | Write `<scene_basename>_sockets.json` beside the scene |

Equipment preview controls:

| Control | Meaning |
| --- | --- |
| `Equipment` | Scans `/Users/fatboy/pet/assets/equipment/**/*.png`; the first option clears/removes the current equipment preview |
| `PNG Path` | Equipment PNG to preview, e.g. `/Users/fatboy/pet/assets/equipment/hats/straw_hat.png` |
| `Slot` | Which socket the preview follows |
| `Anchor X` / `Anchor Y` | Anchor inside the equipment image, normalized `0..1` |
| `Size` | Equipment width as a ratio of pet canvas width |
| `Load` | Load the equipment PNG |
| `Play` / `Stop` | Preview the captured sockets using per-frame durations |

Equipment preview math in Godot:

```text
target_width = pet_canvas_width * size_ratio
scale = target_width / equipment_texture_width
preview_size = equipment_texture_size * scale
anchor_pixel = preview_size * anchor
equipment_position = marker_position - anchor_pixel
```

Flutter now mirrors this width-based, source-aspect-preserving sizing through `EquipmentSize.fromWidthAspect(...)`.

## Recommended Marker Workflow

Use this per animation state:

1. Open the target scene, for example `fish_stay.tscn`.
2. Confirm `Canvas W/H` match the source PNG canvas, usually `450x450`.
3. Confirm `Pet` and `Animation` are correct.
4. If the GIF/sequence has known frame durations, set them:
   - Use `Duration ms` per frame, or
   - Use `All Duration` if every frame is identical.
5. Go to frame `0`.
6. Drag `HeadSocket`, `BodySocket`, and `BackSocket` to the intended attachment points.
7. Click `Capture & Next`.
8. For the next frame:
   - If the sprite moved, adjust the markers.
   - If a marker should stay at the same position, use `Capture, Copy and Next` for the selected slot, or just leave it and capture.
9. Repeat until every frame is captured.
10. Load an equipment PNG if needed.
11. Tune `Anchor X/Y` and `Size`.
12. Click `Play` to verify equipment follows the marker.
13. Click `Export JSON`.

Guidelines:

- Frame `0` becomes the base socket position in Flutter.
- Motion tracks should usually store deltas from frame `0`, not absolute coordinates.
- Keep marker choice consistent across frames. For a hat, the `head` socket should track the same visual contact point on the head.
- Do not chase sub-pixel noise. If adjacent frames visually share the same contact point, reusing the same coordinate is better than introducing jitter.
- For `body` and `back`, only add motion tracks if the slot visibly needs to follow frame movement. Static base sockets are acceptable during rollout.

## Exported JSON Shape

The add-on exports both compatibility and richer schemas:

```json
{
  "pet": "ghost",
  "animation": "idle",
  "canvas": [450.0, 450.0],
  "frameCount": 13,
  "frameHold": 2,
  "frameDurationsMs": [200, 200, 200],
  "frames": [
    {
      "index": 0,
      "image": "res://pet/ghost/ghost_stay/ghost_stay-01.png",
      "durationMs": 200,
      "sockets": {
        "head": { "x": 218.0, "y": 59.0, "nx": 0.484444444, "ny": 0.131111111 },
        "body": { "x": 200.0, "y": 208.0, "nx": 0.444444444, "ny": 0.462222222 },
        "back": { "x": 343.0, "y": 210.0, "nx": 0.762222222, "ny": 0.466666667 }
      }
    }
  ],
  "equipmentPreview": {
    "enabled": true,
    "assetPath": "/Users/fatboy/pet/assets/equipment/hats/straw_hat.png",
    "slot": "head",
    "anchor": { "x": 0.5, "y": 0.55 },
    "sizeRatio": 0.8
  },
  "sockets": {
    "head": [
      { "x": 218.0, "y": 59.0, "nx": 0.484444444, "ny": 0.131111111 }
    ],
    "body": [],
    "back": []
  }
}
```

Use `frames[]` as the preferred format. `sockets` exists for compatibility and quick lookup.

## Applying PNG Sequence To Flutter

1. Copy or export PNGs into Flutter:

```text
/Users/fatboy/pet/assets/pet_sequences/<pet>/<state>/
```

2. Use runtime filenames:

```text
<pet>_<state>-01.png
<pet>_<state>-02.png
...
```

3. Add the asset directory to `pubspec.yaml` if it is a new directory:

```yaml
flutter:
  assets:
    - assets/pet_sequences/<pet>/<state>/
```

4. Add or update a `PetFrameSequence` in `lib/features/pet/pet_animation_frames.dart`:

```dart
static const PetFrameSequence fishIdle = PetFrameSequence(
  petId: 'fish',
  sourceAsset: 'assets/pet/fish/fish_stay.gif',
  frameDurationsMs: [500, 200, 100, 200],
  frameAssets: [
    'assets/pet_sequences/fish/stay/fish_stay-01.png',
    'assets/pet_sequences/fish/stay/fish_stay-02.png',
    'assets/pet_sequences/fish/stay/fish_stay-03.png',
    'assets/pet_sequences/fish/stay/fish_stay-04.png',
  ],
);
```

5. Add the sequence to `PetAnimationFrames.all`.

6. Keep the `sourceAsset` equal to the old catalog GIF path. This lets existing code call `PetAnimatedImage(sourceAsset: pet.stayAsset)` without knowing whether the runtime frame is GIF or PNG.

7. If you add a new pet id, also update `PetCatalog` and version-gated shared item support as usual.

## Applying Socket JSON To Flutter

Use the JSON's normalized values:

```text
nx = x / canvasWidth
ny = y / canvasHeight
```

For each slot:

1. Use frame `0` as the base socket:

```dart
PetEquipmentSlot.head: PetSocket(x: 0.484444444, y: 0.131111111),
```

2. For a moving slot, store deltas from frame `0`:

```text
deltaX = frame.nx - frame0.nx
deltaY = frame.ny - frame0.ny
```

3. Add the deltas as a timed motion track:

```dart
idleMotionTracksBySlot: {
  PetEquipmentSlot.head: PetMotionTrack.timed(
    frameDurationsMs: PetAnimationFrames.ghostIdle.frameDurationsMs,
    frames: [
      Offset(0, 0),
      Offset(0, -0.002222222),
      Offset(-0.002222222, -0.004444444),
    ],
  ),
},
```

4. Keep `body` / `back` static if their motion does not matter visually yet.

Current `PetSocketConfig.resolveMotion(...)` ignores motion for walking and sleeping states. If equipment needs true per-frame tracking for `walk` or `sleep`, extend the socket model first rather than overloading idle tracks.

## Applying Equipment Preview Metadata

If the exported JSON contains:

```json
"equipmentPreview": {
  "enabled": true,
  "assetPath": "/Users/fatboy/pet/assets/equipment/hats/straw_hat.png",
  "slot": "head",
  "anchor": { "x": 0.5, "y": 0.55 },
  "sizeRatio": 0.8
}
```

If the preview was cleared with the `Equipment` selector, the export writes:

```json
"equipmentPreview": {
  "enabled": false
}
```

Map it into `EquipmentCatalog`:

```dart
EquipmentDefinition(
  sku: 'equip_straw_hat',
  slot: PetEquipmentSlot.head,
  assetPath: 'assets/equipment/hats/straw_hat.png',
  anchor: EquipmentAnchor(x: 0.5, y: 0.55),
  sizeRatio: EquipmentSize.fromWidthAspect(
    width: 0.8,
    sourceWidth: 512,
    sourceHeight: 360,
  ),
)
```

Use `EquipmentSize.fromWidthAspect(...)` when the Godot preview used the `Size` width ratio. This prevents Flutter `BoxFit.contain` padding from shifting the anchor relative to the Godot preview.

## Quick Manual Conversion Checklist

When receiving `<pet>_<state>_sockets.json`:

- Confirm `frameCount` equals the number of PNGs in `assets/pet_sequences/<pet>/<state>/`.
- Confirm `frameDurationsMs.length == frameCount`.
- Confirm `PetAnimationFrames.<sequence>.frameAssets.length == frameCount`.
- Copy `frameDurationsMs` into the Flutter sequence.
- Use `frames[0].sockets.<slot>.nx/ny` as base sockets.
- Generate motion deltas for only the slots that need per-frame tracking.
- If `equipmentPreview.enabled != false`, copy `equipmentPreview.anchor` and `equipmentPreview.sizeRatio` into the equipment catalog if the preview was tuned.
- Add or update focused tests.

## Verification Commands

After changing Dart or assets:

```sh
dart format lib test
flutter analyze
flutter test
flutter build bundle
git diff --check
```

For asset bundle debugging:

```sh
find assets/pet_sequences -type f | wc -l
strings build/flutter_assets/AssetManifest.bin | rg 'assets/pet_sequences/.+\.png'
```

For focused pet/equipment checks:

```sh
flutter test test/features/pet/pet_animation_frames_test.dart \
  test/features/pet/pet_socket_config_test.dart \
  test/features/home/widgets/pet_equipment_overlay_test.dart \
  test/features/home/widgets/pet_equipment_layout_test.dart
```

## Common Failure Modes

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Equipment looks correct in Godot but shifted in Flutter | Equipment size was treated as width-only in Godot but width/height box in Flutter | Use `EquipmentSize.fromWidthAspect(...)` with the source PNG aspect ratio |
| Equipment follows marker in Godot but not app | Socket JSON was exported but not converted into `PetSocketCatalog` motion track | Add base socket and `PetMotionTrack.timed(...)` deltas |
| App animation timing feels different from GIF/Godot | Flutter sequence uses equal frame timing or wrong durations | Copy `frameDurationsMs` from JSON/GIF metadata |
| PNG frames missing in app | Asset directory not listed in `pubspec.yaml` or bundle not rebuilt | Add directory and run `flutter build bundle` |
| Marker coordinates are scaled wrong | Godot canvas size does not match PNG canvas | Set `Canvas W/H` to the source image canvas before export |
| Marker jumps when changing Godot frame | Frame was not captured or loaded for that index | Use `Load JSON`, verify captured frame list, recapture missing frames |
| Widget tests hang | A sequence animation is running in tests | Use existing `PetAnimationFrameBuilder`; it disables repeat animation under Flutter widget test binding |

## Handoff Notes

- Treat Godot JSON as authoring output, not a runtime app asset.
- Treat Flutter `PetAnimationFrames` and `PetSocketCatalog` as the current production source of truth.
- Keep old GIF assets until the user explicitly approves cleanup.
- Do not rely on the legacy Flutter Dress-up Fit Tool for future calibration. It can remain for debugging, but Godot is now the preferred marker/equipment preview path.
