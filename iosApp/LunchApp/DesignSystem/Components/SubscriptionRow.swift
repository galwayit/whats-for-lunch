//
//  SubscriptionRow.swift
//  LunchApp
//
//  Profile row for an active Lunch Pro subscription: plan name, renewal or expiry line, and the
//  Manage / Restore actions.
//

import SwiftUI

struct SubscriptionRow: View {
    enum Renewal {
        case renews(String)
        case ends(String)

        var text: String {
            switch self {
            case .renews(let date): return Copy.Profile.proActiveRenews(date)
            case .ends(let date): return Copy.Profile.proActiveExpires(date)
            }
        }
    }

    let planName: String
    let renewal: Renewal
    let onManage: () -> Void
    let onRestore: () -> Void

    var body: some View {
        LunchCard {
            VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                HStack(spacing: Tokens.Spacing.sm) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                        Text(Copy.Profile.proActiveTitle(planName)).lunchText(.heading).foregroundStyle(Tokens.Palette.text)
                        Text(renewal.text).lunchText(.bodySmall).foregroundStyle(Tokens.Palette.textSecondary)
                    }
                    Spacer()
                    ProBadge()
                }
                HStack(spacing: Tokens.Spacing.sm) {
                    LunchButton(title: Copy.Profile.proManage, style: .secondary, action: onManage)
                    LunchButton(title: Copy.Profile.proRestore, style: .text, action: onRestore)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview("Subscription rows") {
    LunchPreview {
        SubscriptionRow(planName: Copy.Paywall.planYearly, renewal: .renews("12 October 2026"), onManage: {}, onRestore: {})
        SubscriptionRow(planName: Copy.Paywall.planMonthly, renewal: .ends("30 September 2026"), onManage: {}, onRestore: {})
    }
}
