//
//  PreviewLocale.swift
//  LunchApp
//
//  @file PreviewLocale.swift
//  @description Moves the fixed sample places to wherever the phone actually is.
//  @author AI Assistant
//  @date 2026-09-23
//

import CoreLocation
import Foundation

/// Where the sample places should appear, relative to the anchor they were written around.
///
/// The preview data is a fixed set of Sydney restaurants. Demoing the app anywhere else shows
/// the wrong suburbs and addresses, and every place sits far enough away that the radius filter
/// drops it. This carries the translation to apply to that data: an offset for the coordinates,
/// and the real locality for the text.
struct PreviewLocale: Equatable {
    var offsetLatitude: Double = 0
    var offsetLongitude: Double = 0
    /// Locality of the phone, such as "Carlton". Nil keeps the sample suburb.
    var suburb: String?
    /// State and postcode of the phone, such as "VIC 3053". Nil keeps the sample tail.
    var region: String?

    /// Identity: the data is already written around this anchor.
    static let anchored = PreviewLocale()

    /// Applies the translation to one restaurant and recomputes its distance from `origin`.
    func relocate(_ restaurant: Restaurant, from origin: Location) -> Restaurant {
        var moved = restaurant
        if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
            let newLatitude = latitude + offsetLatitude
            let newLongitude = longitude + offsetLongitude
            moved.latitude = newLatitude
            moved.longitude = newLongitude
            moved.distanceFromUser = PreviewRestaurantRepository.distanceKm(
                from: origin, toLatitude: newLatitude, longitude: newLongitude
            )
        }
        if let suburb {
            moved.location = suburb
            moved.address = Self.readdress(restaurant.address, suburb: suburb, region: region)
        }
        return moved
    }

    func relocate(_ restaurants: [Restaurant], from origin: Location) -> [Restaurant] {
        restaurants.map { relocate($0, from: origin) }
    }

    /// Keeps the street line of the sample address and swaps the locality tail for the real one,
    /// so "12 Crown Street, Surry Hills NSW 2010" becomes "12 Crown Street, Carlton VIC 3053".
    /// The street names stay invented, which is the point: this is sample data, not a listing.
    static func readdress(_ address: String?, suburb: String, region: String?) -> String? {
        guard let address else { return nil }
        let street = address.split(separator: ",").first.map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? address
        let tail = [suburb, region].compactMap { $0 }.joined(separator: " ")
        return tail.isEmpty ? street : "\(street), \(tail)"
    }
}

/// Resolves a `PreviewLocale` for the phone's position, once, and remembers it.
///
/// One reverse-geocode covers every sample place. Geocoding is rate limited and can fail
/// offline, in which case only the coordinates move and the sample text stays as written.
final class PreviewLocaleResolver {
    private let anchor: Location
    private var cached: PreviewLocale?
    private var resolving: Task<PreviewLocale, Never>?

    init(anchor: Location) {
        self.anchor = anchor
    }

    /// The locale resolved so far. Screens that have no location to hand, such as the detail
    /// sheet, use this so they agree with the list the user came from.
    var current: PreviewLocale { cached ?? .anchored }

    func locale(for location: Location) async -> PreviewLocale {
        if let cached { return cached }
        if let resolving { return await resolving.value }
        let task = Task { () -> PreviewLocale in
            var locale = PreviewLocale(
                offsetLatitude: location.latitude - anchor.latitude,
                offsetLongitude: location.longitude - anchor.longitude
            )
            if let placemark = await Self.placemark(for: location) {
                locale.suburb = placemark.locality ?? placemark.subLocality
                locale.region = [placemark.administrativeArea, placemark.postalCode]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .nilWhenBlank
            }
            return locale
        }
        resolving = task
        let locale = await task.value
        cached = locale
        resolving = nil
        return locale
    }

    private static func placemark(for location: Location) async -> CLPlacemark? {
        let target = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return try? await CLGeocoder().reverseGeocodeLocation(target).first
    }
}

private extension String {
    var nilWhenBlank: String? {
        trimmingCharacters(in: .whitespaces).isEmpty ? nil : self
    }
}
