/**
 * @file SignInSheet.swift
 * @description Sign-in sheet (route `.signIn`) and the provider button stack shared with the
 *              Profile tab's signed-out row.
 * @author AI Assistant
 * @date 2026-09-03
 */

import SwiftUI

struct SignInSheet: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: SignInViewModel?

    private static let iconDiscSize = Tokens.Size.heroButton / 2

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = SignInViewModel(core: app.core) } }
    }

    private func content(_ model: SignInViewModel) -> some View {
        VStack(spacing: 0) {
            ScreenHeader(title: Copy.Profile.signInTitle, dismissal: .close, onDismiss: { app.dismiss() })
            ScrollView {
                LunchCard {
                    VStack(spacing: Tokens.Spacing.md) {
                        IconView(icon: .login, size: Tokens.Size.iconDefault)
                            .foregroundStyle(Tokens.Palette.primary)
                            .frame(width: Self.iconDiscSize, height: Self.iconDiscSize)
                            .background(Tokens.Palette.primarySoft, in: Circle())
                        Text(Copy.Profile.signInTitle)
                            .lunchText(.title)
                            .foregroundStyle(Tokens.Palette.text)
                        Text(Copy.Profile.signInBody)
                            .lunchText(.body)
                            .foregroundStyle(Tokens.Palette.textSecondary)
                            .multilineTextAlignment(.center)
                        SignInButtons(model: model) { app.dismiss() }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Tokens.Spacing.page)
            }
        }
    }
}

/// One button per provider plus the inline error line.
struct SignInButtons: View {
    let model: SignInViewModel
    var onSignedIn: () -> Void = {}

    var body: some View {
        VStack(spacing: Tokens.Spacing.sm) {
            ForEach(model.providers) { provider in
                LunchButton(
                    title: provider.title,
                    style: provider == .apple ? .primary : .secondary,
                    isLoading: model.isSigningIn == provider,
                    isDisabled: model.isSigningIn != nil && model.isSigningIn != provider,
                    identifier: provider.identifier
                ) {
                    Task { if await model.signIn(with: provider) { onSignedIn() } }
                }
            }
            if let error = model.error {
                Text(error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
                    .lunchText(.bodySmall)
                    .foregroundStyle(Tokens.Palette.danger)
            }
        }
    }
}

#Preview {
    SignInSheet().environment(AppEnvironment.preview())
}
