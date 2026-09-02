//
//  HeroHungryButton.swift
//  LunchApp
//
//  The 224pt orange disc with a cream border, two pulsing rings, press scale, and a haptic on
//  release. Rings stop pulsing under Reduce Motion. `searching` swaps the icon for a spinner.
//

import SwiftUI
import UIKit

struct HeroHungryButton: View {
    enum State {
        case idle, searching
    }

    var state: State = .idle
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @SwiftUI.State private var isPulsing = false
    @SwiftUI.State private var spinnerAngle = Angle.zero

    static let identifier = "hero_hungry_button"
    private static let outerRingWidth = Tokens.Spacing.xs / 2
    private static let innerRingWidth = Tokens.Spacing.xs
    private static let iconSize = Tokens.Size.iconDefault * 2
    private static let spinnerTrim = 0.75
    private static let spinnerTurnSeconds = 1.0

    var body: some View {
        ZStack {
            ring(diameter: Tokens.Size.heroRingOuter, width: Self.outerRingWidth, scale: Tokens.Motion.heroPulseScaleOuter)
            ring(diameter: Tokens.Size.heroRingInner, width: Self.innerRingWidth, scale: Tokens.Motion.heroPulseScaleInner)
            Button(action: fire) {
                disc
            }
            .buttonStyle(.pressable)
            .disabled(state == .searching)
            .accessibilityIdentifier(Self.identifier)
            .accessibilityLabel(state == .idle ? Copy.Home.hero : Copy.Home.searchingTitle)
            .accessibilityAddTraits(state == .searching ? .updatesFrequently : [])
        }
        .frame(width: Tokens.Size.heroRingOuter, height: Tokens.Size.heroRingOuter)
        .onAppear(perform: startMotion)
        .onChange(of: reduceMotion) { startMotion() }
        .onChange(of: state) { startMotion() }
    }

    private var disc: some View {
        ZStack {
            Circle()
                .fill(Tokens.Palette.action)
                .lunchShadow(LunchElevation.hero, color: Tokens.Palette.action)
            Circle()
                .strokeBorder(Tokens.Palette.ground, lineWidth: Tokens.Size.heroBorder)
            VStack(spacing: Tokens.Spacing.sm) {
                if state == .searching {
                    spinner
                    Text(Copy.Home.searchingTitle)
                        .lunchText(.caption)
                        .multilineTextAlignment(.center)
                } else {
                    IconView(icon: .restaurant, size: Self.iconSize)
                    Text(Copy.Home.hero)
                        .lunchText(.heading)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Tokens.Size.heroBorder + Tokens.Spacing.md)
            .foregroundStyle(Tokens.Palette.textOnAction)
        }
        .frame(width: Tokens.Size.heroButton, height: Tokens.Size.heroButton)
        .contentShape(Circle())
    }

    private var spinner: some View {
        Circle()
            .trim(from: 0, to: Self.spinnerTrim)
            .stroke(Tokens.Palette.textOnAction, style: StrokeStyle(lineWidth: Self.innerRingWidth, lineCap: .round))
            .frame(width: Self.iconSize, height: Self.iconSize)
            .rotationEffect(spinnerAngle)
    }

    private func ring(diameter: CGFloat, width: CGFloat, scale: Double) -> some View {
        Circle()
            .strokeBorder(Tokens.Palette.actionSoft, lineWidth: width)
            .frame(width: diameter, height: diameter)
            .scaleEffect(isPulsing ? scale : 1)
    }

    private func fire() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        action()
    }

    private func startMotion() {
        if reduceMotion {
            withAnimation(.easeOut(duration: Tokens.Motion.stateDurationSeconds)) {
                isPulsing = false
                spinnerAngle = .zero
            }
            return
        }
        withAnimation(.easeInOut(duration: Tokens.Motion.heroPulseDurationSeconds).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
        if state == .searching {
            withAnimation(.linear(duration: Self.spinnerTurnSeconds).repeatForever(autoreverses: false)) {
                spinnerAngle = .degrees(360)
            }
        } else {
            spinnerAngle = .zero
        }
    }
}

#Preview("Hero idle and searching") {
    LunchPreview(padding: Tokens.Spacing.xl) {
        HeroHungryButton {}
        HeroHungryButton(state: .searching) {}
    }
}
