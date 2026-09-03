package au.iapp.lunch.core.db

import androidx.sqlite.db.SupportSQLiteDatabase
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import au.iapp.lunch.core.platform.AndroidCoreContext

/**
 * Android framework driver. [absolutePath] is passed as the database name;
 * `Context.getDatabasePath` accepts absolute paths, so the Flutter-created
 * file in the app documents directory is opened in place. A newer file makes
 * SQLiteOpenHelper call `onDowngrade`, which is turned into DB_TOO_NEW.
 */
internal actual fun createSqlDriver(absolutePath: String): SqlDriver =
    AndroidSqliteDriver(
        schema = LunchSchema,
        context = AndroidCoreContext.require(),
        name = absolutePath,
        callback = DowngradeGuard,
    )

private object DowngradeGuard : AndroidSqliteDriver.Callback(LunchSchema) {
    override fun onDowngrade(db: SupportSQLiteDatabase, oldVersion: Int, newVersion: Int) {
        throw LunchSchema.tooNew(oldVersion.toLong())
    }
}
