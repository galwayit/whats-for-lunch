/**
 * @file PreviewServices.kt
 * @description In-memory services for [PreviewLunchCore]: AI picks, entitlements, gates, auth,
 * groups and push over the [PreviewCoreData] seed. Behaviour mirrors
 * iosApp/LunchApp/Core/Preview/PreviewServices.swift (latency, gate rules, invite codes) so the
 * two apps demo identically and the unit tests exercise the same paths.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.preview

import au.iapp.lunch.core.api.AiRecommendationService
import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.api.GroupRepository
import au.iapp.lunch.core.api.PushRegistrar
import au.iapp.lunch.core.api.RecommendationEngine
import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.AuthSession
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.core.model.FreeLimits
import au.iapp.lunch.core.model.GateDecision
import au.iapp.lunch.core.model.GateReason
import au.iapp.lunch.core.model.GroupProposal
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.GroupSuggestion
import au.iapp.lunch.core.model.GroupSuggestionDraft
import au.iapp.lunch.core.model.GroupDetails
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.ProOfferings
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.SortOption
import au.iapp.lunch.core.model.SubscriptionStatus
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.ui.components.dartOneDecimal
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlin.random.Random

/** One free AI request a day; Pro has ten. Hosting requires Pro. */
class PreviewGateService(
    private val isPro: () -> Boolean,
    private val session: () -> AuthSession?,
    aiUsedToday: Boolean,
) : GateService {
    /** Requests made today; bumped by [PreviewAiService]. */
    var aiRequestsToday: Int = if (aiUsedToday) 1 else 0
        private set

    fun recordAiUsed() {
        aiRequestsToday += 1
    }

    override suspend fun canRequestAi(): GateDecision = when {
        session() == null -> GateDecision.denied(GateReason.SIGN_IN_REQUIRED)
        aiRequestsToday < (if (isPro()) 10 else FreeLimits.AI_REQUESTS_PER_DAY) -> GateDecision.Allowed
        else -> GateDecision.denied(GateReason.AI_DAILY_LIMIT)
    }

    override fun canAddFavourite(currentCount: Int): GateDecision =
        if (isPro() || currentCount < FreeLimits.FAVOURITES) GateDecision.Allowed else GateDecision.denied(GateReason.FAVOURITES_LIMIT)

    override fun historyWindowDays(): Int? = if (isPro()) null else FreeLimits.HISTORY_DAYS

    override fun canHostGroup(): GateDecision = when {
        !isPro() -> GateDecision.denied(GateReason.HOST_REQUIRES_PRO)
        session() == null -> GateDecision.denied(GateReason.SIGN_IN_REQUIRED)
        else -> GateDecision.Allowed
    }
}

class PreviewAiService(
    private val network: PreviewNetwork,
    private val gates: PreviewGateService,
    private val engine: RecommendationEngine,
    private val allRestaurants: () -> List<Restaurant>,
    private val preferences: () -> UserPreferences?,
    private val clock: Clock,
) : AiRecommendationService {
    private val history = MutableStateFlow(listOf(PreviewCoreData.aiRecommendation))
    private var nextId = 2

    var aiConfiguration = au.iapp.lunch.core.model.AiConfiguration("preview-ai-v2", listOf(au.iapp.lunch.core.model.AiProviderDisclosure("Preview AI", "https://example.com/privacy")))
    override suspend fun configuration(): Result<au.iapp.lunch.core.model.AiConfiguration> = Result.success(aiConfiguration)

    override suspend fun recommend(cravings: String?, maxResults: Int, candidates: List<Restaurant>, consentVersion: String?): Result<AiRecommendation> {
        val decision = gates.canRequestAi()
        if (!decision.allowed) return Result.failure(CoreError.Gate(decision.reason))
        return network.call(PreviewNetwork.AI_LATENCY_MS) {
            val prefs = preferences()
            val pool = candidates.ifEmpty { allRestaurants() }
            val needle = cravings?.trim()?.lowercase().orEmpty()
            val matching = if (needle.isEmpty()) {
                emptyList()
            } else {
                pool.filter { it.name.lowercase().contains(needle) || it.cuisineTypes.any { c -> c.lowercase().contains(needle) } }
            }
            val picks = engine.sort(matching.ifEmpty { pool }, SortOption.RELEVANCE, prefs).take(maxResults)
            val names = picks.joinToString(", ") { it.name }
            val budget = "$".repeat(prefs?.budgetLevel ?: 2)
            val km = formatKm(prefs?.maxTravelDistance ?: 5.0)
            val reasoning = if (needle.isEmpty()) {
                "Based on your $budget budget and $km km range, these are the strongest picks right now: $names."
            } else {
                "For \"${cravings?.trim()}\" within your budget and distance, the best fits are $names."
            }
            val cost = picks.firstOrNull()?.averageMealCost ?: 0.0
            val recommendation = AiRecommendation(
                id = "ai_${nextId++}",
                userId = PreviewCoreData.USER_ID,
                restaurants = picks,
                reasoning = reasoning,
                factorWeights = mapOf("budget" to 0.4, "distance" to 0.3, "rating" to 0.2, "cuisine" to 0.1),
                overallConfidence = if (matching.isEmpty() && needle.isNotEmpty()) 0.62 else 0.86,
                investmentSummary = "About ${formatAud(cost)} today keeps you inside this week's budget.",
                generatedAtEpochSeconds = clock.nowEpochSeconds(),
            )
            gates.recordAiUsed()
            history.update { listOf(recommendation) + it }
            recommendation
        }
    }

    override suspend fun history(userId: Long, limit: Int): Result<List<AiRecommendation>> =
        Result.success(history.value.filter { it.userId == userId }.take(limit))

    override suspend fun submitFeedback(recommendationId: String, placeId: String?, rating: Int, feedback: String?, wasSelected: Boolean): Result<Unit> {
        history.update { list ->
            list.map { if (it.id == recommendationId) it.copy(wasAccepted = wasSelected, userFeedback = feedback) else it }
        }
        return Result.success(Unit)
    }

    override suspend fun usedToday(userId: Long): Int = gates.aiRequestsToday

    /** Reason strings must round the way Dart does, so the preview core matches the real engine. */
    private fun formatKm(km: Double): String = if (km == km.toLong().toDouble()) km.toLong().toString() else dartOneDecimal(km)

    private fun formatAud(amount: Double): String = "A$" + Math.round(amount).toString()
}

class PreviewEntitlementRepository(
    private val network: PreviewNetwork,
    initiallyPro: Boolean,
    private val clock: Clock,
) : EntitlementRepository {
    private val current = MutableStateFlow(
        if (initiallyPro) proStatus(PreviewCoreData.yearlyPackage.productId) else SubscriptionStatus(isPro = false),
    )
    override val status: StateFlow<SubscriptionStatus> = current.asStateFlow()
    private val pro = MutableStateFlow(initiallyPro)
    override val isPro: StateFlow<Boolean> = pro.asStateFlow()
    override val appUserId: StateFlow<String> = MutableStateFlow("\$RCAnonymousID:preview")

    override suspend fun offerings(): Result<ProOfferings> = network.call { PreviewCoreData.offerings }

    override suspend fun purchase(packageIdentifier: String): Result<SubscriptionStatus> = network.call(PreviewNetwork.PURCHASE_LATENCY_MS) {
        val productId = when (packageIdentifier) {
            PreviewCoreData.monthlyPackage.identifier -> PreviewCoreData.monthlyPackage.productId
            else -> PreviewCoreData.yearlyPackage.productId
        }
        set(proStatus(productId))
    }

    override suspend fun restore(): Result<SubscriptionStatus> = network.call { current.value }

    override suspend fun logIn(userId: String): Result<Unit> = Result.success(Unit)

    override suspend fun logOut(): Result<Unit> = Result.success(Unit)

    private fun set(status: SubscriptionStatus): SubscriptionStatus {
        current.value = status
        pro.value = status.isPro
        return status
    }

    private fun proStatus(productId: String): SubscriptionStatus {
        val days = if (productId == PreviewCoreData.yearlyPackage.productId) 365L else 30L
        return SubscriptionStatus(
            isPro = true,
            productId = productId,
            expiresAtEpochSeconds = clock.nowEpochSeconds() + days * SECONDS_PER_DAY,
            willRenew = true,
            managementUrl = MANAGEMENT_URL,
        )
    }

    companion object {
        const val SECONDS_PER_DAY = 86_400L

        /** Google Play's subscription centre; the real core reports RevenueCat's management URL. */
        const val MANAGEMENT_URL = "https://play.google.com/store/account/subscriptions"
    }
}

class PreviewAuthRepository(private val network: PreviewNetwork, signedIn: Boolean) : AuthRepository {
    private val current = MutableStateFlow(if (signedIn) DEMO_SESSION else null)
    override val session: StateFlow<AuthSession?> = current.asStateFlow()

    override suspend fun signInWithApple(idToken: String, nonce: String, fullName: String?): Result<AuthSession> = network.call {
        AuthSession("user_ray", "ray@privaterelay.appleid.com", fullName ?: PreviewCoreData.USER_NAME, requiresAppleReauthentication = true).also { current.value = it }
    }

    override suspend fun signInWithGoogle(idToken: String, nonce: String, accessToken: String?): Result<AuthSession> = network.call {
        AuthSession("user_ray", "ray@gmail.com", PreviewCoreData.USER_NAME).also { current.value = it }
    }

    override suspend fun signInWithEmail(email: String, password: String): Result<AuthSession> = network.call {
        AuthSession("user_ray", email, PreviewCoreData.USER_NAME).also { current.value = it }
    }
    override suspend fun registerWithEmail(email: String, password: String): Result<Boolean> = network.call { false }
    override suspend fun verifyEmail(email: String, code: String): Result<AuthSession> = signInWithEmail(email, "")
    override suspend fun resendVerification(email: String): Result<Unit> = network.call { }
    override suspend fun requestPasswordReset(email: String): Result<Unit> = network.call { }
    override suspend fun resetPassword(email: String, code: String, newPassword: String): Result<AuthSession> = signInWithEmail(email, newPassword)

    override suspend fun signOut(): Result<Unit> {
        current.value = null
        return Result.success(Unit)
    }

    override suspend fun deleteAccount(appleAuthorizationCode: String?): Result<Unit> = network.call { current.value = null }

    companion object {
        val DEMO_SESSION = AuthSession("user_ray", "ray@example.com", "Ray")
    }
}

class PreviewGroupRepository(
    private val network: PreviewNetwork,
    private val session: () -> AuthSession?,
    private val engine: RecommendationEngine,
    private val preferences: () -> UserPreferences?,
    private val searchNearby: suspend (Location, Double) -> List<Restaurant>,
    private val clock: Clock,
    seedGroup: LunchGroup,
    seedRsvps: List<Rsvp>,
) : GroupRepository {
    private val groups = MutableStateFlow(listOf(seedGroup))
    private val suggestionRows = mutableListOf<GroupSuggestion>()
    private val rsvpsByGroup = MutableStateFlow(mapOf(seedGroup.id to seedRsvps))

    override fun myGroups(): Flow<List<LunchGroup>> = groups

    override suspend fun create(name: String, scheduledAtEpochSeconds: Long, area: Location, radiusKm: Double, details: GroupDetails): Result<LunchGroup> = network.call {
        val host = session()
        val id = "grp_" + randomCode(6).lowercase()
        val group = LunchGroup(
            id = id,
            hostId = host?.userId ?: "user_ray",
            hostName = details.hostName.ifBlank { host?.displayName ?: PreviewCoreData.USER_NAME },
            budgetPerPersonMinor = details.budgetPerPersonMinor, currencyCode = details.currencyCode, paymentArrangement = details.paymentArrangement, paymentMethod = details.paymentMethod,
            name = name,
            scheduledAtEpochSeconds = scheduledAtEpochSeconds,
            areaLatitude = area.latitude,
            areaLongitude = area.longitude,
            radiusKm = radiusKm,
            inviteCode = randomCode(6),
            createdAtEpochSeconds = clock.nowEpochSeconds(),
        )
        groups.update { it + group }
        rsvpsByGroup.update {
            it + (id to listOf(Rsvp("rsvp_${id}_host", id, group.hostId, group.hostName, RsvpStatus.ACCEPTED, clock.nowEpochSeconds())))
        }
        group
    }

    override suspend fun propose(groupId: String, consentVersion: String?): Result<List<GroupProposal>> {
        val group = groups.value.firstOrNull { it.id == groupId } ?: return Result.failure(notFound(groupId))
        return coreResult {
            val nearby = searchNearby(Location(group.areaLatitude, group.areaLongitude), group.radiusKm)
            network.roundTrip(PreviewNetwork.PURCHASE_LATENCY_MS)
            val prefs = preferences()
            engine.sort(nearby, SortOption.RELEVANCE, prefs).take(3).map { GroupProposal(it, engine.reasons(it, prefs).take(3)) }
        }
    }

    override suspend fun confirmPlace(groupId: String, restaurant: Restaurant): Result<LunchGroup> = network.call {
        val updated = groups.value.firstOrNull { it.id == groupId }
            ?.copy(placeId = restaurant.placeId, placeName = restaurant.name, placeAddress = restaurant.address)
            ?: throw notFound(groupId)
        groups.update { list -> list.map { if (it.id == groupId) updated else it } }
        updated
    }

    override suspend fun invitation(code: String): Result<Invitation> = network.call { invitationFor(code) }

    override suspend fun respond(code: String, status: RsvpStatus, displayName: String?): Result<Invitation> = network.call {
        val group = groups.value.firstOrNull { it.inviteCode.equals(code, ignoreCase = true) } ?: throw notFound(code)
        val me = session()
        val name = displayName ?: me?.displayName ?: "Guest"
        val guestId = me?.userId ?: "guest_" + name.lowercase().replace(' ', '_')
        rsvpsByGroup.update { all ->
            val existing = all[group.id].orEmpty()
            val updated = if (existing.any { it.guestUserId == guestId }) {
                existing.map { if (it.guestUserId == guestId) it.copy(status = status, displayName = name, respondedAtEpochSeconds = clock.nowEpochSeconds()) else it }
            } else {
                existing + Rsvp("rsvp_${group.id}_$guestId", group.id, guestId, name, status, clock.nowEpochSeconds())
            }
            all + (group.id to updated)
        }
        // A signed-out guest has no session to match on, so the status they just chose is theirs.
        invitationFor(code).copy(myStatus = status)
    }

    override suspend fun suggest(code: String, draft: GroupSuggestionDraft, displayName: String?): Result<Invitation> = network.call {
        val invite = invitationFor(code)
        val row = GroupSuggestion("suggest_" + randomCode(8), invite.group.id, displayName ?: session()?.displayName ?: "Guest", draft.placeName, draft.placeAddress, draft.scheduledAt, draft.note, "pending", clock.nowEpochSeconds())
        suggestionRows.add(row)
        invite.copy(mySuggestion = row)
    }
    override suspend fun suggestions(groupId: String): Result<List<GroupSuggestion>> = Result.success(suggestionRows.filter { it.groupId == groupId })
    override suspend fun reviewSuggestion(groupId: String, suggestionId: String, accept: Boolean): Result<LunchGroup> = network.call {
        val index = suggestionRows.indexOfFirst { it.id == suggestionId && it.groupId == groupId }
        if (index < 0) throw notFound(suggestionId)
        val row = suggestionRows[index]
        suggestionRows[index] = row.copy(status = if (accept) "accepted" else "declined")
        var group = groups.value.first { it.id == groupId }
        if (accept) {
            group = group.copy(scheduledAtEpochSeconds = row.scheduledAtEpochSeconds ?: group.scheduledAtEpochSeconds, placeName = row.placeName ?: group.placeName, placeAddress = if (row.placeName != null) row.placeAddress else group.placeAddress, placeId = if (row.placeName != null) null else group.placeId)
            rsvpsByGroup.update { map -> map + (groupId to map[groupId].orEmpty().map { it.copy(status = RsvpStatus.PENDING) }) }
        }
        groups.update { rows -> rows.map { if (it.id == groupId) group else it } }
        group
    }
    override suspend fun updateDetails(groupId: String, details: GroupDetails): Result<LunchGroup> = network.call {
        val group = groups.value.first { it.id == groupId }.copy(hostName = details.hostName, budgetPerPersonMinor = details.budgetPerPersonMinor, currencyCode = details.currencyCode, paymentArrangement = details.paymentArrangement, paymentMethod = details.paymentMethod)
        groups.update { rows -> rows.map { if (it.id == groupId) group else it } }
        group
    }
    override fun rsvps(groupId: String): Flow<List<Rsvp>> = rsvpsByGroup.map { it[groupId].orEmpty() }

    override suspend fun cancel(groupId: String): Result<Unit> = network.call {
        groups.update { list -> list.filterNot { it.id == groupId } }
        rsvpsByGroup.update { it - groupId }
    }

    private fun invitationFor(code: String): Invitation {
        val group = groups.value.firstOrNull { it.inviteCode.equals(code, ignoreCase = true) } ?: throw notFound(code)
        val attendees = rsvpsByGroup.value[group.id].orEmpty()
        val myStatus = session()?.let { me -> attendees.firstOrNull { it.guestUserId == me.userId }?.status }
        return Invitation(group, attendees, myStatus, PreviewCoreData.INVITE_LINK_BASE + group.inviteCode, suggestionRows.lastOrNull { it.groupId == group.id })
    }

    private fun notFound(key: String) = CoreError.Service("NOT_FOUND", "No group for $key")

    private fun randomCode(length: Int): String = buildString {
        repeat(length) { append(CODE_ALPHABET[Random.nextInt(CODE_ALPHABET.length)]) }
    }

    private companion object {
        const val CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    }
}

class PreviewPushRegistrar : PushRegistrar {
    override suspend fun register(token: String, platform: String): Result<Unit> = Result.success(Unit)
}
