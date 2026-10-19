import Foundation
import Sentry
import StoreKit
import Testing
@testable import LunchApp

@MainActor
struct AppDiagnosticsTests {
    @Test func expected_user_outcomes_do_not_become_issues() {
        let errors: [CoreError] = [
            .offline, .notSignedIn, .gate(.aiDailyLimit),
            .service(code: "PURCHASE_CANCELLED", message: "private"),
            .service(code: "PaymentPendingError", message: "private"),
            .service(code: "LOCATION_PERMISSION_DENIED", message: "private"),
            .service(code: "AI_CONSENT_REQUIRED", message: "private"),
            .service(code: "invalid_credentials", message: "private"),
            .service(code: "otp_expired", message: "private")
        ]
        for error in errors { #expect(AppDiagnostics.reportableCode(error) == nil) }
    }

    @Test func unexpected_failures_keep_only_controlled_codes() {
        #expect(AppDiagnostics.reportableCode(.service(code: "AI_UNAVAILABLE", message: "private prompt")) == "AI_UNAVAILABLE")
        #expect(AppDiagnostics.reportableCode(.service(code: "person@example.test", message: "token")) == "SERVICE_ERROR")
        #expect(AppDiagnostics.reportableCode(.unknown("secret")) == "UNEXPECTED")
    }

    @Test func privacy_options_disable_automatic_content_collection() {
        let options = Options()
        AppDiagnostics.configure(options)
        #expect(!options.sendDefaultPii)
        #expect(!options.enableMemoryIntrospection)
        #expect(!options.enableNetworkBreadcrumbs)
        #expect(!options.enableCaptureFailedRequests)
        #expect(!options.enableAutoBreadcrumbTracking)
        #expect(!options.enableAutoSessionTracking)
        #expect(!options.enableMetricKit)
        #expect(!options.attachScreenshot && !options.attachViewHierarchy)
        #expect(!options.enableLogs)
        #expect(options.tracesSampleRate == 0)
        #expect(options.sessionReplay.sessionSampleRate == 0)
        #expect(options.sessionReplay.onErrorSampleRate == 0)
        #expect(options.enableCrashHandler && options.enableAppHangTracking)
        #expect(options.beforeSend != nil)
    }

    @Test func scrubbing_removes_sensitive_fields_and_preserves_crash_frames() {
        let event = Event(level: .fatal)
        let user = User()
        user.email = "sentinel-person@example.test"
        user.userId = "sentinel-user"
        event.user = user
        event.request = SentryRequest()
        event.request?.url = "https://example.test/?token=sentinel-token"
        event.extra = ["prompt": "sentinel-prompt"]
        event.message = SentryMessage(formatted: "sentinel-message")
        event.tags = ["email": "sentinel-tag"]
        event.context = [
            "device": ["model": "iPhone", "name": "sentinel-device"],
            "os": ["version": "26.5"],
            "private": ["notes": "sentinel-notes"]
        ]
        let exception = Exception(value: "sentinel-exception", type: "EXC_BAD_ACCESS")
        let mechanism = Mechanism(type: "mach")
        mechanism.data = ["secret": "sentinel-mechanism"]
        exception.mechanism = mechanism
        let frame = Frame()
        frame.function = "exampleFunction()"
        frame.fileName = "/private/sentinel-path/App.swift"
        frame.package = "/Users/sentinel-developer/LunchApp.debug.dylib"
        frame.vars = ["password": "sentinel-password"]
        frame.contextLine = "sentinel-code"
        exception.stacktrace = SentryStacktrace(frames: [frame], registers: [:])
        event.exceptions = [exception]
        let image = DebugMeta()
        image.codeFile = "/Users/sentinel-developer/LunchApp.debug.dylib"
        image.debugID = "11111111-2222-3333-4444-555555555555"
        image.imageAddress = "0x100000000"
        event.debugMeta = [image]

        let clean = AppDiagnostics.sanitise(event)
        #expect(clean.user == nil && clean.request == nil && clean.extra == nil)
        #expect(clean.message == nil)
        #expect(clean.tags?.isEmpty == true)
        #expect(clean.context?["device"]?["model"] as? String == "iPhone")
        #expect(clean.exceptions?.first?.type == "EXC_BAD_ACCESS")
        #expect(clean.exceptions?.first?.stacktrace?.frames.first?.function == "exampleFunction()")
        #expect(frame.fileName == "App.swift")
        #expect(image.codeFile == "LunchApp.debug.dylib")
        #expect(image.debugID == "11111111-2222-3333-4444-555555555555")
        #expect(image.imageAddress == "0x100000000")
        #expect(!String(describing: clean.serialize()).contains("sentinel"))
    }

    @Test func controlled_failure_keeps_grouping_without_the_original_message() {
        let event = AppDiagnostics.makeEvent(code: "INTERNAL", component: "HomeViewModel.swift", operation: "refresh()")
        #expect(event.message?.formatted == "Lunch INTERNAL")
        #expect(event.tags?["operation"] == "refresh()")
        #expect(event.fingerprint == ["lunch.ios", "INTERNAL", "HomeViewModel.swift", "refresh()"])
        let unsafe = AppDiagnostics.makeEvent(code: "INTERNAL", component: "person@example.test", operation: "private text")
        #expect(unsafe.tags?["component"] == nil && unsafe.tags?["operation"] == nil)
    }

    @Test func previews_and_tests_are_quiet_and_explicit_smoke_test_is_supported() {
        #expect(!AppDiagnostics.shouldStart(isTesting: true, isPreview: false, isDisabled: false, smokeTest: false))
        #expect(!AppDiagnostics.shouldStart(isTesting: false, isPreview: true, isDisabled: false, smokeTest: false))
        #expect(AppDiagnostics.shouldStart(isTesting: false, isPreview: true, isDisabled: false, smokeTest: true))
        #expect(!AppDiagnostics.shouldStart(isTesting: false, isPreview: true, isDisabled: true, smokeTest: true))
        #expect(!AppDiagnostics.shouldStart(isTesting: true, isPreview: true, isDisabled: false, smokeTest: true))
    }

    @Test func handled_error_retry_loops_have_a_bounded_event_budget() {
        var limiter = DiagnosticRateLimiter()
        let first = limiter.admit(key: "one", now: 0)
        let duplicate = limiter.admit(key: "one", now: 119)
        let afterWindow = limiter.admit(key: "one", now: 120)
        #expect(first)
        #expect(!duplicate)
        #expect(afterWindow)
        for number in 0..<18 {
            let admitted = limiter.admit(key: "other-\(number)", now: 121)
            #expect(admitted)
        }
        let afterLimit = limiter.admit(key: "new", now: 300)
        #expect(!afterLimit)
    }

    @Test func environment_labels_separate_debug_testflight_and_store() {
        #expect(AppDiagnostics.environment(isDebug: true, storeEnvironment: nil) == "development")
        #expect(AppDiagnostics.environment(isDebug: false, storeEnvironment: .sandbox) == "testflight")
        #expect(AppDiagnostics.environment(isDebug: false, storeEnvironment: .production) == "production")
        #expect(AppDiagnostics.environment(isDebug: false, storeEnvironment: .xcode) == "development")
        #expect(AppDiagnostics.environment(isDebug: false, storeEnvironment: nil) == "release")
    }

    @Test func dsn_validation_rejects_private_credentials_and_non_sentry_destinations() {
        #expect(AppDiagnostics.validDSN("https://publickey@o1.ingest.us.sentry.io/123"))
        #expect(!AppDiagnostics.validDSN("https://publickey:secret@o1.ingest.us.sentry.io/123"))
        #expect(!AppDiagnostics.validDSN("https://publickey@example.test/123"))
        #expect(!AppDiagnostics.validDSN("https://publickey@o1.ingest.us.sentry.io/123?token=private"))
        #expect(!AppDiagnostics.validDSN("https://publickey@o1.ingest.us.sentry.io/"))
    }
}
