begin;

-- Four illustrated furniture pieces bundled with the 2.3.5 app assets.
-- Version gated so older builds (which lack the PNGs) never see them.
--
-- Prices follow the coin ladder in docs/shop_pricing.md (100/150/200/250):
-- one entry item, one anchor, nothing above ~10 days of median earning.
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
    'furniture_balloon',
    'cosmetic',
    'Balloons',
    100,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/balloon.png',
      'price_jpy', 100,
      'description', 'A ribbon-tied balloon bunch.',
      'visibility_mode', 'version_gated',
      'min_app_version', '2.3.5',
      'fallback_behavior', 'skip'
    ),
    false
  ),
  (
    'furniture_cactus',
    'cosmetic',
    'Cactus',
    150,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/cactus.png',
      'price_jpy', 150,
      'description', 'A potted cactus in bloom.',
      'visibility_mode', 'version_gated',
      'min_app_version', '2.3.5',
      'fallback_behavior', 'skip'
    ),
    false
  ),
  (
    'furniture_carpet',
    'cosmetic',
    'Rug',
    200,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/carpet.png',
      'price_jpy', 200,
      'description', 'A flower-patterned oval rug.',
      'visibility_mode', 'version_gated',
      'min_app_version', '2.3.5',
      'fallback_behavior', 'skip'
    ),
    false
  ),
  (
    'furniture_vinyl',
    'cosmetic',
    'Vinyl Records',
    250,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/vinyl.png',
      'price_jpy', 250,
      'description', 'Records for a music corner.',
      'visibility_mode', 'version_gated',
      'min_app_version', '2.3.5',
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
