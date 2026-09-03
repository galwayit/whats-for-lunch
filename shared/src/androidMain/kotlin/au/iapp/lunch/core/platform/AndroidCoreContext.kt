package au.iapp.lunch.core.platform

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri

/**
 * Holds the application [Context] the SQLite driver needs. It is captured
 * automatically by [LunchCoreInitProvider] (declared in this module's
 * manifest) before `Application.onCreate`, so apps do not have to pass a
 * context to `LunchCoreFactory.start`. [install] exists for tests and for
 * apps that disable manifest merging.
 */
object AndroidCoreContext {
    @Volatile
    private var appContext: Context? = null

    fun install(context: Context) {
        appContext = context.applicationContext ?: context
    }

    internal fun require(): Context = appContext
        ?: error("LunchCore has no Android Context; ensure LunchCoreInitProvider is in the merged manifest or call AndroidCoreContext.install(context)")
}

/** No-op provider whose only job is to capture the application context early. */
class LunchCoreInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        context?.let { AndroidCoreContext.install(it) }
        return true
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
