//
//  FeatureFlags.swift
//  LunchApp
//
//  Build-time switches. Launch arguments live in `LaunchArguments`.
//

import Foundation

enum FeatureFlags {
    /// The real app is the default entry; `-gallery` opens the component gallery instead.
    static let showRealApp = true

    /// Use the in-memory core even without `-previewCore`. Off: without the Kotlin framework
    /// linked, a plain launch shows the not-linked screen so the gap is visible.
    /// Demo builds (`SWIFT_ACTIVE_COMPILATION_CONDITIONS` containing `DEMO`) turn it on so the
    /// app is explorable from the home screen of a device without launch arguments.
    #if DEMO
    static let previewCoreByDefault = true
    #else
    static let previewCoreByDefault = false
    #endif

    static var showsGallery: Bool { !showRealApp || LaunchArguments.current.showsGallery }

    /// Gallery section from `-gallerySection <name>` (a `GallerySection` raw value); unknown names show all.
    static var gallerySectionName: String? { LaunchArguments.current.gallerySection }
}
