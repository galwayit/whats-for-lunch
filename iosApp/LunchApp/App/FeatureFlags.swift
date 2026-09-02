//
//  FeatureFlags.swift
//  LunchApp
//
//  Build-time and launch-argument switches for work in progress.
//

import Foundation

enum FeatureFlags {
    /// Shows the four-tab shell instead of the component gallery. Pass `-rootTabs` as a launch argument.
    static let showsRootTabs = ProcessInfo.processInfo.arguments.contains("-rootTabs")

    /// Opens the component gallery on one section. Pass `-gallerySection <name>` where the name is a
    /// `GallerySection` raw value (for example `cards`, `social`, `paywall`); unknown names show all.
    static let gallerySectionName: String? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-gallerySection"), arguments.indices.contains(flag + 1) else { return nil }
        return arguments[flag + 1]
    }()
}
