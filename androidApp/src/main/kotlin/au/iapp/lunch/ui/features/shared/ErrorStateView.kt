/**
 * @file ErrorStateView.kt
 * @description Renders a [CoreError] as the offline or service-problem empty state with a retry
 * action. Mirrors `ErrorStateView` in iosApp/.../Shared/LoadState.swift.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.shared

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import au.iapp.lunch.R
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.ui.components.EmptyState
import au.iapp.lunch.ui.components.EmptyStateVariant

@Composable
fun ErrorStateView(error: CoreError, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    val offline = error is CoreError.Offline
    EmptyState(
        variant = if (offline) EmptyStateVariant.Offline else EmptyStateVariant.ServiceProblem,
        title = stringResource(if (offline) R.string.error_offline_title else R.string.error_service_title),
        message = stringResource(if (offline) R.string.error_offline_body else R.string.error_service_body),
        actionLabel = stringResource(R.string.action_retry),
        onAction = onRetry,
        modifier = modifier,
    )
}

/** The short toast text for a failed action. */
@Composable
fun errorToast(error: CoreError): String =
    stringResource(if (error is CoreError.Offline) R.string.error_offline_title else R.string.error_service_title)

/** Keep AI availability separate from subscription gates and raw provider diagnostics. */
@Composable
fun AiErrorStateView(error: CoreError, onRetry: () -> Unit, modifier: Modifier = Modifier) {
    if (error is CoreError.Offline) {
        ErrorStateView(error, onRetry, modifier)
        return
    }
    val code = (error as? CoreError.Service)?.code
    val title = when (code) {
        "NO_CANDIDATES" -> R.string.ai_no_matches_title
        "RATE_LIMITED" -> R.string.ai_busy_title
        else -> R.string.ai_unavailable_title
    }
    val message = when (code) {
        "NO_CANDIDATES" -> R.string.ai_no_matches_body
        "RATE_LIMITED" -> R.string.ai_busy_body
        else -> R.string.ai_unavailable_body
    }
    EmptyState(
        variant = if (code == "NO_CANDIDATES") EmptyStateVariant.NothingHere else EmptyStateVariant.ServiceProblem,
        title = stringResource(title),
        message = stringResource(message),
        actionLabel = stringResource(R.string.action_retry),
        onAction = onRetry,
        modifier = modifier,
    )
}
