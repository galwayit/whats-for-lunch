-- 0001: tables for the Lunch backend (see backend/API.md "Tables").
-- Every table is written only by edge functions using the service role;
-- RLS is enabled in 0002 and helper functions live in 0003.

create extension if not exists pgcrypto with schema extensions;

-- Pro entitlement per RevenueCat app user id (mirrors RevenueCat webhooks).
create table public.entitlements (
  app_user_id text primary key,
  is_pro boolean not null default false,
  product_id text,
  expires_at timestamptz,
  source text not null default 'revenuecat',
  updated_at timestamptz not null default now()
);

-- Free-tier counters, one row per app user and local day.
create table public.usage (
  app_user_id text not null,
  day date not null,
  ai_requests integer not null default 0 check (ai_requests >= 0),
  primary key (app_user_id, day)
);
create index usage_day_idx on public.usage (day);

-- One row per Gemini call, for cost and error monitoring.
create table public.ai_requests (
  id bigserial primary key,
  app_user_id text not null,
  model text not null,
  tokens integer not null default 0,
  latency_ms integer not null default 0,
  ok boolean not null default true,
  error text,
  created_at timestamptz not null default now()
);
create index ai_requests_created_at_idx on public.ai_requests (created_at);
create index ai_requests_app_user_id_idx on public.ai_requests (app_user_id, created_at desc);

-- Nearby search cache: geohash cell (precision 6) + radius + normalised query.
-- payload holds the raw Place resources so distances can be recomputed.
create table public.places_cache (
  cell text not null,
  radius_km numeric(5, 1) not null,
  query text not null default '',
  payload jsonb not null,
  fetched_at timestamptz not null default now(),
  primary key (cell, radius_km, query)
);
create index places_cache_fetched_at_idx on public.places_cache (fetched_at);

create table public.place_details_cache (
  place_id text primary key,
  payload jsonb not null,
  fetched_at timestamptz not null default now()
);
create index place_details_cache_fetched_at_idx on public.place_details_cache (fetched_at);

-- Lunch groups hosted by a signed-in Pro user.
-- host_name is denormalised so the public invitation page never needs auth.users.
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users (id) on delete cascade,
  host_name text not null default '',
  name text not null check (char_length(name) between 1 and 80),
  scheduled_at timestamptz not null,
  area_lat double precision not null check (area_lat between -90 and 90),
  area_lng double precision not null check (area_lng between -180 and 180),
  radius_km numeric(5, 1) not null check (radius_km > 0),
  place_id text,
  place_name text,
  place_address text,
  invite_code text not null unique check (invite_code ~ '^[0-9A-HJKMNP-TV-Z]{8}$'),
  created_at timestamptz not null default now(),
  cancelled_at timestamptz
);
create index groups_host_id_idx on public.groups (host_id, scheduled_at desc);
-- invite_code already has a unique index from the constraint.

-- RSVPs: either a signed-in guest (guest_user_id) or a web guest (guest_token).
create table public.rsvps (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  guest_user_id uuid references auth.users (id) on delete cascade,
  guest_token text,
  display_name text not null check (char_length(display_name) between 1 and 60),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  responded_at timestamptz,
  unique (group_id, guest_user_id),
  unique (group_id, guest_token),
  check (guest_user_id is not null or guest_token is not null)
);
create index rsvps_group_id_idx on public.rsvps (group_id);
create index rsvps_guest_user_id_idx on public.rsvps (guest_user_id);

-- FCM tokens keyed by token; app_user_id links anonymous devices, user_id signed-in ones.
create table public.device_tokens (
  token text primary key,
  app_user_id text not null,
  user_id uuid references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_id_idx on public.device_tokens (user_id);
create index device_tokens_app_user_id_idx on public.device_tokens (app_user_id);

/*
down:
  drop table if exists public.device_tokens;
  drop table if exists public.rsvps;
  drop table if exists public.groups;
  drop table if exists public.place_details_cache;
  drop table if exists public.places_cache;
  drop table if exists public.ai_requests;
  drop table if exists public.usage;
  drop table if exists public.entitlements;
  -- pgcrypto is shared with other Supabase features; leave it installed.
*/
