import Foundation
import Testing
@testable import LunchApp

@MainActor
struct AuthFlowTests {
    @Test func registration_requires_email_verification_and_clears_password() async {
        let core = PreviewLunchCore()
        let model = SignInViewModel(core: core, tokens: PreviewSignInTokens())
        model.email = " sam@example.test "
        model.changeEmailStep(.register)
        model.password = "password8"
        model.passwordConfirmation = "password8"
        #expect(await model.submitEmail() == false)
        #expect(model.emailStep == .verify)
        #expect(core.auth.session == nil)
        #expect(model.password.isEmpty)
        #expect(model.passwordConfirmation.isEmpty)
        model.code = "12345678"
        #expect(await model.submitEmail())
        #expect(core.auth.session?.email == "sam@example.test")
        #expect(model.code.isEmpty)
    }

    @Test func rejects_short_or_mismatched_password_before_registering() async {
        let core = PreviewLunchCore()
        let model = SignInViewModel(core: core)
        model.email = "sam@example.test"
        model.changeEmailStep(.register)
        model.password = "short"
        model.passwordConfirmation = "short"
        #expect(await model.submitEmail() == false)
        #expect(core.auth.session == nil)
        model.password = "password8"
        #expect(await model.submitEmail() == false)
        #expect(model.emailStep == .register)
    }

    @Test func reset_request_does_not_sign_in_until_code_and_password_are_supplied() async {
        let core = PreviewLunchCore()
        let model = SignInViewModel(core: core)
        model.email = "sam@example.test"
        model.changeEmailStep(.forgotPassword)
        #expect(await model.submitEmail() == false)
        #expect(model.emailStep == .resetPassword)
        #expect(core.auth.session == nil)
        model.password = "password8"
        model.passwordConfirmation = "password8"
        model.code = "12345678"
        #expect(await model.submitEmail())
        #expect(model.password.isEmpty)
    }

    @Test func cancelling_google_leaves_no_error_or_spinner() async {
        let model = SignInViewModel(core: PreviewLunchCore(), tokens: CancelledTokens())
        #expect(await model.signIn(with: .google) == false)
        #expect(model.error == nil)
        #expect(!model.isBusy)
    }

    @Test func email_account_deletion_does_not_request_apple_credentials() async throws {
        let core = PreviewLunchCore()
        _ = try await core.auth.signInWithEmail(email: "sam@example.test", password: "password8")
        let model = ProfileViewModel(core: core, tokens: CancelledTokens())
        #expect(await model.deleteAccount())
        #expect(core.auth.session == nil)
    }

    @Test func apple_account_deletion_still_requires_fresh_apple_credentials() async throws {
        let core = PreviewLunchCore()
        _ = try await core.auth.signInWithApple(idToken: "fictional", nonce: "fictional", fullName: nil)
        let model = ProfileViewModel(core: core, tokens: CancelledTokens())
        #expect(await model.deleteAccount() == false)
        #expect(core.auth.session != nil)
    }

    private struct CancelledTokens: SignInTokenProvider {
        let supportedProviders = SignInProvider.allCases
        func appleCredential() async throws -> AppleCredential { throw CancellationError() }
        func googleCredential() async throws -> GoogleCredential { throw CancellationError() }
    }
}
