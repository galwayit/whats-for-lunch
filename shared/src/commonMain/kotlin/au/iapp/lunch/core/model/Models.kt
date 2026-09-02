package au.iapp.lunch.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/*
 * Domain models shared by iOS and Android.
 *
 * Timestamps are epoch SECONDS (Long) everywhere, because that is how the
 * Drift-created diet_buddy.sqlite stores DateTime columns. Convert to
 * platform date types at the UI edge only.
 */

@Serializable
enum class AllergenSafetyLevel { STRICT, MODERATE, LENIENT } // ordinal order matches the Dart enum index stored in JSON

/**
 * Mirrors the JSON stored in users.preferences by the Flutter app.
 * Key names and defaults must stay identical so an existing row round-trips.
 */
@Serializable
data class UserPreferences(
    val dietaryRestrictions: List<String> = emptyList(),
    val cuisinePreferences: List<String> = emptyList(),
    val allergens: List<String> = emptyList(),
    /** Stored as the enum index (0 strict, 1 moderate, 2 lenient). */
    val allergenSafetyLevels: Map<String, Int> = emptyMap(),
    val contextualPreferences: Map<String, List<String>> = emptyMap(),
    val cuisineRatings: Map<String, Double> = emptyMap(),
    val restaurantVisitCounts: Map<String, Int> = emptyMap(),
    val budgetLevel: Int = 2,
    val maxTravelDistance: Double = 5.0,
    val includeChains: Boolean = true,
    val mealFrequencyPerDay: Int = 3,
    val weeklyBudget: Double = 200.0,
    val enableLocationServices: Boolean = true,
    val showMapView: Boolean = true,
    val mapZoomLevel: Int = 14,
    val lastKnownLocation: List<Double>? = null,
    val requireDietaryVerification: Boolean = true,
    val minimumRating: Double = 3.0,
    val preferredPriceRanges: List<String> = listOf("$", "$$"),
    val avoidBusyTimes: Boolean = false,
    val accessibilityRequirements: Map<String, Boolean> = emptyMap(),
)

@Serializable
data class UserProfile(
    val id: Long,
    val name: String,
    val preferences: UserPreferences,
    val createdAtEpochSeconds: Long,
)

@Serializable
data class Meal(
    val id: Long? = null,
    val userId: Long,
    val restaurantId: String? = null,
    val restaurantName: String? = null,
    /** One of breakfast, lunch, dinner, snack, dining_out, delivery, takeout, groceries. */
    val mealType: String,
    val cost: Double,
    val dateEpochSeconds: Long,
    val notes: String? = null,
    val photoIds: List<String> = emptyList(),
)

@Serializable
data class BudgetEntry(
    val id: Long? = null,
    val userId: Long,
    val amount: Double,
    val category: String,
    val dateEpochSeconds: Long,
)

@Serializable
data class RestaurantReview(
    val reviewId: String,
    val authorName: String,
    val authorPhotoUrl: String? = null,
    val rating: Int,
    val text: String? = null,
    val timeEpochSeconds: Long,
    val relativeTimeDescription: String = "",
)

@Serializable
data class Restaurant(
    val placeId: String,
    val name: String,
    val location: String,
    val address: String? = null,
    val phoneNumber: String? = null,
    val website: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    /** Kilometres from the user at fetch time. */
    val distanceFromUser: Double? = null,
    val rating: Double? = null,
    val reviewCount: Int? = null,
    /** 1..4, matching the number of dollar signs. */
    val priceLevel: Int? = null,
    val priceRanges: List<String> = emptyList(),
    val cuisineType: String? = null,
    val cuisineTypes: List<String> = emptyList(),
    val supportedDietaryRestrictions: List<String> = emptyList(),
    val allergenInfo: List<String> = emptyList(),
    val dietaryCompatibilityScores: Map<String, Double> = emptyMap(),
    val hasVerifiedDietaryInfo: Boolean = false,
    val communityVerificationCount: Int = 0,
    val openingHours: List<String> = emptyList(),
    val isOpenNow: Boolean = false,
    val currentWaitTime: String? = null,
    val features: List<String> = emptyList(),
    val averageMealCost: Double? = null,
    val valueScore: Double? = null,
    val mealTypeAverageCosts: Map<String, Double> = emptyMap(),
    val recentReviews: List<RestaurantReview> = emptyList(),
    val cachedAtEpochSeconds: Long = 0,
    val lastVerifiedEpochSeconds: Long? = null,
    val photoReference: String? = null,
    val photoReferences: List<String> = emptyList(),
    /** Absolute URL served by the backend for the first photo, when available. */
    val photoUrl: String? = null,
)

enum class SortOption { RELEVANCE, PRICE, DISTANCE, RATING }

@Serializable
data class AiRecommendation(
    val id: String,
    val userId: Long,
    val restaurants: List<Restaurant>,
    val reasoning: String,
    val factorWeights: Map<String, Double> = emptyMap(),
    val overallConfidence: Double,
    val investmentSummary: String? = null,
    val generatedAtEpochSeconds: Long,
    val wasAccepted: Boolean = false,
    val userFeedback: String? = null,
) {
    val confidenceLevel: String
        get() = when {
            overallConfidence >= 0.8 -> "High"
            overallConfidence >= 0.6 -> "Medium"
            else -> "Low"
        }
}

/* ---------- Budget and achievements ---------- */

data class WeeklyBudgetState(
    val weeklyCapacity: Double,
    val currentSpent: Double,
    val remainingCapacity: Double,
    val experiencesLogged: Int,
    val targetExperiences: Int,
    val weekStartEpochSeconds: Long,
) {
    val capacityProgress: Double get() = if (weeklyCapacity > 0) currentSpent / weeklyCapacity else 0.0
    val experienceProgress: Double get() = if (targetExperiences > 0) experiencesLogged.toDouble() / targetExperiences else 0.0
}

enum class ImpactLevel { LOW, MODERATE, HIGH, VERY_HIGH }
enum class GuidanceLevel { EXCELLENT, GOOD, MODERATE, HIGH }

data class MealImpact(
    val mealCost: Double,
    val projectedSpent: Double,
    val projectedRemaining: Double,
    val impactLevel: ImpactLevel,
    val guidanceLevel: GuidanceLevel,
    val message: String,
    val exceedsCapacity: Boolean,
)

data class BudgetImpact(
    val percentageOfWeeklyBudget: Double,
    val impactLevel: ImpactLevel?,
    val message: String,
    val remainingBudget: Double,
)

@Serializable
data class Achievement(
    val id: String,
    val title: String,
    val description: String,
    val category: String,
    val points: Int,
    val iconName: String,
    val isUnlocked: Boolean = false,
    val unlockedAtEpochSeconds: Long? = null,
)

data class MealCategory(
    val id: String,
    val name: String,
    val description: String,
    val icon: String,
    val suggestedBudget: Double,
)

/* ---------- Monetization ---------- */

enum class Tier { FREE, PRO }

/** Free-tier allowances. Single source of truth for gates on the client. */
object FreeLimits {
    const val AI_REQUESTS_PER_DAY = 1
    const val FAVOURITES = 10
    const val HISTORY_DAYS = 30
}

enum class GateReason {
    OK,
    AI_DAILY_LIMIT,
    FAVOURITES_LIMIT,
    HISTORY_WINDOW,
    HOST_REQUIRES_PRO,
    SIGN_IN_REQUIRED,
}

data class GateDecision(val allowed: Boolean, val reason: GateReason) {
    companion object {
        val Allowed = GateDecision(true, GateReason.OK)
        fun denied(reason: GateReason) = GateDecision(false, reason)
    }
}

data class ProPackage(
    /** RevenueCat package identifier, e.g. "$rc_annual". */
    val identifier: String,
    val productId: String,
    val localizedPrice: String,
    val periodLabel: String,
    val hasFreeTrial: Boolean,
    val trialLabel: String? = null,
)

data class ProOfferings(val monthly: ProPackage?, val yearly: ProPackage?)

data class SubscriptionStatus(
    val isPro: Boolean,
    val productId: String? = null,
    val expiresAtEpochSeconds: Long? = null,
    val willRenew: Boolean = false,
    val managementUrl: String? = null,
)

/* ---------- Auth and social ---------- */

data class AuthSession(val userId: String, val email: String?, val displayName: String?)

enum class RsvpStatus { PENDING, ACCEPTED, DECLINED }

@Serializable
data class LunchGroup(
    val id: String,
    val hostId: String,
    val hostName: String,
    val name: String,
    val scheduledAtEpochSeconds: Long,
    val areaLatitude: Double,
    val areaLongitude: Double,
    val radiusKm: Double,
    val placeId: String? = null,
    val placeName: String? = null,
    val placeAddress: String? = null,
    val inviteCode: String,
    val createdAtEpochSeconds: Long,
)

@Serializable
data class Rsvp(
    val id: String,
    val groupId: String,
    val guestUserId: String? = null,
    val displayName: String,
    val status: RsvpStatus,
    val respondedAtEpochSeconds: Long? = null,
)

@Serializable
data class GroupProposal(val restaurant: Restaurant, val reasons: List<String>)

/** What a guest sees when opening an invitation link. */
@Serializable
data class Invitation(
    val group: LunchGroup,
    val attendees: List<Rsvp>,
    val myStatus: RsvpStatus? = null,
    val inviteUrl: String,
)

data class Location(val latitude: Double, val longitude: Double, val accuracyMetres: Double? = null)

/* ---------- Errors ---------- */

sealed class CoreError : Exception() {
    data object Offline : CoreError()
    data class Service(val code: String, override val message: String) : CoreError()
    data class Gate(val reason: GateReason) : CoreError()
    data object NotSignedIn : CoreError()
    data class Unknown(override val cause: Throwable?) : CoreError()
}
