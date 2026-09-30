---
name: new-furniture-art
description: Design and produce new furniture art (a seasonal drop, a new shop piece) from idea to a shippable assets/furniture PNG, then wire and roll it out via shared-item-rollout.
---

# New Furniture Art

Art rules, prompts and failure modes live in [the art style guide](../../../docs/art_style.md).
Wiring and rollout rules live in the shared-item-rollout skill and
`docs/shop_pricing.md`. This skill is only the order of operations. Read the
section named in each step; do not restate it.

## Steps

0. **Sync first.** Run `git pull`, then read `git log` and `docs/release_status.md`.
   Other sessions may be working on the same drop, the version bump or its
   migrations (this happened with the Halloween 2026 drop).
1. **Brief.** Settle the item list with the user. Price each piece on the
   ladder in `docs/shop_pricing.md` (every drop needs a 100; at most one 250
   anchor). Agree the NEW-badge window (`new_until`) for the drop.
2. **Composition sketch.** Draw an SVG sketch per item in the canon style (§1).
   Render it with `rsvg-convert` and review it yourself against §4 before showing
   it. Then get the user's sign-off. Keep sources in
   `design/furniture_sketches/<drop>/`. The sketch is never uploaded to Gemini.
3. **Gemini prompt.** Build the style image with
   `scripts/normalize_furniture.py --ref-sheet … --ref-items cactus`. For each
   item, give the user the full §6.2 prompt with `{ITEM}`, `{THING}` and `{PARTS}`
   filled from the approved sketch (§6.3 has worked examples). Name what every
   part attaches to. White parts get a coloured outline (the pale-items rule).
   The user runs Gemini; you cannot.
4. **Review the output** against §4. For failures, draft §6.4 edit prompts,
   one fix per prompt, or flag hand cleanup.
5. **Normalize** (§7). Inspect the result on dark and light backgrounds for
   halos, fringes and lost white parts.
6. **In-room preview.** Composite on a room background at 1×/2×/3× of
   `RoomCanvas.furnitureBaseWidthFraction`, run the §2 squint test, and send
   the preview to the user.
7. **Wire and roll out.** Load `.codex/skills/shared-item-rollout/SKILL.md`,
   read `.codex/skills/shared-item-rollout/references/decor-contracts.md`, and
   complete all six touch points in `docs/shop_pricing.md` ("Where a new item
   gets wired"). Gate `min_app_version` to the first build that really bundles
   the PNGs, and put `new_until` for every item in the migration.
8. **Validate** per `docs/testing.md`: format check, full `flutter analyze`,
   full `flutter test`, plus the rollout skill's `flutter build bundle` asset
   check. Commit and push.
9. **Production.** Only with explicit approval, and each step approved separately:
   - Apply the migration. Follow the `AGENTS.md` migration rule: check for an
     existing apply, then rename the file to the recorded version. Verify live:
     the three decor-contract layers, old-version exclusion and target-version
     inclusion. Log it in `docs/release_status.md`.
   - Deploy `notify_friend` if its name table changed, then verify per
     `docs/ai_collaboration_workflow.md` ("Production Verification").
10. **Feed back.** Add any new failure mode or prompt fix to `docs/art_style.md`
    §4 or §6.5, and any rollout lesson to its canonical doc, in the same change.

## Done means

- PNGs are normalized and committed, and sketches are saved.
- All six touch points are wired.
- Validation is green and the work is pushed.
- Approved production steps are applied, verified and logged.
- Anything unapproved (migration, function deploy, `new_until`) is reported as
  pending.
