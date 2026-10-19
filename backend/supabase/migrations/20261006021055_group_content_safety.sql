-- Private moderation queue and bilateral blocking. App clients never read identities,
-- report evidence or guest capabilities; only service handlers can invoke the RPCs.
alter table public.groups add column moderated_at timestamptz;
alter table public.rsvps add column moderated_at timestamptz;
alter table public.group_suggestions add column moderated_at timestamptz;

create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  reporter text not null,
  target_kind text not null check (target_kind in ('group','rsvp','suggestion')),
  target_id uuid not null,
  reason text not null check (reason in ('harassment','hate','sexual','spam','other')),
  evidence jsonb not null,
  status text not null default 'open' check (status in ('open','removed','dismissed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (reporter, group_id, target_kind, target_id)
);
create index content_reports_queue on public.content_reports(status, created_at);
create index content_reports_reporter_date on public.content_reports(reporter, created_at);
create table public.content_blocks (
  blocker text not null,
  blocked text not null,
  created_at timestamptz not null default now(),
  primary key (blocker, blocked),
  check (blocker <> blocked)
);
create index content_blocks_target on public.content_blocks(blocked, blocker);
alter table public.content_reports enable row level security;
alter table public.content_blocks enable row level security;
revoke all on public.content_reports, public.content_blocks from public, anon, authenticated;
grant all on public.content_reports, public.content_blocks to service_role;

create function private.content_identity(p_user uuid, p_token text) returns text
language sql immutable security invoker set search_path = '' as $$
  select case when p_user is not null then 'u:' || p_user::text
    when p_token ~ '^[a-f0-9]{64}$' then 'g:' || encode(extensions.digest(p_token, 'sha256'), 'hex') end;
$$;
create function private.content_blocked(a text, b text) returns boolean
language sql stable security invoker set search_path = '' as $$
  select exists(select 1 from public.content_blocks where (blocker=a and blocked=b) or (blocker=b and blocked=a));
$$;
revoke all on function private.content_identity(uuid,text), private.content_blocked(text,text) from public, anon, authenticated;
grant usage on schema private to service_role;
grant execute on function private.content_identity(uuid,text), private.content_blocked(text,text) to service_role;

create function public.group_safety_context(p_group_id uuid, p_user_id uuid, p_guest_token text, p_include_cancelled boolean default false)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'allowed', g.moderated_at is null and not private.content_blocked('u:'||g.host_id::text, private.content_identity(p_user_id,p_guest_token)),
    'hiddenRsvpIds', coalesce((select jsonb_agg(r.id) from public.rsvps r where r.group_id=g.id and
      (r.moderated_at is not null or private.content_blocked(private.content_identity(r.guest_user_id,r.guest_token), private.content_identity(p_user_id,p_guest_token))
      or private.content_blocked(private.content_identity(r.guest_user_id,r.guest_token), 'u:'||g.host_id::text))), '[]'::jsonb)
  ) from public.groups g where g.id=p_group_id and (g.cancelled_at is null or p_include_cancelled);
$$;
revoke all on function public.group_safety_context(uuid,uuid,text,boolean) from public, anon, authenticated;
grant execute on function public.group_safety_context(uuid,uuid,text,boolean) to service_role;

create function public.group_safety_action(p_code text, p_user_id uuid, p_guest_token text,
  p_target_kind text, p_target_id uuid, p_action text, p_reason text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare g public.groups; r public.rsvps; s public.group_suggestions;
  actor text; target text; evidence jsonb; report_id uuid;
begin
  actor := private.content_identity(p_user_id,p_guest_token);
  if actor is null then raise exception 'Guest identity or sign-in required' using errcode='22023'; end if;
  if p_action not in ('report','block','report_block') or p_action is null then raise exception 'Invalid action' using errcode='22023'; end if;
  if p_reason not in ('harassment','hate','sexual','spam','other') or p_reason is null then raise exception 'Invalid reason' using errcode='22023'; end if;
  -- Serialise the actor across invitations as well as each invitation's total.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(actor, 61006));
  select * into g from public.groups where invite_code=p_code for update;
  if not found then raise exception 'Invitation unavailable' using errcode='P0002'; end if;
  if p_target_kind='group' and (p_target_id is null or p_target_id=g.id) then
    p_target_id := g.id;
    target := 'u:'||g.host_id::text;
    evidence := jsonb_build_object('name',g.name,'hostName',g.host_name,'placeName',g.place_name,'placeAddress',g.place_address);
  elsif p_target_kind='rsvp' then
    select * into r from public.rsvps where id=p_target_id and group_id=g.id;
    if not found then raise exception 'Guest unavailable' using errcode='P0002'; end if;
    target := private.content_identity(r.guest_user_id,r.guest_token);
    evidence := jsonb_build_object('displayName',r.display_name);
  elsif p_target_kind='suggestion' then
    if p_user_id is null or p_user_id <> g.host_id then raise exception 'Only the host can report private suggestions' using errcode='42501'; end if;
    select * into s from public.group_suggestions where id=p_target_id and group_id=g.id;
    if not found then raise exception 'Suggestion unavailable' using errcode='P0002'; end if;
    select * into r from public.rsvps where id=s.rsvp_id;
    target := private.content_identity(r.guest_user_id,r.guest_token);
    evidence := jsonb_build_object('displayName',s.display_name,'placeName',s.place_name,'placeAddress',s.place_address,'note',s.note);
  else raise exception 'Invalid target' using errcode='22023'; end if;
  if target is null or target=actor then raise exception 'Cannot report or block yourself' using errcode='22023'; end if;
  if p_action in ('report','report_block') then
    select id into report_id from public.content_reports where reporter=actor and group_id=g.id and target_kind=p_target_kind and target_id=p_target_id;
    if report_id is null then
      if (select count(*) from public.content_reports where reporter=actor and created_at>now()-interval '1 day') >= 20
      or (select count(*) from public.content_reports where group_id=g.id and created_at>now()-interval '1 day') >= 200 then
        raise exception 'Report limit reached; contact hello@iapp.au' using errcode='22023';
      end if;
      insert into public.content_reports(group_id,reporter,target_kind,target_id,reason,evidence)
        values(g.id,actor,p_target_kind,p_target_id,p_reason,evidence) returning id into report_id;
    end if;
  end if;
  if p_action in ('block','report_block') then
    insert into public.content_blocks(blocker,blocked) values(actor,target) on conflict do nothing;
  end if;
  return report_id;
end $$;
revoke all on function public.group_safety_action(text,uuid,text,text,uuid,text,text) from public, anon, authenticated;
grant execute on function public.group_safety_action(text,uuid,text,text,uuid,text,text) to service_role;

-- These private predicates answer only for auth.uid(); clients cannot query others' blocks.
create function private.can_view_group_content(p_group_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select (select auth.uid()) is not null and exists(select 1 from public.groups g where g.id=p_group_id and g.moderated_at is null
    and not private.content_blocked('u:'||g.host_id::text,'u:'||(select auth.uid())::text));
$$;
create function private.can_view_rsvp_content(p_rsvp_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select (select auth.uid()) is not null and exists(select 1 from public.rsvps r join public.groups g on g.id=r.group_id
    where r.id=p_rsvp_id and r.moderated_at is null and g.moderated_at is null
    and not private.content_blocked('u:'||g.host_id::text,'u:'||(select auth.uid())::text)
    and not private.content_blocked(private.content_identity(r.guest_user_id,r.guest_token),'u:'||g.host_id::text)
    and not private.content_blocked(private.content_identity(r.guest_user_id,r.guest_token),'u:'||(select auth.uid())::text));
$$;
revoke all on function private.can_view_group_content(uuid), private.can_view_rsvp_content(uuid) from public, anon;
grant execute on function private.can_view_group_content(uuid), private.can_view_rsvp_content(uuid) to authenticated;
create policy groups_safety on public.groups as restrictive for select to authenticated using(private.can_view_group_content(id));
create policy rsvps_safety on public.rsvps as restrictive for select to authenticated using(private.can_view_rsvp_content(id));

-- Enforce blocks on writes even if a caller uses an old app or bypasses the UI.
create function private.guard_group_guest_content() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare g public.groups; r public.rsvps;
begin
  if tg_op='UPDATE' and ((tg_table_name='rsvps' and new.status='pending') or
    (tg_table_name='group_suggestions' and new.status in ('declined','superseded'))) then return new; end if;
  select * into g from public.groups where id=new.group_id;
  if tg_table_name='rsvps' then r := new;
  else select * into r from public.rsvps where id=new.rsvp_id; end if;
  if g.moderated_at is not null or r.moderated_at is not null or new.moderated_at is not null or private.content_blocked('u:'||g.host_id::text,private.content_identity(r.guest_user_id,r.guest_token)) then
    raise exception 'This interaction is unavailable' using errcode='42501';
  end if;
  return new;
end $$;
revoke all on function private.guard_group_guest_content() from public,anon,authenticated;
create trigger rsvp_content_guard before insert or update of status,display_name on public.rsvps for each row execute function private.guard_group_guest_content();
create trigger suggestion_content_guard before insert or update of status on public.group_suggestions for each row execute function private.guard_group_guest_content();

-- Account deletion removes personal safety records too. Group deletion cascades reports.
create function private.delete_content_identity() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.content_blocks where blocker='u:'||old.id::text or blocked='u:'||old.id::text;
  delete from public.content_reports where reporter='u:'||old.id::text
    or (target_kind='rsvp' and target_id in (select id from public.rsvps where guest_user_id=old.id))
    or (target_kind='suggestion' and target_id in (select s.id from public.group_suggestions s join public.rsvps r on r.id=s.rsvp_id where r.guest_user_id=old.id));
  return old;
end $$;
revoke all on function private.delete_content_identity() from public,anon,authenticated;
create trigger delete_content_identity before delete on auth.users for each row execute function private.delete_content_identity();

-- Operator-only resolution; no client can remove another person's content.
create function public.review_content_report(p_report_id uuid, p_remove boolean)
returns void language plpgsql security invoker set search_path = '' as $$
declare r public.content_reports; s public.group_suggestions;
begin
  if p_remove is null then raise exception 'Decision required' using errcode='22023'; end if;
  select * into r from public.content_reports where id=p_report_id for update;
  if not found then raise exception 'Report unavailable' using errcode='P0002'; end if;
  if r.status <> 'open' then return; end if;
  if p_remove then
    if r.target_kind='group' then update public.groups set moderated_at=now() where id=r.group_id;
    elsif r.target_kind='rsvp' then
      update public.rsvps set moderated_at=now() where id=r.target_id and group_id=r.group_id;
      update public.group_suggestions set moderated_at=now() where rsvp_id=r.target_id;
      if exists(select 1 from public.group_suggestions where rsvp_id=r.target_id and status='accepted') then
        update public.groups set moderated_at=now() where id=r.group_id;
      end if;
    else
      select * into s from public.group_suggestions where id=r.target_id and group_id=r.group_id;
      update public.group_suggestions set moderated_at=now() where id=r.target_id;
      if s.status='accepted' then update public.groups set moderated_at=now() where id=r.group_id; end if;
    end if;
  end if;
  update public.content_reports set status=case when p_remove then 'removed' else 'dismissed' end, reviewed_at=now() where id=p_report_id;
end $$;
revoke all on function public.review_content_report(uuid,boolean) from public,anon,authenticated;
grant execute on function public.review_content_report(uuid,boolean) to service_role;
