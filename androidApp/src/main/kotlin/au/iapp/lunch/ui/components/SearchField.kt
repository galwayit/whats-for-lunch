/**
 * @file SearchField.kt
 * @description Discover search input: search icon, clear button once there is text, and the
 * keyboard's search action wired to [onSearch].
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

/**
 * @param onSearch Called when the keyboard search action fires.
 */
@Composable
fun SearchField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = stringResource(R.string.discover_search_placeholder),
    onSearch: () -> Unit = {},
    enabled: Boolean = true,
) {
    val colors = LunchTheme.colors
    val searchLabel = stringResource(R.string.a11y_search)
    val clearLabel = stringResource(R.string.a11y_clear_search)
    LunchTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier.semantics { contentDescription = searchLabel },
        placeholder = placeholder,
        leadingIcon = LunchIcon.Search,
        enabled = enabled,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = { onSearch() }),
        trailing = if (value.isEmpty()) {
            null
        } else {
            {
                Box(
                    modifier = Modifier
                        .size(TokenSize.touchTarget - TokenSpacing.sm)
                        .clickable(
                            indication = ripple(bounded = false, radius = TokenSize.touchTarget / 2),
                            interactionSource = null,
                            role = Role.Button,
                            onClickLabel = clearLabel,
                            onClick = { onValueChange("") },
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    LunchIconView(icon = LunchIcon.Close, tint = colors.textSecondary, contentDescription = clearLabel)
                }
            }
        },
    )
}

@LunchPreviews
@Composable
private fun SearchFieldPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            SearchField(value = "", onValueChange = {})
            SearchField(value = "Sushi", onValueChange = {})
        }
    }
}
