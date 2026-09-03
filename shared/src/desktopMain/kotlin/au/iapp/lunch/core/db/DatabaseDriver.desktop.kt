package au.iapp.lunch.core.db

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver

/** JDBC (sqlite-jdbc) driver; schema handling is left to [DatabaseOpener]. */
internal actual fun createSqlDriver(absolutePath: String): SqlDriver =
    JdbcSqliteDriver("jdbc:sqlite:$absolutePath")
