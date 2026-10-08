---
name: new-room-background
description: Design and produce a new room background (a seasonal drop, a new shop background) from idea to a shippable assets/bg JPG, then wire and roll it out via shared-item-rollout.
---

# New Room Background

Art rules, the Gemini template and the normalize script are in
[the art style guide](../../../docs/art_style.md) §8. Wiring and rollout rules
are in the shared-item-rollout skill and `docs/shop_pricing.md`. This skill
gives only the order of operations; read the section each step names.

## Steps

0. **Sync first.** Run `git pull`, then read `git log` and
   `docs/release_status.md`. The release status decides `min_app_version`: any
   build already uploaded without the JPG does not count.
1. **Brief.** Agree on the scene, sku (`background_<key>`), display name, and
   light or dark ground with the user. Backgrounds take the 200 rung in
   `docs/shop_pricing.md`. A seasonal one shares the drop's `new_until`.
2. **Composition sketch.** Sketch the layout so the empty middle (§8.1) is
   agreed before generating. A Design canvas artboard at 402×874 or an SVG
   works. Never upload the sketch to Gemini.
3. **Gemini prompt.** Fill the §8.3 template from the approved sketch and give
   it to the user with the style image (`background-paid-01.jpg`), 9:16. The
   user runs Gemini; you cannot. Ask for the full-resolution download.
4. **Review** against §8.1: is the middle empty, is the decoration at the
   edges, does it match the medium. Draft one §6.4 edit prompt per failure.
5. **Normalize** (§8.4). Keep the raw source in
   `design/backgrounds/<drop>/<key>_raw.png`. Pick `--band` from the art,
   then look at the output and check the stretched middle shows no visible
   stretch.
6. **In-room preview.** Run `--preview`, do the squint test, and send the
   preview to the user.
7. **Wire and roll out.** Load `.codex/skills/shared-item-rollout/SKILL.md` and
   `.codex/skills/shared-item-rollout/references/decor-contracts.md`. A background has seven touch points:
   - the JPG under `assets/bg/paid/` (the folder is already in `pubspec.yaml`)
   - a key, asset constant and `RoomBackgroundDefinition` in
     `lib/features/home/room_backgrounds.dart`, with `isDark` for dark grounds
   - a migration inserting the `items` row with `category: background`,
     `background_key`, `visibility_mode: version_gated`, `min_app_version`,
     `fallback_behavior: default_background`, `fallback_background_key: default`,
     `new_until` and `is_active = false`; paid version-gated backgrounds stay
     purchasable while inactive. Reference migration:
     `supabase/migrations/20261008120000_add_halloween_ghost_sky_background.sql`.
   - `storeItemNameBackground…` and `storeItemDescBackground…` in all five ARBs,
     then `flutter gen-l10n`
   - the sku → name case in `lib/features/shop/shop_item_localization.dart`
   - the sku → description case in `lib/features/shop/models/shop_item.dart`
   - the sku in all five locales in `supabase/functions/notify_friend/l10n.ts`
     (`test/notify_friend_store_item_names_test.dart` enforces it)
   Add the key to `test/features/home/room_backgrounds_test.dart`.
8. **Validate** per `docs/testing.md`: format check, full `flutter analyze`,
   full `flutter test`, `python3 scripts/normalize_background.py --selftest`,
   and `flutter build bundle` with the JPG checked in both `AssetManifest.bin`
   and `build/flutter_assets/assets/bg/`. Commit and push.
9. **Production.** Only with explicit approval, and approve each step
   separately:
   - Apply the migration following the `AGENTS.md` migration rule. Verify live
     that the target version includes the row and older versions exclude it,
     and that the purchase RPC and `room_backgrounds_insert` accept it. Log it in
     `docs/release_status.md`.
   - Deploy `notify_friend` for the new push name, then verify per
     `docs/ai_collaboration_workflow.md` ("Production Verification").
10. **Hand off to release.** The background appears only when the gated build
    ships. `.codex/skills/release-notes-sync/SKILL.md` covers the release copy.
11. **Feed back.** Add new failure modes or prompt fixes to `docs/art_style.md`
    §8 in the same change.

## Done means

- The JPG is normalized and committed, and the raw source is saved.
- All seven touch points are wired and covered by tests.
- Validation passes and the work is pushed.
- Approved production steps are applied, verified and logged.
- Anything unapproved (migration, function deploy) is reported as pending.
