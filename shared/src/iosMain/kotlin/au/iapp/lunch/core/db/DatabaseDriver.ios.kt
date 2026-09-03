package au.iapp.lunch.core.db

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import co.touchlab.sqliter.DatabaseConfiguration

/**
 * SQLiter driver. The absolute path is split into the directory (`basePath`)
 * and the file name so the Flutter-created file is opened in place. SQLiter
 * routes a version mismatch through [LunchSchema.migrate], which throws
 * DB_TOO_NEW when the file is newer than this module.
 */
internal actual fun createSqlDriver(absolutePath: String): SqlDriver {
    val separator = absolutePath.lastIndexOf('/')
    val directory = if (separator > 0) absolutePath.substring(0, separator) else null
    val fileName = absolutePath.substring(separator + 1)
    return NativeSqliteDriver(
        schema = LunchSchema,
        name = fileName,
        onConfiguration = { config: DatabaseConfiguration ->
            config.copy(extendedConfig = DatabaseConfiguration.Extended(basePath = directory))
        },
    )
}
