package au.iapp.lunch.core.db

import app.cash.sqldelight.db.SqlDriver

/**
 * Creates the platform SQLite driver for the file at [absolutePath].
 *
 * Android and iOS drivers are constructed with [LunchSchema] so the platform
 * open helper creates or migrates the file; desktop returns a bare JDBC
 * driver and [DatabaseOpener] does the work. A file newer than schema v6
 * surfaces as `CoreError.Service("DB_TOO_NEW")` on every platform.
 */
internal expect fun createSqlDriver(absolutePath: String): SqlDriver
