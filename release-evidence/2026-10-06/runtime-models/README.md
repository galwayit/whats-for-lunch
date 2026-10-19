# Supabase runtime model parameters — 6 October 2026

The requested settings are saved in Supabase project `lunch`
(`cswdcbmywzzisovsgwac`). Open the [system_parameters table](https://supabase.com/dashboard/project/cswdcbmywzzisovsgwac/editor/17772?schema=public),
then edit `value` on the row with `key = ai.providers`.

Current saved configuration:

| Setting | Value |
| --- | --- |
| Primary provider | `google` |
| Google free / Pro model | `gemini-3.8-flash` / `gemini-3.8-flash` |
| Backup provider | `openai` |
| OpenAI free / Pro model | `gpt-6-luna` / `gpt-6-luna` |
| Inactive alternative | Anthropic Claude |
| AI enabled | `false` — coordinated backend rollout still pending |

The row was saved at 10:15:55 am Melbourne time. Provider API keys remain in
Supabase Secrets; the new `OPENAI_API_KEY` timestamp was verified without reading
its plaintext. The key and GPT-6 Luna have not yet had a live generation test.

## What changed

- Provisioned `system_parameters`, `system_parameter_history`, the audit trigger,
  and the disabled `ai.providers` seed. The exact transaction is in
  [bootstrap-system-parameters.sql](bootstrap-system-parameters.sql).
- Updated the local example and the unapplied migration's OpenAI models to
  `gpt-6-luna` for both tiers.
- Made the settings portion of the unapplied migration preserve operator values
  and audit history when the complete migration later runs. Repeated preparation
  creates no phantom audit entries.
- Added a regression check demonstrating fresh database reads per request,
  per-tier model selection, unchanged in-flight snapshots and unchanged consent
  for a model-only edit.

## Verification

- Backend format/type checks passed; **103 tests passed**.
- Fresh PostgreSQL installation: **48 assertions passed**.
- Settings provisioned before full migration: **52 assertions passed**, including
  preservation of an operator-selected model across the subsequent full rollout.
- Live SQL confirmed the saved model values, RLS on both tables, no table access
  for `anon` or `authenticated`, service-role read/update access, and one seed
  history record. See [live-verification.json](live-verification.json).
- Security Advisor has no new warnings. Its existing leaked-password protection
  warning is unchanged.
- Chrome Table Editor displayed the saved provider models. The editor was viewed
  without changing or saving any additional values.
- The disposable test container was removed.

## Activation remains pending

This deployment changes only operator settings. No application function, billing
snapshot, user quota, secret, or existing user data was changed. The full migration
has not been marked applied; all three previous rollout migrations remain pending.

The secure AI handlers require the billing/quota migration and verified subscription
configuration. `REVENUECAT_PRO_PRODUCT_IDS` is still absent, and actual Apple
subscription configuration was not completed by this task. AI therefore remains
disabled. The database setting is ready for that rollout; the old deployed handlers
do not yet consume it.

After the backend router is deployed and enabled, changing only a model takes
effect on the next request with **no iOS/Android release or function redeploy**.
See [AI_PROVIDERS.md](../../../backend/AI_PROVIDERS.md) for the operator procedure,
validation and rollback details.
