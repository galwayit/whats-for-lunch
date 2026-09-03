//
//  WeeklyBudgetStrip.swift
//  LunchApp
//
//  Compact weekly budget summary for Home and Track: spent of capacity, amount left, a thin
//  progress bar, and the experiences count. Tapping opens budget setup.
//

import SwiftUI

struct WeeklyBudgetStrip: View {
    let budget: WeeklyBudgetState
    var tone: CapacityRing.Tone = .healthy
    let onTap: () -> Void

    private static let barHeight = Tokens.Spacing.sm
    private static let iconSize = Tokens.Size.iconDefault - Tokens.Spacing.xs

    var body: some View {
        Button(action: onTap) {
            LunchCard {
                VStack(alignment: .leading, spacing: Tokens.Spacing.sm + Tokens.Spacing.xs) {
                    HStack {
                        IconView(icon: .payments, size: Self.iconSize).foregroundStyle(tone.color)
                        Text(Copy.Track.ringLabel(spent: PreviewData.currency(budget.currentSpent), capacity: PreviewData.currency(budget.weeklyCapacity)))
                            .lunchText(.heading)
                            .foregroundStyle(Tokens.Palette.text)
                        Spacer()
                        IconView(icon: .chevronRight, size: Self.iconSize).foregroundStyle(Tokens.Palette.textSecondary)
                    }
                    progressBar
                    HStack {
                        Text(Copy.Track.ringRemaining(PreviewData.currency(budget.remainingCapacity)))
                        Spacer()
                        Text("\(budget.experiencesLogged) of \(budget.targetExperiences) experiences")
                    }
                    .lunchText(.caption)
                    .foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Copy.Track.ringSetup)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Tokens.Palette.hairline)
                Capsule()
                    .fill(tone.color)
                    .frame(width: proxy.size.width * min(max(budget.capacityProgress, 0), 1))
                    .animation(.easeOut(duration: Tokens.Motion.fadeInDurationSeconds), value: budget.capacityProgress)
            }
        }
        .frame(height: Self.barHeight)
    }
}

#Preview("Weekly budget strip") {
    LunchPreview {
        WeeklyBudgetStrip(budget: PreviewData.weeklyBudget) {}
        WeeklyBudgetStrip(budget: PreviewData.weeklyBudgetOver, tone: .over) {}
    }
}
