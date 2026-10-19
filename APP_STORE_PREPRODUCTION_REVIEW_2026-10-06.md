# App Store pre-production review — 6 October 2026

Subsequent implementation and current release gates are recorded in [readiness progress](APP_STORE_READINESS_PROGRESS_2026-10-06.md). This audit retains its original observations.

**Verdict: not ready for App Store submission.** The core product has enough functionality to justify a native app, but its production configuration, paid subscription setup and several account/user flows are incomplete. Adding more features is not the priority; completing and proving the existing experience is.

This review covers the current working tree, the existing Debug artifact, focused automated checks, public pages, and read-only inspection of App Store Connect, Apple Developer, RevenueCat and Supabase in Chrome. No application code or account configuration was changed, no purchase was made, and nothing was submitted or deployed. The working tree contains substantial pre-existing work; Git HEAD alone does not identify the reviewed implementation.

**Priority and evidence**

“Confirmed” means observed in current source, files, test output or a live dashboard. “Review risk” means the implementation creates a plausible Apple review concern, not that Apple has already rejected it. “Unverified” means release acceptance evidence is still required.

| Priority | Finding | Evidence and completion condition |
| --- | --- | --- |
| Blocker | Production iOS configuration is absent | Release preflight fails because Lunch.Release.plist is missing. GoogleService-Info.plist is also missing; Debug uses a RevenueCat Test Store key. Supply validated production configuration, archive and validate the exact signed Release artifact. |
| Blocker | Apple subscription sales are not configured | RevenueCat is connected only to its Test Store. App Store Connect has no subscription group/products. Create the actual Apple products and connect them to RevenueCat, the app and the backend. |
| Blocker | Paid Apps Agreement is unsigned | App Store Connect shows “New” and “View and Agree to Terms”. The account owner must complete this, then verify banking/tax readiness. |
| Blocker | Apple-linked account deletion cannot complete | Four Apple revocation secrets are absent, and deletion calls revocation before removing the account. Configure and test the complete deletion flow. |
| Blocker | Email verification does not match the app | Hosted confirmation emails use a link; the native app requires a numeric code. Configure delivery/templates or implement the corresponding secure link callback, then test real emails. |
| Blocker | Submission has no build, screenshots or reviewer access details | TestFlight has no builds; the selected screenshot panel is empty; review contact and notes are blank. The description also incorrectly promises unlimited AI. |
| High | Unknown allergen data can receive full compatibility | Both recommendation engines score an absent allergen as compatible, even when the venue has no verified dietary data. Correct this before exposing allergy-based recommendations. |
| High / review risk | Shared group content has no report/block/moderation flow | Freeform names and suggestions can be shared with guests. Length and rate limits exist, but user safety controls were not found. |
| High | Denying location leads to a generic service error | Restaurant discovery requires device location; no manual-area fallback was found. Give users an actionable permission state and an alternative where practical. |
| High if retained | Push notifications are not operational | Firebase iOS configuration and the backend FCM service-account secret are absent. Prove notification delivery or explicitly remove the feature from the initial release. |

**1. Release configuration and the exact binary**

The release validator fails on the missing production plist. The archive script also requires a Firebase configuration and rejects RevenueCat Test Store keys. This is a failed prerequisite check; no new Release archive was attempted.

Sources: [archive configuration gate](/Users/rayding/galway/what_we_have_for_lunch/iosApp/scripts/copy_runtime_config.sh), [release validator](/Users/rayding/galway/what_we_have_for_lunch/iosApp/scripts/validate_release_config.py), [preflight result](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/app-store-preflight/release-preflight.log).

The target is au.iapp.lunch, team RYM9BD2B27, iPhone only, minimum iOS 18. Installed Xcode 27.0 and the previous Debug artifact's iOS 27 SDK meet Apple's currently published minimum SDK generation. That does not establish distribution signing or upload acceptance. [Apple SDK requirement](https://developer.apple.com/news/?id=ueeok6yw).

Before upload, align marketing version/build with the App Store version, inspect the final archive's configuration and privacy report, and validate its provisioning, production push entitlement and disabled debugging entitlement. A development APNs entitlement in source or a successful Debug install is not evidence of the final exported entitlements.

**2. Real subscriptions and server access**

The live RevenueCat project explicitly warns that it is connected to the Test Store. App Store Connect has no subscription group. Supabase lacks REVENUECAT_PRO_PRODUCT_IDS, so the backend's product allowlist cannot recognise a real Pro purchase. It also lacks REVENUECAT_ALLOW_APPLE_SANDBOX, leaving verified Apple sandbox purchases disabled under the current policy.

Sources: [billing policy](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/billing.ts:17), live RevenueCat project 66f64377 and App Store Connect app 6808090102.

Required work:

- Create the intended monthly/yearly Apple products in a subscription group, with complete pricing, localisation and review information.
- Connect a real Apple app in RevenueCat; configure its Apple credentials, products, offering and the canonical pro entitlement.
- Put the public Apple RevenueCat SDK key in the production app configuration; keep server keys in Supabase Secrets.
- Set the backend allowlist to the actual Apple product IDs. Support verified Apple sandbox entitlements for TestFlight and App Review while maintaining the existing identity/product/environment checks.
- Verify purchase, cancellation, pending transactions, restore after reinstall, renewal/expiry, refund/revocation, account transfer and corresponding server access. Verify the webhook path, not only the paywall badge.

Apple reviews purchases in the sandbox, so refusing sandbox subscriptions can leave reviewers unable to use Pro. Products do not need prior approval to function during review; the first subscription submission goes with the app. [Apple review purchase configuration](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases), [first subscription submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/).

The native paywall already has localised prices, subscription periods, renewal information, eligible trial handling, Restore, Terms and Privacy links. These are implemented positives, not proof that Apple's payment flow works.

**3. Commercial account readiness**

Apple membership is active, with renewal shown as 8 April 2027. The Free Apps Agreement is active. The Paid Apps Agreement remains “New”; it was not accepted during this review. An active paid agreement is necessary for paid purchases to function in review. Banking/tax completion was not independently established and must be checked after the owner completes the agreement. [Apple purchase prerequisites](https://developer.apple.com/help/app-review/before-submitting-for-review/configure-in-app-purchases), [tax information](https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information).

The app currently declares non-trader status. Because the intended product earns subscription income, the owner should reassess that declaration for any EU launch. This is an owner classification decision, not an automatic finding that the current declaration is unlawful. [Apple DSA guidance](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements).

**4. Account deletion and registration**

APPLE_CLIENT_ID, APPLE_TEAM_ID, APPLE_KEY_ID and APPLE_SIGN_IN_PRIVATE_KEY are absent from the live Supabase secret inventory. The deletion endpoint reads this configuration and revokes Apple authorisation before deleting an Apple-linked account. The current path therefore fails before deletion, despite the in-app deletion button and reauthentication UI being present.

Sources: [Apple configuration](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/apple.ts:11), [deletion sequence](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/account-delete/index.ts:19). Apple's account-deletion guidance also addresses associated data and Sign in with Apple token revocation. [Account deletion requirements](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

Test deletion for Apple, Google and email accounts, including retries and associated records. Confirm the user-facing explanation about an ongoing App Store subscription and locally retained journal data matches actual behaviour.

Supabase currently enables Apple, Google and Email providers, allows new users, and requires email confirmation. However, its email page says default templates are used until custom SMTP is configured. The confirmation preview contains a ConfirmationURL link, while the app asks for a 6–10 digit code and tells users a reset code will arrive.

Source: [native email flow](/Users/rayding/galway/what_we_have_for_lunch/iosApp/LunchApp/Features/Auth/SignInViewModel.swift:133).

Configure production email delivery and matching confirmation/recovery templates, or implement a secure callback flow that matches the delivered links. Validate signup, confirmation, expired codes/links, resend and password reset with delivered emails. Tests with pre-confirmed fixtures do not establish email delivery.

Google OAuth publication status could not be freshly verified because Google requested reauthentication. Do not treat “Testing” status alone as a universal sign-in blocker: Google's basic identity-only scope exception permits normal Sign in with Google without restricting users to the test list. Verify the app with an ordinary external Google account and review branding. [Google testing exception](https://support.google.com/cloud/answer/15549945?hl=en).

**5. Allergen handling needs a semantic fix**

Google Places results are mapped with empty allergen information and hasVerifiedDietaryInfo=false. Both engines then award 1.0 compatibility whenever the user's allergen is absent from that empty list. With an allergen-only preference, an unknown venue can therefore pass the verification-related threshold.

Sources: [unknown dietary data](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/places.ts:179), [shared filter and score](/Users/rayding/galway/what_we_have_for_lunch/shared/src/commonMain/kotlin/au/iapp/lunch/core/engine/RecommendationEngineImpl.kt:216), [Swift score](/Users/rayding/galway/what_we_have_for_lunch/iosApp/LunchApp/Core/Engines/SwiftRecommendationEngine.swift:178).

Absence of evidence must remain “unknown”, not become a safety score. Distinguish verified, unsuitable and unknown data; honour the verification preference; show a clear venue-confirmation message beside the recommendation. Add regression coverage for empty data and conflicting allergen evidence. A disclaimer buried in Terms would not correct the ranking defect.

This is a confirmed source-level defect and a safety/review risk, not a claim that the app has been clinically assessed or rejected. Apple's safety and accurate-metadata guidelines provide the relevant review context. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

**6. Group content and location fallback**

Group invitations and suggestions include guest/host names, place text, addresses and notes. Validation bounds their size and time, and database limits constrain volume. No content-reporting, user/guest blocking or moderation workflow was found.

Source: [suggestion input](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/group-planning.ts:41).

Implement reporting, abuse blocking and a removal/review process; alternatively, narrow the first release's shared inputs to a deliberately constrained experience and reassess the residual risk. Private invitations do not establish an exemption from Apple's user-generated-content expectations. Apple's guideline 1.2 is the relevant review reference. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

Location denial throws LOCATION_PERMISSION_DENIED; Home and Discover request current location before searching; the shared error view maps that condition to a service problem. Provide dedicated permission guidance and a manual suburb/address or area selection where practical. A user who skips an optional onboarding permission should not be left with an unexplained retry loop.

Sources: [location adapter](/Users/rayding/galway/what_we_have_for_lunch/iosApp/LunchApp/Core/KotlinLunchCore.swift:120), [Home search](/Users/rayding/galway/what_we_have_for_lunch/iosApp/LunchApp/Features/Home/HomeViewModel.swift:45), [error display](/Users/rayding/galway/what_we_have_for_lunch/iosApp/LunchApp/Features/Shared/LoadState.swift:40). Relevant policy: guideline 5.1.1(iv), permission choice and alternatives. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

**7. Push delivery and operational acceptance**

The iOS Firebase plist and backend FCM_SERVICE_ACCOUNT_JSON are absent. The server explicitly skips pushes without that secret. Configure Firebase/APNs and test a genuine push through background/terminated states and notification navigation, or deliberately remove the feature from the first release and adjust configuration gates and claims.

Source: [push skip behaviour](/Users/rayding/galway/what_we_have_for_lunch/backend/supabase/functions/_shared/notify.ts:18).

All 17 application Edge Functions are currently ACTIVE. That supersedes earlier observations of only 13 deployed functions. This audit did not make billable AI requests or prove current provider failover. A [preceding same-day check](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/test-deploy-device/README.md:47) recorded a Gemini backup HTTP 402; that remains an operational verification item until resolved and rechecked.

Supabase currently uses its Free plan. Apple does not mandate upgrading it. Production readiness does require suitable availability, recovery, monitoring and capacity: establish tested backups/restoration, failure alerts, usage/budget limits and an incident contact appropriate to the launch scale.

**8. Store listing, privacy and review access**

App Store Connect remains at version 1.0, Prepare for Submission. There is no selected build; TestFlight shows “No Builds”. The inspected iPhone screenshot panel has zero screenshots. Review contact and notes are blank, and sign-in access details are not supplied.

The description promises “unlimited AI picks”, but the implemented product provides one free request per UTC day and ten Pro requests per UTC day, shared with group suggestions. Correct the description, promotional material and any screenshots to the actual allowance.

Complete screenshots for the device sizes App Store Connect requires, support/contact details, review credentials/instructions for all gated features, and any export-compliance answers. Give reviewers a working backend and explain the free/Pro limits and sandbox purchase path. Metadata and full review access are covered by guidelines 2.1 and 2.3. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

Age ratings are already configured: 13+ in most regions, with regional/older-OS variants. App Privacy has a policy URL and 13 declared data types. This audit did not establish final publication/attestation of those answers. Reconcile them with the exact Release privacy report, actual data flows and third-party SDKs before attesting. Do not infer a mismatch merely because the app manifest and store form have different counts. [App Privacy guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy).

Privacy, Terms and Support render in Chrome. Simple non-browser probes received Cloudflare 403 responses, while Apple's association-file CDN returned HTTP 200 with the correct team/bundle and /i/* paths. That is not evidence that the site or universal links are broken. Keep public reviewer access and the actual installed-app link flow in final acceptance tests.

**Verified progress and limits**

- The 1024 × 1024 RGB icon has no alpha and is compiled into the inspected Debug app.
- The existing Debug build is 1.0.0 (5), previously installed on Ray's iPhone. It is not a distribution artifact.
- Twenty-two bundled privacy manifests were found in that artifact; the exact Release remains to be assessed.
- AI consent identifies the primary and backup recipients, supports revocation and changes its consent version when recipients change.
- Restaurant cards display Google attribution. The current photo store uses bounded transient memory, expires entries and clears on background/memory pressure; no new image-persistence regression was identified in this check.
- This review freshly passed 107 backend tests, backend format/type checks, 12 release-configuration tests and the web invitation suite.
- Earlier today, a separate run recorded 490 tests, including 128 iOS unit tests and one UI test. All 21 files in that run's feature-specific hash manifest still match. Those 490 tests were not rerun here and do not constitute full Release acceptance.
- No genuine Apple purchase, delivered verification email, destructive account deletion or new physical-device accessibility/permission test was performed in this audit.

Evidence: [audit files](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/app-store-preflight), [earlier test scope](/Users/rayding/galway/what_we_have_for_lunch/release-evidence/2026-10-06/ai-free-daily/README.md).

**Recommended release order**

1. Owner: complete the paid agreement and verify tax/banking and launch territories. Engineering: configure actual Apple subscriptions, production app settings, email, Apple deletion and push.
2. Engineering: fix allergen semantics, location denial and shared-content controls; correct the unlimited-AI claim.
3. Produce one signed Release archive, validate/upload it, then qualify that exact build through TestFlight. Test fresh install/update, all login methods, real sandbox subscriptions and backend access, account deletion, invitations/suggestions, push, denial/offline/provider failure, iOS 18/current iOS, large text and VoiceOver.
4. Complete screenshots, reviewer access, privacy attestation and subscription review information. Submit the app and first subscriptions together only after the acceptance record passes.

My recommendation is to keep the first release focused on dependable restaurant discovery, honest dietary information and useful group planning. The present feature set is sufficient; reliability and transparent paid value are the work that now determines launch quality. Apple makes the final approval decision.
