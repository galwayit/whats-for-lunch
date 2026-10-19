# Redesigned app: Ray iPhone Debug install and tests — 8 October 2026

Debug **1.0.0 (9)** (`au.iapp.lunch`) is installed and launched normally on
**Ray’s iPhone 12 Pro, iOS 27.0.1**. The existing app was updated in place. The
separate UI test runner was removed after testing. Code-signature verification
passed, and the app retains development team `RYM9BD2B27`.

The normal launch uses the configured Kotlin core and existing app data. The final
startup capture is [final-live-home.png](screenshots/final-live-home.png).
The phone’s dark appearance was restored after the light/dark tests.

## Results

| Check | Result |
| --- | --- |
| Device unit tests | 145 passed |
| Device UI checks | 11 distinct checks passed across the final full and targeted runs |
| Configuration Python tests | 15 passed |
| Bricolage fonts and design-system assertions | Passed on the physical phone |
| Final app signature | Verified with `codesign --verify --deep --strict` |
| Source integrity | 259 source/resource hashes checked; no drift after final test build |

The final full suite on build 8 passed 154 of 156 tests; its two authentication
checks still had unreliable keyboard interaction. After adjusting sign-in
scrolling and the UI-test interaction, **both authentication checks passed on
build 9**. This is combined coverage, not a claim that the full 156-test suite was
rerun on one build-9 binary. See [test-summary.json](test-summary.json),
[build8-test-summary.json](build8-test-summary.json), and
[auth-final-test-summary.json](auth-final-test-summary.json).

UI coverage includes:

- Home recommendations and navigation through Discover, Track, Profile, and
  Preferences in both actual system light and dark appearance.
- Restaurant details → prefilled meal → split bill → use my share.
- Group bill-splitting sheet first opening, closing, and reopening.
- Registration, verification-code completion, and missing recovery-code validation.
- The first free AI request followed by the daily-limit paywall.
- Invitation suggestions, offline place-picker layout, reporting/blocking controls,
  and manual search-area entry without requesting location.

Screenshots are indexed in [screenshots/manifest.json](screenshots/manifest.json).
Reviewed captures confirm the Paprika palette and Bricolage headings, readable
light/dark content, populated split sheets, and the full dietary notice in Discover.

## Fixes made during device testing

1. **Blank split-bill sheet:** replaced independent presentation booleans with an
   identifiable model-driven sheet in Track and Group detail. The sheet always has
   its model when it opens; closing clears that same presentation state.
2. **Truncated dietary notice:** allowed its text to retain its full vertical size
   in Discover’s header.
3. **Sign-in keyboard interaction:** scrolling dismisses the keyboard immediately;
   UI tests reveal the action before tapping and verify the actual form outcome.
4. **Preview consent isolation:** preview/demo AI consent and Profile’s consent
   setting now use a separate defaults suite, preserving live provider consent in
   subsequent preview runs. A regression test checks the isolation.
5. **Device-compatible fixtures:** the unit-test bundle copies the shared engine and
   bill-splitting JSON files. Tests read bundle resources instead of Mac filesystem
   paths. Throwing suite initializers report missing fixtures without crashing the
   test host.
6. Added four reusable redesign UI checks, including regression coverage for both
   split-bill entry points. Appearance tests use `XCUIDevice.appearance` and restore
   the previous setting during teardown.

## Scope and limitations

The UI workflows use the in-memory preview core and fictional data. They did not
send authentication emails, submit real invitation responses, make purchases, or
consume live AI allowance. Normal production-core launch was verified separately;
this run does not qualify live email delivery, provider billing, purchases, or push.
No backend deployment or App Store/TestFlight release was performed.

The initial fixture AI run used the old shared consent preference before isolation
was fixed. The normal AI screen may therefore request consent again for the real
providers. No production consent was fabricated or inferred to suppress that prompt.

Existing unrelated working-tree changes were preserved. No Git commit was made.

## Artifacts and reproduction

- Final app: `/private/tmp/lunch-ray-redesign-20261008/Build/Products/Debug-iphoneos/LunchApp.app`
- Full build-8 results: `/private/tmp/lunch-ray-redesign-20261008-final.xcresult`
- Final authentication results: `/private/tmp/lunch-ray-redesign-20261008-auth-final.xcresult`
- Install/version/launch receipts: `final-iphone-install.json`,
  `final-installed-app.json`, and `final-iphone-launch.json`.
- Binary identity and hashes: `final-device-build.json`.
- Source hashes: `source-hashes.json` and `source-verification.json`.

The regular app profile was already available. The separate UI test runner lacked
an app-team profile, so `test-signing.xcconfig` temporarily selects an existing
wildcard development profile for that runner only. The project’s signing settings
were not changed. The cached wildcard profile includes Ray’s phone and is signed
with the existing Lei Ding development identity.

Re-run on the paired phone with the local signing configuration:

```sh
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
xcodebuild -project iosApp/LunchApp.xcodeproj -scheme LunchApp \
  -configuration Debug -destination 'platform=iOS,id=00008101-000D44620111001E' \
  -derivedDataPath /private/tmp/lunch-ray-redesign-20261008 \
  -xcconfig release-evidence/2026-10-08/redesign-device/test-signing.xcconfig \
  -parallel-testing-enabled NO CURRENT_PROJECT_VERSION=9 test
```

Initial failed runs are retained as diagnostic evidence. They are superseded by
the successful checks described above, rather than silently omitted.
