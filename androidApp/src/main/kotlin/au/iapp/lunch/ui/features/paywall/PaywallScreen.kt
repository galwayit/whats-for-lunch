/**
 * @file PaywallScreen.kt
 * @description Screen 11 of design/screens.md: the Lunch Pro paywall over the shared
 * `PaywallView`, with the success state after purchase or restore.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.paywall

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.AILoading
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.PaywallView
import au.iapp.lunch.ui.components.ProBadge
import au.iapp.lunch.ui.features.shared.ErrorStateView
import au.iapp.lunch.ui.features.shared.HeaderDismiss
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.features.shared.LoadState
import au.iapp.lunch.ui.features.shared.ModalScreen
import au.iapp.lunch.ui.features.shared.ScreenHeader
import au.iapp.lunch.ui.features.shared.toView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

object PaywallLinks {
    /** Pages served from backend/web; confirm before release. */
    const val TERMS = "https://lunch.iapp.au/terms"
    const val PRIVACY = "https://lunch.iapp.au/privacy"
}

@Composable
fun PaywallScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: PaywallViewModel = viewModel { PaywallViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val colors = LunchTheme.colors
    val nothingText = stringResource(R.string.paywall_restore_nothing)

    LaunchedEffect(state.restoredNothing) {
        if (state.restoredNothing) {
            app.showToast(nothingText)
            viewModel.consumeRestoredNothing()
        }
    }

    ModalScreen(onBack = app::dismiss, modifier = modifier) {
        // The page carries its own "Lunch Pro" title, so the header is just the close control.
        ScreenHeader(title = "", dismiss = HeaderDismiss.Close, onDismiss = app::dismiss)
        if (state.isPro) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(TokenSpacing.pageWide),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(TokenSpacing.md, Alignment.CenterVertically),
            ) {
                ProBadge()
                LunchText(text = stringResource(R.string.paywall_success_title), role = LunchTextRole.Title, textAlign = TextAlign.Center)
                LunchText(text = stringResource(R.string.paywall_success_body), role = LunchTextRole.Body, color = colors.textSecondary, textAlign = TextAlign.Center)
                LunchButton(text = stringResource(R.string.action_done), onClick = app::dismiss, modifier = Modifier.fillMaxWidth())
            }
            return@ModalScreen
        }
        when (val packages = state.packages) {
            LoadState.Idle, LoadState.Loading -> AILoading(title = stringResource(R.string.a11y_loading), modifier = Modifier.fillMaxWidth().padding(TokenSpacing.page))
            is LoadState.Failed -> ErrorStateView(error = packages.error, onRetry = viewModel::load, modifier = Modifier.fillMaxWidth())
            is LoadState.Loaded -> Column(modifier = Modifier.weight(1f)) {
                PaywallView(
                    packages = packages.value.map { it.toView() },
                    selectedIdentifier = state.selectedIdentifier,
                    onSelect = { view -> packages.value.firstOrNull { it.identifier == view.identifier }?.let(viewModel::select) },
                    onSubscribe = viewModel::purchase,
                    onRestore = viewModel::restore,
                    onTerms = { Intents.openUrl(context, PaywallLinks.TERMS) },
                    onPrivacy = { Intents.openUrl(context, PaywallLinks.PRIVACY) },
                    purchasing = state.isPurchasing || state.isRestoring,
                    modifier = Modifier.weight(1f),
                )
                state.purchaseError?.let {
                    LunchText(text = stringResource(purchaseErrorMessage(it)), role = LunchTextRole.Caption, color = colors.danger, modifier = Modifier.padding(horizontal = TokenSpacing.page, vertical = TokenSpacing.sm))
                }
            }
        }
    }
}
