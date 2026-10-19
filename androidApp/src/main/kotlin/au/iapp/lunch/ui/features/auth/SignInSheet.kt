package au.iapp.lunch.ui.features.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.clickable
import androidx.compose.ui.Alignment
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.app.LunchConfig
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.SheetContainer
import au.iapp.lunch.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInSheet(onDismiss: () -> Unit, modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val context = LocalContext.current
    val tokens = remember(app, context) {
        if (app.signInTokens === UnavailableSignInTokenProvider) GoogleSignInTokenProvider(context, LunchConfig.current.googleServerClientId)
        else app.signInTokens
    }
    val viewModel: SignInViewModel = viewModel { SignInViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors
    // These deliberately aren't saveable: credentials must not enter Android's saved-state Bundle.
    var password by remember { mutableStateOf("") }
    var confirmation by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    LaunchedEffect(state.emailStep) { password = ""; confirmation = ""; code = "" }
    LaunchedEffect(state.isSignedIn) {
        if (state.isSignedIn) { password = ""; confirmation = ""; code = ""; onDismiss() }
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = colors.surface, dragHandle = null, modifier = modifier) {
        SheetContainer(title = stringResource(R.string.profile_signin_title)) {
            Column(modifier = Modifier.verticalScroll(rememberScrollState()).imePadding(), verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
                if (state.emailStep == EmailAuthStep.SignIn) {
                    LunchText(text = stringResource(R.string.profile_signin_body), role = LunchTextRole.Body, color = colors.textSecondary)
                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Image(painterResource(R.drawable.google_sign_in), contentDescription = "Sign in with Google",
                            modifier = Modifier.size(width = 216.dp, height = 48.dp).clip(RoundedCornerShape(50))
                                .clickable(enabled = !state.isBusy, role = Role.Button) { viewModel.signIn(SignInProvider.Google, tokens) }
                                .testTag("sign_in_google"), contentScale = ContentScale.Fit)
                    }
                    if (state.busyProvider != null) LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                    HorizontalDivider()
                }
                val title = when (state.emailStep) {
                    EmailAuthStep.SignIn -> "Sign in with email"
                    EmailAuthStep.Register -> "Create your account"
                    EmailAuthStep.Verify -> "Verify your email"
                    EmailAuthStep.ForgotPassword -> "Forgot password?"
                    EmailAuthStep.ResetPassword -> "Choose a new password"
                }
                Text(title, color = colors.text)
                OutlinedTextField(value = state.email, onValueChange = viewModel::setEmail, label = { Text("Email address") },
                    singleLine = true, enabled = !state.isBusy && !state.needsCode,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email), modifier = Modifier.fillMaxWidth().testTag("auth_email"))
                if (state.needsCode) {
                    OutlinedTextField(value = code, onValueChange = { code = it }, label = { Text("Email verification code") },
                        singleLine = true, enabled = !state.isBusy, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                        modifier = Modifier.fillMaxWidth().testTag("auth_code"))
                }
                if (state.needsPassword) {
                    OutlinedTextField(value = password, onValueChange = { password = it },
                        label = { Text(if (state.needsNewPassword) "Password (at least 8 characters)" else "Password") },
                        singleLine = true, enabled = !state.isBusy, visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password), modifier = Modifier.fillMaxWidth().testTag("auth_password"))
                }
                if (state.needsNewPassword) {
                    OutlinedTextField(value = confirmation, onValueChange = { confirmation = it }, label = { Text("Confirm password") },
                        singleLine = true, enabled = !state.isBusy, visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password), modifier = Modifier.fillMaxWidth().testTag("auth_confirm_password"))
                }
                state.notice?.let { LunchText(it, role = LunchTextRole.Body, color = colors.textSecondary) }
                state.error?.let { LunchText(authErrorMessage(it), role = LunchTextRole.Caption, color = colors.danger, modifier = Modifier.testTag("auth_error")) }
                val action = when (state.emailStep) {
                    EmailAuthStep.SignIn -> "Sign in"
                    EmailAuthStep.Register -> "Create account"
                    EmailAuthStep.Verify -> "Verify email"
                    EmailAuthStep.ForgotPassword -> "Send reset code"
                    EmailAuthStep.ResetPassword -> "Reset password"
                }
                LunchButton(text = action, onClick = { viewModel.submitEmail(password, confirmation, code) }, enabled = !state.isBusy,
                    loading = state.emailBusy, modifier = Modifier.fillMaxWidth().testTag("auth_submit"))
                if (state.needsCode) TextButton(onClick = viewModel::resendCode, enabled = !state.isBusy) { Text("Resend code") }
                if (state.emailStep == EmailAuthStep.SignIn) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        TextButton(onClick = { viewModel.changeEmailStep(EmailAuthStep.Register) }, enabled = !state.isBusy) { Text("Create account") }
                        TextButton(onClick = { viewModel.changeEmailStep(EmailAuthStep.ForgotPassword) }, enabled = !state.isBusy) { Text("Forgot password?") }
                    }
                } else {
                    TextButton(onClick = { viewModel.changeEmailStep(EmailAuthStep.SignIn) }, enabled = !state.isBusy) { Text("Back to sign in") }
                }
            }
        }
    }
}
