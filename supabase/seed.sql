begin;

insert into label_mappings (label_en, canonical_tag, locale, label_local, synonyms, priority) values
  -- beverage.coffee
  ('Coffee', 'beverage.coffee', 'zh-TW', '咖啡', array['咖啡','杯子','馬克杯'], 0),
  ('Espresso', 'beverage.coffee', 'zh-TW', '濃縮咖啡', array['咖啡','杯子','馬克杯'], 0),
  ('Cappuccino', 'beverage.coffee', 'zh-TW', '卡布奇諾', array['咖啡','杯子','馬克杯'], 0),
  ('Latte', 'beverage.coffee', 'zh-TW', '拿鐵', array['咖啡','杯子','馬克杯'], 0),
  ('Cup', 'beverage.coffee', 'zh-TW', '杯子', array['咖啡','杯子','馬克杯'], -1),
  ('Coffee', 'beverage.coffee', 'ja-JP', 'コーヒー', array['コーヒー','カップ'], 0),
  ('Espresso', 'beverage.coffee', 'ja-JP', 'エスプレッソ', array['コーヒー','カップ'], 0),
  ('Cappuccino', 'beverage.coffee', 'ja-JP', 'カプチーノ', array['コーヒー','カップ'], 0),
  ('Latte', 'beverage.coffee', 'ja-JP', 'ラテ', array['コーヒー','カップ'], 0),
  ('Cup', 'beverage.coffee', 'ja-JP', 'カップ', array['コーヒー','カップ'], -1),

  -- beverage.tea
  ('Tea', 'beverage.tea', 'zh-TW', '茶', array['茶','杯子'], 0),
  ('Teapot', 'beverage.tea', 'zh-TW', '茶壺', array['茶','杯子'], 0),
  ('Cup', 'beverage.tea', 'zh-TW', '杯子', array['茶','杯子'], -1),
  ('Tea', 'beverage.tea', 'ja-JP', 'お茶', array['お茶','カップ'], 0),
  ('Teapot', 'beverage.tea', 'ja-JP', 'ティーポット', array['お茶','カップ'], 0),
  ('Cup', 'beverage.tea', 'ja-JP', 'カップ', array['お茶','カップ'], -1),

  -- beverage.juice
  ('Juice', 'beverage.juice', 'zh-TW', '果汁', array['果汁','飲料','飲品'], 0),
  ('Drink', 'beverage.juice', 'zh-TW', '飲料', array['果汁','飲料','飲品'], -1),
  ('Beverage', 'beverage.juice', 'zh-TW', '飲品', array['果汁','飲料','飲品'], -1),
  ('Juice', 'beverage.juice', 'ja-JP', 'ジュース', array['ジュース','飲み物'], 0),
  ('Drink', 'beverage.juice', 'ja-JP', '飲み物', array['ジュース','飲み物'], -1),
  ('Beverage', 'beverage.juice', 'ja-JP', '飲み物', array['ジュース','飲み物'], -1),

  -- dessert.ice_cream
  ('Ice cream', 'dessert.ice_cream', 'zh-TW', '冰淇淋', array['冰淇淋','霜淇淋'], 0),
  ('Frozen dessert', 'dessert.ice_cream', 'zh-TW', '冰品', array['冰淇淋','霜淇淋'], 0),
  ('Ice cream', 'dessert.ice_cream', 'ja-JP', 'アイスクリーム', array['アイスクリーム'], 0),
  ('Frozen dessert', 'dessert.ice_cream', 'ja-JP', '冷凍デザート', array['アイスクリーム'], 0),

  -- dessert.cake
  ('Cake', 'dessert.cake', 'zh-TW', '蛋糕', array['蛋糕','派','杯子蛋糕'], 0),
  ('Cupcake', 'dessert.cake', 'zh-TW', '杯子蛋糕', array['蛋糕','派','杯子蛋糕'], 0),
  ('Pie', 'dessert.cake', 'zh-TW', '派', array['蛋糕','派','杯子蛋糕'], 0),
  ('Cake', 'dessert.cake', 'ja-JP', 'ケーキ', array['ケーキ','パイ','カップケーキ'], 0),
  ('Cupcake', 'dessert.cake', 'ja-JP', 'カップケーキ', array['ケーキ','パイ','カップケーキ'], 0),
  ('Pie', 'dessert.cake', 'ja-JP', 'パイ', array['ケーキ','パイ','カップケーキ'], 0),

  -- dessert.cookie
  ('Cookie', 'dessert.cookie', 'zh-TW', '餅乾', array['餅乾','巧克力'], 0),
  ('Biscuit', 'dessert.cookie', 'zh-TW', '餅乾', array['餅乾','巧克力'], 0),
  ('Chocolate', 'dessert.cookie', 'zh-TW', '巧克力', array['餅乾','巧克力'], -1),
  ('Cookie', 'dessert.cookie', 'ja-JP', 'クッキー', array['クッキー','チョコ','ビスケット'], 0),
  ('Biscuit', 'dessert.cookie', 'ja-JP', 'ビスケット', array['クッキー','チョコ','ビスケット'], 0),
  ('Chocolate', 'dessert.cookie', 'ja-JP', 'チョコ', array['クッキー','チョコ','ビスケット'], -1),

  -- fruit.any
  ('Fruit', 'fruit.any', 'zh-TW', '水果', array['水果','蘋果','香蕉','莓果','草莓','柳橙'], 0),
  ('Apple', 'fruit.any', 'zh-TW', '蘋果', array['水果','蘋果','香蕉','莓果','草莓','柳橙'], 0),
  ('Banana', 'fruit.any', 'zh-TW', '香蕉', array['水果','蘋果','香蕉','莓果','草莓','柳橙'], 0),
  ('Berry', 'fruit.any', 'zh-TW', '莓果', array['水果','蘋果','香蕉','莓果','草莓','柳橙'], 0),
  ('Strawberry', 'fruit.any', 'zh-TW', '草莓', array['水果','蘋果','香蕉','莓果','草莓','柳橙'], 0),
  ('Orange', 'fruit.any', 'zh-TW', '柳橙', array['水果','蘋果','香蕉','莓果','草莓','柳橙'], 0),
  ('Fruit', 'fruit.any', 'ja-JP', 'フルーツ', array['フルーツ','りんご','バナナ','ベリー','いちご','オレンジ'], 0),
  ('Apple', 'fruit.any', 'ja-JP', 'りんご', array['フルーツ','りんご','バナナ','ベリー','いちご','オレンジ'], 0),
  ('Banana', 'fruit.any', 'ja-JP', 'バナナ', array['フルーツ','りんご','バナナ','ベリー','いちご','オレンジ'], 0),
  ('Berry', 'fruit.any', 'ja-JP', 'ベリー', array['フルーツ','りんご','バナナ','ベリー','いちご','オレンジ'], 0),
  ('Strawberry', 'fruit.any', 'ja-JP', 'いちご', array['フルーツ','りんご','バナナ','ベリー','いちご','オレンジ'], 0),
  ('Orange', 'fruit.any', 'ja-JP', 'オレンジ', array['フルーツ','りんご','バナナ','ベリー','いちご','オレンジ'], 0),

  -- meal.sandwich
  ('Sandwich', 'meal.sandwich', 'zh-TW', '三明治', array['三明治','漢堡','麵包'], 0),
  ('Hamburger', 'meal.sandwich', 'zh-TW', '漢堡', array['三明治','漢堡','麵包'], 0),
  ('Bread', 'meal.sandwich', 'zh-TW', '麵包', array['三明治','漢堡','麵包'], 0),
  ('Sandwich', 'meal.sandwich', 'ja-JP', 'サンドイッチ', array['サンドイッチ','ハンバーガー','パン'], 0),
  ('Hamburger', 'meal.sandwich', 'ja-JP', 'ハンバーガー', array['サンドイッチ','ハンバーガー','パン'], 0),
  ('Bread', 'meal.sandwich', 'ja-JP', 'パン', array['サンドイッチ','ハンバーガー','パン'], 0),

  -- meal.rice
  ('Rice', 'meal.rice', 'zh-TW', '米飯', array['米飯','壽司','便當'], 0),
  ('Sushi', 'meal.rice', 'zh-TW', '壽司', array['米飯','壽司','便當'], 0),
  ('Bento', 'meal.rice', 'zh-TW', '便當', array['米飯','壽司','便當'], 0),
  ('Rice', 'meal.rice', 'ja-JP', 'ごはん', array['ごはん','寿司','弁当'], 0),
  ('Sushi', 'meal.rice', 'ja-JP', '寿司', array['ごはん','寿司','弁当'], 0),
  ('Bento', 'meal.rice', 'ja-JP', '弁当', array['ごはん','寿司','弁当'], 0),

  -- meal.noodles
  ('Noodle', 'meal.noodles', 'zh-TW', '麵', array['麵','拉麵','義大利麵'], 0),
  ('Ramen', 'meal.noodles', 'zh-TW', '拉麵', array['麵','拉麵','義大利麵'], 0),
  ('Spaghetti', 'meal.noodles', 'zh-TW', '義大利麵', array['麵','拉麵','義大利麵'], 0),
  ('Noodle', 'meal.noodles', 'ja-JP', '麺', array['麺','ラーメン','スパゲッティ'], 0),
  ('Ramen', 'meal.noodles', 'ja-JP', 'ラーメン', array['麺','ラーメン','スパゲッティ'], 0),
  ('Spaghetti', 'meal.noodles', 'ja-JP', 'スパゲッティ', array['麺','ラーメン','スパゲッティ'], 0),

  -- flower
  ('Flower', 'flower', 'zh-TW', '花', array['花','花朵','植物'], 0),
  ('Plant', 'flower', 'zh-TW', '植物', array['花','花朵','植物'], -1),
  ('Flower', 'flower', 'ja-JP', '花', array['花','植物'], 0),
  ('Plant', 'flower', 'ja-JP', '植物', array['花','植物'], -1)

on conflict do nothing;

insert into quests (code, name, name_zh, name_ja, canonical_tags, reward_coins, is_active) values
  ('Q001', 'Coffee', '咖啡', 'コーヒー', array['beverage.coffee'], 20, true),
  ('Q002', 'Tea', '茶', 'お茶', array['beverage.tea'], 20, true),
  ('Q003', 'Ice Cream', '冰淇淋', 'アイスクリーム', array['dessert.ice_cream'], 20, true),
  ('Q004', 'Fruit', '水果', 'フルーツ', array['fruit.any'], 20, true),
  ('Q005', 'Dessert', '甜點', 'デザート', array['dessert.cake','dessert.cookie'], 20, true),
  ('Q006', 'Meal', '正餐', '食事', array['meal.sandwich','meal.rice','meal.noodles'], 20, true),
  ('Q007', 'Flower', '花', '花', array['flower'], 20, true)

on conflict (code) do nothing;

insert into items (sku, type, name, price_coins, price_usd, metadata, is_active) values
  (
    'cosmetic_room_cozy',
    'cosmetic',
    'Cozy Room Wallpaper',
    120,
    null,
    '{"price_jpy":120,"currency":"JPY","category":"room","description":"Warm wooden room skin."}'::jsonb,
    true
  ),
  (
    'cosmetic_room_sky',
    'cosmetic',
    'Sky Window Theme',
    180,
    null,
    '{"price_jpy":180,"currency":"JPY","category":"room","description":"Bright sky window backdrop."}'::jsonb,
    true
  ),
  (
    'consumable_snack_pack',
    'consumable',
    'Snack Pack',
    40,
    null,
    '{"price_jpy":40,"currency":"JPY","category":"pet","description":"Small treat for quick care."}'::jsonb,
    true
  ),
  (
    'consumable_clean_kit',
    'consumable',
    'Clean Kit',
    60,
    null,
    '{"price_jpy":60,"currency":"JPY","category":"pet","description":"Basic cleaning supplies."}'::jsonb,
    true
  ),
  (
    'subscription_premium_monthly',
    'subscription',
    'Premium Monthly',
    null,
    null,
    '{"price_jpy":480,"currency":"JPY","category":"subscription","description":"Unlimited rooms and no ads.","iap_product_id":"Petmonthly","iap_type":"subscription","rc_entitlement_id":"Petmonthly"}'::jsonb,
    true
  ),
  (
    'iap_coin_pack_small',
    'consumable',
    'Coin Pack Small',
    null,
    null,
    '{"price_jpy":120,"currency":"JPY","category":"coin_pack","description":"One-time coin pack.","iap_product_id":"Petcoins120","iap_type":"consumable","coin_amount":120}'::jsonb,
    true
  )
on conflict (sku) do update set
  type = excluded.type,
  name = excluded.name,
  price_coins = excluded.price_coins,
  price_usd = excluded.price_usd,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

commit;
