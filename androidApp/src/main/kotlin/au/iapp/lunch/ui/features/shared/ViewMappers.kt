/**
 * @file ViewMappers.kt
 * @description Maps shared-core models onto the view types the design-system components take
 * (`au.iapp.lunch.ui.preview`). The fields match by name, so each mapping is a plain copy.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import au.iapp.lunch.core.model.LunchGroup
import au.iapp.lunch.core.model.Meal
import au.iapp.lunch.core.model.ProPackage
import au.iapp.lunch.core.model.Restaurant
import au.iapp.lunch.core.model.Rsvp
import au.iapp.lunch.core.model.RsvpStatus
import au.iapp.lunch.core.model.WeeklyBudgetState
import au.iapp.lunch.ui.preview.LunchGroup as LunchGroupView
import au.iapp.lunch.ui.preview.Meal as MealView
import au.iapp.lunch.ui.preview.ProPackage as ProPackageView
import au.iapp.lunch.ui.preview.Restaurant as RestaurantView
import au.iapp.lunch.ui.preview.Rsvp as RsvpView
import au.iapp.lunch.ui.preview.RsvpStatus as RsvpStatusView
import au.iapp.lunch.ui.preview.WeeklyBudget as WeeklyBudgetView

fun Restaurant.toView(): RestaurantView = RestaurantView(
    placeId = placeId,
    name = name,
    location = location,
    address = address,
    distanceFromUser = distanceFromUser,
    rating = rating,
    reviewCount = reviewCount,
    priceLevel = priceLevel,
    cuisineTypes = cuisineTypes.ifEmpty { listOfNotNull(cuisineType) },
    isOpenNow = isOpenNow,
    photoUrl = photoUrl,
)

fun Meal.toView(): MealView = MealView(
    id = id ?: 0L,
    restaurantName = restaurantName,
    mealType = mealType,
    cost = cost,
    dateEpochSeconds = dateEpochSeconds,
    notes = notes,
)

fun WeeklyBudgetState.toView(): WeeklyBudgetView = WeeklyBudgetView(
    weeklyCapacity = weeklyCapacity,
    currentSpent = currentSpent,
    experiencesLogged = experiencesLogged,
    targetExperiences = targetExperiences,
)

fun LunchGroup.toView(): LunchGroupView = LunchGroupView(
    id = id,
    hostName = hostName,
    name = name,
    scheduledAtEpochSeconds = scheduledAtEpochSeconds,
    placeName = placeName,
    placeAddress = placeAddress,
    inviteCode = inviteCode,
    details = au.iapp.lunch.core.model.GroupDetails(hostName, budgetPerPersonMinor, currencyCode, paymentArrangement, paymentMethod),
)

fun RsvpStatus.toView(): RsvpStatusView = when (this) {
    RsvpStatus.PENDING -> RsvpStatusView.PENDING
    RsvpStatus.ACCEPTED -> RsvpStatusView.ACCEPTED
    RsvpStatus.DECLINED -> RsvpStatusView.DECLINED
}

fun Rsvp.toView(): RsvpView = RsvpView(id = id, displayName = displayName, status = status.toView())

fun ProPackage.toView(): ProPackageView = ProPackageView(
    identifier = identifier,
    productId = productId,
    localizedPrice = localizedPrice,
    periodLabel = periodLabel,
    hasFreeTrial = hasFreeTrial,
    trialLabel = trialLabel,
)
