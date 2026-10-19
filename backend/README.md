# Lunch backend

Supabase Edge Functions, Postgres migrations, and the public invite/support site.
See [API.md](API.md) for the contract and [the release review](../RELEASE_READINESS_2026-10-01.md)
for live account findings and outstanding setup.

## Existing project

Use the existing Sydney project `cswdcbmywzzisovsgwac`; do not create a replacement.
On 6 October 2026, all migrations through `20261001144342` and all 17 functions
were deployed after local regression tests and a restore check of the actual
public/private schema backup. Existing groups and RSVPs were preserved.
The previously provisioned settings survived the full migration.
AI is enabled with OpenAI `gpt-6-luna` as primary and Google Gemini as backup.
Gemini currently returns HTTP 402; its billing must be resolved before relying on
backup availability. The live authenticated AI, consent, quota and paid-denial
checks passed with a disposable account, which was removed afterwards.
See [deployment evidence](../release-evidence/2026-10-06/test-deploy-device/README.md).
Real Apple subscriptions, custom SMTP, Apple revocation and push remain separate
release dependencies; this deployment is not App Store release qualification.

## Local checks

Requires Deno 2, Supabase CLI 2, and Docker for SQL concurrency/RLS tests.

```sh
cd backend
make check
make test
docker run --detach --name lunch-review-postgres-local --env POSTGRES_PASSWORD=local-fixture-only --tmpfs /var/lib/postgresql/data postgres:17-alpine
# Wait for pg_isready before testing.
docker exec lunch-review-postgres-local pg_isready -U postgres
python3 tests/postgres_regression.py lunch-review-postgres-local
python3 tests/postgres_regression.py lunch-review-postgres-local --bootstrap-settings-first
docker rm --force lunch-review-postgres-local
```

The SQL runner only accepts the dedicated test-container prefix and creates a new
database each time. It tests concurrent quotas, refunds, replay, billing order,
duplicate events, function privileges, and RLS. It never uses production credentials.
The second run also verifies that provisioning AI settings ahead of the rollout
preserves operator model choices and audit history when all migrations later run.

## Configure before deployment

`production.env.example` names server configuration. Put real values in a secure,
git-ignored environment file. The current `.env` is incomplete; deploying blank
values does not configure working providers.

- Google Places: restricted server Places key and provider API quotas.
- AI: configure primary and backup provider keys in Supabase Secrets and runtime
  parameters using [AI_PROVIDERS.md](AI_PROVIDERS.md). The migration seeds a disabled
  Google/OpenAI route and a selectable Claude profile. Qualify actual model access,
  latency, output quality and provider billing controls before enabling.
- Apple native auth: Supabase accepts `au.iapp.lunch`. Deletion additionally needs
  `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, and a Sign in with Apple private
  key (PKCS8 PEM, escaped newlines supported). This is a separate key purpose from
  RevenueCat's In-App Purchase key.
- RevenueCat: configure the real App Store app, Apple In-App Purchase key, real
  monthly/yearly products, `pro` entitlement, and `default` offering. Provide a server
  API v2 key with only subscription and product read scopes, `REVENUECAT_PROJECT_ID`,
  the exact store product-ID allowlist, and the existing webhook bearer secret.
  See [REVENUECAT.md](REVENUECAT.md) for exact permissions and verification. Public `appl_` SDK keys belong in the app; server
  keys do not. Enable Apple sandbox explicitly for TestFlight/App Review acceptance.
  This never enables RevenueCat Test Store entitlements.
- Firebase: configure `au.iapp.lunch`, APNs credentials, real iOS
  `GoogleService-Info.plist` under `iosApp/LunchApp/Config/`, and server
  `FCM_SERVICE_ACCOUNT_JSON`. Confirm physical-device delivery after login and no
  delivery after logout/account switching.
- Invite base: `https://lunch.iapp.au/i/` in both backend and client configuration.

The existing RevenueCat webhook points to
`https://cswdcbmywzzisovsgwac.supabase.co/functions/v1/revenuecat-webhook`.
Keep all lifecycle events. It now verifies current subscriber state, rather than
granting access from event names. A TEST event checks transport only.

## Coordinated deployment

After backup/restore readiness and configuration have been verified:

```sh
cd backend
supabase migration list
supabase db push --dry-run --skip-vault
# Review the exact migration and linked project before the mutations below.
supabase secrets set --env-file /secure/path/lunch-production.env
supabase db push --skip-vault
make deploy-functions
```

Release the migration and all affected functions together. Schedule a brief
maintenance window: old and new quota writers must not overlap. The migration
clears rebuildable Places response caches, not journals or saved place IDs. Do not
roll back to client-selected identity or event-based Pro grants. Keep a database
backup and fix forward if those security-sensitive paths fail.

With controlled accounts and Apple sandbox purchases, verify purchase, restore,
renewal, expiry, refund, transfer, duplicate/delayed webhook, sign-out, account switch,
quota contention, Apple account deletion, and push delivery. Inspect function logs
without recording secrets or prompts. Local tests and TEST webhooks are not proof
that real purchases work.

## Static site and operations

Deploy `web/` through the existing hosting path after reviewing the updated privacy
and terms text. See [web/README.md](web/README.md) for routes and association checks.
Source changes do not prove the public policy or AASA file is live.

Before charging users, establish uptime/error alerts, provider cost alerts,
database backup/restore evidence, retention/cleanup for usage and event ledgers,
support ownership, and a provider outage response. The verified Supabase account
is on the Free plan; production capacity and backup capabilities remain unqualified.
