# Tested deployment and Ray iPhone debug install — 6 October 2026

## Completed

- Supabase `lunch` (`cswdcbmywzzisovsgwac`): all three pending migrations applied;
  all 17 application functions are active. The thirteen original functions are
  version 9; four newly added functions are version 2. Maintenance responses have
  been replaced by the application handlers.
- AI enabled in `public.system_parameters`, row `ai.providers`: primary `openai`,
  backup `google`; OpenAI models are `gpt-6-luna` for both free and Pro. Model edits
  take effect on the next request without a mobile release or function deployment.
- Cloudflare Pages production deployment `56dbf96a`: `https://lunch.iapp.au`.
  Invitation scripts match the tested source; privacy includes OpenAI; the AASA
  response contains the correct team/bundle identity. All returned HTTP 200.
- Debug **1.0.0 (3)**, bundle `au.iapp.lunch`, development-signed with team
  `RYM9BD2B27`, installed and launched on Ray’s iPhone 12 Pro. Installation updated
  the existing app without uninstalling it. AppIcon is compiled into the bundle.
- Hosted email/password sign-in and email confirmation enabled. Password minimum
  8, OTP length 8, expiry 600 seconds. Google and Apple remained enabled.

## Validation

| Check | Result |
| --- | --- |
| Backend format/type checks | Passed |
| Backend Deno tests | 105 passed |
| Shared JVM tests | 141 passed |
| Shared Android tests | 37 passed |
| Android app unit tests and debug assembly | 62 passed; build succeeded |
| iOS simulator tests | 117 passed, including four UI tests |
| iOS configuration/security Python tests | 12 passed |
| PostgreSQL migration, billing, RLS and invitation assertions | 76 passed |
| Settings-first migration assertions | 52 passed |
| Web invitation workflow and design checks | Passed |
| Actual database backup restore plus pending migrations | Passed; existing row counts preserved |
| Code signing verification | Passed |
| Source hashes unchanged after testing | Passed |

Simulator screenshots in `ios-attachments/` show the corrected full-screen error
layout, invitation details/three choices and a guest suggestion awaiting review.
The iOS build emits existing upstream RevenueCat/Kotlin debug-symbol/module-cache
warnings; no build or test errors were reported.

## Live acceptance

`provider-results.json`: the replacement OpenAI key and `gpt-6-luna` returned a
valid fictional recommendation (4.633 seconds, 354 tokens). Gemini returned HTTP
402. This is why OpenAI was promoted to primary.

`failover-result.json`: real Gemini HTTP 402 failed over once to OpenAI, which
returned a valid recommendation (2.831 seconds, 359 tokens). The adapter now
handles payment-required provider failures, with a matching regression test.

`live-acceptance.json`: a temporary, confirmed fictional account signed in and
exercised the deployed HTTP endpoints. Consent disclosure returned 200; missing
consent returned 403; a consented recommendation returned 200; the next free-tier
request returned the daily-limit response; Pro hosting returned 403. The saved
attempt selected OpenAI `gpt-6-luna` as primary. This test bypassed email delivery
only by creating a confirmed fixture account; it did not bypass AI or billing gates.

`live-smoke.json`: all 17 routes responded without maintenance/5xx errors; nearby
restaurant search returned 20 results; public auth settings confirm email,
Google and Apple enabled, with email confirmation required.

The diagnostic required an existing project server key. Its unauthenticated
request returned 401. It was removed after testing (final endpoint returns 404).
All fixture records/accounts were removed; `remaining_test_accounts` is zero.
The original one group, one RSVP and two entitlement rows remain. Configuration
history grew from one entry to two for the primary/backup/enablement change.
The disposable local PostgreSQL container was removed.

Security advisors reported no new findings. The existing leaked-password
protection warning remains; the dashboard makes that feature a paid-plan option.

## Deployment safeguards and backup

A temporary 503/Retry-After response was verified on all 17 routes before waiting
150 seconds for older requests to finish. Migrations, functions and AI activation
then ran sequentially. The maintenance state was verified at 10:37:21 Melbourne;
AI activation completed at 10:40:31. The backup includes both `public` and `private`
(the latter holds RLS helpers), and was restored into a disposable local database
before applying the migrations there. Counts matched the source and remained
unchanged after the migration rehearsal.

The private backup is at `/private/tmp/lunch-predeploy-20261006` with mode-600
schema/data files; only hashes/metadata are included in this evidence directory.
This local snapshot is not a configured recurring or off-host production backup.
The signed device app is at
`/private/tmp/lunch-ray-debug-20261006/Build/Products/Debug-iphoneos/LunchApp.app`.
The simulator xcresult is `/private/tmp/lunch-validation-20261006-tests.xcresult`.

## Remaining release and manual-test limits

- Gemini backup is configured but currently unavailable with HTTP 402. Resolve its
  billing before relying on provider redundancy. No Google billing changes made.
- `REVENUECAT_PRO_PRODUCT_IDS` is absent and the debug SDK key is Test Store.
  An empty allowlist now safely gives the free tier after successful RevenueCat
  verification. Test Store purchases do not qualify for backend Pro access.
  Genuine Pro/group-hosting acceptance needs real Apple subscriptions, the Apple
  SDK key, an approved product allowlist and explicit Apple sandbox enablement.
  No real purchase, renewal, refund or transfer was qualified in this run.
- Custom SMTP and the prepared OTP confirmation/recovery templates are still
  required. Supabase’s current default template sends a link, while the app expects
  a code. SMTP must be configured before new registration/password-reset delivery
  can be tested successfully. No authentication email was sent in this run.
- Apple token revocation credentials, Firebase/APNs push, production release
  configuration, provider/account release requirements and App Store submission
  remain separate work. This run installed a development build; it did not submit
  or publish an App Store release.

Relevant code fixes made during this run: failover on provider HTTP 402 and
fail-closed free access when no paid product allowlist has been configured.
All existing unrelated working-tree changes were preserved; no Git commit was made.
