import SwiftUI

/// Text remains intact while editing; money becomes integer cents only after validation.
struct GroupDetailsDraft {
    var hostName = ""
    var budget = ""
    var paymentArrangement = "undecided"
    var paymentMethod = "undecided"
    init(_ details: GroupDetails = GroupDetails()) {
        hostName = details.hostName
        budget = details.budgetPerPersonMinor.map { String(format: "%.2f", Double($0) / 100) } ?? ""
        paymentArrangement = details.paymentArrangement
        paymentMethod = details.paymentMethod
    }
    var value: GroupDetails? {
        let host = hostName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty, host.count <= 60 else { return nil }
        let text = budget.trimmingCharacters(in: .whitespacesAndNewlines)
        var cents: Int64?
        if !text.isEmpty {
            guard text.range(of: "^[0-9]+([.,][0-9]{1,2})?$", options: .regularExpression) != nil,
                  let amount = Decimal(string: text.replacingOccurrences(of: ",", with: ".")), amount <= 10000 else { return nil }
            cents = NSDecimalNumber(decimal: amount * 100).int64Value
        }
        return GroupDetails(hostName: host, budgetPerPersonMinor: cents, paymentArrangement: paymentArrangement, paymentMethod: paymentMethod)
    }
}

struct GroupDetailsFields: View {
    @Binding var draft: GroupDetailsDraft
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text("Invitation details").lunchText(.heading)
            Text("Host name").lunchText(.label)
            LunchTextField(placeholder: "Name shown to guests", text: $draft.hostName, icon: .person, identifier: "group_host_name")
            Text("Budget per person (AUD)").lunchText(.label)
            LunchTextField(placeholder: "Optional, e.g. 25.00", text: $draft.budget, icon: .payments, identifier: "group_budget")
                .keyboardType(.decimalPad)
            Text("Leave the budget blank if it is still to be confirmed.").lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            Picker("Who pays", selection: $draft.paymentArrangement) {
                ForEach(GroupDetails.arrangements, id: \.0) { Text($0.1).tag($0.0) }
            }
            Picker("How to pay", selection: $draft.paymentMethod) {
                ForEach(GroupDetails.methods, id: \.0) { Text($0.1).tag($0.0) }
            }
            Text("This records the plan for the meal. No money is collected here.").lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
        }.tint(Tokens.Palette.primary).foregroundStyle(Tokens.Palette.text)
    }
}

struct GroupPlanningSummary: View {
    let group: LunchGroup
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Label("Host: \(group.hostName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Name not provided" : group.hostName)", systemImage: "person")
            Label(group.details.budgetDescription, systemImage: "dollarsign.circle")
            Label("Who pays: \(group.details.arrangementDescription)", systemImage: "person.2")
            Label("Payment: \(group.details.paymentDescription)", systemImage: "creditcard")
        }.lunchText(.bodySmall).foregroundStyle(Tokens.Palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GroupDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: GroupDetailsDraft
    @State private var saving = false
    @State private var error: String?
    let save: (GroupDetails) async throws -> Void
    init(details: GroupDetails, save: @escaping (GroupDetails) async throws -> Void) {
        _draft = State(initialValue: GroupDetailsDraft(details)); self.save = save
    }
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Edit invitation", onDismiss: { dismiss() })
            ScrollView {
                VStack(spacing: Tokens.Spacing.lg) {
                    GroupDetailsFields(draft: $draft)
                    Text("Changing the budget or payment plan resets RSVPs. Guests will need to respond again.").lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                    if let error { Text(error).foregroundStyle(Tokens.Palette.danger) }
                    LunchButton(title: "Save details", style: .primary, isLoading: saving, isDisabled: draft.value == nil) {
                        guard let details = draft.value else { return }
                        saving = true
                        Task {
                            do { try await save(details); dismiss() }
                            catch { self.error = CoreError.from(error).planningMessage }
                            saving = false
                        }
                    }
                }.padding(Tokens.Spacing.page)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Tokens.Palette.ground.ignoresSafeArea())
            .interactiveDismissDisabled(saving)
    }
}

struct SuggestionSummary: View {
    let suggestion: GroupSuggestion
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            if let place = suggestion.placeName { Text(place).lunchText(.heading) }
            if let address = suggestion.placeAddress { Text(address).lunchText(.bodySmall) }
            if let time = suggestion.scheduledAt { Text(time.formatted(date: .complete, time: .shortened)).lunchText(.body) }
            if let note = suggestion.note { Text(note).lunchText(.bodySmall) }
        }.frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Tokens.Palette.text)
    }
}

extension CoreError {
    var planningMessage: String {
        switch self {
        case .offline: Copy.Error.offlineBody
        case .service(let code, let message) where ["BAD_REQUEST", "NAME_REQUIRED", "NOT_FOUND", "FORBIDDEN"].contains(code): message
        default: Copy.Error.serviceBody
        }
    }
}
