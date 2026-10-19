# Manual-test fixes — 2 October 2026

Implemented locally for the native iOS/Android apps and the shared Supabase/web invitation contract.

- App destinations now use full-screen presentation with an expanding themed background and a header anchored at the top. Local sharing/utility sheets retain their native presentation. The error-state screenshot verifies the layout fix.
- Replaced the solid-orange iOS placeholder with a generated plate/fork/spoon mark. Packaged the same artwork as the Android adaptive icon. The signed iOS bundle contains the compiled icon; its source is opaque 1024 × 1024 PNG.
- Hosts can enter and edit their public host name, optional per-person AUD budget, who pays, and payment method. Existing missing values display “To be confirmed”; they are not invented. This is an agreed meal arrangement, not payment collection.
- Guests can suggest another place, time, or both, with a note. Submission preserves the existing plan and RSVP. Only the verified host can review it. Applying a suggestion atomically updates the plan, resets RSVPs and supersedes competing suggestions. Payment-plan changes also require a fresh RSVP. A host-name spelling correction does not.
- Suggestions persist in PostgreSQL. Anonymous guests use the existing per-invitation capability store; public responses disclose only their own latest suggestion. Best-effort pushes use the existing notification setup, with manual refresh/share as the fallback.

## Verification

269 automated tests passed: 85 backend, 141 shared, 32 Android, 9 iOS unit and 2 iOS UI tests.
76 PostgreSQL checks passed, including concurrent duplicate submissions, capabilities, host permissions,
RLS/RPC denial, stale approval, cost changes and cancellation. The real web page script passed fixture
checks for validation, failure/retry, token persistence, safe text rendering and refreshed RSVP state.
Both signed iOS Debug and Android Debug builds passed. `verification.json` records logs, hashes and
result bundles. No tests sent real invitations or exercised a payment transaction.

A combined iOS unit/UI runner stalled after the UI cases; separate reruns passed. Chrome displayed the
local web invitation's host/budget/payment and third option, but browser interaction timed out. The web
submission claim is based on the page-script fixture, not a successful Chrome end-to-end submission.

## Rollout status

**Debug build installed and launched on Ray's iPhone at the user's request.** Version 1.0.0 (2),
bundle `au.iapp.lunch`, was installed in place without uninstalling or resetting app data. The latest
incremental signed build passed, its signature and Debug entitlement were verified, and `devicectl`
confirmed the installed bundle/version and a normal launch. See `iphone-debug-install.json` and
`iphone-debug-install-build.log`. The binary hash matches the previously tested Debug artifact.
Manual phone flows remain for the user to test. The backend and website remain unchanged; there is
no App Store/TestFlight release claim.

The new migration is `backend/supabase/migrations/20261001144342_group_invitation_planning.sql`.
Deploy it with the updated `groups-create`, `groups-update`, `groups-suggestions`, `invitations`,
`invitations-respond` and `invitations-suggest` handlers, matching shared dependencies and web page.
`make deploy-functions` now includes the added endpoints. CI includes the invitation SQL and web tests.

The checkout already contains pending billing/security and AI-provider migrations from earlier work.
Its `groups-create` uses that pending verified billing implementation. The current name-only Supabase
secret check found `REVENUECAT_SECRET_API_KEY` absent, so the coordinated paid-backend rollout remains
blocked. `GEMINI_API_KEY` and `OPENAI_API_KEY` are also absent; those are separately needed to restore
AI place recommendations. They are not a requirement for the suggestion-writing endpoint itself.
The explicitly requested Debug installation permits testing the new icon and full-screen layout.
The new invitation planning/suggestion actions still require the matching backend rollout, and the
layout fix does not resolve the separate AI availability error. Add the previously agreed server
secrets securely, verify billing/providers, and deploy matching migrations/functions/web before
testing those server-backed actions or publishing a release.

## Manual retest after rollout

1. Open a group as its host → Edit invitation details. Save host name, AUD budget and payment plan.
2. Open its invitation on another device/browser. Check those details and Accept / Decline / Suggest.
3. Suggest another place and/or time. Verify the current plan/RSVP remains unchanged and the pending
   suggestion remains visible after reopening the same invite on the same device.
4. As host, review Guest suggestions. Keeping the plan must leave the place/time unchanged. Applying
   the alternative requires confirmation and resets every RSVP. Refresh the guest invitation and RSVP
   again to the new plan. Check that an old competing suggestion cannot overwrite it.
5. Check the launcher icon and app destinations in light/dark mode, including a failed place lookup.

Implementation references: [Apple full-screen cover](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)),
[Supabase function privileges](https://supabase.com/docs/guides/database/functions),
[Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
