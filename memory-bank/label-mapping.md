# Label Mapping Dictionary

## Goals
- Translate ML Kit English labels into ZH/JA gameplay tags.
- Map tags to daily quests with minimal false positives.

## Normalization Rules
- Lowercase, trim, and remove punctuation.
- Prefer exact label matches, then synonyms.
- Avoid matching generic labels (e.g., "Food") unless no specific tag exists.

## Canonical Tags (Seed)
Use these tags across labels and quests for stable matching.

| canonical_tag | ml_kit_labels (EN) | zh-TW keywords | ja-JP keywords | notes |
| --- | --- | --- | --- | --- |
| beverage.coffee | Coffee, Espresso, Cappuccino, Latte, Cup | 咖啡, 杯子, 馬克杯 | コーヒー, カップ | Treat "Cup" as coffee only if paired with beverage labels |
| beverage.tea | Tea, Teapot, Cup | 茶, 杯子 | お茶, カップ | "Tea" beats "Beverage" |
| beverage.juice | Juice, Drink, Beverage | 果汁, 飲料, 飲品 | ジュース, 飲み物 | Use with confidence >= 0.7 |
| dessert.ice_cream | Ice cream, Frozen dessert | 冰淇淋, 霜淇淋 | アイスクリーム | Daily quest example: 影雪糕 |
| dessert.cake | Cake, Cupcake, Pie | 蛋糕, 派, 杯子蛋糕 | ケーキ, パイ | Dessert quest target |
| dessert.cookie | Cookie, Biscuit, Chocolate | 餅乾, 巧克力 | クッキー, チョコ | Lower priority than ice cream/cake |
| fruit.any | Fruit, Apple, Banana, Berry, Strawberry, Orange | 水果, 蘋果, 香蕉, 草莓, 柳橙 | フルーツ, りんご, バナナ, いちご, オレンジ | Accept any fruit label |
| meal.sandwich | Sandwich, Hamburger, Bread | 三明治, 漢堡, 麵包 | サンドイッチ, ハンバーガー, パン | Avoid generic "Food" if possible |
| meal.rice | Rice, Sushi, Bento | 米飯, 壽司, 便當 | ごはん, 寿司, 弁当 | Useful for JP market |
| meal.noodles | Noodle, Ramen, Spaghetti | 麵, 拉麵, 義大利麵 | 麺, ラーメン, スパゲッティ | Use for meal quest |
| flower | Flower, Plant | 花, 花朵, 植物 | 花, 植物 | Optional quest for variety |

## Quest Keywords (Seed)
Use canonical tags to reduce mismatch. Localized names are displayed to users.

| quest_id | quest_name_zh | quest_name_ja | canonical_tags |
| --- | --- | --- | --- |
| Q001 | 咖啡 | コーヒー | beverage.coffee |
| Q002 | 茶 | お茶 | beverage.tea |
| Q003 | 冰淇淋 | アイスクリーム | dessert.ice_cream |
| Q004 | 水果 | フルーツ | fruit.any |
| Q005 | 甜點 | デザート | dessert.cake, dessert.cookie |
| Q006 | 正餐 | 食事 | meal.sandwich, meal.rice, meal.noodles |
| Q007 | 花 | 花 | flower |

## Notes
- Keep label mappings small and explicit to reduce false positives.
- Add new labels when ML Kit logs show repeated misses.
