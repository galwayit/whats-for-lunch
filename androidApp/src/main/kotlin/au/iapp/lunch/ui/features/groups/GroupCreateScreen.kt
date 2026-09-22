/**
 * @file GroupCreateScreen.kt
 * @description Screen 13 of design/screens.md: create a lunch group (Pro only) with a name,
 * date and time, current-location area and radius, then propose places.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.groups

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZoneOffset

object GroupCreateDefaults {
    const val NAME_TEST_TAG = "group_name_field"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupCreateScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: GroupCreateViewModel = viewModel { GroupCreateViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors
    val zone = remember(app) { ZoneId.of(app.clock.timeZoneId()) }
    var showDate by remember { mutableStateOf(false) }
    var showTime by remember { mutableStateOf(false) }
    val scheduled = remember(state.scheduledAtEpochSeconds) { Instant.ofEpochSecond(state.scheduledAtEpochSeconds).atZone(zone) }

    ModalScreen(onBack = app::dismiss, modifier = modifier.imePadding()) {
        ScreenHeader(title = stringResource(R.string.group_create_title), onDismiss = app::dismiss)
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = TokenSpacing.page),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
        ) {
            if (state.showHostGate) {
                UpsellRow(
                    title = stringResource(R.string.gate_host_title),
                    body = stringResource(R.string.gate_host_body),
                    ctaLabel = stringResource(R.string.gate_host_cta),
                    onCta = { app.present(AppRoute.Paywall) },
                )
            }
            LunchTextField(
                value = state.name,
                onValueChange = viewModel::setName,
                placeholder = stringResource(R.string.group_create_name_placeholder),
                leadingIcon = LunchIcon.Group,
                enabled = !state.showHostGate,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(GroupCreateDefaults.NAME_TEST_TAG),
            )
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                SectionTitle(text = stringResource(R.string.group_create_when))
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    Chip(text = LunchFormat.day(state.scheduledAtEpochSeconds), selected = false, onClick = { showDate = true }, leadingIcon = LunchIcon.CalendarToday)
                    Chip(text = LunchFormat.time(state.scheduledAtEpochSeconds), selected = false, onClick = { showTime = true }, leadingIcon = LunchIcon.Schedule)
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                SectionTitle(text = stringResource(R.string.group_create_where))
                LunchButton(
                    text = stringResource(if (state.isLocating) R.string.group_create_locating else R.string.group_create_current_location),
                    onClick = viewModel::useCurrentLocation,
                    icon = LunchIcon.NearMe,
                    style = LunchButtonStyle.Secondary,
                    loading = state.isLocating,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                SectionTitle(text = stringResource(R.string.group_create_radius))
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    GroupCreateViewModel.RADIUS_OPTIONS_KM.forEach { km ->
                        Chip(text = stringResource(R.string.group_create_radius_chip, km.toInt()), selected = state.radiusKm == km, onClick = { viewModel.setRadius(km) })
                    }
                }
            }
            state.error?.let { LunchText(text = errorToast(it), role = LunchTextRole.Caption, color = colors.danger) }
        }
        LunchButton(
            text = stringResource(R.string.group_create_propose),
            onClick = viewModel::create,
            icon = LunchIcon.AutoAwesome,
            enabled = state.canCreate,
            loading = state.isCreating,
            modifier = Modifier
                .fillMaxWidth()
                .padding(TokenSpacing.page),
        )
    }

    if (showDate) {
        val pickerState = rememberDatePickerState(initialSelectedDateMillis = scheduled.toLocalDate().atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli())
        DatePickerDialog(
            onDismissRequest = { showDate = false },
            confirmButton = {
                TextButton(onClick = {
                    pickerState.selectedDateMillis?.let { millis ->
                        val date = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()
                        viewModel.setScheduledAt(date.atTime(LocalTime.from(scheduled)).atZone(zone).toEpochSecond())
                    }
                    showDate = false
                }) { LunchText(text = stringResource(R.string.action_done), role = LunchTextRole.Button) }
            },
            dismissButton = { TextButton(onClick = { showDate = false }) { LunchText(text = stringResource(R.string.action_cancel), role = LunchTextRole.Button) } },
        ) { DatePicker(state = pickerState) }
    }
    if (showTime) {
        val timeState = rememberTimePickerState(initialHour = scheduled.hour, initialMinute = scheduled.minute)
        AlertDialog(
            onDismissRequest = { showTime = false },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.setScheduledAt(scheduled.toLocalDate().atTime(timeState.hour, timeState.minute).atZone(zone).toEpochSecond())
                    showTime = false
                }) { LunchText(text = stringResource(R.string.action_done), role = LunchTextRole.Button) }
            },
            dismissButton = { TextButton(onClick = { showTime = false }) { LunchText(text = stringResource(R.string.action_cancel), role = LunchTextRole.Button) } },
            text = { TimePicker(state = timeState) },
            containerColor = colors.surface,
        )
    }
}
