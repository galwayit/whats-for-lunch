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
import GoogleSignIn

/// What `AuthRepository.signInWithApple` needs: the identity token, the raw nonce it was
/// requested with, and the name Apple shares on first sign-in.
nonisolated struct AppleCredential: Equatable {
    let idToken: String
    let nonce: String
    let fullName: String?
    var authorizationCode: String? = nil
}

nonisolated struct GoogleCredential: Equatable {
    let idToken: String
    let nonce: String
    var accessToken: String? = nil
}

/// Source of provider tokens. The view model only ever sees strings; SDK types stay here.
protocol SignInTokenProvider {
    var supportedProviders: [SignInProvider] { get }
    func appleCredential() async throws -> AppleCredential
    func googleCredential() async throws -> GoogleCredential
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

    func googleCredential() async throws -> GoogleCredential { GoogleCredential(idToken: "preview", nonce: "preview") }
}

struct SystemSignInTokens: SignInTokenProvider {
    /// Setup errors are kept out of user-visible SDK diagnostics.
    static let googleUnavailableCode = "GOOGLE_SIGN_IN_UNAVAILABLE"
    let supportedProviders: [SignInProvider] = [.apple, .google]

    func appleCredential() async throws -> AppleCredential {
        try await AppleSignInCoordinator().signIn()
    }

    func googleCredential() async throws -> GoogleCredential {
        guard let client = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              let server = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String,
              !client.isEmpty, !server.isEmpty else {
            throw CoreError.service(code: Self.googleUnavailableCode, message: "Google sign-in is unavailable. Try email.")
        }
        guard var presenting = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else {
            throw CoreError.unknown("No sign-in presentation window")
        }
        while let next = presenting.presentedViewController { presenting = next }
        let nonce = AppleSignInCoordinator.randomNonce()
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: client, serverClientID: server)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presenting, hint: nil, additionalScopes: nil,
                nonce: AppleSignInCoordinator.sha256(nonce)
            )
            guard let idToken = result.user.idToken?.tokenString else {
                throw CoreError.unknown("Google returned no identity token")
            }
            // Supabase owns the session. The Google SDK need not retain a second signed-in account.
            let accessToken = result.user.accessToken.tokenString
            GIDSignIn.sharedInstance.signOut()
            return GoogleCredential(idToken: idToken, nonce: nonce, accessToken: accessToken)
        } catch {
            if (error as NSError).domain == kGIDSignInErrorDomain,
               (error as NSError).code == GIDSignInError.canceled.rawValue { throw CancellationError() }
            throw error
        }
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
        let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        resume(.success(AppleCredential(idToken: idToken, nonce: nonce, fullName: name.isEmpty ? nil : name, authorizationCode: code)))
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

    fileprivate static func randomNonce() -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<32).map { _ in alphabet[Int.random(in: 0..<alphabet.count)] })
    }

    fileprivate static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
