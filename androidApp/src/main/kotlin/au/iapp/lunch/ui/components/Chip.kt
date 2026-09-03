/**
 * @file Chip.kt
 * @description Selectable filter chip: capsule, `primary` when selected, hairline outline when
 * not, with an optional leading icon and trailing chevron (for chips that open a sheet).
 * @author AI Assistant
 * @date 2026-09-03
 */
package au.iapp.lunch.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.Dp
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

object ChipDefaults {
    val iconSize: Dp = TokenSize.iconDefault - TokenSpacing.sm
}

/**
 * @param selected Drives the fill and the `selected` accessibility state.
 * @param leadingIcon Optional icon before the label.
 * @param trailingChevron Shows an expand chevron after the label for chips that open a sheet.
 */
@Composable
fun Chip(
    text: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: LunchIcon? = null,
    trailingChevron: Boolean = false,
) {
    val colors = LunchTheme.colors
    val container = if (selected) colors.primary else colors.surface
    val content = if (selected) colors.textOnPrimary else colors.text
    val interactionSource = remember { MutableInteractionSource() }
    val shape = LunchTheme.shapes.chip

    Row(
        modifier = modifier
            .pressable(interactionSource, enabled)
            .alpha(if (enabled) 1f else ComponentDefaults.DISABLED_ALPHA)
            .defaultMinSize(minHeight = TokenSize.touchTarget)
            .clip(shape)
            .background(container)
            .then(if (selected) Modifier else Modifier.border(ComponentDefaults.hairlineWidth, colors.hairlineStrong, shape))
            .selectable(
                selected = selected,
                interactionSource = interactionSource,
                indication = ripple(color = content),
                enabled = enabled,
                role = Role.Button,
                onClick = onClick,
            )
            .padding(horizontal = TokenSpacing.md, vertical = TokenSpacing.sm),
        horizontalArrangement = Arrangement.spacedBy(TokenSpacing.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leadingIcon != null) {
            LunchIconView(icon = leadingIcon, size = ChipDefaults.iconSize, tint = content)
        }
        LunchText(text = text, role = LunchTextRole.Body, color = content, maxLines = 1)
        if (trailingChevron) {
            LunchIconView(icon = LunchIcon.ExpandMore, size = ChipDefaults.iconSize, tint = content)
        }
    }
}

@LunchPreviews
@Composable
private fun ChipPreview() {
    LunchPreviewSurface {
        Row(horizontalArrangement = Arrangement.spacedBy(TokenSpacing.sm)) {
            Chip("Price", selected = true, onClick = {}, leadingIcon = LunchIcon.Payments, trailingChevron = true)
            Chip("Distance", selected = false, onClick = {}, trailingChevron = true)
            Chip("Rating", selected = false, onClick = {}, enabled = false)
        }
    }
}
