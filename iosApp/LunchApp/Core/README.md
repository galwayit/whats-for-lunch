# Core

Swift mirror of the shared Kotlin contract (`shared/src/commonMain/kotlin/au/iapp/lunch/core/api/Contracts.kt`
and `.../model/Models.kt`). The screens depend only on these protocols and value types, never on
the Kotlin framework directly, so the app builds and runs before `LunchCore.xcframework` exists.

## Mapping from Kotlin

| Kotlin | Swift |
| --- | --- |
| `interface Foo` | `protocol Foo` (same member names) |
| `suspend fun f(): Result<T>` | `func f() async throws -> T`, throwing `CoreError` |
| `val x: StateFlow<T>` | `var x: T { get }` + `var xUpdates: AsyncStream<T>` |
| `fun f(): Flow<T>` | `func f() -> AsyncStream<T>` |
| `data class` | `struct` with the same fields; `Long` is `Int64`, epoch seconds stay seconds |
| `enum class FOO_BAR` | `case fooBar` |
| `sealed class CoreError` | `enum CoreError` |
| `interface LunchCore` | `protocol LunchCoreClient` (plus `location`, injected by the app) |
| `interface Clock` | `protocol LunchClock` (avoids the SwiftUI/Foundation `Clock` protocol) |

`Date` conveniences on `Meal`, `LunchGroup` and `SubscriptionStatus` and `Restaurant.photoURL`
exist for views only; they are not part of the contract.

## Implementations

- `Core/Preview/PreviewLunchCore` - in-memory implementation with realistic Sydney/Melbourne data.
  Selected by the `-previewCore` launch argument (see `App/LaunchArguments.swift` for the flags).
- `Core/Engines/*` - pure Swift ports of the four Kotlin engines. They implement the same rules as
  `shared/.../core/engine/*Impl.kt` and are what previews and unit tests use.
- `Core/NotConfiguredCore` - the placeholder shown until the Kotlin framework is linked.

## The SKIE adapter (next milestone)

`KotlinLunchCore: LunchCoreClient` will wrap the framework's `LunchCore` instance: each property
forwards to the Kotlin object, SKIE turns `suspend` into `async throws` and `Flow` into
`AsyncSequence` (wrap in `AsyncStream`), `Result` failures are rethrown as `CoreError`, and the
models are converted field-by-field (Kotlin `Long` -> `Int64`, enum ordinals -> Swift cases). Nothing
in `Features/` needs to change for that swap; only `LunchApp.swift` picks the implementation.
