/**
 * @file LunchTextField.kt
 * @description The base text input: 16dp corners, hairline at rest, a 2dp `primary` border when
 * focused (`danger` when in error), leading icon and trailing slot.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.Dp
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchMotion
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing

object LunchTextFieldDefaults {
    val focusBorderWidth: Dp = TokenSpacing.xs / 2
    val restBorderWidth: Dp = ComponentDefaults.hairlineWidth
}

/**
 * @param label Optional caption above the field.
 * @param supportingText Optional caption below; drawn in `danger` when [isError].
 * @param trailing Slot after the text (a clear button, a unit).
 */
@Composable
fun LunchTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String? = null,
    label: String? = null,
    leadingIcon: LunchIcon? = null,
    trailing: (@Composable () -> Unit)? = null,
    enabled: Boolean = true,
    isError: Boolean = false,
    supportingText: String? = null,
    singleLine: Boolean = true,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
) {
    val colors = LunchTheme.colors
    val focused by interactionSource.collectIsFocusedAsState()
    val emphasised = focused || isError
    val borderColor by animateColorAsState(
        targetValue = when {
            isError -> colors.danger
            focused -> colors.primary
            else -> colors.hairlineStrong
        },
        animationSpec = LunchMotion.state(),
        label = "fieldBorder",
    )
    val borderWidth = if (emphasised) LunchTextFieldDefaults.focusBorderWidth else LunchTextFieldDefaults.restBorderWidth
    val shape = LunchTheme.shapes.input

    Column(modifier = modifier.alpha(if (enabled) 1f else ComponentDefaults.DISABLED_ALPHA)) {
        if (label != null) {
            LunchText(
                text = label,
                role = LunchTextRole.Caption,
                color = colors.textSecondary,
                modifier = Modifier.padding(bottom = TokenSpacing.xs),
            )
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .fillMaxWidth()
                .defaultMinSize(minHeight = TokenSize.buttonHeight)
                .background(colors.surface, shape)
                .border(borderWidth, borderColor, shape),
            enabled = enabled,
            textStyle = LunchTheme.typography.body.copy(color = colors.text),
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions,
            singleLine = singleLine,
            visualTransformation = visualTransformation,
            interactionSource = interactionSource,
            cursorBrush = SolidColor(colors.primary),
            decorationBox = { innerTextField ->
                Row(
                    modifier = Modifier
                        .defaultMinSize(minHeight = TokenSize.buttonHeight)
                        .padding(horizontal = TokenSpacing.md, vertical = TokenSpacing.sm),
                    horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (leadingIcon != null) {
                        LunchIconView(icon = leadingIcon, tint = colors.textSecondary)
                    }
                    Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
                        if (value.isEmpty() && placeholder != null) {
                            LunchText(text = placeholder, role = LunchTextRole.Body, color = colors.textSecondary, maxLines = 1)
                        }
                        innerTextField()
                    }
                    trailing?.invoke()
                }
            },
        )
        if (supportingText != null) {
            LunchText(
                text = supportingText,
                role = LunchTextRole.Caption,
                color = if (isError) colors.danger else colors.textSecondary,
                modifier = Modifier.padding(top = TokenSpacing.xs, start = TokenSpacing.md),
            )
        }
    }
}

@LunchPreviews
@Composable
private fun LunchTextFieldPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.md)) {
            LunchTextField(value = "", onValueChange = {}, placeholder = "Your first name", label = "Name")
            LunchTextField(value = "Ray", onValueChange = {}, leadingIcon = LunchIcon.Person)
            LunchTextField(value = "ray@", onValueChange = {}, isError = true, supportingText = "Enter a full email address")
            LunchTextField(value = "Disabled", onValueChange = {}, enabled = false)
        }
    }
}
