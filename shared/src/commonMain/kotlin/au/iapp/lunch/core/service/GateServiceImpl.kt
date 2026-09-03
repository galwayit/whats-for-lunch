package au.iapp.lunch.core.service

import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.model.FreeLimits
import au.iapp.lunch.core.model.GateDecision
import au.iapp.lunch.core.model.GateReason

/**
 * Free-tier limits from [FreeLimits]; Pro (per [EntitlementRepository]) lifts
 * all of them. The AI gate counts today's successful requests locally so the
 * paywall can show before a round trip; the backend enforces the same quota.
 */
internal class GateServiceImpl(
    private val entitlements: EntitlementRepository,
    private val auth: AuthRepository,
    private val users: UserRepository,
    private val usage: AiUsage,
) : GateService {

    private val isPro: Boolean get() = entitlements.isPro.value

    override suspend fun canRequestAi(): GateDecision {
        if (isPro) return GateDecision.Allowed
        val userId = users.current.value?.id ?: return GateDecision.Allowed
        return if (usage.usedToday(userId) < FreeLimits.AI_REQUESTS_PER_DAY) GateDecision.Allowed
        else GateDecision.denied(GateReason.AI_DAILY_LIMIT)
    }

    override fun canAddFavourite(currentCount: Int): GateDecision =
        if (isPro || currentCount < FreeLimits.FAVOURITES) GateDecision.Allowed
        else GateDecision.denied(GateReason.FAVOURITES_LIMIT)

    override fun historyWindowDays(): Int? = if (isPro) null else FreeLimits.HISTORY_DAYS

    override fun canHostGroup(): GateDecision = when {
        auth.session.value == null -> GateDecision.denied(GateReason.SIGN_IN_REQUIRED)
        !isPro -> GateDecision.denied(GateReason.HOST_REQUIRES_PRO)
        else -> GateDecision.Allowed
    }
}
