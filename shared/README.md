# shared — Kotlin Multiplatform core

Everything the user cannot see: domain rules, SQLite, networking, purchases, auth, groups.
Consumed by `androidApp` as a Gradle module and by `iosApp` as the `LunchCore` XCFramework
(SKIE makes `Flow` an `AsyncSequence` and sealed classes Swift enums).

Public surface: `au.iapp.lunch.core.api.Contracts.kt` and `model/Models.kt`. Apps depend on nothing else.

## Database compatibility with the Flutter app (must hold)

The Flutter app created `diet_buddy.sqlite` with Drift at **schema version 6**
(`PRAGMA user_version = 6`). The native apps open the same file. Rules:

- Table names are Drift's snake_case of the Dart class names, including the quirks:
  `users`, `meals`, `budget_trackings`, `restaurants`, `restaurant_cache`, `dietary_compatibility`,
  `user_discovery_history`, `a_i_recommendations`, `a_i_recommendation_feedback`, `a_i_usage_metrics`,
  `photos`, `user_restaurant_interactions`, `meal_outcomes`.
- Column names are snake_case of the Dart getters (`placeId` → `place_id`, `photoIds` → `photo_ids`,
  `recommendedRestaurantIds` → `recommended_restaurant_ids`).
- Types: `IntColumn` → `INTEGER`, `TextColumn` → `TEXT`, `RealColumn` → `REAL`,
  `BoolColumn` → `INTEGER` holding 0/1 (Drift adds `CHECK ("col" IN (0, 1))`),
  `DateTimeColumn` → `INTEGER` holding **Unix seconds**.
- `autoIncrement()` → `INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT`. Non-nullable columns are `NOT NULL`.
  `withDefault(currentDateAndTime)` → `DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))`.
  Text defaults like `'[]'` and `'{}'` are literal.
- Lists and maps are JSON text; `users.preferences` is the JSON produced by `UserPreferences.toJson()` in
  `archive/flutter/lib/domain/entities/user_preferences.dart` (camelCase keys, `allergenSafetyLevels` values are enum indexes).
- Indexes are created with raw SQL in `archive/flutter/lib/data/database/database.dart`
  (`_createOptimizedIndexes`, `_createLearningSignalIndexes`); recreate them with `IF NOT EXISTS`.

Opening strategy: read `user_version`; if 0 run the full create script and set 6; if 6 do nothing;
if 1..5 apply the same incremental steps Drift would (`onUpgrade` in database.dart); if greater than
the version this module knows, refuse to open and surface `CoreError.Service("DB_TOO_NEW", …)`.
Never drop or rename an existing column.

The source of truth for the Dart schema is `archive/flutter/lib/data/database/database.dart`
(table classes at the top). `verifyMigrations` is off in Gradle because the file is owned by Drift history,
not by SQLDelight migrations.

## Fixture vectors

`src/commonTest/resources/fixtures/*.json` hold input/expected pairs for the pure engines. They are derived
from the Flutter implementation and its tests:

- `archive/flutter/lib/presentation/providers/simple_providers.dart` (compatibility score, reasons)
- `archive/flutter/lib/presentation/providers/budget_providers.dart` (weekly state, impact, achievements)
- `archive/flutter/lib/presentation/providers/meal_providers.dart` (smart defaults, categories, budget impact)
- `archive/flutter/lib/presentation/pages/discover_page.dart` (`_sortRestaurants`)
- `archive/flutter/test/presentation/providers/budget_calculations_test.dart` and siblings

## Building

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home
./gradlew :shared:desktopTest          # engines + SQLite on the JVM
./gradlew :shared:testDebugUnitTest    # Android unit tests
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64   # LunchCore.framework for the simulator
```
