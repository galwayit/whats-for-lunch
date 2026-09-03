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
    @Environment(AppEnvironment.self) private var app
    @State private var model: GroupDetailViewModel?
    @State private var shareItem: ShareItem?
    @State private var showsCancelConfirmation = false
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
                                detail(icon: .restaurant, text: group.placeName ?? Copy.Group.choosingPlace)
                                if let address = group.placeAddress { detail(icon: .locationOn, text: address) }
                                detail(icon: .schedule, text: group.scheduledAt.formatted(date: .complete, time: .shortened))
                                if group.placeId == nil {
                                    LunchButton(title: Copy.Group.proposalsTitle, style: .secondary) {
                                        app.replaceTop(with: .groupProposals(groupId: group.id))
                                    }
                                }
                            }
                        }

                        Text(Copy.Group.detailInvite).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
                        InviteShareRow(inviteUrl: model.inviteUrl) {
                            shareItem = URL(string: model.inviteUrl).map(ShareItem.init)
                        }

                        Text(Copy.Group.detailGuests).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
                        LunchCard {
                            VStack(spacing: 0) {
                                if model.guests.isEmpty {
                                    Text(Copy.Group.inviteAttending(0)).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                                } else {
                                    ForEach(model.guests) { GuestRow(rsvp: $0) }
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

                        Button(role: .destructive) { showsCancelConfirmation = true } label: {
                            Text(Copy.Group.detailCancel)
                                .lunchText(.button)
                                .frame(maxWidth: .infinity, minHeight: Tokens.Size.buttonHeight)
                        }
                        .disabled(model.isCancelling)
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
        .task { await model.observeGroup() }
        .task { await model.observeGuests() }
        .sheet(item: $shareItem) { item in ShareSheet(items: [item.url]) }
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
            Text(model.actionError == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
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
