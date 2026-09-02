-- 0002: row-level security (see backend/API.md "Row-level security").
-- The service role bypasses RLS, so edge functions remain the only writers.
-- Tables with RLS enabled and no policy are invisible to anon/authenticated.

alter table public.entitlements enable row level security;
alter table public.usage enable row level security;
alter table public.ai_requests enable row level security;
alter table public.places_cache enable row level security;
alter table public.place_details_cache enable row level security;
alter table public.device_tokens enable row level security;
alter table public.groups enable row level security;
alter table public.rsvps enable row level security;

-- groups: readable by the host and by any signed-in user with an rsvp row.
create policy groups_select_host_or_guest
  on public.groups
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or exists (
      select 1 from public.rsvps r
      where r.group_id = groups.id and r.guest_user_id = auth.uid()
    )
  );

-- rsvps: readable by the group host and by the guest themself.
create policy rsvps_select_host_or_guest
  on public.rsvps
  for select
  to authenticated
  using (
    guest_user_id = auth.uid()
    or exists (
      select 1 from public.groups g
      where g.id = rsvps.group_id and g.host_id = auth.uid()
    )
  );

-- No insert/update/delete policies anywhere: writes go through functions.
-- entitlements, usage, ai_requests, caches, device_tokens: service role only
-- (RLS on, zero policies).

-- Realtime: allow the apps to subscribe to rsvps for the host's groups.
alter publication supabase_realtime add table public.rsvps;

/*
down:
  alter publication supabase_realtime drop table public.rsvps;
  drop policy if exists rsvps_select_host_or_guest on public.rsvps;
  drop policy if exists groups_select_host_or_guest on public.groups;
  alter table public.rsvps disable row level security;
  alter table public.groups disable row level security;
  alter table public.device_tokens disable row level security;
  alter table public.place_details_cache disable row level security;
  alter table public.places_cache disable row level security;
  alter table public.ai_requests disable row level security;
  alter table public.usage disable row level security;
  alter table public.entitlements disable row level security;
*/
