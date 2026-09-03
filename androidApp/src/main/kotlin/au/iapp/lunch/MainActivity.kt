/**
 * @file MainActivity.kt
 * @description Single activity host. Shows the component gallery until
 * [FeatureFlags.showRealApp] flips, then the four-tab shell.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import au.iapp.lunch.ui.gallery.ComponentGallery
import au.iapp.lunch.ui.gallery.GallerySection
import au.iapp.lunch.ui.navigation.RootScaffold
import au.iapp.lunch.ui.theme.LunchTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val initialSection = GallerySection.fromKey(FeatureFlags.gallerySectionName(intent))
        setContent {
            if (FeatureFlags.showRealApp) {
                LunchTheme { RootScaffold() }
            } else {
                ComponentGallery(initialSection = initialSection)
            }
        }
    }
}
