/**
 * @file LunchButton.kt
 * @description The four button styles from design/screens.md: Action (orange, the one
 * conversion button per screen), Primary (paprika), Secondary (soft paprika with outline), and Text.
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import au.iapp.lunch.R
import au.iapp.lunch.ui.preview.LunchPreviewSurface
import au.iapp.lunch.ui.preview.LunchPreviews
import au.iapp.lunch.ui.theme.LunchIcon
import au.iapp.lunch.ui.theme.LunchIconView
import au.iapp.lunch.ui.theme.LunchText
import au.iapp.lunch.ui.theme.LunchTextRole
import au.iapp.lunch.ui.theme.LunchTheme
import au.iapp.lunch.ui.theme.TokenSize
import au.iapp.lunch.ui.theme.TokenSpacing
import au.iapp.lunch.ui.theme.pressable

enum class LunchButtonStyle { Action, Primary, Secondary, Text }

object LunchButtonDefaults {
    val iconSize: Dp = TokenSize.iconDefault - TokenSpacing.xs
    val progressStrokeWidth: Dp = 2.dp
}

/**
 * A full-height design-system button.
 *
 * @param text The label; also the accessibility name.
 * @param loading Shows a spinner in place of the label and blocks taps; the label keeps its
 * width so the layout does not jump.
 * @param icon Optional leading icon.
 */
@Composable
fun LunchButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    style: LunchButtonStyle = LunchButtonStyle.Primary,
    icon: LunchIcon? = null,
    enabled: Boolean = true,
    loading: Boolean = false,
) {
    val colors = LunchTheme.colors
    val container: Color
    val content: Color
    val outline: Color?
    when (style) {
        LunchButtonStyle.Action -> { container = colors.action; content = colors.textOnAction; outline = null }
        LunchButtonStyle.Primary -> { container = colors.primary; content = colors.textOnPrimary; outline = null }
        LunchButtonStyle.Secondary -> {
            container = colors.primarySoft
            content = colors.primary
            outline = colors.primary.copy(alpha = ComponentDefaults.OUTLINE_TINT_ALPHA)
        }
        LunchButtonStyle.Text -> { container = Color.Transparent; content = colors.primary; outline = null }
    }
    val isText = style == LunchButtonStyle.Text
    val interactionSource = remember { MutableInteractionSource() }
    val interactive = enabled && !loading
    val loadingLabel = stringResource(R.string.a11y_loading)
    val shape = LunchTheme.shapes.button

    Box(
        modifier = modifier
            .pressable(interactionSource, interactive)
            .alpha(if (enabled) 1f else ComponentDefaults.DISABLED_ALPHA)
            .defaultMinSize(
                minWidth = TokenSize.buttonMinWidth,
                minHeight = if (isText) TokenSize.touchTarget else TokenSize.buttonHeight,
            )
            .clip(shape)
            .background(container)
            .then(if (outline != null) Modifier.border(ComponentDefaults.hairlineWidth, outline, shape) else Modifier)
            .clickable(
                interactionSource = interactionSource,
                indication = ripple(color = content),
                enabled = interactive,
                role = Role.Button,
                onClick = onClick,
            )
            .semantics { if (loading) stateDescription = loadingLabel }
            .padding(horizontal = if (isText) TokenSpacing.sm else TokenSpacing.lg, vertical = TokenSpacing.sm),
        contentAlignment = Alignment.Center,
    ) {
        Row(
            modifier = Modifier.alpha(if (loading) 0f else 1f),
            horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (icon != null) {
                LunchIconView(icon = icon, size = LunchButtonDefaults.iconSize, tint = content)
            }
            LunchText(text = text, role = LunchTextRole.Button, color = content, maxLines = 1)
        }
        if (loading) {
            CircularProgressIndicator(
                modifier = Modifier.size(LunchButtonDefaults.iconSize),
                color = content,
                strokeWidth = LunchButtonDefaults.progressStrokeWidth,
            )
        }
    }
}

@LunchPreviews
@Composable
private fun LunchButtonPreview() {
    LunchPreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            LunchButton("Start free trial", {}, style = LunchButtonStyle.Action)
            LunchButton("Log this meal", {}, icon = LunchIcon.Add)
            LunchButton("Directions", {}, style = LunchButtonStyle.Secondary, icon = LunchIcon.Directions)
            LunchButton("Show me more", {}, style = LunchButtonStyle.Text)
            LunchButton("Saving", {}, loading = true)
            LunchButton("Disabled", {}, enabled = false)
        }
    }
}
