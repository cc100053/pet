begin;

update public.items
set
  price_coins = 260,
  metadata = jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{price_jpy}',
    '260'::jsonb,
    true
  )
where sku = 'equip_crown'
  and metadata->>'category' = 'equipment';

update public.items
set
  price_coins = 170,
  metadata = jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{price_jpy}',
    '170'::jsonb,
    true
  )
where sku = 'equip_ribbon'
  and metadata->>'category' = 'equipment';

update public.items
set
  price_coins = 240,
  metadata = jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{price_jpy}',
    '240'::jsonb,
    true
  )
where sku = 'equip_sunglasses'
  and metadata->>'category' = 'equipment';

commit;
