# Lunch backend API

This describes the local implementation after the 2 October 2026 provider routing changes.
It does not confirm deployment. Base URL:
`https://cswdcbmywzzisovsgwac.supabase.co/functions/v1`.

## Authentication and limits

Clients send `apikey: <public key>` and `Authorization: Bearer <public key or user JWT>`.
Protected operations verify the JWT with Supabase Auth. `x-app-user-id` is a legacy
identifier and never authorises a purchase, quota, or account operation. AI needs a
signed-in account; browsing and invitation responses support guests. Anonymous
invitation requests may carry an invitation-specific `x-guest-token`.

Errors are `{ "error": { "code": "...", "message": "..." } }`. Key codes:
`SIGN_IN_REQUIRED` (401), `AI_DAILY_LIMIT` (402), `HOST_REQUIRES_PRO` /
`AI_CONSENT_REQUIRED` (403), `RATE_LIMITED` (429), `AI_UNAVAILABLE` (503), and retryable upstream errors.
JSON bodies are capped at 64 KiB, including streams without Content-Length.
API model timestamps are epoch seconds.

## Places

- `POST /places-nearby`: `{lat, lng, radiusKm, query?, maxPrice?, minRating?}`.
  Calls Google Places New; a query uses text search. Returns
  `{restaurants: [Restaurant], cached: false, fetchedAt}`. Distance is computed from
  the supplied location; filters run on the current response.
- `POST /places-details`: `{placeId}` → `{restaurant: Restaurant, reviews: [Review]}`.
- `GET /places-photo?name=places/.../photos/...&maxWidth=800`: proxies image bytes;
  the API key stays server-side; the response uses `Cache-Control: no-store`.

Provider responses are no longer persisted in backend cache tables. The migration
clears those rebuildable caches. Native clients retain place IDs in the database
and current responses in bounded process memory. Author credits and source links
travel with Google photos/reviews; content lacking required credits is hidden on iOS.
Global UTC daily request ceilings protect Places, photos, and all AI providers. These are
request limits, not a substitute for provider billing controls.

## AI

`GET /ai-config` returns `{consentVersion, providers: [{name, privacyUrl}]}` with
`Cache-Control: no-store`. It reveals only the current primary/backup recipients.
Clients fetch it before an AI request, display both recipients and the data shared,
and send the version that the user explicitly accepted. A recipient/endpoint/policy
change invalidates old consent; model changes and swapping the same two recipients
do not. The server validates consent against the same routing snapshot used by that
request, before any provider receives personal data. Missing/disabled settings or
no configured credential return `AI_UNAVAILABLE`.

`POST /ai-recommend` requires a verified account and:

```json
{
  "aiConsentVersion": "<current consentVersion from GET /ai-config>",
  "cravings": "something light",
  "maxResults": 3,
  "context": {
    "mealType": "lunch",
    "budgetRange": "$$",
    "dietaryPreferences": { "restrictions": [], "allergies": [] },
    "recentMeals": [],
    "location": { "hasLocation": false, "latitude": null, "longitude": null },
    "temporal": { "hour": 12, "dayOfWeek": 2, "isWeekend": false },
    "preferenceScores": {}
  },
  "candidates": []
}
```

The example leaves candidates empty to show the shape; actual requests require
1–20 restaurant candidates. The app fetches nearby candidates when none are selected.
It obtains consent before building/sending personal AI context. The consent field
records the client contract; it is not an authentication credential.

The backend reconciles the account's current RevenueCat subscriber state, then
atomically reserves a UTC daily allowance: **free 1; Pro 10**, with personal and
group suggestions sharing the Pro allowance. After the free request is used,
the next attempt opens the subscription paywall. A new UTC day restores the
free allowance. `AI_DAILY_LIMIT` includes `resetsAt`
at the next UTC midnight. Failed provider work refunds exactly its own reservation
once. IDs returned by any provider must belong to the candidate set.

Routing and per-tier models come from the service-only `system_parameters` row
`ai.providers`. Supported adapters are Google Gemini, OpenAI Responses, Anthropic
Claude and explicitly approved OpenAI-compatible chat completion endpoints. Each
request tries the primary and then at most one backup on timeout, network failure,
429/5xx, missing credentials, provider capacity, auth/model availability errors, or
invalid/truncated output. No failover follows a safety refusal or HTTP 400. Auth,
consent and user quota failures never call a provider. Each attempt counts toward
the global and profile limits; only one user allowance is charged on success, and
failure refunds it. Attempts are bounded at 10 seconds each; native AI requests
allow 60 seconds including billing verification, group Places and database work.
See [AI_PROVIDERS.md](AI_PROVIDERS.md) for settings, credential names and rollout.

Responses are
`{recommendation: AiRecommendation}`. The server's `userId: 0` is replaced with the
local journal user ID by the client.

## Groups and invitations

- `POST /groups-create`: `{name, scheduledAt, lat, lng, radiusKm}`. Verified Pro host
  required. Returns `{group: LunchGroup}` with a unique invitation code.
- `POST /groups-propose`: `{groupId, hostPreferences?, aiConsentVersion: "<current disclosure version>"}`.
  Verified Pro host and consent required. Reserves one of the shared 10 daily AI
  requests before Places/AI work; failures refund it. Returns `{proposals}`.
- `POST /groups-confirm`: `{groupId, placeId, placeName, placeAddress}`. Host-only;
  saves the chosen place and sends invitation pushes. Returns `{group}`.
- `POST /groups-cancel`: `{groupId}`. Host-only, idempotent cancellation, 204.
- `GET /invitations?code=ABCD1234`: public `{invitation: Invitation}`. A capability
  identifies the requesting anonymous guest's own response.
- `POST /invitations-respond`: `{code, status: "accepted" | "declined", displayName?}`.
  Signed-in responses belong to the verified account. Anonymous responses return a
  64-character hex `guestToken` for subsequent requests. Native clients persist it in
  Keychain/Keystore storage per invitation; the web page uses localStorage. Never log
  it or attach it to an unrelated invitation.

Hosts and their signed-in guests read relevant groups/RSVPs through RLS. The iOS
app refreshes visible groups periodically and surfaces errors explicitly.

## Push and deletion

`POST /push-register`: `{token, platform: "ios" | "android", action?: "unregister"}`.
A verified account is required. Unregistration removes only that account's matching
token. Native clients retain pending FCM tokens locally and register after login;
sign-out unregisters while the JWT is still valid. APNs tokens are not FCM tokens.

`POST /account-delete`: `{appleAuthorizationCode?: "fresh native Apple code"}`.
For Apple accounts, fresh authorisation is exchanged and revoked server-side, with
subject/audience/issuer/expiry checks. Only revocation progress is retained so a
failed database step can be retried; provider tokens/codes are not stored. Then
account-linked server records and the Auth user are removed. A local journal remains
on the device. Apple subscription cancellation remains a separate user action.

## Billing webhook

`POST /revenuecat-webhook` requires `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>`
and an event envelope with `event.id` and `event.type`.

Events trigger current `GET /v1/subscribers/{account-UUID}` reconciliation; event
types alone never grant access. Both sides of a transfer are reconciled. Duplicate
IDs are ignored atomically; older in-flight snapshots cannot overwrite newer ones.
Only configured products under entitlement `pro`, from `app_store`, with valid
expiry/grace and no refund unlock Pro. Test Store is always rejected. Apple sandbox
is accepted only when explicitly configured. `TEST` returns success without changing
access; that is not proof a real purchase works.

## Database and configuration

Migrations define `entitlements`, `usage`, `ai_requests`, `groups`, `rsvps`,
`device_tokens`, legacy caches, plus `revenuecat_events`, `ai_reservations`,
`account_deletions`, `upstream_usage`, `system_parameters` and `system_parameter_history`. Billing/quota/deletion tables and RPCs
are service-role-only with explicit grants. See migrations for columns and policies.

`production.env.example` lists required server secrets and optional limits. No
secret API key, Apple private key, or Firebase service account belongs in an app
bundle. `iosApp/LunchApp/Config/Lunch.Release.plist` holds public client configuration.


## Invitation planning (requires `20261001144342_group_invitation_planning.sql`)

Group payloads include `hostName`, nullable integer `budgetPerPersonMinor`, `currencyCode`
(current form supports AUD), `paymentArrangement` (`undecided`, `pay_own`, `split_equally`,
`host_pays`) and `paymentMethod` (`undecided`, `at_venue`, `cash`, `card`, `bank_transfer`).
The amounts are per-person estimates; the app does not collect payment. Missing legacy values
are explicitly shown as to be confirmed. `groups-create` accepts these as a `details` object.

- `POST groups-update`: `{groupId, details: {hostName, budgetPerPersonMinor, currencyCode,
  paymentArrangement, paymentMethod}}`. Verified host only; changes to cost/payment reset RSVPs.
- `POST invitations-suggest`: `{code, displayName?, suggestion: {placeName?, placeAddress?,
  scheduledAt?, note?}}`. A place, a future time (epoch seconds), or both is required. Uses
  the same JWT/256-bit guest capability as RSVP. New anonymous guests supply a name and receive
  `guestToken`, which must be persisted per invite and sent as `x-guest-token` on later calls.
  Returns `{invitation, guestToken?}`. The original RSVP is preserved. One pending suggestion
  per guest; a retried request returns that pending suggestion. A pending suggestion cannot
  be edited until the host reviews it. Ten submissions per guest and 200 per lunch maximum.
- `GET groups-suggestions?groupId=<uuid>`: verified host only. Returns `{suggestions: [...]}`.
- `POST groups-suggestions`: `{groupId, suggestionId, accept: boolean}`. Verified host only;
  returns `{group}`. Acceptance atomically changes place/time, clears a stale Google Place ID
  for a manually entered place, resets RSVPs, and marks other pending suggestions superseded.
  Decline preserves the current plan. Stale/replayed decisions fail without changing the plan.

Invitation reads and RSVPs include only the caller's latest `mySuggestion` (or null); hosts use
`groups-suggestions` to review the whole group. Suggestion wire values exclude RSVP IDs, user
IDs and capability tokens. Writes/RPCs are service-role-only with RLS and explicit grants.
A best-effort push alerts the host on first submission and signed-in guests when a proposal is
applied. Guests without push access must reopen/refresh the invitation; hosts should share the
updated link. Notification failure cannot undo a saved suggestion or plan change.

Verification: `deno test .` in `supabase/functions`, `node tests/web_invite_test.mjs`, and
`python3 tests/invitation_regression.py lunch-review-postgres-<disposable-container>`.
The database script creates fictional data in a fresh isolated test database; never point it
at a production database. Deploy the migration and all invitation/group handlers together;
new clients must not be advertised as supporting live suggestions against the old backend.
