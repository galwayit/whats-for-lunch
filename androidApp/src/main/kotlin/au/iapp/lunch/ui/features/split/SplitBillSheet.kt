/**
 * @file SplitBillSheet.kt
 * @description Screen 12 of design/screens.md: the "Split the bill" bottom sheet. Bill and
 * surcharge fields, one amount row per person (typing adjusts a row, the rest rebalance), the
 * total, inline engine errors, the device-only "Pay me at" field, and Share / Use my share.
 * Opened from the Track meal log card and from a hosted group's detail screen.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features.split

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.input.KeyboardType
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import au.iapp.lunch.R
import au.iapp.lunch.core.engine.BillSplitEngine
import au.iapp.lunch.ui.components.ComponentDefaults
import au.iapp.lunch.ui.components.CurrencyField
import au.iapp.lunch.ui.components.CurrencyFieldDefaults
import au.iapp.lunch.ui.components.LunchButton
import au.iapp.lunch.ui.components.LunchButtonStyle
import au.iapp.lunch.ui.components.LunchTextField
import au.iapp.lunch.ui.components.SheetContainer
import au.iapp.lunch.ui.features.shared.Intents
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/** Every `split.*` template the sheet formats, read once from strings.xml. */
@Composable
fun rememberSplitCopy(): SplitCopy = SplitCopy(
    you = stringResource(R.string.split_person_you),
    personNumbered = stringResource(R.string.split_person_n),
    total = stringResource(R.string.split_total),
    totalWithSurcharge = stringResource(R.string.split_total_surcharge),
    errorNoBill = stringResource(R.string.split_error_no_bill),
    errorNoPeople = stringResource(R.string.split_error_no_people),
    errorTooMany = stringResource(R.string.split_error_too_many),
    errorSurcharge = stringResource(R.string.split_error_surcharge),
    errorOver = stringResource(R.string.split_error_over),
    errorUnder = stringResource(R.string.split_error_under),
    placeFallback = stringResource(R.string.split_message_place_fallback),
    messageHeader = stringResource(R.string.split_message_header),
    messageLine = stringResource(R.string.split_message_line),
    messagePay = stringResource(R.string.split_message_pay),
    messageFooter = stringResource(R.string.split_message_footer),
    note = stringResource(R.string.split_note),
)

/**
 * @param onUseShare Receives my share and the `split.note` text; the host decides what to do.
 * @param isUsingShare Shows a spinner on "Use my share" while the host logs the meal.
 * @param hostError The host's own failure (e.g. logging the meal), shown above the buttons.
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalComposeUiApi::class)
@Composable
fun SplitBillSheet(
    viewModel: SplitBillViewModel,
    onDismiss: () -> Unit,
    onUseShare: (SplitShare) -> Unit,
    isUsingShare: Boolean = false,
    hostError: String? = null,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val copy = rememberSplitCopy()
    val context = LocalContext.current
    val colors = LunchTheme.colors

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        // With the keyboard up the tall sheet rises to the window top; stop it at the status bar.
        modifier = Modifier.statusBarsPadding(),
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = colors.surface,
        dragHandle = null,
    ) {
        SheetContainer(
            title = stringResource(R.string.split_title),
            modifier = Modifier
                // The sheet is its own window, so the root's resource-id exposure stops here.
                .semantics { testTagsAsResourceId = true }
                .verticalScroll(rememberScrollState()),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
                CurrencyField(
                    value = state.billText,
                    onValueChange = viewModel::setBill,
                    label = stringResource(R.string.split_bill_label),
                    placeholder = stringResource(R.string.split_bill_placeholder),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag(SplitBillDefaults.BILL_FIELD_TAG),
                )
                LunchTextField(
                    value = state.surchargeText,
                    // Same shape as money: digits with up to two decimals, e.g. "1.5".
                    onValueChange = { if (CurrencyFieldDefaults.isAcceptable(it)) viewModel.setSurcharge(it) },
                    label = stringResource(R.string.split_surcharge_label),
                    placeholder = stringResource(R.string.split_surcharge_placeholder),
                    supportingText = stringResource(R.string.split_surcharge_help),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag(SplitBillDefaults.SURCHARGE_FIELD_TAG),
                )
                PeopleHeader(state = state, onCountChange = viewModel::setPeopleCount)
                state.people.forEachIndexed { index, person ->
                    PersonRow(
                        index = index,
                        name = person.label(copy),
                        amount = state.amountText(index),
                        adjusted = state.isAdjusted(index),
                        onAmountChange = { viewModel.setAmount(index, it) },
                        onReset = { viewModel.reset(index) },
                    )
                }
                state.errorText(copy)?.let { LunchText(text = it, role = LunchTextRole.Caption, color = colors.danger) }
                state.totalText(copy)?.let { LunchText(text = it, role = LunchTextRole.Heading) }
                LunchTextField(
                    value = state.payId,
                    onValueChange = viewModel::setPayId,
                    label = stringResource(R.string.split_payid_label),
                    placeholder = stringResource(R.string.split_payid_placeholder),
                    supportingText = stringResource(R.string.split_payid_note),
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag(SplitBillDefaults.PAYID_FIELD_TAG),
                )
                hostError?.let { LunchText(text = it, role = LunchTextRole.Caption, color = colors.danger) }
                Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
                    LunchButton(
                        text = stringResource(R.string.split_share),
                        onClick = { state.shareMessage(copy)?.let { Intents.share(context, it) } },
                        style = LunchButtonStyle.Secondary,
                        icon = LunchIcon.Share,
                        enabled = state.canAct,
                        modifier = Modifier
                            .weight(1f)
                            .testTag(SplitBillDefaults.SHARE_BUTTON_TAG),
                    )
                    LunchButton(
                        text = stringResource(R.string.split_use_share),
                        onClick = { state.myShare(copy)?.let(onUseShare) },
                        enabled = state.canAct,
                        loading = isUsingShare,
                        modifier = Modifier
                            .weight(1f)
                            .testTag(SplitBillDefaults.USE_SHARE_BUTTON_TAG),
                    )
                }
            }
        }
    }
}

/** "PEOPLE", plus the 1-50 stepper when the sheet came from Track. */
@Composable
private fun PeopleHeader(state: SplitBillUiState, onCountChange: (Int) -> Unit) {
    val count = state.people.size
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (state.showsStepper) Modifier.testTag(SplitBillDefaults.PEOPLE_STEPPER_TAG) else Modifier),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
    ) {
        LunchText(
            text = stringResource(R.string.split_people_label),
            role = LunchTextRole.Caption,
            color = LunchTheme.colors.textSecondary,
            modifier = Modifier.weight(1f),
        )
        if (state.showsStepper) {
            StepperButton(
                glyph = stringResource(R.string.split_stepper_decrease),
                description = stringResource(R.string.a11y_split_fewer_people),
                enabled = count > 1,
                onClick = { onCountChange(count - 1) },
            )
            LunchText(text = count.toString(), role = LunchTextRole.Heading)
            StepperButton(
                glyph = stringResource(R.string.split_stepper_increase),
                description = stringResource(R.string.a11y_split_more_people),
                enabled = count < BillSplitEngine.MAX_PEOPLE,
                onClick = { onCountChange(count + 1) },
            )
        }
    }
}

@Composable
private fun StepperButton(glyph: String, description: String, enabled: Boolean, onClick: () -> Unit) {
    val colors = LunchTheme.colors
    val shape = LunchTheme.shapes.chip
    Box(
        modifier = Modifier
            .size(TokenSize.touchTarget)
            .clip(shape)
            .border(ComponentDefaults.hairlineWidth, colors.hairlineStrong, shape)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) {
        LunchText(text = glyph, role = LunchTextRole.Heading, color = if (enabled) colors.text else colors.textSecondary)
    }
}

@Composable
private fun PersonRow(
    index: Int,
    name: String,
    amount: String,
    adjusted: Boolean,
    onAmountChange: (String) -> Unit,
    onReset: () -> Unit,
) {
    val colors = LunchTheme.colors
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
            LunchText(text = name, role = LunchTextRole.Body, maxLines = 1)
            if (adjusted) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs)) {
                    LunchText(
                        text = stringResource(R.string.split_person_adjusted),
                        role = LunchTextRole.Caption,
                        color = colors.primary,
                        modifier = Modifier
                            .background(colors.primarySoft, LunchTheme.shapes.chip)
                            .padding(horizontal = TokenSpacing.sm, vertical = TokenSpacing.xs / 2),
                    )
                    LunchButton(
                        text = stringResource(R.string.split_person_reset),
                        onClick = onReset,
                        style = LunchButtonStyle.Text,
                        modifier = Modifier.testTag(SplitBillDefaults.resetTag(index)),
                    )
                }
            }
        }
        CurrencyField(
            value = amount,
            onValueChange = onAmountChange,
            placeholder = stringResource(R.string.split_bill_placeholder),
            modifier = Modifier
                .weight(1f)
                .testTag(SplitBillDefaults.amountTag(index)),
        )
    }
}
