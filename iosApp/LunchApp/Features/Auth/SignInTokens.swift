/**
 * @file SignInTokens.swift
 * @description Obtains provider credentials on the platform side (Sign in with Apple through
 *              AuthenticationServices) and hands plain tokens to the core auth contract.
 * @author AI Assistant
 * @date 2026-09-03
 */

import AuthenticationServices
import CryptoKit
import UIKit

/// What `AuthRepository.signInWithApple` needs: the identity token, the raw nonce it was
/// requested with, and the name Apple shares on first sign-in.
nonisolated struct AppleCredential: Equatable {
    let idToken: String
    let nonce: String
    let fullName: String?
}

/// Source of provider tokens. The view model only ever sees strings; SDK types stay here.
protocol SignInTokenProvider {
    var supportedProviders: [SignInProvider] { get }
    func appleCredential() async throws -> AppleCredential
    func googleIdToken() async throws -> String
}

enum SignInTokens {
    /// Preview-core runs (Maestro, screenshots) skip the system sheets; the preview auth
    /// repository accepts any token.
    static func forCurrentLaunch() -> any SignInTokenProvider {
        if LaunchArguments.current.usesPreviewCore || FeatureFlags.previewCoreByDefault {
            return PreviewSignInTokens()
        }
        return SystemSignInTokens()
    }
}

struct PreviewSignInTokens: SignInTokenProvider {
    let supportedProviders = SignInProvider.allCases

    func appleCredential() async throws -> AppleCredential {
        AppleCredential(idToken: "preview", nonce: "preview", fullName: nil)
    }

    func googleIdToken() async throws -> String { "preview" }
}

struct SystemSignInTokens: SignInTokenProvider {
    /// Error code surfaced while the GoogleSignIn SDK and its OAuth client id are not in the project.
    static let googleUnavailableCode = "GOOGLE_SIGN_IN_UNAVAILABLE"
    let supportedProviders: [SignInProvider] = [.apple]

    func appleCredential() async throws -> AppleCredential {
        try await AppleSignInCoordinator().signIn()
    }

    func googleIdToken() async throws -> String {
        throw CoreError.service(code: Self.googleUnavailableCode, message: "GoogleSignIn SDK is not linked")
    }
}

/// Drives one `ASAuthorizationController` request and resolves it as an async call.
/// Cancelling the system sheet throws `CancellationError`, which the view model treats as "no error".
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleCredential, Error>?
    private var nonce = ""

    func signIn() async throws -> AppleCredential {
        nonce = Self.randomNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            resume(.failure(CoreError.unknown("Apple returned no identity token")))
            return
        }
        let name = credential.fullName.map { PersonNameComponentsFormatter().string(from: $0) } ?? ""
        resume(.success(AppleCredential(idToken: idToken, nonce: nonce, fullName: name.isEmpty ? nil : name)))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as? ASAuthorizationError)?.code == .canceled {
            resume(.failure(CancellationError()))
        } else {
            resume(.failure(error))
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }

    private func resume(_ result: Result<AppleCredential, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    private static func randomNonce() -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<32).map { _ in alphabet[Int.random(in: 0..<alphabet.count)] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
