/**
 * @file LaunchArguments.kt
 * @description Launch extras that pick the core implementation and seed the preview core,
 * mirroring iosApp/LunchApp/App/LaunchArguments.swift. Booleans arrive as `--ez name true`,
 * strings as `--es name value`, e.g.
 * `adb shell am start -n <pkg>/au.iapp.lunch.MainActivity --ez previewCore true --ez isPro true`.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.app

import android.content.Intent
import android.os.Bundle
import au.iapp.lunch.preview.PreviewCoreOptions

data class LaunchArguments(
    /** Use the in-memory `PreviewLunchCore` instead of the configured core. */
    val usesPreviewCore: Boolean = false,
    /** Open the component gallery instead of the app. */
    val showsGallery: Boolean = false,
    val isPro: Boolean = false,
    val isSignedIn: Boolean = false,
    val isOffline: Boolean = false,
    val aiUsedToday: Boolean = false,
    /** Preview runs start past onboarding unless `--ez onboarded false` is passed. */
    val isOnboarded: Boolean = true,
    /** Invitation code to open on launch, as if the app link had been tapped. */
    val inviteCode: String? = null,
    /** Gallery section to open (`--es gallerySection cards`). */
    val gallerySection: String? = null,
    /** Optional route to open on launch, e.g. `paywall` or `budget`; see [AppRoute.fromKey]. */
    val openRoute: String? = null,
) {
    val previewOptions: PreviewCoreOptions
        get() = PreviewCoreOptions(
            isPro = isPro,
            isSignedIn = isSignedIn,
            isOffline = isOffline,
            aiUsedToday = aiUsedToday,
            isOnboarded = isOnboarded,
        )

    companion object {
        const val PREVIEW_CORE = "previewCore"
        const val GALLERY = "gallery"
        const val IS_PRO = "isPro"
        const val SIGNED_IN = "signedIn"
        const val OFFLINE = "offline"
        const val AI_USED_TODAY = "aiUsedToday"
        const val ONBOARDED = "onboarded"
        const val OPEN_INVITE = "openInvite"
        const val GALLERY_SECTION = "gallerySection"
        const val OPEN_ROUTE = "openRoute"

        fun from(intent: Intent?): LaunchArguments = from(intent?.extras)

        fun from(extras: Bundle?): LaunchArguments {
            if (extras == null) return LaunchArguments()
            return from(extras.keySet().associateWith { key -> extras.get(key) })
        }

        /** Pure parser over the extras' values so JVM tests can cover it without a Bundle. */
        fun from(values: Map<String, Any?>): LaunchArguments = LaunchArguments(
            usesPreviewCore = values.flag(PREVIEW_CORE, false),
            showsGallery = values.flag(GALLERY, false),
            isPro = values.flag(IS_PRO, false),
            isSignedIn = values.flag(SIGNED_IN, false),
            isOffline = values.flag(OFFLINE, false),
            aiUsedToday = values.flag(AI_USED_TODAY, false),
            isOnboarded = values.flag(ONBOARDED, true),
            inviteCode = values.text(OPEN_INVITE),
            gallerySection = values.text(GALLERY_SECTION),
            openRoute = values.text(OPEN_ROUTE),
        )

        /** `--ez name true` is the documented form; `--es name 1` / `--es name false` also work. */
        private fun Map<String, Any?>.flag(name: String, default: Boolean): Boolean {
            if (!containsKey(name)) return default
            return when (val raw = get(name)) {
                is Boolean -> raw
                is String -> raw.trim().lowercase() !in setOf("0", "false", "no")
                is Number -> raw.toInt() != 0
                else -> default
            }
        }

        private fun Map<String, Any?>.text(name: String): String? = (get(name) as? String)?.trim()?.takeIf { it.isNotEmpty() }
    }
}
