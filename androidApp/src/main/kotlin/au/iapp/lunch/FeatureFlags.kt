/**
 * @file FeatureFlags.kt
 * @description Build-time switches for work in progress. Launch extras live in
 * [au.iapp.lunch.app.LaunchArguments]. Mirrors iosApp/LunchApp/App/FeatureFlags.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch

import android.content.Intent
import au.iapp.lunch.app.LaunchArguments

object FeatureFlags {
    /** The real app is the default entry; `--ez gallery true` opens the component gallery instead. */
    const val showRealApp = true

    /** Use the in-memory core even without `--ez previewCore true`. Off so a plain launch shows the gap. */
    const val previewCoreByDefault = false

    /**
     * Intent extra naming the gallery section to open, e.g.
     * `adb shell am start -n <pkg>/.MainActivity --ez gallery true --es gallerySection paywall`.
     */
    const val GALLERY_SECTION_EXTRA = LaunchArguments.GALLERY_SECTION

    fun showsGallery(arguments: LaunchArguments): Boolean = !showRealApp || arguments.showsGallery

    /** The section name passed at launch, or null when absent. */
    fun gallerySectionName(intent: Intent?): String? = intent?.getStringExtra(GALLERY_SECTION_EXTRA)
}
