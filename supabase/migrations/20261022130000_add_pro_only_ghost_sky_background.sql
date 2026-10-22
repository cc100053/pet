begin;

-- Halloween 2026 room background, included with Pro instead of sold for coins.
-- Art: docs/art_style.md, "Room backgrounds". The grant_pro_backgrounds Edge
-- Function verifies the RevenueCat entitlement and inserts it into each of the
-- subscriber's rooms; both prices stay null so the coin/diamond purchase RPCs
-- reject it (item_not_for_coins / item_not_for_diamonds).
--
-- 5.0.1 (build 32) was uploaded with the JPG but without the Pro-only shop UI,
-- so gate to 6.0.0, the first release that labels it "Pro members only".
insert into public.items (
  sku,
  type,
  name,
  price_coins,
  price_diamonds,
  price_usd,
  metadata,
  is_active
)
values
  (
    'background_ghost_sky',
    'cosmetic',
    'Ghost Sky Background',
    null,
    null,
    null,
    jsonb_build_object(
      'category', 'background',
      'background_key', 'ghost_sky',
      'pro_only', true,
      'description', 'A soft lilac sky with fluffy clouds and two friendly ghosts peeking in.',
      'visibility_mode', 'version_gated',
      'min_app_version', '6.0.0',
      'fallback_behavior', 'default_background',
      'fallback_background_key', 'default',
      'new_until', '2026-11-01T00:00:00Z'
    ),
    false
  )
on conflict (sku) do update
set
  type = excluded.type,
  name = excluded.name,
  price_coins = excluded.price_coins,
  price_diamonds = excluded.price_diamonds,
  price_usd = excluded.price_usd,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

-- Direct inserts stay allowed for purchasable backgrounds (unchanged), but a
-- Pro-only background can only arrive through the service-role grant.
drop policy if exists room_backgrounds_insert on public.room_backgrounds;
create policy room_backgrounds_insert
on public.room_backgrounds
for insert
to authenticated
with check (
  public.is_room_member(room_id)
  and acquired_by = (select auth.uid())
  and exists (
    select 1
    from public.items
    where items.id = room_backgrounds.item_id
      and (items.metadata ->> 'category') = 'background'
      and coalesce(items.metadata ->> 'shop_visibility', '') <> 'hidden'
      and coalesce(items.metadata ->> 'pro_only', 'false') <> 'true'
      and (
        coalesce(items.is_active, false) = true
        or coalesce(items.metadata ->> 'visibility_mode', 'public') = 'version_gated'
      )
  )
);

commit;
