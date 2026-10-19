import SwiftUI

/// Keep the provider and each displayed photo's author alongside the content.
struct GoogleMapsAttribution: View {
    let restaurant: Restaurant
    var includesPhoto = true

    var body: some View {
        if let uri = restaurant.googleMapsUri, let url = URL(string: uri) {
            VStack(alignment: .leading, spacing: 6) {
                Link("Google Maps", destination: url)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: true, vertical: false)
                ForEach(Array((restaurant.attributions ?? []).enumerated()), id: \.offset) { _, credit in
                    AttributionCredit(credit: credit)
                }
                if includesPhoto && restaurant.photoURL != nil {
                    ForEach(Array((restaurant.photoAttributions ?? []).enumerated()), id: \.offset) { _, credit in
                        AttributionCredit(credit: credit)
                    }
                    if let uri = restaurant.photoSourceUri, let url = URL(string: uri) {
                        Link("View photo on Google Maps", destination: url).font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
        }
    }
}

struct AttributionCredit: View {
    let credit: PlaceAttribution
    var body: some View {
        HStack(spacing: 6) {
            if let uri = credit.photoUri, let url = URL(string: uri) {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.clear }
                    .frame(width: 24, height: 24).clipShape(Circle()).accessibilityHidden(true)
            }
            if let uri = credit.uri, let url = URL(string: uri) {
                Link(credit.name, destination: url).font(.caption)
            } else { Text(credit.name).font(.caption) }
        }
    }
}
