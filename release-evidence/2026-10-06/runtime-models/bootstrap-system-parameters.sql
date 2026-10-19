-- Settings-only preparation. AI remains disabled; no billing, user or quota changes.
BEGIN;
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


COMMIT;
