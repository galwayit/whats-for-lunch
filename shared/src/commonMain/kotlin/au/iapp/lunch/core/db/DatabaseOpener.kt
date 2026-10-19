package au.iapp.lunch.core.db

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import au.iapp.lunch.core.model.CoreError

/**
 * Opens `diet_buddy.sqlite` with the strategy from shared/README.md:
 *
 * - `user_version` 0: run the full Drift v6 create script and set 6.
 * - 1..5: replay Drift's incremental `onUpgrade` steps, then set 6.
 * - 6: nothing to do.
 * - greater than 6: refuse with `CoreError.Service("DB_TOO_NEW", ...)`.
 *
 * Platform drivers built with [LunchSchema] have already done this by the
 * time the first statement runs, in which case the read yields 6 and the
 * call is a no-op; the JDBC driver relies on this code entirely.
 */
internal object DatabaseOpener {

    /** Ensures the schema is at v6 and wraps the driver in the generated database. */
    fun open(driver: SqlDriver): LunchDatabase {
        try {
            val version = userVersion(driver)
            when {
                version == 0L -> {
                    LunchSchema.create(driver)
                    setUserVersion(driver, DriftSchemaV6.VERSION)
                }
                version == DriftSchemaV6.VERSION -> Unit
                version in 1 until DriftSchemaV6.VERSION -> {
                    LunchSchema.migrate(driver, version, DriftSchemaV6.VERSION)
                    setUserVersion(driver, DriftSchemaV6.VERSION)
                }
                else -> throw LunchSchema.tooNew(version)
            }
        } catch (e: CoreError) {
            driver.close()
            throw e
        } catch (e: Exception) {
            driver.close()
            throw CoreError.Service(DB_OPEN_FAILED, e.message ?: "Could not open the database")
        }
        // The old app persisted full Google Places responses. Only IDs are retained now.
        driver.execute(null, "DELETE FROM restaurant_cache", 0)
        driver.execute(null, """UPDATE restaurants SET name='Saved place', location='', address=NULL,
            phone_number=NULL, website=NULL, latitude=NULL, longitude=NULL, distance_from_user=NULL,
            rating=NULL, review_count=NULL, price_level=NULL, price_ranges='[]', cuisine_type=NULL,
            cuisine_types='[]', supported_dietary_restrictions='[]', allergen_info='[]', dietary_compatibility_scores='{}',
            has_verified_dietary_info=0, community_verification_count=0, opening_hours='[]', is_open_now=0,
            current_wait_time=NULL, features='[]', average_meal_cost=NULL, value_score=NULL, meal_type_average_costs='{}',
            cached_at=0, last_verified=NULL, photo_reference=NULL, photo_references='[]'""", 0)
        return LunchDatabase(driver)
    }

    /** Reads `PRAGMA user_version`. */
    fun userVersion(driver: SqlDriver): Long =
        driver.executeQuery(
            identifier = null,
            sql = "PRAGMA user_version",
            mapper = { cursor ->
                cursor.next()
                QueryResult.Value(cursor.getLong(0) ?: 0L)
            },
            parameters = 0,
        ).value

    private fun setUserVersion(driver: SqlDriver, version: Long) {
        driver.execute(null, "PRAGMA user_version = $version", 0)
    }

    const val DB_OPEN_FAILED = "DB_OPEN_FAILED"
}
