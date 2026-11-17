-- Guests per lunch are capped like suggestions (200). RSVPs are inserted by the reply
-- handler and by submit_group_suggestion, so a trigger covers every path. Updating an
-- existing reply never fires it.
create function private.enforce_rsvp_limit() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  -- An upsert of an existing reply reaches this trigger before its conflict is detected.
  -- It returns before the group lock: waiting for its own row while holding that lock could
  -- deadlock with a moderation review, which locks the reply first and the group second.
  if exists(select 1 from public.rsvps where group_id = new.group_id
    and (guest_user_id = new.guest_user_id or guest_token = new.guest_token)) then return new; end if;
  -- The group lock makes concurrent new guests count each other.
  perform 1 from public.groups where id = new.group_id for update;
  if (select count(*) from public.rsvps where group_id = new.group_id) >= 200 then
    raise exception 'Guest limit reached for this lunch' using errcode = '22023';
  end if;
  return new;
end $$;
revoke all on function private.enforce_rsvp_limit() from public, anon, authenticated;
create trigger rsvp_limit before insert on public.rsvps for each row execute function private.enforce_rsvp_limit();
