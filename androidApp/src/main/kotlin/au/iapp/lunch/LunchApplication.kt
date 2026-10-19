/**
 * @file LunchApplication.kt
 * @description Process-wide holder for the [AppEnvironment], so the core outlives activity
 * recreation. The environment is built from the first launch's [LaunchArguments] and rebuilt
 * only when a later launch carries different arguments (screenshot and Maestro runs).
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch

import android.app.Application
import android.content.ComponentCallbacks2
import coil3.ImageLoader
import coil3.SingletonImageLoader
import coil3.memory.MemoryCache
import coil3.request.CachePolicy
import au.iapp.lunch.app.AndroidLocationProvider
import au.iapp.lunch.app.AppEnvironment
import au.iapp.lunch.app.LaunchArguments
import au.iapp.lunch.app.LunchConfig
import au.iapp.lunch.core.LunchCoreFactory
import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.preview.PreviewLocationProvider
import au.iapp.lunch.preview.PreviewLunchCore
import java.io.File
import au.iapp.lunch.ui.features.auth.PreviewSignInTokenProvider

class LunchApplication : Application() {
    private var cached: Pair<LaunchArguments, AppEnvironment>? = null
    private var photoLoader: ImageLoader? = null

    override fun onCreate() {
        super.onCreate()
        SingletonImageLoader.setSafe { context ->
            ImageLoader.Builder(context)
                .memoryCache { MemoryCache.Builder().maxSizeBytes(32L * 1024 * 1024).build() }
                .diskCache(null)
                .diskCachePolicy(CachePolicy.DISABLED)
                .build().also { photoLoader = it }
        }
    }

    @Suppress("DEPRECATION")
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) photoLoader?.memoryCache?.clear()
    }

    /** The environment for [arguments], reusing the current one when the arguments match. */
    @Synchronized
    fun environment(arguments: LaunchArguments): AppEnvironment {
        cached?.let { (args, env) -> if (args == arguments) return env }
        return makeEnvironment(arguments).also { cached = arguments to it }
    }

    private fun makeEnvironment(arguments: LaunchArguments): AppEnvironment {
        if (arguments.usesPreviewCore || FeatureFlags.previewCoreByDefault) {
            return AppEnvironment(core = PreviewLunchCore(arguments.previewOptions), location = PreviewLocationProvider(), signInTokens = PreviewSignInTokenProvider)
        }
        val config = LunchConfig.current
        if (!config.isComplete) {
            // Nothing to talk to: keep the preview core underneath so the screen tree still renders.
            return AppEnvironment(core = PreviewLunchCore(), location = PreviewLocationProvider(), isCoreLinked = false)
        }
        val location = AndroidLocationProvider(this)
        val core = LunchCoreFactory.start(
            CoreConfig(
                supabaseUrl = config.supabaseUrl.orEmpty(),
                supabaseAnonKey = config.supabaseAnonKey.orEmpty(),
                backendBaseUrl = config.backendBaseUrl.orEmpty(),
                revenueCatApiKey = config.revenueCatApiKey.orEmpty(),
                databasePath = File(filesDir, DATABASE_FILE).absolutePath,
                inviteLinkBase = config.inviteUrl(""),
                isDebug = BuildConfig.DEBUG,
            ),
            location,
        )
        return AppEnvironment(core = core, location = location)
    }

    private companion object {
        /** Same file the Flutter app created, so history carries over (see shared/BUILD_NOTES.md). */
        const val DATABASE_FILE = "diet_buddy.sqlite"
    }
}
