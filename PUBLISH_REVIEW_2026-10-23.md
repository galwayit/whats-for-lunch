# Pre-publish code review and step list — 23 October 2026

Branch `native-migration` at commit 4296d80 (CI green on 19 October), compared against
[RELEASE_PLAN_2026-10-19.md](RELEASE_PLAN_2026-10-19.md). Seven reviewers read the code in
parallel (iOS build and privacy manifest, App Review guidelines, Android release, backend
security, shared core, listings and legal, release engineering), a researcher checked the
October 2026 store rules, every blocker and high finding was independently re-verified against
the tree, and a second round covered three areas nobody had looked at (Apple sign-in on the
hosted Supabase project, Google Places retention terms, the invite cold-start path). Nothing in
the repo or any account was changed.

**Verdict: still not ready for either store, but iOS is one engineering sprint plus your
account work away. The 19 October plan is sound in its order and ownership; it has four tasks
that would produce the wrong result as written and about fifteen items it does not know
about. Android remains a second release and has one new high-severity defect (the in-place
upgrade opens the wrong database file).**

---

## 1. What is verified fine

- Paywall structure meets 3.1.2: name, period, price from StoreKit via RevenueCat, benefits,
  Restore, Terms and Privacy links. Trial copy is data-driven and disappears when no
  introductory offer exists.
- Sign in with Apple sits above Google with the native button (4.8). AI consent is shown and
  versioned before any request on both platforms and names each provider (5.1.2(i)). Report,
  block and a support contact exist for group content (1.2). Account deletion is in-app on
  both platforms. No login wall: Discover, Track and guest RSVP work without an account.
- Release build is clean of DEBUG and DEMO code paths; a Test Store RevenueCat key cannot reach
  a Release archive; the preview core only starts with a launch argument.
- Backend: every money-spending or user-scoped function is authenticated or guest-token scoped,
  RLS denies anon on every table, the RevenueCat webhook uses a constant-time bearer check and
  idempotent snapshots, Apple token revocation runs before deletion, no PII in logs.
- Google Places content is scrubbed to place id plus "Saved place" before it reaches the
  on-device database, with a regression test. The backend cache is 24 hours.
- Android is already compliant with Play Billing Library 8 (purchases-kmp 3.9.0 pulls billing
  8.3.0) and the 16 KB page-size rule (the one native library is 16 KB aligned). Lint has no
  errors.
- Export compliance answer is "no" (TLS only); ITSAppUsesNonExemptEncryption=false is right.
- Legal pages exist, are dated, name every AI, maps, purchase and diagnostics processor, and
  describe deletion.

---

## 2. Where the 19 October plan is wrong

| Plan task | Problem | Do this instead |
| --- | --- | --- |
| 2.2 "hide the notification prompt, remove reminder claims" | The group reminder is a **local** notification (`GroupReminder.swift`); it works without Firebase. 2.2 would delete a working feature and leave the real push plumbing (Firebase Messaging link, `registerForRemoteNotifications`, `aps-environment` entitlement) in the binary, where its SDK privacy manifest adds Device ID and Analytics declarations the app never uses. | Keep the reminder; relabel it "Remind me an hour before" and read its state back from pending notifications. Remove the Firebase package, the Messaging delegate, the remote-registration call and the `aps-environment` entitlement. Drop the `--firebase` gate from `copy_runtime_config.sh` and its validator tests. |
| 4.1 "screenshots from the TestFlight build with -previewCore" | An App Store-signed build cannot run on a simulator or take launch arguments. And the preview data still prices Lunch Pro at A$2.99 / A$19.99 with a 7-day trial (`PreviewData.swift:168`, Android `PreviewCoreData.kt:208`); the committed paywall screenshots show "Start free trial". | Fix the preview fixtures and the two unit tests that pin them, regenerate, then capture from a simulator build. Capture the paywall for the subscription review screenshot (task 1.3) from a sandbox-signed device build so the real StoreKit price shows. |
| 1.8 "Ray runs make secrets" | `make secrets` pushes `supabase/.env`, which holds none of the seven Phase 1 names and would blank the live Gemini key. The Phase 1 values live in `supabase/.env.phase1`, whose header gives the right commands. | Use the two commands in that file's header, then `supabase secrets list` and compare names. |
| 5.5 "document production values in lunch.properties.example" | Nothing reads that file; the Gradle script reads only `-Plunch.*` properties and environment variables. Worse, `assets/` is packaged, so a filled copy would ship inside the APK. | Load a properties file from outside the tree (next to the keystore properties) in `build.gradle.kts`, and fail `bundleRelease` when any value is blank, not https, or the RevenueCat key does not start with `goog_`. Today a release with no properties builds fine and shows the "core not configured" developer screen. |
| 5.3 / 5.6 / 6.1 ordering | The Flutter app signed its release builds with the **debug** keystore, and nothing in the tree proves it ever reached Play. Generating a fresh upload key before checking Play Console can strand you behind an upload-key reset. | Do 6.1 first and record: does the package exist, highest versionCode, Play App Signing on or off, upload-key SHA-1. Then decide the key for 5.3 and whether 5.6 is even possible. |
| 6.7 "phone screenshots from the emulator" | Existing Android screenshots are 1080x2424 (2.24:1) with an alpha channel; Play rejects both. No feature graphic and no 512 px icon exist. | Capture at 1080x2160 or 1080x1920, flatten, and produce the 1024x500 feature graphic and 512x512 icon. |
| 3.11 "airplane mode" | Tested immediately, it passes; after more than an hour the Supabase token refresh fails, the core maps `RefreshFailure` to "no session" (`AuthRepositoryImpl.kt:42`), and a paying user sees Free limits and sign-in prompts. | Treat refresh failure as still signed in; extend 3.11 to "airplane mode after one hour, relaunch". |

---

## 3. New findings not in the plan

Severity: **blocker** = cannot build, sell or pass review; **high** = probable rejection or a
user-facing failure in 1.0; medium and low follow in section 6.

### iOS (before TestFlight)

| # | Severity | Finding | Fix |
| --- | --- | --- | --- |
| N1 | high | Apple sign-in on the hosted Supabase project is unproven. The project is "enabled" but nothing records `au.iapp.lunch` in the provider's Client IDs field or a real Apple sign-in on a device. Supabase rejects the token with "Unacceptable audience" if the field is wrong; reviewers tap the top button first. | Ray: Supabase → Authentication → Providers → Apple, confirm Client IDs. Then sign in with Apple on the existing Debug device build, including Hide My Email, before any Release work. Record it under release-evidence. |
| N2 | high | A guest who installs from the Smart App Banner and taps the invite link again sees five onboarding steps and no invitation (reproduced on the simulator). `ContentView` shows `OnboardingView`, which has no route presenter; Android already draws routes above onboarding. | Host the route stack above onboarding (move `.routePresenter(level: 0)` from `RootTabView` to `ContentView`), add a UI test with `-onboarded 0 -openInvite`, and extend plan 3.7 and 4.8 to "fresh install, never opened, tap link from Messages". |
| N3 | high | Terms of Use link is missing from the App Store Connect metadata. Apple requires it in the description or the EULA field for auto-renewable subscriptions; this is a routine 3.1.2 rejection. | Add "Terms of Use: https://lunch.iapp.au/terms/" and the privacy URL to the end of the description in task 4.2. |
| N4 | medium | `PrivacyInfo.xcprivacy` declares only UserDefaults, but `AppDiagnostics.swift:124` uses `systemUptime`, a System Boot Time required-reason API. | Add `NSPrivacyAccessedAPICategorySystemBootTime` with reason 35F9.1, or switch the rate limiter to a monotonic clock. Confirm with the archive's privacy report in 2.5. |
| N5 | medium | Camera and photo-library usage strings describe a meal-photo feature that does not exist in the native app. | Delete both keys from `Info.plist` and the photo sentences from the privacy page. |
| N6 | medium | Account deletion: any backend failure shows "couldn't reach the lunch service"; the Delete row is offered while signed out; success gives no feedback. Until the Apple secrets exist (1.7, 1.8) an Apple-linked reviewer hits this. | Map not-signed-in and server errors to honest messages with a support link; toast on success. |
| N7 | medium | Buttons labelled "Continue with Apple" on the paywall and the AI screen open the generic sign-in sheet, not Sign in with Apple. Apple's HIG forbids its name on a control that does something else. | Retitle to "Sign in". |
| N8 | medium | In-app Privacy screen says signing in copies meals to your account for restore on a new phone. Nothing syncs; the sign-in sheet and the web policy say the opposite. Same string on Android. | Rewrite `Copy.Info.privacyBody` and `info_privacy_body`. |
| N9 | medium | Apple's full name is never persisted after the first authorization, so Hide My Email users appear as a relay token in Profile and in invitations. | Call `updateUser` with `full_name` after the first Apple sign-in. |
| N10 | medium | Large-display screenshots are missing: the existing set is 1206x2622 with alpha. Apple needs 1320x2868 or 1290x2796 (or 1284x2778) flattened RGB. | Capture on an iPhone 17 Pro Max simulator and flatten. |

### Backend and operations (before App Review)

| # | Severity | Finding | Fix |
| --- | --- | --- | --- |
| N11 | high | The three Places functions are public with only a **global** daily cap (1000 searches, 3000 photos). Anyone with the functions URL can exhaust it at 00:01 UTC and black out Discover, AI picks and group proposals for every user until 10 am Melbourne. | Add a per-caller bucket (hashed IP plus user id) before `reserveUpstream`, restrict CORS to `https://lunch.iapp.au`, and set the Google Cloud quota to the same ceiling. Keep the 1.12 spend alert. |
| N12 | medium | Every protected request does a live RevenueCat v2 read before anything else (`tier.ts:27`), so a RevenueCat outage returns 502 for AI and hosting to free users too. | Trust the stored row when `reconciled_at` is fresh; reconcile only when stale, absent or just purchased. |
| N13 | medium | Gemini backup has returned HTTP 402 since 6 October; the plan never resolves it, so AI has one provider and a failed attempt burns a global slot. | Ray: fix Gemini billing, or set the backup to Claude with an Anthropic key, or set it to none deliberately. Re-check `ai-config` afterwards because the consent version changes. |
| N14 | medium | Anonymous RSVP inserts per invite link are unbounded; suggestions are capped at 200 per lunch but RSVPs are not. | One migration: a per-group RSVP ceiling in a trigger or RPC, plus a regression assertion. |
| N15 | medium | Nothing is scheduled: `cleanup_places_cache` is never run and `ai_requests`, `ai_reservations`, `upstream_usage`, `revenuecat_events` and reviewed reports grow forever. The privacy page gives no retention period. | One migration enabling pg_cron with a daily cleanup and 90-day ledger retention; state the period on the privacy page. |
| N16 | medium | Group venue name and address are stored permanently in `groups` and re-used in later AI prompts and on the public invite page. Google allows caching Places content other than ids for 30 days. | Store only the place id and re-fetch for display, or purge `place_address` and the past-picks read for groups older than 30 days. |
| N17 | medium | Hosted auth settings are hand-configured: `site_url` may still be localhost, leaked-password protection is off, rate limits unrecorded, and `supabase config push` would blank the Apple client id because `config.toml` uses env placeholders. | After 1.11: set Site URL, enable leaked-password protection, review rate limits (raise the custom-SMTP email limit above 30/hour for launch), and record the hosted values in `AUTH_SETUP.md`. Never run `config push` without fixing the file. |
| N18 | medium | No alerting of any kind and no runbook. Phase 7 is "watch daily". Android will ship with no crash reporting. | One Sentry alert rule to hello@iapp.au, a log drain on Pro, a one-page runbook (redeploy from tag, AI kill switch, PITR restore, limit variables, rollout halt threshold). Make Sentry Android required in 5.4. |

### Release engineering (before the first archive)

| # | Severity | Finding | Fix |
| --- | --- | --- | --- |
| N19 | medium | The submitted build cannot be reproduced from git: only tag is `flutter-baseline`, build numbers are command-line overrides, `main` still shows the Flutter tree, and the plan itself is untracked. | Commit the plan, fast-forward `main` to `native-migration`, set the build number in the project file, tag each archived commit, add tags to the CI trigger, record tag and SHA in release-evidence. |
| N20 | medium | CI never builds a Release configuration on either platform, so the archive gate, Release-only Swift, the Kotlin/Native release link and the R8-shrunk Android build are first exercised on one laptop on archive day. | Add a Release simulator build with signing disabled to the iOS job and `bundleRelease` plus `lintRelease` to the Android job. Pin the CI Xcode version. |
| N21 | medium | Every release input lives only on this Mac (Sentry token, release plist, two Apple `.p8` keys, the future upload keystore). | Escrow them in a password manager or encrypted off-machine backup and note the location (not the values) in HANDOFF.md. |
| N22 | medium | The leaked Google Maps key is still in `archive/flutter/COMPREHENSIVE_SECURITY_AUDIT_REPORT.md` on both branches; 1.2 only revokes it. | After revocation, delete the two lines on both branches and add a key-pattern grep (or gitleaks) to CI. |
| N23 | low | `deno.lock` is git-ignored, so CI and deploys resolve backend dependencies unlocked. `archive/flutter/.env.development` is tracked despite the ignore rule (placeholders only). | Commit the lock, run `--frozen` in CI, untrack the env file. |

### Android (Phase 5, before any Play upload)

| # | Severity | Finding | Fix |
| --- | --- | --- | --- |
| N24 | high | The in-place upgrade opens the wrong database. Flutter wrote `app_flutter/diet_buddy.sqlite`; the native app opens `files/diet_buddy.sqlite` (`LunchApplication.kt:72`). Every upgrading user starts empty and the orphaned Flutter file keeps full Google Places content forever. | Before `LunchCoreFactory.start`, move the file (with -wal/-shm/-journal siblings) from `getDir("flutter")` into `filesDir`, or open it where it is. Add a test seeded at the Flutter path. Then 5.6 can actually pass. |
| N25 | high | Google Play purchases can never unlock Pro. Both RevenueCat readers accept only `store === "app_store"` and the unit test pins Play as rejected. Phase 6.2 creates Play products but no task touches the backend. | Accept `play_store` in `revenuecat.ts` and `revenuecat-v2.ts`, decide how Play product ids (subscription plus base plan) are matched against the allowlist, extend the secret, replace the test with a Play fixture, update REVENUECAT.md and the terms page. Add a Play sandbox purchase to 6.8. |
| N26 | high | Denying location once dead-ends Home and Discover: no re-prompt, no Open Settings, onboarding completes regardless, and Android has no manual search-area picker at all. iOS routes to `SearchAreaView`. | Add the denied state with Open Settings and re-prompt, and decide whether Android 1.0 ships the search-area picker. |
| N27 | high | Profile upsell card hard-codes "Try free for 7 days" (`strings.xml:268`); the paywall itself is store-driven and safe. | Change to "See Lunch Pro" as on iOS; update `design/copy.md`, which still specifies the trial, backup-and-sync and a Gemini-only consent text. |
| N28 | medium | Profile shows a "Continue with Apple" button on Android; the sheet offers Google and email only. | Remove it. |
| N29 | medium | `POST_NOTIFICATIONS` is declared, the Profile Notifications row opens system settings, and the group reminder switch is a no-op on Android (local state only). The invite page also promises "reminders". | Remove the permission and the row, wire the switch to a local alarm or remove it, and change the invite page line. |
| N30 | medium | No `dataExtractionRules`: Android 12+ device-to-device transfer still copies the PayID text that the app promises stays on the phone, and the Keystore-encrypted guest tokens arrive without their key and crash on read. | Add extraction rules excluding both preference files; return null on a decrypt failure. |
| N31 | medium | Play's Data safety form needs a dedicated account-deletion URL naming the app and developer, steps, and what is kept. The support page has a section but the site answers every unknown path with the home page (no 404). | Add `backend/web/account-deletion/` and a `404.html`. |
| N32 | medium | Google sign-in on a Play-signed build needs Android OAuth clients for both the Play app-signing SHA-1 and the upload SHA-1; `NoCredentialException` is unhandled on devices with no Google account. | Owner creates both clients after 6.3; engineering records the ids and handles the exception. |
| N33 | medium | Terms, support and privacy pages are Apple-only (Apple EULA, "Apple account", "iPhone model") and never identify the trading entity or governing law. | Make the subscription wording store-neutral, add "Lei Ding trading as iAPP, ABN, Victoria", licence, termination and 13+ lines before 6.7. |
| N34 | low | Android ships as 2.0.0 while iOS ships 1.0.0; no monochrome icon layer; launcher PNG in a density-less folder. | Decide one public version string; add the monochrome layer. |

---

## 4. Store rules checked on 22 October 2026 that change assumptions

| Rule | What it means here |
| --- | --- |
| Play target API 36 has been required since 31 August 2026; the extension window closes 1 November. | Task 5.1 is mandatory before any upload, including internal testing. SDK Platform 36 is already installed; edge-to-edge and predictive back are already handled. |
| Play Billing Library 8+ required; 16 KB page size required for targetSdk 35+. | Already satisfied, no work. |
| Play personal accounts created after 13 November 2023 need a closed test with 12 testers for 14 days before production. | Depends on when the Play account was created and whether the Flutter app reached production. Check in 6.1; if it applies, budget two extra weeks before 6.9. |
| Apple requires Xcode 26 or later; Xcode 27.1 builds are accepted. Apps built with the iOS 27.1 SDK need iPhone Duo screenshots from April 2027. | Fine for 1.0; the first update after April 2027 needs the extra sizes. |
| Apple requires an Australian ABN with GST registration evidence; the DSA trader question must be answered even for AU-only distribution. | Plan 1.0 and 1.1 are right. Answer "not a trader" with EU storefronts deselected; adding the EU later means verifying as a trader first. |
| App Review purchases in the sandbox; TestFlight purchases are sandbox too. | `REVENUECAT_ALLOW_APPLE_SANDBOX=true` must be set before Phase 3 and stay true through every review of an update. |
| Supabase Free projects pause after a week of inactivity; built-in SMTP sends 2 emails an hour to team addresses only; custom SMTP defaults to 30 an hour. PITR needs at least Small compute. | 1.9 and 1.11 are launch blockers, not polish. Raise the email rate limit for launch day. Budget roughly A$215 a month for Pro plus Small compute plus PITR, or take Pro's daily backups without PITR. |
| Play account deletion needs an in-app path **and** a web URL that names the app and developer. | See N31. |

---

## 5. The ordered step list

Keep the 19 October plan's phases and owners. The entries below are the delta: **NEW** is not
in the plan, **CHANGE** replaces a plan task's wording. Everything else in the plan stands.

### Phase 1 — accounts (Ray), with three additions

1. 1.0 to 1.7 as planned (GST, tax, banking, revoke the Maps key, subscription group with
   `au.iapp.lunch.pro.monthly` and `.yearly` at A$4.99 and A$29.99, IAP key, RevenueCat Apple
   app and `appl_` key, webhook, Sign in with Apple key).
2. **NEW (N1)** Confirm the Supabase Apple provider has `au.iapp.lunch` in Client IDs, then
   sign in with Apple on the current Debug device build, including Hide My Email. Claude
   records the evidence.
3. **CHANGE (1.8)** Fill `backend/supabase/.env.phase1`, run the two commands in its header,
   then `supabase secrets list`. Include `REVENUECAT_PRO_PRODUCT_IDS` with both ids exactly and
   `REVENUECAT_ALLOW_APPLE_SANDBOX=true`. Confirm `REVENUECAT_PROJECT_ID` carries the `proj`
   prefix.
4. 1.9 SMTP and templates, then raise the auth email rate limit above 30 an hour.
5. 1.10 publish the OAuth consent screen. 1.11 Pro plan; decide PITR versus daily backups.
   Then **NEW (N17)** set Site URL, enable leaked-password protection, record rate limits.
6. 1.12 spend alerts. **NEW (N13)** resolve the Gemini 402 or choose the backup deliberately.
7. **NEW (N22)** after revoking the Maps key, Claude deletes the two lines on both branches.

### Phase 2 — iOS build (Claude), with the fixes folded in

8. **NEW (N19)** Commit the plan, fast-forward `main`, set `CURRENT_PROJECT_VERSION` to 10 or
   higher in the project file (2.3), tag before archiving.
9. 2.1 write `Lunch.Release.plist` from the example once the `appl_` key exists; the validator
   must pass.
10. **CHANGE (2.2)** Remove Firebase Messaging, the remote-registration call and the
    `aps-environment` entitlement; drop the `--firebase` archive gate and its tests; keep the
    local reminder, relabel it, read its state back; remove the Profile Notifications row or
    relabel it "Lunch reminders".
11. **NEW** Fix the preview fixtures and tests to A$4.99 / A$29.99 with no trial on both
    platforms, plus `FakeEntitlementRepository.kt`, `design/copy.md`, `design/screens.md`
    and the `start_trial_sandbox` Maestro flow. Regenerate the screenshot sets.
12. **NEW (N2, N4 to N9)** Route presenter above onboarding; SystemBootTime manifest entry;
    delete camera and photo usage strings; honest deletion messages and hide Delete when signed
    out; retitle the two "Continue with Apple" buttons; rewrite the in-app privacy text;
    persist Apple full name; treat token refresh failure as still signed in; pass the backend's
    `resetsAt` through the gate error.
13. **NEW (N20)** Add a Release simulator build to CI and pin the Xcode version. Run the full
    suite and the archive gate locally.
14. 2.4 docs: HANDOFF.md needs its sections 1, 5, 6, 7 and 8 rewritten (functions count,
    secrets, test counts, "nothing has been pushed", Android consent, prices, product ids,
    agreement status, Pro AI limit of 10 a day); README push lines and simulator name; the
    BUILD_NOTES relink note.
15. 2.5 to 2.8 as planned (signed archive, privacy report from the archive, dSYMs, TestFlight).
    **NEW (N21)** escrow the signing and config material off this Mac.

### Phase 3 — iOS qualification on the TestFlight build

16. 3.1 to 3.12 as planned, with these extensions: 3.3 includes Hide My Email; 3.4 buys the
    **yearly** product as well as monthly and confirms `groups-create` succeeds right after;
    3.7 and 4.8 use a fresh install that was never opened before the link is tapped; 3.11
    repeats after more than an hour offline; 3.12 notes that text scale is clamped at 2.0.
17. **NEW (N11, N12, N14 to N16)** Backend hardening ships with the Phase 2 deploy: per-caller
    Places limit and CORS restriction, fresh-snapshot shortcut in `tierFor`, RSVP ceiling,
    pg_cron cleanup and retention, group venue retention. Each is one migration or one function
    change with a regression test; the PostgreSQL job in CI covers them.

### Phase 4 — App Store submission

18. 4.1 capture from a simulator build at 1320x2868 (and keep a 1206x2622 set), flattened.
19. 4.2 write `design/store-listing.md`; the description states the 1 free / 10 Pro daily
    allowance, the prices, auto-renewal, and ends with the Terms of Use and Privacy URLs (N3).
    Settle "For" versus "for" in the app name across the site titles.
20. 4.3 fill App Privacy from the **archive's** privacy report, not from the app manifest.
    Expected answers: name, email, health (dietary), other financial info (budget), purchase
    history, precise and coarse location, other user content, user id, product interaction,
    and unlinked crash, performance and diagnostic data; tracking no. Age rating 13+ with
    user-generated content yes, health or wellness topics yes, alcohol references infrequent,
    unrestricted web access no. Trader status: not a trader, EU excluded.
21. 4.4 review notes: test account, sandbox purchase path, "subscriptions and Restore require
    the supplied account", the one-free-AI-request rule.
22. 4.5 to 4.8 as planned. **NEW (N18)** before 4.6: one Sentry alert rule, the runbook, the
    moderation owner and cadence recorded in release-evidence.
23. **NEW** Cloudflare: add a WAF skip for the legal pages and `.well-known` so non-browser
    clients (Apple's and Google's URL checkers) are not served 403.

### Phase 5 — Android build (after iOS is in review)

24. **CHANGE** Do 6.1 first: package exists or not, highest versionCode, Play App Signing
    state, upload-key SHA-1, account creation date (closed-test rule). Only then 5.3.
25. 5.1 target and compile SDK 36. 5.2 fix R8 (pin R8 9.1.29 or bump AGP), then run the
    shrunk, signed bundle through every screen on the emulator.
26. **NEW (N24 to N30)** Flutter database path migration with a test; Play store acceptance in
    both RevenueCat readers with a Play fixture; location-denied state and the search-area
    decision; "See Lunch Pro" and the copy deck; remove the Apple button; remove
    `POST_NOTIFICATIONS` and the Notifications row, wire or remove the reminder switch; data
    extraction rules and the guest-token decrypt guard.
27. **CHANGE (5.5)** Load production values from a git-ignored file outside `src/`; fail the
    release build on blank or non-`goog_` values; delete the assets example.
28. 5.4 make Sentry Android required (auto-init plus the Gradle plugin for mapping upload);
    archive `mapping.txt` per release regardless.
29. **NEW (N20)** `bundleRelease` and `lintRelease` in CI. 5.6 and 5.7 as planned, now with a
    Flutter install that is signed with the same key as the new bundle.

### Phase 6 — Google Play

30. 6.2 to 6.5 as planned, plus **NEW (N32)** two Android OAuth clients (app-signing and upload
    SHA-1) and both fingerprints in `assetlinks.json`.
31. 6.6 Data safety from the same sheet as App Privacy, with "shared" for location, health and
    user content sent to AI and maps providers, no ads, no device ids, crash logs if Sentry
    ships, and the account-deletion URL from N31. Identity verification, payments profile with
    ABN and GST status, trader declaration, public developer email.
32. 6.7 assets: 1080x2160 flattened screenshots, 1024x500 feature graphic, 512x512 icon, and
    the store-neutral legal pages from N33 deployed first.
33. 6.8 internal testing with a Play sandbox purchase of both products; if the closed-test rule
    applies, 12 testers for 14 days before 6.9.

---

## 6. Lower priority, after 1.0

- Supabase session tokens live in plain UserDefaults and SharedPreferences while guest tokens
  already use Keychain and Keystore; pass a secure session manager to the Auth plugin.
- An iOS database open failure (corrupt file) is an uncatchable Kotlin exception at launch and
  crash-loops with no Sentry event; add a throwing open step with a rename-and-retry.
- RevenueCat `logIn` failure at sign-in is logged and never retried, so a subscriber stays Free
  until they tap Restore; retry on foreground.
- The 24-hour local restaurant cache is wiped on every launch, so Discover is empty offline
  after a relaunch and favourites re-fetch on every cold start; batch the look-ups.
- Preview core, gallery and launch-argument switches are compiled into Release on both
  platforms; on Android any app can start `MainActivity` with the preview extras. Gate behind
  debug builds once the screenshot process no longer needs them.
- Gate copy "invite friends for free" inside a Pro gate reads as free hosting; group detail,
  group cards and invitation cards show Places name and address without Google attribution.
- Dependabot, osv-scanner and `deno lint` in CI; `SignOutScope.GLOBAL` on explicit sign-out;
  one retry on idempotent GETs.
- The live `ai.providers` routing row exists only in the production database; export it to a
  validated JSON file so a restore does not ship with AI disabled.

---

## 7. Decisions still yours

- Which PITR tier, if any, on Supabase Pro.
- Gemini: fix billing, switch the backup to Claude, or run with one provider.
- Android public version string (2.0.0 or 1.0.0) and whether Android 1.0 ships the manual
  search-area picker.
- Whether to keep the Android `applicationId` if Play Console shows the Flutter app never
  shipped; a new id would let iOS and Android match and remove the upgrade constraints.
- Who owns moderation and how often the open-reports query is run.
