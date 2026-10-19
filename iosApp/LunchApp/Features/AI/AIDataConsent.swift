import Foundation

struct AIDataConsent {
    static let defaultsKey = "aiDataSharingConsentVersion"
    static var defaultStore: UserDefaults {
        store(preview: LaunchArguments.current.usesPreviewCore || FeatureFlags.previewCoreByDefault)
    }
    private let defaults: UserDefaults
    init(defaults: UserDefaults? = nil,
         preview: Bool = LaunchArguments.current.usesPreviewCore || FeatureFlags.previewCoreByDefault) {
        // Preview UI tests also run on personal devices. Their fictional provider agreement
        // must not replace consent recorded for the configured production providers.
        self.defaults = defaults ?? Self.store(preview: preview)
    }
    private static func store(preview: Bool) -> UserDefaults {
        preview
            ? UserDefaults(suiteName: "au.iapp.lunch.preview.aiConsent")!
            : .standard
    }
    var version: String? { defaults.string(forKey: Self.defaultsKey) }
    var isGranted: Bool { !(version ?? "").isEmpty }
    func isGranted(for version: String) -> Bool { !version.isEmpty && self.version == version }
    func revoke() { defaults.removeObject(forKey: Self.defaultsKey) }
    func grant(version: String) { defaults.set(version, forKey: Self.defaultsKey) }
}
