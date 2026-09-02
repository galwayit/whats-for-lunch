//
//  InviteShareRow.swift
//  LunchApp
//
//  The group's invite link (id invite_link_text) with a Share invite action that the screen
//  wires to the system share sheet.
//

import SwiftUI

struct InviteShareRow: View {
    let inviteUrl: String
    let onShare: () -> Void

    static let linkIdentifier = "invite_link_text"
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                HStack(spacing: Tokens.Spacing.sm) {
                    IconView(icon: .mail, size: Self.iconSize).foregroundStyle(Tokens.Palette.primary)
                    Text(inviteUrl)
                        .lunchText(.bodySmall)
                        .foregroundStyle(Tokens.Palette.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .accessibilityLabel("Invite link")
                        .accessibilityValue(inviteUrl)
                        .accessibilityIdentifier(Self.linkIdentifier)
                }
                .padding(Tokens.Spacing.sm + Tokens.Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Tokens.Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: Tokens.Radius.toast, style: .continuous))
                LunchButton(title: Copy.Group.detailShare, style: .primary, icon: .share, action: onShare)
            }
        }
    }
}

#Preview("Invite share") {
    LunchPreview {
        InviteShareRow(inviteUrl: PreviewData.inviteUrl) {}
    }
}
