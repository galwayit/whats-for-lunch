# One free AI request, then a subscription prompt — 6 October 2026

## Delivered behaviour

- A signed-in free user can make one successful Ask AI request per UTC day,
  including the "Why this?" entry point. Provider consent is still required.
- The next attempt opens the Lunch Pro paywall. The first result remains
  available when the paywall is dismissed; it does not immediately reopen.
- Subscribing or restoring Pro refreshes access on the same AI screen.
- Pro retains ten requests per UTC day, shared with group suggestions. Exhausting
  that allowance displays the reset time without an upgrade prompt.
- Free access renews at 00:00 UTC. Failed requests do not increment local success
  usage; the existing backend refunds failed provider reservations.
- Existing chain exclusion and photo reuse fixes are retained.

## Validation

| Check | Result |
| --- | --- |
| Shared JVM tests | 148 passed |
| Shared Android tests | 40 passed |
| Android app unit tests | 66 passed |
| Backend format/type checks and Deno tests | Passed; 107 tests |
| iOS simulator tests | 128 unit tests and 1 UI test passed |
| Generated chain catalogue / whitespace checks | Passed |

Total: **490 passed**, no failures or skipped tests. The iOS UI test launched the
free preview account, obtained the first recommendation and verified that the
second Ask opened the paywall. Its screenshot is in `ios-attachments/`.
Displayed store prices and eligibility in this screenshot are preview fixtures.
The test did not perform a real purchase or send a paid AI request.

Tests also cover failed requests preserving the free allowance, a new UTC day,
local versus server quota denial, preserving the first result after an upgrade
prompt, and upgrading without recreating the AI screen. A whitespace-only
Android indentation adjustment followed the passing build.

`ios-test-summary.json` and `test-summary.json` record the results. The result
bundle is `/private/tmp/lunch-ai-free-daily-ios.xcresult`.

## Backend and device scope

The backend already enforces free 1 / Pro 10. Its AI and group entry-point source
hashes still match the preceding deployed version 10, so no function or database
deployment was needed. Local backend tests now exercise the actual reservation
helper instead of the obsolete unused helper that described unlimited Pro use.
An optional attempt to retrieve deployed source through the Supabase connector
was denied by that connector's permissions; no live provider call was made.

Debug **1.0.0 (5)** was development-signed for `au.iapp.lunch` with team
`RYM9BD2B27`, installed over the existing app on Ray's iPhone 12 Pro, and launched.
No uninstall was performed. Installation and launch records accompany this note;
`device-build.json` identifies the signed artifact. Existing upstream debug-symbol
warnings remain; the build and code-signature verification passed.

`tested-source-sha256.json` records the final source files relevant to this change.
