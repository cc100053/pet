begin;

update public.items
set
  name = 'Pro Monthly Plan',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Monthly Pro plan."', true)
where sku = 'subscription_premium_monthly';

update public.items
set
  name = 'Diamond Pack 300',
  metadata = metadata
    || jsonb_build_object(
      'description', 'One-time 300 diamond pack.',
      'price_jpy', 300,
      'iap_product_id', 'Petdiamonds300',
      'diamond_amount', 300
    )
where sku = 'iap_diamond_pack_small';

update public.items
set
  name = 'Return Letter',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Call back a departed pet."', true)
where sku = 'return_letter';

update public.items
set
  name = 'Default Background',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Original cozy room backdrop."', true)
where sku = 'background_default';

update public.items
set
  name = 'Moonlight Background',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"A calm moonlit room backdrop."', true)
where sku = 'background_test1';

update public.items
set
  name = 'Sofa',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Comfy sofa."', true)
where sku = 'furniture_emoji_sofa';

update public.items
set
  name = 'Plant',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Fresh green corner."', true)
where sku = 'furniture_emoji_plant';

update public.items
set
  name = 'Picture Frame',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Picture frame."', true)
where sku = 'furniture_emoji_frame';

update public.items
set
  name = 'Teddy Bear',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Soft teddy."', true)
where sku = 'furniture_emoji_teddy';

update public.items
set
  name = 'Bricks',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Block accent."', true)
where sku = 'furniture_emoji_brick';

update public.items
set
  name = 'TV',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Tiny TV."', true)
where sku = 'furniture_emoji_tv';

update public.items
set
  name = 'Bath',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Mini bath."', true)
where sku = 'furniture_emoji_bath';

update public.items
set
  name = 'Ribbon',
  metadata = jsonb_set(coalesce(metadata, '{}'::jsonb), '{description}', '"Decor ribbon."', true)
where sku = 'furniture_emoji_ribbon';

commit;
