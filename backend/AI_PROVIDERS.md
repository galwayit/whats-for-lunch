# Runtime AI system parameters

AI is selected on the server. An operator can change the main provider, backup,
per-tier models and limits without releasing another iOS or Android app. Users
cannot edit system parameters or see provider keys. The router and matching
account/billing/quota migrations were deployed on 6 October 2026. Live acceptance
passed for authenticated AI, consent, quota enforcement and Pro-access denial.
This does not qualify real Apple purchases. The migration preserves settings
already entered by an operator rather than resetting them to its seed.

## Settings

In the existing Supabase project `cswdcbmywzzisovsgwac`, open Table Editor →
`system_parameters` → row `ai.providers` → `value`. The migration seeds the
[example configuration](ai-providers.example.json) with `enabled: false`.
Use that JSON as the starting point. Keep API keys out of this row and source control.
Every edit records the before/after value in `system_parameter_history`.
The protected settings are live and enabled. OpenAI is primary; Google is backup.

### Change a model without an app release

1. Open Supabase **lunch → Table Editor → public.system_parameters**.
2. Open the `value` JSON for the row whose `key` is `ai.providers`.
3. Find the provider by `id` (for example, `openai`). Change `models.free` and/or
   `models.pro` to the exact model ID. OpenAI is currently configured for
   `gpt-6-luna` in both tiers.
4. Save the row. While the backend router is enabled, the next AI
   request uses this value. In-flight requests retain their original settings.
   Neither a mobile release nor a function redeploy is required for a model edit.

Keep `primary` and `backup` as provider IDs, not model names. The live values are
`openai` and `google`, respectively. Updating `OPENAI_API_KEY` in Secrets changes the credential; it does
not select a model. Updating the JSON model does not require replacing the key,
provided that key's project permits the selected model. Model-only edits preserve
the existing consent version because the companies receiving data are unchanged.

| Parameter | Meaning |
| --- | --- |
| `enabled` | Emergency on/off switch. Disabled returns a safe availability error. |
| `primary` | ID of the profile tried first. Live value: `openai`. |
| `backup` | ID tried once if the primary fails; `null` explicitly disables fallback. Live value: `google`. |
| `providers[].id` | Stable lowercase profile ID; letters, digits, `_` and `-`, max 32 characters. |
| `providers[].kind` | `google`, `openai`, `anthropic`, or `openai-compatible`. |
| `providers[].models.free/pro` | Model IDs for each tier. Verify access and quality in your paid project. |
| `providers[].timeoutMs` | 1,000–10,000 milliseconds per attempt; initial value 10,000. |
| `providers[].maxOutputTokens` | 256–4,096; includes provider-specific output/reasoning limits. |
| `providers[].dailyRequestLimit` | 1–10,000 attempts per profile, UTC day. Failed paid attempts still count. |
| `consentRevision` | Change when the data-sharing policy changes; always requires fresh permission. |

Primary and backup must be different profile IDs. Prefer different companies so
one vendor outage does not disable both. Model IDs are editable rather than tied
to a mobile release. The seed uses Gemini 3.8 Flash, GPT-6 Luna and Claude Haiku
4.5. The [GPT-6 Luna model documentation](https://developers.openai.com/api/docs/models/gpt-6-luna)
confirms Responses API and structured-output support. The replacement key and
GPT-6 Luna passed a live fictional recommendation and the deployed authenticated
AI endpoint on 6 October. Gemini 3.8 Flash currently returns HTTP 402, despite
passing an earlier check. Real Gemini-to-OpenAI failover was verified after adding
HTTP 402 to the retryable provider failures. OpenAI was then promoted to primary.
Resolve Gemini billing before treating the backup as available.
Claude remains unconfigured. A model change still needs an access, latency and
recommendation-quality check before relying on it in production.
Changing `backup` to `claude` selects the Anthropic profile. At most two profiles
receive a request; the remaining configured profiles are inactive.

The OpenAI model must also be in the API project's **Limits → Allowed models** list.
The user created the `whats-for-lunch` OpenAI project, enabled `gpt-6-luna`, and
replaced `OPENAI_API_KEY` in Supabase on 6 October 2026. The previous project's
`gpt-5.4-mini` request returned HTTP 403. A key can have Responses write permission and still be denied
by this separate project model restriction. Preserve the restriction and choose an
approved model rather than widening key permissions to fix a model mismatch.
The prior key's 5 November expiry does not describe the replacement key. The
new key's creation form was configured with Responses Write and no access to
other endpoints; the user completed creation and storage. See the earlier
[credential verification](../release-evidence/2026-10-06/service-activation/README.md)
for the scope of the old provider checks.

## Credentials

Add existing keys in Supabase → Edge Functions → Secrets:

| Adapter | Server secret |
| --- | --- |
| Google Gemini | `GEMINI_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Anthropic Claude | `ANTHROPIC_API_KEY` |
| Compatible API | A separate `AI_COMPAT_<NAME>_API_KEY` for each provider |

The existing Google Places key is separate and must not be reused as an AI key.
Provider keys are sent in headers, never query strings or app bundles. A backup
needs its own working credential and quota. Missing primary credentials can fail
straight to a configured backup; if both are missing no provider call is made.
`AI_DAILY_REQUEST_LIMIT` (secret, default 500, max 10,000) caps combined attempts
across all profiles. The total cap and profile cap are reserved atomically. These
are request ceilings; set provider billing/quota controls as well.

Built-in provider endpoints, display names, privacy URLs and secret names are fixed
by the adapter. A compatible profile must additionally set `name`, `privacyUrl`,
`endpoint` (the full HTTPS chat completions URL) and `secretEnv`. For example:

```json
{
  "id": "example",
  "kind": "openai-compatible",
  "name": "Example AI",
  "privacyUrl": "https://example.com/privacy",
  "endpoint": "https://api.example.com/v1/chat/completions",
  "secretEnv": "AI_COMPAT_EXAMPLE_API_KEY",
  "models": { "free": "your-model-id", "pro": "your-model-id" },
  "timeoutMs": 10000,
  "maxOutputTokens": 2048,
  "dailyRequestLimit": 100
}
```

Also approve that exact endpoint in `AI_ALLOWED_COMPATIBLE_ENDPOINTS` (comma-separated
HTTPS URLs, no queries/fragments/credentials/IP addresses). Redirects are refused.
The provider must support Chat Completions with strict `json_schema` output. An API
with a different protocol needs a new adapter; a URL alone cannot make it compatible.
Never put Supabase/service-role secrets in a compatible provider's secret slot.

## Validate, update and roll back

Validate a non-secret JSON file locally before using Table Editor or SQL Editor:

```sh
cd backend
deno run --allow-read scripts/ai-parameters.ts ai-providers.example.json
# After editing your copy, produce reviewable SQL, with proper escaping:
deno run --allow-read scripts/ai-parameters.ts ai-providers.example.json --sql > /tmp/lunch-ai-settings.sql
```

The output contains no credentials. Review the linked project and the complete JSON
before running that SQL. A valid update is picked up on the next request; each
in-flight request keeps one consistent configuration snapshot. Roll back by validating
and applying a prior `old_value` from `system_parameter_history`. Invalid settings
fail closed rather than silently sending personal data to an unexpected provider.

## Behaviour and consent

- A primary success never calls the backup. A timeout, network failure, 429/5xx,
  missing key, 401/403/404 availability failure, provider capacity, or malformed,
  truncated or unusable result triggers one backup attempt. HTTP 400 and explicit
  safety refusals do not trigger a backup. There are no automatic retry loops.
- One logical successful recommendation consumes one user allowance. If no usable
  result is produced, its reservation is refunded. Free accounts get one request
  per UTC day; Pro gets ten, shared between personal and group suggestions.
- Both providers use the same constrained output schema and candidate validation.
  Unknown restaurant IDs are filtered, duplicates removed and results bounded.
- Before sending context, the app fetches `GET /ai-config`, names all active
  recipients and links to their policies. The accepted version is sent with the
  request. Switching to a new recipient/endpoint or changing the policy revision
  invalidates old consent. Swapping the same two providers or changing only a model
  does not. iOS permission can be withdrawn in Profile; Android permission lasts
  for the current screen. Both re-check the current disclosure before a request.
- Server `ai_requests` records provider/model, attempt number, role, latency, tokens,
  safe failure category and logical request ID. It does not store the prompt or key.
  OpenAI Responses uses `store: false`. This does not promise provider-wide zero retention.

## Activation and acceptance

1. Complete the coordinated backend rollout in [README.md](README.md), including
   the verified RevenueCat server key and actual App Store subscription setup.
   The older deployed backend trusts client-selected IDs; do not enable billable AI
   on it. Production code deliberately rejects RevenueCat Test Store purchases.
2. Deploy the updated privacy page and the new iOS/Android consent flow.
3. Confirm both AI secrets are present, then choose qualified models and enable the
   reviewed `ai.providers` row. `GET /ai-config` must show the expected recipients.
4. With a controlled signed-in account, generate personal and group recommendations.
   Confirm a returned usable result and the matching successful `ai_requests` row.
   Check paid access with a verified Apple sandbox receipt when sandbox is enabled.
5. In a staging project, force a primary outage and confirm the backup succeeds,
   one user allowance is used and two attempts are recorded. Make both fail and
   verify the allowance is refunded. Change the backup recipient and verify a new
   consent prompt before another provider call. Do not deliberately break production
   credentials to simulate outages.

Local unit tests simulate these failures and database tests verify RLS and quota
concurrency. Neither proves real account credentials, latency or live model quality.

The adapters follow the current official [OpenAI structured output API](https://developers.openai.com/api/docs/guides/structured-outputs),
[Google GenerateContent structured output API](https://ai.google.dev/gemini-api/docs/generate-content/structured-output),
and [Anthropic structured output API](https://platform.claude.com/docs/en/build-with-claude/structured-outputs).

Ask AI includes one free request per UTC day using `models.free`. Lunch Pro
uses `models.pro` and has ten requests per UTC day, shared with group suggestions.
