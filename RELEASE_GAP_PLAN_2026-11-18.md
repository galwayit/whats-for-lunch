# App Store release: gaps and closing plan — 18 November 2026

Branch `native-migration` at commit 1027350. This review checks the current code, the live
backend and the live website against [PUBLISH_REVIEW_2026-10-23.md](PUBLISH_REVIEW_2026-10-23.md)
and [RELEASE_PLAN_2026-10-19.md](RELEASE_PLAN_2026-10-19.md). It covers the iOS App Store
release. Android is a later release and has one status line in section 6. Nothing in the
repository, the backend or any account was changed during the review.

**Verdict: not ready to submit.** The app code is close: five of the October fixes are done
and every test suite passes. The release is blocked by account setup that only you can do
(Apple agreements, subscription products, RevenueCat, Supabase plan), by one stale public page,
and by about three days of engineering. No signed build has been made yet.

The steps in section 5 replace the step list in section 5 of the 23 October review for iOS.

---

## 1. What is done since 23 October

| Item | Evidence |
| --- | --- |
| Paywall preview data, tests and copy use A$4.99 / A$29.99 with no trial | commit a0148cd |
| Firebase and remote push are removed; the local lunch reminder stays | commit aa1a015; the entitlements file now holds only Sign in with Apple and the `lunch.iapp.au` link domain |
| An invitation opened on a fresh install shows before onboarding, with a UI test | commit 343fe81 |
| The system boot time API and the unused camera and photo permission texts are removed | commit 4e1bebf |
| The AI request size and timeout fixes and the merged nearby-places ranking are deployed | `ai-recommend` deployed 23 October; `places-nearby` and `groups-propose` deployed 6 November |
| All eight database migrations are applied to the live project | Supabase migration list |
| The legal pages and the app-link file answer non-browser clients with HTTP 200 | `curl` without a browser user agent |
| Apple's servers hold the correct app-link file for `RYM9BD2B27.au.iapp.lunch` | Apple's app-site-association cache |

---

## 2. Blockers

A blocker stops the archive, the sale or the review today.

| # | Gap | Evidence | Owner |
| --- | --- | --- | --- |
| B1 | **No production purchase setup.** The backend does not have the product id list, the sandbox switch or the four Sign in with Apple values. Without them a purchase never unlocks Lunch Pro, and account deletion fails for a user who signed in with Apple. | Live secret names: `REVENUECAT_PRO_PRODUCT_IDS`, `REVENUECAT_ALLOW_APPLE_SANDBOX`, `APPLE_CLIENT_ID`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGN_IN_PRIVATE_KEY` are all absent. `APPLE_KEY_ID` is still blank in `backend/supabase/.env.phase1`. | Ray |
| B2 | **No Release configuration.** `iosApp/LunchApp/Config/Lunch.Release.plist` does not exist. The only RevenueCat key on this Mac is a Test Store key. The archive step fails on purpose until a production key (`appl_…`) is present. | File listing; key prefix in `Lunch.plist` | Ray supplies the key, Claude writes the file |
| B3 | **The backend is on the Supabase Free plan and goes to sleep.** The project was hibernated when this review started; the first database calls timed out. A reviewer or a user who meets a sleeping backend sees errors. The Free plan's built-in email also sends only to team addresses, so public email sign-up cannot work without custom mail (SMTP) setup. | Organisation plan is `free`; the advisor call returned "project is currently hibernated"; `AUTH_SETUP.md` records SMTP as not configured | Ray |
| B4 | **The live privacy policy does not match the app.** `https://lunch.iapp.au/privacy/` still names meal photos, push notifications and Firebase Cloud Messaging. The repository copy is correct; it was never deployed. Apple compares the policy with the binary. | `diff` of the live page against `backend/web/privacy/index.html` | Claude deploys after your go-ahead |
| B5 | **No signed build exists.** This Mac has two Apple Development certificates and no distribution certificate. There is no export options file. The build number in the project is 2, but device builds already used numbers up to 9. No build has reached TestFlight. | `security find-identity`; `project.pbxproj`; no evidence folder after 8 October | Claude, after Ray signs in to Xcode |
| B6 | **No store listing material.** The screenshots are 1206x2622 with an alpha channel; Apple needs 1320x2868 (or 1290x2796) without alpha. There is no listing text (`design/store-listing.md`), no App Privacy answer sheet and no review notes. | `sips` on `iosApp/screenshots/`; file listing | Claude drafts, Ray approves and uploads |

Not verified from this machine, because they live in your accounts: the Paid Apps agreement
status, tax and banking, whether the two subscription products exist, and the RevenueCat App
Store app. The missing backend values in B1 suggest these steps are not complete.

---

## 3. High-priority gaps

Each of these can cause a rejection or a visible failure in version 1.0.

| # | Gap | Where | Owner |
| --- | --- | --- | --- |
| H1 | Google sign-in works only for listed test users. The last recorded state of the Google consent screen is "Testing", and publishing was blocked until the branding fields (home page, privacy and terms links) are filled. In that state the reviewer's Google account is refused. | `AUTH_SETUP.md` line 16 (written 6 October; confirm in Google Cloud) | Ray |
| H2 | Account deletion shows "couldn't reach the lunch service" for every failure, shows the Delete row to a signed-out user, and gives no message on success. | `ProfileViewModel.swift:57`, `ProfileView.swift:201` | Claude |
| H3 | Two buttons named "Continue with Apple" open the general sign-in sheet. Apple does not allow its name on a control that does something else. | `PaywallScreen.swift:41`, `AIRecommendationsView.swift:53` | Claude |
| H4 | The in-app Privacy text says that sign-in copies meals to the account. Nothing is copied; the web policy says the opposite. | `Copy.swift:339` | Claude |
| H5 | A paying user who is offline for more than one hour appears signed out and sees Free limits, because a failed token refresh is treated as "no session". | `AuthRepositoryImpl.kt:42` | Claude |
| H6 | The three Places functions are public and have only one global daily limit. One caller can use the whole limit and empty Discover for every user until 00:00 UTC. All functions also allow any web origin. | `_shared/budget.ts`, `_shared/errors.ts:10` | Claude |
| H7 | Sign in with Apple on the production backend has no recorded test with "Hide My Email". The reviewer taps this button first. | no file under `release-evidence/` | Ray tests, Claude records |

---

## 4. Medium and low gaps

| # | Gap | Owner |
| --- | --- | --- |
| M1 | The privacy manifest declares "Device ID". That entry dates from the push design; the app no longer registers a device token. Remove it, or the App Privacy label must list Device ID. **New finding.** | Claude |
| M2 | Fourteen of the eighteen functions were last deployed on 6 October, before the shared error module changed. Deploy all functions together before qualification so they run the same shared code. **New finding.** | Claude |
| M3 | The Apple user's name is not saved after the first sign-in, so "Hide My Email" users show a relay address in Profile and in invitations. | Claude |
| M4 | Every protected request reads RevenueCat first. A RevenueCat outage then fails AI and group hosting for free users too. | Claude |
| M5 | Guest RSVPs per invitation have no upper limit. | Claude |
| M6 | No scheduled cleanup exists. The places cache and the usage tables grow without limit, and the privacy page gives no retention period. | Claude |
| M7 | Venue name and address stay in `groups` permanently. Google allows 30 days for such content. | Claude |
| M8 | Leaked-password protection is off on the hosted project (confirmed by the Supabase security advisor today). The hosted Site URL and email rate limit are not recorded. | Ray |
| M9 | The state of the Gemini billing error (HTTP 402 since 6 October) is unknown. The live AI configuration still names Gemini and OpenAI. | Ray |
| M10 | The leaked Google Maps key is still in `archive/flutter/COMPREHENSIVE_SECURITY_AUDIT_REPORT.md` on both branches of the public repository. I could not confirm that the key is revoked. | Ray revokes, Claude removes the lines |
| M11 | The release cannot be rebuilt from git: two commits are not pushed, there is no release tag, and `main` still shows the Flutter app. | Claude, with your decision on `main` |
| M12 | CI never builds the Release configuration, and it selects the newest Xcode instead of a pinned one. This Mac moved to Xcode 27.2. | Claude |
| M13 | `deno.lock` is ignored by git, so backend dependencies are not locked in CI or in deploys. | Claude |
| M14 | No alert rule and no runbook exist. GitHub has no `SENTRY_AUTH_TOKEN` secret. | Claude and Ray |
| M15 | Signing and config files (Apple keys, the Release config, the Sentry token) exist only on this Mac. | Ray |
| M16 | `HANDOFF.md` is out of date (function and test counts, "nothing has been pushed", secrets, prices). The privacy page still says "Updated 6 October 2026". | Claude |
| L1 | The Home Screen name "What We Have For Lunch" has 22 characters; iOS shortens names after about 12. Consider "Lunch". | Ray decides |

---

## 5. The plan

Three tracks. Track A is the critical path and only you can do it. Track B needs nothing from
you except three approvals, so it can run at the same time. Tracks C to E need both.

### Track A — accounts (Ray). Start now; Apple can take several days.

| Step | Action | Done when |
| --- | --- | --- |
| A1 | App Store Connect → Business: complete the tax forms and banking. Register the ABN for GST first if that is not done. | Paid Apps agreement shows **Active** |
| A2 | App Store Connect → Subscriptions: create group "Lunch Pro" with `au.iapp.lunch.pro.monthly` (A$4.99) and `au.iapp.lunch.pro.yearly` (A$29.99), no trial, Australia only. | Both products show "Missing Metadata" or "Ready to Submit" |
| A3 | App Store Connect → Users and Access → Integrations: create an In-App Purchase key. Keep the `.p8` file outside the repository. | Key ID and Issuer ID noted |
| A4 | RevenueCat: add the App Store app for `au.iapp.lunch`, upload the A3 key, import both products, attach them to entitlement `pro` in offering `default`. Copy the public `appl_…` key. Send the webhook test event. | Offering shows two packages; test event returns 200 |
| A5 | Apple Developer → Keys: create a Sign in with Apple key. Put its Key ID in `backend/supabase/.env.phase1`. Run the three commands in that file's header. Do **not** run `make secrets`. | Claude confirms the six names in `supabase secrets list` |
| A6 | Supabase: upgrade the organisation to Pro (this stops hibernation). Set up custom SMTP and paste the two email templates. Raise the email rate limit above 30 an hour. Set the Site URL to `https://lunch.iapp.au`. Turn on leaked-password protection. | A sign-up email with an 8-digit code arrives at a non-team address |
| A7 | Google Cloud: revoke the leaked Maps key, fill the consent screen branding (home page `https://lunch.iapp.au`, privacy and terms links) and publish it, set budget alerts, and fix Gemini billing or choose another backup provider. | Consent screen status "In production" |
| A8 | Xcode → Settings → Accounts: sign in with the Apple ID of team RYM9BD2B27. Accept any pending licence agreement at developer.apple.com (an earlier build failed on this). | Claude can create the distribution certificate during the archive |
| A9 | Store the `.p8` keys, the Release config and the Sentry token in a password manager. | Location noted in `HANDOFF.md` |

### Track B — engineering (Claude). About three days; can start today.

| Step | Work | Proof |
| --- | --- | --- |
| B1 | iOS fixes H2 to H5, M1, M3. Set the build number to 10. | A failing test first for each fix, then the full iOS and shared suites |
| B2 | Backend hardening H6, M4 to M7: a limit for each caller on Places, a restricted web origin, a recent-snapshot shortcut for the Pro check, an RSVP limit, a daily cleanup job with 90-day retention, venue data retention. | One regression test for each change; the PostgreSQL job in CI |
| B3 | Release engineering M10 to M13: Release simulator build in CI, pinned Xcode, committed `deno.lock`, removal of the leaked-key lines plus a key-pattern check, an export options file, push the branch. | CI green on the pushed commit |
| B4 | Website: deploy the corrected privacy page, add the retention period, update the date. | Live page equals the repository copy |
| B5 | Listing: `design/store-listing.md` with name, subtitle, keywords, description (real AI allowance, prices, auto-renewal, Terms of Use and Privacy links at the end), review notes, App Privacy answers and age-rating answers. Screenshots at 1320x2868 without alpha. | Files in the repository for your approval |
| B6 | Docs M16 and a one-page runbook (M14). | `HANDOFF.md` matches the tree |

**Approvals needed before parts of Track B** (see section 7): the two database migrations in
B2, the website deploy in B4, and the change to `main` in B3.

**Advice on scope.** H6 should ship before review, because an empty Discover during review is
a rejection. M4 and M7 are not review risks. If time is short, move them to version 1.0.1; the
other B2 items are small and share one deploy.

### Track C — release build (Claude). Needs A4, A5, A6 and A8.

| Step | Work | Proof |
| --- | --- | --- |
| C1 | Write `Lunch.Release.plist` with the `appl_…` key. | `validate_release_config.py` passes |
| C2 | Apply the migrations and deploy all eighteen functions (M2). | Function list shows one deploy date; smoke calls return 200 |
| C3 | Tag the commit. Archive, export, and inspect the entitlements, the bundled config and the archive's privacy report. Upload debug symbols to Sentry. | `.xcarchive` and `.ipa`; Sentry shows release `au.iapp.lunch@1.0.0+10` |
| C4 | Upload to TestFlight. | Build is "Ready to Test" |

### Track D — qualification on the TestFlight build (Ray on the phone, Claude on the logs)

Run scenarios 3.1 to 3.12 of the 19 October plan with a sandbox Apple account, plus these
additions: Sign in with Apple with "Hide My Email" (H7); buy the yearly product as well as the
monthly one; open an invitation link on a phone where the app was never opened; repeat the
offline test after more than one hour; delete an Apple, a Google and an email account. Capture
the paywall with the real store price for the subscription review screenshot. Claude records
the evidence under `release-evidence/`. A failure returns to Track B or C for a new build.

### Track E — submission (Ray, with Claude's drafts)

| Step | Action |
| --- | --- |
| E1 | Fill the version page: screenshots, text from B5, support and privacy URLs, age rating, App Privacy answers from the archive's privacy report, export compliance "no", trader status "not a trader" with EU storefronts off. |
| E2 | Add the review notes: test account, sandbox purchase path, the one free AI request rule. |
| E3 | Attach the build and both subscriptions to version 1.0. The first subscriptions must go to review together with the app version. Select manual release. Submit. |
| E4 | After approval: release, then Claude checks the store link, the banner on an invitation page and a link on a fresh install. |

### Order and timing

```
Track A (Ray) ─────────────┐
                           ├─► C build ─► D qualification ─► E submit ─► Apple review (1–3 days)
Track B (Claude, 3 days) ──┘
```

The earliest realistic submission is about two weeks from the day Track A starts. Apple's tax
and banking processing in A1 sets the pace; everything Claude does in Track C waits for the
`appl_…` key from A4.

---

## 6. Android status

Unchanged since 23 October. The target API level is still 35 (Play has required 36 since
31 August 2026), there is no release signing, and findings N24 to N34 of the 23 October review
are open. This stays a second release after iOS is in review.

---

## 7. Decisions for you

1. May Claude apply two new database migrations (RSVP limit; scheduled cleanup with 90-day
   retention) to the live project after they pass the regression tests?
2. May Claude deploy the corrected website to `lunch.iapp.au`?
3. May Claude fast-forward `main` to `native-migration` on the public repository? This replaces
   the Flutter tree that the public sees today.
4. Supabase Pro with or without point-in-time recovery (about A$215 a month with it).
5. Gemini: fix billing, use another backup provider, or run with one provider.
6. Home Screen name: keep "What We Have For Lunch" or shorten it.

---

## 8. Checks run for this review

| Check | Result |
| --- | --- |
| `:shared:desktopTest` | 152 tests, 0 failures |
| `:shared:testDebugUnitTest` | 41 tests, 0 failures |
| Backend `make check` and `make test` | type check and format clean; 117 tests, 0 failures |
| Release config script tests | 14 tests, OK |
| Web invitation test, colour lint | pass |
| iOS `xcodebuild test` (simulator) | 157 tests, 0 failures, 0 skipped (counts from the `.xcresult`, Xcode 27.2) |
| iOS Release build for the simulator, no signing | build succeeded, with the expected warning that `Lunch.Release.plist` is missing (B2) |
| GitHub CI | last run 23 October on commit 4fe09d7: success. The two newer commits are not pushed, so CI has not seen them. |

Not run: a signed archive (blocked by B2 and B5), Android builds (out of scope), and a live test
of whether the leaked Maps key is revoked (the request was not permitted from this session).

---

## 9. Progress: Track B, 18 November

Track B is implemented and tested locally. Nothing is deployed, nothing is applied to the live
database, and nothing is pushed.

| Step | Status | Notes |
| --- | --- | --- |
| B1 iOS fixes | Done | H2, H3, H4, H5, M1 and M3 are fixed, each with tests. H5 also needed a fix to the Pro status, which treated a failed token refresh as "signed out". Build number is 10. |
| B2 Backend hardening | Done in code, **not deployed** | H6, M4, M5, M6 and M7 in three new migrations (`20261118000001` to `20261118000003`) and the shared function code. |
| B3 Release engineering | Done, except the push | CI builds Release, pins Xcode and rejects committed credentials; `deno.lock` is tracked and CI runs in frozen mode; the leaked key text is redacted on this branch; `iosApp/ExportOptions.plist` exists. |
| B4 Website | Text done, **not deployed** | The privacy page states the retention periods and the per-caller request counters. Deploy it after the backend. |
| B5 Listing | Draft done | `design/store-listing.md` and seven 1320x2868 screenshots in `iosApp/screenshots/store/`. |
| B6 Docs | Done | `HANDOFF.md` updated; `RUNBOOK.md` is new. |

Checks on the final state: shared core 158 and 41 tests, Android app 66, iOS 163, backend 129,
PostgreSQL regression 119 assertions, all with 0 failures.

New facts found during the work:

- GitHub's `macos-26` image has Xcode 26.6 at most, so CI has never used Xcode 27. The pin is
  now explicit. The App Store archive is built on this Mac with Xcode 27.2.
- `sentry-cli` is not installed on this Mac. Install it before step C3, or the debug symbols
  cannot be uploaded.
- The per-caller limit identifies a signed-out caller by network address. People behind one
  shared address (many mobile networks) share that caller's 200 Places requests a day. Signed-in
  users are counted by account. Which request header carries the real address on Supabase's
  gateway must be confirmed after the first deploy (`backend/README.md` has the check).
- The store screenshots come from sample data: the places have no photos and the user is "Ray".

What you approve when you approve decision 1 (section 7) has grown. The three migrations:

1. add a table of daily request counters for each caller (hashed, no raw addresses);
2. limit a lunch to 200 guests;
3. add a daily job that deletes usage and purchase-event records older than 90 days and
   reviewed reports older than 90 days, and **removes the venue name and address from lunches
   more than 30 days in the past** (Google's limit for stored Places content). The place
   identifier stays, but a host who opens an old lunch no longer sees where it was.

Item 3 changes what users see. If you want old lunches to keep their venue, say so and I will
split that part out before anything is applied.
