//
//  InviteQRSheet.swift
//  LunchApp
//
//  QR sheet opened from Group detail's Show QR code button (design/screens.md screen 10):
//  `group.qr.title`, the invite URL as a QR code (id invite_qr_image), `group.qr.body`, and the
//  invite link text. The code is generated on device by InviteQRCode; there is no network call.
//

import SwiftUI

struct InviteQRSheet: View {
    @Environment(\.dismiss) private var dismiss
    let inviteUrl: String

    @State private var cgImage: CGImage?

    static let imageIdentifier = "invite_qr_image"

    /// Dark modules on a light background in both themes so any camera can scan it (design/
    /// screens.md screen 10): fixed to the light-appearance value of the darkest text colour and
    /// the lightest surface colour, regardless of the device's current colour scheme.
    private static let foreground = InviteQRCode.lightCGColor(Tokens.Palette.text)
    private static let background = InviteQRCode.lightCGColor(Tokens.Palette.surface)

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: Copy.Group.qrTitle, onDismiss: { dismiss() })
            ScrollView {
                LunchCard {
                    VStack(spacing: Tokens.Spacing.md) {
                        qrImage
                        Text(Copy.Group.qrBody)
                            .lunchText(.body)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                            .multilineTextAlignment(.center)
                        Text(inviteUrl)
                            .lunchText(.bodySmall)
                            .foregroundStyle(Tokens.Palette.text)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                            .accessibilityLabel("Invite link")
                            .accessibilityValue(inviteUrl)
                            .accessibilityIdentifier(InviteShareRow.linkIdentifier)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Tokens.Spacing.page)
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .task(id: inviteUrl) {
            cgImage = await InviteQRCode.makeCGImageAsync(message: inviteUrl, foreground: Self.foreground, background: Self.background)
        }
    }

    @ViewBuilder
    private var qrImage: some View {
        if let cgImage {
            Image(decorative: cgImage, scale: 1)
                .interpolation(.none)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: Tokens.Size.heroButton)
                .accessibilityLabel(inviteUrl)
                .accessibilityIdentifier(Self.imageIdentifier)
        } else {
            ProgressView()
                .frame(width: Tokens.Size.heroButton, height: Tokens.Size.heroButton)
        }
    }
}

#Preview("Invite QR") {
    LunchPreview {
        InviteQRSheet(inviteUrl: PreviewData.inviteUrl)
    }
}
