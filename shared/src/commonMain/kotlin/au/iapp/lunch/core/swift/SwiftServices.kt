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
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.Location
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
    /**
     * Calls the backend, which enforces the daily quota and picks the model by tier.
     * The client also pre-checks GateService so the paywall shows without a round trip.
     */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun recommend(cravings: String?, maxResults: Int, candidates: List<Restaurant>): AiRecommendation =
        unwrap { ai.recommend(cravings, maxResults, candidates) }

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
    suspend fun signInWithGoogle(idToken: String): AuthSession = unwrap { auth.signInWithGoogle(idToken) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun signOut() {
        unwrap { auth.signOut() }
    }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun deleteAccount() {
        unwrap { auth.deleteAccount() }
    }
}

/** Swift view of [GroupRepository]. */
class SwiftGroupRepository(private val groups: GroupRepository) {
    fun myGroups(): Flow<List<LunchGroup>> = groups.myGroups()

    /** Host only. Backend verifies the Pro entitlement. */
    @Throws(CoreError::class, CancellationException::class)
    suspend fun create(name: String, scheduledAtEpochSeconds: Long, area: Location, radiusKm: Double): LunchGroup =
        unwrap { groups.create(name, scheduledAtEpochSeconds, area, radiusKm) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun propose(groupId: String): List<GroupProposal> = unwrap { groups.propose(groupId) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun confirmPlace(groupId: String, restaurant: Restaurant): LunchGroup =
        unwrap { groups.confirmPlace(groupId, restaurant) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun invitation(code: String): Invitation = unwrap { groups.invitation(code) }

    @Throws(CoreError::class, CancellationException::class)
    suspend fun respond(code: String, status: RsvpStatus, displayName: String?): Invitation =
        unwrap { groups.respond(code, status, displayName) }

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
