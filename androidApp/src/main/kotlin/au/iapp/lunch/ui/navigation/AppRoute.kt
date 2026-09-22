/**
 * @file AppRoute.kt
 * @description Every destination in the app, per the navigation section of design/screens.md.
 * Tabs host their own stacks; the rest are pushed or presented modally from the tab noted.
 * Mirrors iosApp/LunchApp/App/AppRoute.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.navigation

import au.iapp.lunch.ui.components.LunchTab

sealed class AppRoute {
    data object Onboarding : AppRoute()
    data class Tab(val tab: LunchTab) : AppRoute()

    // From Home
    data class AiRecommendations(val pickPlaceId: String?) : AppRoute()
    data object GroupCreate : AppRoute()
    data class GroupProposals(val groupId: String) : AppRoute()
    data class GroupDetail(val groupId: String) : AppRoute()
    data object Paywall : AppRoute()

    // From Profile
    data object Preferences : AppRoute()
    data object SignIn : AppRoute()
    data object Privacy : AppRoute()
    data object Help : AppRoute()

    // From Track
    data object BudgetSetup : AppRoute()

    // From anywhere (app link https://lunch.iapp.au/i/<code>)
    data class Invitation(val code: String) : AppRoute()

    companion object {
        /** Routes reachable from the `openRoute` launch extra; null for anything else. */
        fun fromKey(key: String): AppRoute? = when (val trimmed = key.trim().lowercase()) {
            "ai" -> AiRecommendations(pickPlaceId = null)
            "paywall" -> Paywall
            "preferences" -> Preferences
            "signin", "sign_in" -> SignIn
            "privacy" -> Privacy
            "help" -> Help
            "budget" -> BudgetSetup
            "group_create", "groupcreate" -> GroupCreate
            "home" -> Tab(LunchTab.Home)
            "discover" -> Tab(LunchTab.Discover)
            "track" -> Tab(LunchTab.Track)
            "profile" -> Tab(LunchTab.Profile)
            // `group_detail:<id>` and `proposals:<id>` carry the group they open.
            else -> trimmed.substringBefore(':').let { name ->
                val id = trimmed.substringAfter(':', missingDelimiterValue = "")
                when {
                    id.isEmpty() -> null
                    name == "group_detail" -> GroupDetail(id)
                    name == "proposals" -> GroupProposals(id)
                    name == "invite" -> Invitation(id.uppercase())
                    else -> null
                }
            }
        }
    }
}
