# Publish-readiness review — 19 October 2026

Branch `native-migration`, working tree as of 19 October 2026. Compared against the
[6 October audit](APP_STORE_PREPRODUCTION_REVIEW_2026-10-06.md) and its
[progress record](APP_STORE_READINESS_PROGRESS_2026-10-06.md); only items re-verified today are
stated as fact. Nothing in the app, backend or any account was changed by this review.

**Verdict: not ready to publish on either store.** The iOS code base is launch-grade and every
local suite is green, but the first real build is still blocked by configuration and commerce
setup that only the account owner can complete. Android is a full phase behind iOS and should be
treated as a second release.

## 1. What was verified today

| Check | Result |
| --- | --- |
| `:shared:desktopTest` | 151 passed |
| `:shared:testDebugUnitTest` | 41 passed |
| `:androidApp:testDebugUnitTest` | 66 passed |
| `:androidApp:assembleRelease` | Builds an **unsigned** APK (8.5 MB) with 40 R8 "cannot parse Kotlin metadata" warnings |
| `backend make check` + `make test` | Format and type checks pass, 112 tests passed |
| Web invitation regression (`backend/tests/web_invite_test.mjs`) | Passed |
| Release-config script tests (`iosApp/scripts`) | 15 passed |
| iOS `xcodebuild test` (simulator, Xcode 27.1) | 156 passed (145 unit + 11 UI), after a forced relink of the Kotlin framework; the first run failed on a stale framework cached from Xcode 27.0 |
| Archive gate (`copy_runtime_config.sh`, Release + install) | **Fails as designed**: `Lunch.Release.plist` is missing |
| Live Supabase project `cswdcbmywzzisovsgwac` | 18 Edge Functions ACTIVE; secret names listed below |
| Public pages `lunch.iapp.au` (privacy, terms, support) | Dated 6 October 2026; name Google, Gemini, OpenAI, Anthropic, Sentry, RevenueCat, Firebase; contact `hello@iapp.au` |

Live secret inventory (names only): `GOOGLE_PLACES_API_KEY`, `GEMINI_API_KEY`, `OPENAI_API_KEY`,
`REVENUECAT_SECRET_API_KEY`, `REVENUECAT_PROJECT_ID`, `REVENUECAT_WEBHOOK_SECRET`,
`INVITE_LINK_BASE` plus the platform `SUPABASE_*` values.

Still **absent**: `REVENUECAT_PRO_PRODUCT_IDS`, `REVENUECAT_ALLOW_APPLE_SANDBOX`,
`APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGN_IN_PRIVATE_KEY`,
`FCM_SERVICE_ACCOUNT_JSON`.

## 2. Repository state is itself a risk

- **Nothing has been committed since 23 September.** The tree holds 244 modified files, 132
  untracked files and one deletion: the whole of split-the-bill, QR invites, content safety,
  Sentry, the AI provider router, Google sign-in, five migrations and four review documents.
  The branch is 21 commits ahead of `origin/main` and has never been pushed, so CI has never
  run on this code. One bad `git checkout` loses a month of work.
- **A Google Maps key is still public.** `COMPREHENSIVE_SECURITY_AUDIT_REPORT.md` on
  `origin/main` (and `archive/flutter/` on this branch) contains an `AIzaSyA47…` key. The
  memory from 23 September flagged it; it has not been removed. Confirm it is revoked in Google
  Cloud, then delete the lines. Public history keeps the string regardless.
- **Two untracked files are not git-ignored** and will be committed by the next `git add -A`:
  `iosApp/LunchApp/Config/Sentry.plist` (public DSN, by design) and `config/google-oauth.json`
  (public OAuth client IDs, by design). Both are safe to commit; just decide deliberately.
- `HANDOFF.md` is stale: it says Android has no AI consent step (`AiConsentDialog.kt` exists and
  is wired), and its test counts predate the current suites.

## 3. iOS: blocked on owner actions, not on code

| # | Blocker | Evidence today | What closes it |
| --- | --- | --- | --- |
| 1 | No production configuration | `Config/` holds only `Lunch.plist` (Test Store key), the example and `Sentry.plist`. `Lunch.Release.plist` and `GoogleService-Info.plist` are absent; the archive gate fails. | Create `Lunch.Release.plist` with the `appl_` RevenueCat key and real OAuth IDs; add the Firebase plist or drop push (see 5). |
| 2 | Subscriptions are not sellable | Backend has no `REVENUECAT_PRO_PRODUCT_IDS`, so no real purchase can ever grant Pro; `REVENUECAT_ALLOW_APPLE_SANDBOX` is unset, so App Review's sandbox purchase would be refused. RevenueCat is still a Test Store project per the 6 October audit. | Owner: Paid Apps Agreement, tax and banking, subscription group with `au.iapp.lunch.pro.monthly` / `.yearly`, Apple app in RevenueCat. Then set both secrets (`…ALLOW_APPLE_SANDBOX=true` for review). |
| 3 | Apple-linked accounts cannot be deleted | `account-delete/index.ts` revokes the Apple token before deleting, and the four `APPLE_*` secrets are absent. Email and Google accounts delete fine. | Create the Sign in with Apple key, set the four secrets, test deletion with an Apple test account. Guideline 5.1.1(v). |
| 4 | Email flow unproven | The app asks for a verification code; the hosted Supabase templates were still link-based on 6 October. Not re-checkable from the repo. | Configure SMTP and the templates in `backend/supabase/templates/`, then prove sign-up and recovery with delivered mail. |
| 5 | Push is dead | No `FCM_SERVICE_ACCOUNT_JSON`, no Firebase plist. The app guards `FirebaseApp.configure` behind the plist, so it does not crash. | Either configure Firebase and APNs and test background delivery, or remove the notification permission prompt and any claim of reminders from the first release. |
| 6 | Store listing incomplete | Per 6 October: no build in TestFlight, no screenshots, no review notes, and the description promises unlimited AI (actual: 1 free, 10 Pro per day). Not re-checkable without App Store Connect. | Fix the copy, upload iPhone screenshots, add review account and notes. |
| 7 | Bundle id decision | iOS is `au.iapp.lunch`; the Flutter app shipped as `au.iapp.guesswhat.whatWeHaveForLunch`. Android kept its id. | Decide: new listing (current state) or keep the old id for an in-place upgrade. |

Smaller iOS items:

- `aps-environment` is `development` in the entitlements; Xcode rewrites it to `production` for
  App Store exports, but confirm it on the exported archive.
- Build is `1.0.0 (2)` in `project.pbxproj`; the 8 October device evidence was `1.0.0 (9)`, so
  set the build number deliberately before the first upload.
- Xcode moved to 27.1 since the last evidence. The cached Kotlin framework from 27.0 made the
  simulator build fail with "unable to resolve a compatible module: LunchCore" until relinked;
  CI builds fresh and is unaffected, but note it in `shared/BUILD_NOTES.md`.
- Supabase is on the free plan: no point-in-time recovery and no backups beyond daily. Move to
  Pro before taking paid subscriptions.

## 4. Android: a release phase, not a checklist

| # | Gap | Evidence today |
| --- | --- | --- |
| 1 | No release signing | `androidApp/build.gradle.kts` has no `signingConfigs`; the only artefact is `androidApp-release-unsigned.apk`. No keystore exists in or outside the repo. |
| 2 | Target SDK too low for Play | `targetSdk = 35`. Google Play requires new apps and updates to target API 36 from 31 August 2026 (extension to 1 November 2026). Today is 19 October. |
| 3 | R8 cannot read Kotlin 2.4.10 metadata | 40 warnings from the R8 bundled with AGP 8.11.1; `proguard-rules.pro` is empty. The shrunk build has never run on a device. Bump AGP or add keep rules, then test the release APK on the emulator. |
| 4 | App Links will not verify | `backend/web/.well-known/assetlinks.json` carries a placeholder fingerprint. Needs the Play upload-key SHA-256. |
| 5 | No push, no crash reporting | No Firebase or Sentry dependency on Android at all; `POST_NOTIFICATIONS` is requested anyway. |
| 6 | Runtime config | `BuildConfig` fields default to empty; a release needs `-Plunch.*` properties or environment variables at build time, and nothing documents the production values. |
| 7 | In-place upgrade untested | Same `applicationId` and `diet_buddy.sqlite` as the Flutter 1.0.0+1 build, `versionCode = 2`. No test installs the Flutter build and upgrades over it. |
| 8 | Play Console not started | No listing, data-safety form, screenshots upload or internal-testing track is referenced anywhere in the repo. |

Android positives: the AI consent dialog exists, account deletion and restore purchases are in
the Profile and Paywall screens, `allowBackup=false`, and the 66 unit tests pass.

## 5. Backend and web

Green and deployed. The only open operational items are the ones listed under iOS blockers 2,
3 and 5, plus:

- The 6 October evidence recorded a Gemini backup provider returning HTTP 402. No later record
  shows it resolved; re-check the provider route before launch.
- Daily request ceilings are the defaults (places 1000, photos 3000, AI 500). Set Google Cloud
  and OpenAI billing alerts to match.

## 6. Recommended order

1. **Today:** commit the working tree in a few logical commits, push, and let CI run. Remove the
   leaked Maps key from `origin/main` after confirming it is revoked.
2. **Owner (Ray):** Paid Apps Agreement, tax and banking, subscription products, RevenueCat
   Apple app, Sign in with Apple key, SMTP, and the Firebase-or-no-push decision. Decide the
   bundle id.
3. **Engineering:** write `Lunch.Release.plist`, set the seven missing secrets, archive, upload to
   TestFlight, and qualify one build end to end (sandbox purchase, restore, deletion, email,
   links, offline).
4. **Submit iOS.** Correct the listing copy and screenshots first.
5. **Android as phase two:** signing and Play App Signing, target SDK 36, R8 fix, assetlinks
   fingerprint, Play Console listing and data safety, then an internal-testing track.
