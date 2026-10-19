import Foundation
import Testing

private nonisolated final class TestBundleMarker: NSObject {}

nonisolated enum TestFixtures {
    /// The Xcode test target copies the shared JSON files into its bundle. A physical
    /// device cannot read the Mac source paths embedded by `#filePath`.
    static func data(named name: String) throws -> Data {
        let url = try #require(
            Bundle(for: TestBundleMarker.self).url(forResource: name, withExtension: "json"),
            "Missing bundled test fixture: \(name).json"
        )
        return try Data(contentsOf: url)
    }
}
