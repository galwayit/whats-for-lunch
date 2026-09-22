/**
 * @file MealLogCard.kt
 * @description The quick meal log card: meal-type chips, place field with suggestions, cost
 * field with the budget impact line, date picker, notes and the log action.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.track

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import au.iapp.lunch.R
import au.iapp.lunch.core.model.ImpactLevel
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.CurrencyField
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZoneOffset

object MealLogDefaults {
    const val PLACE_TEST_TAG = "meal_place_field"
    const val COST_TEST_TAG = "meal_cost_field"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MealLogCard(state: TrackUiState, viewModel: TrackViewModel, modifier: Modifier = Modifier) {
    val colors = LunchTheme.colors
    val draft = state.draft
    var showDatePicker by remember { mutableStateOf(false) }

    LunchCard(modifier = modifier.fillMaxWidth()) {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            LunchText(text = stringResource(R.string.track_log_title), role = LunchTextRole.Heading)
            LunchText(text = stringResource(R.string.track_log_type), role = LunchTextRole.Label, color = colors.textSecondary)
            Row(modifier = Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                TrackViewModel.MEAL_TYPES.forEach { type ->
                    Chip(text = mealTypeLabel(type), selected = draft.mealType == type, onClick = { viewModel.setMealType(type) })
                }
            }
            LunchTextField(
                value = draft.restaurantName,
                onValueChange = viewModel::setPlace,
                placeholder = stringResource(R.string.track_log_place_placeholder),
                leadingIcon = LunchIcon.Restaurant,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(MealLogDefaults.PLACE_TEST_TAG),
            )
            val suggestions = state.suggestions.take(SUGGESTION_LIMIT)
            if (suggestions.isNotEmpty() && draft.restaurantName.isEmpty()) {
                Row(modifier = Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    suggestions.forEach { name -> Chip(text = name, selected = false, onClick = { viewModel.pickSuggestion(name) }) }
                }
            }
            CurrencyField(
                value = draft.cost,
                onValueChange = viewModel::setCost,
                supportingText = state.impact?.message,
                isError = state.impact?.exceedsCapacity == true,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(MealLogDefaults.COST_TEST_TAG),
            )
            state.impact?.let { impact ->
                val tone = when (impact.impactLevel) {
                    ImpactLevel.LOW, ImpactLevel.MODERATE -> colors.success
                    ImpactLevel.HIGH -> colors.warning
                    ImpactLevel.VERY_HIGH -> colors.danger
                }
                LunchText(text = stringResource(R.string.track_ring_remaining, LunchFormat.currency(impact.projectedRemaining)), role = LunchTextRole.Caption, color = tone)
            }
            Chip(
                text = stringResource(R.string.track_log_date_value, LunchFormat.day(draft.dateEpochSeconds)),
                selected = false,
                onClick = { showDatePicker = true },
                leadingIcon = LunchIcon.CalendarToday,
            )
            LunchTextField(
                value = draft.notes,
                onValueChange = viewModel::setNotes,
                placeholder = stringResource(R.string.track_log_notes_placeholder),
                modifier = Modifier.fillMaxWidth(),
            )
            state.logError?.let { LunchText(text = errorToast(it), role = LunchTextRole.Caption, color = colors.danger) }
            LunchButton(
                text = stringResource(R.string.action_log_this_meal),
                onClick = viewModel::log,
                enabled = draft.canLog,
                loading = state.isLogging,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }

    if (showDatePicker) {
        val zone = ZoneId.systemDefault()
        val current = Instant.ofEpochSecond(draft.dateEpochSeconds).atZone(zone)
        val pickerState = rememberDatePickerState(initialSelectedDateMillis = current.toLocalDate().atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli())
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    pickerState.selectedDateMillis?.let { millis ->
                        val date = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()
                        viewModel.setDate(date.atTime(LocalTime.from(current)).atZone(zone).toEpochSecond())
                    }
                    showDatePicker = false
                }) { LunchText(text = stringResource(R.string.action_done), role = LunchTextRole.Button) }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) { LunchText(text = stringResource(R.string.action_cancel), role = LunchTextRole.Button) }
            },
        ) {
            DatePicker(state = pickerState)
        }
    }
}

private const val SUGGESTION_LIMIT = 4
