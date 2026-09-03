//
//  OnboardingView.swift
//  LunchApp
//
//  Screen 1 of design/screens.md: progress bar, eyebrow, card, primary CTA at the bottom.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model: OnboardingViewModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                Color.clear
            }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear { if model == nil { model = OnboardingViewModel(core: app.core) } }
    }

    private func content(_ model: OnboardingViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            header(model)
            ScrollView {
                LunchCard {
                    switch model.step {
                    case 1: OnboardingWelcomeStep()
                    case 2: OnboardingNameStep(name: $model.name)
                    case 3: OnboardingBudgetStep(model: model)
                    case 4: OnboardingDietaryStep(model: model)
                    default: OnboardingLocationStep()
                    }
                }
                .padding(Tokens.Spacing.page)
                .animation(reduceMotion ? nil : .easeInOut(duration: Tokens.Motion.stateDurationSeconds), value: model.step)
            }
            footer(model)
        }
    }

    private func header(_ model: OnboardingViewModel) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Tokens.Palette.primarySoft)
                    Capsule().fill(Tokens.Palette.primary).frame(width: proxy.size.width * model.progress)
                }
            }
            .frame(height: Tokens.Spacing.xs)
            .accessibilityHidden(true)
            HStack {
                if model.step > 1 {
                    Button(action: model.back) {
                        IconView(icon: .arrowBack, size: Tokens.Size.iconDefault)
                            .foregroundStyle(Tokens.Palette.text)
                            .frame(width: Tokens.Size.touchTarget, height: Tokens.Size.touchTarget)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(Copy.Action.back)
                }
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(Copy.Onboarding.step(model.step))
                        .lunchText(.caption)
                        .foregroundStyle(Tokens.Palette.primary)
                    Text(stepLabel(model.step))
                        .lunchText(.label)
                        .foregroundStyle(Tokens.Palette.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, Tokens.Spacing.page)
        .padding(.top, Tokens.Spacing.md)
    }

    private func stepLabel(_ step: Int) -> String {
        switch step {
        case 1: return Copy.Onboarding.step1Eyebrow
        case 2: return Copy.Onboarding.step2Eyebrow
        case 3: return Copy.Onboarding.step3Eyebrow
        case 4: return Copy.Onboarding.step4Eyebrow
        default: return Copy.Onboarding.step5Eyebrow
        }
    }

    @ViewBuilder
    private func footer(_ model: OnboardingViewModel) -> some View {
        VStack(spacing: Tokens.Spacing.sm) {
            if let error = model.error {
                Text(error == .offline ? Copy.Error.offlineBody : Copy.Error.serviceBody)
                    .lunchText(.bodySmall)
                    .foregroundStyle(Tokens.Palette.danger)
            }
            switch model.step {
            case 1:
                LunchButton(title: Copy.Onboarding.step1Cta, style: .primary, identifier: "onboarding_next", action: model.next)
            case 5:
                LunchButton(
                    title: model.hasLocationPermission ? Copy.Onboarding.finishCta : Copy.Onboarding.step5Cta,
                    style: .primary,
                    icon: .nearMe,
                    isLoading: model.isSubmitting,
                    identifier: "onboarding_allow_location"
                ) {
                    Task { await model.allowLocation(app: app) }
                }
                if !model.hasLocationPermission {
                    LunchButton(title: Copy.Onboarding.step5Skip, style: .text, isDisabled: model.isSubmitting, identifier: "onboarding_skip_location") {
                        Task { await model.finish(app: app) }
                    }
                }
            default:
                LunchButton(title: Copy.Action.continue, style: .primary, isDisabled: !model.canContinue, identifier: "onboarding_next", action: model.next)
            }
        }
        .padding(.horizontal, Tokens.Spacing.page)
        .padding(.bottom, Tokens.Spacing.md)
    }
}

// MARK: - Steps

private struct OnboardingWelcomeStep: View {
    private static let discSize = Tokens.Size.touchTarget * 2
    private static let imageHeight = Tokens.Spacing.xxl * 3

    var body: some View {
        VStack(spacing: Tokens.Spacing.md) {
            ZStack {
                Circle().fill(Tokens.Palette.primarySoft)
                IconView(icon: .restaurant, size: Tokens.Size.iconDefault + Tokens.Spacing.sm, filled: true)
                    .foregroundStyle(Tokens.Palette.primary)
            }
            .frame(width: Self.discSize, height: Self.discSize)
            Text(Copy.Onboarding.step1Title)
                .lunchText(.title)
                .foregroundStyle(Tokens.Palette.text)
                .multilineTextAlignment(.center)
            Text(Copy.Onboarding.step1Body)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
                .multilineTextAlignment(.center)
            RoundedRectangle(cornerRadius: Tokens.Radius.container, style: .continuous)
                .fill(Tokens.Palette.surfaceRaised)
                .frame(height: Self.imageHeight)
                .overlay {
                    IconView(icon: .restaurantMenu, size: Tokens.Size.iconDefault * 2)
                        .foregroundStyle(Tokens.Palette.hairlineStrong)
                }
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct OnboardingNameStep: View {
    @Binding var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Onboarding.step2Title)
                .lunchText(.title)
                .foregroundStyle(Tokens.Palette.text)
            LunchTextField(placeholder: Copy.Onboarding.step2Placeholder, text: $name, icon: .person, identifier: "onboarding_name_field", submitLabel: .next)
                .textContentType(.givenName)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingBudgetStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Onboarding.step3Title)
                .lunchText(.title)
                .foregroundStyle(Tokens.Palette.text)
            Text(Copy.Onboarding.step3Body)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
            PriceLevelChips(selected: $model.budgetLevel)
            DistanceSlider(label: Copy.Onboarding.step3Distance(LunchFormat.kilometres(model.maxTravelDistance)), value: $model.maxTravelDistance)
            Toggle(isOn: $model.includeChains) {
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(Copy.Onboarding.step3Chains).lunchText(.label).foregroundStyle(Tokens.Palette.text)
                    Text(Copy.Onboarding.step3ChainsHint).lunchText(.caption).foregroundStyle(Tokens.Palette.textSecondary)
                }
            }
            .tint(Tokens.Palette.primary)
            .accessibilityIdentifier("onboarding_chains_toggle")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingDietaryStep: View {
    let model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
            Text(Copy.Onboarding.step4Title)
                .lunchText(.title)
                .foregroundStyle(Tokens.Palette.text)
            Text(Copy.Onboarding.step4Body)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
            DietaryChipGrid(selected: model.dietary, includeNone: true) { model.toggleDietary($0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingLocationStep: View {
    private static let discSize = Tokens.Size.touchTarget * 2

    var body: some View {
        VStack(spacing: Tokens.Spacing.md) {
            ZStack {
                Circle().fill(Tokens.Palette.actionSoft)
                IconView(icon: .locationOn, size: Tokens.Size.iconDefault + Tokens.Spacing.sm, filled: true)
                    .foregroundStyle(Tokens.Palette.action)
            }
            .frame(width: Self.discSize, height: Self.discSize)
            Text(Copy.Onboarding.step5Title)
                .lunchText(.title)
                .foregroundStyle(Tokens.Palette.text)
                .multilineTextAlignment(.center)
            Text(Copy.Onboarding.step5Body)
                .lunchText(.body)
                .foregroundStyle(Tokens.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared controls (also used by Preferences and Discover)

/// Four price chips, "$" to "$$$$".
struct PriceLevelChips: View {
    @Binding var selected: Int
    var identifierPrefix = "price_level"

    var body: some View {
        HStack(spacing: Tokens.Spacing.sm) {
            ForEach(OnboardingViewModel.priceLevels, id: \.self) { level in
                let label = String(repeating: "$", count: level)
                Chip(title: label, isSelected: selected == level, identifier: "\(identifierPrefix)_\(label)") { selected = level }
            }
        }
    }
}

/// Labelled 1 to 20 km slider in whole kilometres.
struct DistanceSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            Text(label).lunchText(.label).foregroundStyle(Tokens.Palette.text)
            Slider(value: $value, in: OnboardingViewModel.distanceRange, step: 1)
                .tint(Tokens.Palette.primary)
                .accessibilityLabel(label)
        }
    }
}

/// Wrapping chip grid of the dietary options from the copy deck.
struct DietaryChipGrid: View {
    let selected: Set<String>
    var includeNone = false
    var onlyAllergens = false
    /// Hides the allergen options; Preferences shows them in their own section.
    var onlyDiets = false
    let onToggle: (String) -> Void

    private var options: [(label: String, key: String)] {
        var list = Copy.Dietary.options.filter { option in
            let isAllergen = Copy.Dietary.allergenKeys.contains(option.key)
            if onlyAllergens { return isAllergen }
            if onlyDiets { return !isAllergen }
            return true
        }
        if includeNone { list.append(Copy.Dietary.none) }
        return list
    }

    var body: some View {
        FlowLayout(spacing: Tokens.Spacing.sm) {
            ForEach(options, id: \.key) { option in
                Chip(title: option.label, isSelected: selected.contains(option.key), identifier: "dietary_\(option.key)") { onToggle(option.key) }
            }
        }
    }
}

/// Minimal wrapping layout for chip grids.
nonisolated struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        return arrange(subviews, width: width).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews, width: bounds.width)
        for (subview, origin) in zip(subviews, arrangement.origins) {
            subview.place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

#Preview("Onboarding") {
    OnboardingView().environment(AppEnvironment.preview(PreviewCoreOptions(isOnboarded: false)))
}
