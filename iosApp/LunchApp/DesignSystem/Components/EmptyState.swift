//
//  EmptyState.swift
//  LunchApp
//
//  Empty, offline, and service-problem states. The variant picks the icon; the title, message,
//  and action come from the screen so each uses its own copy.
//

import SwiftUI

struct EmptyState: View {
    enum Variant {
        case nothingHere, offline, serviceProblem

        var icon: LunchIcon {
            switch self {
            case .nothingHere: return .restaurantMenu
            case .offline: return .wifiOff
            case .serviceProblem: return .cloudOff
            }
        }

        var tint: Color {
            switch self {
            case .nothingHere: return Tokens.Palette.primary
            case .offline: return Tokens.Palette.warning
            case .serviceProblem: return Tokens.Palette.danger
            }
        }
    }

    let variant: Variant
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: () -> Void = {}

    private static let discSize = Tokens.Size.touchTarget * 2
    private static let iconSize = Tokens.Size.iconDefault + Tokens.Spacing.sm

    /// The offline state with the global copy.
    static func offline(action: @escaping () -> Void) -> EmptyState {
        EmptyState(variant: .offline, title: Copy.Error.offlineTitle, message: Copy.Error.offlineBody, actionTitle: Copy.Action.retry, action: action)
    }

    /// The service-problem state with the global copy.
    static func serviceProblem(action: @escaping () -> Void) -> EmptyState {
        EmptyState(variant: .serviceProblem, title: Copy.Error.serviceTitle, message: Copy.Error.serviceBody, actionTitle: Copy.Action.retry, action: action)
    }

    var body: some View {
        VStack(spacing: Tokens.Spacing.md) {
            ZStack {
                Circle().fill(variant.tint.opacity(Tokens.Palette.primarySoftOpacity))
                IconView(icon: variant.icon, size: Self.iconSize).foregroundStyle(variant.tint)
            }
            .frame(width: Self.discSize, height: Self.discSize)
            VStack(spacing: Tokens.Spacing.sm) {
                Text(title).lunchText(.title).foregroundStyle(Tokens.Palette.text)
                Text(message).lunchText(.body).foregroundStyle(Tokens.Palette.textSecondary)
            }
            .multilineTextAlignment(.center)
            if let actionTitle {
                LunchButton(title: actionTitle, style: .secondary, fillsWidth: false, action: action)
                    .padding(.top, Tokens.Spacing.sm)
            }
        }
        .padding(Tokens.Spacing.lg)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

extension Tokens.Palette {
    /// The 10% tint level used by `primarySoft`, for tinting other palette colours the same way.
    static let primarySoftOpacity = 0.1
}

#Preview("Empty states") {
    LunchPreview {
        EmptyState(variant: .nothingHere, title: Copy.Home.emptyTitle, message: Copy.Home.emptyBody, actionTitle: Copy.Home.emptyDiscover)
        EmptyState.offline {}
        EmptyState.serviceProblem {}
    }
}
