---
name: new-furniture-art
description: Design and produce new furniture art (a seasonal drop, a new shop piece) from idea to a shippable assets/furniture PNG, then hand off to shared-item-rollout for wiring.
---

# New Furniture Art

Rules, prompts and failure modes live in [the art style guide](../../../docs/art_style.md).
This skill is only the order of operations. Do not restate the guide; read the
section named in each step.

## Steps

1. **Brief.** Settle the item list with the user. Price each piece on the
   ladder in `docs/shop_pricing.md` (every drop needs a 100; at most one 250
   anchor).
2. **Composition sketch.** Draw an SVG sketch per item in the canon style (§1).
   Render it with `rsvg-convert`, review it yourself against §4 before showing
   it, then get the user's sign-off. Keep sources in
   `design/furniture_sketches/<drop>/`.
3. **Gemini prompt.** Build the style image with
   `scripts/normalize_furniture.py --ref-sheet … --ref-items cactus`. Fill the
   §6.2 template, turning the approved sketch into the `{ITEM}` bullets and naming
   what every part attaches to. Pale or white items get the dark-grey background
   line. The user runs Gemini; you cannot.
4. **Review the output.** When the user returns an image, check it against §4.
   Draft §6.4 edit prompts for anything that fails, one fix per prompt.
5. **Normalize.** Run `python3 scripts/normalize_furniture.py <raw> assets/furniture/<name>.png`,
   adding `--holes` for dark-grey inputs. Inspect the result on dark and light
   backgrounds for halos and fringes.
6. **In-room preview.** Composite it on a room background at 1×, 2× and 3× of
   `RoomCanvas.furnitureBaseWidthFraction` and run the §2 squint test. Send the
   preview to the user.
7. **Wire it up.** Load `.codex/skills/shared-item-rollout/SKILL.md` and follow
   it together with "Where a new item gets wired" in `docs/shop_pricing.md`.
   - Gate `min_app_version` to the first build that actually bundles the PNG.
     Check `docs/release_status.md`: an already-uploaded build without the asset
     does not count.
   - Write the migration, but apply it only after the user explicitly approves
     the production change. Then log it in `docs/release_status.md`.
8. **Feed back.** If a new failure mode or prompt fix came up, add it to
   `docs/art_style.md` §4 or §6.5 in the same change.

## Done means

PNG normalized and committed, sketch sources saved, rollout skill complete
(including its `flutter build bundle` asset check), tests green, pushed, and any
unapplied migration reported as pending.
