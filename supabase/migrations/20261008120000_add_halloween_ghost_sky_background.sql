begin;

-- Halloween 2026 room background. Art: docs/art_style.md, "Room backgrounds".
-- 5.0.0 (build 31) is already uploaded without the JPG, so gate to the next
-- release that bundles assets/bg/paid/background-paid-03.jpg.
--
-- Price 200: the background rung (docs/shop_pricing.md). Paid version-gated
-- backgrounds stay purchasable with is_active = false (decor-contracts.md).
-- NEW window matches the rest of the Halloween 2026 drop.
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
    200,
    null,
    null,
    jsonb_build_object(
      'category', 'background',
      'background_key', 'ghost_sky',
      'price_jpy', 200,
      'currency', 'JPY',
      'description', 'A soft lilac sky with fluffy clouds and two friendly ghosts peeking in.',
      'visibility_mode', 'version_gated',
      'min_app_version', '5.0.1',
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

commit;
