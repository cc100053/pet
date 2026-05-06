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
values (
  'equip_crown',
  'cosmetic',
  'Crown',
  120,
  null,
  null,
  jsonb_build_object(
    'category', 'equipment',
    'equipment_slot', 'head',
    'asset_path', 'assets/equipment/hats/crown.png',
    'emoji', '👑',
    'price_jpy', 120,
    'description', 'A shiny crown for your pet.',
    'visibility_mode', 'version_gated',
    'min_app_version', '1.4.0'
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
