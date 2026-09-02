//
//  AILoading.swift
//  LunchApp
//
//  Loading state for AI searches: a sparkle that breathes inside a soft disc, three pulsing
//  dots, and the searching copy. Static under Reduce Motion.
//

import SwiftUI

struct AILoading: View {
    var title = Copy.Home.searchingTitle
    var subtitle: String? = Copy.Home.searchingBody

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = false

    private static let discSize = Tokens.Size.touchTarget * 2
    private static let dotSize = Tokens.Spacing.sm + Tokens.Spacing.xs
    private static let dotCount = 3
    private static let dotStagger = 0.15
    private static let dotRestScale = 0.6
    private static let dotRestOpacity = 0.4
    private static let breatheScale = 1.1

    var body: some View {
        VStack(spacing: Tokens.Spacing.md) {
            ZStack {
                Circle().fill(Tokens.Palette.primarySoft)
                IconView(icon: .autoAwesome, size: Tokens.Size.iconDefault + Tokens.Spacing.sm)
                    .foregroundStyle(Tokens.Palette.primary)
                    .scaleEffect(phase ? Self.breatheScale : 1)
            }
            .frame(width: Self.discSize, height: Self.discSize)
            HStack(spacing: Tokens.Spacing.sm) {
                ForEach(0..<Self.dotCount, id: \.self) { index in
                    Circle()
                        .fill(Tokens.Palette.primary)
                        .frame(width: Self.dotSize, height: Self.dotSize)
                        .scaleEffect(phase ? 1 : Self.dotRestScale)
                        .opacity(phase ? 1 : Self.dotRestOpacity)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: Tokens.Motion.fadeInDurationSeconds * 2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * Self.dotStagger),
                            value: phase
                        )
                }
            }
            VStack(spacing: Tokens.Spacing.xs) {
                Text(title).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                if let subtitle {
                    Text(subtitle).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: Tokens.Motion.fadeInDurationSeconds * 2).repeatForever(autoreverses: true), value: phase)
        .onAppear { phase = !reduceMotion }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview("AI loading") {
    LunchPreview(padding: Tokens.Spacing.xl) {
        AILoading()
    }
}
