//
//  PaywallScreen.swift
//  LunchApp
//
//  @file PaywallScreen.swift
//  @description The Lunch Pro paywall (design/screens.md section 9): both plans from the core
//  entitlement API with the 7-day trial on yearly, restore, terms and privacy links, and the
//  "You're on Lunch Pro" success state with Done.
//  @author AI Assistant
//  @date 2026-09-03
//

import SwiftUI

struct PaywallScreen: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.openURL) private var openURL
    @State private var model: PaywallViewModel?

    static let successIdentifier = "paywall_success"

    var body: some View {
        Group {
            if let model { content(model) } else { Color.clear }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            if model == nil { model = PaywallViewModel(core: app.core) }
        }
    }

    private func content(_ model: PaywallViewModel) -> some View {
        @Bindable var model = model
        return ZStack(alignment: .topTrailing) {
            if model.isSubscribed {
                successState
            } else if case .failed(let error) = model.offerings {
                ErrorStateView(error: error) { Task { await model.load() } }
                    .padding(.top, Tokens.Size.touchTarget + Tokens.Spacing.md)
            } else {
                PaywallView(
                    yearly: model.yearly,
                    monthly: model.monthly,
                    storeName: Copy.Paywall.storeName,
                    isPurchasing: model.isPurchasing,
                    onPurchase: { package in Task { await model.purchase(package) } },
                    onRestore: { Task { await restore(model) } },
                    onTerms: { openURL(LunchConfig.termsUrl) },
                    onPrivacy: { app.present(.privacy) }
                )
                if model.offerings.isLoading {
                    ProgressView()
                        .tint(Tokens.Palette.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Tokens.Palette.ground.opacity(0.72))
                }
            }

            if !model.isSubscribed { closeButton }
        }
        .task { await model.load() }
        .alert(Copy.Error.serviceTitle, isPresented: Binding(
            get: { model.error != nil },
            set: { if !$0 { model.error = nil } }
        )) {
            Button(Copy.Action.done) { model.error = nil }
        } message: {
            Text(model.error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
        }
    }

    private var closeButton: some View {
        Button { app.dismiss() } label: {
            IconView(icon: .close, size: Tokens.Size.iconDefault)
                .foregroundStyle(Tokens.Palette.text)
                .frame(width: Tokens.Size.touchTarget, height: Tokens.Size.touchTarget)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Copy.Action.close)
        .accessibilityIdentifier("paywall_close")
        .padding(Tokens.Spacing.md)
    }

    private var successState: some View {
        VStack(spacing: Tokens.Spacing.lg) {
            Spacer()
            IconView(icon: .workspacePremium, size: Tokens.Size.touchTarget, filled: true)
                .foregroundStyle(Tokens.Palette.primary)
                .frame(width: Tokens.Size.heroButton / 2, height: Tokens.Size.heroButton / 2)
                .background(Tokens.Palette.primarySoft, in: Circle())
            Text(Copy.Paywall.successTitle)
                .lunchText(.display)
                .foregroundStyle(Tokens.Palette.text)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(Copy.Paywall.successBody)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            LunchButton(title: Copy.Action.done, style: .primary, identifier: "paywall_done") { app.dismiss() }
        }
        .padding(Tokens.Spacing.page)
        .accessibilityIdentifier(Self.successIdentifier)
    }

    private func restore(_ model: PaywallViewModel) async {
        guard let outcome = await model.restore() else { return }
        if outcome == .nothingToRestore { app.showToast(Copy.Paywall.restoreNothing) }
    }
}

#Preview("Free") {
    PaywallScreen().environment(AppEnvironment.preview())
}
