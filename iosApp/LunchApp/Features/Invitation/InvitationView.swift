//
//  InvitationView.swift
//  LunchApp
//
//  @file InvitationView.swift
//  @description Guest view of an invitation opened from a universal link or -openInvite: accept or decline (guests give a name), then add to calendar or get directions.
//  @author AI Assistant
//  @date 2026-09-03
//

import SwiftUI

struct InvitationView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.openURL) private var openURL
    @State private var model: InvitationViewModel?
    let code: String

    var body: some View {
        Group {
            if let model { content(model) } else { Color.clear }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            if model == nil { model = InvitationViewModel(core: app.core, code: code) }
        }
    }

    private func content(_ model: InvitationViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            ScreenHeader(title: Copy.Group.invitationTitle, onDismiss: { app.dismiss() })
            Group {
                if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let invitation = model.invitation {
                    ScrollView {
                        VStack(spacing: Tokens.Spacing.lg) {
                            if model.status == .accepted {
                                responseCard(title: Copy.Group.inviteAcceptedTitle, icon: .eventAvailable, group: invitation.group)
                                LunchButton(title: Copy.Action.addToCalendar, style: .primary, icon: .calendarToday, isLoading: model.isAddingToCalendar) {
                                    Task {
                                        if await model.addToCalendar() { app.showToast(Copy.Group.calendarAdded) }
                                    }
                                }
                                if invitation.group.placeName != nil {
                                    LunchButton(title: Copy.Action.directions, style: .secondary, icon: .directions) {
                                        MapsLauncher.openDirections(to: Self.restaurant(from: invitation.group))
                                    }
                                }
                                if model.showsGuestOffer {
                                    UpsellRow(title: Copy.Gate.guestOfferTitle, message: Copy.Gate.guestOfferBody, ctaTitle: Copy.Gate.hostCta, icon: .group) {
                                        app.present(.paywall)
                                    }
                                    .accessibilityIdentifier("invite_guest_offer")
                                }
                            } else if model.status == .declined {
                                responseCard(title: Copy.Group.inviteDeclinedTitle, icon: .eventBusy, group: invitation.group)
                                LunchButton(title: Copy.Group.inviteGetApp, style: .secondary) { openURL(LunchConfig.appStoreUrl) }
                            } else {
                                if app.session == nil {
                                    LunchTextField(
                                        placeholder: Copy.Group.inviteNamePrompt,
                                        text: $model.guestName,
                                        icon: .person,
                                        identifier: "invite_guest_name"
                                    )
                                }
                                InvitationCard(
                                    group: invitation.group,
                                    attendees: invitation.attendees,
                                    isResponding: model.isResponding,
                                    onAccept: { Task { await model.respond(.accepted, requiresName: app.session == nil) } },
                                    onDecline: { Task { await model.respond(.declined, requiresName: false) } }
                                )
                            }

                            if let error = model.actionError {
                                Text(error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
                                    .lunchText(.bodySmall)
                                    .foregroundStyle(Tokens.Palette.danger)
                            }
                        }
                        .padding(Tokens.Spacing.page)
                        .padding(.bottom, Tokens.Spacing.xl)
                    }
                } else if let error = model.loadError {
                    EmptyState(
                        variant: error == .offline ? .offline : .serviceProblem,
                        title: error == .offline ? Copy.Error.offlineTitle : Copy.Group.invitationMissing,
                        message: error == .offline ? Copy.Error.offlineBody : Copy.Group.invitationMissingBody,
                        actionTitle: Copy.Action.retry,
                        action: { Task { await model.load() } }
                    )
                }
            }
        }
        .task { await model.load() }
    }

    /// Confirmation card shown after responding. Keeps the place and time visible so the
    /// guest still has the essentials without reopening the link.
    private func responseCard(title: String, icon: LunchIcon, group: LunchGroup) -> some View {
        LunchCard {
            VStack(spacing: Tokens.Spacing.md) {
                IconView(icon: icon, size: Tokens.Size.touchTarget).foregroundStyle(Tokens.Palette.success)
                Text(title).lunchText(.title).foregroundStyle(Tokens.Palette.text)
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    if let place = group.placeName {
                        detail(icon: .restaurant, text: place)
                    }
                    if let address = group.placeAddress {
                        detail(icon: .locationOn, text: address)
                    }
                    detail(icon: .schedule, text: group.scheduledAt.formatted(date: .complete, time: .shortened))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func detail(icon: LunchIcon, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.sm) {
            IconView(icon: icon, size: Tokens.Size.iconDefault - Tokens.Spacing.xs).foregroundStyle(Tokens.Palette.primary)
            Text(text).lunchText(.body).foregroundStyle(Tokens.Palette.text)
        }
    }

    private static func restaurant(from group: LunchGroup) -> Restaurant {
        Restaurant(
            placeId: group.placeId ?? group.id,
            name: group.placeName ?? group.name,
            location: group.placeAddress ?? "",
            address: group.placeAddress
        )
    }
}

#Preview("Invitation") {
    InvitationView(code: PreviewData.group.inviteCode).environment(AppEnvironment.preview())
}
