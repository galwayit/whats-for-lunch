//
//  ScreenPlaceholders.swift
//  LunchApp
//
//  Temporary placeholders that keep the project building while feature screens land.
//  Each is deleted when its real screen is added under Features/<Feature>/.
//

import SwiftUI

private struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        Text(title).lunchText(.title).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProfileView: View { var body: some View { PlaceholderScreen(title: Copy.Profile.title) } }
struct GroupCreateView: View { var body: some View { PlaceholderScreen(title: Copy.Group.createTitle) } }
struct GroupProposalsView: View { let groupId: String; var body: some View { PlaceholderScreen(title: Copy.Group.proposalsTitle) } }
struct GroupDetailView: View { let groupId: String; var body: some View { PlaceholderScreen(title: groupId) } }
struct PaywallScreen: View { var body: some View { PlaceholderScreen(title: Copy.Paywall.title) } }
struct PreferencesView: View { var body: some View { PlaceholderScreen(title: Copy.Preferences.title) } }
struct SignInSheet: View { var body: some View { PlaceholderScreen(title: Copy.Profile.signInTitle) } }
struct InvitationView: View { let code: String; var body: some View { PlaceholderScreen(title: code) } }
