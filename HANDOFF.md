# Handoff

Written 2026-09-23, on branch `native-migration`. Read `README.md` first for the layout and the
everyday commands. This document covers what the README cannot: what is actually finished, what
is deliberately fake, what will bite you, and what only Ray can unblock.

If you change something this document describes, change this document.

---

## 1. Where the project stands

Last updated 2026-11-18. The Flutter app has been rewritten as two native apps over one Kotlin
Multiplatform core. Both apps are feature complete against the screens in `design/screens.md`.
Demo builds run on in-memory sample data; a plain Debug build of the iOS app runs against the
live Supabase backend with real Google Places data (section 4a).

The iOS app is being prepared for its first App Store submission. What is left, who does it and
in which order is in `RELEASE_GAP_PLAN_2026-11-18.md`; the release-day commands are in
`RUNBOOK.md`; the listing text and screenshots are in `design/store-listing.md`. Android is a
second release.

| Area | State |
|---|---|
| `shared/` core | Complete. Domain rules, SQLite, backend client, purchases, auth, groups. |
| `iosApp/` | Every screen built. Version 1.0.0, build 10. No signed archive has been made yet. |
| `androidApp/` | Every screen built. Runs on an emulator. Not ready for Play (target API 35, no release signing). |
| `backend/` | 18 Edge Functions and 11 migrations, unit and database tested. |
| Live backend | Supabase `lunch` (ref `cswdcbmywzzisovsgwac`, Sydney, **Free plan, hibernates when idle**). 8 migrations applied; `20261118000001` to `20261118000003` are not applied yet and must go in before the next function deploy. Section 6 lists the secrets. No store products exist yet. |
| Website | `lunch.iapp.au` on Cloudflare Pages. The live privacy page is older than `backend/web/privacy/`; deploy it together with the backend. |

Green on 2026-11-18:

| Suite | Count |
|---|---|
| `:shared:desktopTest` | 158 |
| `:shared:testDebugUnitTest` | 41 |
| `:androidApp:testDebugUnitTest` | 66 |
| iOS `xcodebuild test` (unit and UI, from the `.xcresult`) | 163 |
| `cd backend && make test` | 129 |
| `backend/tests/invitation_regression.py` (PostgreSQL 17 in Docker) | 119 assertions |

`origin/native-migration` holds the branch up to commit 4fe09d7; newer commits are local until
they are pushed. `main` still shows the Flutter tree. The remote is **public**, so read
section 6 before you push.

---

## 2. The thing most likely to waste your day

**The Kotlin, SKIE, RevenueCat and Xcode versions are a single chain. Bump them together or not
at all.**

```
SKIE 0.10.14  →  needs Kotlin 2.4.10  →  Gradle >= 8.14.4
purchases-kmp 3.9.0  →  built against purchases-ios 5.89.0
purchases-hybrid-common 19.0.0 (Xcode SPM pin)  →  pins purchases-ios 5.89.0
```

Both halves must land on the same `purchases-ios`. The Kotlin side is in
`gradle/libs.versions.toml`; the iOS side is an SPM pin inside
`iosApp/LunchApp.xcodeproj/project.pbxproj`. Get it wrong and Gradle resolves happily, then the
**app link step** fails with undefined RevenueCat symbols. The Kotlin framework itself links
without the SDK because the interop is header-only, so a green framework build proves nothing.

Do not go back to `purchases-kmp 2.10.2+17.55.1`. It pins `purchases-ios 5.67.1`, whose
`PaywallColor.swift` does not compile under Swift 6.4. That is what forced the upgrade.

`shared/BUILD_NOTES.md` has the long version, including why an older Kotlin reports a missing
`.klib` that is sitting right there on disk.

---

## 3. Traps that already caught us

**Every Swift closure is main-actor isolated by default.** The iOS target sets
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Hand a closure to a system API that calls back off
the main thread and the app dies in `_dispatch_assert_queue_fail`, with no useful crash log. This
took the whole app down through the colour tokens, because SwiftUI resolves colours on its async
render thread. Mark such closures `@Sendable` and the enclosing function `nonisolated`. There are
about 54 `nonisolated` annotations in the iOS code, all for this reason.

To debug this class of crash, a plain stack gives you frame 0 and nothing else. Do this instead:

```bash
xcrun simctl launch --wait-for-debugger <simulator-udid> au.iapp.lunch
lldb --batch -p <pid> -o "breakpoint set -n _dispatch_assert_queue_fail" -o continue -o "bt 40"
```

**`commonMain` cannot use JVM-only APIs.** `putIfAbsent`, `computeIfAbsent`, anything `java.*`.
Desktop and Android compile them fine; only Kotlin/Native rejects them, so you find out late.

**Dart rounds half up, most platforms round half even.** Ratings and distances shown to the user
must match the Kotlin engine's reason strings byte for byte, or the same restaurant reads 4.2 in
one place and 4.3 in another. Use `toFixed1` in `au.iapp.lunch.core.platform` (Kotlin),
`DartNumberFormat.swift` (iOS) or `dartOneDecimal` in `ui/components/Formatting.kt` (Android).
Never `String.format`, `DecimalFormat` or `%.1f`. The three implementations are pinned to the
same vectors in `shared/src/commonTest/resources/fixtures/engine_vectors.json`.

**Simulator names and UDIDs die with every Xcode release.** Resolve one at run time. CI already
does; copy that snippet rather than hardcoding.

---

## 4. How the demo builds work

Both apps ship a preview core: a complete in-memory implementation of every contract, with
simulated latency. It is what every screenshot and most tests run against.

On iOS, a build with the `DEMO` compilation condition turns the preview core on by default and
switches location to the real device:

```bash
xcodebuild -project iosApp/LunchApp.xcodeproj -scheme LunchApp -configuration Debug \
  -destination 'platform=iOS,id=<device-id>' \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEMO' build
xcrun devicectl device install app --device <device-id> <path>/LunchApp.app
xcrun devicectl device process launch --device <device-id> --terminate-existing au.iapp.lunch
```

The sample restaurants are written around a fixed Sydney anchor. `PreviewLocale` translates the
whole set to wherever the phone is and rewrites the locality from one reverse-geocode, so a demo
in Melbourne shows Melbourne addresses. Street names stay invented on purpose. A run started with
`-previewCore` keeps the anchor, which is what makes screenshots reproducible. If you add a call
site that reads `PreviewData.restaurants` directly, route it through `PreviewLocale` or it will
silently disagree with every other screen.

Launch arguments drive the rest: `-isPro`, `-signedIn`, `-offline`, `-aiUsedToday`, `-onboarded`,
`-openInvite`, `-openRoute`, `-gallery`. Android takes the same switches as intent extras.

**Android has no equivalent of the device-location work.** Its preview core still answers with the
Sydney anchor. Known gap, not a bug to rediscover.

### 4a. Debug builds against the live backend

Build Debug **without** `DEMO` and fill the git-ignored `Lunch.plist` (Supabase URL, legacy anon
key, functions URL, RevenueCat key). The project lives in Supabase organisation "ray2ding's Org";
the CLI must be logged in to that account (`supabase login`) to deploy. The database password is
in `~/.config/lunch/supabase-db-password`, outside the repo.

In Debug builds only, an empty RevenueCat key starts the core with purchases turned off
(`PurchasesDisabledEntitlementRepository`): the user stays free and the backend sees a stable
per-install `debug-<uuid>` id from user defaults. Release builds and the core both refuse to start
without a key. The current `Lunch.plist` holds a RevenueCat **Test Store** key (`test_`), which
simulates purchases and must never ship in a release build.

Release builds cannot pick it up. The build phase "Copy runtime config"
(`iosApp/scripts/copy_runtime_config.sh`) bundles `Config/Lunch.plist` for Debug and
`Config/Lunch.Release.plist` for Release (both git-ignored). Archiving fails if the Release file is
missing or its RevenueCat key is not an `appl_` key, and `LunchConfig.revenueCatKey` drops any
`test_` key at runtime in Release as a backstop.

**AI consent.** Nothing is sent to an AI provider until the user agrees on the AI screen (App
Review 5.1.2(i)). The card names the providers that the backend's `ai-config` function returns,
and the answer is stored per install as the agreed consent version (`aiDataSharingConsentVersion`),
so a provider change asks again. Both platforms have the consent step. The iOS code no longer
reads the old `-aiDataSharingConsent 1` launch argument; preview runs keep their answer in a
separate preview store.

Known quality issue: with no search text, `places-nearby` asks Google for `includedTypes:
["restaurant"]`, which also matches hotels, supermarkets and venues that merely contain one.

---

## 4b. Split the bill

A free calculator (`design/screens.md` §12): even split plus adjustable amounts, optional
surcharge, share sheet summary with an optional "Pay me at" line kept on the device only. No money
moves and nothing reaches the backend. Maths is `BillSplitEngine` (Kotlin) and
`SwiftBillSplitEngine` (iOS), both pinned to `fixtures/bill_split_vectors.json`; change the vectors,
not one implementation. The group entry excludes the host's own RSVP, because the core records the
host as an accepted guest of their own group.

## 4c. Inviting in person

Group detail offers `Share invite` (system share sheet; on iPhones, holding the phones top to top
AirDrops the link) and `Show QR code` (on-device QR: CoreImage on iOS, ZXing core on Android). The
link `https://lunch.iapp.au/i/<code>` opens the app through Universal Links when installed;
otherwise the web invite page lets the guest accept without the app, offers the stores, and shows a
Smart App Banner whose `app-argument` hands the invite to the app after installing. The banner and
App Store link only work once App Store 1.0 (Apple ID 6808090102) is live.

## 5. What is deliberately unfinished

These are not oversights. Each needs a decision or an account step that is not done yet.

- **Push notifications are out of 1.0.** The iOS app has no Firebase, no remote registration and
  no `aps-environment` entitlement. The shared core and the backend keep the `push-register`
  path, but nothing calls it. Group lunch reminders are local notifications: they do not sync
  and do not survive a reinstall.
- **Google sign-in is configured but not qualified.** iOS uses GoogleSignIn 10.0.0; Android uses
  Credential Manager 1.6.0 / Google ID 1.2.1. Both use nonce-verified Supabase token exchange.
  The last recorded state of the Google consent screen is Testing, which limits sign-in to
  listed test users. See `AUTH_SETUP.md` for the client ids, SMTP, templates and the
  qualification still required. No successful production sign-in or email delivery is implied.
- **Maestro is not installed**, so the eight flows in `maestro/flows/` have never run. The test
  ids they need exist and were verified on-device.
- **The Android app-link file carries a placeholder fingerprint.** It needs the Play upload key
  SHA-256 before deep links will verify. Android is a second release; its open items are in
  `PUBLISH_REVIEW_2026-10-23.md` (N24 to N34).

---

## 6. Secrets and the public remote

`github.com/galwayit/whats-for-lunch` is **public**. The only env files in git hold
placeholders. One real credential did reach the public history: a Google Maps key quoted in the
archived Flutter audit report. The text is redacted on this branch, but the key stays in history
and on `main`, so it must be revoked in Google Cloud. CI now fails when a provider key or a key
file is committed.

Runtime configuration is deliberately outside the repo:

- iOS bundles `iosApp/LunchApp/Config/Lunch.plist` (Debug) or `Lunch.Release.plist` (Release), both
  gitignored, as `Lunch.plist`. `Lunch.plist.example` is the template. The Release file does not
  exist yet; it needs the production RevenueCat key (`appl_...`).
- Android reads `BuildConfig` fields fed from `-Plunch.*` properties or environment variables,
  all defaulting to empty.
- The backend reads its secrets from Supabase. Set on the live project: `GOOGLE_PLACES_API_KEY`,
  `GEMINI_API_KEY`, `OPENAI_API_KEY`, `REVENUECAT_SECRET_API_KEY`, `REVENUECAT_PROJECT_ID`,
  `REVENUECAT_WEBHOOK_SECRET` and `INVITE_LINK_BASE`. **Not set yet** (checked 2026-11-18):
  `REVENUECAT_PRO_PRODUCT_IDS`, `REVENUECAT_ALLOW_APPLE_SANDBOX`, `APPLE_CLIENT_ID`,
  `APPLE_TEAM_ID`, `APPLE_KEY_ID` and `APPLE_SIGN_IN_PRIVATE_KEY`. Without them a purchase does
  not unlock Lunch Pro and an Apple user cannot delete their account. The template with the
  right commands is the git-ignored `backend/supabase/.env.phase1`. Do not use `make secrets`:
  it pushes a different file. The `SUPABASE_*` values are injected by the platform.

The signing and config material (Apple `.p8` keys, the Release config, the Sentry token in
`.sentryclirc`) exists only on Ray's Mac until it is stored in a password manager.

---

## 7. Decisions

Decided by Ray on 2026-10-19 (`RELEASE_PLAN_2026-10-19.md`, Phase 0):

1. The iOS bundle id stays `au.iapp.lunch`. The App Store listing is new; the Flutter app's id
   `au.iapp.guesswhat.whatWeHaveForLunch` is not reused. Android keeps its old applicationId.
2. Lunch Pro costs A$4.99 a month and A$29.99 a year, with no trial. The product ids are
   `au.iapp.lunch.pro.monthly` and `au.iapp.lunch.pro.yearly`, mapped to the RevenueCat packages
   `$rc_monthly` and `$rc_annual` in offering `default`, entitlement `pro`.
3. No push notifications in 1.0.
4. iAPP trades as a sole trader on the existing ABN. Australia only at launch.
5. iOS ships first; Android is a second release.

Still open, all Ray's: the account steps and the six decisions in
`RELEASE_GAP_PLAN_2026-11-18.md` (Track A and section 7). They block the first signed build.

---

## 8. Product rules worth knowing before you change behaviour

The free tier is limited rather than ad-supported. That was a deliberate decision: no ads, ever.

| Limit | Free | Lunch Pro |
|---|---|---|
| AI requests | 1 a day | 10 a day, shared between personal and group suggestions |
| Favourites | 10 | Unlimited |
| History | 30 days | Full |
| Group lunches | Accept invitations only | Create and host |

Only paying users can create or host a group. Guests can see and accept an invitation without an
account. Gating lives in the core, not the UI, so both platforms enforce it identically. Do not
re-implement a gate in a screen.

---

## 9. House rules this codebase follows

- **Colours come from tokens.** `design/tokens.json` is the source; `python3 design/generate_tokens.py`
  writes both platforms. Never hand-edit the generated files. `design/check_no_literal_colours.sh`
  fails the build if a literal colour appears outside them. The palette is Paprika (warm
  red-orange brand, saffron rating stars, berry errors); green survives only as `success`. The
  web pages in `backend/web` copy the same values by hand, so change them together.
- **Type is two families.** Headline roles (`display`, `title`, `heading`) use the bundled
  Bricolage Grotesque Bold and ExtraBold; every other role uses the platform's system face. The
  `family` field on each role in `tokens.json` decides which. Font files and their licence notes:
  `iosApp/LunchApp/Resources/Fonts/README.md` and `androidApp/src/main/res/README.md`.
- **Copy comes from `design/copy.md`**, mirrored into `Copy.swift` and `strings.xml`.
- **Tests are named `should_<expected>_when_<condition>`.**
- **Every file carries a header comment** with its purpose.
- Screenshots live in `iosApp/screenshots/` and `androidApp/screenshots/`: 19 `screen-*` captures
  each, 17 light and 2 dark, plus the component gallery. Regenerate them when a screen changes.

---

## 10. First hour on this codebase

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home
./gradlew :shared:desktopTest :androidApp:assembleDebug :androidApp:testDebugUnitTest
cd backend && make check && make test && cd ..
```

Then open `iosApp/LunchApp.xcodeproj` and run the LunchApp scheme on a simulator. If the Kotlin
framework step fails, read section 2 before changing any version.

Read in this order: `README.md`, then `design/screens.md` for what each screen owes you, then
`shared/src/commonMain/kotlin/au/iapp/lunch/core/api/Contracts.kt`, which is the whole contract
between the core and both apps, then `shared/BUILD_NOTES.md` when the build argues with you.
