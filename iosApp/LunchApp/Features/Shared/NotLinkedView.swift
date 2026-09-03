//
//  NotLinkedView.swift
//  LunchApp
//
//  Shown when a normal launch cannot start the production core.
//

import SwiftUI

struct NotLinkedView: View {
    var body: some View {
        VStack(spacing: Tokens.Spacing.lg) {
            Spacer()
            EmptyState(variant: .serviceProblem, title: Copy.Error.notLinkedTitle, message: Copy.Error.notLinkedBody)
            Spacer()
            Text(NotConfigured.code)
                .lunchText(.caption)
                .foregroundStyle(Tokens.Palette.textSecondary)
        }
        .padding(Tokens.Spacing.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Palette.ground.ignoresSafeArea())
    }
}

#Preview {
    NotLinkedView()
}
