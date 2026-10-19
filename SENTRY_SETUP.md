# Sentry setup for Lunch iOS

Organisation: **iapp-do**. Existing project: **apple**. SDK: **Sentry Cocoa 9.30.0**, pinned with Swift Package Manager using the official **Sentry-Dynamic** product.

The existing Apple onboarding project was identified in the signed-in Chrome session. The supplied onboarding run code was not needed for this manual SDK integration; it is not used as an API token or embedded in the app.

## What is connected

- The public ingestion DSN is in iosApp/LunchApp/Config/Sentry.plist. It is intentionally not a secret. Set enabled=false there to turn off reporting in subsequent builds.
- AppDiagnostics starts before the production core is created.
- Native crash and app-hang reporting are enabled. Unexpected failures that pass through CoreError.from are captured with controlled error codes and the source component/function.
- Environment labels are development for Debug, testflight for a verified StoreKit 2 sandbox app transaction, and production for a verified production app transaction. Release launches initially use release until asynchronous verification succeeds; if verification is unavailable they keep that neutral label. No deprecated receipt-URL check or receipt refresh is used. Verify the actual TestFlight event label during release qualification.
- Releases use the bundle identifier, marketing version and build: au.iapp.lunch@version+build.
- Previews, galleries and test hosts do not initialise Sentry. The explicit Debug-only -sentrySmokeTest flag permits a synthetic event with the fictional preview core; it does not bypass the test-host or disableDiagnostics guards.

## Data and volume

No app account is assigned to Sentry. Before-send filtering removes user, request, extra, breadcrumb, freeform message and exception-value fields, retaining a bounded technical context. Stack frames remain available for diagnosis.

The apple project's server-side data scrubber and default scrubbers are enabled. Prevent Storing of IP Addresses is enabled, and Additional Sensitive Fields contains city, subdivision, region, country_code and ip_address. Sentry can otherwise derive approximate location from the connection even when the app removes user context. Changes apply to new events and may take 5–15 minutes to propagate. Simulator image and frame paths are reduced to file names before upload, retaining debug UUIDs and addresses for symbol matching.

Automatic network request capture, UI breadcrumbs, screenshots, view hierarchies, session replay, logs, metrics and performance tracing are disabled. Memory introspection and MetricKit payload capture are disabled. Automatic session tracking is disabled in this first integration, so crash-free-user/session statistics are not qualified.

Offline states, cancellation, pending purchases, common input/authentication failures, quota gates and denied permissions are excluded. Unexpected handled errors are limited to one of the same code/component/function every two minutes and 20 total per process launch. Native crash/hang events do not use that handled-error limiter.

The local privacy page and application privacy manifest include the new diagnostic collection. Publish the updated privacy page and reconcile App Store Connect's Crash Data, Performance Data and Other Diagnostic Data disclosures with the final build before public release. Website publication and store attestation are separate release steps.

## Verify ingestion

Build the app, install it on an iPhone simulator and launch it with:

    xcrun simctl launch booted au.iapp.lunch -previewCore -sentrySmokeTest

This emits one controlled Lunch SENTRY_SETUP_TEST event. Its event ID appears in the simulator process output. Look for it in the apple project, environment development. A synthetic event verifies SDK ingestion; it does not by itself validate a native crash, device installation, production signing or symbolication.

For normal manual testing, launch the Debug app without preview flags. Expected payment cancellation and subscription gates should not create issues.

## Debug symbols

Sentry needs the exact build's dSYM files to make native stack traces readable. The upload credential must never go in Sentry.plist, Lunch.plist, an Info.plist, source code or Supabase Secrets: it is a build-system credential.

Use a Sentry organisation token with the org:ci build scope, stored as SENTRY_AUTH_TOKEN in the CI secret store. For local development, Sentry CLI can read the repository-root .sentryclirc; that file is git-ignored and should have owner-only permissions (0600). Do not commit it or paste the token into chat.

After installing the official sentry-cli, run:

    sh iosApp/scripts/upload_sentry_symbols.sh /absolute/path/LunchApp.xcarchive

For a Debug build compiled with DEBUG_INFORMATION_FORMAT=dwarf-with-dsym, the command also accepts the built app's dSYM directory:

    sh iosApp/scripts/upload_sentry_symbols.sh /absolute/path/LunchApp.app.dSYM

The script targets iapp-do/apple, waits for processing and rejects empty symbol directories. It passes --no-sources and does not pass --include-sources. Upload symbols from each exact archive before distributing it; a prior build's symbols are not interchangeable.

The public DSN is sufficient for event ingestion. The approved organisation token **Lunch iOS symbol uploads**, scoped to **org:ci**, is stored in the repository-root .sentryclirc with owner-only permissions (0600). It is Git-ignored, untracked, and verified absent from the tested app bundle. This is local build configuration; CI needs its own secure SENTRY_AUTH_TOKEN configuration.

## Verification on 6 October 2026

- The complete simulator suite passed: 137 unit tests plus 5 UI tests. After extending path scrubbing, all 137 unit tests passed again. All 15 configuration and symbol-upload script checks passed.
- Normal Kotlin/RevenueCat core startup was verified with Sentry enabled. The static Sentry product produced a RevenueCat startup crash in this build; selecting the official dynamic product eliminated the observed crash. Keep the dynamic product until any future SDK change passes the same normal-startup check.
- Controlled synthetic events reached [APPLE-1](https://iapp-do.sentry.io/issues/7775603715/), labelled development and au.iapp.lunch@1.0.0+6. Event e23381d2d10b4076b0c031913fa0fccf verified filtered geography and shortened image paths. The first diagnostic event preceded the server-side geography rules; those rules apply to subsequent events.
- Sentry CLI 3.8.0 uploaded and confirmed processing of the matching LunchApp and LunchApp.debug.dylib dSYMs, plus the Sentry framework's arm64 and x86_64 symbols. No source bundles were uploaded.
- A new event, **1d040d9ff3e14207be89c89d6bbc944e**, verified readable application stack frames in Sentry: AppDiagnostics.start (AppDiagnostics.swift:60) and LunchApp.makeEnvironment (LunchApp.swift:37). Some simulator/system-library frames remain unresolved. Older events from different build UUIDs are not qualified by this upload.
- After adding the explicit --no-sources upload guard, all 15 configuration and upload-script checks passed again.

The detailed result, binary UUIDs and source hashes are saved in release-evidence/2026-10-06/sentry/verification.json. This run did not install a build on a physical iPhone, produce a signed Release archive, publish the privacy page or submit an App Store build.

## Scope and follow-up

This setup covers the native iOS app. Android and Supabase Edge Functions should get their own Sentry projects/DSNs when added, so SDK platforms, releases and alerts remain distinguishable. Backend monitoring would provide the server stack trace behind an iOS service-failure event.

Check the organisation's trial/plan, ingestion quota and existing notification routing before production. No paid plan, notification recipient, Seer permission or subscription was changed by this integration.

## References

- [Apple SDK setup](https://docs.sentry.io/platforms/apple/guides/ios/)
- [Data collected](https://docs.sentry.io/platforms/apple/data-management/data-collected/)
- [Debug symbols](https://docs.sentry.io/platforms/apple/dsym/)
- [SDK options](https://docs.sentry.io/platforms/apple/configuration/options/)
- [Server-side location scrubbing](https://www.sentry.help/en/articles/13964201-can-i-disable-ip-geolocation-for-gdpr-compliance)
