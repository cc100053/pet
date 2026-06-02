-- Schedule cleanup_abandoned_rooms via pg_cron + pg_net (mirrors hunger_tick).
--
-- Two daily jobs:
--   * scan  -> finds stale rooms, snapshots R2 photo counts into the review
--              queue as 'pending'. NEVER deletes.
--   * purge -> deletes R2 photos ONLY for candidates you set to 'approved'
--              in Supabase Studio, then marks them 'purged'.
--
-- Because purge acts solely on 'approved' rows, it is safe to run on a
-- schedule: nothing disappears until you approve it.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

-- Vault secret used as the Bearer token the edge function verifies.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'cleanup_rooms_secret') then
    perform vault.create_secret(
      gen_random_uuid()::text,
      'cleanup_rooms_secret',
      'Auth secret for cleanup_abandoned_rooms cron schedule'
    );
  end if;
end
$$;

-- Helper: post to the edge function with the vault secret + a JSON body.
-- (Inlined per job below to keep this migration self-contained.)

-- Job 1: SCAN (daily 03:00 UTC) --------------------------------------------
do $$
declare
  v_jobname text := 'cleanup_abandoned_rooms_scan_daily';
begin
  perform cron.unschedule(jobid) from cron.job where jobname = v_jobname;

  perform cron.schedule(
    v_jobname,
    '0 3 * * *',
    $cmd$
    select net.http_post(
      url := 'https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/cleanup_abandoned_rooms',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (
          select decrypted_secret from vault.decrypted_secrets
          where name = 'cleanup_rooms_secret' limit 1
        )
      ),
      body := jsonb_build_object(
        'source', 'pg_cron',
        'mode', 'scan',
        'inactive_days', 30,
        'room_limit', 200
      )
    );
    $cmd$
  );
end
$$;

-- Job 2: PURGE (daily 03:30 UTC, approved-only) ----------------------------
do $$
declare
  v_jobname text := 'cleanup_abandoned_rooms_purge_daily';
begin
  perform cron.unschedule(jobid) from cron.job where jobname = v_jobname;

  perform cron.schedule(
    v_jobname,
    '30 3 * * *',
    $cmd$
    select net.http_post(
      url := 'https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/cleanup_abandoned_rooms',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (
          select decrypted_secret from vault.decrypted_secrets
          where name = 'cleanup_rooms_secret' limit 1
        )
      ),
      body := jsonb_build_object(
        'source', 'pg_cron',
        'mode', 'purge',
        'dry_run', false
      )
    );
    $cmd$
  );
end
$$;
