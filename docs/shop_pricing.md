# Shop Pricing

How to price a new coin-priced shop item without re-deriving the economy every
time. Pick a rung from the ladder, sanity-check against the guardrails, ship.

Re-run the calibration queries at the bottom **once per quarter**, or after any
change to coin rewards, ad rewards, or diamond exchange rates. Everything above
them is a conclusion drawn from those queries — if the numbers move, the ladder
moves with them.

Last calibrated: **2026-08-13** (242 profiles, 30-day window).

## The two facts everything rests on

1. **Coin price is a pacing lever, not a revenue lever.** ~95% of all coins are
   earned by feeding and cleaning; only ~5% trace back to paid diamonds. A price
   does not decide what you earn — it decides how many days of play an item
   costs and how many players ever get it.
2. **The median wallet is nearly empty** (median balance 21 coins, median
   25 coins earned per active day). Most players spend as they earn. Anything
   above ~150 is not a purchase, it is a savings goal.

## The ladder

Price in **days of play**, then round to a rung. Days = price ÷ 25 (median coins
per active day). Never invent a value between rungs — an arbitrary 180 implies a
precision we do not have and makes the next drop harder to slot.

| Rung | Days to earn | Use for |
|---|---|---|
| **100** | 4 | Entry item. Small accent, one per drop. |
| **150** | 6 | Standard piece. Illustrated art, ordinary footprint. |
| **200** | 8 | Large footprint, or a complement that enables other placements (rugs, backgrounds). |
| **250** | 10 | Anchor. The statement piece a room gets built around. One per drop, at most. |

Emoji-art items sit one rung below the equivalent illustrated item — the
illustrated Cactus is 150 against the emoji Plant's 120.

## Guardrails

- **Ceiling: 250.** Nothing above ~10 days of median earning until a 300 tier
  demonstrably sells. See the Toilet/Tub evidence below.
- **Every drop needs a 100.** A median-wallet player must be able to buy
  something on launch day. This is also shelf placement: `_itemSortPrice`
  (`lib/features/shop/shop_view.dart:628`) sorts the grid ascending, so the
  cheapest new item takes the top slot and announces the drop.
- **Complements cheap, focal points expensive.** A rug makes everything placed
  on it look better, so a cheap rug sells more of everything else. Price the
  thing that *enables* other purchases low.
- **Launch low, raise later — never the reverse.** Prices are a one-line
  `UPDATE` with no client change (precedent:
  `supabase/migrations/20260511225923_raise_v140_equipment_prices.sql`). Raising
  a cosmetic's price is painless; cutting it burns everyone who paid full price.
- **Keep `price_coins` and `metadata.price_jpy` equal.** They are the same
  number in two places and the shop reads both.

## Why the ceiling is 250

Toilet and Tub shipped in the same migration, same category, identical exposure
since 1.1.2 — a clean natural experiment:

| Item | Price | Purchases | Buyers | Coins sunk |
|---|---|---|---|---|
| Toilet | 150 | 21 | 14 | 3,150 |
| Tub | 300 | 10 | 8 | 3,000 |

Double the price, half the buyers, **the same coin sink**. The expensive item
extracted nothing extra; it only meant six fewer players ever owned one.
Catalog-wide the pattern is directionally the same (items ≤170 average ~19
purchases, items ≥200 average ~10), though exposure time is uncontrolled there.

## Recalibration queries

Run all three, then update the "Last calibrated" date and any number above that
has moved materially. Project ref `ilxzpszgirhwxpeocygs` (verify against `.env`
before running).

```sql
-- 1. Earn rate. Drives the ladder: rung = target_days * median_per_day.
with daily as (
  select user_id, date_trunc('day', created_at) as d, sum(amount) as earned
  from public.coin_ledger
  where amount > 0 and created_at > now() - interval '30 days'
  group by 1, 2
)
select count(*) as active_user_days,
       round(avg(earned)) as avg_per_day,
       percentile_cont(0.5) within group (order by earned) as median_per_day,
       percentile_cont(0.9) within group (order by earned) as p90_per_day
from daily;

-- 2. Wallets. Median balance sets what an "affordable today" item costs.
select count(*) as profiles,
       round(avg(coins)) as avg_coins,
       percentile_cont(0.5) within group (order by coins) as median_coins,
       percentile_cont(0.9) within group (order by coins) as p90_coins
from public.profiles;

-- 3. Price vs uptake. Confirms the ceiling still holds.
--    Compare items of the same category and similar exposure only.
select i.sku, i.price_coins, count(*) as purchases,
       count(distinct c.user_id) as buyers,
       count(*) * i.price_coins as coins_sunk
from public.coin_ledger c
join public.items i on i.id = (c.metadata->>'item_id')::uuid
where c.source = 'store_purchase'
group by i.sku, i.price_coins
order by i.price_coins;

-- 4. Coin supply mix. If paid diamonds ever exceed ~20% of coins earned,
--    fact #1 no longer holds and this whole document needs rethinking.
select source, count(*) as events, sum(amount) as total
from public.coin_ledger
where amount > 0
group by source order by total desc;
```

## Applying a price change

Prices are catalog data — no client release required.

```sql
update public.items i
set price_coins = v.price,
    metadata = i.metadata || jsonb_build_object('price_jpy', v.price)
from (values ('some_sku', 150)) as v(sku, price)
where i.sku = v.sku
returning i.sku, i.price_coins, i.metadata->>'price_jpy';
```

Mirror the change into the migration that created the item so git and prod stay
in sync, and log it in `docs/release_status.md` under Backend Deployments.

## Where a new item gets wired

Pricing is one of five touch points. For a furniture item the full set is:

1. `assets/furniture/<name>.png` — lowercase filename; `pubspec.yaml` already
   globs the directory, so no pubspec edit.
2. A migration in `supabase/migrations/` inserting the `items` row. Gate it with
   `is_active=false` + `visibility_mode=version_gated` +
   `min_app_version=<the release that bundles the asset>` +
   `fallback_behavior=skip`, so builds without the PNG never see it.
3. `lib/l10n/app_{en,ja,zh,zh_TW,ko}.arb` — `storeItemName…` and
   `storeItemDesc…` keys, then `flutter gen-l10n`.
4. `lib/features/shop/shop_item_localization.dart` — sku → name case.
5. `lib/features/shop/models/shop_item.dart` (`localizedDescription`) — sku →
   description case.

Reference implementation: `supabase/migrations/20260813120000_add_v235_furniture_catalog.sql`
and the commit that accompanies it.
