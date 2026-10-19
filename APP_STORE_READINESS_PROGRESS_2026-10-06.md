# App Store readiness implementation — 6 October 2026

**Not yet ready to submit.** This records implementation after the [pre-production audit](APP_STORE_PREPRODUCTION_REVIEW_2026-10-06.md); it is not App Store approval or signed Release acceptance.

## Implemented in this working tree

- Dietary filtering: unknown allergen information no longer counts as a verified match. Known allergen conflicts remain excluded even when verification is optional. Strict diet matching requires explicit support for every selected diet. Swift, shared Kotlin and the AI backend use these rules. In-app explanations and the preference switch make the limitation visible.
- iOS location denial: users can choose a suburb, town or address with Apple Maps without granting device-location permission. The chosen area persists locally, reaches discovery and AI/group search, and cannot be silently overwritten by a late GPS callback. Permission errors now offer an actionable area chooser.
- Group content safety: report/block controls on iOS and web, a conservative abuse-text filter, private report evidence, service-only moderation functions, database read/write restrictions, notification filtering and account-deletion cleanup. Anonymous identities remain isolated to an invitation; account blocks work across invitations.
- Published public disclosures cover Sentry, manual-area searches, shared-content reports and blocking. Operator instructions are in [backend/MODERATION.md](backend/MODERATION.md). An assigned human must monitor the queue and support mailbox; code is not operational coverage.

## Verification

- 143 iOS unit tests passed, including dietary safety and manual-area persistence.
- 151 shared-core tests passed, including guest-token isolation, location override and safety-request failure handling.
- 112 backend tests passed; Deno format/type checks passed.
- PostgreSQL 17 migration/RLS/invitation/content-safety regressions passed in a disposable container, using fictional data. These cover direct database attempts, anonymous blocking before RSVP, target validation, report idempotency, notification safety after cancellation, removal of accepted guest content and account deletion.
- The web invitation regression passed, including first-RSVP name validation after receiving a guest token, report retries, blocking and safe rendering.
- Seven iOS UI tests passed, including the area chooser and guest report/block choices. This makes 413 unit/UI tests, in addition to the database and web-script regressions.
- Migration history matches all prior local migrations. Dry-run identified only `20261006021055_group_content_safety.sql` as pending; it was then applied and its live ledger entry verified.
- Release preflight still fails on missing `Lunch.Release.plist`. No new signed Release archive exists.

## Deployment status

The tested migration and ten affected Edge Functions were deployed to `cswdcbmywzzisovsgwac`. All ten report ACTIVE. Live read-only checks confirmed RLS on both private tables, two restrictive content policies, no client access to reports/blocks or service-only moderation, and service access to the safety predicate. Unauthenticated/invalid endpoint probes returned the expected HTTP 400 without accessing real invitations or creating reports.

The web invitation controls and privacy/support/terms pages were published to the `lunch` Cloudflare Pages project, deployment `76cf0cbe`, and the updated public disclosures were verified in Chrome at `https://lunch.iapp.au`. This deploy also publishes the earlier local Sentry privacy disclosure. No genuine user report, paid purchase, account deletion or billable AI call was performed during live verification. The new iOS UI is built and tested in the simulator, but has not been installed on the physical iPhone or distributed through TestFlight in this work.

## Remaining submission gates

1. Business/tax: the owner reports signing the Paid Apps Agreement; Apple subsequently showed Pending User Info. Tax/banking remain incomplete. The supplied sole-trader ABN was active but not GST-registered when checked in ABN Lookup. The Apple ABN field is a draft only; no GST application or tax certification was submitted. The owner is deciding sole trader versus company.
2. Paid product configuration: create actual Apple subscription products, link a real Apple app/credentials in RevenueCat, set the product allowlist and deliberate Apple sandbox support, and obtain the Apple public SDK key for Release. The existing Test Store is not evidence of an App Store purchase.
3. Apple account deletion: configure Apple token-revocation credentials securely in Supabase and verify the complete flow with a dedicated Apple test account.
4. Email: align hosted verification/recovery templates with the native code-entry flow, configure suitable production delivery and prove receipt/recovery.
5. Push: configure Firebase iOS/APNs and the backend service account, then verify background/terminated delivery and routing. Do not remove the release checks merely to obtain a passing archive.
6. AI operations: recheck the previously failing Gemini backup and prove fallback with the configured primary/backup route. No new billable provider test was performed for these code fixes.
7. Submission materials: correct the store's unlimited-AI claim to the actual daily allowance; provide current screenshots, reviewer access, contact details and notes, and reconcile App Privacy with Sentry and the final binary. Owner declarations, including EU trader classification and export/tax answers, require accurate owner input.
8. Exact artifact acceptance: produce/validate/upload a signed Release, upload its matching debug symbols, and qualify that build with TestFlight purchases/restores, all login/deletion paths, real group safety, email, push, universal links, permissions, offline/provider failures and accessibility. Local preview tests do not establish these outcomes.

## Evidence

Non-secret logs and file hashes are saved under `release-evidence/2026-10-06/submission-readiness/`. No API key or signing private key belongs in this report or the app bundle.
