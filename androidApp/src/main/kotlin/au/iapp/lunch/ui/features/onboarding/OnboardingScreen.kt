/**
 * @file OnboardingScreen.kt
 * @description Screen 1 of design/screens.md: progress bar, step card and bottom CTA across the
 * five onboarding steps. Step 5 asks for location, then creates the user.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.features.onboarding

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import au.iapp.lunch.R
import au.iapp.lunch.app.LocalAppEnvironment
import au.iapp.lunch.ui.components.Chip
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchCard
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.features.shared.ChipGrid
import au.iapp.lunch.ui.features.shared.DietaryOptions
import au.iapp.lunch.ui.features.shared.LunchFormat
import au.iapp.lunch.ui.features.shared.StepProgress
import au.iapp.lunch.ui.features.shared.errorToast
import au.iapp.lunch.ui.features.shared.rememberLocationPermission
import au.iapp.lunch.ui.features.shared.lunchSliderColors
import au.iapp.lunch.ui.features.shared.lunchSwitchColors
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

object OnboardingDefaults {
    const val NAME_TEST_TAG = "onboarding_name_field"
}

@Composable
fun OnboardingScreen(modifier: Modifier = Modifier) {
    val app = LocalAppEnvironment.current
    val viewModel: OnboardingViewModel = viewModel { OnboardingViewModel(app) }
    val state by viewModel.state.collectAsStateWithLifecycle()
    val colors = LunchTheme.colors
    val permission = rememberLocationPermission(onResult = { viewModel.finish() })

    BackHandler(enabled = state.step > 1) { viewModel.back() }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(colors.ground)
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .imePadding()
            .padding(horizontal = TokenSpacing.pageWide),
    ) {
        StepProgress(
            progress = state.progress,
            eyebrow = stringResource(R.string.onboarding_step, state.step),
            title = stepEyebrow(state.step),
            modifier = Modifier.padding(top = TokenSpacing.lg, bottom = TokenSpacing.lg),
        )
        AnimatedContent(
            targetState = state.step,
            transitionSpec = { fadeIn(LunchMotion.fadeIn()) togetherWith fadeOut(LunchMotion.state()) },
            label = "onboardingStep",
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
        ) { step ->
            // wrapContentHeight keeps the card around its content: the animated slot is a fixed
            // height and would otherwise stretch the card to the footer.
            LunchCard(modifier = Modifier.fillMaxWidth().wrapContentHeight(Alignment.Top)) {
                when (step) {
                    1 -> WelcomeStep()
                    2 -> NameStep(state.name, viewModel::setName)
                    3 -> BudgetStep(state, viewModel)
                    4 -> DietaryStep(state.dietary, viewModel::toggleDietary)
                    else -> LocationStep()
                }
            }
        }
        state.error?.let { error ->
            LunchText(
                text = errorToast(error),
                role = LunchTextRole.Caption,
                color = colors.danger,
                modifier = Modifier.padding(top = TokenSpacing.sm),
            )
        }
        Column(
            modifier = Modifier.padding(vertical = TokenSpacing.md),
            verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
        ) {
            when (state.step) {
                OnboardingViewModel.STEP_COUNT -> {
                    LunchButton(
                        text = stringResource(if (permission.isGranted) R.string.onboarding_finish_cta else R.string.onboarding_step5_cta),
                        onClick = { if (permission.isGranted) viewModel.finish() else permission.request() },
                        loading = state.isSubmitting,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    LunchButton(
                        text = stringResource(R.string.onboarding_step5_skip),
                        onClick = { viewModel.finish() },
                        style = LunchButtonStyle.Text,
                        enabled = !state.isSubmitting,
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
                else -> LunchButton(
                    text = stringResource(if (state.step == 1) R.string.onboarding_step1_cta else R.string.action_continue),
                    onClick = viewModel::next,
                    enabled = state.canContinue,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

@Composable
private fun stepEyebrow(step: Int): String = stringResource(
    when (step) {
        1 -> R.string.onboarding_step1_eyebrow
        2 -> R.string.onboarding_step2_eyebrow
        3 -> R.string.onboarding_step3_eyebrow
        4 -> R.string.onboarding_step4_eyebrow
        else -> R.string.onboarding_step5_eyebrow
    },
)

@Composable
private fun StepIntro(icon: LunchIcon, title: String, body: String) {
    val colors = LunchTheme.colors
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        Box(
            modifier = Modifier
                .size(TokenSize.touchTarget * 2)
                .background(colors.primarySoft, LunchTheme.shapes.chip),
            contentAlignment = Alignment.Center,
        ) {
            LunchIconView(icon = icon, size = TokenSize.iconDefault + TokenSpacing.sm, filled = true, tint = colors.primary)
        }
        LunchText(text = title, role = LunchTextRole.Title, textAlign = TextAlign.Center)
        LunchText(text = body, role = LunchTextRole.Body, color = colors.textSecondary, textAlign = TextAlign.Center)
    }
}

@Composable
private fun WelcomeStep() {
    val colors = LunchTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg), horizontalAlignment = Alignment.CenterHorizontally) {
        StepIntro(LunchIcon.Restaurant, stringResource(R.string.onboarding_step1_title), stringResource(R.string.onboarding_step1_body))
        // Image placeholder per the spec: a soft block until artwork lands.
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(TokenSize.heroButton / 2)
                // primarySoft, not surface: the card is already surface and the block would vanish.
                .background(colors.primarySoft, LunchTheme.shapes.container),
            contentAlignment = Alignment.Center,
        ) {
            LunchIconView(icon = LunchIcon.LocalCafe, tint = colors.primary, size = TokenSize.iconDefault * 2)
        }
    }
}

@Composable
private fun NameStep(name: String, onNameChange: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.lg)) {
        StepIntro(LunchIcon.Person, stringResource(R.string.onboarding_step2_title), "")
        LunchTextField(
            value = name,
            onValueChange = onNameChange,
            placeholder = stringResource(R.string.onboarding_step2_placeholder),
            modifier = Modifier
                .fillMaxWidth()
                .testTag(OnboardingDefaults.NAME_TEST_TAG),
        )
    }
}

@Composable
private fun BudgetStep(state: OnboardingUiState, viewModel: OnboardingViewModel) {
    val colors = LunchTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        LunchText(text = stringResource(R.string.onboarding_step3_title), role = LunchTextRole.Heading)
        LunchText(text = stringResource(R.string.onboarding_step3_body), role = LunchTextRole.BodySmall, color = colors.textSecondary)
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            OnboardingViewModel.PRICE_LEVELS.forEach { level ->
                Chip(text = "$".repeat(level), selected = state.budgetLevel == level, onClick = { viewModel.setBudgetLevel(level) })
            }
        }
        LunchText(
            text = stringResource(R.string.onboarding_step3_distance, LunchFormat.compact(state.maxTravelDistance)),
            role = LunchTextRole.Body,
        )
        Slider(
            value = state.maxTravelDistance.toFloat(),
            onValueChange = { viewModel.setMaxTravelDistance(it.toDouble()) },
            valueRange = OnboardingViewModel.DISTANCE_MIN.toFloat()..OnboardingViewModel.DISTANCE_MAX.toFloat(),
            steps = (OnboardingViewModel.DISTANCE_MAX - OnboardingViewModel.DISTANCE_MIN).toInt() - 1,
            colors = lunchSliderColors(),
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                LunchText(text = stringResource(R.string.onboarding_step3_chains), role = LunchTextRole.Body)
                LunchText(text = stringResource(R.string.onboarding_step3_chains_hint), role = LunchTextRole.Caption, color = colors.textSecondary)
            }
            Switch(checked = state.includeChains, onCheckedChange = viewModel::setIncludeChains, colors = lunchSwitchColors())
        }
    }
}

@Composable
private fun DietaryStep(selected: Set<String>, onToggle: (String) -> Unit) {
    val colors = LunchTheme.colors
    Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
        LunchText(text = stringResource(R.string.onboarding_step4_title), role = LunchTextRole.Heading)
        LunchText(text = stringResource(R.string.onboarding_step4_body), role = LunchTextRole.BodySmall, color = colors.textSecondary)
        ChipGrid(
            options = (DietaryOptions.all + DietaryOptions.none).map { it.key to stringResource(it.labelRes) },
            selected = selected,
            onToggle = onToggle,
        )
    }
}

@Composable
private fun LocationStep() {
    StepIntro(LunchIcon.LocationOn, stringResource(R.string.onboarding_step5_title), stringResource(R.string.onboarding_step5_body))
}
