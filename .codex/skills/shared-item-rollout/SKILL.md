---
name: shared-item-rollout
description: Add shared backgrounds, furniture, or pets, or change their version gates, purchase eligibility, or fallback behavior.
---

# Shared Item Rollout

Use for shared room state, not local-only cosmetic assets, profile/avatar edits,
or App Store metadata. Reuse existing compatibility helpers rather than adding
another system.

## Compatibility invariants

- New shared items must not be exposed to old app versions by default. Keep
  visibility gating separate from render fallback: a room can use an item that
  another member cannot discover or buy.
- Unsupported backgrounds use the default background; unsupported furniture is
  skipped; unsupported pets use `PetCatalog.defaultPetId`. Apply fallbacks to
  active rooms, room lists/summaries, and other remote-room preview surfaces.
- Reuse the generic room compatibility update prompt for unsupported pets,
  furniture, and backgrounds.
- Do not set new decor globally `is_active = true` without the user's explicit
  acceptance of old-client exposure. Follow root compatibility-approval and
  production-target rules for backend work.

## Conditional contracts

For backgrounds/furniture catalog, inventory, or purchase changes, read
[decor-contracts.md](references/decor-contracts.md). Catalog visibility,
purchase RPC predicates, and table RLS must agree; visible catalog alone is
not sufficient for owned inventory hydration or authorization.

Pets are not shop items. Use `PetCatalog` metadata, `minAppVersion`, and
`visiblePetsForAppVersion(...)` for selection, with default-pet fallback.
Relevant surfaces are `lib/features/pet/pet_catalog.dart`,
`lib/features/pet/pet_selection_page.dart`, `lib/features/home/home_view.dart`,
and `lib/features/home/room_selection_view.dart`. For PNG sequence or socket
work, use the pet-socket skill and
[the sequence workflow](../../../docs/godot-png-sequence-socket-workflow.md).

## Complete the affected rollout

Change only the required asset, catalog, localization, prompt, and notification
surfaces; reuse gates/fallbacks that already work. Add localized item copy in
all supported ARBs for that item type and generate localizations when changed.
Register assets as needed; nested asset folders may need explicit entries.

If item-specific names or avatar assets occur in notification payloads, update
`supabase/functions/notify_friend/index.ts` and, for pet avatar handling,
`android/app/src/main/kotlin/com/example/pet/PetTomoFirebaseMessagingService.kt`
as needed. Apply migrations and deploy required function changes within the
authorized rollout using root compatibility, target/config verification, and
production-verification rules; an asset-edit request alone does not authorize
unrelated external operations.

Follow [the final validation requirements](../../../docs/testing.md). Verify
affected old/target-version behavior and fallback surfaces. When assets change,
run `flutter build bundle` and confirm both `AssetManifest.bin` and copied files
under `build/flutter_assets/assets/` contain the new paths. For backend changes,
verify live enforcement under the decor/compatibility workflow. Completion
for implementation includes relevant regression coverage and, within the
approved rollout scope, applied/committed migrations and deployed payload
changes. For review-only or code-only work, report pending operations without
executing them.
