//
//  GroupProposalsView.swift
//  LunchApp
//
//  @file GroupProposalsView.swift
//  @description Three proposed places for a group lunch; choosing one confirms it through the core and opens the group detail.
//  @author AI Assistant
//  @date 2026-09-03
//

import SwiftUI

struct GroupProposalsView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var model: GroupProposalsViewModel?
    let groupId: String

    var body: some View {
        Group {
            if let model { content(model) } else { Color.clear }
        }
        .background(Tokens.Palette.ground.ignoresSafeArea())
        .onAppear {
            if model == nil { model = GroupProposalsViewModel(core: app.core, groupId: groupId) }
        }
    }

    private func content(_ model: GroupProposalsViewModel) -> some View {
        VStack(spacing: 0) {
            ScreenHeader(title: Copy.Group.proposalsTitle, dismissal: .back, onDismiss: { app.dismiss() })
            Group {
                if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = model.error {
                    ErrorStateView(error: error) { Task { await model.load() } }
                } else if model.proposals.isEmpty {
                    EmptyState(
                        variant: .nothingHere,
                        title: Copy.Group.noProposals,
                        message: Copy.Group.noProposalsBody,
                        actionTitle: Copy.Action.retry,
                        action: { Task { await model.load() } }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Tokens.Spacing.md) {
                            ForEach(Array(model.proposals.enumerated()), id: \.element.id) { index, proposal in
                                ProposalCard(
                                    restaurant: proposal.restaurant,
                                    reasons: proposal.reasons,
                                    index: index,
                                    isChoosing: model.choosingPlaceId == proposal.id
                                ) {
                                    Task {
                                        if let group = await model.choose(proposal.restaurant) {
                                            app.replaceTop(with: .groupDetail(groupId: group.id))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(Tokens.Spacing.page)
                        .padding(.bottom, Tokens.Spacing.xl)
                    }
                }
            }
        }
        .task { await model.load() }
    }
}

#Preview {
    GroupProposalsView(groupId: PreviewData.group.id).environment(AppEnvironment.preview(PreviewCoreOptions(isPro: true, isSignedIn: true)))
}
