/**
 * @file AppEnvironment.kt
 * @description App-wide state shared by every screen: the core, the location provider, the
 * clock, mirrored entitlement and session streams, the selected tab, the modal route stack and
 * the toast bus. Provided to the composition through [LocalAppEnvironment]. Mirrors
 * iosApp/LunchApp/App/AppEnvironment.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.app

import androidx.compose.runtime.staticCompositionLocalOf
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.api.LunchCore
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.UserProfile
import au.iapp.lunch.preview.PreviewCoreOptions
import au.iapp.lunch.preview.PreviewLocationProvider
import au.iapp.lunch.preview.PreviewLunchCore
import au.iapp.lunch.ui.components.LunchTab
import au.iapp.lunch.ui.navigation.AppRoute
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import au.iapp.lunch.ui.features.auth.PreviewSignInTokenProvider
import au.iapp.lunch.ui.features.auth.SignInTokenProvider
import au.iapp.lunch.ui.features.auth.UnavailableSignInTokenProvider
import kotlinx.coroutines.flow.update

/** A restaurant handed to the Track tab so the quick log form starts filled in. */
data class MealPrefill(val restaurantId: String?, val restaurantName: String, val cost: Double?) {
    constructor(restaurant: Restaurant) : this(restaurant.placeId, restaurant.name, restaurant.averageMealCost)
}

class AppEnvironment(
    val core: LunchCore,
    val location: LocationProvider,
    /** False when the backend is not configured; the root shows the not-configured screen. */
    val isCoreLinked: Boolean = true,
    /** Identity tokens for the sign-in sheet; real builds have none until a provider is chosen. */
    val signInTokens: SignInTokenProvider = UnavailableSignInTokenProvider,
) {
    val clock: Clock get() = core.clock
    val user: StateFlow<UserProfile?> get() = core.users.current
    val hasCompletedOnboarding: StateFlow<Boolean> get() = core.users.hasCompletedOnboarding
    val isPro: StateFlow<Boolean> get() = core.entitlements.isPro
    val session: StateFlow<AuthSession?> get() = core.auth.session

    private val tab = MutableStateFlow(LunchTab.Home)
    val selectedTab: StateFlow<LunchTab> = tab.asStateFlow()

    /** Modal stack. Index 0 is presented over the tabs, index 1 over that, and so on. */
    private val stack = MutableStateFlow<List<AppRoute>>(emptyList())
    val routes: StateFlow<List<AppRoute>> = stack.asStateFlow()

    /** Transient message shown by the toast host; cleared by it. */
    private val toastMessage = MutableStateFlow<String?>(null)
    val toast: StateFlow<String?> = toastMessage.asStateFlow()

    /** Filled by "Log this meal" on Home, Discover or AI; Track consumes it when it appears. */
    private val prefill = MutableStateFlow<MealPrefill?>(null)
    val mealPrefill: StateFlow<MealPrefill?> = prefill.asStateFlow()

    /** Craving typed on Home (Pro only); the AI screen consumes it when it appears. */
    var aiCravingDraft: String? = null

    /** Set by onboarding so Home runs the first search automatically. */
    var shouldRunFirstSearch: Boolean = false

    fun selectTab(newTab: LunchTab) {
        tab.value = newTab
    }

    fun present(route: AppRoute) {
        stack.update { if (it.lastOrNull() == route) it else it + route }
    }

    /** Dismisses the topmost modal. */
    fun dismiss() {
        stack.update { it.dropLast(1) }
    }

    fun dismissAll() {
        stack.value = emptyList()
    }

    /** Replaces the top modal, so a gate can swap itself for the Paywall or Sign in sheet. */
    fun replaceTop(route: AppRoute) {
        stack.update { if (it.isEmpty()) listOf(route) else it.dropLast(1) + route }
    }

    /** Presents the screen a gate denial asks for; returns false for [GateReason.OK]. */
    fun present(gate: GateReason): Boolean = when (gate) {
        GateReason.HOST_REQUIRES_PRO, GateReason.FAVOURITES_LIMIT, GateReason.HISTORY_WINDOW -> {
            present(AppRoute.Paywall)
            true
        }
        GateReason.SIGN_IN_REQUIRED -> {
            present(AppRoute.SignIn)
            true
        }
        GateReason.AI_DAILY_LIMIT -> if (isPro.value) false else { present(AppRoute.Paywall); true }
        GateReason.OK -> false
    }

    fun openInvitation(code: String) {
        dismissAll()
        present(AppRoute.Invitation(code))
    }

    fun showToast(message: String) {
        toastMessage.value = message
    }

    fun clearToast() {
        toastMessage.value = null
    }

    /** "Log this meal" from any screen: dismisses modals and opens Track with the form filled. */
    fun logMeal(restaurant: Restaurant) {
        prefill.value = MealPrefill(restaurant)
        dismissAll()
        selectTab(LunchTab.Track)
    }

    fun consumeMealPrefill(): MealPrefill? = prefill.getAndUpdate { null }

    companion object {
        /** In-memory environment for previews, tests and `--ez previewCore true` runs. */
        fun preview(options: PreviewCoreOptions = PreviewCoreOptions(), clock: Clock? = null): AppEnvironment {
            val core = if (clock == null) PreviewLunchCore(options) else PreviewLunchCore(options, clock)
            return AppEnvironment(core = core, location = PreviewLocationProvider(), signInTokens = PreviewSignInTokenProvider)
        }
    }
}

private inline fun <T> MutableStateFlow<T>.getAndUpdate(transform: (T) -> T): T {
    while (true) {
        val current = value
        if (compareAndSet(current, transform(current))) return current
    }
}

/** The environment for the current composition; set once in `MainActivity`. */
val LocalAppEnvironment = staticCompositionLocalOf<AppEnvironment> {
    error("LocalAppEnvironment is not provided")
}
