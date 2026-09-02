//
//  GuestRow.swift
//  LunchApp
//
//  One guest in the group detail list with their RSVP status.
//

import SwiftUI

struct GuestRow: View {
    let rsvp: Rsvp

    var body: some View {
        HStack(spacing: Tokens.Spacing.md) {
            InitialAvatar(name: rsvp.displayName, size: Tokens.Size.touchTarget - Tokens.Spacing.sm)
            Text(rsvp.displayName).lunchText(.body).foregroundStyle(Tokens.Palette.text)
            Spacer()
            BadgeLabel(text: statusText, tint: statusColor, background: statusColor.opacity(Tokens.Palette.primarySoftOpacity))
        }
        .padding(.vertical, Tokens.Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rsvp.displayName), \(statusText)")
    }

    private var statusText: String {
        switch rsvp.status {
        case .accepted: return Copy.Group.detailAccepted
        case .declined: return Copy.Group.detailDeclined
        case .pending: return Copy.Group.detailPending
        }
    }

    private var statusColor: Color {
        switch rsvp.status {
        case .accepted: return Tokens.Palette.success
        case .declined: return Tokens.Palette.danger
        case .pending: return Tokens.Palette.textSecondary
        }
    }
}

#Preview("Guests") {
    LunchPreview {
        VStack(spacing: 0) {
            ForEach(PreviewData.rsvps) { GuestRow(rsvp: $0) }
        }
    }
}
