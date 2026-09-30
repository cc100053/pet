begin;

-- Halloween 2026 drop. Art: docs/art_style.md workflow.
-- 3.3.0 (build 26) is already archived without the PNG, so gate to the next
-- release that bundles the three PNGs.
--
-- Prices follow the ladder in docs/shop_pricing.md: Pumpkin Lantern is the
-- drop's 100 entry item, Candy Cauldron a standard 150, Bat-Wing Armchair the
-- single 250 anchor.
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
  ),
  (
    'furniture_candy_cauldron',
    'cosmetic',
    'Candy Cauldron',
    150,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/candy_cauldron.png',
      'price_jpy', 150,
      'description', 'A cauldron overflowing with treats.',
      'visibility_mode', 'version_gated',
      'min_app_version', '3.3.1',
      'fallback_behavior', 'skip'
    ),
    false
  ),
  (
    'furniture_bat_armchair',
    'cosmetic',
    'Bat-Wing Armchair',
    250,
    null,
    null,
    jsonb_build_object(
      'category', 'furniture',
      'asset_path', 'assets/furniture/bat_armchair.png',
      'price_jpy', 250,
      'description', 'A cozy armchair with little bat wings.',
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
