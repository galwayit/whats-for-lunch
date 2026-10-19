import MapKit
import SwiftUI

/// A search centre chosen by the user, never presented as their device location.
nonisolated struct SearchArea: Codable, Hashable, Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    var id: String { "\(latitude),\(longitude)" }
    var location: Location { Location(latitude: latitude, longitude: longitude) }
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    private static let key = "lunch.selectedSearchArea.v1"

    static func load(from defaults: UserDefaults = .standard) -> SearchArea? {
        guard let data = defaults.data(forKey: key), let area = try? JSONDecoder().decode(Self.self, from: data), area.isValid else { return nil }
        return area
    }
    static func save(_ area: SearchArea?, to defaults: UserDefaults = .standard) {
        if let area, area.isValid, let data = try? JSONEncoder().encode(area) { defaults.set(data, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }
}

struct SearchAreaButton: View {
    @Environment(AppEnvironment.self) private var app
    var body: some View {
        Button { app.present(.searchArea) } label: {
            Label(app.searchArea.map { "Search near \($0.name)" } ?? "Search area: current location", systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(Tokens.Palette.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Tokens.Spacing.sm)
        }
        .accessibilityIdentifier("search_area_button")
    }
}

struct SearchAreaView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.openURL) private var openURL
    @State private var query = ""
    @State private var results: [SearchArea] = []
    @State private var searching = false
    @State private var message: String?
    @State private var search: MKLocalSearch?
    @State private var revision = 0

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Choose a search area", dismissal: .back) { app.dismiss() }
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                    Text("Search for a suburb, town or address. You can find lunch without sharing your device location.")
                        .lunchText(.body).foregroundStyle(Tokens.Palette.textSecondary)
                    LunchTextField(placeholder: "Suburb, town or address", text: $query, icon: .locationOn, identifier: "search_area_query", submitLabel: .search) { Task { await findArea() } }
                    LunchButton(title: "Find area", style: .primary, isLoading: searching, isDisabled: query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, identifier: "search_area_find") { Task { await findArea() } }
                    if let message { Text(message).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary) }
                    ForEach(results) { area in
                        Button {
                            app.selectSearchArea(area)
                            app.dismiss()
                        } label: {
                            Label(area.name, systemImage: "mappin.circle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding().background(Tokens.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: Tokens.Radius.container))
                        }
                        .foregroundStyle(Tokens.Palette.text)
                    }
                    Divider()
                    LunchButton(title: "Use my current location", style: .secondary, icon: .nearMe, identifier: "search_area_current") {
                        Task {
                            let permission = LocationPermission()
                            if await permission.request() {
                                app.selectSearchArea(nil)
                                app.dismiss()
                            } else {
                                message = "Location access is off. Choose an area above, or enable location for Lunch in Settings."
                            }
                        }
                    }
                    Button("Open location settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }.foregroundStyle(Tokens.Palette.primary)
                    Text("Your selected area is saved on this device. Area searches are provided by Apple Maps.")
                        .lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
                }.padding(Tokens.Spacing.page)
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onDisappear { revision += 1; search?.cancel() }
    }

    private func findArea() async {
        search?.cancel()
        revision += 1
        let expected = revision
        searching = true
        results = []
        message = nil
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        request.resultTypes = [.address]
        let pending = MKLocalSearch(request: request)
        search = pending
        do {
            let response = try await pending.start()
            guard expected == revision else { return }
            var seen: Set<String> = []
            results = response.mapItems.compactMap { item in
                let coordinate: CLLocationCoordinate2D
                if #available(iOS 26.0, *) { coordinate = item.location.coordinate }
                else { coordinate = item.placemark.coordinate }
                let area = SearchArea(name: item.name ?? query, latitude: coordinate.latitude, longitude: coordinate.longitude)
                return area.isValid && seen.insert(area.id).inserted ? area : nil
            }
            if results.isEmpty { message = "No matching area found. Include the state or country and try again." }
        } catch {
            guard expected == revision else { return }
            message = "We couldn’t find that area right now. Check your connection and try again."
        }
        if expected == revision { searching = false }
    }
}
