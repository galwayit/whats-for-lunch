//
//  ScreenHeader.swift
//  LunchApp
//
//  Title row for modal screens: a back or close button, the title, and an optional trailing
//  control (Preferences uses it for Save).
//

import SwiftUI

struct ScreenHeader<Trailing: View>: View {
    enum Dismissal { case back, close }

    let title: String
    var dismissal: Dismissal = .close
    let onDismiss: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, dismissal: Dismissal = .close, onDismiss: @escaping () -> Void, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.dismissal = dismissal
        self.onDismiss = onDismiss
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            Button(action: onDismiss) {
                IconView(icon: dismissal == .back ? .arrowBack : .close, size: Tokens.Size.iconDefault)
                    .foregroundStyle(Tokens.Palette.text)
                    .frame(width: Tokens.Size.touchTarget, height: Tokens.Size.touchTarget)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(dismissal == .back ? Copy.Action.back : Copy.Action.close)
            .accessibilityIdentifier(dismissal == .back ? "header_back" : "header_close")
            Text(title)
                .lunchText(.heading)
                .foregroundStyle(Tokens.Palette.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            trailing()
        }
        .padding(.horizontal, Tokens.Spacing.sm)
        .padding(.vertical, Tokens.Spacing.sm)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, dismissal: Dismissal = .close, onDismiss: @escaping () -> Void) {
        self.init(title: title, dismissal: dismissal, onDismiss: onDismiss) { EmptyView() }
    }
}
