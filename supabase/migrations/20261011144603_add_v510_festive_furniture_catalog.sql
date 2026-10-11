begin;

-- Build 31 (5.0.0) was uploaded without these PNGs. Only 5.1.0+ bundles them.
-- Prices follow docs/shop_pricing.md; NEW window approved through November 1.
insert into public.items (
  sku, type, name, price_coins, price_diamonds, price_usd, metadata, is_active
)
select
  sku, 'cosmetic', name, price, null, null,
  jsonb_build_object(
    'category', 'furniture',
    'asset_path', asset_path,
    'price_jpy', price,
    'description', description,
    'visibility_mode', 'version_gated',
    'min_app_version', '5.1.0',
    'fallback_behavior', 'skip',
    'new_until', '2026-11-01T00:00:00Z'
  ),
  false
from (values
  ('furniture_candle', 'Candle', 100, 'assets/furniture/candle.png', 'A ribbon-tied candle for a cozy glow.'),
  ('furniture_candy_cane', 'Candy Cane', 150, 'assets/furniture/candy_cane.png', 'A cheerful striped candy cane.'),
  ('furniture_sunflower', 'Sunflowers', 150, 'assets/furniture/sunflower.png', 'A pot of sunflowers to brighten the room.'),
  ('furniture_gift', 'Gift Box', 200, 'assets/furniture/gift.png', 'A festive gift wrapped with a big bow.'),
  ('furniture_christmas_tree', 'Christmas Tree', 250, 'assets/furniture/christmas_tree.png', 'A snowy tree dressed for Christmas.')
) as furniture(sku, name, price, asset_path, description)
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
