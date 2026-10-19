/**
 * @file PayIdStore.kt
 * @description Remembers the split sheet's optional "Pay me at" text (a PayID, BSB and account,
 * or "cash") on this device only. It is never synced or sent; the app also opts out of Android
 * backup (`allowBackup="false"`), so it does not leave the phone that way either.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features.split

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

interface PayIdStore {
    /** The saved text, or "" when nothing is saved. */
    fun load(): String

    /** Saves [value]; blank text clears it. */
    fun save(value: String)
}

class SharedPreferencesPayIdStore(private val prefs: SharedPreferences) : PayIdStore {
    override fun load(): String = prefs.getString(KEY, null).orEmpty()

    override fun save(value: String) = prefs.edit {
        if (value.isBlank()) remove(KEY) else putString(KEY, value)
    }

    companion object {
        const val PREFS_NAME = "lunch_split_bill"
        const val KEY = "pay_me_at"

        fun from(context: Context): SharedPreferencesPayIdStore =
            SharedPreferencesPayIdStore(context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE))
    }
}
