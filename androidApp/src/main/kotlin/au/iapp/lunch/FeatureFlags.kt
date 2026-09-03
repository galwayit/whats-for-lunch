/**
 * @file FeatureFlags.kt
 * @description Build-time and launch-argument switches for work in progress. Mirrors
 * iosApp/LunchApp/App/FeatureFlags.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch

import android.content.Intent

object FeatureFlags {
    /** Shows the four-tab shell instead of the component gallery. Flip when the screens land. */
    const val showRealApp = false

    /**
     * Intent extra naming the gallery section to open, e.g.
     * `adb shell am start -n <pkg>/.MainActivity --es gallerySection paywall`.
     */
    const val GALLERY_SECTION_EXTRA = "gallerySection"

    /** The section name passed at launch, or null when absent. */
    fun gallerySectionName(intent: Intent?): String? = intent?.getStringExtra(GALLERY_SECTION_EXTRA)
}
