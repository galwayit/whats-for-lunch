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
- `Core/KotlinLunchCore` - production adapter over the linked Kotlin framework. It converts
  models explicitly, bridges SKIE flows to `AsyncStream`, and feeds Core Location into KMP.
- `Core/NotConfiguredCore` - safe fallback when `Config/Lunch.plist` is absent or incomplete.

## The SKIE adapter

`KotlinLunchCore: LunchCoreClient` wraps the production framework's `SwiftLunchCore` facade.
SKIE turns Kotlin `suspend` calls into `async throws` and flows into `AsyncSequence`; the adapter
converts those flows to `AsyncStream`, translates `CoreError`, and maps models field-by-field.
Normal launches select it when `Lunch.plist` is complete; `-previewCore` remains deterministic.
