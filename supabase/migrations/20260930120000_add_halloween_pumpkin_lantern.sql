begin;

-- Halloween 2026 drop, first piece. Art: docs/art_style.md workflow.
-- 3.3.0 (build 26) is already archived without the PNG, so gate to the next
-- release that bundles assets/furniture/pumpkin_lantern.png.
--
-- Price 100: the drop's entry item (docs/shop_pricing.md, "every drop needs a 100").
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
    'furniture_pumpkin_lantern',
    'cosmetic',
    'Pumpkin Lantern',
    100,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/pumpkin_lantern.png',
      'price_jpy', 100,
      'description', 'A smiling jack-o''-lantern for spooky season.',
      'visibility_mode', 'version_gated',
      'min_app_version', '3.3.1',
      'fallback_behavior', 'skip'
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
