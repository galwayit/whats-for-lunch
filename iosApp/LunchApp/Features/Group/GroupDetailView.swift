//
//  GroupDetailView.swift
//  LunchApp
//
//  @file GroupDetailView.swift
//  @description Host view of a group lunch: place and time, invite link with share sheet, guest RSVPs, reminder toggle and cancel.
//  @author AI Assistant
//  @date 2026-09-03
//

import SwiftUI

struct GroupDetailView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppEnvironment.self) private var app
    @State private var model: GroupDetailViewModel?
    @State private var shareItem: ShareItem?
    @State private var showsQRSheet = false
    @State private var showsCancelConfirmation = false
    @State private var splitModel: SplitBillViewModel?
    @State private var showsDetails = false
    @State private var suggestionToApply: GroupSuggestion?
    let groupId: String

    var body: some View {
        Group {
            if let model { content(model) } else { Color.clear }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            if model == nil { model = GroupDetailViewModel(core: app.core, groupId: groupId) }
        }
    }

    private func content(_ model: GroupDetailViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            ScreenHeader(title: model.group?.name ?? Copy.Home.groupRowTitle, dismissal: .back, onDismiss: { app.dismiss() })
            if let group = model.group {
                ScrollView {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                        LunchCard {
                            VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                                GroupPlanningSummary(group: group)
                                if !model.isHost {
                                    GroupSafetyButton(code: group.inviteCode, targetKind: "group", targetId: group.id, label: "Report invitation or block host") { app.dismiss() }
                                }
                                if model.isHost {
                                    LunchButton(title: "Edit invitation details", style: .secondary) { showsDetails = true }
                                }
                                detail(icon: .restaurant, text: group.placeName ?? Copy.Group.choosingPlace)
                                if let address = group.placeAddress { detail(icon: .locationOn, text: address) }
                                detail(icon: .schedule, text: group.scheduledAt.formatted(date: .complete, time: .shortened))
                                if group.placeName == nil && model.isHost {
                                    LunchButton(title: Copy.Group.proposalsTitle, style: .secondary) {
                                        app.replaceTop(with: .groupProposals(groupId: group.id))
                                    }
                                } else {
                                    LunchButton(title: Copy.Split.groupOpen, style: .secondary, icon: .payments, identifier: "group_split_button") {
                                        splitModel = SplitBillViewModel(
                                            guestNames: SplitBillViewModel.acceptedGuestNames(model.guests, hostId: group.hostId),
                                            placeName: group.placeName
                                        )
                                    }
                                }
                            }
                        }

                        if model.isHost {
                            Text("Guest suggestions").lunchText(.heading)
                            if let error = model.suggestionsError {
                                Text(error.planningMessage).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.danger)
                                LunchButton(title: "Retry suggestions", style: .secondary) { Task { await model.loadSuggestions() } }
                            } else if model.suggestions.isEmpty {
                                Text("Guests can suggest a different place or time from their invitation.").lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                            }
                            ForEach(model.suggestions) { suggestion in
                                LunchCard {
                                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                                        Text("From \(suggestion.displayName)").lunchText(.heading)
                                        SuggestionSummary(suggestion: suggestion)
                                        GroupSafetyButton(code: group.inviteCode, targetKind: "suggestion", targetId: suggestion.id, label: "Report suggestion or block guest") { Task { await model.refresh() } }
                                        if suggestion.status == "pending" {
                                            LunchButton(title: "Apply suggestion", style: .primary, isDisabled: model.reviewingId != nil) { suggestionToApply = suggestion }
                                            LunchButton(title: "Keep current plan", style: .secondary, isDisabled: model.reviewingId != nil) { Task { await model.review(suggestion, accept: false) } }
                                        } else { Text(suggestion.status.capitalized).lunchText(.caption) }
                                    }
                                }
                            }
                        }

                        Text(Copy.Group.detailInvite).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
                        InviteShareRow(inviteUrl: model.inviteUrl, onShare: {
                            shareItem = URL(string: model.inviteUrl).map(ShareItem.init)
                        }, onShowQR: {
                            showsQRSheet = true
                        })

                        if let error = model.error { ErrorStateView(error: error) { Task { await model.refresh() } } }
                        if let error = model.guestsError { ErrorStateView(error: error) { Task { await model.observeGuests() } } }
                        Text(Copy.Group.detailGuests).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
                        LunchCard {
                            VStack(spacing: 0) {
                                if model.guests.isEmpty {
                                    Text(Copy.Group.inviteAttending(0)).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                                } else {
                                    ForEach(model.guests) { guest in
                                        VStack(alignment: .leading) {
                                            GuestRow(rsvp: guest)
                                            if guest.guestUserId != app.session?.userId {
                                                GroupSafetyButton(code: group.inviteCode, targetKind: "rsvp", targetId: guest.id, label: "Report or block \(guest.displayName)") { Task { await model.refresh() } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Toggle(Copy.Group.detailReminder, isOn: Binding(
                            get: { model.reminderEnabled },
                            set: { enabled in Task { await model.setReminder(enabled) } }
                        ))
                        .tint(Tokens.Palette.primary)
                        .lunchText(.body)
                        .padding(Tokens.Spacing.md)
                        .background(Tokens.Palette.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))

                        if model.isHost { Button(role: .destructive) { showsCancelConfirmation = true } label: {
                            Text(Copy.Group.detailCancel)
                                .lunchText(.button)
                                .frame(maxWidth: .infinity, minHeight: Tokens.Size.buttonHeight)
                        }
                        .disabled(model.isCancelling) }
                    }
                    .padding(Tokens.Spacing.page)
                    .padding(.bottom, Tokens.Spacing.xl)
                }
            } else if let error = model.error {
                ErrorStateView(error: error) { Task { await model.observeGroup() } }
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await model.refresh()
                do { try await Task.sleep(for: .seconds(15)) } catch { return }
            }
        }
        .fullScreenCover(isPresented: $showsDetails) {
            if let group = model.group { GroupDetailsSheet(details: group.details) { try await model.updateDetails($0) } }
        }
        .confirmationDialog("Apply this suggestion?", isPresented: Binding(get: { suggestionToApply != nil }, set: { if !$0 { suggestionToApply = nil } }), titleVisibility: .visible) {
            Button("Update lunch and reset RSVPs") {
                if let suggestion = suggestionToApply { Task { await model.review(suggestion, accept: true) } }
                suggestionToApply = nil
            }
            Button("Cancel", role: .cancel) { suggestionToApply = nil }
        } message: { Text("All guests will need to RSVP again. Share the updated invitation so they can check the new plan.") }
        .sheet(item: $shareItem) { item in ShareSheet(items: [item.url]) }
        .sheet(isPresented: $showsQRSheet) { InviteQRSheet(inviteUrl: model.inviteUrl) }
        .sheet(item: $splitModel) { splitModel in
            SplitBillView(model: splitModel) { Task { await useGroupSplitShare(splitModel, model: model) } }
        }
        .confirmationDialog(Copy.Group.cancelTitle, isPresented: $showsCancelConfirmation, titleVisibility: .visible) {
            Button(Copy.Group.detailCancel, role: .destructive) {
                Task {
                    if await model.cancel() {
                        app.showToast(Copy.Group.groupCancelled)
                        app.dismiss()
                    }
                }
            }
            Button(Copy.Action.cancel, role: .cancel) {}
        } message: {
            Text(Copy.Group.cancelBody)
        }
        .alert(Copy.Error.serviceTitle, isPresented: Binding(
            get: { model.actionError != nil },
            set: { if !$0 { model.actionError = nil } }
        )) {
            Button(Copy.Action.done) { model.actionError = nil }
        } message: {
            Text(model.actionError?.planningMessage ?? Copy.Error.serviceBody)
        }
    }

    /// "Use my share" from the split sheet: logs the meal straight away (no cost field to fill in
    /// here) and shows the same `Logged` toast Track uses.
    private func useGroupSplitShare(_ splitModel: SplitBillViewModel, model: GroupDetailViewModel) async {
        guard let user = app.user, let group = model.group, let meal = splitModel.buildGroupMeal(userId: user.id, group: group) else { return }
        do {
            _ = try await app.core.meals.log(meal: meal)
            app.showToast(Copy.Track.logged)
            self.splitModel = nil
        } catch {
            model.actionError = CoreError.from(error)
        }
    }

    private func detail(icon: LunchIcon, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.sm) {
            IconView(icon: icon).foregroundStyle(Tokens.Palette.primary)
            Text(text).lunchText(.body).foregroundStyle(Tokens.Palette.text)
        }
    }
}

#Preview {
    GroupDetailView(groupId: PreviewData.group.id).environment(AppEnvironment.preview(PreviewCoreOptions(isPro: true, isSignedIn: true)))
}
