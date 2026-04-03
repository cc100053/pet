begin;

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
    'background_sage_frame',
    'cosmetic',
    'Sage Frame Background',
    0,
    0,
    null,
    '{"price_jpy":0,"currency":"JPY","category":"background","background_key":"sage_frame","description":"A soft paper-textured room with a playful sage border.","visibility_mode":"version_gated","min_app_version":"1.1.0","fallback_behavior":"default_background","fallback_background_key":"default"}'::jsonb,
    false
  ),
  (
    'background_lilac_frame',
    'cosmetic',
    'Lilac Frame Background',
    0,
    0,
    null,
    '{"price_jpy":0,"currency":"JPY","category":"background","background_key":"lilac_frame","description":"A soft paper-textured room with a gentle lilac border.","visibility_mode":"version_gated","min_app_version":"1.1.0","fallback_behavior":"default_background","fallback_background_key":"default"}'::jsonb,
    false
  ),
  (
    'background_bubble_sky',
    'cosmetic',
    'Bubble Sky Background',
    200,
    200,
    null,
    '{"price_jpy":200,"currency":"JPY","category":"background","background_key":"bubble_sky","description":"A bright blue sky filled with clouds and iridescent bubbles.","visibility_mode":"version_gated","min_app_version":"1.1.0","fallback_behavior":"default_background","fallback_background_key":"default"}'::jsonb,
    false
  ),
  (
    'background_starlit_dream',
    'cosmetic',
    'Starlit Dream Background',
    200,
    200,
    null,
    '{"price_jpy":200,"currency":"JPY","category":"background","background_key":"starlit_dream","description":"A dreamy night sky with pastel planets, clouds, and shooting stars.","visibility_mode":"version_gated","min_app_version":"1.1.0","fallback_behavior":"default_background","fallback_background_key":"default"}'::jsonb,
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
