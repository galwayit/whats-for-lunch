# shared/ build notes

Working notes for the Kotlin Multiplatform core (`:shared`). Written incrementally so a
resumed session can pick up without re-reading everything. `README.md` in this directory
describes the intended architecture; this file records what was actually built, the
decisions that deviate from the Flutter app or the brief, and what is still open.

## Commands (always from the repo root)

```sh
cd /Users/rayding/galway/what_we_have_for_lunch
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home
./gradlew :shared:compileKotlinDesktop :shared:compileDebugKotlinAndroid   # type-check JVM + Android
./gradlew :shared:desktopTest                                             # 89 tests, all green
./gradlew :shared:testDebugUnitTest                                        # Android unit tests
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64                      # LunchCore.framework (see below)
```

`gradlew` only exists at the repo root; running it from `shared/` silently does nothing.
Test reports: `shared/build/test-results/desktopTest/*.xml`.

## Layout

| Source set | Contents |
| --- | --- |
| `commonMain/.../api`, `model` | Public API (`Contracts.kt`, `Models.kt`). Only additive changes are allowed. |
| `commonMain/.../engine` | Pure engines (recommendation, budget, achievements, meal defaults). |
| `commonMain/.../db` | SQLDelight `LunchDatabase` over the Drift v6 schema, row mappers, JSON helpers. |
| `commonMain/.../data` | Repositories over SQLite: users, meals, restaurants (+24 h cache), favourites, achievements. |
| `commonMain/.../network` | `BackendClient` interface, DTOs mirroring `backend/API.md`, Ktor implementation. |
| `commonMain/.../service` | AI recommendations, gates, usage metrics, auth (Supabase), groups, push, entitlement factory (`expect`). |
| `commonMain/.../di` + `LunchCoreImpl`/`LunchCoreFactory` | Koin module and the facade the apps call. |
| `storeMain` | Custom hierarchy group (`androidTarget` + iOS): RevenueCat `purchases-kmp` wrapper and its `actual`. |
| `desktopMain` | JVM actuals: SQLite driver, OkHttp engine, `SystemClock`, `FakeEntitlementRepository`. |
| `androidMain` / `iosMain` | Driver, HTTP engine and clock actuals only. |
| `desktopTest` | All repository/service/network/facade tests plus `support/` helpers. |
| `commonTest` | Engine tests driven by `resources/fixtures/*.json`. |

## Decisions and deviations

- **`store` hierarchy group.** `shared/build.gradle.kts` declares
  `applyDefaultHierarchyTemplate { common { group("store") { withAndroidTarget(); withIos() } } }`
  so the RevenueCat wrapper lives once in `storeMain` instead of being duplicated in
  `androidMain` and `iosMain`. Desktop gets `FakeEntitlementRepository` (in-memory, Pro
  toggled by `setPro`, anonymous id `$RCAnonymousID:desktop-fake`, packages
  `$rc_monthly`/`lunch_pro_monthly` and `$rc_annual`/`lunch_pro_yearly`).
- **Isolated Koin container.** `LunchCoreFactory.start` uses `koinApplication { }` (not
  `startKoin`) so tests can start several cores and a host app's own Koin is untouched.
  `LunchCoreImpl` resolves every dependency lazily. A Swift-friendly
  `start(config, location)` overload exists next to `start(config, location, clock)`;
  the `internal` four-argument overload additionally takes the Ktor engine for tests.
- **`isPro` is updated synchronously with `status`** in both entitlement repositories
  (a `MutableStateFlow` set in the same call) rather than derived with `stateIn`, so
  `GateService` never reads a stale value right after `purchase()`/`setPro()`.
- **Achievements** are stored in `users.preferences` under the `nativeAchievements` key
  as `{ "<id>": unlockedAtEpochSeconds }`. Flutter ignores unknown keys, the Drift schema
  stays at v6, and `UserPreferences` still decodes to defaults for such a row.
  `UserRepository.updatePreferences` re-encodes on top of the stored JSON so unknown keys
  (Flutter's or ours) survive.
- **Favourites** are rows in `user_restaurant_interactions` (`favorited` / `unfavorited`);
  the Flutter app kept them in memory only. Latest row per place wins; the free cap of 10
  is enforced through `GateService` inside the toggle transaction.
- **Meal suggestions** use the `meals.restaurant_name` column directly
  (`restaurantNameFrequency`, 30-day window, top 10 by count then recency) instead of the
  Flutter join through restaurants.
- **Nearby cache key** is (lower-cased trimmed query, lat and lng rounded to 3 decimals);
  TTL 24 h; offline falls back to any stale rows for the same key, otherwise
  `CoreError.Offline`. The radius filter is re-applied to cached results with the haversine
  distance from the new point.
- **Backend error mapping** (`KtorBackendClient`): transport `IOException` ->
  `CoreError.Offline`; `AI_DAILY_LIMIT` / `HOST_REQUIRES_PRO` / `SIGN_IN_REQUIRED` ->
  `CoreError.Gate`; other non-2xx -> `CoreError.Service(code or HTTP_<status>, message)`;
  bodies that fail to decode -> `Service("BAD_RESPONSE")`. Ktor's `ContentNegotiation`
  wraps kotlinx-serialization failures in `io.ktor.serialization.ContentConvertException`
  (`JsonConvertException`), which is not a `SerializationException`; it is caught
  explicitly. `groups-create` returns `{ "group": ... }` (201), decoded via `GroupResponse`.
- **AI usage metrics** (`a_i_usage_metrics`) record one row per recommendation attempt and
  one per feedback submission. Failed attempts store a short label in `error_message`:
  `GATE_<reason>`, `OFFLINE`, `<code>: <message>`, or the exception message.
  `usedToday` counts successful `recommendation` rows inside the local calendar day of
  `Clock.timeZoneId()`.
- **AI recommendation persistence** mirrors the Flutter AIRepository: candidates and
  recommended restaurants are upserted into `restaurants`, the recommendation row stores the
  request context JSON in `user_context`, `expires_at = now + 6 h`, and the backend's
  `userId = 0` is replaced by the local user id.
- **Groups.** `GroupRepository.cancel` returns `Service("GROUP_CANCEL_UNSUPPORTED")`: the
  backend has no cancel function and clients cannot write `groups` directly (RLS).
- **Supabase on desktop.** `createSupabaseClient` with Auth, Postgrest and Functions
  constructs on the JVM without network access; `LunchCoreFactoryTest` relies on this.

## Tests (desktopTest)

`support/` holds `TestClock` (frozen at 1_788_400_000 = 2026-09-03 11:46:40 AEST, Sydney
zone), `TestDb` (temp copy of the Drift v6 fixture or a fresh file), `MockBackend`
(Ktor `MockEngine` routed by function name, records requests, `goOffline()`),
`FakeAuthRepository`, `FakeLocationProvider`, `Samples`. Do not wrap StateFlow waits in
`withTimeout` inside `runTest`: it runs on virtual time and expires as soon as the scheduler
is idle while the flow is fed from a real dispatcher.

| Class | Tests |
| --- | --- |
| `data.UserRepositoryTest` | 6 |
| `data.MealRepositoryTest` | 6 |
| `data.RestaurantRepositoryTest` | 7 |
| `data.FavouritesRepositoryTest` | 3 |
| `data.AchievementRepositoryTest` | 3 |
| `network.KtorBackendClientTest` | 15 (success + gate/error per endpoint group, headers, offline, bad JSON) |
| `service.GateServiceTest` | 5 |
| `service.AiRecommendationServiceTest` | 6 |
| `LunchCoreFactoryTest` | 2 (createUser -> log -> weeklyState; desktop wiring) |
| engines, db, json (pre-existing) | 36 |

## Fixture database

`src/desktopTest/resources/fixtures/diet_buddy_v6_flutter.sqlite`: `PRAGMA user_version = 6`,
13 tables, one row in `users` (id 1, "Demo User", `created_at` 1788327233, `preferences`
`{}`), every other table empty. Booleans are `INTEGER`, timestamps epoch seconds.

## iOS framework

See the section appended below once `:shared:linkDebugFrameworkIosSimulatorArm64` has run.

## Open issues

- `expect`/`actual` classes warning (`SystemClock`) is the Kotlin 2.2 beta notice; add
  `-Xexpect-actual-classes` to the compiler args if it should be silenced.
- Android unit tests (`androidUnitTest`) only cover what `commonTest` shares; the
  repository/service tests are desktop-only by design (JDBC SQLite driver).
- `RevenueCatEntitlementRepository` has no automated test (needs the store SDK); it is
  compiled for Android and iOS but exercised only by hand.
- `AuthRepositoryImpl`, `GroupRepositoryImpl` and `PushRegistrarImpl` are covered only
  through `KtorBackendClientTest` (the HTTP layer) and the Koin wiring test; the Supabase
  Auth/Postgrest paths have no mock in this module.
