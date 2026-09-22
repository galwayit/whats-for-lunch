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
./gradlew :shared:desktopTest                                             # 105 tests, all green
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
| `commonMain/.../swift` | Swift facade: throwing wrappers over the contracts, `SwiftLunchCore`, `SwiftLunchCoreFactory`, `ExternalLocationProvider` (see below). |
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
- **Groups.** `GroupRepository.cancel` calls the authenticated `groups-cancel` function.
  Cancellation is host-only, idempotent, and preserves the row while setting `cancelled_at`;
  invitation and group-list queries exclude cancelled groups.
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
| `swift.SwiftFacadeTest` | 7 (value returned, `CoreError` rethrown unchanged, foreign exception -> `Unknown`, cancellation untouched, Flow pass-through) |
| `swift.ExternalLocationProviderTest` | 7 (permission gating, latest fix, negative accuracy, first-fix wait, clear, revoke/regrant) |
| `swift.SwiftLunchCoreFactoryTest` | 2 (typed onboarding -> log -> inRange through the facade; Swift entry point wiring) |
| engines, db, json (pre-existing) | 36 |

## Fixture database

`src/commonTest/resources/fixtures/diet_buddy_v6_flutter.sqlite`: `PRAGMA user_version = 6`,
13 tables, one row in `users` (id 1, "Demo User", `created_at` 1788327233, `preferences`
`{}`), every other table empty. Booleans are `INTEGER`, timestamps epoch seconds.

## iOS framework

`./gradlew :shared:linkDebugFrameworkIosSimulatorArm64` (about 1 min warm) produces
`shared/build/bin/iosSimulatorArm64/debugFramework/LunchCore.framework` (static, ~80 MB
debug). SKIE 0.10.14 adds `Modules/LunchCore.swiftmodule` and `Headers/LunchCore-Swift.h`,
so Swift sees `suspend` functions as `async` and `Flow` as `AsyncSequence`. Device builds
use `:shared:linkDebugFrameworkIosArm64`; Xcode should call
`:shared:embedAndSignAppleFrameworkForXcode` from a Run Script phase (see
`iosApp/LunchApp/Core/README.md` for the adapter plan).

Constraints discovered while linking (2026-09-03):

- The RevenueCat, Kotlin, SKIE and Xcode versions move as one chain and must be bumped
  together (resolved 2026-09-23). `purchases-kmp` 3.9.0 needs Kotlin >= 2.3, which needs
  SKIE 0.10.14 (Kotlin 2.4.10), which needs Gradle >= 8.14.4. On the Xcode side the
  `purchases-hybrid-common` SPM pin must resolve to the same `purchases-ios` that the
  Kotlin SDK was built against: `purchases-kmp` 3.9.0 uses `purchases-ios` 5.89.0, which
  `purchases-hybrid-common` 19.0.0 pins exactly. Getting this wrong fails late, at the
  app link step, not at Gradle resolution.
- Do not go back to `purchases-kmp` 2.10.2+17.55.1. It pins `purchases-ios` 5.67.1, whose
  `PaywallColor.swift` does not compile under Swift 6.4 (Xcode 27): the compiler now
  synthesises a memberwise `init(stringRepresentation:)` that collides with the
  hand-written one. Every 3.x klib is compiled with Kotlin 2.3.20 or newer
  (klib `abi_version >= 2.3.0`), so an older Kotlin native resolver skips it with a
  misleading `KLIB resolver: Could not find ... .klib`.
- `commonMain` must stay off JVM-only collection APIs (`putIfAbsent`,
  `computeIfAbsent`, `java.*`); the desktop and Android compilations accept them, only
  the Kotlin/Native compilation rejects them.
- The RevenueCat iOS SDK itself (`PurchasesHybridCommon`) is an SPM dependency of the
  Xcode app target; `RevenueCatEntitlementRepository` cannot run on a device without it.
  The Kotlin framework itself links without it because the cinterop is header-only, but
  the app has ~221 undefined RevenueCat symbols that only the SPM product satisfies.

## Swift facade (`au.iapp.lunch.core.swift`, 2026-09-03)

**Why.** `kotlin.Result<T>` is a value class and the Objective-C export erases it to
`id`/`Any?`, so SKIE emitted `func log(meal: Meal) async throws -> Any?` for all 34
`Result`-returning suspend members of `Contracts.kt`. Swift needs typed values and typed
errors, and `Contracts.kt` must stay untouched (the apps code against it), so the fix is an
additive layer that never lets a `Result` cross the boundary.

**Files** (`src/commonMain/kotlin/au/iapp/lunch/core/swift/`):

| File | Contents |
| --- | --- |
| `SwiftErrors.kt` | `internal inline fun <T> unwrap(block: () -> Result<T>): T`, the single Result-to-exception bridge. |
| `SwiftRepositories.kt` | `SwiftUserRepository`, `SwiftMealRepository`, `SwiftRestaurantRepository`, `SwiftFavouritesRepository`, `SwiftAchievementRepository`. |
| `SwiftServices.kt` | `SwiftAiRecommendationService`, `SwiftEntitlementRepository`, `SwiftAuthRepository`, `SwiftGroupRepository`, `SwiftPushRegistrar`. |
| `SwiftLunchCore.kt` | `SwiftLunchCore(core: LunchCore)`: one lazily created wrapper per `LunchCore` property, same names; `gates`, the four engines and `clock` pass through (no `Result` members). No `close()` because `LunchCore` has none. |
| `SwiftLunchCoreFactory.kt` | `object SwiftLunchCoreFactory { start(config, location: ExternalLocationProvider[, clock]) }` delegating to `LunchCoreFactory.start`. |
| `ExternalLocationProvider.kt` | `LocationProvider` the app feeds from CoreLocation (below). |

**Wrapping rules.** Each wrapper is a plain class taking the contract interface (it does not
implement it, because same-name members with different return types cannot coexist):

- `suspend fun f(...): Result<T>` becomes
  `@Throws(CoreError::class, CancellationException::class) suspend fun f(...): T`, same
  name and parameter names, body `unwrap { delegate.f(...) }`.
- `Flow`/`StateFlow` members and every non-`Result` member pass straight through.
- Wrappers are created `by lazy`, so the core keeps its own lazy Koin resolution.

**How Swift starts and uses the core** (import `LunchCore`):

```swift
let location = ExternalLocationProvider()               // keep it; feed it from CLLocationManager
let core = SwiftLunchCoreFactory.shared.start(config: config, location: location)

let user = try await core.users.createUser(name: "Sam", preferences: prefs)   // UserProfile
let mealId = try await core.meals.log(meal: meal)                              // KotlinLong (.int64Value)
let week = try await core.meals.inRange(userId: user.id, startEpochSeconds: a, endEpochSeconds: b) // [Meal]
for await meals in core.meals.observeRecent(userId: user.id, limit: 20, windowDays: nil) { ... } // SkieSwiftFlow<[Meal]>
let done = core.users.hasCompletedOnboarding.value       // SkieSwiftStateFlow<KotlinBoolean>
```

Generated signatures (SKIE 0.10.14, `shared/build/skie/binaries/debugFramework/DEBUG/iosSimulatorArm64/swift/generated/Shared/`):
`createUser(name:preferences:) async throws -> UserProfile`,
`log(meal:) async throws -> KotlinLong`, `restaurantSuggestions(userId:) async throws -> [String]`,
`purchase(packageIdentifier:) async throws -> SubscriptionStatus`, `updateName(name:) async throws -> Void`.
Kotlin/Native boxes primitives in suspend return positions (`KotlinLong`, `KotlinInt`,
`KotlinBoolean`, use `.int64Value` / `.intValue` / `.boolValue`); `Unit` is `Void`; Kotlin
default arguments are not exported, which is why `ExternalLocationProvider` has explicit
overloads and a no-argument constructor.

**Location-provider protocol** (`ExternalLocationProvider`, also a plain `LocationProvider`
for the Kotlin core):

1. `setPermission(granted:)` on every `CLLocationManager.authorizationStatus` change
   (`authorizedWhenInUse`/`authorizedAlways` -> `true`). Denying also drops the last fix.
2. `update(latitude:longitude:accuracyMetres:)` for every fix (`horizontalAccuracy < 0`
   means unknown, stored as `nil`); `update(latitude:longitude:)` when accuracy is unknown.
3. `clear()` when the last fix is no longer trustworthy.

`hasPermission()` returns the last `setPermission` value (`false` initially). `current()`
fails with `CoreError.Service(code: "LOCATION_PERMISSION_DENIED")` while denied; with
permission it returns the latest fix or waits `firstFixTimeoutMillis` (default 10 s, `0`
never waits) for the first one, then fails with `CoreError.Service(code: "NO_LOCATION")`,
the same code as the desktop `FakeLocationProvider`, which `AiRecommendationServiceImpl`
treats as "no location context". Swift-side extras: `currentLocation() async throws ->
Location` (typed twin of `current()`), `permissionIsGranted()`, and the observable
`location: SkieSwiftOptionalStateFlow<Location>` / `permissionGranted: SkieSwiftStateFlow<KotlinBoolean>`.
`withTimeoutOrNull` inside `current()` is safe under `runTest` because the fix is fed from
the same test dispatcher (`launch { delay(...); update(...) }`), unlike the real-dispatcher
case noted under Tests.

**Exception mapping.** `unwrap` turns a `Result` into a return value or a thrown `CoreError`:

| Kotlin outcome | Swift sees |
| --- | --- |
| `Result.success(v)` | `v` returned |
| `Result.failure(CoreError)` or a thrown `CoreError` | the same `CoreError` instance |
| `Result.failure(other)` or any other thrown `Throwable` | `CoreError.Unknown(cause: other)` |
| `CancellationException` (thrown or carried) | propagated unchanged, so `Task` cancellation still works |

Kotlin exceptions reach Swift as `NSError`; the Kotlin object is in
`userInfo["KotlinException"]`, and the sealed hierarchy is switchable through SKIE:

```swift
do { _ = try await core.meals.log(meal: meal) }
catch {
    guard let coreError = (error as NSError).userInfo["KotlinException"] as? CoreError else { throw error }
    switch onEnum(of: coreError) {
    case .offline: ...
    case .service(let e): ... e.code, e.message
    case .gate(let e): ... e.reason
    case .notSignedIn: ...
    case .unknown(let e): ... e.cause
    }
}
```

All `CoreError` subclasses (`Offline`, `Service`, `Gate`, `NotSignedIn`, `Unknown`) are
exported as `LunchCoreCoreError*` classes and appear in `Shared.CoreError.swift`.

## Open issues

- `expect`/`actual` classes warning (`SystemClock`) is the Kotlin beta notice; add
  `-Xexpect-actual-classes` to the compiler args if it should be silenced.
- Android unit tests (`androidUnitTest`) only cover what `commonTest` shares; the
  repository/service tests are desktop-only by design (JDBC SQLite driver).
- `RevenueCatEntitlementRepository` has no automated test (needs the store SDK); it is
  compiled for Android and iOS but exercised only by hand.
- `AuthRepositoryImpl`, `GroupRepositoryImpl` and `PushRegistrarImpl` are covered only
  through `KtorBackendClientTest` (the HTTP layer) and the Koin wiring test; the Supabase
  Auth/Postgrest paths have no mock in this module.
