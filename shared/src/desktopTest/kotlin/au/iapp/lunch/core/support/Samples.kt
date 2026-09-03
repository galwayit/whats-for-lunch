package au.iapp.lunch.core.support

import au.iapp.lunch.core.model.AiRecommendation
import au.iapp.lunch.core.model.Invitation
import au.iapp.lunch.core.model.Location
import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.RestaurantReview
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus

/** Domain objects shared by the desktop tests. Coordinates are around Sydney CBD. */
object Samples {
    val sydney = Location(latitude = -33.8688, longitude = 151.2093)

    fun restaurant(
        placeId: String = "place-1",
        name: String = "Sample Sushi",
        latitude: Double = -33.8700,
        longitude: Double = 151.2100,
        rating: Double = 4.4,
    ) = Restaurant(
        placeId = placeId,
        name = name,
        location = "Sydney",
        address = "1 George St",
        latitude = latitude,
        longitude = longitude,
        rating = rating,
        reviewCount = 120,
        priceLevel = 2,
        priceRanges = listOf("$$"),
        cuisineType = "Japanese",
        cuisineTypes = listOf("Japanese", "Sushi"),
        distanceFromUser = 0.2,
    )

    fun review() = RestaurantReview(reviewId = "r-1", authorName = "Alex", rating = 5, text = "Great", timeEpochSeconds = 1_788_300_000)

    fun recommendation(id: String = "rec-1", restaurants: List<Restaurant> = listOf(restaurant()), generatedAt: Long = 0) =
        AiRecommendation(
            id = id,
            userId = 0,
            restaurants = restaurants,
            reasoning = "Light and close by",
            factorWeights = mapOf("price" to 0.4, "distance" to 0.6),
            overallConfidence = 0.85,
            generatedAtEpochSeconds = generatedAt,
        )

    fun group(id: String = "group-1") = LunchGroup(
        id = id,
        hostId = "user-1",
        hostName = "Sam",
        name = "Friday team lunch",
        scheduledAtEpochSeconds = 1_788_600_000,
        areaLatitude = sydney.latitude,
        areaLongitude = sydney.longitude,
        radiusKm = 2.0,
        inviteCode = "ABCD1234",
        createdAtEpochSeconds = 1_788_400_000,
    )

    fun invitation(status: RsvpStatus? = null) = Invitation(
        group = group(),
        attendees = listOf(Rsvp(id = "rsvp-1", groupId = "group-1", displayName = "Kim", status = RsvpStatus.ACCEPTED)),
        myStatus = status,
        inviteUrl = "https://lunch.iapp.au/i/ABCD1234",
    )
}
