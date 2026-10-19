// Generated from shared/restaurant-chains.json. Do not edit the aliases here.
import Foundation

nonisolated enum RestaurantChains {
    private static let aliases = [
        "burger king",
        "burgerking",
        "chicken treat",
        "dominos",
        "grilld",
        "guzman y gomez",
        "hungry jacks",
        "hungryjacks",
        "kentucky fried chicken",
        "kfc",
        "mcdonald",
        "mcdonalds",
        "nandos",
        "oporto",
        "pizza hut",
        "red rooster",
        "starbucks",
        "subway",
        "taco bell",
        "the coffee club",
        "zambrero",
    ]

    static func matches(_ name: String) -> Bool {
        let normalised = name.lowercased()
            .replacingOccurrences(of: "['’‘ʼ`]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        return aliases.contains { " \(normalised) ".contains(" \($0) ") }
    }
}
