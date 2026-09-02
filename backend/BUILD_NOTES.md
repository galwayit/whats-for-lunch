# Build notes

Judgement calls made where `API.md` was silent or the source left room, plus
open items. Update this file when any of them change.

## Judgement calls

1. **`groups.host_name` column.** `LunchGroup.hostName` is required by the Kotlin model but the table list in API.md has no host name. The column is denormalised at `groups-create` time from the JWT metadata (`full_name` -> `name` -> `display_name` -> email local part -> "Host") so the public invitation page never needs `auth.users`.
2. **Text queries use `places:searchText`.** `searchNearby` has no text filter, so when `query` is non-empty the function calls `searchText` with `includedType: restaurant` and a `locationBias` circle of the same radius. Both share the `places_cache` key (cell + radius + normalised query). `maxPrice` / `minRating` are applied after mapping so they never fragment the cache.
3. **Cache radius is rounded to 0.5 km** (`nearby.ts: cacheRadius`) so 2.0 and 2.2 km requests share a row. Results outside `radiusKm + 0.5` are dropped after the distance is recomputed from the exact request point.
4. **Free quota is incremented before the Gemini call and refunded on failure** (`increment_ai_usage(..., -1)`), so a Gemini outage does not burn the single free request but concurrent requests cannot sneak past the limit.
5. **`AiRecommendation.userId` is `0`.** The backend does not know the client's local SQLite user id; the client should overwrite it before persisting.
6. **Anonymous web RSVPs use a header, not a cookie.** `invitations-respond` returns `guestToken` once; the page stores it in `localStorage` and sends `x-guest-token` on later calls. Cookies would not survive the app-store redirect flow and the functions domain differs from the page domain.
7. **`groups-confirm` checks host only.** API.md says "auth required, host only"; the Pro check is enforced at create and propose. Once a group exists the host may confirm even if the subscription lapsed.
8. **RevenueCat Pro detection** is "any entitlement id present and not expired". If the project ever ships a non-Pro entitlement, filter `entitlement_ids` to `pro` in `revenuecat.ts`.
9. **TRANSFER carries `expires_at` / `product_id` from the old row** because RevenueCat does not include product fields on TRANSFER events. Old ids are set to `is_pro = false`.
10. **Cuisine mapping for Places API (New)** strips `_restaurant` from a type before looking it up in the legacy label table, and adds `steak_house`, `hamburger`, `coffee_shop` aliases. Fallback "Restaurant" / "Food" and the feature list are unchanged from the Flutter code.
11. **Photo proxy width** is clamped to 64..1600 px; the response is cached by the CDN for a day (`s-maxage=604800`).
12. **`account-delete` also removes `usage` and `ai_requests` rows** keyed by the user id (RevenueCat's anonymous ids for the same person are not linkable server-side and are left alone).
13. **`current_tier()` SQL function is provided but `tier.ts` queries the row directly** so the same logic is unit-tested (`tier_test.ts`). Both apply the same rule.
14. **Realtime**: `rsvps` is added to the `supabase_realtime` publication so the host app can subscribe (RLS still applies).
15. **Rating formatting in the prompt** mimics Dart (`4.0` rather than `4`) so the ported prompt text matches the original byte for byte.

## Not covered by tests (needs the local stack or a project)

- SQL functions (`generate_invite_code`, `increment_ai_usage`, `cleanup_places_cache`) and the RLS policies. Run `supabase start && supabase db reset` and exercise them from the SQL editor before the first deploy.
- Handler wiring against PostgREST (only the pure modules are unit-tested; handlers are thin by design).

## Open items

- `groups-propose` uses only `groups.place_name` of the host's past groups as "past picks"; there is no per-guest history yet.
- No rate limiting on the public `invitations` / `invitations-respond` endpoints beyond input validation. Supabase's gateway limits apply; add a per-IP counter if abuse appears.
- The web page shows generic App Store / Play links; replace `data-ios-url` / `data-android-url` once the listings exist.
