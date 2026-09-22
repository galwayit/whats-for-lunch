/**
 * @file GroupProposalsScreen.kt
 * @description Screen 14 of design/screens.md: three proposed places for the group, one
 * "Choose" each.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.groups

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.AILoading
import au.iapp.lunch.ui.components.ProposalCard
import au.iapp.lunch.ui.features.shared.ErrorStateView
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun GroupProposalsScreen(groupId: String, modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: GroupProposalsViewModel = viewModel(key = "proposals:$groupId") { GroupProposalsViewModel(app, groupId) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors

    ModalScreen(onBack = app::dismiss, modifier = modifier) {
        ScreenHeader(title = stringResource(R.string.group_proposals_title), onDismiss = app::dismiss)
        when (val proposals = state.proposals) {
            LoadState.Idle, LoadState.Loading -> AILoading(
                title = stringResource(R.string.ai_thinking_title),
                subtitle = stringResource(R.string.ai_thinking_body),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(TokenSpacing.page),
            )
            is LoadState.Failed -> ErrorStateView(error = proposals.error, onRetry = viewModel::load, modifier = Modifier.fillMaxWidth())
            is LoadState.Loaded -> LazyColumn(
                contentPadding = PaddingValues(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm),
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.md),
            ) {
                item { LunchText(text = stringResource(R.string.group_proposals_choose), role = LunchTextRole.Body, color = colors.textSecondary) }
                state.chooseError?.let { error ->
                    item { LunchText(text = errorToast(error), role = LunchTextRole.Caption, color = colors.danger) }
                }
                itemsIndexed(proposals.value, key = { _, p -> p.restaurant.placeId }) { index, proposal ->
                    ProposalCard(
                        restaurant = proposal.restaurant.toView(),
                        index = index,
                        onChoose = { viewModel.choose(proposal.restaurant) },
                        choosing = state.choosingPlaceId == proposal.restaurant.placeId,
                    )
                }
            }
        }
    }
}
