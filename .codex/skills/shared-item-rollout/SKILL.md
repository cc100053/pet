---
name: shared-item-rollout
description: Use when adding or updating shared room items such as backgrounds, furniture, or pets, especially when old and new app versions may coexist. Covers the PicPet mixed-version rollout workflow: version-gated catalog visibility, old-client fallback rendering, update prompting, Supabase migration rules, notification sync, and verification.
---

# Shared Item Rollout

Use this workflow for any shared room item that can appear across members on mixed app versions:
- backgrounds
- furniture
- pets

Do not treat these as simple asset drops. In this repo, shared items must ship with a compatibility plan.

## Core Rule

Never expose a new shared item to old app versions by default.

Every rollout has 2 separate layers:
- visibility gating
  controls which app versions can discover or buy the item
- render fallback
  controls what an older client shows when a room is already using the new item

If you only do one layer, mixed-version rooms will drift.

## Repo Contracts

### Shop-backed decor
- Shop compatibility metadata lives on `public.items.metadata`
- Current SQL gate:
  - `visibility_mode`
  - `min_app_version`
  - `fallback_behavior`
  - `fallback_background_key`
- Compatibility-aware clients fetch:
  - `public.get_visible_shop_items(p_app_version text)`
- Legacy clients still read:
  - `items.is_active = true`

Relevant files:
- `supabase/migrations/20260403121500_add_version_gated_shop_catalog_rpc.sql`
- `lib/features/shop/models/shop_item.dart`
- `lib/features/shop/shop_view.dart`
- `lib/features/home/home_view.dart`

### Pets
- Pets are not shop items in this repo.
- Pet compatibility is app-side through `PetCatalog` metadata plus old-client fallback to the default pet.

Relevant files:
- `lib/features/pet/pet_catalog.dart`
- `lib/features/pet/pet_selection_page.dart`
- `lib/features/home/home_view.dart`
- `lib/features/home/room_selection_view.dart`
- `android/app/src/main/kotlin/com/example/pet/PetTomoFirebaseMessagingService.kt`
- `supabase/functions/notify_friend/index.ts`

## Rollout Workflow

### 1. Classify the shared item
- `background` or `furniture`
  use Shop visibility gate + Home render fallback
- `pet`
  use `PetCatalog` min-version gate + Home/Room Selection fallback

### 2. Add assets and localization
- Register new assets in Flutter and `pubspec.yaml` when needed.
- Add localized names/descriptions/taglines in every supported ARB touched by that item type.
- Run `flutter gen-l10n`.

### 3. Add visibility gating

For backgrounds/furniture:
- Insert or update `items` rows with:
  - `is_active = false`
  - `metadata.visibility_mode = 'version_gated'`
  - `metadata.min_app_version = '<target version>'`
  - fallback metadata appropriate to the item
- Save the migration under `supabase/migrations/`
- Apply it through Supabase MCP, not as dashboard-only SQL

For pets:
- Add the new pet to `PetCatalog`
- Set `minAppVersion`
- Make selection surfaces use `visiblePetsForAppVersion(...)`

### 4. Add render fallback

For backgrounds:
- Unsupported active background must fall back to the default background

For furniture:
- Unsupported placed furniture must be skipped entirely

For pets:
- Unsupported shared pet type must fall back to `PetCatalog.defaultPetId`

Fallback must be applied on:
- active room rendering
- room list / room summary rendering
- any other shared preview surface that can display remote room state

### 5. Reuse the update prompt
- If a room is using a newer shared item than the client supports, reuse the room compatibility update prompt instead of inventing a new flow.
- Keep the prompt generic enough to cover pet, furniture, and background conflicts.

### 6. Sync notifications if payloads depend on the item
- If notification payloads include item-specific names or avatar assets, update them too.

Current examples:
- shop purchase item-name localization:
  - `supabase/functions/notify_friend/index.ts`
- pet avatar asset/type handling:
  - `supabase/functions/notify_friend/index.ts`
  - `android/app/src/main/kotlin/com/example/pet/PetTomoFirebaseMessagingService.kt`

If an Edge Function changes, deploy it after the code change.

## Guardrails

- Do not globally flip new shared decor to `is_active = true` unless the user explicitly accepts old-client exposure.
- Do not assume Shop gating is enough for shared room state.
- Do not invent a second compatibility system when the existing prompt, RPC, metadata, or fallback helpers already cover the use case.
- Do not update only Flutter without updating Supabase or notification payloads when the item type needs them.

## Expected Deliverables

When this skill is used, the final change should usually include:
- assets wired
- localization updated
- compatibility gate added
- fallback rendering added
- prompt path preserved or expanded
- Supabase migration committed and applied if decor catalog changed
- notification payload changes deployed if touched
- tests added or updated

## Verification

Always run:
- `flutter gen-l10n` if ARB files changed
- `flutter analyze`
- `flutter test`

For decor catalog changes, also sanity-check visibility behavior against version boundaries, for example:
- old version does not see the new item
- target version does see the new item

## When Not To Use

Do not use this skill for:
- purely local cosmetic assets with no shared room state
- non-shared profile/avatar changes
- unrelated App Store metadata updates
