# Shared decor contracts

Use for shared backgrounds/furniture catalog, inventory, or purchase changes.
Paths and commands below are relative to the repository root. Migration paths
explain the design, not current production state: inspect the latest applied
migration and live definitions under `docs/ai_collaboration_workflow.md` before
changing database behavior.

### Shop-backed decor
- Shop compatibility metadata lives on `public.items.metadata`
- Compatibility metadata:
  - `visibility_mode`
  - `min_app_version`
  - `shop_visibility`
  - `fallback_behavior`
  - `fallback_background_key`
- Compatibility-aware clients fetch:
  - `public.get_visible_shop_items(p_app_version text)`
- Legacy clients still read:
  - `items.is_active = true`
- Purchase authorization for decor is separate from catalog visibility:
  - purchase RPCs must accept the same version-gated rows that Shop can show
  - table RLS policies must also allow inserts for those same rows
- Hidden rollout-only decor uses:
  - `metadata.shop_visibility = 'hidden'`
  - keep it out of the Shop UI and purchase path while still allowing room seeding / compatibility ownership
- Room backpack/catalog hydration must not depend only on the visible Shop catalog:
  - load the room's owned furniture inventory first
  - if an owned `item_id` is missing from `get_visible_shop_items(...)`, fetch
    the item row by id and merge it into the room furniture catalog
  - still apply `ShopItem.isSupportedOnAppVersion(...)` before rendering/placing
- Client app-version gates should prefer the live platform version from
  `PackageInfo.fromPlatform()` and use `lastLaunchedAppVersion` only as a
  fallback. A stale cached launch version can hide newly supported items after
  an app update.

Relevant files:
- `supabase/migrations/20260403121500_add_version_gated_shop_catalog_rpc.sql`
- `supabase/migrations/20260404103000_fix_version_gated_background_purchase.sql`
- `supabase/migrations/20260404104500_fix_room_backgrounds_insert_policy.sql`
- `lib/features/shop/models/shop_item.dart`
- `lib/features/shop/shop_view.dart`
- `lib/features/shop/services/shop_purchase_handler.dart`
- `lib/features/home/home_view.dart`


## Catalog rollout

New decor uses `is_active = false`, `metadata.visibility_mode = 'version_gated'`,
`metadata.min_app_version = '<target version>'`, and appropriate fallback
metadata. Set `metadata.shop_visibility = 'hidden'` for rollout-only free items
that must not appear in Shop. Save migrations in `supabase/migrations/` and
apply through Supabase MCP under root target-verification/approval rules.

Audit all three enforcement layers when changing any one:
- Catalog visibility: `get_visible_shop_items(...)`, `ShopItem`, UI filters.
- Purchase validation: RPC predicates.
- Write authorization: RLS on `room_backgrounds`, `room_item_inventories`, and
  other affected tables.

Version-gated paid backgrounds can be purchasable with `is_active = false`;
purchase RPCs and `room_backgrounds_insert` must support those eligible rows.
Hidden free rollout backgrounds remain excluded from purchase and purchase
insert policies while allowing intended room seeding/compatibility ownership.

Verify old-version exclusion, target-version inclusion, and the live RPC/RLS
predicates when changed. Confirm hidden rollout items stay excluded and eligible
paid version-gated items pass. Read `docs/shop_pricing.md` before setting prices.
