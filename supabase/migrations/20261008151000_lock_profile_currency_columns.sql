-- profiles_update (user_id = auth.uid()) plus full table grants let any
-- signed-in user PATCH /rest/v1/profiles and set their own coins/diamonds.
-- Balances change only through SECURITY DEFINER functions; clients keep
-- exactly the columns any app version has written (git history 2026-10-08:
-- insert user_id/nickname/timezone, update nickname/avatar_url/timezone; no
-- release ever wrote coins or diamonds). Owner-approved 2026-10-08.
-- Side effect: the admin debug coin tool (home_view_debug.dart) stops working.

revoke insert, update, truncate, references, trigger
  on public.profiles from anon, authenticated;
revoke delete on public.profiles from anon;

grant insert (user_id, nickname, avatar_url, locale, timezone)
  on public.profiles to authenticated;
grant update (nickname, avatar_url, locale, timezone)
  on public.profiles to authenticated;
-- SELECT and DELETE for authenticated stay as they are (RLS-scoped).
