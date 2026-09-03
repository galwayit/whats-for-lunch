package au.iapp.lunch.core.support

import au.iapp.lunch.core.db.DatabaseFactory
import au.iapp.lunch.core.db.LunchDatabase
import java.io.File

/** Temporary databases for repository tests: a copy of the Drift v6 fixture or a fresh file. */
object TestDb {
    const val FIXTURE = "diet_buddy_v6_flutter.sqlite"

    /** The Flutter fixture (one user: id 1, "Demo User", empty preferences). */
    fun fixture(): LunchDatabase = DatabaseFactory.open(fixturePath())

    fun fixturePath(): String = JvmFixtures.copyToTemp(FIXTURE, ".sqlite").absolutePath

    /** Path of a not-yet-existing file, so the schema is created from scratch. */
    fun newPath(): String = File.createTempFile("lunch-new-", ".sqlite").also { it.delete(); it.deleteOnExit() }.absolutePath

    fun empty(): LunchDatabase = DatabaseFactory.open(newPath())
}
