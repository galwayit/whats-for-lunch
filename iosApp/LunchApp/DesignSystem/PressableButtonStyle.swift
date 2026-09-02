//
//  PressableButtonStyle.swift
//  LunchApp
//
//  The shared press feedback: scale to `Tokens.Motion.pressScale` over
//  `Tokens.Motion.pressDurationSeconds`. Reduced motion swaps the scale for an opacity dip.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let pressedOpacity = 0.7

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? Tokens.Motion.pressScale : 1)
            .opacity(configuration.isPressed && reduceMotion ? Self.pressedOpacity : 1)
            .animation(.easeOut(duration: Tokens.Motion.pressDurationSeconds), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
