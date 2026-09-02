# Lunch backend (Supabase)

Edge functions, Postgres migrations and the static invite page for the Lunch
apps. The API contract is `API.md`; this file is the operator's guide.

```
backend/
  API.md                      contract (endpoints, shapes, tables, RLS, secrets)
  BUILD_NOTES.md              judgement calls and open items
  Makefile                    make check | test | deploy
  supabase/
    config.toml               project config (auth providers, function JWT flags)
    migrations/               0001 tables, 0002 RLS, 0003 SQL helpers
    functions/
      deno.json               strict TS + fmt settings
      _shared/                pure modules + tests (deno test)
      <function>/index.ts     one thin handler per endpoint
  web/
    invite/index.html         /i/<code> landing page
    .well-known/              universal links / app links (placeholders)
```

## Prerequisites

- Deno 2.x (`deno --version`)
- Supabase CLI 2.x (`brew install supabase/tap/supabase`)
- A Supabase project (free tier is fine to start)
- Google Cloud project with **Places API (New)** and **Generative Language API** enabled
- RevenueCat project with a `pro` entitlement
- Firebase project (for FCM) with a service account

## 1. Create and link the project

```sh
supabase login
supabase projects create lunch --org-id <org> --region ap-southeast-2 --db-password '<strong>'
cd backend
supabase link --project-ref <project-ref>
```

`config.toml` already declares the functions and their `verify_jwt` flags, the
Apple/Google auth providers (via `env(...)` placeholders) and local ports
(API 54321, DB 54322). For local work create `backend/supabase/.env` (git-ignored):

```
SUPABASE_AUTH_EXTERNAL_APPLE_CLIENT_ID=au.iapp.lunch
SUPABASE_AUTH_EXTERNAL_APPLE_SECRET=<apple client secret jwt>
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=<web-id>.apps.googleusercontent.com,<ios-id>.apps.googleusercontent.com,<android-id>.apps.googleusercontent.com
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=<google oauth client secret>
GOOGLE_PLACES_API_KEY=...
GEMINI_API_KEY=...
REVENUECAT_WEBHOOK_SECRET=<long random string>
FCM_SERVICE_ACCOUNT_JSON=<single-line service account JSON>
INVITE_LINK_BASE=https://lunch.iapp.au/i/
```

## 2. Apply migrations

```sh
supabase db push            # applies supabase/migrations/* to the linked project
```

Each migration ends with a `down:` comment block describing how to reverse it.
`0003` creates `generate_invite_code()`, `current_tier(text)`,
`increment_ai_usage(text, date, int)` and `cleanup_places_cache(interval)`.
Schedule the cleanup with pg_cron from the SQL editor:

```sql
select cron.schedule('places-cache-cleanup', '17 * * * *', $$select public.cleanup_places_cache()$$);
```

## 3. Set secrets

Never commit them. Either push the env file or set them one by one:

```sh
supabase secrets set --env-file supabase/.env
# or
supabase secrets set GOOGLE_PLACES_API_KEY=... GEMINI_API_KEY=... REVENUECAT_WEBHOOK_SECRET=... INVITE_LINK_BASE=https://lunch.iapp.au/i/
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json | tr -d '\n')"
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
by the platform automatically.

## 4. Deploy functions

```sh
make check      # deno fmt --check + deno check on every module
make test       # deno test (pure modules; no network)
make deploy     # supabase db push + supabase functions deploy <each>
```

`make deploy-functions` loops over the twelve functions. The JWT policy per
function comes from `config.toml` (`verify_jwt = false` for the public ones,
`true` for `groups-create`, `groups-propose`, `groups-confirm`, `account-delete`).

Smoke test:

```sh
curl -s "https://<ref>.supabase.co/functions/v1/places-nearby" \
  -H "apikey: <anon>" -H "Authorization: Bearer <anon>" -H "x-app-user-id: smoke" \
  -H "content-type: application/json" \
  -d '{"lat":-33.87,"lng":151.21,"radiusKm":2,"query":null}' | head -c 400
```

## 5. Auth providers

**Apple** (Supabase Dashboard -> Authentication -> Providers -> Apple):
- Client IDs: the iOS bundle id `au.iapp.lunch` (native sign-in sends an id token + nonce).
- Secret key: the client secret JWT generated from your Sign in with Apple key. It expires every 6 months; rotate it.
- Android uses Apple's web flow via the Services ID; add that id to the client id list as well.

**Google** (Providers -> Google):
- Client IDs: web, iOS and Android OAuth client ids, comma-separated, so id tokens from every platform validate.
- `skip_nonce_check = true` is set in `config.toml` because Google's native SDKs do not always support nonces.

The same values go in `supabase/.env` under `SUPABASE_AUTH_EXTERNAL_*` for the local stack.

## 6. RevenueCat webhook

In the RevenueCat dashboard -> Project -> Integrations -> Webhooks:

- URL: `https://<ref>.supabase.co/functions/v1/revenuecat-webhook`
- Authorization header value: `Bearer <REVENUECAT_WEBHOOK_SECRET>` (the same string you set as the secret)
- Events: leave all enabled. The function maps purchase/renewal events to `is_pro = true`,
  keeps access until `expires_at` for CANCELLATION / EXPIRATION / BILLING_ISSUE, and moves
  the row on TRANSFER. Unknown and TEST events return 200 without changes.

Use the "Send test event" button after deploying; expect `{"ok":true,"updated":0,"type":"TEST"}`.

## 7. Push (FCM HTTP v1)

1. Firebase console -> Project settings -> Service accounts -> Generate new private key.
2. Set the file's contents as `FCM_SERVICE_ACCOUNT_JSON` (one line).
3. Both apps call `POST /push-register` with their FCM token. iOS needs APNs configured in Firebase.

The sender signs the OAuth assertion with Web Crypto; no Firebase SDK is used.

## 8. Host the web folder

Serve `web/` from the invite domain (e.g. `lunch.iapp.au`) with these rules:

- `/i/*` -> `web/invite/index.html` (rewrite, not redirect)
- `/.well-known/apple-app-site-association` -> served as `application/json`, no redirect
- `/.well-known/assetlinks.json` -> served as `application/json`

Before deploying, edit the `data-*` attributes on `<main>` in `invite/index.html`
(functions URL, anon key, store links) and replace the placeholders in `.well-known/`
(Apple Team ID, Android signing SHA-256).

Example `vercel.json`:

```json
{
  "rewrites": [{ "source": "/i/:code", "destination": "/invite/index.html" }],
  "headers": [{ "source": "/.well-known/(.*)", "headers": [{ "key": "Content-Type", "value": "application/json" }] }]
}
```

Example Cloudflare Pages `_redirects`: `/i/* /invite/index.html 200`.

`INVITE_LINK_BASE` must match the hosted path (`https://lunch.iapp.au/i/`), and the
apps' `CoreConfig.inviteLinkBase` must match too.

## Local development (optional)

`supabase start` runs the full stack in Docker (ports from `config.toml`), then
`supabase functions serve --env-file supabase/.env` serves the functions with hot reload.
`supabase db reset` re-applies the migrations from scratch.

## Verification

```sh
make check   # Checked 45 files (fmt) + type check of every .ts
make test    # 48 tests, all pure (prompt snapshot, parser, geohash, haversine,
             # Places mapping, quota, RevenueCat mapping, invites, push JWT, errors)
```
