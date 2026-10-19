//
//  InvitationCard.swift
//  LunchApp
//
//  What a guest sees from an invitation link: host, place, address, time, who is going, and
//  Accept / Decline.
//

import SwiftUI

struct InvitationCard: View {
    let group: LunchGroup
    let attendees: [Rsvp]
    var isResponding = false
    let onAccept: () -> Void
    let onDecline: () -> Void

    private static let avatarSize = Tokens.Size.iconDefault + Tokens.Spacing.sm
    private static let avatarOverlap = Tokens.Spacing.sm
    private static let maxAvatars = 4
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    private var going: [Rsvp] { attendees.filter { $0.status == .accepted } }

    var body: some View {
        LunchCard(padding: Tokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(Copy.Group.inviteTitle(host: group.hostName))
                    .lunchText(.title)
                    .foregroundStyle(Tokens.Palette.text)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                    if let place = group.placeName {
                        detail(icon: .restaurant, text: place)
                    }
                    if let address = group.placeAddress {
                        detail(icon: .locationOn, text: address)
                    }
                    detail(icon: .schedule, text: group.scheduledAt.formatted(date: .complete, time: .shortened))
                }
                GroupPlanningSummary(group: group)
                HStack(spacing: Tokens.Spacing.sm) {
                    avatarStack
                    Text(Copy.Group.inviteAttending(going.count)).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
                }
                HStack(spacing: Tokens.Spacing.sm) {
                    LunchButton(title: Copy.Group.inviteDecline, style: .secondary, isDisabled: isResponding, action: onDecline)
                    LunchButton(title: Copy.Group.inviteAccept, style: .primary, isLoading: isResponding, action: onAccept)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func detail(icon: LunchIcon, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.Spacing.sm) {
            IconView(icon: icon, size: Self.iconSize).foregroundStyle(Tokens.Palette.primary)
            Text(text).lunchText(.body).foregroundStyle(Tokens.Palette.text)
        }
    }

    private var avatarStack: some View {
        HStack(spacing: -Self.avatarOverlap) {
            ForEach(going.prefix(Self.maxAvatars)) { rsvp in
                InitialAvatar(name: rsvp.displayName, size: Self.avatarSize)
                    .overlay(Circle().strokeBorder(Tokens.Palette.surface, lineWidth: 1))
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Invitation") {
    LunchPreview {
        InvitationCard(group: PreviewData.group, attendees: PreviewData.rsvps, onAccept: {}, onDecline: {})
        InvitationCard(group: PreviewData.group, attendees: PreviewData.rsvps, isResponding: true, onAccept: {}, onDecline: {})
    }
}
