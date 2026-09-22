/**
 * @file PreferencesScreen.kt
 * @description Screen 8 of design/screens.md: weekly budget, price level, distance, chains,
 * dietary needs and allergens, saved back through the shared user repository.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.preferences

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
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.features.shared.ChipGrid
import au.iapp.lunch.ui.features.shared.DietaryOptions
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.features.shared.lunchSliderColors
import au.iapp.lunch.ui.features.shared.lunchSwitchColors
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun PreferencesScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: PreferencesViewModel = viewModel { PreferencesViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors
    val savedText = stringResource(R.string.preferences_saved)

    ModalScreen(onBack = app::dismiss, modifier = modifier) {
        ScreenHeader(title = stringResource(R.string.preferences_title), onDismiss = app::dismiss)
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = TokenSpacing.page),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
        ) {
            Group(title = stringResource(R.string.preferences_section_budget)) {
                LunchText(text = stringResource(R.string.preferences_weekly, LunchFormat.currency(state.weeklyBudget)), role = LunchTextRole.Body)
                Slider(
                    value = state.weeklyBudget.toFloat(),
                    onValueChange = { viewModel.setWeeklyBudget(it.toDouble()) },
                    valueRange = PreferencesViewModel.BUDGET_MIN.toFloat()..PreferencesViewModel.BUDGET_MAX.toFloat(),
                    steps = ((PreferencesViewModel.BUDGET_MAX - PreferencesViewModel.BUDGET_MIN) / PreferencesViewModel.BUDGET_STEP).toInt() - 1,
                    colors = lunchSliderColors(),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    PreferencesViewModel.PRICE_LEVELS.forEach { level ->
                        Chip(text = "$".repeat(level), selected = state.budgetLevel == level, onClick = { viewModel.setBudgetLevel(level) })
                    }
                }
            }
            Group(title = stringResource(R.string.preferences_section_location)) {
                LunchText(text = stringResource(R.string.preferences_distance, LunchFormat.compact(state.maxTravelDistance)), role = LunchTextRole.Body)
                Slider(
                    value = state.maxTravelDistance.toFloat(),
                    onValueChange = { viewModel.setMaxTravelDistance(it.toDouble()) },
                    valueRange = PreferencesViewModel.DISTANCE_MIN.toFloat()..PreferencesViewModel.DISTANCE_MAX.toFloat(),
                    steps = (PreferencesViewModel.DISTANCE_MAX - PreferencesViewModel.DISTANCE_MIN).toInt() - 1,
                    colors = lunchSliderColors(),
                )
            }
            Group(title = stringResource(R.string.preferences_section_restaurant)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    LunchText(text = stringResource(R.string.profile_pref_chains), role = LunchTextRole.Body, modifier = Modifier.weight(1f))
                    Switch(checked = state.includeChains, onCheckedChange = viewModel::setIncludeChains, colors = lunchSwitchColors())
                }
            }
            Group(title = stringResource(R.string.preferences_section_dietary)) {
                ChipGrid(
                    options = DietaryOptions.dietary.map { it.key to stringResource(it.labelRes) },
                    selected = state.dietary,
                    onToggle = viewModel::toggleDietary,
                )
            }
            Group(title = stringResource(R.string.preferences_section_allergens)) {
                ChipGrid(
                    options = DietaryOptions.allergens.map { it.key to stringResource(it.labelRes) },
                    selected = state.allergens,
                    onToggle = viewModel::toggleAllergen,
                )
            }
            state.error?.let { LunchText(text = errorToast(it), role = LunchTextRole.Caption, color = colors.danger) }
        }
        LunchButton(
            text = stringResource(R.string.action_save),
            onClick = {
                viewModel.save {
                    app.showToast(savedText)
                    app.dismiss()
                }
            },
            loading = state.isSaving,
            modifier = Modifier
                .fillMaxWidth()
                .padding(TokenSpacing.page),
        )
    }
}

@Composable
private fun Group(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        SectionTitle(text = title)
        LunchCard(modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) { content() }
        }
    }
}
