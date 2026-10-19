/**
 * @file ProfileView.swift
 * @description Screen 7 of design/screens.md, hosted in the fourth tab: header card,
 *              preference tiles, Lunch Pro card, sign-in row, settings and account actions.
 * @author AI Assistant
 * @date 2026-09-03
 */

import SwiftUI
import UserNotifications

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.openURL) private var openURL
    @AppStorage(AIDataConsent.defaultsKey, store: AIDataConsent.defaultStore) private var aiSharingVersion = ""
    @State private var model: ProfileViewModel?
    @State private var signIn: SignInViewModel?
    @State private var showsDeleteConfirmation = false
    @State private var exportItem: ShareItem?

    private static let avatarSize = Tokens.Size.heroButton / 2

    var body: some View {
        Group {
            if let model, let signIn {
                content(model, signIn: signIn)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            if model == nil { model = ProfileViewModel(core: app.core) }
            if signIn == nil { signIn = SignInViewModel(core: app.core) }
        }
    }

    private func content(_ model: ProfileViewModel, signIn: SignInViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                Text(Copy.Profile.title)
                    .lunchText(.display)
                    .foregroundStyle(Tokens.Palette.text)
                    .accessibilityAddTraits(.isHeader)
                headerCard
                section(Copy.Profile.sectionPreferences) { preferenceTiles }
                section(Copy.Profile.sectionPro) { proCard(model) }
                if app.session == nil { signInCard(signIn) }
                section(Copy.Profile.sectionSettings) { settingsList }
                section(Copy.Profile.sectionAccount) { accountList(model) }
                if let error = model.error {
                    Text(error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
                        .lunchText(.bodySmall)
                        .foregroundStyle(Tokens.Palette.danger)
                }
            }
            .padding(Tokens.Spacing.page)
            .padding(.bottom, Tokens.Spacing.xl)
        }
        .task { await model.observeStatus() }
        .confirmationDialog(Copy.Profile.deleteTitle, isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
            Button(Copy.Profile.deleteConfirm, role: .destructive) {
                Task { _ = await model.deleteAccount() }
            }
            Button(Copy.Action.cancel, role: .cancel) {}
        } message: {
            Text(Copy.Profile.deleteBody)
        }
        .sheet(item: $exportItem) { item in ShareSheet(items: [item.url]) }
    }

    // MARK: Sections

    private var headerCard: some View {
        LunchCard {
            HStack(spacing: Tokens.Spacing.md) {
                InitialAvatar(name: app.user?.name ?? "", size: Self.avatarSize)
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(app.user?.name ?? "")
                        .lunchText(.title)
                        .foregroundStyle(Tokens.Palette.text)
                        .accessibilityIdentifier("profile_name")
                    BadgeLabel(text: Copy.Profile.badge, tint: Tokens.Palette.primary, background: Tokens.Palette.primarySoft)
                }
                Spacer(minLength: 0)
                if app.isPro { ProBadge() }
            }
        }
    }

    private var preferenceTiles: some View {
        let prefs = app.user?.preferences ?? UserPreferences()
        return HStack(spacing: Tokens.Spacing.sm) {
            preferenceTile(title: Copy.Profile.prefBudget, value: String(repeating: "$", count: max(prefs.budgetLevel, 1)), identifier: "profile_pref_budget")
            preferenceTile(title: Copy.Profile.prefDistance, value: LunchFormat.kilometres(prefs.maxTravelDistance), identifier: "profile_pref_distance")
            preferenceTile(title: Copy.Profile.prefChains, value: prefs.includeChains ? Copy.Profile.chainsOn : Copy.Profile.chainsOff, identifier: "profile_pref_chains")
        }
    }

    private func preferenceTile(title: String, value: String, identifier: String) -> some View {
        Button { app.present(.preferences) } label: {
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(value).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                Text(title).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.Spacing.md)
            .background(Tokens.Palette.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
            .lunchHairline(radius: Tokens.Radius.container)
        }
        .buttonStyle(.pressable)
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private func proCard(_ model: ProfileViewModel) -> some View {
        if app.isPro {
            SubscriptionRow(
                planName: model.planName,
                renewal: model.renewal,
                onManage: {
                    if let url = model.status.managementUrl.flatMap(URL.init(string:)) { openURL(url) }
                },
                onRestore: { Task { _ = await model.restore() } }
            )
        } else {
            UpsellRow(title: Copy.Profile.proFreeTitle, message: Copy.Profile.proFreeBody, ctaTitle: Copy.Profile.proFreeCta, icon: .workspacePremium) {
                app.present(.paywall)
            }
            .accessibilityIdentifier("profile_pro_cta")
        }
    }

    private func signInCard(_ signIn: SignInViewModel) -> some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                Text(Copy.Profile.signInTitle).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                Text(Copy.Profile.signInBody).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                SignInButtons(model: signIn)
                LunchButton(title: "Continue with email", style: .secondary, identifier: "profile_sign_in_email") { app.present(.signIn) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var settingsList: some View {
        listCard {
            listRow(icon: .tune, title: Copy.Profile.settingsEdit, identifier: "profile_edit_preferences") { app.present(.preferences) }
            listRow(icon: .notifications, title: Copy.Profile.settingsNotifications, identifier: "profile_notifications") {
                Task {
                    let settings = await UNUserNotificationCenter.current().notificationSettings()
                    if settings.authorizationStatus == .notDetermined {
                        await LunchAppDelegate.requestNotificationPermission()
                    } else if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            if !aiSharingVersion.isEmpty {
                listRow(icon: .autoAwesome, title: "Withdraw AI data sharing consent", identifier: "profile_revoke_ai_consent") {
                    AIDataConsent().revoke()
                    aiSharingVersion = ""
                    app.showToast("AI sharing is off. You can agree again when you next ask for recommendations.")
                }
            }
            listRow(icon: .shield, title: Copy.Profile.settingsPrivacy, identifier: "profile_privacy") { app.present(.privacy) }
            listRow(icon: .help, title: Copy.Profile.settingsHelp, identifier: "profile_help", isLast: true) { app.present(.help) }
        }
    }

    private func accountList(_ model: ProfileViewModel) -> some View {
        listCard {
            if let session = app.session {
                HStack(spacing: Tokens.Spacing.md) {
                    IconView(icon: .person, size: Tokens.Size.iconDefault).foregroundStyle(Tokens.Palette.textSecondary)
                    Text(Copy.Profile.signedInAs(session.displayName ?? session.email ?? session.userId))
                        .lunchText(.body)
                        .foregroundStyle(Tokens.Palette.text)
                    Spacer(minLength: 0)
                }
                .padding(Tokens.Spacing.md)
                .accessibilityIdentifier("profile_signed_in_as")
                rowDivider
                listRow(icon: .logout, title: Copy.Profile.signOut, identifier: "profile_sign_out", isLoading: model.isSigningOut) {
                    Task { _ = await model.signOut() }
                }
            }
            listRow(icon: .download, title: "Export meal report (PDF) · Pro", identifier: "profile_export_pdf", isLoading: model.isExporting) {
                guard app.isPro else { app.present(.paywall); return }
                Task {
                    guard let user = app.user, let url = await model.exportPDF(user: user) else { return }
                    exportItem = ShareItem(url: url)
                }
            }
            listRow(icon: .download, title: Copy.Profile.exportData, identifier: "profile_export", isLoading: model.isExporting) {
                Task {
                    guard let user = app.user, let url = await model.exportData(user: user) else { return }
                    exportItem = ShareItem(url: url)
                }
            }
            listRow(icon: .delete, title: Copy.Profile.deleteTitle, identifier: "profile_delete", tint: Tokens.Palette.danger, isLoading: model.isDeleting, isLast: true) {
                showsDeleteConfirmation = true
            }
        }
    }

    // MARK: Building blocks

    private func section<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            Text(title).lunchText(.label).foregroundStyle(Tokens.Palette.textSecondary)
            content()
        }
    }

    private func listCard<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        LunchCard(padding: 0) {
            VStack(spacing: 0) { content() }
        }
    }

    private var rowDivider: some View {
        Divider().overlay(Tokens.Palette.hairline).padding(.leading, Tokens.Spacing.md)
    }

    private func listRow(icon: LunchIcon, title: String, identifier: String, tint: Color = Tokens.Palette.text, isLoading: Bool = false, isLast: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: Tokens.Spacing.md) {
                    IconView(icon: icon, size: Tokens.Size.iconDefault).foregroundStyle(tint)
                    Text(title).lunchText(.body).foregroundStyle(tint)
                    Spacer(minLength: 0)
                    if isLoading {
                        ProgressView().tint(Tokens.Palette.textSecondary)
                    } else {
                        IconView(icon: .chevronRight, size: Tokens.Size.iconDefault).foregroundStyle(Tokens.Palette.textSecondary)
                    }
                }
                .padding(Tokens.Spacing.md)
                .frame(minHeight: Tokens.Size.touchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .disabled(isLoading)
            .accessibilityIdentifier(identifier)
            if !isLast { rowDivider }
        }
    }
}

#Preview("Free, signed out") {
    ProfileView().environment(AppEnvironment.preview())
}

#Preview("Pro, signed in") {
    ProfileView().environment(AppEnvironment.preview(PreviewCoreOptions(isPro: true, isSignedIn: true)))
}
