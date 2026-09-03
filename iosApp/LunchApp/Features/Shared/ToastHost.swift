//
//  ToastHost.swift
//  LunchApp
//
//  Bottom toast driven by `AppEnvironment.toast`. Auto-dismisses after the token duration and
//  animates only when reduced motion is off.
//

import SwiftUI

struct ToastHost: ViewModifier {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = app.toast {
                Text(message)
                    .lunchText(.label)
                    .foregroundStyle(Tokens.Palette.textOnPrimary)
                    .padding(.horizontal, Tokens.Spacing.md)
                    .padding(.vertical, Tokens.Spacing.sm + Tokens.Spacing.xs)
                    .background(Tokens.Palette.text, in: RoundedRectangle(cornerRadius: Tokens.Radius.toast, style: .continuous))
                    .padding(.bottom, Tokens.Spacing.xxl + Tokens.Spacing.lg)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .accessibilityIdentifier("toast")
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(Tokens.Motion.achievementToastAutoDismissSeconds))
                        if app.toast == message { app.toast = nil }
                    }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: Tokens.Motion.stateDurationSeconds), value: app.toast)
    }
}

extension View {
    func toastHost() -> some View { modifier(ToastHost()) }
}
