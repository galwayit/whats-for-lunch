# Service configuration check — 6 October 2026 (Melbourne)

The Gemini, OpenAI, RevenueCat server key and RevenueCat project ID are present in
Supabase `lunch` (`cswdcbmywzzisovsgwac`). The RevenueCat key's SHA256 matches the
V2 key created for this project; the project ID digest matches `proj66f64377`.
The secret value was not printed, saved to disk, or included in this evidence.
Presence and matching fingerprints do not prove model access, quota or working requests.

## Remaining configuration

- `REVENUECAT_PRO_PRODUCT_IDS` is absent. It must list actual approved Apple
  subscription store identifiers. RevenueCat still shows only the Test Store SDK
  configuration; a real Apple app and subscriptions remain required for paid access.
- Apple account deletion configuration is absent: `APPLE_CLIENT_ID`,
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGN_IN_PRIVATE_KEY`.
- Push configuration `FCM_SERVICE_ACCOUNT_JSON` is absent.
- `REVENUECAT_ALLOW_APPLE_SANDBOX` is absent, so the new backend defaults to false.
  It is needed when testing genuine Apple sandbox purchases, not Test Store purchases.
- `ANTHROPIC_API_KEY` is optional while Google is primary and OpenAI is backup.

## Deployment state

The live project has 13 functions at version 6. It does not have `ai-config`,
`groups-update`, `groups-suggestions`, or `invitations-suggest`.
Read-only SQL confirms `system_parameters`, `ai_reservations`, `revenuecat_events`
and `group_suggestions` do not exist yet. The successful migration dry run lists
exactly these pending migrations:

1. `20261001035112_production_billing_security.sql`
2. `20261001140622_ai_provider_system_parameters.sql`
3. `20261001144342_group_invitation_planning.sql`

The original application functions, schema, system parameters and secrets were not changed.
The AI routing migration seeds `enabled: false`; adding provider secrets does not
deploy that migration or activate the new router.

## Live credential verification

A temporary diagnostic was prepared and passed Deno formatting/type checks at
`/private/tmp/lunch-service-check-20261006/supabase/functions/lunch-provider-check/index.ts`.
It requires the existing project service-role credential, accepts no arbitrary
URLs, uses fictional restaurant data, and returns only check results. It would make
one small generation request to Gemini and one to OpenAI, plus RevenueCat reads.

After an initial automatic approval rejection, the user explicitly approved the
temporary check and its removal. The diagnostic was deployed with exact project
server-key validation (supporting Supabase's current opaque secret keys). Missing
authentication and invalid-key requests returned 401. One authorised check ran
at 02:43:50 on 6 October 2026 Melbourne time, using only fictional restaurant data.

- Gemini `gemini-3.8-flash`: valid structured recommendation, 4.102 seconds,
  777 reported tokens.
- OpenAI `gpt-5.4-mini`: HTTP 403, 2.031 seconds. No usable backup response.
  Chrome subsequently showed that Responses write permission was already enabled,
  but project model access was limited to `gpt-5.6-luna` and
  `gpt-4.1-nano-2025-04-14`. The requested model was outside this allowlist.
- RevenueCat V2 product read: HTTP 200, three Test Store products (`monthly`,
  `yearly`, `lifetime`). This is not evidence of Apple product setup.
- RevenueCat subscription read for a deliberately nonexistent test customer:
  HTTP 404 `resource_missing`, the expected missing-customer response. No real
  paid entitlement was tested.

The diagnostic was deleted after the test. A fresh function inventory confirmed
its absence and the original 13 functions. The dashboard test's secret header and
temporary clipboard data were cleared before capturing evidence.

## OpenAI correction and verification

The unapplied AI migration seed and example configuration now select the existing
allowed `gpt-5.6-luna` model. No OpenAI permissions or project limits were changed.
The provider configuration validates, its migration seed matches the example, and
all 102 backend tests pass after the correction.

The private diagnostic was temporarily redeployed for an OpenAI-only retry. At
02:52:33 on 6 October 2026 Melbourne time, `gpt-5.6-luna` returned a valid structured
recommendation in 2.820 seconds, with 380 reported tokens. The function was removed
again immediately; the final function inventory confirms its absence and the
original 13 functions. See [openai-corrected-result.json](openai-corrected-result.json).

The active OpenAI key expires on 5 November 2026. Rotation is still required before
that date. Both AI provider keys/models have passed a small live fixture; automated
failover in the deployed app, real purchases, Apple revocation and push remain untested.

See [provider-check-result.json](provider-check-result.json) for the actual result.

See [verification.json](verification.json) for the machine-readable observations.
