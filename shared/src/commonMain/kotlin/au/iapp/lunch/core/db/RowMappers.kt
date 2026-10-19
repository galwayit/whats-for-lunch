package au.iapp.lunch.core.db

import au.iapp.lunch.core.json.UserPreferencesJson
import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.UserProfile

/*
 * Conversions between generated SQLDelight rows and the domain models,
 * mirroring EntityMappers in the Flutter app (JSON columns, epoch seconds).
 */

internal fun Users.toProfile(): UserProfile = UserProfile(
    id = id,
    name = name,
    preferences = UserPreferencesJson.decode(preferences),
    createdAtEpochSeconds = created_at,
)

internal fun Meals.toMeal(): Meal = Meal(
    id = id,
    userId = user_id,
    restaurantId = restaurant_id,
    restaurantName = restaurant_name,
    mealType = meal_type,
    cost = cost,
    dateEpochSeconds = date,
    notes = notes,
    photoIds = DbJson.stringList(photo_ids),
)

internal fun Restaurants.toRestaurant(): Restaurant = Restaurant(
    placeId = place_id,
    name = name,
    location = location,
    address = address,
    phoneNumber = phone_number,
    website = website,
    latitude = latitude,
    longitude = longitude,
    distanceFromUser = distance_from_user,
    rating = rating,
    reviewCount = review_count?.toInt(),
    priceLevel = price_level?.toInt(),
    priceRanges = DbJson.stringList(price_ranges),
    cuisineType = cuisine_type,
    cuisineTypes = DbJson.stringList(cuisine_types),
    supportedDietaryRestrictions = DbJson.stringList(supported_dietary_restrictions),
    allergenInfo = DbJson.stringList(allergen_info),
    dietaryCompatibilityScores = DbJson.doubleMap(dietary_compatibility_scores),
    hasVerifiedDietaryInfo = has_verified_dietary_info,
    communityVerificationCount = community_verification_count.toInt(),
    openingHours = DbJson.stringList(opening_hours),
    isOpenNow = is_open_now,
    currentWaitTime = current_wait_time,
    features = DbJson.stringList(features),
    averageMealCost = average_meal_cost,
    valueScore = value_score,
    mealTypeAverageCosts = DbJson.doubleMap(meal_type_average_costs),
    cachedAtEpochSeconds = cached_at,
    lastVerifiedEpochSeconds = last_verified,
    photoReference = photo_reference,
    photoReferences = DbJson.stringList(photo_references),
)

/** Writes a restaurant with INSERT OR REPLACE, like Drift's insertOrReplace. */
internal fun RestaurantsQueries.upsert(restaurant: Restaurant, cachedAtEpochSeconds: Long) {
    val permitted = if (restaurant.googleMapsUri != null) Restaurant(placeId = restaurant.placeId, name = "Saved place", location = "") else restaurant
    upsertPermitted(permitted, cachedAtEpochSeconds)
}

private fun RestaurantsQueries.upsertPermitted(restaurant: Restaurant, cachedAtEpochSeconds: Long) = upsert(
    place_id = restaurant.placeId,
    name = restaurant.name,
    location = restaurant.location,
    address = restaurant.address,
    phone_number = restaurant.phoneNumber,
    website = restaurant.website,
    latitude = restaurant.latitude,
    longitude = restaurant.longitude,
    distance_from_user = restaurant.distanceFromUser,
    rating = restaurant.rating,
    review_count = restaurant.reviewCount?.toLong(),
    price_level = restaurant.priceLevel?.toLong(),
    price_ranges = DbJson.encode(restaurant.priceRanges),
    cuisine_type = restaurant.cuisineType,
    cuisine_types = DbJson.encode(restaurant.cuisineTypes),
    supported_dietary_restrictions = DbJson.encode(restaurant.supportedDietaryRestrictions),
    allergen_info = DbJson.encode(restaurant.allergenInfo),
    dietary_compatibility_scores = DbJson.encode(restaurant.dietaryCompatibilityScores),
    has_verified_dietary_info = restaurant.hasVerifiedDietaryInfo,
    community_verification_count = restaurant.communityVerificationCount.toLong(),
    opening_hours = DbJson.encode(restaurant.openingHours),
    is_open_now = restaurant.isOpenNow,
    current_wait_time = restaurant.currentWaitTime,
    features = DbJson.encode(restaurant.features),
    average_meal_cost = restaurant.averageMealCost,
    value_score = restaurant.valueScore,
    meal_type_average_costs = DbJson.encode(restaurant.mealTypeAverageCosts),
    cached_at = if (restaurant.cachedAtEpochSeconds > 0) restaurant.cachedAtEpochSeconds else cachedAtEpochSeconds,
    last_verified = restaurant.lastVerifiedEpochSeconds,
    photo_reference = restaurant.photoReference,
    photo_references = DbJson.encode(restaurant.photoReferences),
)

/** Rebuilds a recommendation from its row plus the cached restaurants, in stored order. */
internal fun A_i_recommendations.toRecommendation(restaurantsById: Map<String, Restaurant>): AiRecommendation {
    val orderedIds = DbJson.stringList(recommended_restaurant_ids)
    return AiRecommendation(
        id = id,
        userId = user_id,
        restaurants = orderedIds.mapNotNull { restaurantsById[it] },
        reasoning = reasoning,
        factorWeights = DbJson.doubleMap(factor_weights),
        overallConfidence = overall_confidence,
        investmentSummary = null,
        generatedAtEpochSeconds = generated_at,
        wasAccepted = was_accepted,
        userFeedback = user_feedback,
    )
}
