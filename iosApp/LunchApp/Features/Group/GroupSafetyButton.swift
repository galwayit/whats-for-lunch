import SwiftUI

/// Reports go to the private moderation queue. Blocking also stops future
/// interactions from the same account or anonymous guest identity on the server.
struct GroupSafetyButton: View {
    @Environment(AppEnvironment.self) private var app
    let code: String
    let targetKind: String
    let targetId: String?
    var label = "Report or block"
    let onBlocked: () -> Void
    @State private var showing = false

    var body: some View {
        Button(label) { showing = true }
            .font(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            .sheet(isPresented: $showing) {
                GroupSafetySheet(code: code, targetKind: targetKind, targetId: targetId) { blocked in
                    showing = false
                    if blocked { onBlocked() }
                }
            }
    }
}

private struct GroupSafetySheet: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    let code: String
    let targetKind: String
    let targetId: String?
    let completed: (Bool) -> Void
    @State private var reason = "harassment"
    @State private var busy = false
    @State private var error: String?
    private let reasons = [("harassment", "Harassment or threats"), ("hate", "Hateful content"), ("sexual", "Sexual content"), ("spam", "Spam or scam"), ("other", "Other concern")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason for reporting") {
                    Picker("Reason", selection: $reason) {
                        ForEach(reasons, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    Text("Reports include this content and are sent privately to Lunch support for review. Blocking hides this person’s content and stops their interactions with you.")
                    if app.session == nil {
                        Text("As a guest, blocking applies to this invitation on this device. Sign in before blocking for account-wide blocking across invitations and devices.").font(.caption)
                    }
                }
                Section {
                    Button("Send report") { Task { await send("report") } }
                    Button("Report and block", role: .destructive) { Task { await send("report_block") } }
                    Button("Block without reporting", role: .destructive) { Task { await send("block") } }
                }.disabled(busy)
                if busy { ProgressView() }
                if let error { Text(error).foregroundStyle(.red) }
                Link("Contact support", destination: LunchConfig.supportUrl)
            }
            .navigationTitle("Report or block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(busy) } }
            .interactiveDismissDisabled(busy)
        }
    }

    private func send(_ action: String) async {
        busy = true
        defer { busy = false }
        error = nil
        do {
            try await app.core.groups.safetyAction(code: code, targetKind: targetKind, targetId: targetId, action: action, reason: reason)
            app.showToast(action == "block" ? "Blocked" : "Report sent to Lunch support")
            completed(action != "report")
        } catch {
            self.error = "Couldn’t save your request. Please try again or contact support."
        }
    }
}
