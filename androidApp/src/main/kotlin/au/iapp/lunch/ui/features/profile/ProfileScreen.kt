/**
 * @file ProfileScreen.kt
 * @description Screen 7 of design/screens.md: identity header, preference rows, the Pro section,
 * settings links and the account section with sign-in, export and delete.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.profile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.InitialAvatar
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.ProBadge
import au.iapp.lunch.ui.components.Renewal
import au.iapp.lunch.ui.components.SubscriptionRow
import au.iapp.lunch.ui.components.UpsellRow
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.SectionTitle
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.navigation.AppRoute
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

@Composable
fun ProfileScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: ProfileViewModel = viewModel { ProfileViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val events by viewModel.events.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val colors = LunchTheme.colors
    val restoredText = stringResource(R.string.paywall_restored)
    val nothingText = stringResource(R.string.paywall_restore_nothing)
    val exportSubject = stringResource(R.string.profile_export_subject)
    val failedText = events.firstOrNull().let { if (it is ProfileEvent.Failed) errorToast(it.error) else null }

    LaunchedEffect(events) {
        when (val event = events.firstOrNull() ?: return@LaunchedEffect) {
            ProfileEvent.Restored -> app.showToast(restoredText)
            ProfileEvent.NothingToRestore -> app.showToast(nothingText)
            is ProfileEvent.Export -> Intents.share(context, event.json, exportSubject)
            is ProfileEvent.Failed -> failedText?.let(app::showToast)
        }
        viewModel.consumeEvent()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = TokenSpacing.page, vertical = TokenSpacing.md),
        verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg),
    ) {
        LunchText(text = stringResource(R.string.profile_title), role = LunchTextRole.Title)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            InitialAvatar(name = state.user?.name.orEmpty(), size = TokenSize.touchTarget + TokenSpacing.md)
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                LunchText(text = state.user?.name.orEmpty(), role = LunchTextRole.Heading)
                state.session?.let { session ->
                    LunchText(text = stringResource(R.string.profile_signed_in_as, session.email ?: session.displayName ?: session.userId), role = LunchTextRole.Caption, color = colors.textSecondary)
                }
            }
            if (state.isPro) ProBadge()
        }

        val prefs = state.user?.preferences
        Section(title = stringResource(R.string.profile_section_preferences)) {
            SettingRow(label = stringResource(R.string.profile_pref_budget), value = "$".repeat(prefs?.budgetLevel ?: 2), onClick = { app.present(AppRoute.Preferences) })
            SettingRow(label = stringResource(R.string.profile_pref_distance), value = LunchFormat.kilometres(prefs?.maxTravelDistance ?: 0.0), onClick = { app.present(AppRoute.Preferences) })
            SettingRow(
                label = stringResource(R.string.profile_pref_chains),
                value = stringResource(if (prefs?.includeChains != false) R.string.profile_chains_on else R.string.profile_chains_off),
                onClick = { app.present(AppRoute.Preferences) },
            )
        }

        Section(title = stringResource(R.string.profile_section_pro)) {
            if (state.isPro) {
                val planName = stringResource(if (state.plan == ProfilePlan.Yearly) R.string.profile_plan_yearly else R.string.profile_plan_monthly)
                SubscriptionRow(
                    planName = planName,
                    renewal = if (state.status.willRenew) Renewal.Renews else Renewal.Ends,
                    date = state.status.expiresAtEpochSeconds?.let(LunchFormat::day).orEmpty(),
                    onManage = { Intents.openUrl(context, state.status.managementUrl ?: ProfileViewModel.PLAY_SUBSCRIPTIONS_URL) },
                )
            } else {
                UpsellRow(
                    title = stringResource(R.string.profile_pro_free_title),
                    body = stringResource(R.string.profile_pro_free_body),
                    ctaLabel = stringResource(R.string.profile_pro_free_cta),
                    onCta = { app.present(AppRoute.Paywall) },
                )
            }
            LunchButton(text = stringResource(R.string.profile_pro_restore), onClick = viewModel::restore, style = LunchButtonStyle.Text, enabled = !state.isBusy)
        }

        Section(title = stringResource(R.string.profile_section_settings)) {
            SettingRow(label = stringResource(R.string.profile_settings_edit), onClick = { app.present(AppRoute.Preferences) })
            SettingRow(label = stringResource(R.string.profile_settings_notifications), onClick = { Intents.openAppSettings(context) })
            SettingRow(label = stringResource(R.string.profile_settings_privacy), onClick = { app.present(AppRoute.Privacy) })
            SettingRow(label = stringResource(R.string.profile_settings_help), onClick = { app.present(AppRoute.Help) })
        }

        Section(title = stringResource(R.string.profile_section_account)) {
            if (state.session == null) {
                LunchText(text = stringResource(R.string.profile_signin_title), role = LunchTextRole.Heading)
                LunchText(text = stringResource(R.string.profile_signin_body), role = LunchTextRole.BodySmall, color = colors.textSecondary)
                LunchButton(text = stringResource(R.string.profile_signin_apple), onClick = { app.present(AppRoute.SignIn) }, icon = LunchIcon.Person, modifier = Modifier.fillMaxWidth())
                LunchButton(text = stringResource(R.string.profile_signin_google), onClick = { app.present(AppRoute.SignIn) }, icon = LunchIcon.Person, style = LunchButtonStyle.Secondary, modifier = Modifier.fillMaxWidth())
            } else {
                LunchButton(text = stringResource(R.string.profile_export), onClick = viewModel::export, icon = LunchIcon.Share, style = LunchButtonStyle.Secondary, enabled = !state.isBusy, modifier = Modifier.fillMaxWidth())
                LunchButton(text = stringResource(R.string.profile_signout), onClick = viewModel::signOut, style = LunchButtonStyle.Text, enabled = !state.isBusy, modifier = Modifier.fillMaxWidth())
                LunchButton(text = stringResource(R.string.profile_delete_title), onClick = viewModel::askDelete, style = LunchButtonStyle.Text, enabled = !state.isBusy, modifier = Modifier.fillMaxWidth())
            }
        }
    }

    if (state.showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = viewModel::cancelDelete,
            title = { LunchText(text = stringResource(R.string.profile_delete_title), role = LunchTextRole.Heading) },
            text = { LunchText(text = stringResource(R.string.profile_delete_body), role = LunchTextRole.Body) },
            confirmButton = {
                TextButton(onClick = viewModel::deleteAccount) { LunchText(text = stringResource(R.string.profile_delete_confirm), role = LunchTextRole.Button, color = colors.danger) }
            },
            dismissButton = {
                TextButton(onClick = viewModel::cancelDelete) { LunchText(text = stringResource(R.string.action_cancel), role = LunchTextRole.Button) }
            },
            containerColor = colors.surface,
        )
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        SectionTitle(text = title)
        LunchCard(modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) { content() }
        }
    }
}

@Composable
private fun SettingRow(label: String, onClick: () -> Unit, value: String? = null) {
    val colors = LunchTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = TokenSize.touchTarget)
            .clickable(onClick = onClick),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        LunchText(text = label, role = LunchTextRole.Body, modifier = Modifier.weight(1f))
        value?.let { LunchText(text = it, role = LunchTextRole.BodySmall, color = colors.textSecondary) }
        LunchIconView(icon = LunchIcon.ChevronRight, tint = colors.textSecondary)
    }
}
