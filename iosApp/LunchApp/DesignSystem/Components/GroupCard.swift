//
//  GroupCard.swift
//  LunchApp
//
//  Home "Lunch together" row item: group name, place, time, and how many are going.
//

import SwiftUI

struct GroupCard: View {
    let group: LunchGroup
    let attendingCount: Int
    let onTap: () -> Void

    private static let discSize = Tokens.Size.touchTarget
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        Button(action: onTap) {
            LunchCard {
                HStack(spacing: Tokens.Spacing.md) {
                    ZStack {
                        Circle().fill(Tokens.Palette.primarySoft)
                        IconView(icon: .group, size: Self.iconSize).foregroundStyle(Tokens.Palette.primary)
                    }
                    .frame(width: Self.discSize, height: Self.discSize)
                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text(group.name).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                        Text(subtitle).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                        Text(Copy.Group.inviteAttending(attendingCount)).lunchText(.caption).foregroundStyle(Tokens.Palette.primary)
                    }
                    Spacer()
                    IconView(icon: .chevronRight, size: Self.iconSize).foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let time = group.scheduledAt.formatted(date: .abbreviated, time: .shortened)
        if let place = group.placeName { return "\(place) · \(time)" }
        return time
    }
}

#Preview("Group card") {
    LunchPreview {
        GroupCard(group: PreviewData.group, attendingCount: 2) {}
    }
}
