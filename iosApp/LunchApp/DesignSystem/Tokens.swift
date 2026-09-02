// GENERATED FROM design/tokens.json BY design/generate_tokens.py. DO NOT EDIT BY HAND.
import SwiftUI

public enum Tokens {
    public enum Palette {
        /// Screen background. One value; Discover's #FDFAF3 is retired.
        public static let ground = Color(light: Color(red: 1.0000, green: 0.9725, blue: 0.9059, opacity: 1.0000), dark: Color(red: 0.0784, green: 0.1176, blue: 0.0863, opacity: 1.0000))
        /// Cards, inputs, sheets.
        public static let surface = Color(light: Color(red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0000), dark: Color(red: 0.1020, green: 0.1686, blue: 0.1176, opacity: 1.0000))
        /// Nested cards, tab bar.
        public static let surfaceRaised = Color(light: Color(red: 0.9922, green: 0.9804, blue: 0.9529, opacity: 1.0000), dark: Color(red: 0.1333, green: 0.2196, blue: 0.1647, opacity: 1.0000))
        /// Body text.
        public static let text = Color(light: Color(red: 0.2902, green: 0.2078, blue: 0.1529, opacity: 1.0000), dark: Color(red: 0.9176, green: 0.8941, blue: 0.8471, opacity: 1.0000))
        /// Captions, hints, unselected tabs.
        public static let textSecondary = Color(light: Color(red: 0.5451, green: 0.4353, blue: 0.2784, opacity: 1.0000), dark: Color(red: 0.7098, green: 0.6588, blue: 0.5608, opacity: 1.0000))
        /// Text on primary fills.
        public static let textOnPrimary = Color(light: Color(red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0000), dark: Color(red: 0.0549, green: 0.1020, blue: 0.0627, opacity: 1.0000))
        /// Text on the action fill.
        public static let textOnAction = Color(light: Color(red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0000), dark: Color(red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 1.0000))
        /// Structure, selected states, primary buttons.
        public static let primary = Color(light: Color(red: 0.1843, green: 0.4980, blue: 0.2471, opacity: 1.0000), dark: Color(red: 0.3725, green: 0.7569, blue: 0.4471, opacity: 1.0000))
        /// Tinted fills (10% / 14%).
        public static let primarySoft = Color(light: Color(red: 0.1843, green: 0.4980, blue: 0.2471, opacity: 0.1020), dark: Color(red: 0.3725, green: 0.7569, blue: 0.4471, opacity: 0.1412))
        /// The Hungry button and the paywall button only.
        public static let action = Color(light: Color(red: 1.0000, green: 0.4196, blue: 0.2078, opacity: 1.0000), dark: Color(red: 1.0000, green: 0.5412, blue: 0.3608, opacity: 1.0000))
        /// Rings and glows around the action.
        public static let actionSoft = Color(light: Color(red: 1.0000, green: 0.4196, blue: 0.2078, opacity: 0.1216), dark: Color(red: 1.0000, green: 0.5412, blue: 0.3608, opacity: 0.1608))
        /// Positive badges.
        public static let success = Color(light: Color(red: 0.1804, green: 0.4902, blue: 0.1961, opacity: 1.0000), dark: Color(red: 0.4353, green: 0.8118, blue: 0.5020, opacity: 1.0000))
        /// Caution badges.
        public static let warning = Color(light: Color(red: 0.7216, green: 0.3255, blue: 0.0000, opacity: 1.0000), dark: Color(red: 1.0000, green: 0.6902, blue: 0.4039, opacity: 1.0000))
        /// Errors, destructive actions.
        public static let danger = Color(light: Color(red: 0.7176, green: 0.1098, blue: 0.1098, opacity: 1.0000), dark: Color(red: 1.0000, green: 0.5412, blue: 0.5020, opacity: 1.0000))
        /// Neutral information badges.
        public static let info = Color(light: Color(red: 0.1059, green: 0.3686, blue: 0.5412, opacity: 1.0000), dark: Color(red: 0.4863, green: 0.7686, blue: 0.9608, opacity: 1.0000))
        /// Card borders, dividers (14% / 10%).
        public static let hairline = Color(light: Color(red: 0.4196, green: 0.3059, blue: 0.2392, opacity: 0.1412), dark: Color(red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.1020))
        /// Focused borders, strong dividers.
        public static let hairlineStrong = Color(light: Color(red: 0.4196, green: 0.3059, blue: 0.2392, opacity: 0.2784), dark: Color(red: 1.0000, green: 1.0000, blue: 1.0000, opacity: 0.2196))
        /// Behind sheets and dialogs.
        public static let scrim = Color(light: Color(red: 0.2431, green: 0.1686, blue: 0.1255, opacity: 0.6000), dark: Color(red: 0.0000, green: 0.0000, blue: 0.0000, opacity: 0.6510))
    }

    public enum Type {
        public static let family = "Plus Jakarta Sans"
        public static let textScaleMin: CGFloat = 0.8
        public static let textScaleMax: CGFloat = 2.0
        public static let display = TextRole(size: 32, weight: 800, lineHeight: 38, tracking: -0.5, uppercase: false)
        public static let title = TextRole(size: 22, weight: 700, lineHeight: 28, tracking: 0, uppercase: false)
        public static let heading = TextRole(size: 17, weight: 700, lineHeight: 22, tracking: 0, uppercase: false)
        public static let body = TextRole(size: 16, weight: 500, lineHeight: 24, tracking: 0.15, uppercase: false)
        public static let bodySmall = TextRole(size: 14, weight: 400, lineHeight: 20, tracking: 0.25, uppercase: false)
        public static let caption = TextRole(size: 13, weight: 500, lineHeight: 18, tracking: 0.2, uppercase: false)
        public static let label = TextRole(size: 11, weight: 700, lineHeight: 16, tracking: 1.2, uppercase: true)
        public static let button = TextRole(size: 16, weight: 700, lineHeight: 20, tracking: 0.1, uppercase: false)
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
    public var fontWeight: Font.Weight {
        switch weight { case 800: return .heavy; case 700: return .bold; case 600: return .semibold; case 500: return .medium; default: return .regular }
    }
}

public extension Color {
    /// Resolves to the light or dark value from the active trait collection.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
}
