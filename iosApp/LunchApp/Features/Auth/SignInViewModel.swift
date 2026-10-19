/**
 * @file SignInViewModel.swift
 * @description Runs a sign-in through the providers the core auth contract exposes
 *              (Apple and Google) and reports progress and errors to the sheet.
 * @author AI Assistant
 * @date 2026-09-03
 */

import Foundation

/// The providers `AuthRepository` accepts.
enum SignInProvider: String, CaseIterable, Identifiable {
    case apple, google

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple: return Copy.Profile.signInApple
        case .google: return Copy.Profile.signInGoogle
        }
    }

    var identifier: String { "sign_in_\(rawValue)" }
}

@Observable
final class SignInViewModel {
    /// The provider whose sign-in is in flight, if any.
    private(set) var isSigningIn: SignInProvider?
    private(set) var error: CoreError?
    private(set) var isEmailBusy = false
    private(set) var emailStep: EmailAuthStep = .signIn
    private(set) var notice: String?
    var email = ""
    var password = ""
    var passwordConfirmation = ""
    var code = ""
    var isBusy: Bool { isSigningIn != nil || isEmailBusy }


    let providers: [SignInProvider]
    private let core: LunchCoreClient
    private let tokens: any SignInTokenProvider

    init(core: LunchCoreClient, tokens: any SignInTokenProvider = SignInTokens.forCurrentLaunch()) {
        self.core = core
        self.tokens = tokens
        providers = tokens.supportedProviders
    }

    /// Returns true once the core reports a session. A cancelled system sheet returns false with no error.
    func signIn(with provider: SignInProvider) async -> Bool {
        guard !isBusy else { return false }
        isSigningIn = provider
        error = nil
        defer { isSigningIn = nil }
        do {
            switch provider {
            case .apple:
                let credential = try await tokens.appleCredential()
                _ = try await core.auth.signInWithApple(idToken: credential.idToken, nonce: credential.nonce, fullName: credential.fullName)
            case .google:
                let credential = try await tokens.googleCredential()
                _ = try await core.auth.signInWithGoogle(idToken: credential.idToken, nonce: credential.nonce, accessToken: credential.accessToken)
            }
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.error = CoreError.from(error)
            return false
        }
    }
}


enum EmailAuthStep { case signIn, register, verify, forgotPassword, resetPassword }

extension SignInViewModel {
    var emailTitle: String {
        switch emailStep {
        case .signIn: "Sign in with email"
        case .register: "Create your account"
        case .verify: "Verify your email"
        case .forgotPassword: "Forgot password?"
        case .resetPassword: "Choose a new password"
        }
    }

    var emailAction: String {
        switch emailStep {
        case .signIn: "Sign in"
        case .register: "Create account"
        case .verify: "Verify email"
        case .forgotPassword: "Send reset code"
        case .resetPassword: "Reset password"
        }
    }

    var needsPassword: Bool { [.signIn, .register, .resetPassword].contains(emailStep) }
    var needsNewPassword: Bool { [.register, .resetPassword].contains(emailStep) }
    var needsCode: Bool { [.verify, .resetPassword].contains(emailStep) }

    func changeEmailStep(_ step: EmailAuthStep) {
        guard !isBusy else { return }
        emailStep = step
        password = ""
        passwordConfirmation = ""
        code = ""
        notice = nil
        error = nil
    }

    func submitEmail() async -> Bool {
        guard !isBusy else { return false }
        error = nil
        notice = nil
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.contains("@"), email.split(separator: "@").count == 2,
              !email.contains(where: { $0.isWhitespace }) else {
            error = .service(code: "INVALID_EMAIL", message: "Enter a valid email address.")
            return false
        }
        if needsPassword && password.isEmpty {
            error = .service(code: "PASSWORD_REQUIRED", message: "Enter your password.")
            return false
        }
        if needsNewPassword && (password.count < 8 || password != passwordConfirmation) {
            error = .service(code: "INVALID_PASSWORD", message: "Use at least 8 characters and make sure both passwords match.")
            return false
        }
        if needsCode && (!(6...10).contains(code.count) || !code.allSatisfy({ $0.isASCII && $0.isNumber })) {
            error = .service(code: "INVALID_CODE", message: "Enter the verification code from your email.")
            return false
        }
        isEmailBusy = true
        defer { isEmailBusy = false }
        do {
            switch emailStep {
            case .signIn:
                _ = try await core.auth.signInWithEmail(email: email, password: password)
            case .register:
                let signedIn = try await core.auth.registerWithEmail(email: email, password: password)
                password = ""
                passwordConfirmation = ""
                if !signedIn {
                    emailStep = .verify
                    notice = "Check your email for a verification code. If you already have an account, sign in or reset your password."
                    return false
                }
            case .verify:
                _ = try await core.auth.verifyEmail(email: email, code: code)
            case .forgotPassword:
                try await core.auth.requestPasswordReset(email: email)
                emailStep = .resetPassword
                notice = "If an account exists for this email, a reset code is on its way."
                return false
            case .resetPassword:
                _ = try await core.auth.resetPassword(email: email, code: code, newPassword: password)
            }
            password = ""
            passwordConfirmation = ""
            code = ""
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.error = CoreError.from(error)
            if case .service(let code, _) = self.error, code == "email_not_confirmed" {
                emailStep = .verify
                password = ""
            }
            return false
        }
    }

    func resendCode() async {
        guard !isBusy else { return }
        isEmailBusy = true
        error = nil
        defer { isEmailBusy = false }
        do {
            if emailStep == .resetPassword { try await core.auth.requestPasswordReset(email: email) }
            else { try await core.auth.resendVerification(email: email) }
            notice = "If eligible, a new code has been sent. Check your inbox and spam folder."
        } catch is CancellationError {
        } catch { self.error = CoreError.from(error) }
    }

    var errorMessage: String? {
        guard let error else { return nil }
        if error == .offline { return Copy.Error.offlineBody }
        guard case .service(let code, let message) = error else { return "Sign-in could not finish. Please try again." }
        switch code {
        case "INVALID_EMAIL", "PASSWORD_REQUIRED", "INVALID_PASSWORD", "INVALID_CODE", "PASSWORD_RESET_RETRY": return message
        case "invalid_credentials": return "The email or password is incorrect. Try again or reset your password."
        case "email_not_confirmed": return "Verify your email first. You can request another code below."
        case "otp_expired": return "That code is invalid or expired. Request a new code and try again."
        case "over_email_send_rate_limit", "over_request_rate_limit": return "Please wait a minute before requesting another code."
        case "weak_password": return "Choose a stronger password with at least 8 characters."
        case SystemSignInTokens.googleUnavailableCode: return "Google sign-in is unavailable right now. Try email."
        default: return "Sign-in could not finish. Please try again."
        }
    }
}
