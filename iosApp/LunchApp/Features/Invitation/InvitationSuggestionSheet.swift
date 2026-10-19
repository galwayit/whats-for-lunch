import SwiftUI

struct InvitationSuggestionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var place = ""
    @State private var address = ""
    @State private var note = ""
    @State private var changeTime = false
    @State private var time: Date
    @Bindable var model: InvitationViewModel
    let requiresName: Bool
    init(model: InvitationViewModel, requiresName: Bool) {
        self.model = model; self.requiresName = requiresName
        _time = State(initialValue: max(model.invitation?.group.scheduledAt ?? Date(), Date().addingTimeInterval(3600)))
    }
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Suggest a change", onDismiss: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    Text("Suggest another place, time, or both. The host decides whether to change the plan. Your RSVP stays the same until then.")
                        .lunchText(.body).foregroundStyle(Tokens.Palette.textSecondary)
                    if requiresName {
                        Text("Your name").lunchText(.label)
                        LunchTextField(placeholder: "Your name", text: $model.guestName, icon: .person, identifier: "suggestion_guest_name")
                    }
                    Text("Alternative place (optional)").lunchText(.label)
                    LunchTextField(placeholder: "Restaurant or meeting place", text: $place, icon: .restaurant, identifier: "suggestion_place")
                    LunchTextField(placeholder: "Address (optional)", text: $address, icon: .locationOn)
                    Toggle("Suggest another time", isOn: $changeTime).tint(Tokens.Palette.primary)
                    if changeTime { DatePicker("New time", selection: $time, in: Date()...) }
                    LunchTextField(placeholder: "Note for the host (optional)", text: $note)
                    if let error = model.actionError { Text(error.planningMessage).foregroundStyle(Tokens.Palette.danger).lunchText(.bodySmall) }
                    LunchButton(title: "Send suggestion", style: .primary, isLoading: model.isResponding, isDisabled: clean(place) == nil && !changeTime, identifier: "invite_suggestion_send") {
                        Task {
                            let draft = GroupSuggestionDraft(placeName: clean(place), placeAddress: clean(address), scheduledAt: changeTime ? Int64(time.timeIntervalSince1970) : nil, note: clean(note))
                            if await model.suggest(draft, requiresName: requiresName) { dismiss() }
                        }
                    }
                }.padding(Tokens.Spacing.page)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Tokens.Palette.ground.ignoresSafeArea())
            .interactiveDismissDisabled(model.isResponding)
    }
    private func clean(_ value: String) -> String? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
