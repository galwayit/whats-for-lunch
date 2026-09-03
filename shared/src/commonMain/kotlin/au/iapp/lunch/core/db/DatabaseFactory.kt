package au.iapp.lunch.core.db

/**
 * Opens the app database at an absolute path using the platform driver
 * (`createSqlDriver`) and the version strategy in [DatabaseOpener].
 *
 * The same `diet_buddy.sqlite` the Flutter app wrote is opened unchanged;
 * see shared/README.md for the compatibility rules.
 */
object DatabaseFactory {
    /**
     * Opens (creating when absent) the SQLite file at [absolutePath].
     * @throws au.iapp.lunch.core.model.CoreError.Service when the file is newer than v6 or cannot be opened.
     */
    fun open(absolutePath: String): LunchDatabase = DatabaseOpener.open(createSqlDriver(absolutePath))
}
