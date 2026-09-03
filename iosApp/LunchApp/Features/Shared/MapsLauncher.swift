//
//  MapsLauncher.swift
//  LunchApp
//
//  Opens Apple Maps for directions or a place. Falls back to a search by name when the
//  restaurant has no coordinates.
//

import UIKit

enum MapsLauncher {
    private static let scheme = "https"
    private static let host = "maps.apple.com"

    static func openDirections(to restaurant: Restaurant) {
        var items = [URLQueryItem(name: "dirflg", value: "w")]
        if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
            items.append(URLQueryItem(name: "daddr", value: "\(latitude),\(longitude)"))
        } else {
            items.append(URLQueryItem(name: "daddr", value: restaurant.address ?? restaurant.name))
        }
        open(items)
    }

    static func openPlace(_ restaurant: Restaurant) {
        var items = [URLQueryItem(name: "q", value: restaurant.name)]
        if let latitude = restaurant.latitude, let longitude = restaurant.longitude {
            items.append(URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"))
        }
        open(items)
    }

    private static func open(_ items: [URLQueryItem]) {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/"
        components.queryItems = items
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }
}
