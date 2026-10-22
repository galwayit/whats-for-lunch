import Foundation
import Sentry
import StoreKit

/// Error monitoring only. Keep content, identity and automatic network/UI capture out of telemetry.
@MainActor
enum AppDiagnostics {
    private static var started = false
    private static var limiter = DiagnosticRateLimiter()

    static func start(arguments: LaunchArguments = .current, bundle: Bundle = .main) {
        guard !started else { return }
        let processEnvironment = ProcessInfo.processInfo.environment
        #if DEBUG
        let smokeTest = arguments.flag("sentrySmokeTest") == true
        let isDebug = true
        #else
        let smokeTest = false
        let isDebug = false
        #endif
        let isTesting = ["XCTestConfigurationFilePath", "XCTestBundlePath", "XCTestSessionIdentifier"]
            .contains { processEnvironment[$0] != nil } || NSClassFromString("XCTestCase") != nil
        guard shouldStart(
            isTesting: isTesting, isPreview: arguments.usesPreviewCore || arguments.showsGallery,
            isDisabled: arguments.flag("disableDiagnostics") == true || processEnvironment["LUNCH_DIAGNOSTICS_DISABLED"] == "1",
            smokeTest: smokeTest
        ), let url = bundle.url(forResource: "Sentry", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let config = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           config["enabled"] as? Bool == true,
           let dsn = config["dsn"] as? String, validDSN(dsn)
        else { return }

        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let options = Options()
        configure(options)
        options.dsn = dsn
        options.releaseName = "\(bundle.bundleIdentifier ?? "au.iapp.lunch")@\(version)+\(build)"
        options.dist = build
        options.environment = environment(isDebug: isDebug, storeEnvironment: nil)
        SentrySDK.start(options: options)
        started = SentrySDK.isEnabled

        if started, !isDebug {
            // StoreKit 2 verifies the distribution environment without reading a deprecated receipt URL.
            // Early launch failures keep the neutral "release" label until verification succeeds.
            Task {
                guard let result = try? await AppTransaction.shared,
                      case .verified(let transaction) = result else { return }
                let name = environment(isDebug: false, storeEnvironment: transaction.environment)
                SentrySDK.configureScope { $0.setEnvironment(name) }
            }
        }

        #if DEBUG
        if smokeTest, started {
            // Explicit launch-only diagnostic; never crashes the user's app or sends account data.
            let event = makeEvent(code: "SENTRY_SETUP_TEST", component: "AppDiagnostics.swift", operation: "smokeTest")
            let id = SentrySDK.capture(event: event)
            print("Lunch Sentry synthetic test event: \(id.sentryIdString)")
        }
        #endif
    }

    nonisolated static func shouldStart(isTesting: Bool, isPreview: Bool, isDisabled: Bool, smokeTest: Bool) -> Bool {
        !isDisabled && !isTesting && (!isPreview || smokeTest)
    }

    nonisolated static func validDSN(_ value: String) -> Bool {
        guard let url = URLComponents(string: value), url.scheme == "https",
              let host = url.host, host.hasSuffix(".sentry.io"),
              let key = url.user, !key.isEmpty, url.password == nil,
              url.query == nil, url.fragment == nil else { return false }
        let project = url.path.dropFirst()
        return !project.isEmpty && project.allSatisfy { $0.isASCII && $0.isNumber }
    }

    nonisolated static func environment(isDebug: Bool, storeEnvironment: AppStore.Environment?) -> String {
        if isDebug { return "development" }
        switch storeEnvironment {
        case .sandbox: return "testflight"
        case .production: return "production"
        case .xcode: return "development"
        default: return "release"
        }
    }

    static func configure(_ options: Options) {
        options.debug = false
        options.sendDefaultPii = false
        options.enableMemoryIntrospection = false
        options.enableAutoBreadcrumbTracking = false
        options.enableNetworkBreadcrumbs = false
        options.enableCaptureFailedRequests = false
        options.enableNetworkTracking = false
        options.enableFileIOTracing = false
        options.enableDataSwizzling = false
        options.maxBreadcrumbs = 0
        options.beforeBreadcrumb = { _ in nil }
        options.enableAutoSessionTracking = false
        options.enableMetricKit = false
        options.enableMetricKitRawPayload = false
        options.attachScreenshot = false
        options.attachViewHierarchy = false
        options.enableLogs = false
        options.beforeSendLog = { _ in nil }
        options.beforeSendMetric = { _ in nil }
        options.tracesSampleRate = 0
        options.sessionReplay.sessionSampleRate = 0
        options.sessionReplay.onErrorSampleRate = 0
        options.enableCrashHandler = true
        options.enableAppHangTracking = true
        options.attachStacktrace = true
        options.maxCacheItems = 20
        options.beforeSend = { sanitise($0) }
    }

    static func record(_ error: CoreError, component: StaticString = #fileID, operation: StaticString = #function) {
        guard started, let code = reportableCode(error) else { return }
        let file = String(describing: component).split(separator: "/").last.map(String.init) ?? "LunchApp"
        let function = String(describing: operation)
        let key = "\(code):\(file):\(function)"
        // Wall-clock time, not systemUptime: the latter is a required-reason API (system boot time)
        // and the limiter only needs coarse windows.
        guard limiter.admit(key: key, now: Date().timeIntervalSinceReferenceDate) else { return }
        SentrySDK.capture(event: makeEvent(code: code, component: file, operation: function))
    }

    nonisolated static func reportableCode(_ error: CoreError) -> String? {
        switch error {
        case .offline, .gate, .notSignedIn: return nil
        case .unknown: return "UNEXPECTED"
        case .service(let code, _):
            let normalised = code.uppercased()
            let expected: Set<String> = [
                "PURCHASE_CANCELLED", "PURCHASECANCELLEDERROR", "PAYMENTPENDINGERROR",
                "OPERATIONALREADYINPROGRESSERROR", "AI_DAILY_LIMIT", "HOST_REQUIRES_PRO",
                "SIGN_IN_REQUIRED", "AI_CONSENT_REQUIRED", "UNAUTHORIZED", "FORBIDDEN",
                "BAD_REQUEST", "NOT_FOUND", "NO_CANDIDATES", "NO_USER", "NO_LOCATION",
                "LOCATION_PERMISSION_DENIED", "CALENDAR_DENIED", "NOTIFICATION_DENIED",
                "REMINDER_IN_PAST", "PURCHASES_DISABLED", "PASSWORD_RESET_RETRY",
                "INVALID_CREDENTIALS", "INVALID_LOGIN_CREDENTIALS", "EMAIL_NOT_CONFIRMED",
                "USER_ALREADY_EXISTS", "WEAK_PASSWORD", "OTP_EXPIRED",
                "OVER_EMAIL_SEND_RATE_LIMIT", "OVER_REQUEST_RATE_LIMIT", "SIGNUP_DISABLED"
            ]
            if expected.contains(normalised) { return nil }
            return diagnosticCodes.contains(normalised) ? normalised : "SERVICE_ERROR"
        }
    }

    nonisolated static let diagnosticCodes: Set<String> = [
        "UNEXPECTED", "SERVICE_ERROR", "INTERNAL", "UPSTREAM_ERROR", "AI_UNAVAILABLE",
        "RATE_LIMITED", "BAD_RESPONSE", "CONFIG_MISSING", "CORE_NOT_CONFIGURED",
        "DB_OPEN_FAILED", "DB_TOO_NEW", "GROUP_READ_FAILED", "NO_SESSION",
        "NO_PRODUCTS", "PACKAGE_NOT_FOUND", "SUBSCRIPTION_SYNC_FAILED",
        "STOREPROBLEMERROR", "CONFIGURATIONERROR", "INVALIDCREDENTIALSERROR",
        "SENTRY_SETUP_TEST"
    ]

    nonisolated static func makeEvent(code: String, component: String, operation: String) -> Event {
        let event = Event(level: .error)
        event.tags = ["error_code": code, "component": component, "operation": operation]
        return sanitise(event)
    }

    /// Runs for automatic crashes as well as handled errors, on whichever thread the SDK uses.
    nonisolated static func sanitise(_ event: Event) -> Event {
        event.user = nil
        event.request = nil
        event.extra = nil
        event.breadcrumbs = []
        event.serverName = nil
        event.transaction = nil
        event.error = nil
        event.logger = "lunch.ios"

        let code = event.tags?["error_code"].flatMap { diagnosticCodes.contains($0) ? $0 : nil }
        var tags: [String: String] = [:]
        if let code {
            tags["error_code"] = code
            for key in ["component", "operation"] {
                if let value = event.tags?[key], value.count <= 160,
                   value.range(of: "^[A-Za-z0-9_().:]+$", options: .regularExpression) != nil {
                    tags[key] = value
                }
            }
            event.message = SentryMessage(formatted: "Lunch \(code)")
            event.fingerprint = ["lunch.ios", code, tags["component"] ?? "", tags["operation"] ?? ""]
        } else {
            // Exception text can contain tokens, URLs or user-supplied strings.
            event.message = nil
            event.fingerprint = nil
        }
        event.tags = tags

        let allowed: [String: Set<String>] = [
            "app": ["app_identifier", "app_name", "app_version", "app_build", "in_foreground"],
            "os": ["name", "version", "build", "kernel_version", "rooted"],
            "device": ["family", "model", "model_id", "arch", "simulator", "memory_size", "free_memory", "orientation"]
        ]
        var contexts: [String: [String: Any]] = [:]
        for (name, keys) in allowed {
            if let values = event.context?[name] { contexts[name] = values.filter { keys.contains($0.key) } }
        }
        event.context = contexts
        for image in event.debugMeta ?? [] {
            // A simulator image path can include the developer's home-directory name.
            // UUID and load addresses, retained below, identify the matching symbols.
            if let path = image.codeFile { image.codeFile = (path as NSString).lastPathComponent }
        }
        for exception in event.exceptions ?? [] {
            exception.value = nil
            if exception.type?.isEmpty != false { exception.type = "NativeError" }
            exception.mechanism?.data = nil
            exception.mechanism?.desc = nil
            exception.mechanism?.helpLink = nil
            scrub(exception.stacktrace)
        }
        for thread in event.threads ?? [] {
            thread.name = nil
            scrub(thread.stacktrace)
        }
        scrub(event.stacktrace)
        return event
    }

    nonisolated private static func scrub(_ stacktrace: SentryStacktrace?) {
        guard let stacktrace else { return }
        for frame in stacktrace.frames {
            frame.vars = nil
            frame.contextLine = nil
            frame.preContext = nil
            frame.postContext = nil
            if let name = frame.fileName { frame.fileName = (name as NSString).lastPathComponent }
            if let path = frame.package { frame.package = (path as NSString).lastPathComponent }
        }
    }
}

/// Bound handled-error traffic during retry loops; crash reporting is not subject to this limiter.
nonisolated struct DiagnosticRateLimiter {
    private var lastSent: [String: TimeInterval] = [:]
    private var sent = 0
    mutating func admit(key: String, now: TimeInterval) -> Bool {
        guard sent < 20 else { return false }
        if let previous = lastSent[key], now - previous < 120 { return false }
        lastSent[key] = now
        sent += 1
        return true
    }
}
