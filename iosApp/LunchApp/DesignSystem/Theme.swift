//
//  Theme.swift
//  LunchApp
//
//  Typography helpers on top of the generated Tokens: the Plus Jakarta Sans font with a
//  system-rounded fallback, text role modifiers, the text-scale clamp, and the elevation
//  values from design/tokens.json that the generator does not emit yet.
//

import SwiftUI
import UIKit

// MARK: - Typography tokens

extension Tokens {
    /// `Tokens.Type` is a reserved member name in Swift; the generated enum is declared with
    /// backticks and used through this alias everywhere else.
    typealias Typography = `Type`
}

// MARK: - Font

enum LunchFont {
    /// PostScript family prefix of the bundled Plus Jakarta Sans files (see Resources/Fonts/README.md).
    static let postScriptPrefix = "PlusJakartaSans"

    /// True when the custom font files are bundled and registered through `UIAppFonts`.
    /// Evaluated once; the stand-in is the system font with the rounded design.
    static let isCustomFontAvailable: Bool = UIFont(name: postScriptName(for: .regular), size: UIFont.labelFontSize) != nil

    /// The font for a text role at a concrete point size (already scaled for Dynamic Type).
    static func font(size: CGFloat, weight: Font.Weight) -> Font {
        if isCustomFontAvailable {
            return .custom(postScriptName(for: weight), fixedSize: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    static func font(_ role: TextRole) -> Font {
        font(size: role.size, weight: role.fontWeight)
    }

    /// The UIKit font matching `font(size:weight:)`, used for line-height maths.
    static func uiFont(size: CGFloat, weight: Font.Weight) -> UIFont {
        if isCustomFontAvailable, let custom = UIFont(name: postScriptName(for: weight), size: size) {
            return custom
        }
        let system = UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
        guard let rounded = system.fontDescriptor.withDesign(.rounded) else { return system }
        return UIFont(descriptor: rounded, size: size)
    }

    /// "PlusJakartaSans-Bold" etc. Weight 800 in the tokens maps to ExtraBold.
    static func postScriptName(for weight: Font.Weight) -> String {
        "\(postScriptPrefix)-\(styleName(for: weight))"
    }

    private static func styleName(for weight: Font.Weight) -> String {
        switch weight {
        case .heavy, .black: return "ExtraBold"
        case .bold: return "Bold"
        case .semibold: return "SemiBold"
        case .medium: return "Medium"
        default: return "Regular"
        }
    }
}

private extension Font.Weight {
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .heavy, .black: return .heavy
        case .bold: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        default: return .regular
        }
    }
}

// MARK: - Text roles

/// The eight text roles from tokens.json, applied with `.lunchText(.body)`.
enum LunchTextRole: CaseIterable {
    case display, title, heading, body, bodySmall, caption, label, button

    var token: TextRole {
        switch self {
        case .display: return Tokens.Typography.display
        case .title: return Tokens.Typography.title
        case .heading: return Tokens.Typography.heading
        case .body: return Tokens.Typography.body
        case .bodySmall: return Tokens.Typography.bodySmall
        case .caption: return Tokens.Typography.caption
        case .label: return Tokens.Typography.label
        case .button: return Tokens.Typography.button
        }
    }

    /// The UIKit text style each role scales with under Dynamic Type.
    var relativeTextStyle: Font.TextStyle {
        switch self {
        case .display: return .largeTitle
        case .title: return .title2
        case .heading: return .headline
        case .body: return .body
        case .bodySmall: return .subheadline
        case .caption: return .footnote
        case .label: return .caption2
        case .button: return .body
        }
    }
}

/// Applies font, line height, tracking, and uppercase for a text role, scaled with Dynamic Type.
struct LunchTextModifier: ViewModifier {
    let role: LunchTextRole
    @ScaledMetric private var scaledSize: CGFloat
    @ScaledMetric private var scaledLineHeight: CGFloat

    init(role: LunchTextRole) {
        self.role = role
        _scaledSize = ScaledMetric(wrappedValue: role.token.size, relativeTo: role.relativeTextStyle)
        _scaledLineHeight = ScaledMetric(wrappedValue: role.token.lineHeight, relativeTo: role.relativeTextStyle)
    }

    func body(content: Content) -> some View {
        let token = role.token
        let natural = LunchFont.uiFont(size: scaledSize, weight: token.fontWeight).lineHeight
        content
            .font(LunchFont.font(size: scaledSize, weight: token.fontWeight))
            .tracking(token.tracking)
            .lineSpacing(max(0, scaledLineHeight - natural))
            .textCase(token.uppercase ? .uppercase : nil)
    }
}

extension View {
    func lunchText(_ role: LunchTextRole) -> some View {
        modifier(LunchTextModifier(role: role))
    }
}

// MARK: - Text scale clamp

/// Maps `Tokens.Typography.textScaleMin/Max` (0.8 to 2.0) onto Dynamic Type sizes so the layout never
/// renders outside the tested range. Scale factors come from the system's own body metrics.
enum LunchTextScale {
    static let allowedRange: ClosedRange<DynamicTypeSize> = {
        let categories: [UIContentSizeCategory] = [
            .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge,
        ]
        let base = bodyPointSize(for: .large)
        let scaled = categories.map { (size: DynamicTypeSize($0) ?? .large, factor: bodyPointSize(for: $0) / base) }
        let lower = scaled.first { $0.factor >= Tokens.Typography.textScaleMin }?.size ?? .large
        let upper = scaled.last { $0.factor <= Tokens.Typography.textScaleMax }?.size ?? .large
        return min(lower, upper)...max(lower, upper)
    }()

    private static func bodyPointSize(for category: UIContentSizeCategory) -> CGFloat {
        UIFont.preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(preferredContentSizeCategory: category)).pointSize
    }
}

extension View {
    /// Clamps Dynamic Type to the range allowed by the tokens.
    func lunchTextScaleClamped() -> some View {
        dynamicTypeSize(LunchTextScale.allowedRange)
    }
}

// MARK: - Elevation

/// Shadow values from tokens.json `elevation`; mirrored here until generate_tokens.py emits them.
enum LunchElevation {
    struct Shadow {
        let y: CGFloat
        let blur: CGFloat
        let alpha: Double
    }

    static let card = Shadow(y: 2, blur: 8, alpha: 0.04)
    static let hero = Shadow(y: 10, blur: 25, alpha: 0.40)
    static let sheet = Shadow(y: -4, blur: 24, alpha: 0.12)
}

extension View {
    /// Applies an elevation shadow using a palette colour at the token alpha.
    func lunchShadow(_ shadow: LunchElevation.Shadow, color: Color = Tokens.Palette.text) -> some View {
        self.shadow(color: color.opacity(shadow.alpha), radius: shadow.blur / 2, x: 0, y: shadow.y)
    }
}

// MARK: - Hairline

extension View {
    /// The standard 1pt hairline border on a rounded container.
    func lunchHairline(radius: CGFloat, color: Color = Tokens.Palette.hairline, width: CGFloat = 1) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(color, lineWidth: width))
    }
}

#Preview("Text roles") {
    LunchPreview(alignment: .leading) {
        ForEach(LunchTextRole.allCases, id: \.self) { role in
            Text(String(describing: role)).lunchText(role).foregroundStyle(Tokens.Palette.text)
        }
    }
}
