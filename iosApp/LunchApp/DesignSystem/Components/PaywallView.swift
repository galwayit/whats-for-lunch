//
//  PaywallView.swift
//  LunchApp
//
//  Lunch Pro paywall: two plan cards (yearly preselected with the trial line and BEST VALUE),
//  six benefits, the action-coloured CTA (id paywall_cta), the legal sentence with the store
//  name substituted, and Restore / Terms / Privacy links.
//

import SwiftUI

struct PaywallView: View {
    let yearly: ProPackage?
    let monthly: ProPackage?
    var storeName = "Apple"
    var isPurchasing = false
    let onPurchase: (ProPackage) -> Void
    let onRestore: () -> Void
    let onTerms: () -> Void
    let onPrivacy: () -> Void

    @State private var selectedIdentifier: String?

    static let ctaIdentifier = "paywall_cta"
    private static let benefitIconSize = Tokens.Size.iconDefault - Tokens.Spacing.sm
    private static let heroIconSize = Tokens.Size.iconDefault + Tokens.Spacing.md

    private var selectedPackage: ProPackage? {
        [yearly, monthly].compactMap { $0 }.first { $0.identifier == selectedIdentifier }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                header
                VStack(spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
                    if let yearly {
                        planCard(yearly, title: Copy.Paywall.planYearly, detail: Copy.Paywall.planYearlyTrial(yearly.localizedPrice), badge: Copy.Paywall.planYearlyBadge)
                    }
                    if let monthly {
                        planCard(monthly, title: Copy.Paywall.planMonthly, detail: Copy.Paywall.planMonthlyPrice(monthly.localizedPrice), badge: nil)
                    }
                }
                benefits
                LunchButton(
                    title: selectedPackage?.hasFreeTrial == true ? Copy.Paywall.ctaTrial : Copy.Paywall.ctaSubscribe,
                    style: .action,
                    isLoading: isPurchasing,
                    isDisabled: selectedPackage == nil,
                    identifier: Self.ctaIdentifier
                ) {
                    if let selectedPackage { onPurchase(selectedPackage) }
                }
                Text(Copy.Paywall.legal(store: storeName))
                    .lunchText(.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                links
            }
            .padding(Tokens.Spacing.pageWide)
        }
        .background(Tokens.Palette.ground)
        .onAppear {
            if selectedIdentifier == nil { selectedIdentifier = (yearly ?? monthly)?.identifier }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            IconView(icon: .workspacePremium, size: Self.heroIconSize).foregroundStyle(Tokens.Palette.action)
            Text(Copy.Paywall.title).lunchText(.display).foregroundStyle(Tokens.Palette.text)
                .accessibilityAddTraits(.isHeader)
            Text(Copy.Paywall.subtitle).lunchText(.body).foregroundStyle(Tokens.Palette.textSecondary)
        }
    }

    private func planCard(_ package: ProPackage, title: String, detail: String, badge: String?) -> some View {
        let isSelected = package.identifier == selectedIdentifier
        return Button {
            withAnimation(.easeOut(duration: Tokens.Motion.stateDurationSeconds)) {
                selectedIdentifier = package.identifier
            }
        } label: {
            HStack(spacing: Tokens.Spacing.md) {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    HStack(spacing: Tokens.Spacing.sm) {
                        Text(title).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                        if let badge {
                            BadgeLabel(text: badge, tint: Tokens.Palette.textOnAction, background: Tokens.Palette.action)
                        }
                    }
                    Text(detail).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                }
                Spacer()
                IconView(icon: .check, size: Self.benefitIconSize)
                    .foregroundStyle(Tokens.Palette.textOnPrimary)
                    .padding(Tokens.Spacing.xs)
                    .background(isSelected ? Tokens.Palette.primary : Tokens.Palette.hairline, in: Circle())
            }
            .padding(Tokens.Spacing.md)
            .background(Tokens.Palette.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
            .lunchHairline(
                radius: Tokens.Radius.container,
                color: isSelected ? Tokens.Palette.primary : Tokens.Palette.hairline,
                width: isSelected ? LunchTextField.focusBorderWidth : 1
            )
            .contentShape(RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(title), \(detail)" + (badge.map { ", \($0)" } ?? ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("paywall_plan_\(package.identifier)")
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
            ForEach(Copy.Paywall.benefits, id: \.self) { benefit in
                HStack(spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
                    IconView(icon: .check, size: Self.benefitIconSize).foregroundStyle(Tokens.Palette.success)
                    Text(benefit).lunchText(.body).foregroundStyle(Tokens.Palette.text)
                }
            }
        }
    }

    private var links: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Tokens.Spacing.sm) { linkButtons }
            VStack(alignment: .leading, spacing: 0) { linkButtons }
        }
    }

    @ViewBuilder private var linkButtons: some View {
        LunchButton(title: Copy.Paywall.restore, style: .text, fillsWidth: false, action: onRestore)
        Spacer(minLength: 0)
        LunchButton(title: Copy.Paywall.terms, style: .text, fillsWidth: false, action: onTerms)
        Spacer(minLength: 0)
        LunchButton(title: Copy.Paywall.privacy, style: .text, fillsWidth: false, action: onPrivacy)
    }
}

#Preview("Paywall light") {
    PaywallView(
        yearly: PreviewData.yearlyPackage,
        monthly: PreviewData.monthlyPackage,
        onPurchase: { _ in }, onRestore: {}, onTerms: {}, onPrivacy: {}
    )
}

#Preview("Paywall dark") {
    PaywallView(
        yearly: PreviewData.yearlyPackage,
        monthly: PreviewData.monthlyPackage,
        onPurchase: { _ in }, onRestore: {}, onTerms: {}, onPrivacy: {}
    )
    .preferredColorScheme(.dark)
}
