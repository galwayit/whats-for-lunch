package au.iapp.lunch.core.db

import app.cash.sqldelight.db.SqlDriver

/**
 * The incremental steps of Drift's `onUpgrade` in database.dart, replayed for
 * a file whose `user_version` is 1..5. Each step is idempotent
 * (`IF NOT EXISTS`) exactly as Drift's `Migrator` emits it, and no existing
 * column is ever dropped or renamed.
 */
internal object DriftMigrations {

    /** Applies every step needed to bring [fromVersion] up to [DriftSchemaV6.VERSION]. */
    fun apply(driver: SqlDriver, fromVersion: Long) {
        if (fromVersion < 2) {
            // v2: RestaurantCache, DietaryCompatibility, UserDiscoveryHistory
            createTables(driver, "restaurant_cache", "dietary_compatibility", "user_discovery_history")
        }
        if (fromVersion < 3) {
            // v3: AI tables and Photos
            createTables(driver, "a_i_recommendations", "a_i_recommendation_feedback", "a_i_usage_metrics", "photos")
        }
        if (fromVersion < 4) {
            // v4: performance indexes
            DriftSchemaV6.optimizedIndexes.forEach { driver.execute(null, it, 0) }
        }
        if (fromVersion < 5) {
            // v5: meals.restaurant_name (Drift's Migrator.addColumn output)
            driver.execute(null, """ALTER TABLE "meals" ADD COLUMN "restaurant_name" TEXT NULL;""", 0)
        }
        if (fromVersion < 6) {
            // v6: AI learning signal tables and their indexes
            createTables(driver, "user_restaurant_interactions", "meal_outcomes")
            DriftSchemaV6.learningSignalIndexes.forEach { driver.execute(null, it, 0) }
        }
    }

    private fun createTables(driver: SqlDriver, vararg names: String) {
        for (name in names) {
            val ddl = DriftSchemaV6.tables.getValue(name)
            driver.execute(null, ddl, 0)
        }
    }
}
