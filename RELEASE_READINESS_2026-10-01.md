# Lunch production and paid-launch review — 1 October 2026

**Status: local remediation verified; paid launch and App Store submission remain blocked.**
No functions/migrations, website changes or store products were deployed in this run.
The authentication follow-up created Google OAuth clients and saved the hosted
Google provider configuration. No archive was uploaded or submitted. This report supersedes
the account-status assumptions in `PRODUCTION_REVIEW_2026-09-30.md`.

Reviewed the current dirty `native-migration` working tree and the signed-in Apple,
Supabase and RevenueCat accounts in Chrome with the owner's authorisation. Existing
split-bill, QR, design, configuration and other uncommitted work was preserved.
The pre-remediation source snapshot is `/private/tmp/lunch-remediation-baseline-20261001`.
The tests below cover the resulting working tree, not a clean committed release.

## Verified provider state

| Area | Observed state | Paid-launch consequence |
| --- | --- | --- |
| Apple membership | Active; team `RYM9BD2B27`, individual account, expiry 8 April 2027 | Membership alone does not enable subscriptions |
| App Store record | `au.iapp.lunch`, app `6808090102`, iOS 1.0 Prepare for Submission | No selected build; no screenshots or subscription groups/products |
| Paid Apps Agreement | New / unsigned in Business → Agreements | Must be accepted by the Account Holder; complete the resulting tax/banking requirements |
| Store review setup | Manual release selected; review contact/notes empty | Prepare accurate review instructions, contact details, privacy answers, screenshots and subscription review assets |
| EU distribution | Current DSA status is non-trader | Owner must reassess the attestation for the intended commercial activity/territories |
| RevenueCat | Project `66f64377`, “What's for lunch”; only Test Store | Current `test_` SDK configuration cannot take real Apple payments |
| RC products | `default` offering has Test Store monthly/yearly/lifetime packages; monthly/yearly now also grant canonical `pro` | Original `what_s_for_lunch_pro` identifier did not match the app; corrected after device testing. Actual Apple recurring products are still required |
| RC webhook | Active `lunch supa`, correct Lunch Supabase function URL; bearer auth configured; both environments/all events | Good routing evidence; masked secret equality and delivery are not yet proven |
| Supabase | `cswdcbmywzzisovsgwac`, Sydney, Free plan; 13 functions at v2 | Deployment predates this remediation; capacity/backup qualification outstanding |
| Supabase auth | Apple enabled for `au.iapp.lunch`; Google now enabled with real client IDs and nonce verification; email disabled | Google device testing remains pending; email still needs SMTP and hosted configuration |
| Supabase custom secrets | Places key, invite base, webhook secret present by name | Gemini, RC subscriber API, Apple revocation and FCM configuration are absent |
| Database | Remote migrations match local through `20260923000004` | Read-only `db push --dry-run` shows exactly `20261001035112_production_billing_security.sql` pending |
| Release bundle | `Lunch.Release.plist` and `Config/GoogleService-Info.plist` missing | Archive gate correctly blocks a release; no fake keys were inserted |

Chrome access was restored for the subsequent authentication work. Google Web, iOS
and Android debug OAuth clients were created and their IDs saved in Supabase and
shared native build configuration. Google's external consent app remains in Testing,
with two test users and only OpenID/email/profile scopes; Branding completion is
required before publishing. Custom SMTP and hosted email activation are still
missing. See [AUTH_SETUP.md](AUTH_SETUP.md) for current configuration and evidence.

## Gaps fixed locally

| Previous gap | Resulting behaviour and principal source |
| --- | --- |
| Client-chosen identity could select billing/quota access | JWT-verified Supabase identity owns protected requests. Purchase/restore awaits RC login to that exact account; signed-out/mismatched cached state is Free. `backend/supabase/functions/_shared/auth.ts`, `shared/.../service/AccountEntitlementRepository.kt` |
| Incomplete webhook events could grant permanent or stale Pro | Fetch current subscriber state, require exact `pro` + allowlisted Apple products, validate expiry/grace/refund/environment, reconcile transfer sides, deduplicate events atomically, reject older snapshots. `_shared/revenuecat.ts`, `_shared/billing.ts`, new SQL migration |
| Concurrent requests could evade the daily allowance | Atomic reservations, exactly-once refunds, shared personal/group quota, UTC boundaries and server provider ceilings. Free 1 / Pro 10 per day. `_shared/ai-access.ts`, `_shared/budget.ts`, new migration |
| Optional AI data sharing could bypass consent through groups | Versioned individual/group consent, refusal paths, withdrawal in iOS Profile, shared-core/backend guards. `AIDataConsent.swift`, AI/group view models, shared services |
| Main AI screen sent no candidates | Fetch nearby candidates and apply preferences before requesting AI; no requests on declined consent. `AiRecommendationServiceImpl.kt` |
| Paid promises exceeded implemented functionality | Removed backup/sync and unlimited-AI promises; store prices/durations and eligible trials control the paywall. Added genuine Pro multi-page PDF meal reports; free JSON export remains. `PaywallView`, `MealReportPDF.swift`, `ProfileViewModel.swift` |
| Guest RSVP identity was lost | Per-invitation capability persisted in iOS Keychain / Android Keystore-backed storage; serialized updates and scoped headers survive client restart. `GuestTokenStore`, `KtorBackendClient` |
| Apple account deletion did not revoke authorisation | Fresh native authorisation code, server exchange/subject checks/revocation, deletion-progress receipt for retries, clear subscription/local-journal disclosure. `_shared/apple.ts`, `account-delete`, native sign-in/profile code |
| Push registration did not follow login/logout | Secure pending token persistence, register on sign-in, unregister before logout, serialized late-token handling. `PushRegistrarImpl`, `AuthRepositoryImpl`, `push-register` |
| Google content lost credits and was persisted indiscriminately | Credits/source links carried through backend/Kotlin/Swift, iOS attribution beside displayed content, incomplete media hidden, persistent provider response caching removed, place IDs retained. `places.ts`, `RowMappers`, `DatabaseOpener`, `GoogleMapsAttribution.swift` |
| Group fetch errors could look like an empty list | Explicit load results/errors and foreground polling on iOS group/home screens. `GroupRepositoryImpl`, `HomeViewModel`, `GroupDetailViewModel` |
| Release/CI checks could give misleading success | Archive checks exact project/public-key structure and Firebase bundle; tests reject Test Store/server keys; CI preserves pipeline failures and exercises PostgreSQL invariants. `iosApp/scripts`, `.github/workflows/ci.yml` |
| Public source policy described unavailable sync | Updated local privacy/terms source for actual data flows, AI/group sharing, free export, deletion and recurring limits. **These website edits are not live.** |

The RPC migration also adds explicit role grants; new billing, deletion, quota and
upstream-budget tables/RPCs are inaccessible to anonymous/authenticated Data API
callers. The migration purges only the old rebuildable Places response caches.
It must be coordinated with the function deployment so old quota writers do not overlap.

## Verification

| Check | Result |
| --- | --- |
| Backend Deno format/typecheck and tests | **58 passed, 0 failed** |
| Shared Kotlin JVM tests | **128 passed, 0 failed** |
| Android unit tests and compilation | **49 passed, 0 failed** |
| Native iOS simulator suite | **95 passed, 0 failed**, Xcode 27.0, iPhone 17 Pro / iOS 26.5 |
| PostgreSQL 17 migration/concurrency/RLS suite | **24 checks passed**; 30 simultaneous free requests spent exactly one allowance; duplicate refunds/replayed IDs/older snapshots denied |
| Release configuration security tests | **6 passed** |
| Design colour guard / shell syntax / diff whitespace | Passed |
| Remote migration dry run | Succeeded; one pending migration; no remote change |
| Simulator build/run and paywall visual | Succeeded; layout inspected; **preview fixture prices/trial, not Apple product evidence** |

Machine-readable receipt: [verification.json](release-evidence/2026-10-01/verification.json).
Paywall visual: [preview image](release-evidence/2026-10-01/paywall-preview.jpg).

Purchase follow-up: corrected the live RevenueCat Test Store monthly/yearly mapping
to entitlement `pro`, preserving the original entitlement. Both apps now show
restore guidance when a completed purchase has no Pro access, safe store-specific
failure messages, and quiet cancellation. The shared account tests (5) and Android
paywall tests (6) passed. The iOS test build compiled, but the simulator runner
stalled twice without reporting test results; this follow-up does not claim an iOS
test pass. The signed Debug build was installed and launched on Ray’s iPhone with
existing app data preserved. Manual purchase retesting remains pending. See
[purchase-fix-verification.json](release-evidence/2026-10-01/purchase-fix-verification.json)
and [RevenueCat mapping proof](release-evidence/2026-10-01/revenuecat-pro-products-fixed.jpg).

Detailed temporary evidence remains at:

- `/private/tmp/lunch-remediation-backend-final.log`
- `/private/tmp/lunch-remediation-kotlin-final.log`
- `/private/tmp/lunch-remediation-postgres-final.log`
- `/private/tmp/lunch-remediation-ios-tests-final.xcresult`

No live purchase, provider acceptance, physical-device push/revocation, signed
Release archive, TestFlight, or App Review result is implied by these checks. The
Kotlin/Native/SKIE build emits upstream interop/symbol warnings; a signed Release
archive and symbolication check remain necessary.

## Paid product recommendation

Keep SwiftUI + Kotlin Multiplatform + Supabase + RevenueCat. The defects were in
identity, service boundaries and missing account setup; another framework or a new
receipt backend would add work without resolving those problems.

Launch two auto-renewing products in one **Lunch Pro** subscription group:

| Product | Proposed ID | RC package |
| --- | --- | --- |
| Lunch Pro Monthly | `au.iapp.lunch.pro.monthly` | `$rc_monthly` |
| Lunch Pro Yearly | `au.iapp.lunch.pro.yearly` | `$rc_annual` |

Both attach to entitlement `pro` in offering `default`. IDs are proposed setup
values consistent with the client fixtures, not products created in Apple. The
allowlist is configurable if the owner chooses different IDs.

Pro includes group hosting, up to 10 daily AI requests shared with group suggestions,
full meal history/insights, unlimited favourites and iOS PDF meal reports. Keep local
meal logging, basic discovery, free data export and guest RSVPs useful without paying.

Do not sell lifetime access for a product with recurring Places/AI/push costs. Do
not assume the preview A$2.99/month, A$19.99/year or seven-day trial is a viable or
approved price. Choose actual store prices after measuring store proceeds, provider
cost per active subscriber, support/refund cost and expected free-user usage. Start
with a simple monthly/annual offer; add a trial only after measuring its conversion
and cost. No income or conversion improvement has yet been measured.

Model IDs are configurable so a model lifecycle change does not require an app
release. Qualify an available model on JSON validity, useful recommendations,
latency and actual billed cost before changing the current defaults. Request ceilings
bound calls, not dollars. Anonymous discovery can still exhaust shared capacity;
provider quotas/alerts and abuse monitoring are required before public scale.

## Owner actions and release sequence

1. **In Apple Business → Agreements**, review and accept the Paid Apps Agreement,
   then complete Apple's required tax/banking setup. Review DSA trader status and
   intended territories. These are owner legal/financial attestations.
2. **Connect RevenueCat's App Store app** for bundle `au.iapp.lunch` / app `6808090102`.
   Its current form requires the Apple In-App Purchase `.p8` key, Key ID and Issuer ID.
   New private-key access and disclosure need owner confirmation; never paste keys
   in chat. Create the two Apple subscriptions, localisation, prices/availability,
   review screenshots/notes, and any deliberately chosen introductory offer. Import
   products into RC, attach `pro` and `default`, and use the resulting public `appl_`
   SDK key in the Release plist.
3. **Supply missing service configuration securely** using
   [production.env.example](backend/production.env.example): Gemini, RC server
   subscriber API, Apple Sign in revocation and FCM credentials. The Apple revocation
   key has a different purpose from the In-App Purchase key. Configure APNs/Firebase
   and the real `Config/GoogleService-Info.plist`. Owner-controlled Google/Firebase
   account acceptance has not been verified. Enable Apple sandbox for TestFlight/App
   Review; RevenueCat Test Store remains rejected in all environments.
4. **Qualify operations**, including database backup/restore, monitored provider
   quotas/costs, usage/event retention, error/availability alerts, support and recovery.
   Review intended changes in this dirty tree, commit a traceable release revision,
   and deploy the migration/functions together using [backend/README.md](backend/README.md).
   Publish the reviewed policy/site update and verify its live URLs and AASA file.
5. **Run real acceptance tests** on controlled accounts: new/returning/ineligible
   purchase, cancelled purchase, restore/reinstall, renewal, expiry, refund, billing
   grace, account switch/transfer, logout, webhook retries/order, signed-out denial,
   simultaneous quotas, AI consent/refusal/withdrawal, group guest restart, Apple
   deletion followed by sign-in, and push delivery after login but not logout.
6. **Archive the configured Release**, inspect bundle/privacy/entitlements and symbols,
   upload to TestFlight, test that exact build on a physical device, and capture the
   required App Store screenshot size. Existing 1206×2622 screenshots do not supply
   the required large iPhone screenshot slot. Fill review contact/notes, privacy
   answers, age rating, export compliance and subscription metadata, then submit the
   app with its first subscriptions. Manual release remains selected; public launch
   follows Apple's approval and release action.

App Store publication cannot be completed from local source changes alone. The
first concrete blocker is the unsigned Paid Apps Agreement; the next is real Apple
product/credential configuration, followed by exact-build acceptance evidence.

## Primary references used

- [Apple agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/): paid/IAP contractual setup.
- [Apple first In-App Purchase submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/): submission alongside an app version.
- [Apple account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/): Apple authorisation revocation and separate subscription handling.
- [RevenueCat webhooks](https://www.revenuecat.com/docs/integrations/webhooks): current subscriber reconciliation, duplicate handling and authenticated delivery.
- [Google Places policies](https://developers.google.com/maps/documentation/places/web-service/policies): persistent-content restrictions and attribution requirements.
- [Apple screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/): required upload dimensions.
- [Gemini lifecycle](https://ai.google.dev/gemini-api/docs/deprecations): verify model access/lifecycle with the production project before choosing a model.


## Authentication follow-up — 1 October 2026

Google sign-in and email/password registration are now implemented on iOS and
Android, with email verification and password recovery. Google's hosted native
provider is enabled, its three OAuth clients are created, and only basic sign-in
scopes are saved. Live settings confirm activation and reject an invalid Google
ID token. A successful device login, production Android signing client and Google
consent publishing are not yet qualified. Email activation still needs SMTP.
See [AUTH_SETUP.md](AUTH_SETUP.md) and the [auth verification receipt](release-evidence/2026-10-01/auth-verification.json).
The current auth changes pass 137 shared tests, 54 Android unit tests, two Android
Compose UI tests, 101 iOS unit tests, two iOS UI tests and twelve configuration tests.
Fresh Android debug and iOS simulator builds passed with the newly created client
IDs; their compiled settings and callback scheme match the shared public config.
The earlier backend/PostgreSQL and full native test suites were not rerun for the
public-ID/build-configuration follow-up. No successful live authentication, email
delivery, billing or publication has been claimed.
