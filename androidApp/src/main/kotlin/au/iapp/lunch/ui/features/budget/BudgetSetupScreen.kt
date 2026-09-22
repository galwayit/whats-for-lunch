/**
 * @file BudgetSetupScreen.kt
 * @description Screen 6 of design/screens.md: three-step budget setup with the amount slider,
 * experience categories and the celebrations switch.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.budget

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.features.shared.ChipGrid
import au.iapp.lunch.ui.features.shared.HeaderDismiss
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.StepProgress
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.features.shared.lunchSliderColors
import au.iapp.lunch.ui.features.shared.lunchSwitchColors
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun BudgetSetupScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: BudgetSetupViewModel = viewModel { BudgetSetupViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors
    val onBack = { if (state.step > 1) viewModel.back() else app.dismiss() }

    ModalScreen(onBack = onBack, modifier = modifier) {
        ScreenHeader(
            title = stringResource(R.string.budget_title),
            dismiss = if (state.step > 1) HeaderDismiss.Back else HeaderDismiss.Close,
            onDismiss = onBack,
        )
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = TokenSpacing.pageWide),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
        ) {
            StepProgress(
                progress = state.progress,
                eyebrow = stringResource(R.string.budget_step, state.step),
                title = stringResource(
                    when (state.step) {
                        1 -> R.string.budget_step1_title
                        2 -> R.string.budget_step2_title
                        else -> R.string.budget_step3_title
                    },
                ),
            )
            LunchCard(modifier = Modifier.fillMaxWidth()) {
                when (state.step) {
                    1 -> AmountStep(state, viewModel)
                    2 -> ChipGrid(
                        options = state.categories.map { it.id to it.name },
                        selected = state.selectedCategoryIds,
                        onToggle = viewModel::toggleCategory,
                    )
                    else -> Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
                        LunchText(text = stringResource(R.string.budget_step3_body), role = LunchTextRole.Body, color = colors.textSecondary)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            LunchText(text = stringResource(R.string.budget_celebrations), role = LunchTextRole.Body, modifier = Modifier.weight(1f))
                            Switch(checked = state.celebrations, onCheckedChange = viewModel::setCelebrations, colors = lunchSwitchColors())
                        }
                    }
                }
            }
            state.error?.let { LunchText(text = errorToast(it), role = LunchTextRole.Caption, color = colors.danger) }
        }
        Column(modifier = Modifier.padding(TokenSpacing.pageWide), verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            if (state.step < BudgetSetupViewModel.STEP_COUNT) {
                LunchButton(text = stringResource(R.string.action_continue), onClick = viewModel::next, modifier = Modifier.fillMaxWidth())
            } else {
                LunchButton(
                    text = stringResource(R.string.budget_finish),
                    onClick = { viewModel.save(onSaved = app::dismiss) },
                    loading = state.isSaving,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (state.step > 1) {
                LunchButton(text = stringResource(R.string.action_back), onClick = viewModel::back, style = LunchButtonStyle.Text, modifier = Modifier.fillMaxWidth())
            }
        }
    }
}

@Composable
private fun AmountStep(state: BudgetSetupUiState, viewModel: BudgetSetupViewModel) {
    val colors = LunchTheme.colors
    Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        // One amount only: the Display carries it, and the step title already says "each week".
        LunchText(text = stringResource(R.string.budget_per_week, LunchFormat.currency(state.weeklyBudget)), role = LunchTextRole.Display, textAlign = TextAlign.Center)
        Slider(
            value = state.weeklyBudget.toFloat(),
            onValueChange = { viewModel.setWeeklyBudget(it.toDouble()) },
            valueRange = BudgetSetupViewModel.MIN.toFloat()..BudgetSetupViewModel.MAX.toFloat(),
            steps = ((BudgetSetupViewModel.MAX - BudgetSetupViewModel.MIN) / BudgetSetupViewModel.STEP).toInt() - 1,
            colors = lunchSliderColors(),
        )
        LunchText(text = stringResource(R.string.budget_target_experiences, state.targetExperiences), role = LunchTextRole.Caption, color = colors.textSecondary)
    }
}
