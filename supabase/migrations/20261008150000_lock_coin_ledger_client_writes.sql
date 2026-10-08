-- coin_ledger is written only by server functions. The init schema's
-- coin_ledger_insert policy plus default table grants let any signed-in user
-- POST arbitrary rows to /rest/v1/coin_ledger; no app version ever used it.
-- Owner-approved 2026-10-08.

-- The one invoker function that writes the ledger becomes definer, like its
-- siblings (purchase_room_furniture_with_coins, purchase_item_with_coins).
-- It already checks auth.uid(), room membership and the item itself.
alter function public.purchase_room_background_with_coins(uuid, uuid)
  security definer;

drop policy if exists coin_ledger_insert on public.coin_ledger;

revoke insert, update, delete, truncate, references, trigger
  on public.coin_ledger from anon, authenticated;
revoke select on public.coin_ledger from anon;

-- Users still read their own rows (coin_ledger_select: user_id = auth.uid()).
grant select on public.coin_ledger to authenticated;
