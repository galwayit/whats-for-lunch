# Production release plan — App Store and Google Play

Written 19 October 2026 from the [publish-readiness review](PUBLISH_READINESS_REVIEW_2026-10-19.md).
Branch `native-migration` is fully committed and CI is green, so everything below is setup,
configuration, qualification and store work. No new product features are planned before 1.0.

**Shape of the plan.** iOS ships first; Android follows as its own release two to three weeks
later. The two stores share the backend, the legal pages and the commerce accounts, so Phase 0
and Phase 1 serve both. Each task names who does it: **Ray** (needs your account, money or a
legal signature) or **Claude** (can be done from this repo once the inputs exist). Tasks are
ordered so that nothing waits on something later in the list.

Legend for the "Login" column: the account you have to be signed in to, or the thing you have to
authenticate, before that task can start. Claude cannot do these steps for you: the rules here
forbid me from entering passwords, creating accounts or accepting agreements, so each one is a
moment where you drive and I verify afterwards.

---

## Phase 0 — Decisions (half a day, Ray)

**Decided 19 October 2026: every default below stands.** Keep `au.iapp.lunch`; A$4.99 a month
and A$29.99 a year with no trial; no push in 1.0; sole trader; Australia only; Android as phase
two. Tasks marked "if D3 = in" are therefore skipped, and task 2.2 is required.

| # | Decision | Default if you say nothing | Why it matters |
| --- | --- | --- | --- |
| D1 | iOS bundle id: keep `au.iapp.lunch` (new listing) or revert to the Flutter id `au.iapp.guesswhat.whatWeHaveForLunch` (in-place upgrade) | Keep `au.iapp.lunch` | Reverting means a new App ID, new RevenueCat app, new AASA file and re-doing App Store Connect; keeping it means existing iOS users must install a new app |
| D2 | Prices and trial for Lunch Pro | A$4.99/month, A$29.99/year, no trial at launch | The A$2.99 / A$19.99 / 7-day numbers in the preview data were never costed; Apple takes 15–30 % and each Pro user can cost real Places and AI money |
| D3 | Push notifications in 1.0 | **Out** of 1.0 | Needs Firebase, APNs key, a service-account secret and real device testing on both platforms; invitations already work by link, QR and AirDrop |
| D4 | Trading entity: sole trader (current ABN) or company | Sole trader for 1.0 | Changes Apple's tax forms, the EU trader declaration and the Play developer account type; a change later means re-doing both |
| D5 | Territories | Australia only at launch | Narrows tax and DSA questions and keeps the review simpler; expand later |
| D6 | Android at launch or as phase two | Phase two | Android still needs signing, SDK 36, R8 work and a Play listing from zero |

---

## Phase 1 — Commerce and accounts (1–2 days of your time, spread over a week of Apple delays)

These are the hard blockers and every one needs you.

| # | Task | Who | Login | Done when |
| --- | --- | --- | --- | --- |
| 1.0 | **Register the ABN for GST** (voluntary, below the A$75,000 threshold). Apple requires GST registration from every Australia-based developer before it will sell paid apps, and Google Play charges unregistered Australian developers 10 % GST on its service fee. Keep a screenshot of the ABN Lookup page showing "Registered for GST" for Apple | Ray | ATO Online services for business (myGovID) or business.gov.au | ABN Lookup shows GST registered from a date on or before the Apple tax form |
| 1.1 | Paid Apps Agreement accepted on 19 October. Still to do: **tax forms** (ABN plus the GST-registration screenshot from 1.0, W-8BEN as a non-US sole trader) and **banking** | Ray | App Store Connect (Account Holder) | Agreements page shows Paid Apps **Active**; banking status Clear |
| 1.2 | Revoke the leaked Google Maps key `AIzaSyA47…` and confirm the Places key is restricted to the Places API (New) only | Ray | Google Cloud Console | Old key deleted; current key shows one API restriction |
| 1.3 | Create the **Lunch Pro** subscription group with `au.iapp.lunch.pro.monthly` and `au.iapp.lunch.pro.yearly`, prices from D2, localisation, review screenshot and notes | Ray | App Store Connect | Both products show "Ready to Submit" |
| 1.4 | Create an **In-App Purchase key** (Users and Access → Integrations → In-App Purchase) and note the Key ID and Issuer ID | Ray | App Store Connect | `.p8` downloaded to a safe place outside the repo |
| 1.5 | In RevenueCat project `66f64377`, add the **App Store app** for `au.iapp.lunch` / `6808090102`, upload the key from 1.4, import the two products, attach them to entitlement `pro` in offering `default` as `$rc_monthly` and `$rc_annual`, and copy the public `appl_` SDK key | Ray | RevenueCat dashboard | Offering shows two packages; `appl_` key in hand |
| 1.6 | Point the RevenueCat webhook at `https://cswdcbmywzzisovsgwac.supabase.co/functions/v1/revenuecat-webhook` with the existing authorization secret | Ray | RevenueCat dashboard | Webhook saved; test event returns 200 |
| 1.7 | Create a **Sign in with Apple key** (Certificates, Identifiers & Profiles → Keys) for account-deletion revocation; note Key ID | Ray | Apple Developer | `.p8` downloaded outside the repo |
| 1.8 | Set the backend secrets: `REVENUECAT_PRO_PRODUCT_IDS`, `REVENUECAT_ALLOW_APPLE_SANDBOX=true`, `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGN_IN_PRIVATE_KEY`, and the three daily limits | Ray runs `make secrets`; Claude prepares the env file template and verifies names afterwards | Supabase CLI (`supabase login`) | `supabase secrets list` shows all names |
| 1.9 | Configure **custom SMTP** (Resend, Postmark or SES) on the Supabase project and paste the code-based templates from `backend/supabase/templates/` into Auth → Email Templates | Ray | Supabase dashboard, plus the mail provider's console | A real sign-up email arrives with an 8-digit code |
| 1.10 | Publish the **Google OAuth consent screen** (move from Testing to In production) and confirm branding | Ray | Google Cloud Console | Status "In production" |
| 1.11 | Upgrade Supabase to **Pro** and enable point-in-time recovery | Ray | Supabase dashboard (billing) | PITR shows enabled |
| 1.12 | Set spending alerts: Google Cloud budget on Places and Gemini, OpenAI usage limit | Ray | Google Cloud Console, OpenAI platform | Alerts exist at agreed thresholds |
| 1.13 | *Only if D3 = in:* create the Firebase project, add the iOS app, upload the APNs key, download `GoogleService-Info.plist`, create a service account and set `FCM_SERVICE_ACCOUNT_JSON` | Ray | Firebase console, Apple Developer | Plist in `iosApp/LunchApp/Config/`; secret set |

---

## Phase 2 — iOS release build (2–3 days, mostly Claude)

| # | Task | Who | Login | Done when |
| --- | --- | --- | --- | --- |
| 2.1 | Write `iosApp/LunchApp/Config/Lunch.Release.plist` from the example with the `appl_` key and production URLs | Ray supplies the key; Claude writes the file | — | `validate_release_config.py` passes |
| 2.2 | If D3 = out: hide the notification permission prompt and the Firebase gate in `copy_runtime_config.sh`; remove reminder claims from `Copy.swift`; regenerate screenshots | Claude | — | Archive gate no longer requires the Firebase plist |
| 2.3 | Set `MARKETING_VERSION` 1.0.0 and a `CURRENT_PROJECT_VERSION` above the last device build (currently 9) | Claude | — | Project file updated |
| 2.4 | Update `HANDOFF.md` (Android consent, test counts, Xcode 27.1 relink note) and `shared/BUILD_NOTES.md` | Claude | — | Docs match the tree |
| 2.5 | Archive a signed Release and export for App Store; inspect entitlements (`aps-environment` production if D3 = in), the privacy report and the bundle's `Lunch.plist` | Claude builds; Ray must be signed in to Xcode | Xcode → Settings → Accounts (Apple ID with team RYM9BD2B27) | `.xcarchive` and `.ipa` produced; entitlements inspected |
| 2.6 | Upload dSYMs to Sentry with `iosApp/scripts/upload_sentry_symbols.sh` | Claude | Local `.sentryclirc` already present | Sentry shows the release `au.iapp.lunch@1.0.0+N` with symbols |
| 2.7 | Upload the build to TestFlight | Claude via `xcrun altool`/Transporter, or Ray in Xcode Organizer | App Store Connect API key or Apple ID in Xcode | Build appears in TestFlight "Processing" then "Ready to Test" |
| 2.8 | Add the `SENTRY_AUTH_TOKEN` secret to GitHub Actions so CI can upload symbols later | Ray | GitHub repo settings → Secrets | Secret exists |

---

## Phase 3 — iOS qualification on the real build (2–3 days, Ray on the phone, Claude on the backend)

Install the TestFlight build on your iPhone and work through this list with a **sandbox Apple
account** (App Store Connect → Users and Access → Sandbox Testers; create one, Ray). Claude watches
the Supabase logs and the RevenueCat customer page for each step and records the evidence under
`release-evidence/`.

| # | Scenario | Pass condition |
| --- | --- | --- |
| 3.1 | Fresh install, onboarding, deny location, choose an area manually | Discover shows real restaurants for the area |
| 3.2 | Email sign-up with code, sign out, sign in, recovery with code | Every email arrives within a minute; wrong and expired codes are rejected |
| 3.3 | Google sign-in, Apple sign-in | Both create a Supabase user; backend quota follows that user |
| 3.4 | Paywall: buy monthly in sandbox, see Pro in-app, see the entitlement row in Supabase | Webhook arrives; `entitlements` row is Pro with the right expiry |
| 3.5 | Delete the app, reinstall, Restore Purchases | Pro returns without a new charge |
| 3.6 | Cancel in sandbox settings, wait for expiry (sandbox renews every few minutes) | App drops to Free; backend row expires |
| 3.7 | Create a group, invite by link, QR and AirDrop; accept on a second device as a guest without an account | RSVP lands; host sees it |
| 3.8 | Report and block a guest suggestion | Row appears in the moderation queue (`backend/MODERATION.md`) |
| 3.9 | AI request as Free (1/day) then as Pro (10/day); withdraw AI consent | Limits hold; no request leaves the device after withdrawal |
| 3.10 | Delete account for an email user, a Google user and an Apple user | All three succeed; Apple token revoked |
| 3.11 | Airplane mode on Home, Discover, Track | Offline states, no crashes, Sentry quiet |
| 3.12 | Dynamic Type at the largest accessibility size, VoiceOver through Home and the paywall | Nothing truncated or unreachable |
| 3.13 | *If D3 = in:* push after login, none after logout, app in background and terminated | Notification arrives and opens the right screen |

Any failure goes back to Phase 2 for a fix and a new build; re-run only the affected scenarios.

---

## Phase 4 — App Store submission (1 day of your time, then Apple's review)

| # | Task | Who | Login | Done when |
| --- | --- | --- | --- | --- |
| 4.1 | Capture screenshots on the 6.9-inch iPhone simulator (and 6.5-inch) from the TestFlight build using the `-previewCore` launch argument | Claude | — | Six to eight PNGs per size in `iosApp/screenshots/store/` |
| 4.2 | Rewrite the description: replace "unlimited AI picks" with the real allowance; add subtitle, keywords, promotional text | Claude drafts; Ray approves | — | Text in `design/store-listing.md` |
| 4.3 | Fill App Store Connect: screenshots, description, support URL, privacy policy URL, age rating, **App Privacy** answers reconciled with `PrivacyInfo.xcprivacy`, export compliance, EU trader status per D4 | Ray | App Store Connect | Version page shows no missing items |
| 4.4 | Review notes: a test account with its password, the sandbox purchase path, and the one-free-AI-request rule | Ray (Claude drafts the text) | App Store Connect | Notes saved |
| 4.5 | Attach the TestFlight build and the two subscriptions to version 1.0; set **Manual release** | Ray | App Store Connect | Submit for Review enabled |
| 4.6 | Submit | Ray | App Store Connect | Status "Waiting for Review" |
| 4.7 | Handle review questions; if rejected, fix, rebuild, resubmit | Claude fixes, Ray resubmits | App Store Connect | "Pending Developer Release" |
| 4.8 | Release, then verify the live App Store link, the Smart App Banner on `lunch.iapp.au/i/…`, and a universal link on a fresh install | Ray releases; Claude verifies | App Store Connect | App installs from the store; invite link opens the app |

---

## Phase 5 — Android release build (3–4 days, Claude, after iOS is in review)

| # | Task | Who | Login | Done when |
| --- | --- | --- | --- | --- |
| 5.1 | Raise `compileSdk`/`targetSdk` to 36; fix anything that breaks (edge-to-edge and predictive back are the usual ones) | Claude | — | `assembleRelease` and tests green |
| 5.2 | Fix the R8 Kotlin-metadata warnings: bump AGP to the newest 8.x or 9.x that bundles an R8 aware of Kotlin 2.4, or add keep rules; run the shrunk APK on the `Lunch_Screenshots` emulator through every screen | Claude | — | No R8 warnings; release APK runs clean |
| 5.3 | Generate the **upload keystore** outside the repo (`~/.config/lunch/upload.jks`), add a `signingConfigs.release` block that reads `~/.config/lunch/keystore.properties`, keep both git-ignored | Claude | — | `bundleRelease` produces a signed `.aab` |
| 5.4 | Add the Android AI consent strings to `strings.xml` and a Sentry Android SDK if parity is wanted (optional) | Claude | — | Consent copy matches `design/copy.md` |
| 5.5 | Document the production `-Plunch.*` values (non-secret URLs, the `goog_` RevenueCat key once it exists) in `androidApp/src/main/assets/lunch.properties.example` | Claude | — | Example updated |
| 5.6 | Test the **in-place upgrade**: install the last Flutter build (`archive/flutter`) on the emulator, log a meal, install the new `.aab` over it | Claude | — | Meals survive; no crash on first launch |
| 5.7 | Run the Maestro flows once Maestro is installed (`curl -Ls https://get.maestro.mobile.dev | bash`) | Claude | — | Eight flows pass on the emulator |

---

## Phase 6 — Google Play setup and submission (1 day of your time)

| # | Task | Who | Login | Done when |
| --- | --- | --- | --- | --- |
| 6.1 | Confirm the Play developer account that published the Flutter app is still active and in the right entity per D4 | Ray | Google Play Console | Dashboard opens; the existing app is listed |
| 6.2 | Create the **RevenueCat Play Store app**, link it with a Google Cloud service account that has Play Developer API access, create the two subscriptions in Play (same ids, base plans monthly and yearly), import into RevenueCat, copy the `goog_` SDK key | Ray | Google Play Console, Google Cloud Console, RevenueCat | Offering shows Play packages |
| 6.3 | Enrol in **Play App Signing**, upload the upload-key certificate, copy the app-signing SHA-256 | Ray | Google Play Console | SHA-256 in hand |
| 6.4 | Put that SHA-256 into `backend/web/.well-known/assetlinks.json` and redeploy the site | Claude | Cloudflare (`wrangler login` on first use) | `https://lunch.iapp.au/.well-known/assetlinks.json` serves it; Play's App Links check passes |
| 6.5 | Register the release signing certificate's SHA-1 as an Android OAuth client in Google Cloud so Google sign-in works on the signed build | Ray | Google Cloud Console | Client exists; `config/google-oauth.json` updated by Claude |
| 6.6 | Fill the **Data safety** form from the same answers as App Privacy, content rating questionnaire, target audience, ads declaration (none), app access instructions with the test account | Ray | Google Play Console | No policy warnings |
| 6.7 | Listing: title, short and full description, feature graphic 1024×500, phone screenshots from the emulator, optional 7-inch and 10-inch tablet screenshots | Claude produces assets; Ray uploads | Google Play Console | Listing complete |
| 6.8 | Upload the `.aab` to an **internal testing** track; install on a real Android phone; run 3.1–3.12 with a Play licence tester account | Claude builds; Ray tests on the phone | Google Play Console | Scenarios pass |
| 6.9 | Promote to production with a staged rollout at 20 % | Ray | Google Play Console | Status "In review", then live |

---

## Phase 7 — Launch week

- Watch Sentry (`iapp-do/apple`), Supabase logs and the RevenueCat overview daily; Claude can pull these on request.
- Check provider spend after three days against the Phase 1.12 alerts.
- Keep `release-evidence/` updated with the exact build numbers that shipped.
- Open the first post-launch issue list from support mail at `hello@iapp.au`.

---

## Every moment you will need to log in or authenticate

In the order they come up:

1. **App Store Connect** as Account Holder — agreements, tax, banking (1.1), products (1.3), IAP key (1.4), sandbox tester, listing and submission (Phase 4).
2. **Google Cloud Console** — revoke the Maps key (1.2), publish the OAuth consent screen (1.10), budgets (1.12), Android OAuth client (6.5), Play service account (6.2).
3. **RevenueCat dashboard** — App Store app and offering (1.5), webhook (1.6), later the Play app (6.2).
4. **Apple Developer** — Sign in with Apple key (1.7), APNs key only if D3 = in.
5. **Supabase CLI** (`supabase login`) — to push secrets (1.8); **Supabase dashboard** — SMTP and templates (1.9), billing (1.11).
6. **Mail provider** (Resend, Postmark or SES) — create the account and domain records for `iapp.au` (1.9).
7. **OpenAI platform** — usage limit (1.12).
8. **Firebase console** — only if D3 = in (1.13).
9. **Xcode → Accounts** — your Apple ID must be signed in for the signed archive and upload (2.5, 2.7).
10. **GitHub** — the Sentry CI secret (2.8).
11. **Google Play Console** — everything in Phase 6.
12. **Cloudflare** (`wrangler login`) — the first time the site is redeployed from this machine (6.4).

I will say "your turn" at each of these in chat, with the exact page to open. After you finish one,
tell me and I verify the result from the CLI or the repo before moving on.

---

## Rough calendar

| Week | iOS | Android |
| --- | --- | --- |
| 1 | Phase 0 and Phase 1 (Apple agreement processing can take days) | — |
| 2 | Phase 2 build, Phase 3 qualification | Phase 5 starts once iOS is in TestFlight |
| 3 | Phase 4 submit; review typically 1–3 days | Phase 5 finishes |
| 4 | Release; Phase 7 | Phase 6 setup and internal testing |
| 5 | — | Production rollout |

The critical path is Apple's agreement and product setup, which only you can start. Everything
Claude does in Phase 2 waits on the `appl_` key from 1.5.
