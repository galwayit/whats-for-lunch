/**
 * @file SignInSheet.kt
 * @description Screen 12 of design/screens.md: the sign-in bottom sheet with Apple and Google.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.core.model.CoreError
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.SheetContainer
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSpacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInSheet(onDismiss: () -> Unit, modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: SignInViewModel = viewModel { SignInViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors

    LaunchedEffect(state.isSignedIn) { if (state.isSignedIn) onDismiss() }

    // SheetContainer draws the handle, so the Material one is turned off to avoid two of them.
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = colors.surface, dragHandle = null, modifier = modifier) {
        SheetContainer(title = stringResource(R.string.profile_signin_title)) {
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
                LunchText(text = stringResource(R.string.profile_signin_body), role = LunchTextRole.Body, color = colors.textSecondary)
                LunchButton(
                    text = stringResource(R.string.profile_signin_apple),
                    onClick = { viewModel.signIn(SignInProvider.Apple) },
                    icon = LunchIcon.Person,
                    enabled = !state.isBusy,
                    loading = state.busyProvider == SignInProvider.Apple,
                    modifier = Modifier.fillMaxWidth(),
                )
                LunchButton(
                    text = stringResource(R.string.profile_signin_google),
                    onClick = { viewModel.signIn(SignInProvider.Google) },
                    icon = LunchIcon.Person,
                    style = LunchButtonStyle.Secondary,
                    enabled = !state.isBusy,
                    loading = state.busyProvider == SignInProvider.Google,
                    modifier = Modifier.fillMaxWidth(),
                )
                state.error?.let { error ->
                    val text = if (error is CoreError.Service && error.code == UnavailableSignInTokenProvider.CODE) {
                        stringResource(R.string.signin_unavailable)
                    } else {
                        errorToast(error)
                    }
                    LunchText(text = text, role = LunchTextRole.Caption, color = colors.danger)
                }
            }
        }
    }
}
