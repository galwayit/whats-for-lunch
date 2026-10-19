// GENERATED FROM design/tokens.json BY design/generate_tokens.py. DO NOT EDIT BY HAND.
import SwiftUI

public enum Tokens {
    public enum Palette {
        /// Screen background. Warm cream; espresso in dark, never green-black.
        public static let ground = Color(light: (1.0000, 0.9647, 0.9255, 1.0000), dark: (0.1020, 0.0745, 0.0627, 1.0000))
        /// Cards, inputs, sheets.
        public static let surface = Color(light: (1.0000, 1.0000, 1.0000, 1.0000), dark: (0.1490, 0.1098, 0.0902, 1.0000))
        /// Nested cards, tab bar, tags.
        public static let surfaceRaised = Color(light: (1.0000, 0.9412, 0.8784, 1.0000), dark: (0.2000, 0.1490, 0.1216, 1.0000))
        /// Body text.
        public static let text = Color(light: (0.2275, 0.1333, 0.0941, 1.0000), dark: (0.9608, 0.9137, 0.8667, 1.0000))
        /// Captions, hints, unselected tabs.
        public static let textSecondary = Color(light: (0.4784, 0.3529, 0.2824, 1.0000), dark: (0.7686, 0.6824, 0.6118, 1.0000))
        /// Text on primary fills.
        public static let textOnPrimary = Color(light: (1.0000, 1.0000, 1.0000, 1.0000), dark: (0.2275, 0.0706, 0.0235, 1.0000))
        /// Text on the action fill. Large bold labels only in light (3.7:1).
        public static let textOnAction = Color(light: (1.0000, 1.0000, 1.0000, 1.0000), dark: (0.1647, 0.0549, 0.0118, 1.0000))
        /// Paprika. Structure, selected states, primary buttons.
        public static let primary = Color(light: (0.7765, 0.2392, 0.0902, 1.0000), dark: (1.0000, 0.5412, 0.3569, 1.0000))
        /// Tinted fills (10% / 16%).
        public static let primarySoft = Color(light: (0.7765, 0.2392, 0.0902, 0.1020), dark: (1.0000, 0.5412, 0.3569, 0.1608))
        /// The Hungry button and the paywall button only.
        public static let action = Color(light: (0.9255, 0.3059, 0.0784, 1.0000), dark: (1.0000, 0.4196, 0.2078, 1.0000))
        /// Rings and glows around the action.
        public static let actionSoft = Color(light: (0.9255, 0.3059, 0.0784, 0.1216), dark: (1.0000, 0.4196, 0.2078, 0.1608))
        /// Saffron. Rating stars; decorative, always next to the rating number.
        public static let accent = Color(light: (0.8510, 0.5412, 0.0000, 1.0000), dark: (1.0000, 0.7569, 0.3294, 1.0000))
        /// Positive badges and a healthy budget. The only green in the palette.
        public static let success = Color(light: (0.1804, 0.4902, 0.3098, 1.0000), dark: (0.4980, 0.8196, 0.6078, 1.0000))
        /// Caution badges.
        public static let warning = Color(light: (0.6588, 0.3529, 0.0000, 1.0000), dark: (1.0000, 0.7216, 0.4078, 1.0000))
        /// Errors, destructive actions. Berry, so it never reads as the paprika brand colour.
        public static let danger = Color(light: (0.6588, 0.0706, 0.2431, 1.0000), dark: (1.0000, 0.5608, 0.6588, 1.0000))
        /// Neutral information badges.
        public static let info = Color(light: (0.1216, 0.3725, 0.5451, 1.0000), dark: (0.5490, 0.7843, 0.9490, 1.0000))
        /// Card borders, dividers (14% / 12%).
        public static let hairline = Color(light: (0.2275, 0.1333, 0.0941, 0.1412), dark: (1.0000, 1.0000, 1.0000, 0.1216))
        /// Focused borders, strong dividers.
        public static let hairlineStrong = Color(light: (0.2275, 0.1333, 0.0941, 0.2784), dark: (1.0000, 1.0000, 1.0000, 0.2392))
        /// Behind sheets and dialogs.
        public static let scrim = Color(light: (0.1647, 0.0941, 0.0627, 0.6000), dark: (0.0000, 0.0000, 0.0000, 0.6510))
    }

    public enum `Type` {
        public static let family = "Bricolage Grotesque"
        public static let textScaleMin: CGFloat = 0.8
        public static let textScaleMax: CGFloat = 2.0
        public static let display = TextRole(size: 32, weight: 800, lineHeight: 38, tracking: -0.5, uppercase: false, display: true)
        public static let title = TextRole(size: 22, weight: 700, lineHeight: 28, tracking: -0.2, uppercase: false, display: true)
        public static let heading = TextRole(size: 17, weight: 700, lineHeight: 22, tracking: 0, uppercase: false, display: true)
        public static let body = TextRole(size: 16, weight: 500, lineHeight: 24, tracking: 0.15, uppercase: false, display: false)
        public static let bodySmall = TextRole(size: 14, weight: 400, lineHeight: 20, tracking: 0.25, uppercase: false, display: false)
        public static let caption = TextRole(size: 13, weight: 500, lineHeight: 18, tracking: 0.2, uppercase: false, display: false)
        public static let label = TextRole(size: 11, weight: 700, lineHeight: 16, tracking: 1.2, uppercase: true, display: false)
        public static let button = TextRole(size: 16, weight: 700, lineHeight: 20, tracking: 0.1, uppercase: false, display: false)
    }

    public enum Spacing {
        public static let unit: CGFloat = 4
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let page: CGFloat = 16
        public static let pageWide: CGFloat = 24
    }

    public enum Radius {
        public static let container: CGFloat = 16
        public static let chip: CGFloat = 9999
        public static let toast: CGFloat = 12
        public static let sheet: CGFloat = 24
        public static let hero: CGFloat = 9999
        public static let input: CGFloat = 16
        public static let button: CGFloat = 16
    }

    public enum Size {
        public static let touchTarget: CGFloat = 44
        public static let buttonHeight: CGFloat = 52
        public static let buttonMinWidth: CGFloat = 48
        public static let heroButton: CGFloat = 224
        public static let heroRingInner: CGFloat = 256
        public static let heroRingOuter: CGFloat = 288
        public static let heroBorder: CGFloat = 8
        public static let tabIcon: CGFloat = 24
        public static let iconDefault: CGFloat = 24
        public static let capacityRingStroke: CGFloat = 12
    }

    public enum Motion {
        public static let stateDurationSeconds: Double = 0.2
        public static let pressDurationSeconds: Double = 0.1
        public static let pressScale: Double = 0.95
        public static let heroPulseDurationSeconds: Double = 2.4
        public static let heroPulseScaleOuter: Double = 1.04
        public static let heroPulseScaleInner: Double = 1.025
        public static let heroPulseRespectsReducedMotion: Bool = true
        public static let sheetDurationSeconds: Double = 0.3
        public static let fadeInDurationSeconds: Double = 0.3
        public static let achievementToastAutoDismissSeconds: Double = 4.0
    }
}

public struct TextRole {
    public let size: CGFloat; public let weight: Int; public let lineHeight: CGFloat; public let tracking: CGFloat; public let uppercase: Bool
    /// True for roles set in the bundled display family; false for the system text face.
    public let display: Bool
    public var fontWeight: Font.Weight {
        switch weight { case 800: return .heavy; case 700: return .bold; case 600: return .semibold; case 500: return .medium; default: return .regular }
    }
}

public extension Color {
    /// sRGB components, in the order red, green, blue, alpha.
    typealias RGBA = (Double, Double, Double, Double)

    /// Resolves to the light or dark value from the active trait collection.
    ///
    /// UIKit resolves a dynamic colour on whichever thread is drawing, and for SwiftUI
    /// that is often its async render thread rather than the main one. The target builds
    /// with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so both the initialiser and the
    /// provider closure have to opt out explicitly: otherwise the closure is treated as
    /// main-actor work and trips a dispatch queue assertion the moment it is resolved off
    /// the main thread. For the same reason the components become `UIColor`s up front,
    /// rather than calling the main-actor-isolated `UIColor(_: Color)` inside the closure.
    nonisolated init(light: RGBA, dark: RGBA) {
        let lightColor = UIColor(red: light.0, green: light.1, blue: light.2, alpha: light.3)
        let darkColor = UIColor(red: dark.0, green: dark.1, blue: dark.2, alpha: dark.3)
        self.init(uiColor: UIColor { @Sendable trait in
            trait.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }
}
