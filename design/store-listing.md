# App Store listing — version 1.0

Draft for Ray's approval. Paste each field into App Store Connect as written. Australian
English, Australia storefront only. The numbers in this file (prices, AI allowance, free limits)
must match the app and `backend/web/terms/`; if one changes, change all three.

## Identity

| Field | Limit | Text |
|---|---|---|
| Name | 30 | What We Have For Lunch |
| Subtitle | 30 | Find lunch, track your budget |
| Primary category | | Food & Drink |
| Secondary category | | Lifestyle |
| Bundle id | | au.iapp.lunch |
| SKU | | lunch-ios-1 |
| Copyright | | 2026 Lei Ding |
| Support URL | | https://lunch.iapp.au/support/ |
| Marketing URL | | https://lunch.iapp.au/ |
| Privacy Policy URL | | https://lunch.iapp.au/privacy/ |

## Promotional text (170)

Stuck on what to eat? Tap once for a lunch pick near you, keep an eye on your weekly food budget, and invite friends to a group lunch with a link.

## Keywords (100, comma separated, no spaces)

lunch,restaurant,nearby,food,budget,meal,tracker,group,invite,eat,dining,split,bill,cafe,decide

## Description (4000)

What We Have For Lunch answers the daily question in one tap, then helps you keep lunch within budget.

DECIDE FAST
• Tap "I am hungry" for a pick near you, chosen from your distance, budget and dietary needs.
• Browse Discover for restaurants around you, with filters, ratings, directions and whether a place is open now.
• Prefer not to share your location? Choose a suburb or address instead.

KEEP LUNCH ON BUDGET
• Log what you ate in a few seconds.
• Set a weekly budget and watch the ring show what is left.
• Split a bill evenly or by amount and share the result.

EAT TOGETHER
• Accept a group lunch invitation from a link or QR code. Guests do not need an account.
• Suggest another place or time, add the lunch to your calendar and get a reminder an hour before.

AI PICKS, WITH YOUR PERMISSION
• Describe a craving and get suggestions from real places nearby.
• Nothing is sent to an AI provider until you agree, and the app names each provider first.
• A free account includes 1 AI request a day.

YOUR DATA
• Your meal journal, budget and favourites stay on your iPhone.
• No ads and no tracking.
• Export your data at any time, and delete your account in Profile.

LUNCH PRO
Lunch Pro is an optional auto-renewing subscription:
• Host group lunches and invite friends
• 10 AI requests a day, shared between personal and group suggestions
• Full meal history and insights (free accounts see the last 30 days)
• Unlimited favourites (free accounts keep up to 10)
• PDF meal reports

Lunch Pro Monthly: A$4.99 a month. Lunch Pro Yearly: A$29.99 a year.
Payment is charged to your Apple Account when you confirm the purchase. The subscription renews automatically at the same price unless you cancel at least 24 hours before the end of the current period. Manage or cancel it in your Apple Account settings. AI allowances reset at 00:00 UTC.

Restaurant details come from Google Maps and can change; confirm allergens and opening hours with the venue. The app does not give medical or dietary advice.

Terms of Use: https://lunch.iapp.au/terms/
Privacy Policy: https://lunch.iapp.au/privacy/

## What's New (version 1.0)

The first release of the rebuilt What We Have For Lunch.

## Subscriptions (App Store Connect → Subscriptions)

Group reference name: Lunch Pro. Group display name: Lunch Pro. Australia only, no introductory offer.

| Product id | Reference name | Duration | Price | Display name | Description (55) |
|---|---|---|---|---|---|
| au.iapp.lunch.pro.yearly | Lunch Pro Yearly | 1 year | A$29.99 | Lunch Pro Yearly | Host group lunches, 10 AI requests a day, full history |
| au.iapp.lunch.pro.monthly | Lunch Pro Monthly | 1 month | A$4.99 | Lunch Pro Monthly | Host group lunches, 10 AI requests a day, full history |

Rank the yearly product above the monthly one in the group. The review screenshot for each
product is the paywall from a sandbox-signed device build, so that the real store price shows.

Review note for both products: "Unlocks group lunch hosting, 10 AI requests a day, full meal
history, unlimited favourites and PDF reports. Reach the paywall from Profile → See Lunch Pro."

## App Review information

Contact: Lei Ding, hello@iapp.au, phone `<Ray: number>`.

Sign-in required: yes. Demo account: `<Ray: create an email account in the TestFlight build and enter its email and password here>`.

Notes:

```
What We Have For Lunch suggests nearby restaurants, tracks a lunch budget on the device, and
lets people plan a group lunch through an invitation link.

ACCOUNT
- Most of the app works without an account: Discover, Track, budget and accepting an invitation.
- An account is needed for AI requests, purchases and hosting a group. Sign in with Apple,
  Google or email is in Profile. The demo account above is an email account.
- Account deletion: Profile → Delete account (shown when signed in).

LOCATION
- Location is optional. Tap "Choose search area" to enter a suburb or address instead.

AI RECOMMENDATIONS
- Home → tap "I AM HUNGRY" → on the pick, tap "Why this?" or "Show me more". The app asks for permission and names each AI provider before any data
  is sent. Consent can be withdrawn in Profile.
- A free account can make 1 AI request per UTC day. Lunch Pro allows 10.

SUBSCRIPTION
- Profile → See Lunch Pro. Two auto-renewing products in one group: monthly and yearly.
- The purchase and Restore Purchases need a signed-in account, so that the subscription
  follows the account. Please sign in with the demo account first.
- After purchase, Home → Lunch together → "Plan a group lunch" is unlocked.

GROUP LUNCHES AND USER CONTENT
- A host creates a lunch and shares a link (https://lunch.iapp.au/i/<code>) or a QR code.
- Guests can respond without an account, and can report content or block the host from the
  invitation screen. Shared text passes an abuse filter. Reports reach hello@iapp.au.

NOTIFICATIONS
- The only notification is a local reminder one hour before a lunch the user accepted.
  The app does not use remote push notifications.
```

## App Privacy answers

Fill these from the privacy report of the uploaded archive (Xcode Organizer → Generate Privacy
Report), which also includes the SDKs. The app's own manifest declares the following. Tracking:
**No** for every type.

| Data type | Linked to the user | Purposes |
|---|---|---|
| Name | Yes | App Functionality |
| Email Address | Yes | App Functionality |
| Health (dietary needs and allergens) | Yes | App Functionality, Product Personalisation |
| Other Financial Info (lunch budget) | Yes | App Functionality, Product Personalisation |
| Precise Location | Yes | App Functionality, Product Personalisation |
| Coarse Location | Yes | App Functionality, Product Personalisation |
| Other User Content (cravings, group names, suggestions) | Yes | App Functionality, Product Personalisation |
| User ID | Yes | App Functionality |
| Purchase History | Yes | App Functionality |
| Product Interaction (AI usage counts) | Yes | App Functionality, Product Personalisation |
| Crash Data | No | App Functionality |
| Performance Data | No | App Functionality |
| Other Diagnostic Data | No | App Functionality |

Device ID is not collected: the app registers no push token and uses no advertising identifier.

## Age rating answers

| Question | Answer |
|---|---|
| User-generated content | Yes (group names, guest names, place suggestions; report and block are available) |
| Messaging and chat | No |
| Advertising | No |
| Health or wellness topics | Yes (dietary needs and allergens) |
| Alcohol, tobacco or drug use or references | Infrequent (bars and pubs can appear in restaurant results) |
| Unrestricted web access | No |
| Gambling, contests, violence, sexual content, horror | None |

Expected result: 13+.

## Other version settings

| Setting | Value |
|---|---|
| Export compliance | Uses only exempt encryption (`ITSAppUsesNonExemptEncryption` is false) |
| Content rights | Contains third-party content (Google Maps Platform data, shown under its terms) |
| Digital Services Act trader status | Not a trader; EU storefronts not selected |
| Availability | Australia |
| Price | Free, with in-app purchases |
| Version release | Manual |

## Screenshots

6.9-inch set, 1320 x 2868, PNG without alpha, in `iosApp/screenshots/store/`. They come from the
preview core on the iPhone 17 Pro Max simulator, so they show sample places without photos and
the sample user "Ray". Upload in this order:

1. `01-home.png` — one tap for a pick near you
2. `02-discover.png` — restaurants around you
3. `03-track.png` — the weekly budget ring and the meal log
4. `04-invitation.png` — a group lunch invitation
5. `05-group.png` — hosting a group lunch (Lunch Pro)
6. `06-ai.png` — AI picks, before a request
7. `07-split-bill.png` — split the bill

To capture again: build Debug for the simulator, then for each screen run
`xcrun simctl launch <udid> au.iapp.lunch -previewCore -signedIn 1 -isPro 1 -openRoute <route>`
(`tab:discover`, `tab:track`, `groupDetail:grp_1`, `ai`, `splitBill`; the invitation uses
`-signedIn 0 -openInvite K7P2QX`), wait for the screen, and run `xcrun simctl io <udid> screenshot`.
Remove the alpha channel before upload; App Store Connect rejects PNG files that have one.
