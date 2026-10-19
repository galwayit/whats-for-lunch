/**
 * @file LunchConfig.kt
 * @description Backend configuration read from `BuildConfig` (fed by Gradle properties or
 * environment variables, see androidApp/build.gradle.kts). Every value is optional and the app
 * runs without them: the core is simply reported as not configured. Mirrors
 * iosApp/LunchApp/App/LunchConfig.swift, including invitation-link parsing.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.app

import android.net.Uri
import au.iapp.lunch.BuildConfig

data class LunchConfig(
    val supabaseUrl: String? = null,
    val supabaseAnonKey: String? = null,
    val backendBaseUrl: String? = null,
    val revenueCatApiKey: String? = null,
    val inviteLinkBase: String = DEFAULT_INVITE_LINK_BASE,
    val googleServerClientId: String? = null,
) {
    /** True once every value the Kotlin core needs is present. */
    val isComplete: Boolean
        get() = supabaseUrl != null && supabaseAnonKey != null && backendBaseUrl != null && revenueCatApiKey != null

    fun inviteUrl(code: String): String =
        if (inviteLinkBase.endsWith("/")) inviteLinkBase + code else "$inviteLinkBase/$code"

    companion object {
        const val DEFAULT_INVITE_LINK_BASE = "https://lunch.iapp.au/i"
        const val INVITE_HOST = "lunch.iapp.au"
        private val INVITE_PATHS = setOf("i", "invite")

        val current: LunchConfig by lazy {
            LunchConfig(
                supabaseUrl = value(BuildConfig.LUNCH_SUPABASE_URL),
                supabaseAnonKey = value(BuildConfig.LUNCH_SUPABASE_ANON_KEY),
                backendBaseUrl = value(BuildConfig.LUNCH_BACKEND_BASE_URL),
                revenueCatApiKey = value(BuildConfig.LUNCH_REVENUECAT_API_KEY),
                googleServerClientId = value(BuildConfig.LUNCH_GOOGLE_SERVER_CLIENT_ID),
                inviteLinkBase = value(BuildConfig.LUNCH_INVITE_LINK_BASE) ?: DEFAULT_INVITE_LINK_BASE,
            )
        }

        /** Empty strings and untouched `YOUR_...` placeholders count as absent. */
        fun value(raw: String?): String? = raw?.trim()?.takeIf { it.isNotEmpty() && !it.contains("YOUR") }

        /** Extracts the code from `https://lunch.iapp.au/i/<code>` (or `/invite/<code>`); null otherwise. */
        fun inviteCode(uri: Uri?): String? {
            if (uri == null || !uri.host.equals(INVITE_HOST, ignoreCase = true)) return null
            val parts = uri.pathSegments.filter { it.isNotEmpty() }
            if (parts.size != 2 || parts[0].lowercase() !in INVITE_PATHS) return null
            return parts[1].takeIf { it.isNotEmpty() }
        }
    }
}
