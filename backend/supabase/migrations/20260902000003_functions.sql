-- 0003: helper SQL functions used by the edge functions.
-- All are security definer with a pinned search_path and are callable only
-- by the service role (execute is revoked from anon/authenticated).

-- 8 characters of Crockford base32 (0-9 A-Z without I, L, O, U), unique in
-- groups.invite_code. Retries a bounded number of times on collision.
create or replace function public.generate_invite_code()
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  alphabet constant text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  candidate text;
  attempt integer := 0;
begin
  loop
    candidate := '';
    for i in 1..8 loop
      -- gen_random_bytes gives uniform randomness; index is 1-based.
      candidate := candidate
        || substr(alphabet, (get_byte(extensions.gen_random_bytes(1), 0) % 32) + 1, 1);
    end loop;
    exit when not exists (select 1 from public.groups g where g.invite_code = candidate);
    attempt := attempt + 1;
    if attempt >= 20 then
      raise exception 'could not generate a unique invite code after % attempts', attempt;
    end if;
  end loop;
  return candidate;
end;
$$;

-- 'pro' when the entitlement row is Pro and not expired, else 'free'.
create or replace function public.current_tier(app_user_id text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
    when exists (
      select 1 from public.entitlements e
      where e.app_user_id = current_tier.app_user_id
        and e.is_pro
        and (e.expires_at is null or e.expires_at > now())
    ) then 'pro'
    else 'free'
  end;
$$;

-- Atomic per-day counter used by ai-recommend (delta -1 refunds a failed call).
create or replace function public.increment_ai_usage(
  p_app_user_id text,
  p_day date,
  p_delta integer default 1
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  insert into public.usage (app_user_id, day, ai_requests)
  values (p_app_user_id, p_day, greatest(p_delta, 0))
  on conflict (app_user_id, day)
  do update set ai_requests = greatest(public.usage.ai_requests + p_delta, 0)
  returning ai_requests into new_count;
  return new_count;
end;
$$;

-- Removes cache rows older than the TTL (default 24 h) and usage rows older
-- than 60 days. Returns the number of cache rows deleted. Schedule with
-- pg_cron, e.g. select cron.schedule('places-cache', '17 * * * *', $$select public.cleanup_places_cache()$$);
create or replace function public.cleanup_places_cache(ttl interval default interval '24 hours')
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  removed integer := 0;
  removed_details integer := 0;
begin
  delete from public.places_cache where fetched_at < now() - ttl;
  get diagnostics removed = row_count;
  delete from public.place_details_cache where fetched_at < now() - ttl;
  get diagnostics removed_details = row_count;
  delete from public.usage where day < (current_date - interval '60 days');
  return removed + removed_details;
end;
$$;

revoke execute on function public.generate_invite_code() from public, anon, authenticated;
revoke execute on function public.current_tier(text) from public, anon, authenticated;
revoke execute on function public.increment_ai_usage(text, date, integer) from public, anon, authenticated;
revoke execute on function public.cleanup_places_cache(interval) from public, anon, authenticated;

/*
down:
  drop function if exists public.cleanup_places_cache(interval);
  drop function if exists public.increment_ai_usage(text, date, integer);
  drop function if exists public.current_tier(text);
  drop function if exists public.generate_invite_code();
*/
