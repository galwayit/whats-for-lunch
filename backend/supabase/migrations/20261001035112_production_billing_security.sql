-- Service-only billing snapshots and atomic, UTC daily usage reservations.
-- Explicit grants are required after Supabase's 2026 Data API grant change.
alter table public.entitlements add column reconciled_at timestamptz;
alter table public.entitlements add column environment text check (environment in ('PRODUCTION', 'SANDBOX'));

create table public.revenuecat_events (
  event_id text primary key,
  processed_at timestamptz not null default now()
);
alter table public.revenuecat_events enable row level security;
revoke all on public.revenuecat_events from public, anon, authenticated;
grant select, insert, delete on public.revenuecat_events to service_role;

create function public.apply_revenuecat_snapshot(p_rows jsonb, p_observed_at timestamptz, p_event_id text default null)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare row_data jsonb;
begin
  if p_event_id is not null then
    insert into public.revenuecat_events(event_id) values (p_event_id) on conflict do nothing;
    if not found then return false; end if;
  end if;
  for row_data in select value from jsonb_array_elements(p_rows) loop
    insert into public.entitlements(app_user_id, is_pro, product_id, expires_at, source, environment, reconciled_at, updated_at)
    values (row_data->>'app_user_id', (row_data->>'is_pro')::boolean, row_data->>'product_id',
      (row_data->>'expires_at')::timestamptz, 'revenuecat', row_data->>'environment', p_observed_at, now())
    on conflict (app_user_id) do update set
      is_pro = excluded.is_pro, product_id = excluded.product_id, expires_at = excluded.expires_at,
      environment = excluded.environment, reconciled_at = excluded.reconciled_at, updated_at = now()
    where public.entitlements.reconciled_at is null or public.entitlements.reconciled_at <= excluded.reconciled_at;
  end loop;
  return true;
end;
$$;

create table public.ai_reservations (
  request_id uuid primary key,
  app_user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  refunded boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.ai_reservations enable row level security;
revoke all on public.ai_reservations from public, anon, authenticated;
grant select, insert, update, delete on public.ai_reservations to service_role;

create function public.reserve_ai_request(p_app_user_id uuid, p_request_id uuid, p_limit integer)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare quota_day date := (now() at time zone 'UTC')::date; new_count integer;
begin
  if p_limit < 1 or p_limit > 1000 then raise exception 'Invalid quota limit'; end if;
  -- Serialise all reservations for this account before checking the ceiling.
  perform pg_advisory_xact_lock(hashtextextended(p_app_user_id::text, 0));
  -- A replay cannot spend again or reuse a refunded reservation.
  if exists(select 1 from public.ai_reservations where request_id = p_request_id) then return false; end if;
  insert into public.usage(app_user_id, day, ai_requests) values (p_app_user_id::text, quota_day, 1)
  on conflict (app_user_id, day) do update set ai_requests = public.usage.ai_requests + 1
    where public.usage.ai_requests < p_limit
  returning ai_requests into new_count;
  if new_count is null then return false; end if;
  insert into public.ai_reservations(request_id, app_user_id, day) values (p_request_id, p_app_user_id, quota_day);
  return true;
end;
$$;

create function public.refund_ai_request(p_app_user_id uuid, p_request_id uuid)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare quota_day date;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_app_user_id::text, 0));
  update public.ai_reservations set refunded = true
  where request_id = p_request_id and app_user_id = p_app_user_id and not refunded
  returning day into quota_day;
  if quota_day is null then return false; end if;
  update public.usage set ai_requests = greatest(ai_requests - 1, 0)
    where app_user_id = p_app_user_id::text and day = quota_day;
  return true;
end;
$$;

revoke all on function public.apply_revenuecat_snapshot(jsonb, timestamptz, text) from public, anon, authenticated;
revoke all on function public.reserve_ai_request(uuid, uuid, integer) from public, anon, authenticated;
revoke all on function public.refund_ai_request(uuid, uuid) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_snapshot(jsonb, timestamptz, text) to service_role;
grant execute on function public.reserve_ai_request(uuid, uuid, integer) to service_role;
grant execute on function public.refund_ai_request(uuid, uuid) to service_role;
grant select, insert, update, delete on public.entitlements, public.usage, public.ai_requests to service_role;
grant usage, select on sequence public.ai_requests_id_seq to service_role;
-- Older helper functions previously relied on implicit platform privileges.
grant execute on function public.generate_invite_code(), public.current_tier(text),
  public.increment_ai_usage(text, date, integer), public.cleanup_places_cache(interval) to service_role;
grant select on public.groups, public.rsvps to authenticated;
grant all on public.groups, public.rsvps, public.device_tokens, public.places_cache, public.place_details_cache to service_role;

-- Only deletion progress is retained; auth deletion cascades this receipt.
create table public.account_deletions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  apple_revoked_at timestamptz not null default now()
);
alter table public.account_deletions enable row level security;
revoke all on public.account_deletions from public, anon, authenticated;
grant all on public.account_deletions to service_role;

create or replace function public.current_tier(app_user_id text)
returns text language sql stable security invoker set search_path = '' as $$
  select case when exists (
    select 1 from public.entitlements e where e.app_user_id = current_tier.app_user_id
      and e.is_pro and e.expires_at > now() and e.reconciled_at is not null
  ) then 'pro' else 'free' end;
$$;

create table public.upstream_usage (
  provider text not null check (provider in ('places', 'photos', 'gemini')),
  day date not null,
  requests integer not null check (requests > 0),
  primary key (provider, day)
);
alter table public.upstream_usage enable row level security;
revoke all on public.upstream_usage from public, anon, authenticated;
grant select, insert, update, delete on public.upstream_usage to service_role;
create function public.reserve_upstream_request(p_provider text, p_limit integer)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare new_count integer;
begin
  if p_limit < 1 or p_limit > 1000000 then raise exception 'Invalid budget'; end if;
  insert into public.upstream_usage(provider, day, requests)
  values (p_provider, (now() at time zone 'UTC')::date, 1)
  on conflict (provider, day) do update set requests = public.upstream_usage.requests + 1
    where public.upstream_usage.requests < p_limit
  returning requests into new_count;
  return new_count is not null;
end;
$$;
revoke all on function public.reserve_upstream_request(text, integer) from public, anon, authenticated;
grant execute on function public.reserve_upstream_request(text, integer) to service_role;

-- Rebuildable third-party response caches; user records and saved place IDs remain intact.
delete from public.places_cache;
delete from public.place_details_cache;
