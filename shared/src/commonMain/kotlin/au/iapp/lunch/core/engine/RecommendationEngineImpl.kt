package au.iapp.lunch.core.engine

import au.iapp.lunch.core.api.RecommendationEngine
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.SortOption
import au.iapp.lunch.core.model.UserPreferences
import au.iapp.lunch.core.platform.toFixed1
import kotlin.math.abs

/**
 * Pure port of the Flutter recommendation rules.
 *
 * Sources: `HomeSearchNotifier` in simple_providers.dart (score, best match,
 * reasons), `DiscoverPage` in discover_page.dart (sort and its own reasons),
 * and `DiscoveryNotifier._applyUserPreferenceFilters` in
 * discovery_providers.dart. Strings and arithmetic order are kept verbatim so
 * the fixture vectors derived from the Dart code match exactly.
 */
class RecommendationEngineImpl : RecommendationEngine {

    override fun compatibilityScore(restaurant: Restaurant, prefs: UserPreferences?): Double {
        var score = 0.0
        if (prefs != null) {
            // Budget level matching (weight: 40%)
            val priceLevel = restaurant.priceLevel
            if (priceLevel != null) {
                val priceDiff = abs(priceLevel - prefs.budgetLevel)
                score += (4 - priceDiff) * 0.4
            } else {
                score += 2.0 * 0.4
            }

            // Distance preference (weight: 30%)
            val maxDistance = prefs.maxTravelDistance
            val distance = restaurant.distanceFromUser
            if (distance != null) {
                if (distance <= maxDistance) {
                    val distanceScore = 1.0 - (distance / maxDistance)
                    score += distanceScore * 0.3
                }
            } else {
                score += 0.5 * 0.3
            }

            // Rating (weight: 20%)
            val rating = restaurant.rating
            if (rating != null && rating > 0) {
                score += (rating / 5.0) * 0.2
            } else {
                score += 0.5 * 0.2
            }

            // Open now bonus (weight: 10%)
            if (restaurant.isOpenNow) {
                score += 1.0 * 0.1
            }
        } else {
            val rating = restaurant.rating
            if (rating != null) {
                score += rating / 5.0
            } else {
                score += 0.5
            }
        }
        return score
    }

    override fun bestMatch(candidates: List<Restaurant>, prefs: UserPreferences?, rejected: Set<String>): Restaurant? {
        var best: Restaurant? = null
        var bestScore = -1.0
        for (restaurant in candidates) {
            if (restaurant.placeId in rejected) continue
            if (prefs?.includeChains == false && RestaurantChains.matches(restaurant.name)) continue
            if (prefs != null && !matchesDietaryPreferences(restaurant, prefs)) continue
            val score = compatibilityScore(restaurant, prefs)
            if (score > bestScore) {
                bestScore = score
                best = restaurant
            }
        }
        return if (best != null && bestScore > SCORE_THRESHOLD) best else null
    }

    override fun reasons(restaurant: Restaurant, prefs: UserPreferences?): List<String> {
        val reasons = ArrayList<String>()
        if (prefs != null) {
            val priceLevel = restaurant.priceLevel
            if (priceLevel != null) {
                if (priceLevel == prefs.budgetLevel) {
                    val dollarSigns = "$".repeat(prefs.budgetLevel)
                    reasons.add("Perfect budget match ($dollarSigns)")
                } else if (abs(priceLevel - prefs.budgetLevel) <= 1) {
                    reasons.add("Close to your budget range")
                }
            }

            val maxDistance = prefs.maxTravelDistance
            val distance = restaurant.distanceFromUser
            if (distance != null) {
                if (distance <= maxDistance * 0.5) {
                    reasons.add("Very close to you (${distance.toFixed1()}km)")
                } else if (distance <= maxDistance) {
                    reasons.add("Within your preferred distance")
                }
            }

            val rating = restaurant.rating
            if (rating != null && rating >= 4.0) {
                reasons.add("Highly rated (${rating.toFixed1()}/5)")
            }

            if (restaurant.isOpenNow) {
                reasons.add("Open right now")
            }

            val cuisine = restaurant.cuisineType
            if (cuisine != null) {
                reasons.add("Great ${cuisine.lowercase()} cuisine")
            }
        }

        if (reasons.isEmpty()) {
            val rating = restaurant.rating
            if (rating != null && rating > 0) {
                reasons.add("Good ratings (${rating.toFixed1()}/5)")
            }
            val cuisine = restaurant.cuisineType
            if (cuisine != null) {
                reasons.add("$cuisine cuisine")
            }
            if (reasons.isEmpty()) {
                reasons.add("Popular choice in your area")
            }
        }
        return reasons
    }

    override fun discoverReasons(restaurant: Restaurant, prefs: UserPreferences?): List<String> {
        if (prefs == null) return listOf("Great choice for a delicious meal!")
        val reasons = ArrayList<String>()

        val priceLevel = restaurant.priceLevel
        if (priceLevel != null && priceLevel <= prefs.budgetLevel) {
            reasons.add("Fits your ${"$".repeat(prefs.budgetLevel)} budget perfectly")
        }

        val distance = restaurant.distanceFromUser
        if (distance != null && distance <= prefs.maxTravelDistance) {
            reasons.add("Only ${distance.toFixed1()}km away - perfect distance")
        }

        val rating = restaurant.rating
        if (rating != null && rating >= 4.0) {
            reasons.add("Highly rated (${rating.toFixed1()}) by other diners")
        }

        if (restaurant.isOpenNow) {
            reasons.add("Open right now - ready when you are")
        }

        val cuisine = restaurant.cuisineType
        if (cuisine != null) {
            reasons.add("Delicious ${cuisine.lowercase()} cuisine")
        }

        val isChain = isChainRestaurant(restaurant)
        if (prefs.includeChains || !isChain) {
            if (!isChain) {
                reasons.add("Local favorite - unique dining experience")
            }
        }

        if (reasons.isEmpty()) {
            reasons.add("Great choice for a satisfying meal")
        }
        return reasons
    }

    override fun sort(restaurants: List<Restaurant>, option: SortOption, prefs: UserPreferences?): List<Restaurant> {
        val comparator: Comparator<Restaurant> = when (option) {
            SortOption.RELEVANCE -> Comparator { a, b ->
                val reasonsA = discoverReasons(a, prefs).size
                val reasonsB = discoverReasons(b, prefs).size
                var result = reasonsB.compareTo(reasonsA)
                if (result == 0) {
                    val ratingA = a.rating ?: 0.0
                    val ratingB = b.rating ?: 0.0
                    result = ratingB.compareTo(ratingA)
                }
                result
            }
            SortOption.PRICE -> Comparator { a, b ->
                (a.priceLevel ?: 0).compareTo(b.priceLevel ?: 0)
            }
            SortOption.DISTANCE -> Comparator { a, b ->
                (a.distanceFromUser ?: Double.POSITIVE_INFINITY).compareTo(b.distanceFromUser ?: Double.POSITIVE_INFINITY)
            }
            SortOption.RATING -> Comparator { a, b ->
                (b.rating ?: 0.0).compareTo(a.rating ?: 0.0)
            }
        }
        return restaurants.sortedWith(comparator)
    }

    override fun applyPreferenceFilters(restaurants: List<Restaurant>, prefs: UserPreferences?): List<Restaurant> {
        if (prefs == null) return restaurants
        return restaurants.filter { restaurant ->
            val distance = restaurant.distanceFromUser
            if (distance != null && distance > prefs.maxTravelDistance) return@filter false

            val rating = restaurant.rating
            if (rating != null && rating < prefs.minimumRating) return@filter false

            val priceLevel = restaurant.priceLevel
            if (priceLevel != null && prefs.budgetLevel > 0 && priceLevel > prefs.budgetLevel) return@filter false

            if (!matchesDietaryPreferences(restaurant, prefs)) return@filter false

            if (!prefs.includeChains) {
                if (RestaurantChains.matches(restaurant.name)) return@filter false
            }
            true
        }
    }

    override fun dietaryCompatibility(restaurant: Restaurant, dietaryRestrictions: List<String>, allergens: List<String>): Double {
        if (dietaryRestrictions.isEmpty() && allergens.isEmpty()) return 1.0
        // An empty allergen list is missing evidence, never certified free-from data.
        if (hasAllergenConflict(restaurant, allergens)) return 0.0
        if (!restaurant.hasVerifiedDietaryInfo) return 0.0
        var score = 0.0
        val totalRequirements = dietaryRestrictions.size + allergens.size
        for (restriction in dietaryRestrictions) {
            if (restaurant.supportedDietaryRestrictions.contains(restriction)) {
                score += 1.0
            } else {
                val partial = restaurant.dietaryCompatibilityScores[restriction]
                if (partial != null && partial.isFinite()) score += partial.coerceIn(0.0, 1.0)
            }
        }
        return if (totalRequirements > 0) score / totalRequirements else 1.0
    }

    private fun matchesDietaryPreferences(restaurant: Restaurant, prefs: UserPreferences): Boolean {
        if (hasAllergenConflict(restaurant, prefs.allergens)) return false
        if (!prefs.requireDietaryVerification) return true
        if (prefs.dietaryRestrictions.isEmpty() && prefs.allergens.isEmpty()) return true
        return prefs.allergens.isEmpty() && restaurant.hasVerifiedDietaryInfo && prefs.dietaryRestrictions.all { it in restaurant.supportedDietaryRestrictions }
    }

    private fun hasAllergenConflict(restaurant: Restaurant, allergens: List<String>): Boolean {
        val reported = restaurant.allergenInfo.map(::allergenFamily).toSet()
        return allergens.any { allergenFamily(it) in reported }
    }

    private fun allergenFamily(value: String): String = when (val key = value.lowercase().replace('-', '_').replace(' ', '_')) {
        "nut", "nuts", "nut_allergy", "peanut", "peanuts", "tree_nut", "tree_nuts" -> "nuts"
        "shellfish", "shellfish_allergy", "crustacean", "crustaceans", "mollusc", "molluscs" -> "shellfish"
        else -> key
    }

    private fun isChainRestaurant(restaurant: Restaurant): Boolean {
        return RestaurantChains.matches(restaurant.name)
    }

    private companion object {
        const val SCORE_THRESHOLD = 0.1

    }
}
