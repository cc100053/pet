# Godot Socket & Equipment Authoring Workflow

> Audience: future PicPet coding session or asset-authoring session
> Last updated: 2026-07-26
> Scope: socket marker authoring in Godot, equipment anchor/size authoring, and applying all exported data to the Flutter app

---

## Overview

There are **two independent data sets** produced by the Godot authoring plugin. They must both be applied to Flutter correctly.

| Data | What it is | Where it lives in Flutter |
|------|-----------|--------------------------|
| **Socket positions** | Normalized (0–1) XY position of each slot per animation frame | `pet_sockets.dart` — `PetSocketConfig` |
| **Equipment settings** | Anchor and size-ratio for each equipment PNG | `equipment_catalog.dart` — `EquipmentDefinition` |

These are **independent**. Exporting socket positions does not export equipment settings, and vice versa.

---

## File Locations

| Purpose | Path |
|---------|------|
| Flutter app repo | `/Users/fatboy/pet` |
| Godot authoring project | `/Users/fatboy/pet-tomo` |
| Godot socket add-on | `/Users/fatboy/pet-tomo/addons/socket_authoring/` |
| Godot pet scenes | `/Users/fatboy/pet-tomo/pet/<pet>/<animation>.tscn` |
| Godot exported socket JSON | beside the scene, e.g. `pet/ghost/ghost_stay_sockets.json` |
| Godot global equipment overrides | `/Users/fatboy/pet-tomo/equipment_overrides.json` |
| Flutter socket catalog | `/Users/fatboy/pet/lib/features/pet/pet_sockets.dart` |
| Flutter equipment catalog | `/Users/fatboy/pet/lib/features/pet/equipment_catalog.dart` |
| Flutter frame sequence catalog | `/Users/fatboy/pet/lib/features/pet/pet_animation_frames.dart` |
| Flutter overlay renderer | `/Users/fatboy/pet/lib/features/home/widgets/pet_equipment_overlay.dart` |
| Flutter placement math | `/Users/fatboy/pet/lib/features/home/widgets/pet_equipment_layout.dart` |
| Asset registration | `/Users/fatboy/pet/pubspec.yaml` |

---

## Part 1 — Socket Positions

### What Socket Positions Are

Each animation frame has three socket positions (head, body, back) stored as normalized coordinates:

```
nx = pixel_x / canvas_width    (0.0 = left edge, 1.0 = right edge)
ny = pixel_y / canvas_height   (0.0 = top edge, 1.0 = bottom edge)
```

Flutter uses these to know where to place equipment each frame.

### Godot Scene Requirements

Each authoring scene must contain:
- `AnimatedSprite2D`
- `HeadSocket` as `Marker2D`
- `BodySocket` as `Marker2D`
- `BackSocket` as `Marker2D`

Keep `AnimatedSprite2D.centered = false`. Canvas is typically `450×450`.

### Socket Authoring Workflow

Do this **per animation per pet**:

1. Scene Browser → select Pet + Action → scene auto-opens and loads its JSON if it exists
2. Confirm `Canvas W/H` match source PNG canvas (usually `450×450`)
3. Confirm `Pet` and `Animation` labels are correct
4. Go to frame 0
5. Drag `HeadSocket`, `BodySocket`, `BackSocket` to the correct attachment points
6. Click **Capture Frame** — records all three sockets, advances to next frame
7. Adjust markers for next frame, click Capture Frame again
8. Repeat until all frames are captured
9. Click **Export Sockets** ← **mandatory, otherwise all captures are lost on scene switch**

Shortcuts:
- **Capture + Copy Slot** — captures the current frame and copies one selected slot's position to the next frame (useful for static slots)
- **↩ Undo** — reverts the last capture (up to 20 history entries)
- `← Prev` / `Next →` — navigate frames without capturing

> **Critical:** Switching to another scene clears all unsaved captures. Always Export before switching.

### Exported JSON Shape

```json
{
  "pet": "fish",
  "animation": "stay",
  "canvas": [450.0, 450.0],
  "frameCount": 14,
  "frameDurationsMs": [500, 200, 100, 200, 100, 200, 300, 200, 400, 200, 300, 200, 200, 300],
  "frames": [
    {
      "index": 0,
      "durationMs": 500,
      "sockets": {
        "head": { "x": 216.0, "y": 69.0, "nx": 0.48, "ny": 0.153333333 },
        "body": { "x": 206.0, "y": 195.0, "nx": 0.457777778, "ny": 0.433333333 },
        "back": { "x": 310.5, "y": 198.0, "nx": 0.69, "ny": 0.44 }
      }
    }
  ],
  "equipmentSettings": { ... },
  "sockets": { ... }
}
```

Use `frames[]` as source of truth. Always use the `nx`/`ny` normalized values.

### Applying Socket JSON To Flutter (`pet_sockets.dart`)

For each pet × animation state:

**Step 1 — Base socket (frame 0)**

Use `frames[0].sockets.<slot>.nx/ny` as the base:

```dart
sockets: {
  PetEquipmentSlot.head: PetSocket(x: 0.48, y: 0.153333333),
  PetEquipmentSlot.body: PetSocket(x: 0.457777778, y: 0.433333333),
  PetEquipmentSlot.back: PetSocket(x: 0.69, y: 0.44),
},
```

**Step 2 — Walk and sleep overrides**

If the walk or sleep animation's frame 0 differs from idle frame 0, add overrides:

```dart
walkOverrides: {
  PetEquipmentSlot.head: PetSocket(x: 0.477777778, y: 0.135555556),
  PetEquipmentSlot.body: PetSocket(x: 0.451111111, y: 0.431111111),
},
sleepOverrides: {
  PetEquipmentSlot.head: PetSocket(x: 0.477777778, y: 0.135555556),
  PetEquipmentSlot.body: PetSocket(x: 0.455555556, y: 0.431111111),
},
```

**Step 3 — Motion tracks (per-frame deltas)**

Compute delta from base: `delta = frame[i].nx - frame[0].nx`

Add a motion track when the slot **visibly moves** across frames. Use `PetMotionTrack.timed` — the frame durations from `PetAnimationFrames` must match the JSON.

```dart
idleMotionTracksBySlot: {
  PetEquipmentSlot.head: PetMotionTrack.timed(
    frameDurationsMs: PetAnimationFrames.fishIdle.frameDurationsMs,
    frames: [
      Offset(0, 0),
      Offset(0, -0.020000),
      Offset(0, -0.053333),
      // ... one entry per frame
    ],
  ),
  PetEquipmentSlot.body: PetMotionTrack.timed(
    frameDurationsMs: PetAnimationFrames.fishIdle.frameDurationsMs,
    frames: [
      Offset(0, 0),
      Offset(0, -0.020000),
      // ... body deltas
    ],
  ),
},
```

Motion track frame count must equal `PetAnimationFrames.<sequence>.frameAssets.length`.

**When to add a body motion track:**

Fish idle body moves ~24 px vertically (ribbon visibly bobs without a track). Cat walk body shifts ~18 px horizontally. Tiger walk body shifts ~16 px on frame 2.

Rule of thumb: if the body's per-frame range exceeds ~10 px on a 450 px canvas (i.e. delta > 0.022), add a motion track.

**Step 4 — sleepHiddenSlots**

If a slot should not render during sleep (e.g. tiger body is hidden by the sleeping pose), add:

```dart
sleepHiddenSlots: {PetEquipmentSlot.body},
```

**Step 5 — Frame durations**

`pet_animation_frames.dart` stores `frameDurationsMs` for each sequence. This array drives motion track timing and must match the JSON. Cross-check:

```text
JSON frameDurationsMs  ←→  PetAnimationFrames.<seq>.frameDurationsMs
```

Godot exports ~1 ms rounding artefacts (201 instead of 200). Round to nearest 100/50/10 ms in Flutter. The critical check is that the **pattern** (which frames are longer/shorter) matches, not the exact millisecond.

---

## Part 2 — Equipment Settings

### What Equipment Settings Are

Equipment settings define how an equipment PNG is positioned relative to a socket:
- **Anchor X/Y** — the point inside the PNG that aligns to the socket (normalized 0–1)
- **Size ratio** — PNG display width as a fraction of pet canvas width

These are **per-equipment**, not per-frame. They do not change frame by frame.

### Three-Layer Lookup (Godot plugin)

The plugin resolves equipment settings in this priority order:

```
1. Per-animation JSON  (`equipmentSettings` field in the _sockets.json)
   ↓ fallback
2. Per-pet global      (`per_pet.<pet>` in equipment_overrides.json)
   ↓ fallback
3. Default global      (`default` in equipment_overrides.json)
```

When you see an anchor value in the Godot preview, it came from whichever layer had data.

### Equipment Authoring Workflow

Use this when a piece of equipment needs a different position on a specific pet or animation state.

**Case A — equipment looks the same on all animations for this pet**

1. Open any animation scene for the pet
2. Equipment section → select PNG from dropdown → **Load Equipment**
3. Adjust `Anchor X/Y` and `Size Ratio` until it looks correct
4. Click **Sync to All Animations (This Pet)** — writes to all other animation JSONs for this pet
5. Click **Export Sockets** — writes to the current animation's JSON too

> Sync updates other animations but not the currently open one. Always export the current scene as well.

**Case B — one animation state has a different position (e.g. tiger sleep pose)**

1. Do Case A for the standard states first
2. Open the special animation scene (e.g. `tiger_sleep.tscn`)
3. Adjust anchor/size specifically for that pose
4. Click **Export Sockets** — saves only this animation's override

**Case C — set a fallback for all pets (equipment looks the same everywhere)**

1. Tune settings for any scene
2. Click **Save as Default (All Pets)** — writes to `equipment_overrides.json` under `default`
3. Still run Export Sockets for any animation where you want an explicit record

**Case D — set a fallback for one pet (same on all animations of that pet)**

1. Tune settings with the correct pet loaded
2. Click **Save for Current Pet** — writes to `equipment_overrides.json` under `per_pet.<pet>`

The authoring dock reloads the current scene's equipment settings when
**Load Sockets** is used and when the editor/plugin starts with a pet scene
already open. The visible anchor/size controls and preview therefore reflect
the resolved default → per-pet → per-animation lookup without reselecting the
equipment.

### Exported equipmentSettings Shape

The `_sockets.json` contains only overrides that differ from the global defaults:

```json
"equipmentSettings": {
  "/Users/fatboy/pet/assets/equipment/hats/straw_hat.png": {
    "slot": "head",
    "anchor": { "x": 0.45, "y": 0.65 },
    "sizeRatio": 0.65
  }
}
```

If this field is empty `{}`, the animation uses the global override file as fallback.

### Applying Equipment Settings To Flutter (`equipment_catalog.dart`)

**Step 1 — Collect data**

For each equipment SKU, read from all `_sockets.json` files plus `equipment_overrides.json`.

Priority to apply in Flutter mirrors the Godot lookup:
- If all animations of a pet share the same value → use `petOverrides`
- If one specific animation state differs → use `petStateOverrides` (idle/walk/sleep)
- If it varies by exact walk vs idle vs sleep → use `petStateOverrides` with all three fields

**Step 2 — Default anchor = ghost / global-default value**

The `EquipmentDefinition.anchor` is the fallback used when no `petOverrides` or `petStateOverrides` matches. Set it to the ghost (or default-global) values from the JSON.

**Step 3 — Add petOverrides for pets with different values**

```dart
petOverrides: {
  'cat': EquipmentFitOverride(
    anchor: EquipmentAnchor(x: 0.5, y: 0.2),
    sizeRatio: EquipmentSize.fromWidthAspect(widthRatio: 0.45, aspectRatio: 1),
  ),
  'fish': EquipmentFitOverride(
    anchor: EquipmentAnchor(x: 0.5, y: 0.05),
    sizeRatio: EquipmentSize.fromWidthAspect(widthRatio: 0.36, aspectRatio: 1),
  ),
},
```

**Step 4 — Add petStateOverrides for pose-specific differences**

Only needed when idle/walk/sleep of the same pet have different anchor values:

```dart
petStateOverrides: {
  'tiger': EquipmentStateFitOverrides(
    sleep: EquipmentFitOverride(
      anchor: EquipmentAnchor(x: 0.5, y: 0.2),
      sizeRatio: EquipmentSize.fromWidthAspect(widthRatio: 0.45, aspectRatio: 1),
    ),
  ),
},
```

`EquipmentStateFitOverrides.resolve()` falls back: `walk ?? idle`, `sleep ?? idle`. Set only the states that actually differ.

**Step 5 — Cross-check: pets with no JSON entry use the global default**

If a pet has no `equipmentSettings` entry in any of its JSONs and no `per_pet` entry in `equipment_overrides.json`, it falls back to `equipment_overrides.json`'s `default`. In Flutter, this means it uses `EquipmentDefinition.anchor` (the default field). Ensure the Flutter default matches the Godot global default, **not** a pet-specific value.

---

## Quick Checklist When Applying A New Export

Use this each time the user re-exports socket JSONs.

### Socket positions

```
□ Read frameDurationsMs from JSON for each animation
□ Cross-check with PetAnimationFrames.<seq>.frameDurationsMs — pattern must match
□ For each slot, record frame[0].nx/ny as the base socket
□ Record walk animation frame[0] — if different from idle, set walkOverrides
□ Record sleep animation frame[0] — if different from idle, set sleepOverrides
□ Calculate per-frame deltas (frame[i] - frame[0]) for each slot
□ Add motion track for any slot where max(|delta|) > 0.022 (≈10px on 450px canvas)
□ Motion track frame count must equal PetAnimationFrames frameAssets count
□ If a slot should be invisible in sleep, add sleepHiddenSlots
```

### Equipment settings

```
□ For each equipment SKU, extract equipmentSettings from all _sockets.json files
□ Also check equipment_overrides.json for default and per_pet values
□ Identify which pets share the same value → petOverrides
□ Identify which pets have pose-specific differences → petStateOverrides
□ Identify which pets have no JSON entry and fall back to global default → use Flutter default anchor
□ Verify: the Flutter catalog default anchor == ghost (or global default) anchor, not another pet's value
```

---

## Common Failure Modes

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| Equipment correct in Godot, wrong position in Flutter | Body socket base position is a placeholder (e.g. `0.50, 0.52`) instead of actual JSON value | Read `frames[0].sockets.body.nx/ny` from JSON, update `pet_sockets.dart` |
| Equipment correct at frame 0 but drifts across frames | Motion track missing or stale | Recompute deltas from latest JSON, update or add the motion track |
| Equipment position correct but timing is off during animation | `pet_animation_frames.dart` frame durations don't match JSON | Copy duration pattern from JSON, update `frameDurationsMs` |
| Cat/Tiger/Fish equipment shifted relative to Ghost | Cat/Tiger/Fish petOverride missing; Flutter falls back to ghost default anchor | Add `petOverrides` entry for that pet using values from JSON or `equipment_overrides.json` global default |
| Equipment correct on idle but wrong on sleep/walk | State-specific socket or anchor not applied | Check if walk/sleep JSON differs from idle; add `walkOverrides` / `sleepOverrides` and/or `petStateOverrides` |
| Ribbon static while fish bobs up/down | Body motion track missing | Add `idleMotionTracksBySlot[body]` with deltas from `fish_stay_sockets.json` body frames |
| Equipment disappears during sleep | `sleepHiddenSlots` incorrectly hides the slot | Check if slot should be visible; remove from `sleepHiddenSlots` if so |
| Body/back socket position wrong for all states | Developer used a placeholder (0.5, 0.5) instead of reading from JSON | Always read all three slots from `frames[0]`, not just head |
| PNG frames missing in app | Asset directory not in `pubspec.yaml` | Add `- assets/equipment/<subfolder>/` and rebuild |
| Godot plugin shows correct anchor but app doesn't | Pet has no per-pet override; global default was not propagated to Flutter default | Set Flutter `EquipmentDefinition.anchor` to match `equipment_overrides.json` default |

---

## Verification After Applying Changes

```sh
dart analyze lib/features/pet/pet_sockets.dart \
             lib/features/pet/pet_animation_frames.dart \
             lib/features/pet/equipment_catalog.dart
```

Use the in-app debug tools:
- **Equipment Preview** (debug drawer → Pet → Equipment Preview): test all pet × equipment combinations with idle/walk/sleep toggle
- **Socket Debug Overlay** (debug drawer → Pet → Show Socket Overlay): visualize live socket positions to confirm tracking

---

## Architecture Reference

```
Godot _sockets.json (authoritative source)
  └─ socket positions (nx/ny per frame)    →  pet_sockets.dart  (PetSocketConfig)
  └─ frame durations                       →  pet_animation_frames.dart (frameDurationsMs)
  └─ equipmentSettings (anchor/sizeRatio)  →  equipment_catalog.dart (EquipmentDefinition)
equipment_overrides.json (global fallback)
  └─ default + per_pet anchor/sizeRatio    →  equipment_catalog.dart (default anchor + petOverrides)

Runtime rendering:
  PetAnimationFrameBuilder → animationProgress (0–1)
    → PetEquipmentOverlay
        → PetSocketConfig.resolve(slot, isWalking, isSleeping)  ← socket base position
        → PetSocketConfig.resolveMotion(slot, progress, ...)    ← per-frame delta
        → EquipmentDefinition.fitOverrideFor(petId, ...)        ← anchor + sizeRatio
        → resolveEquipmentPlacement(petSize, socket, anchor, sizeRatio, motionOffset)
        → Positioned widget
```
