/**
 * @file CurrencyField.kt
 * @description Money input for meal costs and budgets: currency symbol prefix, decimal keyboard,
 * and input limited to digits with at most two decimals.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardType
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.TokenSpacing

object CurrencyFieldDefaults {
    const val SYMBOL = "$"
    const val MAX_DECIMALS = 2
    private val pattern = Regex("^\\d*(\\.\\d{0,$MAX_DECIMALS})?$")

    /** True for the strings the field accepts: digits, optionally a point and two decimals. */
    fun isAcceptable(input: String): Boolean = pattern.matches(input)
}

/**
 * @param value The raw amount text, e.g. "18.50"; never formatted, so it round-trips to a Double.
 * @param onValueChange Called only with text that passes [CurrencyFieldDefaults.isAcceptable].
 */
@Composable
fun CurrencyField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    placeholder: String = stringResource(R.string.track_log_cost_placeholder),
    enabled: Boolean = true,
    isError: Boolean = false,
    supportingText: String? = null,
) {
    val a11y = stringResource(R.string.a11y_cost)
    LunchTextField(
        value = value,
        onValueChange = { if (CurrencyFieldDefaults.isAcceptable(it)) onValueChange(it) },
        modifier = modifier.semantics { contentDescription = a11y },
        placeholder = placeholder,
        label = label,
        leadingIcon = LunchIcon.AttachMoney,
        enabled = enabled,
        isError = isError,
        supportingText = supportingText,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
    )
}

@LunchPreviews
@Composable
private fun CurrencyFieldPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            CurrencyField(value = "", onValueChange = {}, label = "Cost")
            CurrencyField(value = "18.50", onValueChange = {})
        }
    }
}
