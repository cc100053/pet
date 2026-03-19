begin;

update public.items
set metadata = coalesce(metadata, '{}'::jsonb)
  - 'iap_product_id'
  - 'iap_type'
  - 'coin_amount'
where sku = 'iap_coin_pack_small';

commit;
