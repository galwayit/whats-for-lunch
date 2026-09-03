//
//  InfoScreen.swift
//  LunchApp
//
//  Privacy and Help destinations from Profile. Static copy until the web pages exist.
//

import SwiftUI

struct InfoScreen: View {
    enum Kind { case privacy, help }
    @Environment(AppEnvironment.self) private var app
    let kind: Kind

    private var title: String {
        switch kind {
        case .privacy: return Copy.Profile.settingsPrivacy
        case .help: return Copy.Profile.settingsHelp
        }
    }

    var body: some View {
        SheetContainer(title: title, actionTitle: Copy.Action.done, onAction: { app.dismiss() }) {
            Text(kind == .privacy ? Copy.Info.privacyBody : Copy.Info.helpBody)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
