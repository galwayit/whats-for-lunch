//
//  GroupCreateView.swift
//  LunchApp
//
//  @file GroupCreateView.swift
//  @description Host form for a new group lunch: name, date and time, current-location area and radius. Creating succeeds only for Pro users (GateService.canHostGroup is checked on Home before this screen opens).
//  @author AI Assistant
//  @date 2026-09-03
//

import SwiftUI

struct GroupCreateView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: GroupCreateViewModel?

    var body: some View {
        Group {
            if let model { content(model) } else { Color.clear }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            if model == nil { model = GroupCreateViewModel(core: app.core) }
        }
    }

    private func content(_ model: GroupCreateViewModel) -> some View {
        @Bindable var model = model
        return VStack(spacing: 0) {
            ScreenHeader(title: Copy.Group.createTitle, onDismiss: { app.dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.lg) {
                    LunchTextField(
                        placeholder: Copy.Group.namePlaceholder,
                        text: $model.name,
                        icon: .group,
                        identifier: "group_name_field",
                        submitLabel: .next
                    )

                    GroupDetailsFields(draft: $model.detailsDraft)

                    fieldLabel(Copy.Group.when)
                    LunchCard {
                        DatePicker("", selection: $model.scheduledAt, in: Date()...)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    fieldLabel(Copy.Group.whereLabel)
                    SearchAreaButton()
                    LunchCard {
                        HStack(spacing: Tokens.Spacing.sm) {
                            IconView(icon: .locationOn).foregroundStyle(Tokens.Palette.primary)
                            Text(model.locationSummary)
                                .lunchText(.body)
                                .foregroundStyle(model.area == nil ? Tokens.Palette.textSecondary : Tokens.Palette.text)
                            Spacer()
                            if model.isLocating { ProgressView() }
                        }
                    }

                    fieldLabel(Copy.Group.radius)
                    HStack(spacing: Tokens.Spacing.sm) {
                        ForEach(GroupCreateViewModel.radiusOptions, id: \.self) { radius in
                            Chip(title: Copy.Group.radiusChip(Int(radius)), isSelected: model.radiusKm == radius) {
                                model.radiusKm = radius
                            }
                        }
                    }

                    if let error = model.error {
                        ErrorStateView(error: error) { Task { await model.loadArea() } }
                    }

                    LunchButton(
                        title: Copy.Group.propose,
                        style: .primary,
                        isLoading: model.isCreating,
                        isDisabled: model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.area == nil || model.detailsDraft.value == nil,
                        identifier: "group_create_submit"
                    ) {
                        Task {
                            if let group = await model.create() {
                                app.replaceTop(with: .groupProposals(groupId: group.id))
                            }
                        }
                    }
                }
                .padding(Tokens.Spacing.page)
                .padding(.bottom, Tokens.Spacing.xl)
            }
        }
        .task(id: app.searchArea) { await model.loadArea() }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .lunchText(.label)
            .foregroundStyle(Tokens.Palette.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Create group") {
    GroupCreateView().environment(AppEnvironment.preview())
}
