/**
 * @file SignInSheet.swift
 * @description Sign-in sheet (route `.signIn`) and the provider button stack shared with the
 *              Profile tab's signed-out row.
 * @author AI Assistant
 * @date 2026-09-03
 */

import SwiftUI
import AuthenticationServices
import GoogleSignInSwift

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
                        EmailSignInForm(model: model) { app.dismiss() }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Tokens.Spacing.page)
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

/// One button per provider plus the inline error line.
struct SignInButtons: View {
    @Environment(\.colorScheme) private var colorScheme
    let model: SignInViewModel
    var onSignedIn: () -> Void = {}
    var showsError = true

    var body: some View {
        VStack(spacing: Tokens.Spacing.sm) {
            ForEach(model.providers) { provider in
                Group {
                    if provider == .google {
                        GoogleSignInButton(scheme: colorScheme == .dark ? .dark : .light, style: .wide, state: model.isBusy ? .disabled : .normal) {
                            Task { if await model.signIn(with: provider) { onSignedIn() } }
                        }
                    } else {
                        NativeAppleSignInButton(isEnabled: !model.isBusy, usesDarkBackground: colorScheme == .dark) {
                            Task { if await model.signIn(with: provider) { onSignedIn() } }
                        }.frame(height: Tokens.Size.buttonHeight)
                    }
                }
                .accessibilityIdentifier(provider.identifier)
                .disabled(model.isBusy)
            }
            if model.isSigningIn != nil { ProgressView("Signing in…").lunchText(.caption) }
            if showsError, let message = model.errorMessage {
                Text(message)
                    .lunchText(.bodySmall)
                    .foregroundStyle(Tokens.Palette.danger)
            }
        }
    }
}

#Preview {
    SignInSheet().environment(AppEnvironment.preview())
}


private struct EmailSignInForm: View {
    @Bindable var model: SignInViewModel
    var onSignedIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            if model.emailStep == .signIn {
                SignInButtons(model: model, onSignedIn: onSignedIn, showsError: false)
                HStack {
                    Rectangle().frame(height: 1)
                    Text("or").lunchText(.caption)
                    Rectangle().frame(height: 1)
                }.foregroundStyle(Tokens.Palette.textSecondary.opacity(0.5))
            }
            Text(model.emailTitle).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
            TextField("Email address", text: $model.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("auth_email")
                .disabled(model.isBusy || model.needsCode)
            if model.needsCode {
                TextField("Email verification code", text: $model.code)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("auth_code")
            }
            if model.needsPassword {
                SecureField(model.needsNewPassword ? "Password (at least 8 characters)" : "Password", text: $model.password)
                    .textContentType(model.needsNewPassword ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("auth_password")
            }
            if model.needsNewPassword {
                SecureField("Confirm password", text: $model.passwordConfirmation)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("auth_confirm_password")
            }
            if let notice = model.notice {
                Text(notice).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
            }
            if let error = model.errorMessage {
                Text(error).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.danger)
                    .accessibilityIdentifier("auth_error")
            }
            LunchButton(title: model.emailAction, isLoading: model.isEmailBusy, isDisabled: model.isBusy, identifier: "auth_submit") {
                Task { if await model.submitEmail() { onSignedIn() } }
            }
            if model.needsCode {
                Button("Resend code") { Task { await model.resendCode() } }
                    .accessibilityIdentifier("auth_resend")
            }
            if model.emailStep == .signIn {
                HStack {
                    Button("Create account") { model.changeEmailStep(.register) }.accessibilityIdentifier("auth_register")
                    Spacer()
                    Button("Forgot password?") { model.changeEmailStep(.forgotPassword) }.accessibilityIdentifier("auth_forgot")
                }
            } else {
                Button("Back to sign in") { model.changeEmailStep(.signIn) }.accessibilityIdentifier("auth_back")
            }
        }
        .disabled(model.isBusy)
        .tint(Tokens.Palette.primary)
        .onDisappear { model.password = ""; model.passwordConfirmation = ""; model.code = "" }
    }
}


/// Keep Apple's official button styling while sharing the coordinator with account deletion.
private struct NativeAppleSignInButton: UIViewRepresentable {
    let isEnabled: Bool
    let usesDarkBackground: Bool
    var action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .continue, style: usesDarkBackground ? .white : .black)
        button.addAction(UIAction { _ in context.coordinator.action() }, for: .touchUpInside)
        return button
    }
    func updateUIView(_ button: ASAuthorizationAppleIDButton, context: Context) {
        button.isEnabled = isEnabled
        context.coordinator.action = action
    }
    final class Coordinator {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
    }
}
