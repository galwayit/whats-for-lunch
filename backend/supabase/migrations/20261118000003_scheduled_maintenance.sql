-- Daily retention. pg_cron runs it as the migration role; an operator can run it as service_role.
create function public.run_daily_maintenance()
returns void language plpgsql security invoker set search_path = '' as $$
declare today date := (now() at time zone 'UTC')::date;
begin
  perform public.cleanup_places_cache();
  -- Ledgers keep 90 days for support and billing disputes. Quotas read only the current UTC
  -- day, a reservation is refunded within its own request, and RevenueCat retries a webhook
  -- for hours, so nothing older is needed for idempotency.
  delete from public.ai_requests where created_at < now() - interval '90 days';
  delete from public.ai_reservations where created_at < now() - interval '90 days';
  delete from public.upstream_usage where day < today - 90;
  delete from public.caller_usage where day < today - 90;
  delete from public.revenuecat_events where processed_at < now() - interval '90 days';
  -- Open reports wait for an operator however old they are.
  delete from public.content_reports
    where status <> 'open' and coalesce(reviewed_at, created_at) < now() - interval '90 days';
  -- Google allows Places content other than place IDs to be kept for 30 days only.
  update public.groups set place_name = null, place_address = null
    where scheduled_at < now() - interval '30 days' and (place_name is not null or place_address is not null);
  -- A suggestion must keep a place or a time, so one that only named a place is removed whole.
  delete from public.group_suggestions s using public.groups g
    where g.id = s.group_id and g.scheduled_at < now() - interval '30 days' and s.scheduled_at is null;
  update public.group_suggestions s set place_name = null, place_address = null from public.groups g
    where g.id = s.group_id and g.scheduled_at < now() - interval '30 days' and s.place_name is not null;
end $$;
revoke all on function public.run_daily_maintenance() from public, anon, authenticated;
grant execute on function public.run_daily_maintenance() to service_role;

-- Supabase provides pg_cron; the plain PostgreSQL used by the regression tests does not.
do $$
begin
  if exists (select 1 from pg_catalog.pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron with schema pg_catalog;
    grant usage on schema cron to postgres;
    grant all privileges on all tables in schema cron to postgres;
    -- Rerunning must leave exactly one job.
    perform cron.unschedule(jobid) from cron.job where jobname = 'lunch-daily-maintenance';
    -- 17:17 UTC falls between 01:00 and 05:00 across Australia.
    perform cron.schedule('lunch-daily-maintenance', '17 17 * * *', 'select public.run_daily_maintenance()');
  end if;
end $$;
