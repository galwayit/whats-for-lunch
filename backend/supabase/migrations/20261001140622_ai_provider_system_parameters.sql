-- Runtime AI routing contains no API keys. Only operators/service_role may edit it.
-- This settings-only section may be provisioned ahead of the coordinated rollout.
-- Rerunning it preserves operator values and their history.
create table if not exists public.system_parameters (
  key text primary key,
  value jsonb not null check (jsonb_typeof(value) = 'object'),
  updated_at timestamptz not null default now()
);
alter table public.system_parameters enable row level security;
revoke all on public.system_parameters from public, anon, authenticated;
grant select, insert, update on public.system_parameters to service_role;
create table if not exists public.system_parameter_history (
  id bigint generated always as identity primary key,
  key text not null,
  old_value jsonb,
  new_value jsonb not null,
  changed_at timestamptz not null default now()
);
alter table public.system_parameter_history enable row level security;
revoke all on public.system_parameter_history from public, anon, authenticated;
grant select, insert on public.system_parameter_history to service_role;
grant usage, select on sequence public.system_parameter_history_id_seq to service_role;
create or replace function public.audit_system_parameter() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  new.updated_at := now();
  insert into public.system_parameter_history(key, old_value, new_value)
    values (new.key, case when tg_op = 'UPDATE' then old.value else null end, new.value);
  return new;
end;
$$;
revoke all on function public.audit_system_parameter() from public, anon, authenticated;
grant execute on function public.audit_system_parameter() to service_role;
drop trigger if exists audit_system_parameter on public.system_parameters;
create trigger audit_system_parameter before insert or update on public.system_parameters
for each row execute function public.audit_system_parameter();

-- Deliberately disabled until provider credentials and the secure backend rollout are verified.
insert into public.system_parameters(key, value) select 'ai.providers', '{
  "enabled": false, "primary": "google", "backup": "openai", "consentRevision": "2026-10-02",
  "providers": [
    {"id":"google","kind":"google","models":{"free":"gemini-3.8-flash","pro":"gemini-3.8-flash"},"timeoutMs":10000,"maxOutputTokens":2048,"dailyRequestLimit":400},
    {"id":"openai","kind":"openai","models":{"free":"gpt-6-luna","pro":"gpt-6-luna"},"timeoutMs":10000,"maxOutputTokens":2048,"dailyRequestLimit":200},
    {"id":"claude","kind":"anthropic","models":{"free":"claude-haiku-4-5","pro":"claude-haiku-4-5"},"timeoutMs":10000,"maxOutputTokens":2048,"dailyRequestLimit":200}
  ]
}'::jsonb where not exists (
  select 1 from public.system_parameters where key = 'ai.providers'
);

-- END SETTINGS BOOTSTRAP: the remaining changes require the billing/quota migration.

alter table public.ai_requests
  add column provider text,
  add column request_id uuid,
  add column attempt integer check (attempt in (1,2)),
  add column route_role text check (route_role in ('primary','backup'));
create index ai_requests_request_id_idx on public.ai_requests(request_id);
alter table public.upstream_usage drop constraint upstream_usage_provider_check;
alter table public.upstream_usage add constraint upstream_usage_provider_check
  check (provider in ('places','photos','gemini','ai') or provider ~ '^ai:[a-z][a-z0-9_-]{0,31}$');

-- Reserve both the total AI cap and the profile cap in one transaction. Each actual attempt
-- counts, including a failed call before failover; one user reservation covers both attempts.
create function public.reserve_ai_provider_request(p_provider text, p_provider_limit integer, p_total_limit integer)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare quota_day date := (now() at time zone 'UTC')::date; total_used integer; provider_used integer;
begin
  if p_provider is null or p_provider_limit is null or p_total_limit is null or p_provider !~ '^[a-z][a-z0-9_-]{0,31}$' or p_provider_limit < 1 or p_provider_limit > 10000
    or p_total_limit < 1 or p_total_limit > 10000 then raise exception 'Invalid AI capacity'; end if;
  perform pg_advisory_xact_lock(hashtextextended('ai_provider_capacity', 0));
  select requests into total_used from public.upstream_usage where provider = 'ai' and day = quota_day;
  select requests into provider_used from public.upstream_usage where provider = 'ai:' || p_provider and day = quota_day;
  if coalesce(total_used, 0) >= p_total_limit or coalesce(provider_used, 0) >= p_provider_limit then return false; end if;
  insert into public.upstream_usage(provider, day, requests) values ('ai', quota_day, 1), ('ai:' || p_provider, quota_day, 1)
    on conflict (provider, day) do update set requests = public.upstream_usage.requests + 1;
  return true;
end;
$$;
revoke all on function public.reserve_ai_provider_request(text,integer,integer) from public, anon, authenticated;
grant execute on function public.reserve_ai_provider_request(text,integer,integer) to service_role;
