/**
 * @file MainActivity.kt
 * @description Single activity host. Parses [LaunchArguments] from the intent, picks the
 * component gallery, the not-configured screen or the app, and routes invitation links
 * (`https://lunch.iapp.au/i/<code>` and the `openInvite` extra) into the environment.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.app.LaunchArguments
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.app.LunchConfig
import au.iapp.lunch.ui.features.shared.NotConfiguredScreen
import au.iapp.lunch.ui.gallery.ComponentGallery
import au.iapp.lunch.ui.gallery.GallerySection
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.navigation.RootScaffold
import au.iapp.lunch.ui.theme.LunchTheme

class MainActivity : ComponentActivity() {
    private lateinit var environment: AppEnvironment

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        render(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        render(intent)
    }

    private fun render(intent: Intent?) {
        val arguments = LaunchArguments.from(intent)
        if (FeatureFlags.showsGallery(arguments)) {
            setContent { ComponentGallery(initialSection = GallerySection.fromKey(arguments.gallerySection)) }
            return
        }
        environment = (application as LunchApplication).environment(arguments)
        setContent {
            CompositionLocalProvider(LocalAppEnvironment provides environment) {
                LunchTheme {
                    if (environment.isCoreLinked) RootScaffold() else NotConfiguredScreen()
                }
            }
        }
        openLinks(arguments, intent)
    }

    /** Invitation from the app link or the `openInvite` extra, then an optional `openRoute`. */
    private fun openLinks(arguments: LaunchArguments, intent: Intent?) {
        val code = LunchConfig.inviteCode(intent?.data) ?: arguments.inviteCode
        if (code != null) environment.openInvitation(code)
        arguments.openRoute?.let { AppRoute.fromKey(it) }?.let { environment.present(it) }
    }
}
