import SwiftUI

struct DietaryNotice: View {
    @Environment(AppEnvironment.self) private var app
    var body: some View {
        if let prefs = app.user?.preferences, !prefs.allergens.isEmpty || !prefs.dietaryRestrictions.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(prefs.requireDietaryVerification
                     ? "Only places with verified information matching your dietary preferences are shown. Allergen-free evidence is currently unavailable, so allergy filters may return no matches."
                     : "Dietary and allergen suitability is unverified. Confirm ingredients and cross-contact risks directly with the venue before ordering.")
                    .lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Review dietary preferences") { app.present(.preferences) }
                    .font(.caption).foregroundStyle(Tokens.Palette.primary)
            }
        }
    }
}
