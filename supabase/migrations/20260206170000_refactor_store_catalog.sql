begin;

-- Subscription: monthly plan, localized via App Store/Play with JPY base fallback.
insert into public.items (sku, type, name, price_coins, price_diamonds, price_usd, metadata, is_active)
values (
  'subscription_premium_monthly',
  'subscription',
  'Pro Monthly Plan',
  null,
  null,
  null,
  jsonb_build_object(
    'price_jpy', 300,
    'currency', 'JPY',
    'category', 'subscription',
    'description', 'Monthly Pro plan.',
    'iap_product_id', 'Petmonthly',
    'iap_type', 'subscription',
    'rc_entitlement_id', 'Petmonthly'
  ),
  true
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

-- Diamond IAP: 300 JPY -> 300 diamonds.
insert into public.items (sku, type, name, price_coins, price_diamonds, price_usd, metadata, is_active)
values (
  'iap_diamond_pack_small',
  'consumable',
  'Diamond Pack 300',
  null,
  null,
  null,
  jsonb_build_object(
    'price_jpy', 300,
    'currency', 'JPY',
    'category', 'diamond_pack',
    'description', 'One-time 300 diamond pack.',
    'iap_product_id', 'Petdiamonds300',
    'iap_type', 'consumable',
    'diamond_amount', 300,
    'iap_currency', 'diamond'
  ),
  true
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

-- Utility: Return Letter (diamond spend, consumed immediately by client flow).
insert into public.items (sku, type, name, price_coins, price_diamonds, price_usd, metadata, is_active)
values (
  'return_letter',
  'consumable',
  'Return Letter',
  null,
  150,
  null,
  jsonb_build_object(
    'price_jpy', 150,
    'currency', 'DIAMOND',
    'category', 'utility',
    'description', 'Call back a departed pet.'
  ),
  true
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

-- Backgrounds: 200 candy for non-default entries. Default stays free but owned by default per room.
update public.items
set
  price_coins = case when sku = 'background_default' then 0 else 200 end,
  price_diamonds = null,
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{category}', '"background"'::jsonb, true),
  is_active = true
where sku in ('background_default', 'background_test', 'background_test1');

-- Furniture catalog (emoji placeholders): 8 items, 100~250 candy.
insert into public.items (sku, type, name, price_coins, price_diamonds, price_usd, metadata, is_active)
values
  ('furniture_emoji_sofa', 'cosmetic', 'Emoji Sofa', 250, null, null, '{"category":"furniture","emoji":"🛋️","price_jpy":250,"description":"Comfy sofa."}'::jsonb, true),
  ('furniture_emoji_plant', 'cosmetic', 'Emoji Plant', 120, null, null, '{"category":"furniture","emoji":"🪴","price_jpy":120,"description":"Fresh green corner."}'::jsonb, true),
  ('furniture_emoji_frame', 'cosmetic', 'Emoji Frame', 140, null, null, '{"category":"furniture","emoji":"🖼️","price_jpy":140,"description":"Picture frame."}'::jsonb, true),
  ('furniture_emoji_teddy', 'cosmetic', 'Emoji Teddy', 160, null, null, '{"category":"furniture","emoji":"🧸","price_jpy":160,"description":"Soft teddy."}'::jsonb, true),
  ('furniture_emoji_brick', 'cosmetic', 'Emoji Brick', 100, null, null, '{"category":"furniture","emoji":"🧱","price_jpy":100,"description":"Block accent."}'::jsonb, true),
  ('furniture_emoji_tv', 'cosmetic', 'Emoji TV', 220, null, null, '{"category":"furniture","emoji":"📺","price_jpy":220,"description":"Tiny TV."}'::jsonb, true),
  ('furniture_emoji_bath', 'cosmetic', 'Emoji Bath', 230, null, null, '{"category":"furniture","emoji":"🛁","price_jpy":230,"description":"Mini bath."}'::jsonb, true),
  ('furniture_emoji_ribbon', 'cosmetic', 'Emoji Ribbon', 110, null, null, '{"category":"furniture","emoji":"🎀","price_jpy":110,"description":"Decor ribbon."}'::jsonb, true)
on conflict (sku) do update
set
  type = excluded.type,
  name = excluded.name,
  price_coins = excluded.price_coins,
  price_diamonds = excluded.price_diamonds,
  price_usd = excluded.price_usd,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

-- Disable legacy furniture SKUs to avoid duplicate rows in the store.
update public.items
set is_active = false
where sku in (
  'cosmetic_furniture_cozy_chair',
  'cosmetic_furniture_tiny_plant',
  'cosmetic_furniture_soft_lamp'
);

-- Ensure default background ownership for every room.
with default_bg as (
  select id
  from public.items
  where sku = 'background_default'
  limit 1
)
insert into public.room_backgrounds (room_id, item_id, acquired_by)
select r.id, d.id, r.created_by
from public.rooms r
cross join default_bg d
left join public.room_backgrounds rb
  on rb.room_id = r.id
 and rb.item_id = d.id
where rb.room_id is null;

commit;
