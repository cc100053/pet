do $$
begin
  if not exists (select 1 from vault.secrets where name = 'hunger_tick_secret') then
    perform vault.create_secret(
      gen_random_uuid()::text,
      'hunger_tick_secret',
      'Auth secret for hunger_tick_dispatch cron schedule'
    );
  end if;
end
$$;

do $$
declare
  v_jobname text := 'hunger_tick_dispatch_every_10m';
begin
  perform cron.unschedule(jobid)
  from cron.job
  where jobname = v_jobname;

  perform cron.schedule(
    v_jobname,
    '*/10 * * * *',
    $cmd$
    select net.http_post(
      url := 'https://ilxzpszgirhwxpeocygs.supabase.co/functions/v1/hunger_tick_dispatch',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (
          select decrypted_secret
          from vault.decrypted_secrets
          where name = 'hunger_tick_secret'
          limit 1
        )
      ),
      body := '{"source":"pg_cron"}'::jsonb
    );
    $cmd$
  );
end
$$;
