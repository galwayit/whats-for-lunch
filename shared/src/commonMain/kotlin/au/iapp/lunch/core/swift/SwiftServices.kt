/**
 * @file SwiftServices.kt
 * @description Throwing wrappers over the service contracts (AI recommendations,
 * entitlements, auth, groups, push). Same rules as SwiftRepositories.kt: Result
 * members become throwing members, everything else passes through unchanged.
 * GateService and the pure engines have no Result members and are exposed as-is.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.core.swift

import au.iapp.lunch.core.api.AiRecommendationService
import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.api.GroupRepository
import au.iapp.lunch.core.api.PushRegistrar
import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.GroupSuggestion
import au.iapp.lunch.core.model.GroupSuggestionDraft
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.GroupDetails
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.ProOfferings
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.SubscriptionStatus
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/** Swift view of [AiRecommendationService]. */
class SwiftAiRecommendationService(private val ai: AiRecommendationService) {
    @Throws(CoreError::class, CancellationException::class)
    suspend fun configuration(): au.iapp.lunch.core.model.AiConfiguration = unwrap { ai.configuration() }
    /**
     * Calls the backend, which enforces the daily quota and picks the model by tier.
     * The client also pre-checks GateService so the paywall shows without a round trip.
     */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun recommend(cravings: String?, maxResults: Int, candidates: List<Restaurant>, consentVersion: String? = null): AiRecommendation =
        unwrap { ai.recommend(cravings, maxResults, candidates, consentVersion) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun history(userId: Long, limit: Int): List<AiRecommendation> = unwrap { ai.history(userId, limit) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Boolean) {
        unwrap { ai.submitFeedback(recommendationId, placeId, rating, feedback, wasSelected) }
    }

    /** Requests made today by this user, for the gate row copy. */
    suspend fun usedToday(userId: Long): Int = ai.usedToday(userId)
}

/** Swift view of [EntitlementRepository]. */
class SwiftEntitlementRepository(private val entitlements: EntitlementRepository) {
    val isPro: StateFlow<Boolean> get() = entitlements.isPro
    val status: StateFlow<SubscriptionStatus> get() = entitlements.status

    /** Stable RevenueCat app user id, anonymous until logIn. Sent to the backend as x-app-user-id. */
    val appUserId: StateFlow<String> get() = entitlements.appUserId

    @Throws(CoreError::class, CancellationException::class)
    suspend fun offerings(): ProOfferings = unwrap { entitlements.offerings() }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun purchase(packageIdentifier: String): SubscriptionStatus = unwrap { entitlements.purchase(packageIdentifier) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun restore(): SubscriptionStatus = unwrap { entitlements.restore() }

    /** Called after Supabase sign-in so purchases follow the account. */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun logIn(userId: String) {
        unwrap { entitlements.logIn(userId) }
    }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun logOut() {
        unwrap { entitlements.logOut() }
    }
}

/** Swift view of [AuthRepository]. */
class SwiftAuthRepository(private val auth: AuthRepository) {
    val session: StateFlow<AuthSession?> get() = auth.session

    @Throws(CoreError::class, CancellationException::class)
    suspend fun signInWithApple(idToken: String, nonce: String, fullName: String?): AuthSession =
        unwrap { auth.signInWithApple(idToken, nonce, fullName) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun signInWithGoogle(idToken: String, nonce: String, accessToken: String?): AuthSession = unwrap { auth.signInWithGoogle(idToken, nonce, accessToken) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun signInWithEmail(email: String, password: String): AuthSession = unwrap { auth.signInWithEmail(email, password) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun registerWithEmail(email: String, password: String): Boolean = unwrap { auth.registerWithEmail(email, password) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun verifyEmail(email: String, code: String): AuthSession = unwrap { auth.verifyEmail(email, code) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun resendVerification(email: String) { unwrap { auth.resendVerification(email) } }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun requestPasswordReset(email: String) { unwrap { auth.requestPasswordReset(email) } }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun resetPassword(email: String, code: String, newPassword: String): AuthSession = unwrap { auth.resetPassword(email, code, newPassword) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun signOut() {
        unwrap { auth.signOut() }
    }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun deleteAccount(appleAuthorizationCode: String? = null) {
        unwrap { auth.deleteAccount(appleAuthorizationCode) }
    }
}

/** Swift view of [GroupRepository]. */
class SwiftGroupRepository(private val groups: GroupRepository) {
    @Throws(CoreError::class, CancellationException::class)
    suspend fun loadGroups(): List<LunchGroup> = unwrap { groups.loadGroups() }
    @Throws(CoreError::class, CancellationException::class)
    suspend fun loadRsvps(groupId: String): List<Rsvp> = unwrap { groups.loadRsvps(groupId) }
    fun myGroups(): Flow<List<LunchGroup>> = groups.myGroups()

    /** Host only. Backend verifies the Pro entitlement. */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun create(name: String, scheduledAtEpochSeconds: Long, area: Location, radiusKm: Double, details: GroupDetails): LunchGroup =
        unwrap { groups.create(name, scheduledAtEpochSeconds, area, radiusKm, details) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun propose(groupId: String, consentVersion: String? = null): List<GroupProposal> = unwrap { groups.propose(groupId, consentVersion) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun confirmPlace(groupId: String, restaurant: Restaurant): LunchGroup =
        unwrap { groups.confirmPlace(groupId, restaurant) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun invitation(code: String): Invitation = unwrap { groups.invitation(code) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun respond(code: String, status: RsvpStatus, displayName: String?): Invitation =
        unwrap { groups.respond(code, status, displayName) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun suggest(code: String, draft: GroupSuggestionDraft, displayName: String?): Invitation = unwrap { groups.suggest(code, draft, displayName) }
    @Throws(CoreError::class, CancellationException::class)
    suspend fun suggestions(groupId: String): List<GroupSuggestion> = unwrap { groups.suggestions(groupId) }
    @Throws(CoreError::class, CancellationException::class)
    suspend fun reviewSuggestion(groupId: String, suggestionId: String, accept: Boolean): LunchGroup = unwrap { groups.reviewSuggestion(groupId, suggestionId, accept) }
    @Throws(CoreError::class, CancellationException::class)
    suspend fun updateDetails(groupId: String, details: GroupDetails): LunchGroup = unwrap { groups.updateDetails(groupId, details) }
    @Throws(CoreError::class, CancellationException::class)
    suspend fun safetyAction(code: String, targetKind: String, targetId: String?, action: String, reason: String) {
        unwrap { groups.safetyAction(code, targetKind, targetId, action, reason) }
    }
    fun rsvps(groupId: String): Flow<List<Rsvp>> = groups.rsvps(groupId)

    @Throws(CoreError::class, CancellationException::class)
    suspend fun cancel(groupId: String) {
        unwrap { groups.cancel(groupId) }
    }
}

/** Swift view of [PushRegistrar]. */
class SwiftPushRegistrar(private val push: PushRegistrar) {
    @Throws(CoreError::class, CancellationException::class)
    suspend fun register(token: String, platform: String) {
        unwrap { push.register(token, platform) }
    }
}
