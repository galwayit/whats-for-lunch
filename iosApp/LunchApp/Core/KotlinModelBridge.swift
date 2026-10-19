//
//  KotlinModelBridge.swift
//  LunchApp
//
//  Explicit value mappings between the Swift UI models and LunchCore models.
//  Keeping this boundary mechanical prevents Kotlin/Native reference types from
//  leaking into SwiftUI state and makes migrations auditable.
//

import Foundation
@preconcurrency import LunchCore

// Kotlin/Native freezes these immutable data-class values at the Swift boundary.
// Swift cannot infer that guarantee from the generated Objective-C classes.
extension LunchCore.Restaurant: @unchecked @retroactive Sendable {}
extension LunchCore.Achievement: @unchecked @retroactive Sendable {}

private func kotlinInts(_ values: [String: Int]) -> [String: LunchCore.KotlinInt] {
    values.mapValues { LunchCore.KotlinInt(int: Int32($0)) }
}

private func kotlinDoubles(_ values: [String: Double]) -> [String: LunchCore.KotlinDouble] {
    values.mapValues { LunchCore.KotlinDouble(double: $0) }
}

private func kotlinBooleans(_ values: [String: Bool]) -> [String: LunchCore.KotlinBoolean] {
    values.mapValues { LunchCore.KotlinBoolean(bool: $0) }
}

extension UserPreferences {
    var kotlin: LunchCore.UserPreferences {
        LunchCore.UserPreferences(
            dietaryRestrictions: dietaryRestrictions,
            cuisinePreferences: cuisinePreferences,
            allergens: allergens,
            allergenSafetyLevels: kotlinInts(allergenSafetyLevels),
            contextualPreferences: contextualPreferences,
            cuisineRatings: kotlinDoubles(cuisineRatings),
            restaurantVisitCounts: kotlinInts(restaurantVisitCounts),
            budgetLevel: Int32(budgetLevel),
            maxTravelDistance: maxTravelDistance,
            includeChains: includeChains,
            mealFrequencyPerDay: Int32(mealFrequencyPerDay),
            weeklyBudget: weeklyBudget,
            enableLocationServices: enableLocationServices,
            showMapView: showMapView,
            mapZoomLevel: Int32(mapZoomLevel),
            lastKnownLocation: lastKnownLocation?.map { LunchCore.KotlinDouble(double: $0) },
            requireDietaryVerification: requireDietaryVerification,
            minimumRating: minimumRating,
            preferredPriceRanges: preferredPriceRanges,
            avoidBusyTimes: avoidBusyTimes,
            accessibilityRequirements: kotlinBooleans(accessibilityRequirements)
        )
    }
}

extension LunchCore.UserPreferences {
    var app: UserPreferences {
        UserPreferences(
            dietaryRestrictions: dietaryRestrictions,
            cuisinePreferences: cuisinePreferences,
            allergens: allergens,
            allergenSafetyLevels: allergenSafetyLevels.mapValues { Int($0.int32Value) },
            contextualPreferences: contextualPreferences,
            cuisineRatings: cuisineRatings.mapValues(\.doubleValue),
            restaurantVisitCounts: restaurantVisitCounts.mapValues { Int($0.int32Value) },
            budgetLevel: Int(budgetLevel),
            maxTravelDistance: maxTravelDistance,
            includeChains: includeChains,
            mealFrequencyPerDay: Int(mealFrequencyPerDay),
            weeklyBudget: weeklyBudget,
            enableLocationServices: enableLocationServices,
            showMapView: showMapView,
            mapZoomLevel: Int(mapZoomLevel),
            lastKnownLocation: lastKnownLocation?.map(\.doubleValue),
            requireDietaryVerification: requireDietaryVerification,
            minimumRating: minimumRating,
            preferredPriceRanges: preferredPriceRanges,
            avoidBusyTimes: avoidBusyTimes,
            accessibilityRequirements: accessibilityRequirements.mapValues(\.boolValue)
        )
    }
}

extension LunchCore.UserProfile {
    var app: UserProfile {
        UserProfile(id: id, name: name, preferences: preferences.app, createdAtEpochSeconds: createdAtEpochSeconds)
    }
}

extension Meal {
    var kotlin: LunchCore.Meal {
        LunchCore.Meal(
            id: id.map { LunchCore.KotlinLong(longLong: $0) },
            userId: userId,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            mealType: mealType,
            cost: cost,
            dateEpochSeconds: dateEpochSeconds,
            notes: notes,
            photoIds: photoIds
        )
    }
}

extension LunchCore.Meal {
    var app: Meal {
        Meal(
            id: id?.int64Value,
            userId: userId,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            mealType: mealType,
            cost: cost,
            dateEpochSeconds: dateEpochSeconds,
            notes: notes,
            photoIds: photoIds
        )
    }
}

extension RestaurantReview {
    var kotlin: LunchCore.RestaurantReview {
        LunchCore.RestaurantReview(
            reviewId: reviewId,
            authorName: authorName,
            authorPhotoUrl: authorPhotoUrl,
            rating: Int32(rating),
            text: text,
            timeEpochSeconds: timeEpochSeconds,
            relativeTimeDescription: relativeTimeDescription,
            authorUri: authorUri, sourceUri: sourceUri
        )
    }
}

extension LunchCore.RestaurantReview {
    var app: RestaurantReview {
        RestaurantReview(
            reviewId: reviewId,
            authorName: authorName,
            authorPhotoUrl: authorPhotoUrl,
            rating: Int(rating),
            text: text,
            timeEpochSeconds: timeEpochSeconds,
            relativeTimeDescription: relativeTimeDescription,
            authorUri: authorUri, sourceUri: sourceUri
        )
    }
}

extension Restaurant {
    var kotlin: LunchCore.Restaurant {
        LunchCore.Restaurant(
            placeId: placeId,
            name: name,
            location: location,
            address: address,
            phoneNumber: phoneNumber,
            website: website,
            latitude: latitude.map { LunchCore.KotlinDouble(double: $0) },
            longitude: longitude.map { LunchCore.KotlinDouble(double: $0) },
            distanceFromUser: distanceFromUser.map { LunchCore.KotlinDouble(double: $0) },
            rating: rating.map { LunchCore.KotlinDouble(double: $0) },
            reviewCount: reviewCount.map { LunchCore.KotlinInt(int: Int32($0)) },
            priceLevel: priceLevel.map { LunchCore.KotlinInt(int: Int32($0)) },
            priceRanges: priceRanges,
            cuisineType: cuisineType,
            cuisineTypes: cuisineTypes,
            supportedDietaryRestrictions: supportedDietaryRestrictions,
            allergenInfo: allergenInfo,
            dietaryCompatibilityScores: kotlinDoubles(dietaryCompatibilityScores),
            hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
            communityVerificationCount: Int32(communityVerificationCount),
            openingHours: openingHours,
            isOpenNow: isOpenNow,
            currentWaitTime: currentWaitTime,
            features: features,
            averageMealCost: averageMealCost.map { LunchCore.KotlinDouble(double: $0) },
            valueScore: valueScore.map { LunchCore.KotlinDouble(double: $0) },
            mealTypeAverageCosts: kotlinDoubles(mealTypeAverageCosts),
            recentReviews: recentReviews.map(\.kotlin),
            cachedAtEpochSeconds: cachedAtEpochSeconds,
            lastVerifiedEpochSeconds: lastVerifiedEpochSeconds.map { LunchCore.KotlinLong(longLong: $0) },
            photoReference: photoReference,
            photoReferences: photoReferences,
            photoUrl: photoUrl,
            googleMapsUri: googleMapsUri, photoSourceUri: photoSourceUri,
            photoAttributions: (photoAttributions ?? []).map(\.kotlin), attributions: (attributions ?? []).map(\.kotlin)
        )
    }
}

extension LunchCore.Restaurant {
    var app: Restaurant {
        Restaurant(
            placeId: placeId,
            name: name,
            location: location,
            address: address,
            phoneNumber: phoneNumber,
            website: website,
            latitude: latitude?.doubleValue,
            longitude: longitude?.doubleValue,
            distanceFromUser: distanceFromUser?.doubleValue,
            rating: rating?.doubleValue,
            reviewCount: reviewCount.map { Int($0.int32Value) },
            priceLevel: priceLevel.map { Int($0.int32Value) },
            priceRanges: priceRanges,
            cuisineType: cuisineType,
            cuisineTypes: cuisineTypes,
            supportedDietaryRestrictions: supportedDietaryRestrictions,
            allergenInfo: allergenInfo,
            dietaryCompatibilityScores: dietaryCompatibilityScores.mapValues(\.doubleValue),
            hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
            communityVerificationCount: Int(communityVerificationCount),
            openingHours: openingHours,
            isOpenNow: isOpenNow,
            currentWaitTime: currentWaitTime,
            features: features,
            averageMealCost: averageMealCost?.doubleValue,
            valueScore: valueScore?.doubleValue,
            mealTypeAverageCosts: mealTypeAverageCosts.mapValues(\.doubleValue),
            recentReviews: recentReviews.map(\.app),
            cachedAtEpochSeconds: cachedAtEpochSeconds,
            lastVerifiedEpochSeconds: lastVerifiedEpochSeconds?.int64Value,
            photoReference: photoReference,
            photoReferences: photoReferences,
            photoUrl: photoUrl,
            googleMapsUri: googleMapsUri, photoSourceUri: photoSourceUri,
            photoAttributions: photoAttributions.isEmpty ? nil : photoAttributions.map(\.app),
            attributions: attributions.isEmpty ? nil : attributions.map(\.app)
        )
    }
}

extension LunchCore.AiRecommendation {
    var app: AiRecommendation {
        AiRecommendation(
            id: id,
            userId: userId,
            restaurants: restaurants.map(\.app),
            reasoning: reasoning,
            factorWeights: factorWeights.mapValues(\.doubleValue),
            overallConfidence: overallConfidence,
            investmentSummary: investmentSummary,
            generatedAtEpochSeconds: generatedAtEpochSeconds,
            wasAccepted: wasAccepted,
            userFeedback: userFeedback
        )
    }
}

extension Achievement {
    var kotlin: LunchCore.Achievement {
        LunchCore.Achievement(
            id: id,
            title: title,
            description: description,
            category: category,
            points: Int32(points),
            iconName: iconName,
            isUnlocked: isUnlocked,
            unlockedAtEpochSeconds: unlockedAtEpochSeconds.map { LunchCore.KotlinLong(longLong: $0) }
        )
    }
}

extension LunchCore.Achievement {
    var app: Achievement {
        Achievement(
            id: id,
            title: title,
            description: description_,
            category: category,
            points: Int(points),
            iconName: iconName,
            isUnlocked: isUnlocked,
            unlockedAtEpochSeconds: unlockedAtEpochSeconds?.int64Value
        )
    }
}

extension LunchCore.GateDecision {
    var app: GateDecision { GateDecision(allowed: allowed, reason: reason.app) }
}

extension LunchCore.GateReason {
    var app: GateReason {
        switch self {
        case .ok: .ok
        case .aiDailyLimit: .aiDailyLimit
        case .favouritesLimit: .favouritesLimit
        case .historyWindow: .historyWindow
        case .hostRequiresPro: .hostRequiresPro
        case .signInRequired: .signInRequired
        }
    }
}

extension LunchCore.ProPackage {
    var app: ProPackage {
        ProPackage(identifier: identifier, productId: productId, localizedPrice: localizedPrice, periodLabel: periodLabel, hasFreeTrial: hasFreeTrial, trialLabel: trialLabel)
    }
}

extension LunchCore.ProOfferings {
    var app: ProOfferings { ProOfferings(monthly: monthly?.app, yearly: yearly?.app) }
}

extension LunchCore.SubscriptionStatus {
    var app: SubscriptionStatus {
        SubscriptionStatus(
            isPro: isPro,
            productId: productId,
            expiresAtEpochSeconds: expiresAtEpochSeconds?.int64Value,
            willRenew: willRenew,
            managementUrl: managementUrl
        )
    }
}

extension LunchCore.AuthSession {
    var app: AuthSession { AuthSession(userId: userId, email: email, displayName: displayName, requiresAppleReauthentication: requiresAppleReauthentication) }
}

extension Location {
    var kotlin: LunchCore.Location {
        LunchCore.Location(latitude: latitude, longitude: longitude, accuracyMetres: accuracyMetres.map { LunchCore.KotlinDouble(double: $0) })
    }
}

extension LunchCore.Location {
    var app: Location { Location(latitude: latitude, longitude: longitude, accuracyMetres: accuracyMetres?.doubleValue) }
}

extension LunchCore.LunchGroup {
    var app: LunchGroup {
        LunchGroup(
            id: id,
            hostId: hostId,
            hostName: hostName,
            name: name,
            scheduledAtEpochSeconds: scheduledAtEpochSeconds,
            areaLatitude: areaLatitude,
            areaLongitude: areaLongitude,
            radiusKm: radiusKm,
            placeId: placeId,
            placeName: placeName,
            placeAddress: placeAddress,
            inviteCode: inviteCode,
            createdAtEpochSeconds: createdAtEpochSeconds,
            budgetPerPersonMinor: budgetPerPersonMinor?.int64Value,
            currencyCode: currencyCode,
            paymentArrangement: paymentArrangement,
            paymentMethod: paymentMethod
        )
    }
}

extension LunchCore.RsvpStatus {
    var app: RsvpStatus {
        switch self {
        case .pending: .pending
        case .accepted: .accepted
        case .declined: .declined
        }
    }
}

extension RsvpStatus {
    var kotlin: LunchCore.RsvpStatus {
        switch self {
        case .pending: .pending
        case .accepted: .accepted
        case .declined: .declined
        }
    }
}

extension LunchCore.Rsvp {
    var app: Rsvp {
        Rsvp(
            id: id,
            groupId: groupId,
            guestUserId: guestUserId,
            displayName: displayName,
            status: status.app,
            respondedAtEpochSeconds: respondedAtEpochSeconds?.int64Value
        )
    }
}

extension LunchCore.GroupProposal {
    var app: GroupProposal { GroupProposal(restaurant: restaurant.app, reasons: reasons) }
}

extension LunchCore.Invitation {
    var app: Invitation {
        Invitation(group: group.app, attendees: attendees.map(\.app), myStatus: myStatus?.app, inviteUrl: inviteUrl, mySuggestion: mySuggestion?.app)
    }
}

func appCoreError(_ error: Error) -> CoreError {
    let nsError = error as NSError
    guard let kotlin = nsError.kotlinException as? LunchCore.CoreError else {
        return .unknown(error.localizedDescription)
    }
    if kotlin is LunchCore.CoreError.Offline { return .offline }
    if kotlin is LunchCore.CoreError.NotSignedIn { return .notSignedIn }
    if let service = kotlin as? LunchCore.CoreError.Service {
        return .service(code: service.code, message: service.message)
    }
    if let gate = kotlin as? LunchCore.CoreError.Gate {
        return .gate(gate.reason.app)
    }
    if let unknown = kotlin as? LunchCore.CoreError.Unknown {
        return .unknown(unknown.cause?.message ?? error.localizedDescription)
    }
    return .unknown(error.localizedDescription)
}

func rethrowCoreError<T>(_ operation: () async throws -> T) async throws -> T {
    do { return try await operation() }
    catch is CancellationError { throw CancellationError() }
    catch { throw appCoreError(error) }
}

extension PlaceAttribution {
    var kotlin: LunchCore.PlaceAttribution { LunchCore.PlaceAttribution(name: name, uri: uri, photoUri: photoUri) }
}
extension LunchCore.PlaceAttribution {
    var app: PlaceAttribution { PlaceAttribution(name: name, uri: uri, photoUri: photoUri) }
}

extension GroupDetails {
    var kotlin: LunchCore.GroupDetails { LunchCore.GroupDetails(hostName: hostName, budgetPerPersonMinor: budgetPerPersonMinor.map { KotlinLong(longLong: $0) }, currencyCode: currencyCode, paymentArrangement: paymentArrangement, paymentMethod: paymentMethod) }
}
extension GroupSuggestionDraft {
    var kotlin: LunchCore.GroupSuggestionDraft { LunchCore.GroupSuggestionDraft(placeName: placeName, placeAddress: placeAddress, scheduledAt: scheduledAt.map { KotlinLong(longLong: $0) }, note: note) }
}
extension LunchCore.GroupSuggestion {
    var app: GroupSuggestion { GroupSuggestion(id: id, groupId: groupId, displayName: displayName, placeName: placeName, placeAddress: placeAddress, scheduledAtEpochSeconds: scheduledAtEpochSeconds?.int64Value, note: note, status: status, createdAtEpochSeconds: createdAtEpochSeconds) }
}
