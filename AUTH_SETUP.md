# Google and email authentication

Implemented on 1 October 2026. Native iOS and Android screens support Google sign-in,
email/password sign-in, registration, email verification and password recovery.
iOS retains Sign in with Apple. All successful sessions bind RevenueCat to the
verified Supabase account and refresh pending push registration. Account deletion
requests Apple reauthentication on iOS only when an Apple identity is linked.

**Native Google sign-in is configured; real device qualification is pending.**
After the owner accepted Google's policy, three OAuth clients were created in
Chrome in project `whats-for-lunch-509417`. Supabase project `cswdcbmywzzisovsgwac`
now has Google enabled with their actual public IDs, nonce checks enabled, and
email required. Both native builds consume the public IDs in
[`config/google-oauth.json`](config/google-oauth.json).

Google's external consent app remains in **Testing** with two test users visible
(`ray@getbillabee.com`, explicitly approved by the owner, and the existing
`ray2ding@gmail.com`). Only OpenID, email and basic profile scopes are configured.
The Audience page blocks publishing until Branding configuration is completed:
home page, privacy and terms links are blank, and the current authorised-domain
list contains only the Supabase project host. Qualify the public policy/site update
before submitting those URLs and registering its domain.
On 6 October, hosted email/password and email confirmation were enabled, with
minimum password length 8 and eight-digit verification codes expiring after
600 seconds. A temporary confirmed account successfully signed in for the live
AI acceptance check and was removed afterwards. This did not send email or test
the registration/recovery delivery flow. Custom SMTP and the prepared OTP email
templates remain required: the current default confirmation email contains a
link, while the native app expects a code.

## Google OAuth setup

The Google Cloud project uses app name **What We Have For Lunch** and the business
account as support/developer contact. Qualify test devices/accounts before public
publishing. No Drive, contacts, calendar or other Google API access is requested.

Created clients (1 October 2026):

| Name | Public client ID |
| --- | --- |
| Lunch Supabase Web | `52984609044-tcno2jm34ve7v05umri16hvdoalfpp2v.apps.googleusercontent.com` |
| Lunch iOS | `52984609044-hhqngdbo0iea1k7f54bgi9mlnfusbps1.apps.googleusercontent.com` |
| Lunch Android Debug | `52984609044-9okqqiiu3e6qs8gih5ujik4li6t05e8i.apps.googleusercontent.com` |

| Client | Exact configuration | Where its public ID goes |
| --- | --- | --- |
| Web application | Supabase callback `https://cswdcbmywzzisovsgwac.supabase.co/auth/v1/callback` | First ID in Supabase Google's accepted client IDs; both apps' `googleServerClientId` |
| iOS | Bundle `au.iapp.lunch`, team `RYM9BD2B27`, App Store ID `6808090102` | iOS `googleIosClientId`; include in Supabase's accepted audiences |
| Android | Package `au.iapp.guess_what.what_we_have_for_lunch`, matching signing certificate SHA-1 | Google validates the native caller; use the **Web** ID as the app's server client ID |

Register Android debug and production signing identities separately. Production
needs the **Play App Signing certificate**, not just the local upload certificate.
Release signing is not yet configured in this checkout. Never substitute the iOS
bundle ID for the different existing Android package ID.

The local Android debug certificate was read on 1 October 2026:
`CB:3A:6F:4F:7F:F3:F4:48:1E:F5:84:79:00:C7:4E:E4:9D:35:A4:05` (SHA-1).
Use this only for the Android debug OAuth client; it does not qualify a store build.

Supabase → Authentication → Sign In / Providers → Google:

- Saved all three public client IDs, Web first, from the same Google project.
- The native `signInWithIdToken` flow verifies Google's signed ID token and nonce;
  it does not need the Web client secret. No secret was downloaded, stored locally,
  or entered into Supabase in this run. A future browser OAuth code-exchange flow
  would require the owner to enter that secret directly into Supabase's server-side
  provider field. Never put it in either app, source control, screenshots, or chat.
- Enabled Google and kept **Skip nonce checks off**. Both native apps send a fresh
  hashed nonce to Google and the raw nonce to Supabase; iOS also sends the matching
  access token so Supabase can validate `at_hash` when present.
- Kept “Allow users without an email” off.

The local CLI Google provider stays disabled by default until its environment is
configured; this is separate from the enabled hosted provider. The dashboard does
not evaluate CLI `env(...)` placeholders. Do not paste them there.

The live public settings endpoint confirms `external.google = true`. A deliberate
invalid-token request returned `400 Bad ID token`, confirming the provider reaches
token verification. This is not proof of successful Google authentication. Evidence:
[`google-provider-live-check.json`](release-evidence/2026-10-01/google-provider-live-check.json),
[created clients](release-evidence/2026-10-01/google-oauth-clients-created.jpg),
[saved provider](release-evidence/2026-10-01/supabase-google-enabled.jpg).

### iOS

Public `googleIosClientId` and `googleServerClientId` default to the shared JSON.
Optional keys in ignored `iosApp/LunchApp/Config/Lunch.plist` for Debug or
`Lunch.Release.plist` for Release override these defaults. An explicit empty or
invalid override fails validation rather than silently selecting another project.
`generate_auth_info.py` derives the reversed-client callback scheme and SDK keys
into the build's generated Info.plist. This avoids mismatching Debug and Release
URL schemes. `LunchApp.onOpenURL` passes Google callbacks to the SDK and preserves
invitation handling. The archive configuration check requires both valid IDs;
the real Release plist and Firebase/production billing configuration are still
required. The new defaults do not bypass those release gates.

GoogleSignIn and GoogleSignInSwift are pinned to 10.0.0, compatible with this project's
Xcode 27 and iOS 18 minimum. The app uses official Apple and Google sign-in controls.
It clears the Google SDK session after handing the credentials to Supabase, which
owns the app's persisted authentication session.

### Android

The Web server client ID defaults to the shared JSON. Override with
`-Plunch.googleServerClientId=<web-client-id>` or `LUNCH_GOOGLE_SERVER_CLIENT_ID`
only when deliberately selecting another Google project. Credential Manager 1.6.0 and Google ID 1.2.1 use
`GetSignInWithGoogleOption` when the user taps the official Google button. The
Activity context is passed from the current sheet rather than retained in a global
application provider. Passwords and verification codes never enter saved-state
Bundles. Apple login is not offered on Android.

## Email registration and recovery

Choose an existing transactional email service and a verified sender/domain.
Enter SMTP credentials directly in Supabase → Authentication → Emails → SMTP.
Do not use the limited default Supabase sender for public registration. The current
dashboard requires custom SMTP before custom templates can be used.

Configure these hosted settings to match `backend/supabase/config.toml`:

- Email provider enabled; user signups enabled; **Confirm email enabled**.
- Minimum password length **8**, email OTP length **8**, expiry **600 seconds**,
  resend interval **60 seconds**; double confirmation for email changes enabled.
- Confirmation template: `backend/supabase/templates/confirmation.html`.
- Recovery template: `backend/supabase/templates/recovery.html`.
- Both templates must contain `{{ .Token }}`. The app accepts a 6–10 digit code,
  never consumes a bearer token from an arbitrary deep link, and does not need a
  password-reset website. The email text assumes the configured 10-minute expiry.
- Use a real HTTPS site URL and exact approved redirect URLs for other existing
  flows; do not leave the hosted site URL at localhost.

The register flow returns no signed-in account until verification. Signup/recovery
copy avoids declaring whether an account exists. Existing email users can sign in
or reset their password. A failed password update after recovery clears the local
recovery session and asks for a fresh code because recovery codes are single-use.
Changing form modes clears password/code inputs. Password-manager autofill is
supported by iOS content types; Android fields use password keyboard semantics.

Local CLI config/templates are included, but `supabase db push` does **not** apply
hosted auth-provider settings or SMTP. Configure and verify these separately. The
privacy page describing Apple, Google and email authentication was deployed to
`https://lunch.iapp.au/privacy/` on 6 October and verified over HTTP.

## Qualification before release

1. Register a dedicated test account, receive its email code, reject a wrong/expired
   code, verify successfully, sign out and sign in with the password.
2. Request recovery, receive its code, change the password, reject the old password,
   and sign in with the new password. Check resend throttling and email delivery.
3. Test Google cancellation and successful sign-in on an iPhone and an Android
   device with Google Play services. Verify the production Android signing client.
4. Confirm the same verified Supabase user ID is used by RevenueCat and the backend.
   Test an existing email account's Google sign-in/identity-linking behaviour before
   enabling public traffic; rely on Supabase verification, never email-string joins.
5. Test delete for Google/email and Apple-linked accounts. Apple-linked account
   deletion on Android remains a release limitation: it needs Apple's fresh-code
   revocation flow (currently native iOS only), or the support deletion process.
6. Validate a signed Release archive and real store purchases independently. Auth
   tests and preview screenshots are not evidence of a live subscription or release.

## References

- [Supabase native Google auth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase native ID-token verification implementation](https://github.com/supabase/auth/blob/master/internal/api/token_oidc.go)
- [Supabase email/password auth](https://supabase.com/docs/guides/auth/passwords)
- [Android Credential Manager Google flow](https://developer.android.com/identity/sign-in/credential-manager-siwg-implementation)
- [Google iOS configuration](https://developers.google.com/identity/sign-in/ios/start-integrating)
- [GoogleSignIn 10.0.0 release](https://github.com/google/GoogleSignIn-iOS/releases/tag/10.0.0)
- [Google sign-in button branding](https://developers.google.com/identity/branding-guidelines)


## Local verification (1 October 2026)

- Shared Kotlin: 137 passing tests, including nine real-SDK HTTP contract tests
  for signup/session boundaries, Google nonce/access-token exchange, identity
  binding, email verification, recovery, failure cleanup and resend.
- Android: 54 passing JVM tests; debug APK assembled. Two Compose instrumentation
  tests pass on a temporary Pixel 9a emulator: registration through verification,
  and recovery with missing-code rejection. They use fictional preview accounts.
- iOS: 101 passing unit tests, including six authentication/deletion tests, plus
  two native XCTest UI tests on iPhone 17 Pro (iOS 26.5). Registration through
  verification and missing recovery-code rejection pass with fictional preview
  accounts. Manual password entry handles the system strong-password suggestion.
  Results are recorded in `release-evidence/2026-10-01/auth-verification.json`.
- Twelve Python archive/callback-configuration tests pass. The generated callback
  preserves other handlers, rejects incomplete Google configuration and restricts
  shared defaults to public identifiers. Fresh Android debug and iOS simulator
  builds passed after client creation; compiled client IDs and the iOS callback
  scheme were checked against the shared JSON.
- Hosted Google provider activation is separately verified as described above.
  No real OAuth login, delivered email, physical-device authentication or App Store
  submission is represented by these results. The earlier full native/unit suites
  were not rerun for this public-ID/build-configuration update.

Preview screen evidence: [Android](release-evidence/2026-10-01/auth-android-signin-preview.png), [iOS sign-in](release-evidence/2026-10-01/auth-ios-signin-preview.jpg), [iOS verification](release-evidence/2026-10-01/auth-ios-verification-preview.png).
