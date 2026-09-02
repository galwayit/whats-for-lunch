# Lunch backend API (Supabase Edge Functions)

Base URL: `https://<project-ref>.supabase.co/functions/v1`

Every request carries:

- `apikey: <anon key>` and `Authorization: Bearer <anon key or user JWT>`
- `x-app-user-id: <RevenueCat app user id>` (anonymous until sign-in; after sign-in it equals the Supabase user id because the client calls `Purchases.logIn(userId)`)

Responses are JSON. Errors use `{ "error": { "code": "...", "message": "..." } }` with the HTTP status below. Codes the clients map to gates: `AI_DAILY_LIMIT` (402), `HOST_REQUIRES_PRO` (403), `SIGN_IN_REQUIRED` (401).

All timestamps are epoch seconds unless a field name ends in `_at` in Postgres (timestamptz), which the functions convert on the way out.

## POST /places-nearby

Request: `{ "lat": -33.87, "lng": 151.21, "radiusKm": 5, "query": "sushi" | null, "maxPrice": 1..4 | null, "minRating": 0..5 | null }`

Behaviour: geohash the point to a ~1.2 km cell (precision 6); cache key = cell + radius + normalised query. Serve from `places_cache` when `fetched_at` is under 24 h old. Otherwise call Places API (New) `places:searchNearby` with `includedTypes: ["restaurant"]`, field mask `places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.priceLevel,places.types,places.photos,places.currentOpeningHours.openNow`, map to the Restaurant JSON below, store, return.

Response: `{ "restaurants": [Restaurant], "cached": true|false, "fetchedAt": 1725250000 }`

`distanceFromUser` is computed server-side from the request point (haversine, km).

## POST /places-details

Request: `{ "placeId": "ChIJ..." }`

Behaviour: `place_details_cache` for 24 h; otherwise `GET places/{id}` with field mask `id,displayName,formattedAddress,internationalPhoneNumber,websiteUri,location,rating,userRatingCount,priceLevel,types,photos,currentOpeningHours,reviews`.

Response: `{ "restaurant": Restaurant, "reviews": [Review] }`

## GET /places-photo?name=places/ChIJ.../photos/...&maxWidth=800

Proxies the photo media endpoint so the key never reaches the client. Cached by the CDN headers. Returns image bytes.

## POST /ai-recommend

Request:
```json
{
  "cravings": "something light" | null,
  "maxResults": 3,
  "context": {
    "mealType": "lunch",
    "budgetRange": "$$",
    "dietaryPreferences": { "restrictions": [], "allergies": [] },
    "recentMeals": ["Lunch: $18.50 (yesterday)"],
    "location": { "hasLocation": true, "latitude": -33.87, "longitude": 151.21 },
    "temporal": { "hour": 12, "dayOfWeek": 2, "isWeekend": false },
    "preferenceScores": { "price_sensitivity": 0.7 }
  },
  "candidates": [Restaurant]   // at most 20, as the client already has them
}
```

Behaviour:
1. Resolve tier: `entitlements.is_pro` for `x-app-user-id` (or the JWT user id), expired rows count as free.
2. Free tier: read `usage(app_user_id, day)`; if `ai_requests >= 1` respond 402 `AI_DAILY_LIMIT` with `{ "resetsAt": <epoch seconds of next local midnight, computed from the client's tz header x-timezone> }`. Otherwise increment.
3. Build the prompt (ported from `ai_service.dart` `_buildRecommendationPrompt`, kept in `_shared/prompt.ts`), call Gemini `generateContent` with `responseMimeType: application/json`. Model: `gemini-2.5-flash-lite` for free, `gemini-2.5-flash` for Pro. Temperature 0.7, max output tokens 1000.
4. Parse with the same rules as `_parseRecommendationResponse`: drop place ids not in candidates; factor weights from the first recommendation.
5. Log to `ai_requests` (app_user_id, model, tokens, latency_ms, ok).

Response: `{ "recommendation": AiRecommendation }` where `restaurants` are the full candidate objects in ranked order.

## POST /groups-create (auth required)

Request: `{ "name": "Friday team lunch", "scheduledAt": 1725600000, "lat": -33.87, "lng": 151.21, "radiusKm": 2 }`

Behaviour: require JWT; require `entitlements.is_pro` for the user id, else 403 `HOST_REQUIRES_PRO`. Insert into `groups` with a fresh 8-char base32 `invite_code`. Return the group.

## POST /groups-propose (auth required, host only)

Request: `{ "groupId": "uuid" }`

Behaviour: host and Pro checks; nearby search around the group area (uses the same cache); Gemini ranks three places using the host's preferences (sent in the request as `hostPreferences`) and the group's past picks; returns `{ "proposals": [ { "restaurant": Restaurant, "reasons": ["..."] } ] }`. Counts as one AI request but never against a free quota (hosts are Pro by construction).

## POST /groups-confirm (auth required, host only)

Request: `{ "groupId": "uuid", "placeId": "...", "placeName": "...", "placeAddress": "..." }` → updates the group, fans out an `invitation` push to guests who already have a pending rsvp with a device token. Response: `{ "group": LunchGroup }`.

## GET /invitations?code=ABCD1234

Public. Response: `{ "invitation": Invitation }`. Used by the apps and by the web landing page.

## POST /invitations-respond

Request: `{ "code": "ABCD1234", "status": "accepted" | "declined", "displayName": "Sam" | null }`

Behaviour: if a JWT is present, upsert `rsvps` on (group_id, guest_user_id); otherwise insert a row with `display_name` and a `guest_token` cookie value the web page keeps. Push `rsvp` to the host. Response: `{ "invitation": Invitation }`.

## POST /push-register

Request: `{ "token": "...", "platform": "ios" | "android" }` → upsert `device_tokens` keyed by app user id (or user id when signed in).

## POST /revenuecat-webhook

Header `Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>`. Body is RevenueCat's event envelope. Upsert `entitlements(app_user_id, is_pro, expires_at, product_id, source='revenuecat')` from `event.app_user_id`, `event.entitlement_ids`, `event.expiration_at_ms`, and treat `CANCELLATION`, `EXPIRATION`, `BILLING_ISSUE` as still-active until `expires_at`. Also handle `TRANSFER` (move entitlement to the new app user id).

## Shared JSON shapes

`Restaurant` mirrors `au.iapp.lunch.core.model.Restaurant` (camelCase keys, epoch seconds). `Review` mirrors `RestaurantReview`. `AiRecommendation`, `LunchGroup`, `Rsvp`, `Invitation` mirror the Kotlin models.

## Tables (see migrations)

- `entitlements(app_user_id text pk, is_pro bool, product_id text, expires_at timestamptz, source text, updated_at timestamptz)`
- `usage(app_user_id text, day date, ai_requests int, pk(app_user_id, day))`
- `ai_requests(id bigserial, app_user_id, model, tokens int, latency_ms int, ok bool, error text, created_at)`
- `places_cache(cell text, radius_km numeric, query text, payload jsonb, fetched_at, pk(cell, radius_km, query))`
- `place_details_cache(place_id text pk, payload jsonb, fetched_at)`
- `groups(id uuid pk, host_id uuid → auth.users, name, scheduled_at, area_lat, area_lng, radius_km, place_id, place_name, place_address, invite_code text unique, created_at, cancelled_at)`
- `rsvps(id uuid pk, group_id uuid → groups, guest_user_id uuid null → auth.users, guest_token text null, display_name text, status text check in (pending, accepted, declined), responded_at, unique(group_id, guest_user_id), unique(group_id, guest_token))`
- `device_tokens(app_user_id text, user_id uuid null, token text pk, platform text, updated_at)`

Row-level security: `groups` readable by the host and by any user with an rsvp row; writable only through functions (service role). `rsvps` readable by the group host and the guest. `entitlements`, `usage`, caches, `device_tokens`: service role only.

## Secrets (set with `supabase secrets set`, never committed)

`GOOGLE_PLACES_API_KEY`, `GEMINI_API_KEY`, `REVENUECAT_WEBHOOK_SECRET`, `FCM_SERVICE_ACCOUNT_JSON`, `INVITE_LINK_BASE` (e.g. `https://lunch.iapp.au/i/`).

## Implementation notes (deviations decided during the build; details in BUILD_NOTES.md)

- `groups.host_name` column added so `LunchGroup.hostName` can be returned without a join; taken from the JWT metadata at create time.
- A non-empty `query` uses Places `places:searchText` (searchNearby has no keyword filter); `maxPrice` and `minRating` are applied after the cache lookup so they do not fragment the cache; the cache radius is rounded to 0.5 km.
- The free AI quota is incremented before the Gemini call and refunded with `increment_ai_usage(app_user_id, day, -1)` when the call fails.
- `AiRecommendation.userId` is `0` in backend responses; the client substitutes its local user id when persisting.
- Anonymous web guests receive a `guestToken` in the respond response and send it back as the `x-guest-token` header (stored in localStorage) instead of a cookie.
- `groups-confirm` verifies the host only; the Pro check happens at create and propose.
- `rsvps` is in the realtime publication so a host screen can subscribe if wanted; the apps poll on resume by default.
