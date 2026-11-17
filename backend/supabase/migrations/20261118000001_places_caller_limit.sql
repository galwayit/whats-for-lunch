-- Per-caller UTC daily ceilings for the public Places functions. The global cap alone lets
-- one caller spend the day's budget for everyone. A caller is a salted SHA-256 of the
-- verified account ID or the network address; raw addresses are never stored.
create table public.caller_usage (
  provider text not null check (provider in ('places', 'photos')),
  caller_hash text not null check (caller_hash ~ '^[a-f0-9]{64}$'),
  day date not null,
  requests integer not null check (requests > 0),
  primary key (provider, caller_hash, day)
);
create index caller_usage_day_idx on public.caller_usage (day);
alter table public.caller_usage enable row level security;
revoke all on public.caller_usage from public, anon, authenticated;
grant select, insert, update, delete on public.caller_usage to service_role;

-- One search costs several upstream requests, so the whole cost is reserved or refused at once.
create function public.reserve_caller_request(p_provider text, p_caller_hash text, p_limit integer, p_requests integer default 1)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare new_count integer;
begin
  if p_limit is null or p_requests is null or p_limit < 1 or p_limit > 1000000 or p_requests < 1 then
    raise exception 'Invalid budget';
  end if;
  if p_requests > p_limit then return false; end if;
  insert into public.caller_usage(provider, caller_hash, day, requests)
  values (p_provider, p_caller_hash, (now() at time zone 'UTC')::date, p_requests)
  on conflict (provider, caller_hash, day) do update set requests = public.caller_usage.requests + p_requests
    where public.caller_usage.requests + p_requests <= p_limit
  returning requests into new_count;
  return new_count is not null;
end;
$$;
revoke all on function public.reserve_caller_request(text, text, integer, integer) from public, anon, authenticated;
grant execute on function public.reserve_caller_request(text, text, integer, integer) to service_role;
