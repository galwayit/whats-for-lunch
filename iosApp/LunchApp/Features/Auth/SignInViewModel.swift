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
        isSigningIn = provider
        error = nil
        defer { isSigningIn = nil }
        do {
            switch provider {
            case .apple:
                let credential = try await tokens.appleCredential()
                _ = try await core.auth.signInWithApple(idToken: credential.idToken, nonce: credential.nonce, fullName: credential.fullName)
            case .google:
                let idToken = try await tokens.googleIdToken()
                _ = try await core.auth.signInWithGoogle(idToken: idToken)
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
