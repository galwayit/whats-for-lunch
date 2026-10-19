-- 0004: break the groups <-> rsvps policy recursion.
--
-- 0002's groups policy asks "does the caller have an rsvp?" and the rsvps policy asks "is the
-- caller the host?". Each subquery is itself filtered by the other table's policy, so Postgres
-- reports 42P17 "infinite recursion detected in policy for relation groups" as soon as a signed-in
-- user reads either table (first seen 2026-09-23, crashing the iOS app at launch).
--
-- The membership checks move into SECURITY DEFINER functions, which read the other table as the
-- function owner and so skip its policy. They answer only about the caller (auth.uid()), live in
-- the `private` schema (not exposed through the API), and pin search_path.

create schema if not exists private;
grant usage on schema private to authenticated;

create or replace function private.is_group_guest(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.rsvps r
    where r.group_id = p_group_id and r.guest_user_id = (select auth.uid())
  );
$$;

create or replace function private.is_group_host(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.groups g
    where g.id = p_group_id and g.host_id = (select auth.uid())
  );
$$;

revoke all on function private.is_group_guest(uuid) from public;
revoke all on function private.is_group_host(uuid) from public;
grant execute on function private.is_group_guest(uuid) to authenticated;
grant execute on function private.is_group_host(uuid) to authenticated;

-- Same rules as 0002, now without the cross-table subqueries.
drop policy if exists groups_select_host_or_guest on public.groups;
create policy groups_select_host_or_guest
  on public.groups
  for select
  to authenticated
  using (host_id = (select auth.uid()) or private.is_group_guest(id));

drop policy if exists rsvps_select_host_or_guest on public.rsvps;
create policy rsvps_select_host_or_guest
  on public.rsvps
  for select
  to authenticated
  using (guest_user_id = (select auth.uid()) or private.is_group_host(group_id));

/*
down:
  drop policy if exists rsvps_select_host_or_guest on public.rsvps;
  drop policy if exists groups_select_host_or_guest on public.groups;
  -- then re-run the two create policy statements from 0002
  drop function if exists private.is_group_host(uuid);
  drop function if exists private.is_group_guest(uuid);
*/
