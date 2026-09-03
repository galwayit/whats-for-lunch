package au.iapp.lunch.core.db

import app.cash.sqldelight.db.AfterVersion
import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlSchema
import au.iapp.lunch.core.model.CoreError

/**
 * Drift-compatible schema handed to the platform drivers (Android's
 * SQLiteOpenHelper and SQLiter on iOS run [create] / [migrate] and stamp
 * `user_version` themselves). The desktop JDBC driver has no such hook, so
 * [DatabaseOpener] performs the same steps explicitly.
 */
internal object LunchSchema : SqlSchema<QueryResult.Value<Unit>> {

    override val version: Long = DriftSchemaV6.VERSION

    override fun create(driver: SqlDriver): QueryResult.Value<Unit> {
        DriftSchemaV6.createStatements.forEach { driver.execute(null, it, 0) }
        return QueryResult.Unit
    }

    override fun migrate(
        driver: SqlDriver,
        oldVersion: Long,
        newVersion: Long,
        vararg callbacks: AfterVersion,
    ): QueryResult.Value<Unit> {
        if (oldVersion > newVersion) throw tooNew(oldVersion)
        DriftMigrations.apply(driver, oldVersion)
        return QueryResult.Unit
    }

    /** The error surfaced when a file was written by a newer schema than this module knows. */
    fun tooNew(fileVersion: Long): CoreError.Service = CoreError.Service(
        code = DB_TOO_NEW,
        message = "diet_buddy.sqlite is at schema version $fileVersion but this build supports up to ${DriftSchemaV6.VERSION}",
    )

    const val DB_TOO_NEW = "DB_TOO_NEW"
}
