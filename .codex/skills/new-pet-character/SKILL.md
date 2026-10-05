---
name: new-pet-character
description: Create a new pet character, from concept and master art through idle/walk/sleep animation, transparent export and version-gated app wiring. Also use when generating, reviewing or fixing a pet animation sheet.
---

# New Pet Character

The order of operations for a shippable pet at the quality bar of the shipped
cat, tiger and chicken. Two references carry the detail:

- [Animation and prompts](references/animation-prompts.md): what each state
  must show, how to write the image prompt, the pose guide and targeted fixes.
- [Measure and export](references/measure-and-export.md): the in-app facts,
  the measurements behind every review, and the turtle scripts to copy.

The turtle ("Little Pond Buddy", `design/pet_sketches/turtle_pond_buddy/`) is
the worked example. Its trial READMEs record every rejected attempt and why.

Work in `design/pet_sketches/<pet>/`. Preserve every received sheet unchanged
as `source_sheet.*`. Give each trial its own folder and a README stating what
was received, the measurements and the review, then update the pet's README and
`memory-bank/progress.md` in the same commit.

## Steps

1. **Study the shipped pets first.** Inspect every frame and timing of the
   state you are about to make (`assets/pet_sequences/<pet>/<state>/`,
   `PetAnimationFrames`). Also read how the app plays that state. For example,
   pets travel sideways while walking, and moving left plays the art
   unflipped. Done when the pet README lists frame counts, timings, motion
   features and the in-app playback facts this state must satisfy.

2. **Lock the master.** Generate concept candidates with the existing pets
   attached as style references, and let the owner pick one. Record the
   character brief: palette, silhouette, signature behaviour and the planned
   states. Done when `selected_master.png` is saved and the owner has selected
   it. From here on the master is the identity reference attached to every
   generation, and its measured skin, shell and belly colours (or the
   equivalent regions) are the colour targets.

3. **Make each state: idle, then walk, then sleep.** For each one, pick the
   production route from the route table in
   [animation-prompts](references/animation-prompts.md#production-routes).
   Write the prompt and pose guide following that reference. The owner
   generates the sheet; split, align, colour-measure and preview it with the
   [split script](references/measure-and-export.md#scripts). Review the
   aligned loop against that state's checklist. Done when the owner accepts
   the continuous loop at its real timing. A correct contact sheet alone is
   not acceptance.

4. **Fix narrowly.** When a sheet is mostly right, send a targeted fix in the
   same chat: name the frames to keep, the exact frames to redraw, and end with
   a check that list (see
   [targeted fixes](references/animation-prompts.md#targeted-fixes)). Start a new
   chat only for a new prompt or pose guide. Every edit darkens the colours a
   little, so colour-match after each one.

5. **Export.** Colour-match, remove the background, scale every state to one
   character size (matched head width) and place the feet on the shared
   baseline. Use the [export rules](references/measure-and-export.md#export).
   Done when the stay, walk and sleep frames measure the same head width
   (within about 2 px), share the baseline, show no fringe on dark, and the
   light and dark previews have been reviewed.

6. **Wire the app.** Load the shared-item-rollout skill. Ask the owner for the
   `minAppVersion` gate (it is the owner's decision). Install the frames and
   fallback GIFs, then add the `PetCatalog` entry, the `PetAnimationFrames`
   sequences, localized name and tagline in every ARB, the `pubspec.yaml`
   folders, the equipment preview page entry and the gate/timing tests. Run
   `docs/testing.md` and `flutter build bundle`, then record the gate in
   `docs/release_status.md`. Done when the tests pass, the bundle contains
   every frame and GIF, and the gate is recorded.

7. **Calibrate sockets before shipping.** Without a `PetSocketConfig`, equipped
   items silently disappear on the pet. Use the pet-socket-calibration skill.
   Animated heads (such as the sleep nod) need per-frame tracks; the
   procedural parameters give a starting track. If the face is drawn at an angle,
   measure the eye tilt and give face items a per-state `rotationDegrees` (see
   the turtle's [fit_glasses.py](../../../design/pet_sketches/turtle_pond_buddy/sockets/fit_glasses.py)). Done when every state and slot
   reaches review level 2 and the tracks are synced.

8. **Hand over the human checks.** Mark these `[USER ACTION REQUIRED]`: room-size
   review on a device (needs a build at or above the gate), the push avatar
   (`notify_friend` falls back to the ghost until an avatar is published and
   the function deployed under its own approval), and release timing.
